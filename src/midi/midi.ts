/**
 * Web MIDI output with MPE-style expression: each touch gets its own channel
 * so per-note pitch bend, channel pressure, and CC74 (timbre) stay independent.
 * Also a simple MIDI input that drives a VoiceSink.
 */
import { clamp } from '../audio/dsp'
import type { Store } from '../core/state'
import type { VoiceSink } from '../audio/sink'

/** 14-bit pitch bend bytes [lsb, msb] for a semitone offset within ±range. */
export function bendBytes(semitones: number, range: number): [number, number] {
  const norm = clamp(semitones / range, -1, 1)
  const value = clamp(Math.round(8192 + norm * 8191), 0, 16383)
  return [value & 0x7f, (value >> 7) & 0x7f]
}

/** Rotating member-channel allocator (channels 1–15, zero-indexed; 0 is the MPE master). */
export class ChannelAllocator {
  private free: number[] = []
  private held = new Map<number, number>()

  constructor(low = 1, high = 15) {
    for (let c = low; c <= high; c++) this.free.push(c)
  }

  acquire(id: number): number {
    return this.acquireWithEviction(id).channel
  }

  acquireWithEviction(id: number): { channel: number; evictedId?: number } {
    const existing = this.held.get(id)
    if (existing !== undefined) return { channel: existing }
    const free = this.free.shift()
    const stolen = free === undefined ? this.oldestHeld() : undefined
    const ch = free ?? stolen!.channel
    this.held.set(id, ch)
    return { channel: ch, evictedId: stolen?.id }
  }

  release(id: number): number | undefined {
    const ch = this.held.get(id)
    if (ch !== undefined) {
      this.held.delete(id)
      this.free.push(ch) // back of the queue → maximum reuse distance
    }
    return ch
  }

  channelOf(id: number): number | undefined {
    return this.held.get(id)
  }

  private oldestHeld(): { id: number; channel: number } {
    const first = this.held.entries().next()
    if (first.done) return { id: -1, channel: 1 }
    const [id, ch] = first.value
    this.held.delete(id)
    return { id, channel: ch }
  }
}

interface VoiceState {
  channel: number
  noteNum: number
  pitch: number
  port: MIDIOutput
}

export class MidiOut implements VoiceSink {
  access: MIDIAccess | null = null
  private alloc = new ChannelAllocator()
  private active = new Map<number, VoiceState>()
  private deviceListeners = new Set<() => void>()
  private configuredRange = new WeakMap<MIDIOutput, number>()

  constructor(private store: Store) {
    store.subscribe((_state, path) => {
      if (path === 'midi.outputId') {
        this.allOff()
        this.configureCurrentPort()
      } else if (path === 'midi.bendRange') {
        this.configureCurrentPort()
      }
    })
  }

  async init(): Promise<boolean> {
    if (!('requestMIDIAccess' in navigator)) return false
    try {
      this.access = await navigator.requestMIDIAccess({ sysex: false })
      this.access.onstatechange = () => {
        // Device identity changed underneath active voices. Release everything
        // we can still reach before refreshing selectors/connections.
        this.allOff()
        for (const listener of this.deviceListeners) listener()
        this.configureCurrentPort()
      }
      this.configureCurrentPort()
      for (const listener of this.deviceListeners) listener()
      return true
    } catch {
      return false
    }
  }

  get supported(): boolean {
    return 'requestMIDIAccess' in navigator
  }

  outputs(): Array<{ id: string; name: string }> {
    if (!this.access) return []
    return [...this.access.outputs.values()].map((o) => ({ id: o.id, name: o.name ?? o.id }))
  }

  inputs(): Array<{ id: string; name: string }> {
    if (!this.access) return []
    return [...this.access.inputs.values()].map((i) => ({ id: i.id, name: i.name ?? i.id }))
  }

  onDevicesChanged(listener: () => void): () => void {
    this.deviceListeners.add(listener)
    return () => this.deviceListeners.delete(listener)
  }

  private port(): MIDIOutput | null {
    if (!this.access) return null
    const id = this.store.state.midi.outputId
    return this.access.outputs.get(id) ?? this.access.outputs.values().next().value ?? null
  }

  private sendTo(port: MIDIOutput | null, bytes: number[]): void {
    try {
      port?.send(bytes)
    } catch {
      // device vanished mid-performance — drop the message
    }
  }

  noteOn(id: number, pitch: number, vel: number): void {
    if (this.active.has(id)) this.noteOff(id)
    const port = this.port()
    if (!port) return
    this.ensurePitchBendRange(port)
    const allocation = this.alloc.acquireWithEviction(id)
    const ch = allocation.channel
    if (allocation.evictedId !== undefined) {
      const stolen = this.active.get(allocation.evictedId)
      if (stolen) {
        this.sendTo(stolen.port, [0x80 | stolen.channel, stolen.noteNum, 0])
        this.active.delete(allocation.evictedId)
      }
    }
    const noteNum = clamp(Math.round(pitch), 0, 127)
    const range = this.store.state.midi.bendRange
    const [lsb, msb] = bendBytes(pitch - noteNum, range)
    this.sendTo(port, [0xe0 | ch, lsb, msb])
    this.sendTo(port, [0x90 | ch, noteNum, clamp(Math.round(vel * 127), 1, 127)])
    this.active.set(id, { channel: ch, noteNum, pitch, port })
  }

  glide(id: number, pitch: number): void {
    const v = this.active.get(id)
    if (!v) return
    const range = this.store.state.midi.bendRange
    const [lsb, msb] = bendBytes(pitch - v.noteNum, range)
    this.sendTo(v.port, [0xe0 | v.channel, lsb, msb])
    v.pitch = pitch
  }

  pressure(id: number, value: number): void {
    const v = this.active.get(id)
    if (!v) return
    const val = clamp(Math.round(value * 127), 0, 127)
    this.sendTo(v.port, [0xd0 | v.channel, val])
    if (this.store.state.midi.sendY) this.sendTo(v.port, [0xb0 | v.channel, 74, val])
  }

  noteOff(id: number): void {
    const v = this.active.get(id)
    if (!v) return
    this.sendTo(v.port, [0x80 | v.channel, v.noteNum, 0])
    this.alloc.release(id)
    this.active.delete(id)
  }

  allOff(): void {
    const ports = new Set<MIDIOutput>()
    for (const voice of this.active.values()) ports.add(voice.port)
    for (const id of [...this.active.keys()]) this.noteOff(id)
    const current = this.port()
    if (current) ports.add(current)
    for (const port of ports) {
      for (let ch = 0; ch < 16; ch++) {
        this.sendTo(port, [0xb0 | ch, 64, 0]) // sustain off
        this.sendTo(port, [0xb0 | ch, 120, 0]) // all sound off
        this.sendTo(port, [0xb0 | ch, 123, 0]) // all notes off
        this.sendTo(port, [0xe0 | ch, 0, 64]) // bend center
      }
    }
  }

  private configureCurrentPort(): void {
    const port = this.port()
    if (!port) return
    this.ensurePitchBendRange(port, true)
    // Changing bend sensitivity reinterprets the receiver's existing bend
    // value. Re-send each held voice immediately so sustained notes do not
    // jump until the performer's next movement.
    for (const voice of this.active.values()) {
      if (voice.port !== port) continue
      const [lsb, msb] = bendBytes(
        voice.pitch - voice.noteNum,
        this.store.state.midi.bendRange,
      )
      this.sendTo(port, [0xe0 | voice.channel, lsb, msb])
    }
  }

  private ensurePitchBendRange(port: MIDIOutput, force = false): void {
    const range = clamp(Math.round(this.store.state.midi.bendRange), 1, 96)
    if (!force && this.configuredRange.get(port) === range) return

    // MPE lower-zone configuration: master channel 1, 15 member channels.
    this.sendRpn(port, 0, 0, 6, 15, 0)
    // Configure pitch-bend sensitivity on every member channel.
    for (let ch = 1; ch < 16; ch++) this.sendRpn(port, ch, 0, 0, range, 0)
    this.configuredRange.set(port, range)
  }

  private sendRpn(
    port: MIDIOutput,
    channel: number,
    msb: number,
    lsb: number,
    dataMsb: number,
    dataLsb: number,
  ): void {
    const cc = 0xb0 | channel
    this.sendTo(port, [cc, 101, msb])
    this.sendTo(port, [cc, 100, lsb])
    this.sendTo(port, [cc, 6, dataMsb])
    this.sendTo(port, [cc, 38, dataLsb])
    this.sendTo(port, [cc, 101, 127])
    this.sendTo(port, [cc, 100, 127])
  }
}

let midiInVoiceBase = 1_000_000

export class MidiIn {
  private current: MIDIInput | null = null
  private noteIds = new Map<string, number>()

  constructor(private store: Store, private sink: VoiceSink) {}

  attach(access: MIDIAccess): void {
    this.detach()
    const id = this.store.state.midi.inputId
    const input = access.inputs.get(id) ?? access.inputs.values().next().value ?? null
    if (!input) return
    this.current = input
    input.onmidimessage = (e: MIDIMessageEvent) => this.handle(e.data)
  }

  detach(): void {
    if (this.current) this.current.onmidimessage = null
    this.current = null
    for (const id of this.noteIds.values()) this.sink.noteOff(id)
    this.noteIds.clear()
  }

  handle(data: Uint8Array | null): void {
    if (!data || data.length < 2 || !this.store.state.midi.inEnabled) return
    const status = data[0] & 0xf0
    const ch = data[0] & 0x0f
    const key = `${ch}:${data[1]}`
    if (status === 0x90 && data[2] > 0) {
      const previous = this.noteIds.get(key)
      if (previous !== undefined) this.sink.noteOff(previous)
      const id = midiInVoiceBase++
      this.noteIds.set(key, id)
      this.sink.noteOn(id, data[1], data[2] / 127)
    } else if (status === 0x80 || (status === 0x90 && data[2] === 0)) {
      const id = this.noteIds.get(key)
      if (id !== undefined) {
        this.sink.noteOff(id)
        this.noteIds.delete(key)
      }
    }
  }
}
