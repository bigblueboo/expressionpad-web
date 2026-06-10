/** Synth presets — names resurrected from the original app's preset menu. */
import type { SynthConfig } from './state'

type PresetPatch = Omit<SynthConfig, 'preset' | 'level'>

export const SYNTH_PRESETS: Record<string, PresetPatch> = {
  'Super Sine': {
    gen1: { morph: 0.08, semi: 0, tune: 0, level: 0.85 },
    gen2: { morph: 0.0, semi: 12, tune: 3, level: 0.22 },
    bright: 0.4,
    env: { a: 0.01, d: 0.3, s: 0.75, r: 0.35 },
    filter: { cutoff: 0.8, res: 0.1, env: 0.2 },
    lfo: { rate: 5, depth: 0.08, target: 'pitch' },
  },
  'Growl Dark': {
    gen1: { morph: 0.95, semi: -12, tune: 0, level: 0.9 },
    gen2: { morph: 0.7, semi: -5, tune: -7, level: 0.55 },
    bright: 0.35,
    env: { a: 0.03, d: 0.4, s: 0.6, r: 0.25 },
    filter: { cutoff: 0.32, res: 0.55, env: 0.55 },
    lfo: { rate: 3.2, depth: 0.25, target: 'filter' },
  },
  'Square Tap': {
    gen1: { morph: 1.0, semi: 0, tune: 0, level: 0.7 },
    gen2: { morph: 1.0, semi: 12, tune: 0, level: 0.3 },
    bright: 0.55,
    env: { a: 0.002, d: 0.12, s: 0.25, r: 0.12 },
    filter: { cutoff: 0.65, res: 0.3, env: 0.6 },
    lfo: { rate: 6, depth: 0, target: 'pitch' },
  },
  'Pole Position': {
    gen1: { morph: 0.66, semi: 0, tune: -5, level: 0.75 },
    gen2: { morph: 0.66, semi: 0, tune: 6, level: 0.75 },
    bright: 0.7,
    env: { a: 0.05, d: 0.35, s: 0.8, r: 0.5 },
    filter: { cutoff: 0.45, res: 0.65, env: 0.45 },
    lfo: { rate: 0.8, depth: 0.35, target: 'filter' },
  },
  Synolin: {
    gen1: { morph: 0.4, semi: 0, tune: 0, level: 0.8 },
    gen2: { morph: 0.25, semi: 7, tune: 4, level: 0.35 },
    bright: 0.6,
    env: { a: 0.12, d: 0.4, s: 0.85, r: 0.6 },
    filter: { cutoff: 0.6, res: 0.2, env: 0.25 },
    lfo: { rate: 5.5, depth: 0.18, target: 'pitch' },
  },
  'Saw Demise': {
    gen1: { morph: 0.62, semi: 0, tune: -8, level: 0.85 },
    gen2: { morph: 0.62, semi: -12, tune: 8, level: 0.6 },
    bright: 0.8,
    env: { a: 0.01, d: 0.5, s: 0.55, r: 0.8 },
    filter: { cutoff: 0.5, res: 0.4, env: 0.7 },
    lfo: { rate: 4, depth: 0.12, target: 'filter' },
  },
  'Room Drill': {
    gen1: { morph: 1.0, semi: -24, tune: 0, level: 0.9 },
    gen2: { morph: 0.85, semi: -17, tune: 12, level: 0.5 },
    bright: 0.9,
    env: { a: 0.001, d: 0.08, s: 0.9, r: 0.05 },
    filter: { cutoff: 0.55, res: 0.75, env: 0.8 },
    lfo: { rate: 12, depth: 0.4, target: 'filter' },
  },
}

export const PRESET_NAMES = Object.keys(SYNTH_PRESETS)

/** Paths+values to apply a preset through Store.patch(). */
export function presetPatch(name: string): Record<string, unknown> {
  const p = SYNTH_PRESETS[name]
  if (!p) return {}
  const out: Record<string, unknown> = { 'synth.preset': name }
  for (const gen of ['gen1', 'gen2'] as const) {
    for (const [k, v] of Object.entries(p[gen])) out[`synth.${gen}.${k}`] = v
  }
  out['synth.bright'] = p.bright
  for (const [k, v] of Object.entries(p.env)) out[`synth.env.${k}`] = v
  for (const [k, v] of Object.entries(p.filter)) out[`synth.filter.${k}`] = v
  for (const [k, v] of Object.entries(p.lfo)) out[`synth.lfo.${k}`] = v
  return out
}
