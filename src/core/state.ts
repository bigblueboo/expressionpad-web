/** App state: a small path-addressable store with subscriptions + persistence. */
import type { LayoutKind } from './layout'
import { ROW_TUNINGS, SCALES } from './scales'

export interface PadConfig {
  layout: LayoutKind
  rows: number
  cols: number
  rowTuning: string
  colScale: string
  baseNote: number
  /** 0 = retrigger per key; >0 = continuous pitch slide (value = glide amount). */
  slide: number
  /** Snap slid pitch to semitones. */
  frets: boolean
  /** Derive velocity from vertical touch position within the key. */
  touchVel: boolean
  /** Vertical drag after onset modulates pressure/timbre. */
  aftertouch: boolean
}

export interface GenConfig {
  /** Waveform morph 0..1: sine → triangle → saw → square. */
  morph: number
  /** Semitone offset. */
  semi: number
  /** Fine tune in cents. */
  tune: number
  /** Mix level 0..1. */
  level: number
}

export interface SynthConfig {
  preset: string
  gen1: GenConfig
  gen2: GenConfig
  /** Additive brightness tilt 0..1. */
  bright: number
  env: { a: number; d: number; s: number; r: number }
  filter: { cutoff: number; res: number; env: number }
  lfo: { rate: number; depth: number; target: 'pitch' | 'filter' }
  level: number
}

export interface FxConfig {
  reverb: { fdbk: number; mix: number; on: boolean }
  delay: { time: number; fdbk: number; mix: number; on: boolean }
  distort: { amt: number; on: boolean }
  fatten: { amt: number; on: boolean }
}

export interface MidiConfig {
  outEnabled: boolean
  outputId: string
  bendRange: number
  /** Send Y-axis as CC74 (MPE timbre). */
  sendY: boolean
  inEnabled: boolean
  inputId: string
  /** Play the internal synth (off = pure MIDI controller). */
  localSound: boolean
}

export interface AppearanceConfig {
  scheme: string
  labels: boolean
  brightness: number
  ripples: boolean
  /** Strength of the ripple wave's visual effect, 0..1. */
  rippleAmount: number
  /** Light/dark spread between piano whites and blacks, 0..1. */
  contrast: number
}

export interface SamplerConfig {
  preset: string
  level: number
  attack: number
  release: number
  /** Restart the sample when a slide crosses into a new semitone. */
  retrig: boolean
  /** Root note assumed for a user-loaded sample. */
  userRoot: number
}

export interface UiConfig {
  panelOpen: boolean
  tab: 'synth' | 'smplr' | 'fx' | 'pad' | 'midi'
}

export interface AppState {
  /** Which local sound source touches play — synth or sampler. */
  voice: 'synth' | 'sampler'
  pad: PadConfig
  synth: SynthConfig
  sampler: SamplerConfig
  fx: FxConfig
  midi: MidiConfig
  appearance: AppearanceConfig
  ui: UiConfig
}

export function defaultState(): AppState {
  return {
    voice: 'synth',
    sampler: {
      preset: 'E-Piano', level: 0.8, attack: 0.005, release: 0.35,
      retrig: false, userRoot: 60,
    },
    pad: {
      layout: 'square', rows: 4, cols: 12,
      rowTuning: 'Fourths [+5]', colScale: 'Chromatic', baseNote: 48,
      slide: 0.35, frets: false, touchVel: true, aftertouch: true,
    },
    synth: {
      preset: 'Super Sine',
      gen1: { morph: 0.08, semi: 0, tune: 0, level: 0.85 },
      gen2: { morph: 0, semi: 12, tune: 3, level: 0.22 },
      bright: 0.4,
      env: { a: 0.01, d: 0.3, s: 0.75, r: 0.35 },
      filter: { cutoff: 0.8, res: 0.1, env: 0.2 },
      lfo: { rate: 5, depth: 0.08, target: 'pitch' },
      level: 0.78,
    },
    fx: {
      reverb: { fdbk: 0.5, mix: 0.3, on: true },
      delay: { time: 0.34, fdbk: 0.35, mix: 0.2, on: false },
      distort: { amt: 0.3, on: false },
      fatten: { amt: 0.4, on: true },
    },
    midi: {
      outEnabled: false, outputId: '', bendRange: 48, sendY: true,
      inEnabled: false, inputId: '', localSound: true,
    },
    appearance: {
      scheme: 'Ocean', labels: true, brightness: 0.65,
      ripples: true, rippleAmount: 0.5, contrast: 0.5,
    },
    ui: { panelOpen: true, tab: 'pad' },
  }
}

export type Listener = (state: AppState, path: string) => void

const STORAGE_KEY = 'expressionpad-state-v1'

export class Store {
  state: AppState
  private listeners = new Set<Listener>()
  private saveTimer: ReturnType<typeof setTimeout> | null = null
  private storageKey: string | null

  constructor(initial?: AppState, storageKey: string | null = null) {
    const base = defaultState()
    if (initial) {
      deepMerge(
        base as unknown as Record<string, unknown>,
        initial as unknown,
      )
    }
    this.state = sanitizeState(base)
    this.storageKey = storageKey
  }

  /** Load persisted state merged over defaults (tolerates stale shapes). */
  static load(storageKey = STORAGE_KEY): Store {
    const base = defaultState()
    try {
      const raw = globalThis.localStorage?.getItem(storageKey)
      if (raw) deepMerge(base as unknown as Record<string, unknown>, JSON.parse(raw))
    } catch {
      // corrupted state — start fresh
    }
    return new Store(sanitizeState(base), storageKey)
  }

  get<T = unknown>(path: string): T {
    let cur: unknown = this.state
    for (const part of path.split('.')) {
      if (cur == null || typeof cur !== 'object') throw new Error(`bad path: ${path}`)
      cur = (cur as Record<string, unknown>)[part]
    }
    return cur as T
  }

  set(path: string, value: unknown): void {
    const parts = path.split('.')
    let cur: Record<string, unknown> = this.state as unknown as Record<string, unknown>
    for (let i = 0; i < parts.length - 1; i++) {
      if (!Object.hasOwn(cur, parts[i])) throw new Error(`bad path: ${path}`)
      const next = cur[parts[i]]
      if (next == null || typeof next !== 'object') throw new Error(`bad path: ${path}`)
      cur = next as Record<string, unknown>
    }
    const leaf = parts[parts.length - 1]
    if (!Object.hasOwn(cur, leaf)) throw new Error(`bad path: ${path}`)
    const previous = cur[leaf]
    if (!sameShape(previous, value) || previous === value) return
    cur[leaf] = value
    sanitizeState(this.state)
    if (cur[leaf] === previous) return
    this.emit(path)
    this.scheduleSave()
  }

  /** Set many paths at once, emitting a single notification per path. */
  patch(values: Record<string, unknown>): void {
    for (const [path, value] of Object.entries(values)) this.set(path, value)
  }

  subscribe(fn: Listener): () => void {
    this.listeners.add(fn)
    return () => this.listeners.delete(fn)
  }

  flushSave(): void {
    if (this.saveTimer) {
      clearTimeout(this.saveTimer)
      this.saveTimer = null
    }
    this.writeState()
  }

  private emit(path: string): void {
    for (const fn of this.listeners) fn(this.state, path)
  }

  private scheduleSave(): void {
    if (!this.storageKey) return
    if (this.saveTimer) clearTimeout(this.saveTimer)
    this.saveTimer = setTimeout(() => {
      this.saveTimer = null
      this.writeState()
    }, 250)
  }

  private writeState(): void {
    if (!this.storageKey) return
    try {
      globalThis.localStorage?.setItem(this.storageKey, JSON.stringify(this.state))
    } catch {
      // storage full or unavailable — non-fatal
    }
  }
}

const LAYOUTS = new Set<LayoutKind>(['square', 'hex', 'piano', 'kbd-chromatic', 'kbd-piano'])
const TABS = new Set<UiConfig['tab']>(['synth', 'smplr', 'fx', 'pad', 'midi'])
const VOICES = new Set<AppState['voice']>(['synth', 'sampler'])
const LFO_TARGETS = new Set<SynthConfig['lfo']['target']>(['pitch', 'filter'])
const SYNTH_PRESETS = new Set([
  'Super Sine', 'Growl Dark', 'Square Tap', 'Pole Position', 'Synolin', 'Saw Demise', 'Room Drill',
])
const SAMPLE_PRESETS = new Set([
  'English Horn', 'Choir', 'Strings', 'E-Piano', 'Marimba', 'Pluck', 'User Sample',
])
const SCHEMES = new Set(['Ocean', 'Magenta', 'Rainbow', 'Mono'])

function finite(value: number, fallback: number, min: number, max: number): number {
  return Number.isFinite(value) ? Math.min(max, Math.max(min, value)) : fallback
}

function integer(value: number, fallback: number, min: number, max: number): number {
  return Math.round(finite(value, fallback, min, max))
}

function bool(value: boolean, fallback: boolean): boolean {
  return typeof value === 'boolean' ? value : fallback
}

function string(value: string, fallback: string, maxLength = 512): string {
  return typeof value === 'string' && value.length <= maxLength ? value : fallback
}

/** Clamp numeric leaves and reject unknown named/enum values at every input boundary. */
export function sanitizeState(state: AppState): AppState {
  const d = defaultState()
  if (!VOICES.has(state.voice)) state.voice = d.voice
  if (!LAYOUTS.has(state.pad.layout)) state.pad.layout = d.pad.layout
  state.pad.rows = integer(state.pad.rows, d.pad.rows, 1, 8)
  state.pad.cols = integer(state.pad.cols, d.pad.cols, 4, 24)
  if (!(state.pad.rowTuning in ROW_TUNINGS)) state.pad.rowTuning = d.pad.rowTuning
  if (!(state.pad.colScale in SCALES)) state.pad.colScale = d.pad.colScale
  state.pad.baseNote = integer(state.pad.baseNote, d.pad.baseNote, 12, 96)
  state.pad.slide = finite(state.pad.slide, d.pad.slide, 0, 1)
  state.pad.frets = bool(state.pad.frets, d.pad.frets)
  state.pad.touchVel = bool(state.pad.touchVel, d.pad.touchVel)
  state.pad.aftertouch = bool(state.pad.aftertouch, d.pad.aftertouch)

  for (const [gen, fallback] of [[state.synth.gen1, d.synth.gen1], [state.synth.gen2, d.synth.gen2]] as const) {
    gen.morph = finite(gen.morph, fallback.morph, 0, 1)
    gen.semi = integer(gen.semi, fallback.semi, -24, 24)
    gen.tune = finite(gen.tune, fallback.tune, -50, 50)
    gen.level = finite(gen.level, fallback.level, 0, 1)
  }
  if (!SYNTH_PRESETS.has(state.synth.preset)) state.synth.preset = d.synth.preset
  state.synth.bright = finite(state.synth.bright, d.synth.bright, 0, 1)
  state.synth.env.a = finite(state.synth.env.a, d.synth.env.a, 0.001, 2)
  state.synth.env.d = finite(state.synth.env.d, d.synth.env.d, 0.01, 3)
  state.synth.env.s = finite(state.synth.env.s, d.synth.env.s, 0, 1)
  state.synth.env.r = finite(state.synth.env.r, d.synth.env.r, 0.02, 5)
  state.synth.filter.cutoff = finite(state.synth.filter.cutoff, d.synth.filter.cutoff, 0, 1)
  state.synth.filter.res = finite(state.synth.filter.res, d.synth.filter.res, 0, 1)
  state.synth.filter.env = finite(state.synth.filter.env, d.synth.filter.env, 0, 1)
  state.synth.lfo.rate = finite(state.synth.lfo.rate, d.synth.lfo.rate, 0.05, 30)
  state.synth.lfo.depth = finite(state.synth.lfo.depth, d.synth.lfo.depth, 0, 1)
  if (!LFO_TARGETS.has(state.synth.lfo.target)) state.synth.lfo.target = d.synth.lfo.target
  state.synth.level = finite(state.synth.level, d.synth.level, 0, 1)

  if (!SAMPLE_PRESETS.has(state.sampler.preset)) state.sampler.preset = d.sampler.preset
  state.sampler.level = finite(state.sampler.level, d.sampler.level, 0, 1)
  state.sampler.attack = finite(state.sampler.attack, d.sampler.attack, 0.002, 0.5)
  state.sampler.release = finite(state.sampler.release, d.sampler.release, 0.02, 3)
  state.sampler.retrig = bool(state.sampler.retrig, d.sampler.retrig)
  state.sampler.userRoot = integer(state.sampler.userRoot, d.sampler.userRoot, 24, 96)

  state.fx.reverb.fdbk = finite(state.fx.reverb.fdbk, d.fx.reverb.fdbk, 0, 1)
  state.fx.reverb.mix = finite(state.fx.reverb.mix, d.fx.reverb.mix, 0, 1)
  state.fx.reverb.on = bool(state.fx.reverb.on, d.fx.reverb.on)
  state.fx.delay.time = finite(state.fx.delay.time, d.fx.delay.time, 0.01, 2)
  state.fx.delay.fdbk = finite(state.fx.delay.fdbk, d.fx.delay.fdbk, 0, 0.9)
  state.fx.delay.mix = finite(state.fx.delay.mix, d.fx.delay.mix, 0, 1)
  state.fx.delay.on = bool(state.fx.delay.on, d.fx.delay.on)
  state.fx.distort.amt = finite(state.fx.distort.amt, d.fx.distort.amt, 0, 1)
  state.fx.distort.on = bool(state.fx.distort.on, d.fx.distort.on)
  state.fx.fatten.amt = finite(state.fx.fatten.amt, d.fx.fatten.amt, 0, 1)
  state.fx.fatten.on = bool(state.fx.fatten.on, d.fx.fatten.on)

  state.midi.bendRange = integer(state.midi.bendRange, d.midi.bendRange, 1, 96)
  state.midi.outEnabled = bool(state.midi.outEnabled, d.midi.outEnabled)
  state.midi.outputId = string(state.midi.outputId, d.midi.outputId)
  state.midi.sendY = bool(state.midi.sendY, d.midi.sendY)
  state.midi.inEnabled = bool(state.midi.inEnabled, d.midi.inEnabled)
  state.midi.inputId = string(state.midi.inputId, d.midi.inputId)
  state.midi.localSound = bool(state.midi.localSound, d.midi.localSound)
  if (!SCHEMES.has(state.appearance.scheme)) state.appearance.scheme = d.appearance.scheme
  state.appearance.labels = bool(state.appearance.labels, d.appearance.labels)
  state.appearance.brightness = finite(state.appearance.brightness, d.appearance.brightness, 0, 1)
  state.appearance.ripples = bool(state.appearance.ripples, d.appearance.ripples)
  state.appearance.rippleAmount = finite(state.appearance.rippleAmount, d.appearance.rippleAmount, 0, 1)
  state.appearance.contrast = finite(state.appearance.contrast, d.appearance.contrast, 0, 1)
  state.ui.panelOpen = bool(state.ui.panelOpen, d.ui.panelOpen)
  if (!TABS.has(state.ui.tab)) state.ui.tab = d.ui.tab
  return state
}

function sameShape(a: unknown, b: unknown): boolean {
  return typeof a === typeof b && Array.isArray(a) === Array.isArray(b)
}

function deepMerge(target: Record<string, unknown>, src: unknown): void {
  if (src == null || typeof src !== 'object') return
  for (const [k, v] of Object.entries(src as Record<string, unknown>)) {
    if (!(k in target)) continue
    const t = target[k]
    if (t != null && typeof t === 'object' && !Array.isArray(t) && v != null && typeof v === 'object') {
      deepMerge(t as Record<string, unknown>, v)
    } else if (typeof t === typeof v && Array.isArray(t) === Array.isArray(v)) {
      target[k] = v
    }
  }
}
