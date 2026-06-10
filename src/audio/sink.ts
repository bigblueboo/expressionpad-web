/**
 * VoiceSink: the contract between the touch surface and anything that makes
 * sound — the internal synth, MIDI out, or both via the Router.
 */
export interface VoiceSink {
  /** Start a voice. `pitch` is a (possibly fractional) MIDI note, vel 0..1. */
  noteOn(id: number, pitch: number, vel: number): void
  /** Continuous pitch update for an active voice. */
  glide(id: number, pitch: number): void
  /** Pressure/timbre update 0..1 (aftertouch). */
  pressure(id: number, value: number): void
  noteOff(id: number): void
  allOff(): void
}

/** Fans touch events out to whichever sinks are currently enabled. */
export class Router implements VoiceSink {
  private sinks: Array<{ sink: VoiceSink; enabled: () => boolean }> = []
  private active = new Map<number, VoiceSink[]>()

  add(sink: VoiceSink, enabled: () => boolean): void {
    this.sinks.push({ sink, enabled })
  }

  noteOn(id: number, pitch: number, vel: number): void {
    const targets = this.sinks.filter((s) => s.enabled()).map((s) => s.sink)
    this.active.set(id, targets)
    for (const t of targets) t.noteOn(id, pitch, vel)
  }

  glide(id: number, pitch: number): void {
    for (const t of this.active.get(id) ?? []) t.glide(id, pitch)
  }

  pressure(id: number, value: number): void {
    for (const t of this.active.get(id) ?? []) t.pressure(id, value)
  }

  noteOff(id: number): void {
    for (const t of this.active.get(id) ?? []) t.noteOff(id)
    this.active.delete(id)
  }

  allOff(): void {
    for (const { sink } of this.sinks) sink.allOff()
    this.active.clear()
  }
}
