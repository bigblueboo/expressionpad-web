import { beforeEach, describe, expect, it, vi } from 'vitest'
import { defaultState, Store } from '../src/core/state'
import { presetPatch, PRESET_NAMES, SYNTH_PRESETS } from '../src/core/presets'

// Node 25 injects a non-functional localStorage global that shadows jsdom's;
// stub a real Map-backed implementation for persistence tests.
beforeEach(() => {
  const data = new Map<string, string>()
  vi.stubGlobal('localStorage', {
    getItem: (k: string) => data.get(k) ?? null,
    setItem: (k: string, v: string) => void data.set(k, v),
    removeItem: (k: string) => void data.delete(k),
    clear: () => data.clear(),
  })
})

describe('Store', () => {
  it('reads and writes nested paths', () => {
    const store = new Store()
    expect(store.get<number>('pad.rows')).toBe(4)
    store.set('pad.rows', 6)
    expect(store.get<number>('pad.rows')).toBe(6)
    store.set('synth.env.a', 0.5)
    expect(store.state.synth.env.a).toBe(0.5)
  })

  it('notifies subscribers with the changed path', () => {
    const store = new Store()
    const seen: string[] = []
    store.subscribe((_s, path) => seen.push(path))
    store.set('fx.reverb.mix', 0.9)
    expect(seen).toEqual(['fx.reverb.mix'])
  })

  it('does not notify on no-op writes', () => {
    const store = new Store()
    const fn = vi.fn()
    store.subscribe(fn)
    store.set('pad.rows', store.get('pad.rows'))
    expect(fn).not.toHaveBeenCalled()
  })

  it('unsubscribe stops notifications', () => {
    const store = new Store()
    const fn = vi.fn()
    const off = store.subscribe(fn)
    off()
    store.set('pad.rows', 7)
    expect(fn).not.toHaveBeenCalled()
  })

  it('patch sets multiple paths', () => {
    const store = new Store()
    store.patch({ 'pad.rows': 2, 'pad.cols': 8 })
    expect(store.state.pad.rows).toBe(2)
    expect(store.state.pad.cols).toBe(8)
  })

  it('throws on bad paths', () => {
    const store = new Store()
    expect(() => store.get('nope.nope')).toThrow()
  })

  it('persists to localStorage and loads back', async () => {
    localStorage.clear()
    const store = new Store(defaultState(), 'test-key')
    store.set('pad.cols', 16)
    await new Promise((r) => setTimeout(r, 350)) // debounce window
    const loaded = Store.load('test-key')
    expect(loaded.state.pad.cols).toBe(16)
  })

  it('survives corrupted persisted state', () => {
    localStorage.setItem('bad-key', '{not json')
    const loaded = Store.load('bad-key')
    expect(loaded.state.pad.rows).toBe(4)
  })

  it('merges stale shapes without losing new defaults', () => {
    localStorage.setItem('stale-key', JSON.stringify({ pad: { rows: 5, obsolete: 1 } }))
    const loaded = Store.load('stale-key')
    expect(loaded.state.pad.rows).toBe(5)
    expect(loaded.state.pad.cols).toBe(12) // default preserved
    expect('obsolete' in loaded.state.pad).toBe(false)
  })

  it('rejects type-mismatched persisted values', () => {
    localStorage.setItem('typed-key', JSON.stringify({ pad: { rows: 'six' } }))
    const loaded = Store.load('typed-key')
    expect(loaded.state.pad.rows).toBe(4)
  })
})

describe('presets', () => {
  it('includes the original preset names', () => {
    for (const name of [
      'Growl Dark', 'Square Tap', 'Super Sine', 'Pole Position',
      'Synolin', 'Saw Demise', 'Room Drill',
    ]) {
      expect(PRESET_NAMES).toContain(name)
    }
  })

  it('all preset values are within legal ranges', () => {
    for (const [name, p] of Object.entries(SYNTH_PRESETS)) {
      for (const gen of [p.gen1, p.gen2]) {
        expect(gen.morph, name).toBeGreaterThanOrEqual(0)
        expect(gen.morph, name).toBeLessThanOrEqual(1)
        expect(gen.level, name).toBeGreaterThanOrEqual(0)
        expect(gen.level, name).toBeLessThanOrEqual(1)
        expect(Math.abs(gen.semi), name).toBeLessThanOrEqual(24)
        expect(Math.abs(gen.tune), name).toBeLessThanOrEqual(50)
      }
      expect(p.env.a, name).toBeGreaterThan(0)
      expect(p.env.s, name).toBeLessThanOrEqual(1)
      expect(p.filter.cutoff, name).toBeGreaterThan(0)
      expect(p.filter.cutoff, name).toBeLessThanOrEqual(1)
      expect(['pitch', 'filter']).toContain(p.lfo.target)
    }
  })

  it('presetPatch applies a complete patch through the store', () => {
    const store = new Store()
    store.patch(presetPatch('Growl Dark'))
    expect(store.state.synth.preset).toBe('Growl Dark')
    expect(store.state.synth.gen1.morph).toBe(SYNTH_PRESETS['Growl Dark'].gen1.morph)
    expect(store.state.synth.filter.res).toBe(SYNTH_PRESETS['Growl Dark'].filter.res)
    expect(store.state.synth.lfo.target).toBe('filter')
  })

  it('presetPatch of unknown name is a no-op', () => {
    const store = new Store()
    const before = JSON.stringify(store.state.synth)
    store.patch(presetPatch('Nonexistent'))
    expect(JSON.stringify(store.state.synth)).toBe(before)
  })
})
