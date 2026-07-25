/**
 * TouchTracker — translates pointer events on the pad surface into voice
 * events. Pure logic (no DOM/canvas) so it is fully unit-testable.
 *
 * Behavior, matching the original app:
 * - Each touch is an independent voice (continuous multi-touch).
 * - slide = 0: dragging across keys retriggers discrete notes.
 * - slide > 0: pitch follows the finger continuously across columns and rows;
 *   FRETS snaps the slid pitch to semitones.
 * - TCH VEL: velocity from vertical position within the key at onset.
 * - AFTERTOUCH: vertical movement after onset becomes pressure 0..1.
 */
import type { Layout, KeyShape } from '../core/layout'
import type { PadConfig } from '../core/state'
import type { VoiceSink } from '../audio/sink'
import { clampMidi } from '../core/notes'

export interface ActiveTouch {
  id: number
  key: KeyShape
  currentRow: number
  startY: number
  pitch: number
  pressure: number
  x: number
  y: number
}

export class TouchTracker {
  readonly active = new Map<number, ActiveTouch>()

  constructor(
    private getLayout: () => Layout,
    private getPad: () => PadConfig,
    private sink: VoiceSink,
    private onChange: () => void = () => {},
    /** Fires at event time for every note onset (down or drag retrigger). */
    private onTrigger: (key: KeyShape) => void = () => {},
  ) {}

  down(id: number, x: number, y: number): void {
    const layout = this.getLayout()
    const pad = this.getPad()
    const key = layout.hitTest(x, y)
    if (!key) return
    if (this.active.has(id)) this.up(id)
    const vel = pad.touchVel ? velocityFromKey(key, y) : 0.8
    const touch: ActiveTouch = {
      id, key, currentRow: key.row, startY: y, pitch: key.note, pressure: 0, x, y,
    }
    this.active.set(id, touch)
    this.sink.noteOn(id, clampMidi(key.note), vel)
    this.onTrigger(key)
    this.onChange()
  }

  move(id: number, x: number, y: number): void {
    const touch = this.active.get(id)
    if (!touch) return
    const layout = this.getLayout()
    const pad = this.getPad()
    touch.x = x
    touch.y = y

    if (pad.slide > 0) {
      // Adopt the row beneath the finger before calculating pitch. Keeping the
      // same touch id makes row changes portamento glides rather than retriggers.
      const over = layout.hitTest(x, y)
      if (over) {
        touch.currentRow = over.row
        touch.key = over
      }
      let pitch = layout.pitchAt(x, touch.currentRow)
      if (pad.frets) pitch = Math.round(pitch)
      pitch = clampMidi(pitch)
      if (pitch !== touch.pitch) {
        touch.pitch = pitch
        this.sink.glide(id, pitch)
      }
    } else {
      const over = layout.hitTest(x, y)
      if (over && over.id !== touch.key.id) {
        this.sink.noteOff(id)
        const vel = pad.touchVel ? velocityFromKey(over, y) : 0.8
        touch.key = over
        touch.currentRow = over.row
        touch.startY = y
        touch.pitch = over.note
        touch.pressure = 0
        this.sink.noteOn(id, clampMidi(over.note), vel)
        this.onTrigger(over)
      }
    }

    if (pad.aftertouch) {
      // Moving up from the onset point increases pressure.
      const range = layout.rowHeight * 1.2
      const pressure = Math.min(1, Math.max(0, (touch.startY - y) / range))
      if (Math.abs(pressure - touch.pressure) > 0.01) {
        touch.pressure = pressure
        this.sink.pressure(id, pressure)
      }
    }
    this.onChange()
  }

  up(id: number): void {
    if (!this.active.has(id)) return
    this.active.delete(id)
    this.sink.noteOff(id)
    this.onChange()
  }

  cancelAll(): void {
    this.active.clear()
    this.sink.allOff()
    this.onChange()
  }
}

export interface TouchPoint {
  identifier: number
  clientX: number
  clientY: number
}

/** Map a TouchList-like batch to pad-local coordinates. */
export function touchesToPad(
  list: ArrayLike<TouchPoint>,
  rect: { left: number; top: number },
): Array<{ id: number; x: number; y: number }> {
  const out: Array<{ id: number; x: number; y: number }> = []
  for (let i = 0; i < list.length; i++) {
    const t = list[i]
    out.push({ id: t.identifier, x: t.clientX - rect.left, y: t.clientY - rect.top })
  }
  return out
}

/** Velocity from vertical position within the key: bottom = loud, top = soft. */
export function velocityFromKey(key: KeyShape, y: number): number {
  const local = (y - key.y) / key.h
  return Math.min(1, Math.max(0.05, 0.25 + 0.75 * local))
}
