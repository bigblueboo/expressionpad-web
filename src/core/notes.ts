/** Note naming, MIDI note numbers, and frequency conversion. */

export const NOTE_NAMES = [
  'C', 'C#', 'D', 'Eb', 'E', 'F', 'F#', 'G', 'Ab', 'A', 'Bb', 'B',
] as const

export const A4_MIDI = 69
export const A4_FREQ = 440

/** Convert a (possibly fractional) MIDI note number to frequency in Hz. */
export function midiToFreq(midi: number): number {
  return A4_FREQ * Math.pow(2, (midi - A4_MIDI) / 12)
}

/** Pitch class 0–11 of a MIDI note (rounded to nearest semitone). */
export function pitchClass(midi: number): number {
  return ((Math.round(midi) % 12) + 12) % 12
}

/** Octave number using the MIDI convention where C4 = 60. */
export function octaveOf(midi: number): number {
  return Math.floor(Math.round(midi) / 12) - 1
}

export function noteName(midi: number, withOctave = false): string {
  const name = NOTE_NAMES[pitchClass(midi)]
  return withOctave ? `${name}${octaveOf(midi)}` : name
}

/** Parse names like "C4", "F#3", "Eb2" to a MIDI note number. */
export function noteFromName(name: string): number {
  const m = /^([A-Ga-g])([#b]?)(-?\d+)$/.exec(name.trim())
  if (!m) throw new Error(`unparseable note name: ${name}`)
  const baseMap: Record<string, number> = { C: 0, D: 2, E: 4, F: 5, G: 7, A: 9, B: 11 }
  let pc = baseMap[m[1].toUpperCase()]
  if (m[2] === '#') pc += 1
  if (m[2] === 'b') pc -= 1
  return (parseInt(m[3], 10) + 1) * 12 + pc
}

export function clampMidi(midi: number): number {
  return Math.min(127, Math.max(0, midi))
}
