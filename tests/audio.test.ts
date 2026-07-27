import { describe, expect, it } from 'vitest'
import { SynthEngine } from '../src/audio/engine'
import { SamplerEngine } from '../src/audio/sampler'
import { velocityToGain } from '../src/audio/dsp'
import { Store } from '../src/core/state'
import {
  MockAudioContext, samplerVoiceNodes, synthVoiceGains, voiceBusGain,
} from './mock-audio'

function rig() {
  const store = new Store()
  const ctx = new MockAudioContext()
  const synth = new SynthEngine(store, () => ctx as unknown as AudioContext)
  const sampler = new SamplerEngine(store, synth)
  return { store, ctx, synth, sampler }
}

/** Start a sampler voice and return its nodes (graph pre-warmed first). */
function samplerVoice(r: ReturnType<typeof rig>, id: number, vel = 0.8) {
  r.sampler.noteOn(0, 60, 0.5) // primes the AudioContext and the out bus
  r.sampler.noteOff(0)
  const gains = r.ctx.gains.length
  const filters = r.ctx.filters.length
  r.sampler.noteOn(id, 60, vel)
  return samplerVoiceNodes(r.ctx, gains, filters)
}

describe('audio voice lifecycle', () => {
  it('caps synth release tails and hard panic clears them', () => {
    const { synth, ctx } = rig()
    for (let id = 0; id < 100; id++) {
      synth.noteOn(id, 60 + (id % 12), 0.8)
      synth.noteOff(id)
    }
    expect(synth.liveVoiceCount).toBeLessThanOrEqual(24)
    const delayNodes = ctx.created.delay
    synth.allOff()
    expect(synth.liveVoiceCount).toBe(0)
    expect(ctx.created.delay).toBe(delayNodes + 1)
  })

  it('caps sampler release tails and hard panic clears them', () => {
    const { sampler } = rig()
    for (let id = 0; id < 100; id++) {
      sampler.noteOn(id, 60 + (id % 12), 0.8)
      sampler.noteOff(id)
    }
    expect(sampler.liveVoiceCount).toBeLessThanOrEqual(16)
    sampler.allOff()
    expect(sampler.liveVoiceCount).toBe(0)
  })

  it('holds current automation before starting a release', () => {
    const { synth, ctx } = rig()
    synth.noteOn(1, 60, 1)
    synth.noteOff(1)
    expect(ctx.gains.some((node) => node.gain.held)).toBe(true)
  })

  it('keeps both fatten oscillators on generator one after a wave rebuild', () => {
    const { synth, store, ctx } = rig()
    store.set('fx.fatten.on', true)
    synth.noteOn(1, 60, 1)
    store.set('synth.bright', 0.8)
    const waves = ctx.oscs.slice(-4).map((osc) => osc.wave)
    expect(waves[0]).toBe(waves[2])
    expect(waves[0]).toBe(waves[3])
    expect(waves[1]).not.toBe(waves[0])
  })

  it('retunes each oscillator from its generator while preserving fatten spread', () => {
    const { synth, store, ctx } = rig()
    store.set('fx.fatten.on', true)
    synth.noteOn(1, 60, 1)
    store.set('synth.gen1.tune', 11)
    store.set('synth.gen2.tune', -7)
    const detunes = ctx.oscs.slice(-4).map((osc) => osc.detune.value)
    for (const [actual, expected] of detunes.map((value, i) => [value, [11, -7, 24.6, -2.6][i]])) {
      expect(actual).toBeCloseTo(expected)
    }
  })
})

describe('expression routing', () => {
  it('pressure→level swells the expression gain from the floor', () => {
    const { synth, store, ctx } = rig()
    synth.ensure()
    store.set('expr.pressure', 'level')
    const start = ctx.gains.length
    synth.noteOn(1, 60, 0.8)
    const { exp } = synthVoiceGains(ctx, start)
    expect(exp.gain.value).toBeCloseTo(0.3)
    synth.pressure(1, 1)
    expect(exp.gain.value).toBeCloseTo(1)
    synth.pressure(1, 0)
    expect(exp.gain.value).toBeCloseTo(0.3)
  })

  it('pressure→lfo swells the per-voice LFO sends from silence', () => {
    const { synth, store, ctx } = rig()
    synth.ensure()
    store.set('expr.pressure', 'lfo')
    const start = ctx.gains.length
    synth.noteOn(1, 60, 0.8)
    const { exp, lfoAmtPitch, lfoAmtFilter } = synthVoiceGains(ctx, start)
    expect(exp.gain.value).toBe(1)
    expect(lfoAmtPitch.gain.value).toBe(0)
    expect(lfoAmtFilter.gain.value).toBe(0)
    synth.pressure(1, 0.8)
    expect(lfoAmtPitch.gain.value).toBeCloseTo(0.8)
    expect(lfoAmtFilter.gain.value).toBeCloseTo(0.8)
  })

  it('pressure→filter (default) leaves level and LFO sends alone', () => {
    const { synth, ctx } = rig()
    synth.ensure()
    const start = ctx.gains.length
    synth.noteOn(1, 60, 0.8)
    const { exp, lfoAmtPitch } = synthVoiceGains(ctx, start)
    const filter = ctx.filters.at(-1)!
    const before = filter.frequency.value
    synth.pressure(1, 1)
    expect(filter.frequency.value).toBeGreaterThan(before)
    expect(exp.gain.value).toBe(1)
    expect(lfoAmtPitch.gain.value).toBe(1)
  })

  it('re-routing pressure mid-note resets the abandoned synth destination', () => {
    const { synth, store, ctx } = rig()
    synth.ensure()
    store.set('expr.pressure', 'level')
    const start = ctx.gains.length
    synth.noteOn(1, 60, 0.8)
    const { exp } = synthVoiceGains(ctx, start)
    synth.pressure(1, 0.9)
    expect(exp.gain.value).toBeGreaterThan(0.9)
    store.set('expr.pressure', 'filter')
    expect(exp.gain.value).toBe(1)
  })

  it('tilt→level rides the shared voice bus', () => {
    const { synth, store, ctx } = rig()
    synth.ensure()
    store.set('expr.tilt', 'level') // tiltAmount defaults to 0.5
    synth.setTilt(1)
    expect(voiceBusGain(ctx).gain.value).toBeCloseTo(1)
    synth.setTilt(0)
    expect(voiceBusGain(ctx).gain.value).toBeCloseTo(0.5)
    store.set('expr.tilt', 'off')
    expect(voiceBusGain(ctx).gain.value).toBeCloseTo(1)
  })

  it('tilt→lfo adds depth on top of the knob', () => {
    const { synth, store, ctx } = rig()
    synth.ensure()
    store.set('expr.tilt', 'lfo')
    const lfoPitch = ctx.gains.find((g) => Math.abs(g.gain.value - 0.08 * 60) < 1e-6)!
    expect(lfoPitch).toBeDefined()
    synth.setTilt(1)
    expect(lfoPitch.gain.value).toBeCloseTo((0.08 + 0.5) * 60)
  })

  it('tilt→filter brightens playing voices', () => {
    const { synth, store, ctx } = rig()
    synth.noteOn(1, 60, 0.8)
    store.set('expr.tilt', 'filter')
    const filter = ctx.filters.at(-1)!
    const before = filter.frequency.value
    synth.setTilt(1)
    expect(filter.frequency.value).toBeGreaterThan(before)
  })
})

describe('sampler expression', () => {
  it('keeps the envelope velocity-only: the level floor lives in the expression gain', () => {
    const r = rig()
    r.store.set('expr.pressure', 'level')
    const { vca, exp } = samplerVoice(r, 1)
    expect(vca.gain.value).toBeCloseTo(velocityToGain(0.8)) // full peak, no floor
    expect(exp.gain.value).toBeCloseTo(0.3)
  })

  it('swells with pressure routed to level', () => {
    const r = rig()
    r.store.set('expr.pressure', 'level')
    const { exp } = samplerVoice(r, 1)
    expect(exp.gain.value).toBeCloseTo(0.3)
    r.sampler.pressure(1, 1)
    expect(exp.gain.value).toBeCloseTo(1)
  })

  it('keeps the classic brighten + gentle swell on the default filter routing', () => {
    const r = rig()
    const { exp, filter } = samplerVoice(r, 1)
    const baseCutoff = filter.frequency.value
    r.sampler.pressure(1, 1)
    expect(exp.gain.value).toBeCloseTo(1.35)
    expect(filter.frequency.value).toBeGreaterThan(baseCutoff)
  })

  it('re-routing a held voice returns every destination to neutral', () => {
    const r = rig()
    const { exp, filter } = samplerVoice(r, 1)
    const baseCutoff = filter.frequency.value

    // filter routing under full pressure: bright and swollen…
    r.sampler.pressure(1, 1)
    expect(exp.gain.value).toBeCloseTo(1.35)
    // …then abandoned: both destinations must return to neutral.
    r.store.set('expr.pressure', 'off')
    expect(exp.gain.value).toBe(1)
    expect(filter.frequency.value).toBeCloseTo(baseCutoff)

    // level routing picks up the held pressure, off releases it again.
    r.sampler.pressure(1, 0.5)
    r.store.set('expr.pressure', 'level')
    expect(exp.gain.value).toBeCloseTo(0.3 + 0.7 * 0.5)
    r.store.set('expr.pressure', 'off')
    expect(exp.gain.value).toBe(1)

    // lfo means nothing to samples — also neutral.
    r.store.set('expr.pressure', 'lfo')
    expect(exp.gain.value).toBe(1)
    expect(filter.frequency.value).toBeCloseTo(baseCutoff)
  })
})
