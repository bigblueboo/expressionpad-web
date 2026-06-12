import { describe, expect, it } from 'vitest'
import { buildLayout, type Layout, type LayoutParams } from '../src/core/layout'
import { SCALES } from '../src/core/scales'
import { BrightnessField } from '../src/ui/field'

const square: LayoutParams = {
  kind: 'square', rows: 8, cols: 8, width: 800, height: 800,
  baseNote: 48, rowOffsets: [0, 5, 10, 15, 20, 25, 30, 35], scale: SCALES.Chromatic,
}

function keyAt(layout: Layout, row: number, col: number) {
  const k = layout.keys.find((k) => k.row === row && k.col === col && k.kind !== 'black')
  if (!k) throw new Error(`no key at ${row},${col}`)
  return k
}

/** Advance in frame-sized steps like the renderer does. */
function run(field: BrightnessField, seconds: number) {
  const frames = Math.round(seconds * 60)
  for (let i = 0; i < frames; i++) field.step(1 / 60)
}

describe('BrightnessField', () => {
  it('a poke brightens the touched key immediately', () => {
    const layout = buildLayout(square)
    const field = new BrightnessField(layout.keys)
    const center = keyAt(layout, 4, 4)
    field.poke(center.id)
    expect(field.get(center.id)).toBeCloseTo(1)
    expect(field.energy).toBeGreaterThan(0)
  })

  it('brightness propagates to neighbors, near before far', () => {
    const layout = buildLayout(square)
    const field = new BrightnessField(layout.keys)
    field.poke(keyAt(layout, 4, 4).id)
    run(field, 0.1)
    const near = field.get(keyAt(layout, 4, 5).id)
    const far = field.get(keyAt(layout, 4, 7).id)
    expect(near).toBeGreaterThan(0.02)
    expect(near).toBeGreaterThan(far)
  })

  it('the wave eventually reaches the whole grid', () => {
    const layout = buildLayout(square)
    const field = new BrightnessField(layout.keys)
    field.poke(keyAt(layout, 4, 4).id)
    let cornerPeak = 0
    for (let i = 0; i < 90; i++) {
      field.step(1 / 60)
      cornerPeak = Math.max(cornerPeak, Math.abs(field.get(keyAt(layout, 0, 0).id)))
    }
    expect(cornerPeak).toBeGreaterThan(0.005)
  })

  it('spreads symmetrically from a center poke', () => {
    const layout = buildLayout(square)
    const field = new BrightnessField(layout.keys)
    field.poke(keyAt(layout, 4, 4).id)
    run(field, 0.15)
    const left = field.get(keyAt(layout, 4, 3).id)
    const right = field.get(keyAt(layout, 4, 5).id)
    expect(left).toBeCloseTo(right, 3)
  })

  it('decays back to stillness', () => {
    const layout = buildLayout(square)
    const field = new BrightnessField(layout.keys)
    field.poke(keyAt(layout, 4, 4).id)
    run(field, 8)
    expect(field.energy).toBeLessThan(0.002)
  })

  it('stays finite and bounded under touch spam', () => {
    const layout = buildLayout(square)
    const field = new BrightnessField(layout.keys)
    for (let i = 0; i < 200; i++) {
      field.poke(layout.keys[i % layout.keys.length].id, 1)
      field.step(1 / 60)
    }
    for (const k of layout.keys) {
      const v = field.get(k.id)
      expect(Number.isFinite(v)).toBe(true)
      expect(Math.abs(v)).toBeLessThanOrEqual(2)
    }
  })

  it('works on every layout kind', () => {
    const kinds: LayoutParams['kind'][] = ['square', 'hex', 'piano', 'kbd-chromatic', 'kbd-piano']
    for (const kind of kinds) {
      const layout = buildLayout({ ...square, kind, rows: kind.startsWith('kbd') ? 4 : 4 })
      const field = new BrightnessField(layout.keys)
      const first = layout.keys[0]
      field.poke(first.id)
      run(field, 0.2)
      const someNeighborLit = layout.keys.some(
        (k) => k.id !== first.id && field.get(k.id) > 0.01,
      )
      expect(someNeighborLit, kind).toBe(true)
      for (const k of layout.keys) expect(Number.isFinite(field.get(k.id)), kind).toBe(true)
    }
  })

  it('ignores pokes and reads for unknown key ids', () => {
    const layout = buildLayout(square)
    const field = new BrightnessField(layout.keys)
    field.poke(99999)
    expect(field.get(99999)).toBe(0)
    expect(field.energy).toBeGreaterThanOrEqual(0)
  })
})
