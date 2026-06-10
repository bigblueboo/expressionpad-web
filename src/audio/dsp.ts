/** Pure DSP math — kept free of Web Audio objects so it is unit-testable. */

export function clamp(v: number, lo: number, hi: number): number {
  return Math.min(hi, Math.max(lo, v))
}

export function lerp(a: number, b: number, t: number): number {
  return a + (b - a) * t
}

export const PARTIAL_COUNT = 32

/**
 * Additive harmonic amplitude recipe.
 * morph 0..1 sweeps sine → triangle → saw → square; bright tilts the
 * harmonic rolloff darker (0) or brighter (1).
 */
export function harmonicAmps(morph: number, bright: number, n = PARTIAL_COUNT): number[] {
  const m = clamp(morph, 0, 1)
  const recipes: Array<(k: number) => number> = [
    (k) => (k === 1 ? 1 : 0), // sine
    (k) => (k % 2 === 1 ? ((k % 4 === 1 ? 1 : -1) * 1) / (k * k) : 0), // triangle
    (k) => 1 / k, // saw
    (k) => (k % 2 === 1 ? 1 / k : 0), // square
  ]
  const seg = m * (recipes.length - 1)
  const i = Math.min(recipes.length - 2, Math.floor(seg))
  const t = seg - i
  const tilt = lerp(-0.9, 0.7, clamp(bright, 0, 1))
  const amps: number[] = []
  let peak = 0
  for (let k = 1; k <= n; k++) {
    let a = lerp(recipes[i](k), recipes[i + 1](k), t)
    if (k > 1) a *= Math.pow(k, tilt)
    amps.push(a)
    peak = Math.max(peak, Math.abs(a))
  }
  return peak > 0 ? amps.map((a) => a / peak) : amps
}

/** Fourier coefficients for a PeriodicWave (sine-phase partials). */
export function partialsToWave(amps: number[]): { real: Float32Array<ArrayBuffer>; imag: Float32Array<ArrayBuffer> } {
  const real = new Float32Array(amps.length + 1)
  const imag = new Float32Array(amps.length + 1)
  for (let k = 0; k < amps.length; k++) imag[k + 1] = amps[k]
  return { real, imag }
}

/** Exponentially decaying noise impulse response for the convolver reverb. */
export function impulseResponse(
  seconds: number,
  decay: number,
  sampleRate: number,
  channels = 2,
  random: () => number = Math.random,
): Float32Array<ArrayBuffer>[] {
  const len = Math.max(1, Math.floor(seconds * sampleRate))
  const out: Float32Array<ArrayBuffer>[] = []
  for (let c = 0; c < channels; c++) {
    const buf = new Float32Array(len)
    for (let s = 0; s < len; s++) {
      buf[s] = (random() * 2 - 1) * Math.pow(1 - s / len, decay)
    }
    out.push(buf)
  }
  return out
}

/** Soft-clip waveshaper curve; amount 0..1. */
export function driveCurve(amount: number, n = 1024): Float32Array<ArrayBuffer> {
  const k = 1 + clamp(amount, 0, 1) * 30
  const curve = new Float32Array(n)
  const norm = Math.tanh(k)
  for (let s = 0; s < n; s++) {
    const x = (s / (n - 1)) * 2 - 1
    curve[s] = Math.tanh(k * x) / norm
  }
  return curve
}

/** Map normalized filter cutoff 0..1 to Hz on a log scale. */
export function cutoffToHz(norm: number): number {
  return 40 * Math.pow(2, clamp(norm, 0, 1) * 9) // 40 Hz .. ~20.5 kHz
}

/** Perceptual velocity → gain. */
export function velocityToGain(vel: number): number {
  const v = clamp(vel, 0, 1)
  return v * v * 0.85 + v * 0.15
}
