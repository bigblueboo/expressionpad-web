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
    const existing = this.held.get(id)
    if (existing !== undefined) return existing
    const ch = this.free.shift() ?? this.oldestHeldChannel()
    this.held.set(id, ch)
    return ch
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

  private oldestHeldChannel(): number {
    const first = this.held.entries().next()
    if (first.done) return 1
    const [id, ch] = first.value
    this.held.delete(id)
    return ch
  }
}

interface VoiceState {
  channel: number
  noteNum: number
}

export class MidiOut implements VoiceSink {
  access: MIDIAccess | null = null
  private alloc = new ChannelAllocator()
  private active = new Map<number, VoiceState>()
  onDevicesChanged: (() => void) | null = null

  constructor(private store: Store) {}

  async init(): Promise<boolean> {
    if (!('requestMIDIAccess' in navigator)) return false
    try {
      this.access = await navigator.requestMIDIAccess({ sysex: false })
      this.access.onstatechange = () => this.onDevicesChanged?.()
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

  private port(): MIDIOutput | null {
    if (!this.access) return null
    const id = this.store.state.midi.outputId
    return this.access.outputs.get(id) ?? this.access.outputs.values().next().value ?? null
  }

  private send(bytes: number[]): void {
    try {
      this.port()?.send(bytes)
    } catch {
      // device vanished mid-performance — drop the message
    }
  }

  noteOn(id: number, pitch: number, vel: number): void {
    const ch = this.alloc.acquire(id)
    const noteNum = clamp(Math.round(pitch), 0, 127)
    const range = this.store.state.midi.bendRange
    const [lsb, msb] = bendBytes(pitch - noteNum, range)
    this.send([0xe0 | ch, lsb, msb])
    this.send([0x90 | ch, noteNum, clamp(Math.round(vel * 127), 1, 127)])
    this.active.set(id, { channel: ch, noteNum })
  }

  glide(id: number, pitch: number): void {
    const v = this.active.get(id)
    if (!v) return
    const range = this.store.state.midi.bendRange
    const [lsb, msb] = bendBytes(pitch - v.noteNum, range)
    this.send([0xe0 | v.channel, lsb, msb])
  }

  pressure(id: number, value: number): void {
    const v = this.active.get(id)
    if (!v) return
    const val = clamp(Math.round(value * 127), 0, 127)
    this.send([0xd0 | v.channel, val])
    if (this.store.state.midi.sendY) this.send([0xb0 | v.channel, 74, val])
  }

  noteOff(id: number): void {
    const v = this.active.get(id)
    if (!v) return
    this.send([0x80 | v.channel, v.noteNum, 0])
    this.alloc.release(id)
    this.active.delete(id)
  }

  allOff(): void {
    for (const id of [...this.active.keys()]) this.noteOff(id)
    for (let ch = 0; ch < 16; ch++) this.send([0xb0 | ch, 123, 0])
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
  }

  handle(data: Uint8Array | null): void {
    if (!data || data.length < 2 || !this.store.state.midi.inEnabled) return
    const status = data[0] & 0xf0
    const ch = data[0] & 0x0f
    const key = `${ch}:${data[1]}`
    if (status === 0x90 && data[2] > 0) {
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
