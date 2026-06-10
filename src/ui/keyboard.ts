/**
 * KeyboardInput — plays the pad from a typing keyboard. Keydown/keyup on a
 * key mapped by the current layout (the kbd-* layouts assign
 * KeyboardEvent.code values to keycaps) synthesize touches at the keycap
 * center, so keyboard notes get the same voicing, glow, and ripples as
 * fingers. Other layouts assign no codes, so typing is inert there.
 */
import type { Layout } from '../core/layout'
import type { TouchTracker } from './touch'

const VOICE_ID_BASE = 2_000_000

function isEditable(target: EventTarget | null): boolean {
  if (!(target instanceof HTMLElement)) return false
  return (
    target instanceof HTMLInputElement ||
    target instanceof HTMLTextAreaElement ||
    target instanceof HTMLSelectElement ||
    target.isContentEditable
  )
}

export class KeyboardInput {
  readonly active = new Map<string, number>()
  private nextId = VOICE_ID_BASE

  constructor(
    private getLayout: () => Layout,
    private tracker: TouchTracker,
  ) {}

  attach(target: Window): void {
    target.addEventListener('keydown', this.onKeyDown)
    target.addEventListener('keyup', this.onKeyUp)
    target.addEventListener('blur', this.releaseAll)
  }

  onKeyDown = (e: KeyboardEvent): void => {
    if (e.repeat || e.metaKey || e.ctrlKey || e.altKey) return
    if (isEditable(e.target)) return
    const key = this.getLayout().keys.find((k) => k.code === e.code)
    if (!key) return
    e.preventDefault()
    const stale = this.active.get(e.code)
    if (stale !== undefined) this.tracker.up(stale)
    const id = this.nextId++
    this.active.set(e.code, id)
    this.tracker.down(id, key.cx, key.cy)
  }

  onKeyUp = (e: KeyboardEvent): void => {
    const id = this.active.get(e.code)
    if (id === undefined) return
    this.active.delete(e.code)
    this.tracker.up(id)
  }

  releaseAll = (): void => {
    for (const id of this.active.values()) this.tracker.up(id)
    this.active.clear()
  }
}
