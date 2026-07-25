import { describe, expect, it } from 'vitest'
import { SynthEngine } from '../src/audio/engine'
import { SamplerEngine } from '../src/audio/sampler'
import { Store } from '../src/core/state'
import { MockAudioContext, MockParam } from './mock-audio'

function rig() {
  const store = new Store()
  const ctx = new MockAudioContext()
  const synth = new SynthEngine(store, () => ctx as unknown as AudioContext)
  const sampler = new SamplerEngine(store, synth)
  return { store, ctx, synth, sampler }
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
    const held = ctx.instances.gain.some((node) => {
      const gain = (node as unknown as { gain: MockParam }).gain
      return gain.held
    })
    expect(held).toBe(true)
  })

  it('keeps both fatten oscillators on generator one after a wave rebuild', () => {
    const { synth, store, ctx } = rig()
    store.set('fx.fatten.on', true)
    synth.noteOn(1, 60, 1)
    store.set('synth.bright', 0.8)
    const oscillators = ctx.instances.osc.slice(-4)
    const waves = oscillators.map((osc) => (osc as unknown as { wave: unknown }).wave)
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
    const oscillators = ctx.instances.osc.slice(-4) as unknown as Array<{
      detune: MockParam
    }>
    const detunes = oscillators.map((osc) => osc.detune.value)
    for (const [actual, expected] of detunes.map((value, i) => [value, [11, -7, 24.6, -2.6][i]])) {
      expect(actual).toBeCloseTo(expected)
    }
  })
})

describe('expression routing', () => {
  /** Gain nodes created by a noteOn, in creation order: vca, exp, lfoP, lfoF. */
  function voiceGains(ctx: MockAudioContext, start: number) {
    const gains = ctx.instances.gain as unknown as Array<{ gain: MockParam }>
    return { vca: gains[start], exp: gains[start + 1], lfoP: gains[start + 2], lfoF: gains[start + 3] }
  }

  it('pressure→level swells the expression gain from the floor', () => {
    const { synth, store, ctx } = rig()
    synth.ensure()
    store.set('expr.pressure', 'level')
    const start = ctx.instances.gain.length
    synth.noteOn(1, 60, 0.8)
    const { exp } = voiceGains(ctx, start)
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
    const start = ctx.instances.gain.length
    synth.noteOn(1, 60, 0.8)
    const { exp, lfoP, lfoF } = voiceGains(ctx, start)
    expect(exp.gain.value).toBe(1)
    expect(lfoP.gain.value).toBe(0)
    expect(lfoF.gain.value).toBe(0)
    synth.pressure(1, 0.8)
    expect(lfoP.gain.value).toBeCloseTo(0.8)
    expect(lfoF.gain.value).toBeCloseTo(0.8)
  })

  it('pressure→filter (default) leaves level and LFO sends alone', () => {
    const { synth, ctx } = rig()
    synth.ensure()
    const start = ctx.instances.gain.length
    synth.noteOn(1, 60, 0.8)
    const { exp, lfoP } = voiceGains(ctx, start)
    const filter = ctx.instances.filter.at(-1) as unknown as { frequency: MockParam }
    const before = filter.frequency.value
    synth.pressure(1, 1)
    expect(filter.frequency.value).toBeGreaterThan(before)
    expect(exp.gain.value).toBe(1)
    expect(lfoP.gain.value).toBe(1)
  })

  it('re-routing pressure mid-note resets the abandoned destination', () => {
    const { synth, store, ctx } = rig()
    synth.ensure()
    store.set('expr.pressure', 'level')
    const start = ctx.instances.gain.length
    synth.noteOn(1, 60, 0.8)
    const { exp } = voiceGains(ctx, start)
    synth.pressure(1, 0.9)
    expect(exp.gain.value).toBeGreaterThan(0.9)
    store.set('expr.pressure', 'filter')
    expect(exp.gain.value).toBe(1)
  })

  it('tilt→level rides the shared voice bus', () => {
    const { synth, store, ctx } = rig()
    synth.ensure()
    store.set('expr.tilt', 'level') // tiltAmount defaults to 0.5
    const voiceBus = (ctx.instances.gain as unknown as Array<{ gain: MockParam }>)[1]
    synth.setTilt(1)
    expect(voiceBus.gain.value).toBeCloseTo(1)
    synth.setTilt(0)
    expect(voiceBus.gain.value).toBeCloseTo(0.5)
    store.set('expr.tilt', 'off')
    expect(voiceBus.gain.value).toBeCloseTo(1)
  })

  it('tilt→lfo adds depth on top of the knob', () => {
    const { synth, store, ctx } = rig()
    synth.ensure()
    store.set('expr.tilt', 'lfo')
    const gains = ctx.instances.gain as unknown as Array<{ gain: MockParam }>
    const lfoPitch = gains.find((g) => Math.abs(g.gain.value - 0.08 * 60) < 1e-6)!
    expect(lfoPitch).toBeDefined()
    synth.setTilt(1)
    expect(lfoPitch.gain.value).toBeCloseTo((0.08 + 0.5) * 60)
  })

  it('tilt→filter brightens playing voices', () => {
    const { synth, store, ctx } = rig()
    synth.noteOn(1, 60, 0.8)
    store.set('expr.tilt', 'filter')
    const filter = ctx.instances.filter.at(-1) as unknown as { frequency: MockParam }
    const before = filter.frequency.value
    synth.setTilt(1)
    expect(filter.frequency.value).toBeGreaterThan(before)
  })

  it('sampler swells with pressure routed to level', () => {
    const { sampler, store, ctx } = rig()
    store.set('expr.pressure', 'level')
    sampler.noteOn(1, 60, 0.8)
    const vca = ctx.instances.gain.at(-1) as unknown as { gain: MockParam }
    const floor = vca.gain.value
    expect(floor).toBeGreaterThan(0)
    sampler.pressure(1, 1)
    expect(vca.gain.value).toBeCloseTo(floor / 0.3)
  })
})
