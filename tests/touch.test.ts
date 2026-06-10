import { beforeEach, describe, expect, it } from 'vitest'
import { buildLayout, type Layout } from '../src/core/layout'
import { SCALES } from '../src/core/scales'
import { TouchTracker, touchesToPad, velocityFromKey } from '../src/ui/touch'
import type { PadConfig } from '../src/core/state'
import type { VoiceSink } from '../src/audio/sink'

type Call = [string, ...number[]]

class SpySink implements VoiceSink {
  calls: Call[] = []
  noteOn(id: number, pitch: number, vel: number) { this.calls.push(['on', id, pitch, vel]) }
  glide(id: number, pitch: number) { this.calls.push(['glide', id, pitch]) }
  pressure(id: number, value: number) { this.calls.push(['pressure', id, value]) }
  noteOff(id: number) { this.calls.push(['off', id]) }
  allOff() { this.calls.push(['allOff']) }
  ofType(t: string) { return this.calls.filter((c) => c[0] === t) }
}

function makePad(over: Partial<PadConfig> = {}): PadConfig {
  return {
    layout: 'square', rows: 4, cols: 12, rowTuning: 'Fourths [+5]',
    colScale: 'Chromatic', baseNote: 48, slide: 0, frets: false,
    touchVel: false, aftertouch: false, ...over,
  }
}

function makeLayout(): Layout {
  return buildLayout({
    kind: 'square', rows: 4, cols: 12, width: 1200, height: 400,
    baseNote: 48, rowOffsets: [0, 5, 10, 15], scale: SCALES.Chromatic,
  })
}

describe('TouchTracker', () => {
  let sink: SpySink
  let pad: PadConfig
  let tracker: TouchTracker
  const layout = makeLayout()

  beforeEach(() => {
    sink = new SpySink()
    pad = makePad()
    tracker = new TouchTracker(() => layout, () => pad, sink)
  })

  it('starts a voice on touch down at the key pitch', () => {
    tracker.down(1, 50, 390) // bottom-left key, C3 = 48
    expect(sink.calls).toEqual([['on', 1, 48, 0.8]])
  })

  it('ignores touches that miss the surface', () => {
    tracker.down(1, -10, 50)
    expect(sink.calls).toHaveLength(0)
  })

  it('tracks independent simultaneous touches', () => {
    tracker.down(1, 50, 390)
    tracker.down(2, 150, 390)
    tracker.down(3, 50, 10)
    expect(sink.ofType('on')).toHaveLength(3)
    tracker.up(2)
    expect(sink.ofType('off')).toEqual([['off', 2]])
    expect(tracker.active.size).toBe(2)
  })

  it('retriggers discrete notes when slide is 0', () => {
    tracker.down(1, 50, 390)
    tracker.move(1, 150, 390) // next column
    expect(sink.ofType('off')).toHaveLength(1)
    expect(sink.ofType('on')).toHaveLength(2)
    expect(sink.ofType('on')[1][2]).toBe(49)
    expect(sink.ofType('glide')).toHaveLength(0)
  })

  it('glides continuously when slide > 0', () => {
    pad.slide = 0.5
    tracker.down(1, 50, 390)
    tracker.move(1, 150, 390)
    expect(sink.ofType('on')).toHaveLength(1)
    const glides = sink.ofType('glide')
    expect(glides.length).toBeGreaterThan(0)
    expect(glides[glides.length - 1][2]).toBeCloseTo(49, 1)
  })

  it('produces fractional pitches mid-key while sliding', () => {
    pad.slide = 0.5
    tracker.down(1, 50, 390)
    tracker.move(1, 100, 390) // halfway between key centers
    const p = sink.ofType('glide')[0][2]
    expect(p).toBeGreaterThan(48)
    expect(p).toBeLessThan(49)
    expect(Number.isInteger(p)).toBe(false)
  })

  it('snaps slid pitch to semitones when frets is on', () => {
    pad.slide = 0.5
    pad.frets = true
    tracker.down(1, 50, 390)
    tracker.move(1, 110, 390)
    for (const g of sink.ofType('glide')) {
      expect(Number.isInteger(g[2])).toBe(true)
    }
  })

  it('locks slide pitch to the origin row', () => {
    pad.slide = 0.5
    tracker.down(1, 50, 390) // bottom row
    tracker.move(1, 50, 10) // drag to top row
    // Pitch should stay near the origin row's pitch (48), not jump +15.
    const glides = sink.ofType('glide')
    for (const g of glides) expect(g[2]).toBeLessThan(50)
  })

  it('derives velocity from vertical position when touchVel is on', () => {
    pad.touchVel = true
    tracker.down(1, 50, 399) // very bottom of bottom key → loud
    tracker.down(2, 50, 301) // top of bottom key → soft
    const ons = sink.ofType('on')
    expect(ons[0][3]).toBeGreaterThan(0.9)
    expect(ons[1][3]).toBeLessThan(0.4)
  })

  it('sends pressure on upward drag when aftertouch is on', () => {
    pad.aftertouch = true
    tracker.down(1, 50, 390)
    tracker.move(1, 50, 330)
    const ps = sink.ofType('pressure')
    expect(ps.length).toBeGreaterThan(0)
    expect(ps[ps.length - 1][2]).toBeGreaterThan(0.2)
    expect(ps[ps.length - 1][2]).toBeLessThanOrEqual(1)
  })

  it('does not send pressure when aftertouch is off', () => {
    tracker.down(1, 50, 390)
    tracker.move(1, 50, 300)
    expect(sink.ofType('pressure')).toHaveLength(0)
  })

  it('ends the voice on up and ignores duplicate ups', () => {
    tracker.down(1, 50, 390)
    tracker.up(1)
    tracker.up(1)
    expect(sink.ofType('off')).toHaveLength(1)
  })

  it('cancelAll silences everything', () => {
    tracker.down(1, 50, 390)
    tracker.down(2, 250, 390)
    tracker.cancelAll()
    expect(sink.ofType('allOff')).toHaveLength(1)
    expect(tracker.active.size).toBe(0)
  })

  it('velocityFromKey maps bottom loud, top soft', () => {
    const key = layout.keys[0]
    expect(velocityFromKey(key, key.y + key.h)).toBeCloseTo(1)
    expect(velocityFromKey(key, key.y)).toBeCloseTo(0.25)
  })

  it('touchesToPad converts a whole changedTouches batch to local coords', () => {
    // Rapidly alternating touches arrive batched — every one must survive.
    const batch = [
      { identifier: 101, clientX: 60, clientY: 400 },
      { identifier: 102, clientX: 160, clientY: 410 },
      { identifier: 103, clientX: 260, clientY: 420 },
    ]
    const pts = touchesToPad(batch, { left: 10, top: 20 })
    expect(pts).toEqual([
      { id: 101, x: 50, y: 380 },
      { id: 102, x: 150, y: 390 },
      { id: 103, x: 250, y: 400 },
    ])
  })

  it('a batched multi-touch start produces one voice per contact', () => {
    const batch = [
      { identifier: 7, clientX: 50, clientY: 390 },
      { identifier: 8, clientX: 250, clientY: 390 },
    ]
    for (const t of touchesToPad(batch, { left: 0, top: 0 })) {
      tracker.down(t.id, t.x, t.y)
    }
    expect(sink.ofType('on')).toHaveLength(2)
    expect(tracker.active.size).toBe(2)
  })
})
