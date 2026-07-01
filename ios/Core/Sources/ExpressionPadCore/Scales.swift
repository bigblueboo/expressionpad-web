/// Scales for column pitch mapping and row tunings for vertical intervals.

public let SCALES: [String: [Int]] = [
    "Chromatic": [1],
    "Major": [2, 2, 1, 2, 2, 2, 1],
    "Natural Minor": [2, 1, 2, 2, 1, 2, 2],
    "Harmonic Minor": [2, 1, 2, 2, 1, 3, 1],
    "Dorian": [2, 1, 2, 2, 2, 1, 2],
    "Mixolydian": [2, 2, 1, 2, 2, 1, 2],
    "Major Pentatonic": [2, 2, 3, 2, 3],
    "Minor Pentatonic": [3, 2, 2, 3, 2],
    "Blues": [3, 2, 1, 1, 3, 2],
    "Whole Tone": [2],
]

/// Menu order matches the web build (insertion order of its object literal).
public let SCALE_NAMES = [
    "Chromatic", "Major", "Natural Minor", "Harmonic Minor", "Dorian",
    "Mixolydian", "Major Pentatonic", "Minor Pentatonic", "Blues", "Whole Tone",
]

/// Semitone offset of scale degree `degree` (0 = root). Negative degrees walk
/// down through the scale, so degree -1 of Major is -1 (the leading tone below).
public func degreeToSemitones(_ scale: [Int], _ degree: Int) -> Int {
    let n = scale.count
    var semis = 0
    if degree >= 0 {
        for i in 0..<degree { semis += scale[i % n] }
    } else {
        var i = -1
        while i >= degree {
            semis -= scale[((i % n) + n) % n]
            i -= 1
        }
    }
    return semis
}

public struct RowTuning {
    /// Fixed interval between adjacent rows, in semitones.
    public var interval: Int?
    /// Explicit per-row offsets (e.g. guitar tunings). Rows beyond the array continue in fourths.
    public var offsets: [Int]?
}

public let ROW_TUNINGS: [String: RowTuning] = [
    "Seconds [+2]": RowTuning(interval: 2),
    "Minor 3rd [+3]": RowTuning(interval: 3),
    "Major 3rd [+4]": RowTuning(interval: 4),
    "Fourths [+5]": RowTuning(interval: 5),
    "Fifths [+7]": RowTuning(interval: 7),
    "Octaves [+12]": RowTuning(interval: 12),
    "Guitar EADGBE": RowTuning(offsets: [0, 5, 10, 15, 19, 24]),
    "Open C CGCGCE": RowTuning(offsets: [0, 7, 12, 19, 24, 28]),
]

public let ROW_TUNING_NAMES = [
    "Seconds [+2]", "Minor 3rd [+3]", "Major 3rd [+4]", "Fourths [+5]",
    "Fifths [+7]", "Octaves [+12]", "Guitar EADGBE", "Open C CGCGCE",
]

/// Semitone offset of each row (row 0 = bottom) for the given tuning.
public func rowOffsets(_ tuningName: String, _ rows: Int) -> [Int] {
    let tuning = ROW_TUNINGS[tuningName] ?? ROW_TUNINGS["Fourths [+5]"]!
    var out: [Int] = []
    for r in 0..<rows {
        if let interval = tuning.interval {
            out.append(r * interval)
        } else if let offsets = tuning.offsets {
            if r < offsets.count {
                out.append(offsets[r])
            } else {
                out.append(offsets[offsets.count - 1] + (r - offsets.count + 1) * 5)
            }
        }
    }
    return out
}
