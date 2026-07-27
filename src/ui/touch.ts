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
 * - VIB: horizontal wiggle around a spring-loaded anchor bends the fretted
 *   note by up to ±depth semitones; the anchor trails the finger so a held
 *   offset re-centers (string-like vibrato with spring-back).
 */
import type { Layout, KeyShape } from '../core/layout'
import type { PadConfig } from '../core/state'
import type { VoiceSink } from '../audio/sink'
import { clampMidi } from '../core/notes'

/** Time for a sustained vibrato offset to relax back to the fretted pitch. */
const VIB_RECENTER_MS = 250

export interface ActiveTouch {
  id: number
  key: KeyShape
  currentRow: number
  startY: number
  pitch: number
  pressure: number
  x: number
  y: number
  /** Spring anchor for in-key vibrato; trails x to re-center the bend. */
  anchorX: number
  /** Current vibrato bend in semitones. */
  bend: number
  /** Nearest semitone last heard — fret-crossing haptics fire on change. */
  lastSemi: number
  lastMs: number
}

export interface TouchTrackerOptions {
  getLayout: () => Layout
  getPad: () => PadConfig
  sink: VoiceSink
  onChange?: () => void
  /** Fires at event time for every note onset (down or drag retrigger). */
  onTrigger?: (key: KeyShape) => void
  /** Fires whenever a voice crosses onto a new semitone (fret haptics). */
  onFret?: () => void
  now?: () => number
}

export class TouchTracker {
  readonly active = new Map<number, ActiveTouch>()

  private getLayout: () => Layout
  private getPad: () => PadConfig
  private sink: VoiceSink
  private onChange: () => void
  private onTrigger: (key: KeyShape) => void
  private onFret: () => void
  private now: () => number

  constructor(opts: TouchTrackerOptions) {
    this.getLayout = opts.getLayout
    this.getPad = opts.getPad
    this.sink = opts.sink
    this.onChange = opts.onChange ?? (() => {})
    this.onTrigger = opts.onTrigger ?? (() => {})
    this.onFret = opts.onFret ?? (() => {})
    this.now = opts.now
      ?? (() => (typeof performance !== 'undefined' ? performance.now() : Date.now()))
  }

  down(id: number, x: number, y: number): void {
    const layout = this.getLayout()
    const pad = this.getPad()
    const key = layout.hitTest(x, y)
    if (!key) return
    if (this.active.has(id)) this.up(id)
    const vel = pad.touchVel ? velocityFromKey(key, y) : 0.8
    const touch: ActiveTouch = {
      id, key, currentRow: key.row, startY: y, pitch: key.note, pressure: 0, x, y,
      anchorX: x, bend: 0, lastSemi: Math.round(key.note), lastMs: this.now(),
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

    // Vibrato only makes sense when pitch is otherwise quantized — discrete
    // keys or fretted slides. A free slide already follows the finger.
    const vibrato = pad.vibrato > 0 && (pad.slide === 0 || pad.frets)
    if (vibrato) {
      const t = this.now()
      const dt = Math.max(0, t - touch.lastMs)
      touch.lastMs = t
      touch.anchorX += (x - touch.anchorX) * (1 - Math.exp(-dt / VIB_RECENTER_MS))
      const span = Math.max(1, touch.key.w)
      touch.bend = Math.max(-1, Math.min(1, (x - touch.anchorX) / span)) * pad.vibrato
    }

    if (pad.slide > 0) {
      // Adopt the row beneath the finger before calculating pitch. Keeping the
      // same touch id makes row changes portamento glides rather than retriggers.
      const over = layout.hitTest(x, y)
      if (over) {
        touch.currentRow = over.row
        touch.key = over
      }
      let pitch = layout.pitchAt(x, touch.currentRow)
      if (pad.frets) pitch = Math.round(pitch) + (vibrato ? touch.bend : 0)
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
        touch.anchorX = x
        touch.bend = 0
        this.sink.noteOn(id, clampMidi(over.note), vel)
        this.onTrigger(over)
      } else if (vibrato) {
        const pitch = clampMidi(touch.key.note + touch.bend)
        if (pitch !== touch.pitch) {
          touch.pitch = pitch
          this.sink.glide(id, pitch)
        }
      }
    }

    const semi = Math.round(touch.pitch)
    if (semi !== touch.lastSemi) {
      touch.lastSemi = semi
      this.onFret()
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
