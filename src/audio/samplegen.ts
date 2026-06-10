/**
 * Built-in instrument samples, rendered as PCM with plain math so they ship
 * as code, not audio files — and stay unit-testable.
 *
 * Sustained instruments are built from components whose frequencies all
 * complete an integer number of cycles over the loop window, so the loop
 * point is mathematically click-free. Detunes are ±1 Hz (integer cycles over
 * a 1 s loop) which gives slow ensemble beating that survives the loop.
 */

export interface RenderedSample {
  data: Float32Array<ArrayBuffer>
  /** MIDI note the sample is pitched at. */
  root: number
  /** Loop window in samples; absent = one-shot. */
  loopStart?: number
  loopEnd?: number
}

interface Component {
  freq: number
  amp: number
  /** Exponential decay rate (1/s); 0 = sustain. */
  decay?: number
  /** FM: modulator freq and index (for e-piano bark). */
  fmFreq?: number
  fmIndex?: number
}

function normalize(data: Float32Array<ArrayBuffer>, peak = 0.9): Float32Array<ArrayBuffer> {
  let max = 0
  for (const s of data) max = Math.max(max, Math.abs(s))
  if (max > 0) {
    const k = peak / max
    for (let i = 0; i < data.length; i++) data[i] *= k
  }
  return data
}

function renderComponents(
  sr: number,
  seconds: number,
  components: Component[],
  envelope: (t: number) => number,
): Float32Array<ArrayBuffer> {
  const len = Math.round(seconds * sr)
  const data = new Float32Array(len)
  for (let i = 0; i < len; i++) {
    const t = i / sr
    let s = 0
    for (const c of components) {
      const fm = c.fmFreq ? c.fmIndex! * Math.sin(2 * Math.PI * c.fmFreq * t) : 0
      const d = c.decay ? Math.exp(-c.decay * t) : 1
      s += c.amp * d * Math.sin(2 * Math.PI * c.freq * t + fm)
    }
    data[i] = s * envelope(t)
  }
  return normalize(data)
}

/** Sustained, looping instrument: attack segment + a 1 s loop window. */
function sustained(sr: number, root: number, components: Component[], attack: number): RenderedSample {
  const loopSec = 1
  const seconds = attack + loopSec
  const env = (t: number) => (t < attack ? (t / attack) * (t / attack) : 1)
  const data = renderComponents(sr, seconds, components, env)
  return { data, root, loopStart: Math.round(attack * sr), loopEnd: data.length }
}

function oneShot(sr: number, root: number, seconds: number, components: Component[]): RenderedSample {
  const env = (t: number) => Math.min(1, t * 400) // 2.5 ms anti-click ramp
  return { data: renderComponents(sr, seconds, components, env), root }
}

/** Karplus-Strong plucked string. */
function pluck(sr: number, root: number, freq: number, seconds: number): RenderedSample {
  const n = Math.max(2, Math.round(sr / freq))
  const delay = new Float32Array(n)
  // Deterministic noise so renders are reproducible.
  let seed = 1234567
  const rand = () => {
    seed = (seed * 1103515245 + 12345) & 0x7fffffff
    return seed / 0x7fffffff - 0.5
  }
  for (let i = 0; i < n; i++) delay[i] = rand() * 2
  const len = Math.round(seconds * sr)
  const data = new Float32Array(len)
  let idx = 0
  for (let i = 0; i < len; i++) {
    const next = delay[(idx + 1) % n]
    const cur = delay[idx]
    const avg = 0.5 * (cur + next) * 0.996
    data[i] = cur
    delay[idx] = avg
    idx = (idx + 1) % n
  }
  return { data: normalize(data), root }
}

// 220 Hz = A3 (midi 57) exactly; 110 Hz = A2 (midi 45); 440 Hz = A4 (midi 69).

const BUILDERS: Record<string, (sr: number) => RenderedSample> = {
  'English Horn': (sr) =>
    sustained(sr, 57, [
      { freq: 220, amp: 0.4 }, { freq: 440, amp: 0.75 }, { freq: 660, amp: 1.0 },
      { freq: 880, amp: 0.95 }, { freq: 1100, amp: 0.6 }, { freq: 1320, amp: 0.35 },
      { freq: 1540, amp: 0.22 }, { freq: 1760, amp: 0.12 }, { freq: 1980, amp: 0.06 },
    ], 0.12),
  Choir: (sr) =>
    sustained(sr, 57, [
      { freq: 220, amp: 1.0 }, { freq: 219, amp: 0.6 }, { freq: 221, amp: 0.6 },
      { freq: 440, amp: 0.45 }, { freq: 441, amp: 0.3 },
      { freq: 660, amp: 0.18 }, { freq: 880, amp: 0.4 }, { freq: 1100, amp: 0.25 },
      { freq: 1320, amp: 0.07 },
    ], 0.35),
  Strings: (sr) => {
    const comps: Component[] = []
    for (let k = 1; k <= 14; k++) {
      const amp = (1 / k) * Math.pow(0.92, k)
      comps.push({ freq: 110 * k, amp })
      if (k <= 4) {
        comps.push({ freq: 110 * k + 1, amp: amp * 0.6 })
        comps.push({ freq: 110 * k - 1, amp: amp * 0.6 })
      }
    }
    return sustained(sr, 45, comps, 0.3)
  },
  'E-Piano': (sr) =>
    oneShot(sr, 60, 3.2, [
      { freq: 261.63, amp: 1.0, decay: 1.1 },
      { freq: 523.26, amp: 0.4, decay: 2.4 },
      { freq: 1046.5, amp: 0.25, decay: 6, fmFreq: 261.63, fmIndex: 1.4 },
      { freq: 2093.0, amp: 0.08, decay: 12 },
    ]),
  Marimba: (sr) =>
    oneShot(sr, 69, 1.8, [
      { freq: 440, amp: 1.0, decay: 4.5 },
      { freq: 1760, amp: 0.5, decay: 16 },
      { freq: 4048, amp: 0.25, decay: 40 },
    ]),
  Pluck: (sr) => pluck(sr, 57, 220, 2.5),
}

export const SAMPLE_NAMES = Object.keys(BUILDERS)

export const USER_PRESET = 'User Sample'

export function renderSample(name: string, sampleRate: number): RenderedSample {
  const builder = BUILDERS[name] ?? BUILDERS[SAMPLE_NAMES[0]]
  return builder(sampleRate)
}
