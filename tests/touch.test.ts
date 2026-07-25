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
    touchVel: false, aftertouch: false,
    mirror: false, mirrorOffset: 0, vibrato: 0, haptics: 0, ...over,
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

  it('fires onTrigger at event time for downs and drag retriggers', () => {
    const triggered: number[] = []
    tracker = new TouchTracker(
      () => layout, () => pad, sink, () => {}, (key) => triggered.push(key.note),
    )
    tracker.down(1, 50, 390) // C3
    tracker.up(1) // sub-frame tap: trigger already recorded
    expect(triggered).toEqual([48])
    tracker.down(2, 50, 390)
    tracker.move(2, 150, 390) // slide=0 → retrigger on the next key
    expect(triggered).toEqual([48, 48, 49])
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

  it('does not inject new ripple energy while continuously crossing keys', () => {
    pad.slide = 0.5
    const triggered: number[] = []
    tracker = new TouchTracker(
      () => layout, () => pad, sink, () => {}, (key) => triggered.push(key.id),
    )
    tracker.down(1, 50, 390)
    tracker.move(1, 150, 390)
    tracker.move(1, 250, 390)
    tracker.move(1, 350, 390)
    expect(triggered).toHaveLength(1)
    expect(sink.ofType('glide').length).toBeGreaterThan(0)
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

  it('glides across rows without retriggering the voice', () => {
    pad.slide = 0.5
    tracker.down(1, 50, 390) // bottom row
    tracker.move(1, 50, 10) // drag to top row
    const glides = sink.ofType('glide')
    expect(glides[glides.length - 1]).toEqual(['glide', 1, 63])
    expect(sink.ofType('on')).toHaveLength(1)
    expect(sink.ofType('off')).toHaveLength(0)
    expect(tracker.active.get(1)?.key.row).toBe(3)

    tracker.move(1, 50, 390) // glide back to the bottom row
    expect(sink.ofType('glide').at(-1)).toEqual(['glide', 1, 48])
    expect(sink.ofType('on')).toHaveLength(1)
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

describe('in-key vibrato and fret crossings', () => {
  let sink: SpySink
  let pad: PadConfig
  let frets = 0
  let clock = 0
  let tracker: TouchTracker
  const layout = makeLayout()

  const make = () =>
    new TouchTracker(
      () => layout, () => pad, sink, () => {}, () => {}, () => frets++, () => clock,
    )

  beforeEach(() => {
    sink = new SpySink()
    pad = makePad({ vibrato: 1 })
    frets = 0
    clock = 0
    tracker = make()
  })

  it('bends within the key on horizontal wiggle (slide off)', () => {
    tracker.down(1, 50, 390) // C3 at the key center
    clock += 16
    tracker.move(1, 80, 390) // wiggle right, still inside key 0
    const glides = sink.ofType('glide')
    expect(glides.length).toBeGreaterThan(0)
    const p = glides.at(-1)![2]
    expect(p).toBeGreaterThan(48)
    expect(p).toBeLessThan(49)
    expect(sink.ofType('on')).toHaveLength(1) // no retrigger
  })

  it('springs back to the fretted pitch when the offset is held', () => {
    tracker.down(1, 50, 390)
    clock += 16
    tracker.move(1, 80, 390)
    const bentPitch = sink.ofType('glide').at(-1)![2]
    expect(bentPitch).toBeGreaterThan(48.1)
    for (let i = 0; i < 12; i++) {
      clock += 200
      tracker.move(1, 80, 390) // hold position — anchor catches up
    }
    const settled = sink.ofType('glide').at(-1)![2]
    expect(settled).toBeGreaterThan(48 - 1e-6)
    expect(settled).toBeLessThan(48.03)
  })

  it('scales bend depth with the vibrato knob', () => {
    pad.vibrato = 0.25
    tracker.down(1, 50, 390)
    clock += 16
    tracker.move(1, 150, 390) // way past the key → bend clamps at depth
    // slide=0 crossing a key retriggers instead; stay inside the key:
    sink.calls.length = 0
    tracker.up(1)
    tracker.down(2, 50, 390)
    clock += 16
    tracker.move(2, 95, 390)
    const p = sink.ofType('glide').at(-1)![2]
    expect(p - 48).toBeLessThanOrEqual(0.25 + 1e-9)
  })

  it('resets the bend anchor on drag retrigger', () => {
    tracker.down(1, 50, 390)
    clock += 16
    tracker.move(1, 150, 390) // into the next key → retrigger, anchor reset
    const on = sink.ofType('on').at(-1)!
    expect(on[2]).toBe(49)
    clock += 16
    tracker.move(1, 151, 390) // negligible wiggle after reset
    const glidesAfter = sink.ofType('glide')
    if (glidesAfter.length > 0) {
      expect(Math.abs(glidesAfter.at(-1)![2] - 49)).toBeLessThan(0.05)
    }
  })

  it('adds vibrato on top of fretted slides', () => {
    pad.slide = 0.5
    pad.frets = true
    tracker.down(1, 50, 390)
    clock += 16
    tracker.move(1, 80, 390)
    const p = sink.ofType('glide').at(-1)![2]
    expect(Number.isInteger(p)).toBe(false)
    expect(Math.abs(p - 48)).toBeLessThan(1)
  })

  it('ignores vibrato during free (unfretted) slides', () => {
    pad.slide = 0.5
    pad.frets = false
    tracker.down(1, 50, 390)
    clock += 16
    tracker.move(1, 100, 390)
    const p = sink.ofType('glide').at(-1)![2]
    expect(p).toBeCloseTo(48.5) // pure interpolation, no bend term
  })

  it('fires the fret callback on semitone crossings while sliding', () => {
    pad = makePad({ slide: 0.5 })
    tracker.down(1, 50, 390)
    expect(frets).toBe(0) // onset is not a crossing
    tracker.move(1, 150, 390) // 48 → 49 crosses one boundary
    expect(frets).toBe(1)
    tracker.move(1, 350, 390) // 49 → 51
    expect(frets).toBe(2) // one event per move batch is enough for haptics
  })

  it('fires the fret callback on discrete drag retriggers', () => {
    pad = makePad()
    tracker.down(1, 50, 390)
    tracker.move(1, 150, 390)
    expect(frets).toBe(1)
  })
})
