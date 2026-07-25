/**
 * SamplerEngine — sample-playback voice implementing the same VoiceSink
 * contract as the synth, sharing the host engine's FX chain. Pitch is
 * continuous via AudioBufferSourceNode.detune, so slide/frets/aftertouch
 * behave exactly as on the synth. RETRIG restarts the sample when a slide
 * crosses into a new semitone (harp-gliss style).
 */
import { clamp, cutoffToHz, lerp, velocityToGain } from './dsp'
import { renderSample, SAMPLE_NAMES, USER_PRESET } from './samplegen'
import type { Store } from '../core/state'
import type { SynthEngine } from './engine'
import type { VoiceSink } from './sink'

interface SampleEntry {
  buffer: AudioBuffer
  root: number
  loopStart?: number
  loopEnd?: number
}

interface SVoice {
  pitch: number
  vel: number
  root: number
  src: AudioBufferSourceNode
  filter: BiquadFilterNode
  vca: GainNode
}

const MAX_LIVE_SAMPLE_VOICES = 16
/** Quietest a voice gets when pressure is routed to level (swell floor). */
const EXPR_LEVEL_FLOOR = 0.3

function holdAutomation(param: AudioParam, time: number): void {
  if (typeof param.cancelAndHoldAtTime === 'function') {
    param.cancelAndHoldAtTime(time)
  } else {
    const value = param.value
    param.cancelScheduledValues(time)
    param.setValueAtTime(value, time)
  }
}

export class SamplerEngine implements VoiceSink {
  static readonly maxFileBytes = 50 * 1024 * 1024
  static readonly maxDurationSeconds = 30
  private cache = new Map<string, SampleEntry>()
  private user: { buffer: AudioBuffer; name: string } | null = null
  private out: GainNode | null = null
  private voices = new Map<number, SVoice>()
  private releaseTails = new Set<SVoice>()

  constructor(private store: Store, private host: SynthEngine) {
    store.subscribe((_s, path) => {
      if (path === 'sampler.level' && this.out && this.host.ctx) {
        this.out.gain.setTargetAtTime(
          store.state.sampler.level, this.host.ctx.currentTime, 0.02,
        )
      }
    })
  }

  get voiceCount(): number {
    return this.voices.size
  }

  get liveVoiceCount(): number {
    return this.voices.size + this.releaseTails.size
  }

  get userSampleName(): string | null {
    return this.user?.name ?? null
  }

  setUserSample(buffer: AudioBuffer, name: string): void {
    this.user = { buffer, name }
    this.cache.delete(USER_PRESET)
  }

  /** Decode an audio file into the user sample slot. */
  async decodeFile(file: { name: string; size?: number; arrayBuffer(): Promise<ArrayBuffer> }): Promise<void> {
    if (file.size !== undefined && file.size > SamplerEngine.maxFileBytes) {
      throw new Error('Sample files must be 50 MB or smaller.')
    }
    this.host.ensure() // the file-picker change event is a user gesture
    const bytes = await file.arrayBuffer()
    if (bytes.byteLength === 0 || bytes.byteLength > SamplerEngine.maxFileBytes) {
      throw new Error('Sample file is empty or too large.')
    }
    const buffer = await this.host.ctx!.decodeAudioData(bytes)
    if (
      buffer.length === 0
      || !Number.isFinite(buffer.duration)
      || buffer.duration > SamplerEngine.maxDurationSeconds
    ) {
      throw new Error('Samples must contain audio and be 30 seconds or shorter.')
    }
    this.setUserSample(buffer, file.name)
  }

  private ensureOut(): GainNode {
    this.host.ensure()
    const ctx = this.host.ctx!
    if (!this.out) {
      this.out = ctx.createGain()
      this.out.gain.value = this.store.state.sampler.level
      this.out.connect(this.host.fxInput)
    }
    return this.out
  }

  private currentSample(): SampleEntry | null {
    const ctx = this.host.ctx!
    const preset = this.store.state.sampler.preset
    if (preset === USER_PRESET) {
      if (!this.user) return null
      return {
        buffer: this.user.buffer,
        root: this.store.state.sampler.userRoot,
      }
    }
    const name = SAMPLE_NAMES.includes(preset) ? preset : SAMPLE_NAMES[0]
    let entry = this.cache.get(name)
    if (!entry) {
      const r = renderSample(name, ctx.sampleRate)
      const buffer = ctx.createBuffer(1, r.data.length, ctx.sampleRate)
      buffer.copyToChannel(r.data, 0)
      entry = { buffer, root: r.root, loopStart: r.loopStart, loopEnd: r.loopEnd }
      this.cache.set(name, entry)
    }
    return entry
  }

  noteOn(id: number, pitch: number, vel: number): void {
    this.ensureOut()
    if (this.voices.has(id)) this.noteOff(id)
    this.startVoice(id, pitch, vel)
  }

  private startVoice(id: number, pitch: number, vel: number): void {
    this.reclaimVoices()
    const ctx = this.host.ctx!
    const entry = this.currentSample()
    if (!entry) return
    const s = this.store.state.sampler
    const t = ctx.currentTime

    const src = ctx.createBufferSource()
    src.buffer = entry.buffer
    if (entry.loopStart !== undefined && entry.loopEnd !== undefined) {
      src.loop = true
      src.loopStart = entry.loopStart / entry.buffer.sampleRate
      src.loopEnd = entry.loopEnd / entry.buffer.sampleRate
    }
    src.detune.value = (pitch - entry.root) * 100

    const filter = ctx.createBiquadFilter()
    filter.type = 'lowpass'
    filter.frequency.value = cutoffToHz(0.8)

    const vca = ctx.createGain()
    vca.gain.value = 0
    const swell = this.store.state.expr.pressure === 'level' ? EXPR_LEVEL_FLOOR : 1
    const peak = velocityToGain(vel) * swell
    const a = Math.max(0.002, s.attack)
    vca.gain.setValueAtTime(0, t)
    vca.gain.linearRampToValueAtTime(peak, t + a)

    src.connect(filter).connect(vca).connect(this.out!)
    src.start(t)
    const voice: SVoice = { pitch, vel, root: entry.root, src, filter, vca }
    src.onended = () => {
      if (this.voices.get(id) === voice) this.voices.delete(id)
      this.releaseTails.delete(voice)
      try {
        src.disconnect()
        filter.disconnect()
        vca.disconnect()
      } catch {
        // already torn down
      }
    }
    this.voices.set(id, voice)
  }

  glide(id: number, pitch: number): void {
    const v = this.voices.get(id)
    if (!v || !this.host.ctx) return
    const t = this.host.ctx.currentTime
    const retrig = this.store.state.sampler.retrig
    if (retrig && Math.round(pitch) !== Math.round(v.pitch)) {
      // Restart at the new semitone, like a harp glissando.
      this.releaseVoice(id, v, 0.025)
      this.startVoice(id, Math.round(pitch), v.vel)
      return
    }
    v.pitch = pitch
    const tc = lerp(0.004, 0.06, this.store.state.pad.slide)
    v.src.detune.setTargetAtTime((pitch - v.root) * 100, t, tc)
  }

  pressure(id: number, value: number): void {
    const v = this.voices.get(id)
    if (!v || !this.host.ctx) return
    const t = this.host.ctx.currentTime
    const p = clamp(value, 0, 1)
    switch (this.store.state.expr.pressure) {
      case 'filter':
        v.filter.frequency.setTargetAtTime(cutoffToHz(0.8 + 0.2 * p), t, 0.015)
        // Gentle swell into the touch.
        v.vca.gain.setTargetAtTime(velocityToGain(v.vel) * (1 + 0.35 * p), t, 0.03)
        break
      case 'level':
        v.vca.gain.setTargetAtTime(velocityToGain(v.vel) * lerp(EXPR_LEVEL_FLOOR, 1, p), t, 0.03)
        break
      default:
        // 'lfo' has no meaning for samples; 'off' ignores pressure.
        break
    }
  }

  noteOff(id: number): void {
    const v = this.voices.get(id)
    if (!v || !this.host.ctx) return
    const r = Math.max(0.02, this.store.state.sampler.release)
    this.releaseVoice(id, v, r)
  }

  allOff(): void {
    for (const voice of this.voices.values()) this.hardStopVoice(voice)
    for (const voice of this.releaseTails) this.hardStopVoice(voice)
    this.voices.clear()
    this.releaseTails.clear()
  }

  private releaseVoice(id: number, voice: SVoice, release: number): void {
    const t = this.host.ctx!.currentTime
    holdAutomation(voice.vca.gain, t)
    voice.vca.gain.setTargetAtTime(0, t, release / 3)
    this.voices.delete(id)
    this.releaseTails.add(voice)
    voice.src.stop(t + release * 2 + 0.1)
  }

  private reclaimVoices(): void {
    while (this.voices.size + this.releaseTails.size >= MAX_LIVE_SAMPLE_VOICES) {
      const oldestTail = this.releaseTails.values().next()
      if (!oldestTail.done) {
        this.hardStopVoice(oldestTail.value)
        continue
      }
      const oldest = this.voices.entries().next()
      if (oldest.done) break
      this.hardStopVoice(oldest.value[1])
    }
  }

  private hardStopVoice(voice: SVoice): void {
    for (const [id, active] of this.voices) {
      if (active === voice) this.voices.delete(id)
    }
    this.releaseTails.delete(voice)
    const t = this.host.ctx?.currentTime ?? 0
    holdAutomation(voice.vca.gain, t)
    voice.vca.gain.setValueAtTime(0, t)
    try { voice.src.stop(t) } catch { /* already ended */ }
    try {
      voice.src.disconnect()
      voice.filter.disconnect()
      voice.vca.disconnect()
    } catch {
      // already torn down
    }
  }
}
