// @vitest-environment jsdom
import { beforeEach, describe, expect, it } from 'vitest'
import { Store } from '../src/core/state'
import { SynthEngine } from '../src/audio/engine'
import { MidiOut } from '../src/midi/midi'
import { buildControls } from '../src/ui/controls'
import { knob, stepper, toggle } from '../src/ui/widgets'
import { Router } from '../src/audio/sink'
import type { VoiceSink } from '../src/audio/sink'

function setup() {
  document.body.innerHTML = '<div id="app"></div>'
  const root = document.getElementById('app')!
  const store = new Store()
  const engine = new SynthEngine(store)
  const midi = new MidiOut(store)
  buildControls(store, engine, midi, root)
  return { root, store }
}

describe('control panel', () => {
  beforeEach(() => {
    document.body.innerHTML = ''
  })

  it('renders the four tabs and brand', () => {
    const { root } = setup()
    const tabs = [...root.querySelectorAll('.tab')].map((t) => t.textContent)
    expect(tabs).toEqual(['SYNTH', 'FX', 'PAD', 'MIDI'])
    expect(root.querySelector('.brand')?.textContent).toBe('expressionPad')
  })

  it('shows only the active tab page', () => {
    const { root, store } = setup()
    expect(store.state.ui.tab).toBe('pad')
    const visible = [...root.querySelectorAll<HTMLElement>('.page')]
      .filter((p) => p.style.display !== 'none')
      .map((p) => p.dataset.page)
    expect(visible).toEqual(['pad'])
  })

  it('switches tabs on click', () => {
    const { root, store } = setup()
    const synthTab = [...root.querySelectorAll<HTMLButtonElement>('.tab')]
      .find((t) => t.textContent === 'SYNTH')!
    synthTab.click()
    expect(store.state.ui.tab).toBe('synth')
    const page = root.querySelector<HTMLElement>('[data-page="synth"]')!
    expect(page.style.display).not.toBe('none')
  })

  it('collapses and summons the panel via the chevron', () => {
    const { root, store } = setup()
    const chevron = root.querySelector<HTMLButtonElement>('.chevron')!
    const panel = root.querySelector('.panel')!
    expect(panel.classList.contains('collapsed')).toBe(false)
    chevron.click()
    expect(store.state.ui.panelOpen).toBe(false)
    expect(panel.classList.contains('collapsed')).toBe(true)
    expect(chevron.getAttribute('aria-expanded')).toBe('false')
    chevron.click()
    expect(panel.classList.contains('collapsed')).toBe(false)
  })

  it('tapping the active tab again collapses the panel', () => {
    const { root, store } = setup()
    const padTab = [...root.querySelectorAll<HTMLButtonElement>('.tab')]
      .find((t) => t.textContent === 'PAD')!
    padTab.click() // already active → collapse
    expect(store.state.ui.panelOpen).toBe(false)
    padTab.click() // summon again
    expect(store.state.ui.panelOpen).toBe(true)
  })

  it('exposes the original control groups', () => {
    const { root, store } = setup()
    const titlesOn = (tab: 'synth' | 'fx' | 'pad' | 'midi') => {
      store.patch({ 'ui.tab': tab, 'ui.panelOpen': true })
      return [...root.querySelectorAll(`[data-page="${tab}"] .group-title`)]
        .map((t) => t.textContent)
    }
    expect(titlesOn('pad')).toEqual(
      expect.arrayContaining(['PADMATRIX', 'TOUCH', 'APPEARANCE']),
    )
    expect(titlesOn('fx')).toEqual(
      expect.arrayContaining(['REVERB', 'DELAY', 'DISTORT', 'FATTEN']),
    )
    expect(titlesOn('synth')).toEqual(
      expect.arrayContaining(['PRESET', 'GENERATOR 1', 'GENERATOR 2', 'ENVELOPE', 'FILTER', 'LFO']),
    )
    expect(titlesOn('midi')).toEqual(
      expect.arrayContaining(['MIDI OUT', 'MIDI IN', 'SYSTEM']),
    )
  })

  it('layout select offers hexagons, squares, and piano', () => {
    const { root } = setup()
    const sel = root.querySelector<HTMLSelectElement>(
      '[data-page="pad"] select[aria-label="layout"]',
    )!
    const values = [...sel.options].map((o) => o.value)
    expect(values).toEqual(['square', 'hex', 'piano'])
  })

  it('selecting a preset applies the whole patch', () => {
    const { root, store } = setup()
    const sel = root.querySelector<HTMLSelectElement>(
      '[data-page="synth"] select[aria-label="preset"]',
    )!
    sel.value = 'Growl Dark'
    sel.dispatchEvent(new Event('change'))
    expect(store.state.synth.preset).toBe('Growl Dark')
    expect(store.state.synth.filter.res).toBeCloseTo(0.55)
  })
})

describe('widgets', () => {
  it('toggle flips its store value and aria state', () => {
    const store = new Store()
    const w = toggle(store, 'fx.reverb.on', 'on')
    document.body.appendChild(w)
    const btn = w.querySelector('button')!
    expect(btn.classList.contains('on')).toBe(true)
    btn.click()
    expect(store.state.fx.reverb.on).toBe(false)
    expect(btn.getAttribute('aria-pressed')).toBe('false')
  })

  it('stepper bumps within bounds', () => {
    const store = new Store()
    store.set('pad.rows', 8)
    const w = stepper(store, 'pad.rows', 'rows', { min: 1, max: 8 })
    document.body.appendChild(w)
    const [down, up] = [...w.querySelectorAll('button')]
    up.click()
    expect(store.state.pad.rows).toBe(8) // clamped at max
    down.click()
    expect(store.state.pad.rows).toBe(7)
  })

  it('knob reflects store changes and supports keyboard', () => {
    const store = new Store()
    const w = knob(store, 'synth.level', 'level')
    document.body.appendChild(w)
    const k = w.querySelector<HTMLElement>('.knob')!
    store.set('synth.level', 0.5)
    expect(w.querySelector('.knob-readout')!.textContent).toBe('50%')
    k.dispatchEvent(new KeyboardEvent('keydown', { key: 'ArrowUp', bubbles: true }))
    expect(store.state.synth.level).toBeCloseTo(0.55)
    expect(k.getAttribute('aria-valuenow')).toBe('0.55')
  })
})

describe('Router', () => {
  class Spy implements VoiceSink {
    events: string[] = []
    noteOn(id: number) { this.events.push(`on${id}`) }
    glide(id: number) { this.events.push(`glide${id}`) }
    pressure(id: number) { this.events.push(`p${id}`) }
    noteOff(id: number) { this.events.push(`off${id}`) }
    allOff() { this.events.push('allOff') }
  }

  it('routes to enabled sinks only', () => {
    const a = new Spy()
    const b = new Spy()
    let bEnabled = false
    const r = new Router()
    r.add(a, () => true)
    r.add(b, () => bEnabled)
    r.noteOn(1, 60, 0.8)
    expect(a.events).toEqual(['on1'])
    expect(b.events).toEqual([])
    bEnabled = true
    r.noteOn(2, 62, 0.8)
    expect(b.events).toEqual(['on2'])
  })

  it('keeps routing a voice to its onset-time sinks', () => {
    const a = new Spy()
    let enabled = true
    const r = new Router()
    r.add(a, () => enabled)
    r.noteOn(1, 60, 0.8)
    enabled = false // toggled mid-note: the live voice must still resolve
    r.glide(1, 61)
    r.noteOff(1)
    expect(a.events).toEqual(['on1', 'glide1', 'off1'])
  })
})
