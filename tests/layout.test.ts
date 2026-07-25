import { describe, expect, it } from 'vitest'
import { buildLayout, whiteNotesFrom, type LayoutParams } from '../src/core/layout'
import { SCALES } from '../src/core/scales'

const base: LayoutParams = {
  kind: 'square', rows: 4, cols: 12, width: 1200, height: 400,
  baseNote: 48, rowOffsets: [0, 5, 10, 15], scale: SCALES.Chromatic,
}

describe('square layout', () => {
  const layout = buildLayout(base)

  it('creates rows × cols keys', () => {
    expect(layout.keys).toHaveLength(48)
  })

  it('puts the base note at bottom-left', () => {
    const k = layout.hitTest(10, 390)!
    expect(k.note).toBe(48)
    expect(k.row).toBe(0)
    expect(k.col).toBe(0)
  })

  it('advances columns chromatically and rows by fourths', () => {
    expect(layout.hitTest(150, 390)!.note).toBe(49) // col 1, bottom row
    expect(layout.hitTest(10, 10)!.note).toBe(48 + 15) // top row
  })

  it('keys tile the surface with no gaps', () => {
    for (let x = 5; x < 1200; x += 97) {
      for (let y = 5; y < 400; y += 37) {
        expect(layout.hitTest(x, y)).not.toBeNull()
      }
    }
  })

  it('misses outside the surface', () => {
    expect(layout.hitTest(-5, 100)).toBeNull()
    expect(layout.hitTest(100, 500)).toBeNull()
  })

  it('continuous pitch is monotonic across a row', () => {
    let prev = -Infinity
    for (let x = 0; x <= 1200; x += 25) {
      const p = layout.pitchAt(x, 0)
      expect(p).toBeGreaterThanOrEqual(prev)
      prev = p
    }
  })

  it('continuous pitch matches key note at key center', () => {
    const k = layout.keys.find((k) => k.row === 1 && k.col === 5)!
    expect(layout.pitchAt(k.cx, 1)).toBeCloseTo(k.note)
  })

  it('respects column scales (major pentatonic)', () => {
    const pent = buildLayout({ ...base, scale: SCALES['Major Pentatonic'], cols: 6 })
    const bottom = pent.keys.filter((k) => k.row === 0).map((k) => k.note)
    expect(bottom).toEqual([48, 50, 52, 55, 57, 60])
  })
})

describe('hex layout', () => {
  const layout = buildLayout({ ...base, kind: 'hex', rows: 5, cols: 10 })

  it('creates rows × cols hexes with polygons', () => {
    expect(layout.keys).toHaveLength(50)
    for (const k of layout.keys) {
      expect(k.poly).toHaveLength(6)
    }
  })

  it('hits the hex at its own center', () => {
    for (const k of layout.keys) {
      expect(layout.hitTest(k.cx, k.cy)?.id).toBe(k.id)
    }
  })

  it('odd rows are offset by half a hex', () => {
    const r0 = layout.keys.find((k) => k.row === 0 && k.col === 0)!
    const r1 = layout.keys.find((k) => k.row === 1 && k.col === 0)!
    expect(r1.cx - r0.cx).toBeCloseTo(r0.w / 2, 1)
  })

  it('hexes fit within the surface', () => {
    for (const k of layout.keys) {
      expect(k.x).toBeGreaterThanOrEqual(-0.01)
      expect(k.x + k.w).toBeLessThanOrEqual(1200.01)
      expect(k.y).toBeGreaterThanOrEqual(-0.01)
      expect(k.y + k.h).toBeLessThanOrEqual(400.01)
    }
  })

  it('continuous pitch is monotonic across a row', () => {
    let prev = -Infinity
    for (let x = 0; x <= 1200; x += 30) {
      const p = layout.pitchAt(x, 2)
      expect(p).toBeGreaterThanOrEqual(prev)
      prev = p
    }
  })

  it('stretches to fill most of a mismatched aspect ratio (like the original)', () => {
    const wide = buildLayout({ ...base, kind: 'hex', rows: 6, cols: 14, width: 1024, height: 700 })
    const minY = Math.min(...wide.keys.map((k) => k.y))
    const maxY = Math.max(...wide.keys.map((k) => k.y + k.h))
    expect(maxY - minY).toBeGreaterThan(700 * 0.8)
  })

  it('keeps hit-testing exact under stretch', () => {
    const wide = buildLayout({ ...base, kind: 'hex', rows: 6, cols: 14, width: 1024, height: 700 })
    for (const k of wide.keys) {
      expect(wide.hitTest(k.cx, k.cy)?.id).toBe(k.id)
      // Just inside the top and bottom corners of the stretched hex.
      expect(wide.hitTest(k.cx, k.y + k.h * 0.06)?.id).toBe(k.id)
      expect(wide.hitTest(k.cx, k.y + k.h * 0.94)?.id).toBe(k.id)
    }
  })
})

describe('piano layout', () => {
  const layout = buildLayout({
    ...base, kind: 'piano', rows: 3, cols: 14, rowOffsets: [0, 12, 24],
  })

  it('generates white keys per row plus black keys at 2-semitone gaps', () => {
    const whites = layout.keys.filter((k) => k.kind === 'white')
    const blacks = layout.keys.filter((k) => k.kind === 'black')
    expect(whites).toHaveLength(42)
    // 14 whites starting at C cover two octaves: C..B C..B → 5+5 blacks.
    expect(blacks.filter((b) => b.row === 0)).toHaveLength(10)
  })

  it('white notes follow the C-major key pattern from C3', () => {
    expect(whiteNotesFrom(48, 8)).toEqual([48, 50, 52, 53, 55, 57, 59, 60])
  })

  it('starts on the first white note at or above the row base', () => {
    expect(whiteNotesFrom(49, 3)).toEqual([50, 52, 53]) // C#3 → D3
  })

  it('black keys take precedence in their zone', () => {
    const black = layout.keys.find((k) => k.kind === 'black' && k.row === 0)!
    expect(layout.hitTest(black.cx, black.y + black.h * 0.5)?.id).toBe(black.id)
  })

  it('white keys win below the black zone', () => {
    const black = layout.keys.find((k) => k.kind === 'black' && k.row === 0)!
    const below = layout.hitTest(black.cx, black.y + black.h + 10)
    expect(below?.kind).toBe('white')
  })

  it('stacks rows bottom-up by the row offset', () => {
    const bottomC = layout.hitTest(5, 395)!
    const topC = layout.hitTest(5, 5)!
    expect(topC.note - bottomC.note).toBe(24)
  })

  it('continuous pitch is monotonic across the row', () => {
    let prev = -Infinity
    for (let x = 0; x <= 1200; x += 20) {
      const p = layout.pitchAt(x, 0)
      expect(p).toBeGreaterThanOrEqual(prev)
      prev = p
    }
  })
})

describe('mirrored layout', () => {
  const layout = buildLayout({ ...base, mirror: true, mirrorOffset: 12 })

  it('doubles the key count and flags the layout', () => {
    expect(layout.keys).toHaveLength(96)
    expect(layout.mirrored).toBe(true)
  })

  it('keeps the left half identical to the unmirrored layout at half width', () => {
    const k = layout.hitTest(10, 390)!
    expect(k.note).toBe(48)
    expect(k.row).toBe(0)
    expect(k.col).toBe(0)
  })

  it('reflects geometry so both thumbs see the same shape', () => {
    for (const k of layout.keys.slice(0, 48)) {
      const twin = layout.hitTest(1200 - k.cx, k.cy)!
      expect(twin.note).toBe(k.note + 12)
      expect(twin.cx).toBeCloseTo(1200 - k.cx)
      expect(twin.cy).toBeCloseTo(k.cy)
    }
  })

  it('applies the semitone offset on the right half only', () => {
    expect(layout.hitTest(1190, 390)!.note).toBe(60) // mirror of bottom-left C3
    expect(layout.hitTest(610, 390)!.note).toBe(71) // innermost right key
    expect(layout.hitTest(590, 390)!.note).toBe(59) // innermost left key
  })

  it('mirrors continuous pitch with the offset', () => {
    expect(layout.pitchAt(25, 0)).toBeCloseTo(48) // half-width keys: center at 25
    expect(layout.pitchAt(1175, 0)).toBeCloseTo(60)
    // Pitch rises toward the seam from both sides.
    expect(layout.pitchAt(590, 0)).toBeGreaterThan(layout.pitchAt(500, 0))
    expect(layout.pitchAt(610, 0)).toBeGreaterThan(layout.pitchAt(700, 0) - 1e-9)
  })

  it('resolves touches exactly on the seam', () => {
    expect(layout.hitTest(600, 390)).not.toBeNull()
  })

  it('mirrors hexes with reflected polygons inside the surface', () => {
    const hex = buildLayout({ ...base, kind: 'hex', mirror: true, mirrorOffset: 0 })
    expect(hex.keys.length).toBe(96)
    for (const k of hex.keys) {
      for (const [px] of k.poly!) {
        expect(px).toBeGreaterThanOrEqual(-1)
        expect(px).toBeLessThanOrEqual(1201)
      }
    }
  })

  it('mirrors stacked pianos', () => {
    const solo = buildLayout({ ...base, kind: 'piano' })
    const split = buildLayout({ ...base, kind: 'piano', mirror: true })
    expect(split.keys.length).toBe(2 * solo.keys.length)
  })

  it('is ignored by typing-keyboard layouts', () => {
    const kbd = buildLayout({ ...base, kind: 'kbd-chromatic', mirror: true })
    expect(kbd.mirrored).toBeUndefined()
    expect(kbd.keys.length).toBe(45) // 10 + 11 + 12 + 12 physical keys
  })
})
