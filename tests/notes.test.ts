import { describe, expect, it } from 'vitest'
import {
  clampMidi, midiToFreq, noteFromName, noteName, octaveOf, pitchClass,
} from '../src/core/notes'

describe('notes', () => {
  it('converts MIDI to frequency (A4 = 440)', () => {
    expect(midiToFreq(69)).toBeCloseTo(440)
    expect(midiToFreq(81)).toBeCloseTo(880)
    expect(midiToFreq(60)).toBeCloseTo(261.626, 2)
  })

  it('handles fractional pitches for continuous bends', () => {
    expect(midiToFreq(69.5)).toBeGreaterThan(440)
    expect(midiToFreq(69.5)).toBeLessThan(midiToFreq(70))
    // One cent above A4.
    expect(midiToFreq(69.01)).toBeCloseTo(440 * Math.pow(2, 1 / 1200), 4)
  })

  it('computes pitch class and octave', () => {
    expect(pitchClass(60)).toBe(0)
    expect(pitchClass(61)).toBe(1)
    expect(pitchClass(59)).toBe(11)
    expect(octaveOf(60)).toBe(4)
    expect(octaveOf(48)).toBe(3)
  })

  it('names notes with and without octave', () => {
    expect(noteName(60)).toBe('C')
    expect(noteName(60, true)).toBe('C4')
    expect(noteName(63, true)).toBe('Eb4')
    expect(noteName(66)).toBe('F#')
  })

  it('parses note names', () => {
    expect(noteFromName('C4')).toBe(60)
    expect(noteFromName('A4')).toBe(69)
    expect(noteFromName('F#3')).toBe(54)
    expect(noteFromName('Eb2')).toBe(39)
    expect(() => noteFromName('H4')).toThrow()
  })

  it('round-trips name → midi → name', () => {
    for (const m of [21, 48, 60, 69, 100]) {
      expect(noteFromName(noteName(m, true))).toBe(m)
    }
  })

  it('clamps to valid MIDI range', () => {
    expect(clampMidi(-5)).toBe(0)
    expect(clampMidi(200)).toBe(127)
    expect(clampMidi(64)).toBe(64)
  })
})
