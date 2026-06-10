import { describe, expect, it } from 'vitest'
import { renderSample, SAMPLE_NAMES, USER_PRESET } from '../src/audio/samplegen'

const SR = 8000

describe('sample generators', () => {
  it('exposes a non-empty instrument list', () => {
    expect(SAMPLE_NAMES.length).toBeGreaterThanOrEqual(5)
    expect(SAMPLE_NAMES).toContain('English Horn') // the original's EnglishHrn
    expect(SAMPLE_NAMES).not.toContain(USER_PRESET)
  })

  it('every instrument renders bounded, non-silent PCM with a sane root', () => {
    for (const name of SAMPLE_NAMES) {
      const s = renderSample(name, SR)
      expect(s.data.length, name).toBeGreaterThan(SR / 2)
      expect(s.root, name).toBeGreaterThanOrEqual(36)
      expect(s.root, name).toBeLessThanOrEqual(84)
      let peak = 0
      for (const v of s.data) {
        expect(Math.abs(v), name).toBeLessThanOrEqual(1)
        peak = Math.max(peak, Math.abs(v))
      }
      expect(peak, name).toBeGreaterThan(0.5)
    }
  })

  it('sustained instruments have valid loop windows', () => {
    for (const name of ['English Horn', 'Choir', 'Strings']) {
      const s = renderSample(name, SR)
      expect(s.loopStart, name).toBeDefined()
      expect(s.loopEnd, name).toBe(s.data.length)
      expect(s.loopEnd! - s.loopStart!, name).toBe(SR) // exactly 1 s
    }
  })

  it('loop points are click-free (wrap step ≈ adjacent-sample step)', () => {
    for (const name of ['English Horn', 'Choir', 'Strings']) {
      const s = renderSample(name, SR)
      let maxStep = 0
      for (let i = s.loopStart! + 1; i < s.loopEnd!; i++) {
        maxStep = Math.max(maxStep, Math.abs(s.data[i] - s.data[i - 1]))
      }
      const wrapStep = Math.abs(s.data[s.loopStart!] - s.data[s.loopEnd! - 1])
      expect(wrapStep, name).toBeLessThanOrEqual(maxStep * 1.5)
    }
  })

  it('one-shots decay to near silence', () => {
    for (const name of ['E-Piano', 'Marimba', 'Pluck']) {
      const s = renderSample(name, SR)
      expect(s.loopStart, name).toBeUndefined()
      const tail = s.data.slice(Math.floor(s.data.length * 0.95))
      const head = s.data.slice(0, Math.floor(s.data.length * 0.2))
      const rms = (a: Float32Array) =>
        Math.sqrt(a.reduce((acc, v) => acc + v * v, 0) / a.length)
      expect(rms(tail), name).toBeLessThan(rms(head) * 0.3)
    }
  })

  it('renders are deterministic', () => {
    const a = renderSample('Pluck', SR)
    const b = renderSample('Pluck', SR)
    expect(a.data).toEqual(b.data)
  })

  it('unknown names fall back to the first instrument', () => {
    const a = renderSample('Nonsense', SR)
    const b = renderSample(SAMPLE_NAMES[0], SR)
    expect(a.root).toBe(b.root)
    expect(a.data.length).toBe(b.data.length)
  })
})
