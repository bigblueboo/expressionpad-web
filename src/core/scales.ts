/** Scales for column pitch mapping and row tunings for vertical intervals. */

export const SCALES: Record<string, number[]> = {
  Chromatic: [1],
  Major: [2, 2, 1, 2, 2, 2, 1],
  'Natural Minor': [2, 1, 2, 2, 1, 2, 2],
  'Harmonic Minor': [2, 1, 2, 2, 1, 3, 1],
  Dorian: [2, 1, 2, 2, 2, 1, 2],
  Mixolydian: [2, 2, 1, 2, 2, 1, 2],
  'Major Pentatonic': [2, 2, 3, 2, 3],
  'Minor Pentatonic': [3, 2, 2, 3, 2],
  Blues: [3, 2, 1, 1, 3, 2],
  'Whole Tone': [2],
}

export const SCALE_NAMES = Object.keys(SCALES)

/**
 * Semitone offset of scale degree `degree` (0 = root). Negative degrees walk
 * down through the scale, so degree -1 of Major is -1 (the leading tone below).
 */
export function degreeToSemitones(scale: number[], degree: number): number {
  const n = scale.length
  let semis = 0
  if (degree >= 0) {
    for (let i = 0; i < degree; i++) semis += scale[i % n]
  } else {
    for (let i = -1; i >= degree; i--) {
      semis -= scale[(((i % n) + n) % n)]
    }
  }
  return semis
}

export interface RowTuning {
  /** Fixed interval between adjacent rows, in semitones. */
  interval?: number
  /** Explicit per-row offsets (e.g. guitar tunings). Rows beyond the array continue in fourths. */
  offsets?: number[]
}

export const ROW_TUNINGS: Record<string, RowTuning> = {
  'Seconds [+2]': { interval: 2 },
  'Minor 3rd [+3]': { interval: 3 },
  'Major 3rd [+4]': { interval: 4 },
  'Fourths [+5]': { interval: 5 },
  'Fifths [+7]': { interval: 7 },
  'Octaves [+12]': { interval: 12 },
  'Guitar EADGBE': { offsets: [0, 5, 10, 15, 19, 24] },
  'Open C CGCGCE': { offsets: [0, 7, 12, 19, 24, 28] },
}

export const ROW_TUNING_NAMES = Object.keys(ROW_TUNINGS)

/** Semitone offset of each row (row 0 = bottom) for the given tuning. */
export function rowOffsets(tuningName: string, rows: number): number[] {
  const tuning = ROW_TUNINGS[tuningName] ?? ROW_TUNINGS['Fourths [+5]']
  const out: number[] = []
  for (let r = 0; r < rows; r++) {
    if (tuning.interval !== undefined) {
      out.push(r * tuning.interval)
    } else if (tuning.offsets) {
      if (r < tuning.offsets.length) out.push(tuning.offsets[r])
      else out.push(tuning.offsets[tuning.offsets.length - 1] + (r - tuning.offsets.length + 1) * 5)
    }
  }
  return out
}
