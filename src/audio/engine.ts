/**
 * SynthEngine — polyphonic additive synthesizer on Web Audio.
 *
 * Per voice: gen1 + gen2 oscillators (PeriodicWave from additive partials),
 * optional fatten pair (detuned copies), lowpass filter with envelope + LFO,
 * ADSR amp envelope. Voices feed a shared FX chain:
 *   voices → distortion → delay → reverb → master → limiter → out.
 */
import {
  clamp, cutoffToHz, driveCurve, harmonicAmps, impulseResponse, lerp,
  partialsToWave, velocityToGain,
} from './dsp'
import { midiToFreq } from '../core/notes'
import type { Store, SynthConfig, FxConfig } from '../core/state'
import type { VoiceSink } from './sink'

interface Voice {
  pitch: number
  vel: number
  oscs: OscillatorNode[]
  baseDetunes: number[]
  gens: GainNode[]
  filter: BiquadFilterNode
  vca: GainNode
  pressure: number
  releasedAt: number | null
}

interface FxInsert {
  input: GainNode
  dry: GainNode
  wet: GainNode
  output: GainNode
}

const MAX_VOICES = 10

export class SynthEngine implements VoiceSink {
  ctx: AudioContext | null = null
  private voices = new Map<number, Voice>()
  private wave1: PeriodicWave | null = null
  private wave2: PeriodicWave | null = null
  private voiceBus!: GainNode
  private master!: GainNode
  private limiter!: DynamicsCompressorNode
  private dist!: FxInsert & { shaper: WaveShaperNode }
  private delay!: FxInsert & { node: DelayNode; fdbk: GainNode }
  private reverb!: FxInsert & { conv: ConvolverNode }
  private lfo!: OscillatorNode
  private lfoPitch!: GainNode
  private lfoFilter!: GainNode
  private reverbTimer: ReturnType<typeof setTimeout> | null = null

  constructor(private store: Store, private makeContext?: () => AudioContext) {
    store.subscribe((_s, path) => {
      if (!this.ctx) return
      if (path.startsWith('synth') || path.startsWith('fx')) this.applyParams(path)
    })
  }

  /** Create the AudioContext (must be called from a user gesture). */
  ensure(): void {
    if (this.ctx) {
      if (this.ctx.state === 'suspended') void this.ctx.resume()
      return
    }
    this.ctx = this.makeContext
      ? this.makeContext()
      : new AudioContext({ latencyHint: 'interactive' })
    this.buildGraph()
    this.applyParams('synth')
    this.applyParams('fx')
  }

  get latencyMs(): number {
    if (!this.ctx) return 0
    return Math.round((this.ctx.baseLatency ?? 0) * 1000 + (128 / this.ctx.sampleRate) * 1000)
  }

  private buildGraph(): void {
    const ctx = this.ctx!
    this.voiceBus = ctx.createGain()
    this.master = ctx.createGain()
    this.limiter = ctx.createDynamicsCompressor()
    this.limiter.threshold.value = -3
    this.limiter.knee.value = 6
    this.limiter.ratio.value = 12
    this.limiter.attack.value = 0.002
    this.limiter.release.value = 0.1

    const insert = (): FxInsert => {
      const input = ctx.createGain()
      const dry = ctx.createGain()
      const wet = ctx.createGain()
      const output = ctx.createGain()
      input.connect(dry).connect(output)
      return { input, dry, wet, output }
    }

    const dist = insert() as SynthEngine['dist']
    dist.shaper = ctx.createWaveShaper()
    dist.shaper.oversample = '2x'
    dist.input.connect(dist.shaper).connect(dist.wet).connect(dist.output)
    this.dist = dist

    const delay = insert() as SynthEngine['delay']
    delay.node = ctx.createDelay(2)
    delay.fdbk = ctx.createGain()
    delay.input.connect(delay.node)
    delay.node.connect(delay.fdbk).connect(delay.node)
    delay.node.connect(delay.wet).connect(delay.output)
    this.delay = delay

    const reverb = insert() as SynthEngine['reverb']
    reverb.conv = ctx.createConvolver()
    reverb.input.connect(reverb.conv).connect(reverb.wet).connect(reverb.output)
    this.reverb = reverb

    this.voiceBus
      .connect(this.dist.input)
    this.dist.output.connect(this.delay.input)
    this.delay.output.connect(this.reverb.input)
    this.reverb.output.connect(this.master).connect(this.limiter).connect(ctx.destination)

    this.lfo = ctx.createOscillator()
    this.lfoPitch = ctx.createGain()
    this.lfoFilter = ctx.createGain()
    this.lfo.connect(this.lfoPitch)
    this.lfo.connect(this.lfoFilter)
    this.lfo.start()

    this.rebuildWaves()
    this.rebuildReverb()
  }

  private synth(): SynthConfig {
    return this.store.state.synth
  }

  private fx(): FxConfig {
    return this.store.state.fx
  }

  private rebuildWaves(): void {
    const ctx = this.ctx!
    const s = this.synth()
    const w1 = partialsToWave(harmonicAmps(s.gen1.morph, s.bright))
    const w2 = partialsToWave(harmonicAmps(s.gen2.morph, s.bright))
    this.wave1 = ctx.createPeriodicWave(w1.real, w1.imag, { disableNormalization: false })
    this.wave2 = ctx.createPeriodicWave(w2.real, w2.imag, { disableNormalization: false })
    for (const v of this.voices.values()) {
      for (let i = 0; i < v.oscs.length; i++) {
        v.oscs[i].setPeriodicWave(i % 2 === 0 ? this.wave1 : this.wave2)
      }
    }
  }

  private rebuildReverb(): void {
    // IR generation is mildly expensive; throttle while the knob turns.
    if (this.reverbTimer) clearTimeout(this.reverbTimer)
    this.reverbTimer = setTimeout(() => {
      const ctx = this.ctx!
      const fdbk = this.fx().reverb.fdbk
      const seconds = lerp(0.4, 5, fdbk)
      const chans = impulseResponse(seconds, lerp(4.5, 2, fdbk), ctx.sampleRate)
      const buf = ctx.createBuffer(2, chans[0].length, ctx.sampleRate)
      buf.copyToChannel(chans[0], 0)
      buf.copyToChannel(chans[1], 1)
      this.reverb.conv.buffer = buf
    }, 80)
  }

  private applyParams(path: string): void {
    const s = this.synth()
    const fx = this.fx()
    const t = this.ctx!.currentTime
    if (path === 'synth' || path.includes('morph') || path.includes('bright')) this.rebuildWaves()
    if (path === 'fx' || path.includes('reverb.fdbk')) this.rebuildReverb()

    this.master.gain.setTargetAtTime(s.level, t, 0.02)

    this.dist.shaper.curve = driveCurve(fx.distort.amt)
    this.dist.wet.gain.setTargetAtTime(fx.distort.on ? 1 : 0, t, 0.02)
    this.dist.dry.gain.setTargetAtTime(fx.distort.on ? 0 : 1, t, 0.02)

    this.delay.node.delayTime.setTargetAtTime(clamp(fx.delay.time, 0.01, 2), t, 0.05)
    this.delay.fdbk.gain.setTargetAtTime(clamp(fx.delay.fdbk, 0, 0.9), t, 0.02)
    this.delay.wet.gain.setTargetAtTime(fx.delay.on ? fx.delay.mix : 0, t, 0.02)

    this.reverb.wet.gain.setTargetAtTime(fx.reverb.on ? fx.reverb.mix : 0, t, 0.02)

    this.lfo.frequency.setTargetAtTime(clamp(s.lfo.rate, 0.05, 30), t, 0.02)
    this.lfoPitch.gain.setTargetAtTime(s.lfo.target === 'pitch' ? s.lfo.depth * 60 : 0, t, 0.02)
    this.lfoFilter.gain.setTargetAtTime(s.lfo.target === 'filter' ? s.lfo.depth * 2400 : 0, t, 0.02)

    if (path.includes('semi') || path.includes('tune')) {
      for (const v of this.voices.values()) this.retuneVoice(v)
    }
    if (path.includes('filter') || path.includes('fatten')) {
      for (const v of this.voices.values()) this.updateVoiceFilter(v)
    }
    if (path.includes('gen1.level') || path.includes('gen2.level')) {
      for (const v of this.voices.values()) {
        v.gens[0].gain.setTargetAtTime(s.gen1.level, t, 0.02)
        v.gens[1].gain.setTargetAtTime(s.gen2.level, t, 0.02)
      }
    }
  }

  // -------------------------------------------------------------- voices ---

  noteOn(id: number, pitch: number, vel: number): void {
    this.ensure()
    const ctx = this.ctx!
    if (this.voices.has(id)) this.noteOff(id)
    this.reclaimVoices()
    const s = this.synth()
    const fx = this.fx()
    const t = ctx.currentTime

    const filter = ctx.createBiquadFilter()
    filter.type = 'lowpass'
    const vca = ctx.createGain()
    vca.gain.value = 0
    filter.connect(vca).connect(this.voiceBus)
    this.lfoFilter.connect(filter.detune)

    const fatten = fx.fatten.on
    const detuneSpread = lerp(4, 28, fx.fatten.amt)
    const layers: Array<{ gen: 0 | 1; detune: number; gainScale: number }> = [
      { gen: 0, detune: 0, gainScale: 1 },
      { gen: 1, detune: 0, gainScale: 1 },
    ]
    if (fatten) {
      layers.push({ gen: 0, detune: detuneSpread, gainScale: 0.45 })
      layers.push({ gen: 0, detune: -detuneSpread, gainScale: 0.45 })
    }

    const g1 = ctx.createGain()
    const g2 = ctx.createGain()
    g1.gain.value = s.gen1.level
    g2.gain.value = s.gen2.level
    g1.connect(filter)
    g2.connect(filter)

    const oscs: OscillatorNode[] = []
    const baseDetunes: number[] = []
    for (const layer of layers) {
      const osc = ctx.createOscillator()
      osc.setPeriodicWave(layer.gen === 0 ? this.wave1! : this.wave2!)
      const gen = layer.gen === 0 ? s.gen1 : s.gen2
      osc.frequency.value = midiToFreq(pitch + gen.semi)
      osc.detune.value = gen.tune + layer.detune
      baseDetunes.push(gen.tune + layer.detune)
      const scale = ctx.createGain()
      scale.gain.value = layer.gainScale
      osc.connect(scale).connect(layer.gen === 0 ? g1 : g2)
      this.lfoPitch.connect(osc.detune)
      osc.start(t)
      oscs.push(osc)
    }

    const voice: Voice = {
      pitch, vel, oscs, baseDetunes, gens: [g1, g2], filter, vca,
      pressure: 0, releasedAt: null,
    }
    this.voices.set(id, voice)
    this.updateVoiceFilter(voice)

    const peak = velocityToGain(vel)
    const a = Math.max(0.001, s.env.a)
    vca.gain.cancelScheduledValues(t)
    vca.gain.setValueAtTime(0, t)
    vca.gain.linearRampToValueAtTime(peak, t + a)
    vca.gain.setTargetAtTime(peak * s.env.s, t + a, Math.max(0.01, s.env.d) / 3)
  }

  glide(id: number, pitch: number): void {
    const v = this.voices.get(id)
    if (!v) return
    v.pitch = pitch
    this.retuneVoice(v)
  }

  pressure(id: number, value: number): void {
    const v = this.voices.get(id)
    if (!v) return
    v.pressure = clamp(value, 0, 1)
    this.updateVoiceFilter(v)
  }

  noteOff(id: number): void {
    const v = this.voices.get(id)
    if (!v || !this.ctx) return
    const t = this.ctx.currentTime
    const r = Math.max(0.02, this.synth().env.r)
    v.releasedAt = t
    v.vca.gain.cancelScheduledValues(t)
    v.vca.gain.setTargetAtTime(0, t, r / 3)
    const stopAt = t + r * 2 + 0.1
    for (const osc of v.oscs) osc.stop(stopAt)
    this.voices.delete(id)
    const cleanup = () => {
      try {
        v.vca.disconnect()
        v.filter.disconnect()
        for (const osc of v.oscs) {
          this.lfoPitch.disconnect(osc.detune)
          osc.disconnect()
        }
        this.lfoFilter.disconnect(v.filter.detune)
      } catch {
        // double-disconnects are harmless
      }
    }
    v.oscs[0].onended = cleanup
  }

  allOff(): void {
    for (const id of [...this.voices.keys()]) this.noteOff(id)
  }

  get voiceCount(): number {
    return this.voices.size
  }

  private reclaimVoices(): void {
    if (this.voices.size < MAX_VOICES) return
    const oldest = this.voices.keys().next()
    if (!oldest.done) this.noteOff(oldest.value)
  }

  private retuneVoice(v: Voice): void {
    const s = this.synth()
    const t = this.ctx!.currentTime
    const slide = this.store.state.pad.slide
    const tc = lerp(0.004, 0.06, slide)
    for (let i = 0; i < v.oscs.length; i++) {
      const gen = i === 1 ? s.gen2 : s.gen1
      v.oscs[i].frequency.setTargetAtTime(midiToFreq(v.pitch + gen.semi), t, tc)
    }
  }

  private updateVoiceFilter(v: Voice): void {
    const s = this.synth()
    const t = this.ctx!.currentTime
    // Aftertouch pushes the cutoff up through the envelope-amount range.
    const norm = clamp(s.filter.cutoff + s.filter.env * v.pressure, 0, 1)
    v.filter.frequency.setTargetAtTime(cutoffToHz(norm), t, 0.015)
    v.filter.Q.setTargetAtTime(s.filter.res * 18, t, 0.02)
  }
}
