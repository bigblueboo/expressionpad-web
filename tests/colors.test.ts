import { describe, expect, it } from 'vitest'
import { contrastRatio, keyColors, parseHsl, SCHEME_NAMES } from '../src/ui/colors'
import type { KeyShape } from '../src/core/layout'

function key(note: number, kind: KeyShape['kind'] = 'rect'): KeyShape {
  return { id: note, note, row: 0, col: 0, kind, x: 0, y: 0, w: 50, h: 50, cx: 25, cy: 25 }
}

const opts = { brightness: 0.65, baseNote: 48 }

describe('key colors', () => {
  it('every scheme yields parseable hsl for all pitch classes', () => {
    for (const scheme of SCHEME_NAMES) {
      for (let n = 48; n < 60; n++) {
        const c = keyColors(scheme, key(n), opts)
        expect(parseHsl(c.fill), `${scheme} fill ${n}`).not.toBeNull()
        expect(parseHsl(c.stroke), `${scheme} stroke ${n}`).not.toBeNull()
        expect(parseHsl(c.label), `${scheme} label ${n}`).not.toBeNull()
      }
    }
  })

  it('the root pitch class is visually distinct from its neighbors', () => {
    for (const scheme of SCHEME_NAMES) {
      const root = parseHsl(keyColors(scheme, key(48), opts).fill)!
      const second = parseHsl(keyColors(scheme, key(50), opts).fill)!
      const distinct =
        Math.abs(root.l - second.l) > 5 || Math.abs(root.h - second.h) > 10
      expect(distinct, scheme).toBe(true)
    }
  })

  it('labels meet readable contrast (>= 3:1) against their key fill', () => {
    for (const scheme of SCHEME_NAMES) {
      for (let n = 36; n < 48; n++) {
        const c = keyColors(scheme, key(n), opts)
        expect(
          contrastRatio(c.label, c.fill),
          `${scheme} note ${n}`,
        ).toBeGreaterThanOrEqual(3)
      }
    }
  })

  it('piano whites are light and blacks are dark in every scheme', () => {
    for (const scheme of SCHEME_NAMES) {
      const white = parseHsl(keyColors(scheme, key(60, 'white'), opts).fill)!
      const black = parseHsl(keyColors(scheme, key(61, 'black'), opts).fill)!
      expect(white.l, scheme).toBeGreaterThan(55)
      expect(black.l, scheme).toBeLessThan(30)
    }
  })

  it('brightness scales lightness', () => {
    const dim = parseHsl(keyColors('Ocean', key(50), { ...opts, brightness: 0.1 }).fill)!
    const bright = parseHsl(keyColors('Ocean', key(50), { ...opts, brightness: 1 }).fill)!
    expect(bright.l).toBeGreaterThan(dim.l)
  })

  it('conventional black-key pitch classes are darker on grid keys', () => {
    for (const scheme of SCHEME_NAMES) {
      for (const kind of ['rect', 'hex'] as const) {
        // C# (49) vs its natural neighbors C (48) and D (50).
        const accidental = parseHsl(keyColors(scheme, key(49, kind), opts).fill)!
        const naturalC = parseHsl(keyColors(scheme, key(48, kind), opts).fill)!
        const naturalD = parseHsl(keyColors(scheme, key(50, kind), opts).fill)!
        expect(accidental.l, `${scheme} ${kind}`).toBeLessThan(naturalC.l)
        expect(accidental.l, `${scheme} ${kind}`).toBeLessThan(naturalD.l)
      }
    }
  })

  it('accidental darkening leaves piano whites and blacks alone', () => {
    const white = parseHsl(keyColors('Ocean', key(61, 'white'), opts).fill)!
    expect(white.l).toBeGreaterThan(55) // C# as a white kind stays bright
  })

  it('octaves share a color (pitch-class based)', () => {
    const a = keyColors('Rainbow', key(50), opts)
    const b = keyColors('Rainbow', key(62), opts)
    expect(a.fill).toBe(b.fill)
  })

  it('rainbow spreads hues across the octave', () => {
    const hues = new Set<number>()
    for (let n = 48; n < 60; n++) {
      hues.add(parseHsl(keyColors('Rainbow', key(n), opts).fill)!.h)
    }
    expect(hues.size).toBe(12)
  })
})
