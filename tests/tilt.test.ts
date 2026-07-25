import { describe, expect, it } from 'vitest'
import { TiltSource } from '../src/ui/tilt'

function rig() {
  const seen: number[] = []
  let clock = 0
  const tilt = new TiltSource((v) => seen.push(v), () => clock)
  return { seen, tilt, tick: (ms = 40) => (clock += ms) }
}

describe('TiltSource', () => {
  it('maps device attitude to uprightness 0..1 in any rotation', () => {
    const flat = rig()
    flat.tilt.handle(0, 0) // flat on a table
    expect(flat.seen.at(-1)).toBeCloseTo(0)

    // Screen vertical, portrait: smoothing walks toward 1.
    const portrait = rig()
    for (let i = 0; i < 60; i++) {
      portrait.tick()
      portrait.tilt.handle(90, 0)
    }
    expect(portrait.seen.at(-1)).toBeGreaterThan(0.95)

    // Screen vertical, landscape (gamma) reads the same.
    const landscape = rig()
    for (let i = 0; i < 60; i++) {
      landscape.tick()
      landscape.tilt.handle(0, 90)
    }
    expect(landscape.seen.at(-1)).toBeGreaterThan(0.95)
  })

  it('rate-limits emissions but keeps smoothing between them', () => {
    const { seen, tilt, tick } = rig()
    tilt.handle(90, 0)
    tilt.handle(90, 0) // same instant — suppressed
    tilt.handle(90, 0)
    expect(seen).toHaveLength(1)
    tick()
    tilt.handle(90, 0)
    expect(seen).toHaveLength(2)
    expect(seen[1]).toBeGreaterThan(seen[0]) // smoothing advanced regardless
  })

  it('ignores null readings', () => {
    const { seen, tilt } = rig()
    tilt.handle(null, null)
    expect(seen).toHaveLength(0)
  })
})
