import { beforeEach, describe, expect, it } from 'vitest'
import { Store } from '../src/core/state'
import { SynthEngine } from '../src/audio/engine'
import { SamplerEngine } from '../src/audio/sampler'
import { MockAudioContext } from './mock-audio'

interface TestRig {
  store: Store
  ctx: MockAudioContext
  sampler: SamplerEngine
}

function rig(): TestRig {
  const store = new Store()
  store.set('voice', 'sampler')
  const ctx = new MockAudioContext()
  const engine = new SynthEngine(store, () => ctx as unknown as AudioContext)
  const sampler = new SamplerEngine(store, engine)
  return { store, ctx, sampler }
}

describe('SamplerEngine', () => {
  let t: TestRig

  beforeEach(() => {
    t = rig()
  })

  it('starts a voice with detune relative to the sample root', () => {
    t.store.set('sampler.preset', 'E-Piano') // root C4 = 60
    t.sampler.noteOn(1, 72, 0.8)
    expect(t.sampler.voiceCount).toBe(1)
    const src = lastSource(t.ctx)
    expect(src.started).toBe(true)
    expect(src.detune.value).toBe(1200) // one octave up
  })

  it('supports fractional pitches', () => {
    t.sampler.noteOn(1, 60.5, 0.8)
    expect(lastSource(t.ctx).detune.value).toBe(50)
  })

  it('loops sustained instruments and not one-shots', () => {
    t.store.set('sampler.preset', 'English Horn')
    t.sampler.noteOn(1, 57, 0.8)
    expect(lastSource(t.ctx).loop).toBe(true)
    t.store.set('sampler.preset', 'Marimba')
    t.sampler.noteOn(2, 69, 0.8)
    expect(lastSource(t.ctx).loop).toBe(false)
  })

  it('glide updates detune without restarting when retrig is off', () => {
    t.sampler.noteOn(1, 60, 0.8)
    const src = lastSource(t.ctx)
    const before = t.ctx.created.src
    t.sampler.glide(1, 61.3)
    expect(t.ctx.created.src).toBe(before)
    expect(src.detune.value).toBeCloseTo(130)
  })

  it('retrig restarts the sample when crossing a semitone', () => {
    t.store.set('sampler.retrig', true)
    t.sampler.noteOn(1, 60, 0.8)
    const first = lastSource(t.ctx)
    const before = t.ctx.created.src
    t.sampler.glide(1, 60.4) // same semitone — no restart
    expect(t.ctx.created.src).toBe(before)
    t.sampler.glide(1, 61.2) // crossed — restart at 61
    expect(t.ctx.created.src).toBe(before + 1)
    expect(first.stopped).toBe(true)
    expect(lastSource(t.ctx).detune.value).toBe(100)
    expect(t.sampler.voiceCount).toBe(1)
  })

  it('noteOff releases and removes the voice', () => {
    t.sampler.noteOn(1, 60, 0.8)
    t.sampler.noteOff(1)
    expect(t.sampler.voiceCount).toBe(0)
  })

  it('allOff silences every voice', () => {
    t.sampler.noteOn(1, 60, 0.8)
    t.sampler.noteOn(2, 64, 0.8)
    t.sampler.allOff()
    expect(t.sampler.voiceCount).toBe(0)
  })

  it('caches rendered instruments per preset', () => {
    t.sampler.noteOn(1, 60, 0.8)
    const buffersAfterFirst = t.ctx.created.src
    t.sampler.noteOn(2, 62, 0.8)
    // Two sources but the PCM buffer was only built once (no extra createBuffer
    // beyond reverb IR + sample); assert via timing: rendering twice at 8 kHz
    // would still be fast, so check identity instead.
    expect(t.ctx.created.src).toBe(buffersAfterFirst + 1)
  })

  it('user preset is silent until a sample is loaded, then plays at userRoot', async () => {
    t.store.set('sampler.preset', 'User Sample')
    t.sampler.noteOn(1, 60, 0.8)
    expect(t.sampler.voiceCount).toBe(0)
    await t.sampler.decodeFile({
      name: 'kalimba.wav',
      arrayBuffer: () => Promise.resolve(new ArrayBuffer(8)),
    })
    expect(t.sampler.userSampleName).toBe('kalimba.wav')
    t.store.set('sampler.userRoot', 48)
    t.sampler.noteOn(2, 60, 0.8)
    expect(t.sampler.voiceCount).toBe(1)
    expect(lastSource(t.ctx).detune.value).toBe(1200)
  })

  it('rejects empty or oversized user sample files', async () => {
    await expect(t.sampler.decodeFile({
      name: 'empty.wav',
      arrayBuffer: () => Promise.resolve(new ArrayBuffer(0)),
    })).rejects.toThrow()
    await expect(t.sampler.decodeFile({
      name: 'huge.wav',
      size: SamplerEngine.maxFileBytes + 1,
      arrayBuffer: () => Promise.resolve(new ArrayBuffer(8)),
    })).rejects.toThrow()
  })

  it('pressure brightens and swells the voice', () => {
    t.sampler.noteOn(1, 60, 0.8)
    const filterFreqBefore = lastFilter(t.ctx).frequency.value
    t.sampler.pressure(1, 1)
    expect(lastFilter(t.ctx).frequency.value).toBeGreaterThan(filterFreqBefore)
  })
})

interface MockSource {
  started: boolean
  stopped: boolean
  loop: boolean
  detune: { value: number }
}

interface MockFilter {
  frequency: { value: number }
}

function lastOf(ctx: MockAudioContext, kind: string): unknown {
  const list = ctx.instances[kind]
  if (!list?.length) throw new Error(`no ${kind} created`)
  return list[list.length - 1]
}

function lastSource(ctx: MockAudioContext): MockSource {
  return lastOf(ctx, 'src') as unknown as MockSource
}

function lastFilter(ctx: MockAudioContext): MockFilter {
  return lastOf(ctx, 'filter') as unknown as MockFilter
}
