/// Note naming, MIDI note numbers, and frequency conversion.
import Foundation

public let NOTE_NAMES = ["C", "C#", "D", "Eb", "E", "F", "F#", "G", "Ab", "A", "Bb", "B"]

public let A4_MIDI = 69.0
public let A4_FREQ = 440.0

/// Convert a (possibly fractional) MIDI note number to frequency in Hz.
@inlinable public func midiToFreq(_ midi: Double) -> Double {
    A4_FREQ * pow(2, (midi - A4_MIDI) / 12)
}

/// Pitch class 0–11 of a MIDI note (rounded to nearest semitone).
public func pitchClass(_ midi: Double) -> Int {
    (Int(midi.rounded()) % 12 + 12) % 12
}

public func pitchClass(_ midi: Int) -> Int {
    (midi % 12 + 12) % 12
}

/// Octave number using the MIDI convention where C4 = 60.
public func octaveOf(_ midi: Int) -> Int {
    Int(floor(Double(midi) / 12)) - 1
}

public func noteName(_ midi: Int, withOctave: Bool = false) -> String {
    let name = NOTE_NAMES[pitchClass(midi)]
    return withOctave ? "\(name)\(octaveOf(midi))" : name
}

/// Parse names like "C4", "F#3", "Eb2" to a MIDI note number.
public func noteFromName(_ name: String) -> Int? {
    var chars = Array(name.trimmingCharacters(in: .whitespaces))
    guard !chars.isEmpty else { return nil }
    let baseMap: [Character: Int] = ["C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11]
    guard var pc = baseMap[Character(chars.removeFirst().uppercased())] else { return nil }
    if chars.first == "#" {
        pc += 1
        chars.removeFirst()
    } else if chars.first == "b" {
        pc -= 1
        chars.removeFirst()
    }
    guard let octave = Int(String(chars)) else { return nil }
    return (octave + 1) * 12 + pc
}

@inlinable public func clampMidi(_ midi: Double) -> Double {
    min(127, max(0, midi))
}
