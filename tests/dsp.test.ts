import { describe, expect, it } from 'vitest'
import {
  clamp, cutoffToHz, driveCurve, harmonicAmps, impulseResponse, lerp,
  partialsToWave, velocityToGain,
} from '../src/audio/dsp'

describe('dsp helpers', () => {
  it('clamp and lerp behave', () => {
    expect(clamp(5, 0, 1)).toBe(1)
    expect(clamp(-1, 0, 1)).toBe(0)
    expect(lerp(0, 10, 0.5)).toBe(5)
  })

  it('morph 0 is a pure sine (single partial)', () => {
    const amps = harmonicAmps(0, 0.5)
    expect(Math.abs(amps[0])).toBeCloseTo(1)
    for (const a of amps.slice(1)) expect(Math.abs(a)).toBeLessThan(0.01)
  })

  it('morph 1 is square-like (odd harmonics only)', () => {
    const amps = harmonicAmps(1, 0.5)
    for (let k = 2; k <= amps.length; k += 2) {
      expect(Math.abs(amps[k - 1])).toBeLessThan(0.01)
    }
    expect(Math.abs(amps[2])).toBeGreaterThan(0.05) // 3rd harmonic present
  })

  it('saw region has even harmonics', () => {
    const amps = harmonicAmps(0.66, 0.5)
    expect(Math.abs(amps[1])).toBeGreaterThan(0.05) // 2nd harmonic present
  })

  it('amps are normalized to peak 1', () => {
    for (const morph of [0, 0.25, 0.5, 0.75, 1]) {
      for (const bright of [0, 0.5, 1]) {
        const amps = harmonicAmps(morph, bright)
        const peak = Math.max(...amps.map(Math.abs))
        expect(peak).toBeCloseTo(1)
      }
    }
  })

  it('brightness lifts upper harmonics', () => {
    const dark = harmonicAmps(0.66, 0)
    const bright = harmonicAmps(0.66, 1)
    expect(Math.abs(bright[15])).toBeGreaterThan(Math.abs(dark[15]))
  })

  it('partialsToWave puts amps in imag with DC zero', () => {
    const { real, imag } = partialsToWave([0.5, 0.25])
    expect(real).toHaveLength(3)
    expect(imag[0]).toBe(0)
    expect(imag[1]).toBe(0.5)
    expect(imag[2]).toBe(0.25)
    for (const r of real) expect(r).toBe(0)
  })

  it('impulse response decays toward zero', () => {
    const [left, right] = impulseResponse(0.5, 3, 8000, 2, () => 0.99)
    expect(left).toHaveLength(4000)
    expect(Math.abs(left[0])).toBeGreaterThan(Math.abs(left[3000]))
    expect(Math.abs(left[3999])).toBeLessThan(0.01)
    expect(right).toHaveLength(4000)
  })

  it('impulse samples stay within ±1', () => {
    for (const ch of impulseResponse(0.2, 2, 8000)) {
      for (const s of ch) {
        expect(s).toBeGreaterThanOrEqual(-1)
        expect(s).toBeLessThanOrEqual(1)
      }
    }
  })

  it('drive curve is bounded, odd-symmetric, and monotonic', () => {
    const curve = driveCurve(0.7, 257)
    expect(curve[0]).toBeCloseTo(-1, 1)
    expect(curve[256]).toBeCloseTo(1, 1)
    expect(curve[128]).toBeCloseTo(0, 5)
    for (let i = 1; i < curve.length; i++) {
      expect(curve[i]).toBeGreaterThanOrEqual(curve[i - 1])
    }
  })

  it('cutoff maps 0..1 to audible log range', () => {
    expect(cutoffToHz(0)).toBeCloseTo(40)
    expect(cutoffToHz(1)).toBeGreaterThan(15000)
    expect(cutoffToHz(0.5)).toBeGreaterThan(cutoffToHz(0.4))
  })

  it('velocity curve is monotonic in 0..1', () => {
    let prev = -1
    for (let v = 0; v <= 1.001; v += 0.05) {
      const g = velocityToGain(v)
      expect(g).toBeGreaterThanOrEqual(prev)
      expect(g).toBeLessThanOrEqual(1)
      prev = g
    }
    expect(velocityToGain(0)).toBe(0)
  })
})
