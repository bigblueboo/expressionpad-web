/**
 * Key coloring schemes, riffing on the original app's looks:
 * Ocean (blue grid), Magenta (red/pink pianos), Rainbow (colored hexes),
 * Mono (grayscale hexes/pianos).
 */
import type { KeyShape } from '../core/layout'
import { pitchClass } from '../core/notes'

export interface KeyColors {
  fill: string
  stroke: string
  label: string
}

export const SCHEME_NAMES = ['Ocean', 'Magenta', 'Rainbow', 'Mono'] as const
export type SchemeName = (typeof SCHEME_NAMES)[number]

export interface ColorOpts {
  /** 0..1 overall brightness. */
  brightness: number
  /** Base note of the pad — its pitch class is emphasized as the root. */
  baseNote: number
}

interface HSL {
  h: number
  s: number
  l: number
}

function schemeHsl(scheme: string, key: KeyShape, opts: ColorOpts): HSL {
  const pc = pitchClass(key.note)
  const rootPc = pitchClass(opts.baseNote)
  const fromRoot = (pc - rootPc + 12) % 12
  const isRoot = fromRoot === 0
  switch (scheme) {
    case 'Rainbow':
      return { h: fromRoot * 30, s: 62, l: isRoot ? 56 : 42 }
    case 'Magenta':
      return { h: 320 + fromRoot * 4, s: 60, l: isRoot ? 52 : 30 + (fromRoot % 5) * 5 }
    case 'Mono':
      return { h: 210, s: 6, l: isRoot ? 62 : 26 + (fromRoot % 6) * 5 }
    case 'Ocean':
    default:
      return { h: 196 + fromRoot * 5, s: 64, l: isRoot ? 55 : 30 + (fromRoot % 5) * 6 }
  }
}

export function keyColors(scheme: string, key: KeyShape, opts: ColorOpts): KeyColors {
  let { h, s, l } = schemeHsl(scheme, key, opts)
  // Piano rows: whites stay bright, blacks stay dark, both tinted by the
  // scheme — richly for colored schemes, near-neutral for Mono.
  if (key.kind === 'white') {
    s = scheme === 'Mono' ? 6 : Math.min(s + 5, 62)
    l = scheme === 'Mono' ? 80 : 66
  } else if (key.kind === 'black') {
    s = Math.min(s, 55)
    l = 16
  }
  l = Math.max(4, Math.min(92, l * (0.55 + 0.9 * opts.brightness)))
  const fill = `hsl(${h}, ${s}%, ${l}%)`
  const stroke = `hsl(${h}, ${Math.max(0, s - 15)}%, ${Math.max(0, l - 14)}%)`
  // Pick whichever label tone actually reads against this fill.
  const dark = `hsl(${h}, 25%, 10%)`
  const light = `hsl(${h}, 20%, 92%)`
  const label = contrastRatio(dark, fill) >= contrastRatio(light, fill) ? dark : light
  return { fill, stroke, label }
}

/** Parse "hsl(h, s%, l%)" — used by rendering helpers and tests. */
export function parseHsl(str: string): HSL | null {
  const m = /^hsl\((-?[\d.]+),\s*([\d.]+)%,\s*([\d.]+)%\)$/.exec(str)
  if (!m) return null
  return { h: parseFloat(m[1]), s: parseFloat(m[2]), l: parseFloat(m[3]) }
}

/** WCAG-ish relative luminance from an hsl string (approximate, for contrast tests). */
export function hslLuminance(str: string): number {
  const hsl = parseHsl(str)
  if (!hsl) return 0
  const { h, s, l } = hsl
  const a = (s / 100) * Math.min(l / 100, 1 - l / 100)
  const f = (n: number) => {
    const k = (n + h / 30) % 12
    return l / 100 - a * Math.max(-1, Math.min(k - 3, 9 - k, 1))
  }
  const lin = (c: number) => (c <= 0.03928 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4))
  return 0.2126 * lin(f(0)) + 0.7152 * lin(f(8)) + 0.0722 * lin(f(4))
}

export function contrastRatio(c1: string, c2: string): number {
  const l1 = hslLuminance(c1)
  const l2 = hslLuminance(c2)
  const [hi, lo] = l1 > l2 ? [l1, l2] : [l2, l1]
  return (hi + 0.05) / (lo + 0.05)
}
