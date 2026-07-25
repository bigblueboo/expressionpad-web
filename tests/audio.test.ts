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
