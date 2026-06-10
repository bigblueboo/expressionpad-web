import { beforeEach, describe, expect, it } from 'vitest'
import { buildLayout, KBD_ROWS, type Layout, type LayoutParams } from '../src/core/layout'
import { SCALES } from '../src/core/scales'
import { KeyboardInput } from '../src/ui/keyboard'
import { TouchTracker } from '../src/ui/touch'
import type { PadConfig } from '../src/core/state'
import type { VoiceSink } from '../src/audio/sink'

const base: LayoutParams = {
  kind: 'kbd-chromatic', rows: 4, cols: 12, width: 1250, height: 400,
  baseNote: 48, rowOffsets: [0, 5, 10, 15], scale: SCALES.Chromatic,
}

function keyByCode(layout: Layout, code: string) {
  const k = layout.keys.find((k) => k.code === code)
  if (!k) throw new Error(`no key for ${code}`)
  return k
}

describe('kbd-chromatic layout', () => {
  const layout = buildLayout(base)

  it('maps every non-modifier key across the four rows', () => {
    expect(layout.keys).toHaveLength(10 + 11 + 12 + 12)
    expect(new Set(layout.keys.map((k) => k.code)).size).toBe(45)
  })

  it('walks the bottom row chromatically: z x c v → C C# D Eb', () => {
    expect(keyByCode(layout, 'KeyZ').note).toBe(48) // C3
    expect(keyByCode(layout, 'KeyX').note).toBe(49)
    expect(keyByCode(layout, 'KeyC').note).toBe(50)
    expect(keyByCode(layout, 'KeyV').note).toBe(51)
  })

  it('offsets upper rows by the row tuning', () => {
    expect(keyByCode(layout, 'KeyA').note).toBe(53) // +5 fourths
    expect(keyByCode(layout, 'KeyQ').note).toBe(58)
    expect(keyByCode(layout, 'Digit1').note).toBe(63)
  })

  it('honors the column scale', () => {
    const pent = buildLayout({ ...base, scale: SCALES['Major Pentatonic'] })
    expect(keyByCode(pent, 'KeyZ').note).toBe(48)
    expect(keyByCode(pent, 'KeyX').note).toBe(50)
    expect(keyByCode(pent, 'KeyC').note).toBe(52)
    expect(keyByCode(pent, 'KeyV').note).toBe(55)
  })

  it('staggers rows like a physical keyboard', () => {
    const z = keyByCode(layout, 'KeyZ')
    const a = keyByCode(layout, 'KeyA')
    const q = keyByCode(layout, 'KeyQ')
    expect(a.x).toBeLessThan(z.x)
    expect(q.x).toBeLessThan(a.x)
  })

  it('hit-tests keycaps and shows keycap chars', () => {
    const m = keyByCode(layout, 'KeyM')
    expect(layout.hitTest(m.cx, m.cy)?.code).toBe('KeyM')
    expect(m.char).toBe('m')
  })
})

describe('kbd-piano layout', () => {
  const layout = buildLayout({ ...base, kind: 'kbd-piano', rowOffsets: [0, 12] })

  it('z x c are C D E and s d are C# Eb', () => {
    expect(keyByCode(layout, 'KeyZ').note).toBe(48) // C3
    expect(keyByCode(layout, 'KeyX').note).toBe(50) // D3
    expect(keyByCode(layout, 'KeyC').note).toBe(52) // E3
    expect(keyByCode(layout, 'KeyS').note).toBe(49) // C#3
    expect(keyByCode(layout, 'KeyD').note).toBe(51) // Eb3
  })

  it('leaves gaps where the piano has no black key', () => {
    // E–F boundary: no black key above c/v → KeyF is unmapped.
    expect(layout.keys.find((k) => k.code === 'KeyF')).toBeUndefined()
    expect(keyByCode(layout, 'KeyG').note).toBe(54) // F#3
  })

  it('white and black kinds drive piano coloring', () => {
    expect(keyByCode(layout, 'KeyZ').kind).toBe('white')
    expect(keyByCode(layout, 'KeyS').kind).toBe('black')
  })

  it('second pair sits at the configured row offset', () => {
    expect(keyByCode(layout, 'KeyQ').note).toBe(60) // C4 with +12
    expect(keyByCode(layout, 'Digit2').note).toBe(61) // C#4
  })

  it('has 10 whites per pair and blacks only at 2-semitone gaps', () => {
    const whites = layout.keys.filter((k) => k.kind === 'white')
    const blacks = layout.keys.filter((k) => k.kind === 'black')
    expect(whites).toHaveLength(20)
    expect(blacks).toHaveLength(14) // 7 per CDEFGABCDE span
  })
})

describe('KeyboardInput', () => {
  class SpySink implements VoiceSink {
    ons: number[] = []
    offs = 0
    noteOn(_id: number, pitch: number) { this.ons.push(pitch) }
    glide() {}
    pressure() {}
    noteOff() { this.offs++ }
    allOff() {}
  }

  let layout: Layout
  let sink: SpySink
  let kb: KeyboardInput
  let tracker: TouchTracker

  const pad: PadConfig = {
    layout: 'kbd-chromatic', rows: 4, cols: 12, rowTuning: 'Fourths [+5]',
    colScale: 'Chromatic', baseNote: 48, slide: 0, frets: false,
    touchVel: false, aftertouch: false,
  }

  beforeEach(() => {
    layout = buildLayout(base)
    sink = new SpySink()
    tracker = new TouchTracker(() => layout, () => pad, sink)
    kb = new KeyboardInput(() => layout, tracker)
  })

  const down = (code: string, opts: KeyboardEventInit = {}) =>
    kb.onKeyDown(new KeyboardEvent('keydown', { code, ...opts }))
  const up = (code: string) => kb.onKeyUp(new KeyboardEvent('keyup', { code }))

  it('keydown plays the mapped note, keyup releases it', () => {
    down('KeyZ')
    expect(sink.ons).toEqual([48])
    expect(tracker.active.size).toBe(1)
    up('KeyZ')
    expect(sink.offs).toBe(1)
    expect(tracker.active.size).toBe(0)
  })

  it('supports chords across rows', () => {
    down('KeyZ')
    down('KeyC')
    down('KeyA')
    expect(sink.ons).toEqual([48, 50, 53])
    up('KeyC')
    expect(tracker.active.size).toBe(2)
  })

  it('ignores auto-repeat and modifier combos', () => {
    down('KeyZ', { repeat: true })
    down('KeyZ', { metaKey: true })
    down('KeyZ', { ctrlKey: true })
    expect(sink.ons).toEqual([])
  })

  it('ignores unmapped keys', () => {
    down('Space')
    down('Enter')
    down('ShiftLeft')
    expect(sink.ons).toEqual([])
  })

  it('recovers from stale held state after a layout reset', () => {
    down('KeyZ')
    tracker.cancelAll() // e.g. layout rebuilt while key held
    down('KeyZ') // keyup was never seen; must restart cleanly
    expect(sink.ons).toEqual([48, 48])
    expect(tracker.active.size).toBe(1)
  })

  it('releaseAll silences held keys (window blur)', () => {
    down('KeyZ')
    down('KeyX')
    kb.releaseAll()
    expect(tracker.active.size).toBe(0)
    expect(kb.active.size).toBe(0)
  })

  it('does not steal keys from form fields', () => {
    const input = document.createElement('input')
    document.body.appendChild(input)
    const e = new KeyboardEvent('keydown', { code: 'KeyZ' })
    Object.defineProperty(e, 'target', { value: input })
    kb.onKeyDown(e)
    expect(sink.ons).toEqual([])
    input.remove()
  })

  it('every KBD_ROWS code is unique and well-formed', () => {
    const all = KBD_ROWS.flatMap((r) => r.codes)
    expect(new Set(all).size).toBe(all.length)
    for (const r of KBD_ROWS) expect(r.codes.length).toBe(r.chars.length)
  })
})
