/**
 * Expression policy — the single definition of what the pressure axis does to
 * a voice for each routing target. Both engines consume this instead of
 * branching on the route themselves, so a route change is atomic: every
 * destination gets an explicit value, and abandoned destinations return to
 * neutral (filter 0, level 1, lfo 1).
 */
import { clamp, lerp } from './dsp'
import type { PressureTarget } from '../core/state'

/** Quietest a voice gets when pressure is routed to level (swell floor). */
export const EXPR_LEVEL_FLOOR = 0.3

export type VoiceProfile = 'synth' | 'sampler'

export interface PressureModulation {
  /** Routed pressure 0..1 for the filter; engines scale to their cutoff range. */
  filter: number
  /** Post-envelope gain multiplier. */
  level: number
  /** Per-voice scale on the LFO send (synth only; samples have no LFO). */
  lfo: number
}

export const NEUTRAL_MODULATION: PressureModulation = { filter: 0, level: 1, lfo: 1 }

export function pressureModulation(
  route: PressureTarget,
  pressure: number,
  profile: VoiceProfile,
): PressureModulation {
  const p = clamp(pressure, 0, 1)
  switch (route) {
    case 'filter':
      // The sampler's classic touch response brightens AND gently swells.
      return { filter: p, level: profile === 'sampler' ? 1 + 0.35 * p : 1, lfo: 1 }
    case 'level':
      return { filter: 0, level: lerp(EXPR_LEVEL_FLOOR, 1, p), lfo: 1 }
    case 'lfo':
      return { filter: 0, level: 1, lfo: profile === 'synth' ? p : 1 }
    default:
      return NEUTRAL_MODULATION
  }
}
