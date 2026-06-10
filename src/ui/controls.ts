/**
 * Control panel: top tab bar (SYNTH | FX | PAD | MIDI) with a collapse
 * chevron, and a sliding panel of grouped controls — the original layout.
 */
import type { Store } from '../core/state'
import { PRESET_NAMES, presetPatch } from '../core/presets'
import { ROW_TUNING_NAMES, SCALE_NAMES } from '../core/scales'
import { noteName } from '../core/notes'
import { SCHEME_NAMES } from './colors'
import { SAMPLE_NAMES, USER_PRESET } from '../audio/samplegen'
import { button, group, knob, select, stepper, toggle } from './widgets'
import type { SynthEngine } from '../audio/engine'
import type { SamplerEngine } from '../audio/sampler'
import type { MidiOut } from '../midi/midi'
import type { VoiceSink } from '../audio/sink'

const TABS = [
  { id: 'synth', label: 'SYNTH' },
  { id: 'smplr', label: 'SMPLR' },
  { id: 'fx', label: 'FX' },
  { id: 'pad', label: 'PAD' },
  { id: 'midi', label: 'MIDI' },
] as const

export function buildControls(
  store: Store,
  engine: SynthEngine,
  sampler: SamplerEngine,
  midi: MidiOut,
  router: VoiceSink,
  root: HTMLElement,
): void {
  const bar = document.createElement('header')
  bar.className = 'topbar'
  root.appendChild(bar)

  const brand = document.createElement('span')
  brand.className = 'brand'
  brand.textContent = 'expressionPad'
  bar.appendChild(brand)

  const tabsWrap = document.createElement('nav')
  tabsWrap.className = 'tabs'
  bar.appendChild(tabsWrap)

  const tabButtons = new Map<string, HTMLButtonElement>()
  for (const tab of TABS) {
    const btn = document.createElement('button')
    btn.type = 'button'
    btn.className = 'tab'
    btn.dataset.tab = tab.id
    btn.textContent = tab.label
    btn.addEventListener('click', () => {
      if (store.state.ui.tab === tab.id && store.state.ui.panelOpen) {
        store.set('ui.panelOpen', false)
      } else {
        store.patch({ 'ui.tab': tab.id, 'ui.panelOpen': true })
      }
    })
    tabsWrap.appendChild(btn)
    tabButtons.set(tab.id, btn)
  }

  const chevron = document.createElement('button')
  chevron.type = 'button'
  chevron.className = 'chevron'
  chevron.setAttribute('aria-label', 'toggle control panel')
  chevron.textContent = '«'
  chevron.addEventListener('click', () => store.set('ui.panelOpen', !store.state.ui.panelOpen))
  bar.appendChild(chevron)

  const panel = document.createElement('section')
  panel.className = 'panel'
  root.appendChild(panel)

  const pages: Record<string, HTMLElement> = {
    synth: synthPage(store),
    smplr: smplrPage(store, sampler, router),
    fx: fxPage(store),
    pad: padPage(store),
    midi: midiPage(store, midi, engine),
  }
  for (const [id, page] of Object.entries(pages)) {
    page.classList.add('page')
    page.dataset.page = id
    panel.appendChild(page)
  }

  const sync = () => {
    const { tab, panelOpen } = store.state.ui
    for (const [id, btn] of tabButtons) {
      btn.classList.toggle('active', id === tab && panelOpen)
    }
    for (const [id, page] of Object.entries(pages)) {
      page.style.display = id === tab ? '' : 'none'
    }
    panel.classList.toggle('collapsed', !panelOpen)
    chevron.classList.toggle('collapsed', !panelOpen)
    chevron.setAttribute('aria-expanded', String(panelOpen))
  }
  sync()
  store.subscribe((_s, path) => {
    if (path.startsWith('ui')) sync()
  })
}

function row(...children: HTMLElement[]): HTMLElement {
  const r = document.createElement('div')
  r.className = 'panel-row'
  for (const c of children) r.appendChild(c)
  return r
}

const semiFmt = (v: number) => (v > 0 ? `+${v}` : String(v))

/** SYNTH/SMPLR exclusivity switch — only one local sound source at a time. */
function voiceGroup(store: Store): HTMLElement {
  return group(
    'VOICE',
    select(store, 'voice', 'active', [
      { value: 'synth', text: 'Synth' },
      { value: 'sampler', text: 'Sampler' },
    ]),
  )
}

function smplrPage(store: Store, sampler: SamplerEngine, router: VoiceSink): HTMLElement {
  const presetSel = select(
    store, 'sampler.preset', 'preset',
    [...SAMPLE_NAMES, USER_PRESET].map((p) => ({ value: p, text: p })),
  )

  const status = document.createElement('div')
  status.className = 'midi-status widget'
  const syncStatus = () => {
    if (store.state.sampler.preset === USER_PRESET) {
      status.textContent = sampler.userSampleName
        ? `Loaded: ${sampler.userSampleName}`
        : 'No sample loaded yet.'
    } else {
      status.textContent = 'Built-in instrument.'
    }
  }
  syncStatus()
  store.subscribe((_s, p) => {
    if (p.startsWith('sampler')) syncStatus()
  })

  const file = document.createElement('input')
  file.type = 'file'
  file.accept = 'audio/*'
  file.style.display = 'none'
  file.addEventListener('change', async () => {
    const f = file.files?.[0]
    if (!f) return
    try {
      await sampler.decodeFile(f)
      store.set('sampler.preset', USER_PRESET)
      syncStatus()
    } catch {
      status.textContent = `Could not decode ${f.name}.`
    }
  })

  const loadBtn = button('load', () => file.click())
  loadBtn.appendChild(file)

  return row(
    group('SAMPLER', presetSel, loadBtn, toggle(store, 'sampler.retrig', 'retrig'),
      button('panic', () => router.allOff()), status),
    group(
      'LEVEL',
      knob(store, 'sampler.level', 'level'),
      knob(store, 'sampler.attack', 'attack', { min: 0.002, max: 0.5, fmt: secFmt }),
      knob(store, 'sampler.release', 'release', { min: 0.02, max: 3, fmt: secFmt }),
    ),
    group(
      'USER ROOT',
      stepper(store, 'sampler.userRoot', 'root', {
        min: 24, max: 96, fmt: (v) => noteName(v, true),
      }),
    ),
    voiceGroup(store),
  )
}

function synthPage(store: Store): HTMLElement {
  const presetSel = select(
    store, 'synth.preset', 'preset',
    PRESET_NAMES.map((p) => ({ value: p, text: p })),
  )
  // Selecting a preset applies the whole patch.
  presetSel.querySelector('select')!.addEventListener('change', (e) => {
    store.patch(presetPatch((e.target as HTMLSelectElement).value))
  })

  return row(
    group('PRESET', presetSel, knob(store, 'synth.level', 'level')),
    voiceGroup(store),
    group(
      'GENERATOR 1',
      knob(store, 'synth.gen1.morph', 'wave'),
      stepper(store, 'synth.gen1.semi', 'semi', { min: -24, max: 24, fmt: semiFmt }),
      knob(store, 'synth.gen1.tune', 'tune', { min: -50, max: 50, fmt: (v) => `${Math.round(v)}¢` }),
      knob(store, 'synth.gen1.level', 'level'),
    ),
    group(
      'GENERATOR 2',
      knob(store, 'synth.gen2.morph', 'wave'),
      stepper(store, 'synth.gen2.semi', 'semi', { min: -24, max: 24, fmt: semiFmt }),
      knob(store, 'synth.gen2.tune', 'tune', { min: -50, max: 50, fmt: (v) => `${Math.round(v)}¢` }),
      knob(store, 'synth.gen2.level', 'level'),
    ),
    group('TONE', knob(store, 'synth.bright', 'bright')),
    group(
      'ENVELOPE',
      knob(store, 'synth.env.a', 'attack', { min: 0.001, max: 2, fmt: secFmt }),
      knob(store, 'synth.env.d', 'decay', { min: 0.01, max: 3, fmt: secFmt }),
      knob(store, 'synth.env.s', 'sustain'),
      knob(store, 'synth.env.r', 'release', { min: 0.02, max: 5, fmt: secFmt }),
    ),
    group(
      'FILTER',
      knob(store, 'synth.filter.cutoff', 'cutoff'),
      knob(store, 'synth.filter.res', 'res'),
      knob(store, 'synth.filter.env', 'touch'),
    ),
    group(
      'LFO',
      knob(store, 'synth.lfo.rate', 'rate', { min: 0.05, max: 20, fmt: (v) => `${v.toFixed(1)}Hz` }),
      knob(store, 'synth.lfo.depth', 'depth'),
      select(store, 'synth.lfo.target', 'target', [
        { value: 'pitch', text: 'Pitch' },
        { value: 'filter', text: 'Filter' },
      ]),
    ),
  )
}

const secFmt = (v: number) => (v < 1 ? `${Math.round(v * 1000)}ms` : `${v.toFixed(1)}s`)

function fxPage(store: Store): HTMLElement {
  return row(
    group(
      'REVERB',
      knob(store, 'fx.reverb.fdbk', 'fdbk'),
      knob(store, 'fx.reverb.mix', 'mix'),
      toggle(store, 'fx.reverb.on', 'on'),
    ),
    group(
      'DELAY',
      knob(store, 'fx.delay.time', 'time', { min: 0.02, max: 1.5, fmt: secFmt }),
      knob(store, 'fx.delay.fdbk', 'fdbk', { min: 0, max: 0.9 }),
      knob(store, 'fx.delay.mix', 'mix'),
      toggle(store, 'fx.delay.on', 'on'),
    ),
    group(
      'DISTORT',
      knob(store, 'fx.distort.amt', 'amt'),
      toggle(store, 'fx.distort.on', 'on'),
    ),
    group(
      'FATTEN',
      knob(store, 'fx.fatten.amt', 'fatness'),
      toggle(store, 'fx.fatten.on', 'on'),
    ),
  )
}

function padPage(store: Store): HTMLElement {
  return row(
    group(
      'PADMATRIX',
      select(store, 'pad.layout', 'layout', [
        { value: 'square', text: 'Square' },
        { value: 'hex', text: 'Hexagon' },
        { value: 'piano', text: 'Piano' },
      ]),
      select(store, 'pad.rowTuning', 'row tuning', ROW_TUNING_NAMES),
      stepper(store, 'pad.cols', 'cols', { min: 4, max: 24 }),
      stepper(store, 'pad.rows', 'rows', { min: 1, max: 8 }),
      select(store, 'pad.colScale', 'col scale', SCALE_NAMES),
      stepper(store, 'pad.baseNote', 'base', {
        min: 12, max: 96, fmt: (v) => noteName(v, true),
      }),
    ),
    group(
      'TOUCH',
      knob(store, 'pad.slide', 'slide'),
      toggle(store, 'pad.frets', 'frets'),
      toggle(store, 'pad.touchVel', 'tch vel'),
      toggle(store, 'pad.aftertouch', 'aftrtch'),
    ),
    group(
      'APPEARANCE',
      select(store, 'appearance.scheme', 'coloring', [...SCHEME_NAMES]),
      toggle(store, 'appearance.labels', 'labels'),
      knob(store, 'appearance.brightness', 'bright'),
      toggle(store, 'appearance.ripples', 'ripples'),
    ),
  )
}

function midiPage(store: Store, midi: MidiOut, engine: SynthEngine): HTMLElement {
  const status = document.createElement('div')
  status.className = 'midi-status widget'

  const outSel = select(store, 'midi.outputId', 'output', [{ value: '', text: '—' }])
  const inSel = select(store, 'midi.inputId', 'input', [{ value: '', text: '—' }])

  const refreshPorts = () => {
    for (const [sel, ports, path] of [
      [outSel.querySelector('select')!, midi.outputs(), 'midi.outputId'],
      [inSel.querySelector('select')!, midi.inputs(), 'midi.inputId'],
    ] as const) {
      sel.innerHTML = ''
      const none = document.createElement('option')
      none.value = ''
      none.textContent = ports.length ? 'Auto' : 'No devices'
      sel.appendChild(none)
      for (const p of ports) {
        const opt = document.createElement('option')
        opt.value = p.id
        opt.textContent = p.name
        sel.appendChild(opt)
      }
      sel.value = store.get<string>(path)
    }
  }

  const initMidi = async () => {
    if (!midi.supported) {
      status.textContent = 'Web MIDI is not supported in this browser (iOS Safari: try Web MIDI Browser).'
      return
    }
    const ok = await midi.init()
    status.textContent = ok
      ? `MIDI ready — latency ${engine.latencyMs}ms`
      : 'MIDI access denied.'
    if (ok) {
      refreshPorts()
      midi.onDevicesChanged = refreshPorts
    }
  }
  void initMidi()

  return row(
    group(
      'MIDI OUT',
      toggle(store, 'midi.outEnabled', 'active'),
      outSel,
      stepper(store, 'midi.bendRange', 'bend rng', { min: 1, max: 96 }),
      toggle(store, 'midi.sendY', 'send cc74'),
    ),
    group(
      'MIDI IN',
      toggle(store, 'midi.inEnabled', 'active'),
      inSel,
    ),
    group(
      'SYSTEM',
      toggle(store, 'midi.localSound', 'synth'),
      status,
    ),
  )
}
