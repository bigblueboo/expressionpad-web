/** App state: a small path-addressable store with subscriptions + persistence. */
import type { LayoutKind } from './layout'

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
}

export interface UiConfig {
  panelOpen: boolean
  tab: 'synth' | 'fx' | 'pad' | 'midi'
}

export interface AppState {
  pad: PadConfig
  synth: SynthConfig
  fx: FxConfig
  midi: MidiConfig
  appearance: AppearanceConfig
  ui: UiConfig
}

export function defaultState(): AppState {
  return {
    pad: {
      layout: 'square', rows: 4, cols: 12,
      rowTuning: 'Fourths [+5]', colScale: 'Chromatic', baseNote: 48,
      slide: 0.35, frets: false, touchVel: true, aftertouch: true,
    },
    synth: {
      preset: 'Super Sine',
      gen1: { morph: 0.1, semi: 0, tune: 0, level: 0.8 },
      gen2: { morph: 0.3, semi: 12, tune: 4, level: 0.25 },
      bright: 0.5,
      env: { a: 0.01, d: 0.25, s: 0.7, r: 0.3 },
      filter: { cutoff: 0.75, res: 0.15, env: 0.3 },
      lfo: { rate: 5, depth: 0.1, target: 'pitch' },
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
    appearance: { scheme: 'Ocean', labels: true, brightness: 0.65, ripples: true },
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
    this.state = initial ?? defaultState()
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
    return new Store(base, storageKey)
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
      cur = cur[parts[i]] as Record<string, unknown>
      if (cur == null) throw new Error(`bad path: ${path}`)
    }
    if (cur[parts[parts.length - 1]] === value) return
    cur[parts[parts.length - 1]] = value
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

  private emit(path: string): void {
    for (const fn of this.listeners) fn(this.state, path)
  }

  private scheduleSave(): void {
    if (!this.storageKey) return
    if (this.saveTimer) clearTimeout(this.saveTimer)
    this.saveTimer = setTimeout(() => {
      try {
        globalThis.localStorage?.setItem(this.storageKey!, JSON.stringify(this.state))
      } catch {
        // storage full or unavailable — non-fatal
      }
    }, 250)
  }
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
