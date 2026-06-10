import { describe, expect, it } from 'vitest'
import {
  degreeToSemitones, ROW_TUNING_NAMES, rowOffsets, SCALE_NAMES, SCALES,
} from '../src/core/scales'

describe('scales', () => {
  it('chromatic degrees are semitones', () => {
    for (let d = -13; d <= 13; d++) {
      expect(degreeToSemitones(SCALES.Chromatic, d)).toBe(d)
    }
  })

  it('major scale walks W-W-H-W-W-W-H', () => {
    const major = SCALES.Major
    expect([0, 1, 2, 3, 4, 5, 6, 7].map((d) => degreeToSemitones(major, d)))
      .toEqual([0, 2, 4, 5, 7, 9, 11, 12])
  })

  it('negative degrees walk down through the scale', () => {
    const major = SCALES.Major
    expect(degreeToSemitones(major, -1)).toBe(-1) // leading tone below root
    expect(degreeToSemitones(major, -2)).toBe(-3)
    expect(degreeToSemitones(major, -7)).toBe(-12) // full octave down
  })

  it('pentatonic spans an octave in 5 degrees', () => {
    expect(degreeToSemitones(SCALES['Major Pentatonic'], 5)).toBe(12)
    expect(degreeToSemitones(SCALES['Minor Pentatonic'], 5)).toBe(12)
  })

  it('every scale spans exactly one octave', () => {
    for (const name of SCALE_NAMES) {
      const scale = SCALES[name]
      const sum = scale.reduce((a, b) => a + b, 0)
      expect(12 % sum, `${name} must divide the octave`).toBe(0)
    }
  })

  it('fixed-interval row tunings are multiples', () => {
    expect(rowOffsets('Fourths [+5]', 4)).toEqual([0, 5, 10, 15])
    expect(rowOffsets('Fifths [+7]', 3)).toEqual([0, 7, 14])
    expect(rowOffsets('Octaves [+12]', 2)).toEqual([0, 12])
  })

  it('guitar tuning matches EADGBE intervals', () => {
    expect(rowOffsets('Guitar EADGBE', 6)).toEqual([0, 5, 10, 15, 19, 24])
  })

  it('extends explicit tunings in fourths beyond their length', () => {
    const offsets = rowOffsets('Guitar EADGBE', 8)
    expect(offsets[6]).toBe(29)
    expect(offsets[7]).toBe(34)
  })

  it('falls back to fourths for unknown tuning names', () => {
    expect(rowOffsets('Nonsense', 3)).toEqual([0, 5, 10])
  })

  it('exposes name lists for the UI', () => {
    expect(SCALE_NAMES).toContain('Chromatic')
    expect(ROW_TUNING_NAMES).toContain('Fourths [+5]')
  })
})
