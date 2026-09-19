/**
 * Key coloring schemes, riffing on the original app's looks:
 * Studio (sage LCD with dark root markers), Ocean (blue grid), Magenta (red/pink pianos), Rainbow (colored hexes),
 * Mono (grayscale hexes/pianos).
 */
import type { KeyShape } from '../core/layout'
import { pitchClass } from '../core/notes'

export interface KeyColors {
  fill: string
  stroke: string
  label: string
}

export const SCHEME_NAMES = [
  'Studio',
  'Ocean',
  'Magenta',
  'Rainbow',
  'Mono',
] as const
export type SchemeName = (typeof SCHEME_NAMES)[number]

export interface ColorOpts {
  /** Dim the Studio LCD along with the enclosure. */
  dark?: boolean
  /** 0..1 overall brightness. */
  brightness: number
  /** 0..1 light/dark spread between piano whites and blacks. */
  contrast: number
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
    case 'Studio': {
      const black = key.kind === 'black'
      const accidental = BLACK_PCS.has(pc) && key.kind !== 'white'
      const c = opts.contrast
      if (opts.dark) {
        return {
          h: 76,
          s: 17,
          l:
            (black
              ? 14 - 4 * c
              : isRoot
                ? 37 + 3 * c
                : accidental
                  ? 21 - 5 * c
                  : 28 + 6 * c) *
            (0.7 + 0.45 * opts.brightness),
        }
      }
      return {
        h: 76,
        s: 19,
        l: black
          ? 27 - 10 * c
          : (isRoot ? 66 + 4 * c : accidental ? 66 - 8 * c : 72 + 8 * c) +
            (opts.brightness - 0.65) * 24,
      }
    }
    case 'Rainbow':
      return { h: fromRoot * 30, s: 62, l: isRoot ? 56 : 42 }
    case 'Magenta':
      return {
        h: 320 + fromRoot * 4,
        s: 60,
        l: isRoot ? 52 : 30 + (fromRoot % 5) * 5,
      }
    case 'Mono':
      return { h: 210, s: 6, l: isRoot ? 62 : 26 + (fromRoot % 6) * 5 }
    case 'Ocean':
    default:
      return {
        h: 196 + fromRoot * 5,
        s: 64,
        l: isRoot ? 55 : 30 + (fromRoot % 5) * 6,
      }
  }
}

/** Pitch classes that are black keys on a conventional piano. */
const BLACK_PCS = new Set([1, 3, 6, 8, 10])

export function keyColors(
  scheme: string,
  key: KeyShape,
  opts: ColorOpts,
): KeyColors {
  let { h, s, l } = schemeHsl(scheme, key, opts)
  if (scheme !== 'Studio') {
    // CONTRAST widens or narrows the light/dark spread between whites and
    // blacks (0.5 keeps blacks at their resting depth).
    const c = opts.contrast
    // Grid keys take a cue from the piano: conventional black-key pitch
    // classes go dark like piano blacks, so the natural lattice is legible
    // at a glance. An accidental root keeps a little extra light.
    if (
      (key.kind === 'rect' || key.kind === 'hex') &&
      BLACK_PCS.has(pitchClass(key.note))
    ) {
      s = Math.min(s, 50)
      l =
        (pitchClass(key.note) === pitchClass(opts.baseNote) ? 32 : 22) - 12 * c
    }
    // Piano rows: whites stay bright, blacks stay dark, both tinted by the
    // scheme — richly for colored schemes, near-neutral for Mono.
    if (key.kind === 'white') {
      s = scheme === 'Mono' ? 6 : Math.min(s + 5, 62)
      l = scheme === 'Mono' ? 58 + 36 * c : 46 + 30 * c
    } else if (key.kind === 'black') {
      s = Math.min(s, 55)
      l = 22 - 12 * c
    }
    l = Math.max(4, Math.min(92, l * (0.55 + 0.9 * opts.brightness)))
  }
  const fill = `hsl(${h}, ${s}%, ${l}%)`
  const stroke = `hsl(${h}, ${Math.max(0, s - 15)}%, ${Math.max(0, l - 14)}%)`
  // Pick whichever label tone actually reads against this fill.
  const label = labelColor(fill)
  return { fill, stroke, label }
}

/** Re-evaluate labels against the current LCD region, including bright ripple crests. */
export function labelColor(fill: string): string {
  const h = parseHsl(fill)?.h ?? 48
  const dark = `hsl(${h}, 10%, 1%)`
  const light = `hsl(${h}, 10%, 99.5%)`
  return contrastRatio(dark, fill) >= contrastRatio(light, fill) ? dark : light
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
  const lin = (c: number) =>
    c <= 0.03928 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4)
  return 0.2126 * lin(f(0)) + 0.7152 * lin(f(8)) + 0.0722 * lin(f(4))
}

export function contrastRatio(c1: string, c2: string): number {
  const l1 = hslLuminance(c1)
  const l2 = hslLuminance(c2)
  const [hi, lo] = l1 > l2 ? [l1, l2] : [l2, l1]
  return (hi + 0.05) / (lo + 0.05)
}
