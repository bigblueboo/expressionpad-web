import Testing
import Foundation
@testable import ExpressionPadCore

struct NotesTests {
    @Test func midiToFreqConversion() {
        #expect(abs(midiToFreq(69) - 440) < 1e-9)
        #expect(abs(midiToFreq(81) - 880) < 1e-9)
        #expect(abs(midiToFreq(57) - 220) < 1e-9)
        #expect(abs(midiToFreq(60) - 261.625) < 0.01)
    }

    @Test func pitchClassAndOctave() {
        #expect(pitchClass(60) == 0)
        #expect(pitchClass(61) == 1)
        #expect(pitchClass(59) == 11)
        #expect(octaveOf(60) == 4)
        #expect(octaveOf(59) == 3)
    }

    @Test func noteNames() {
        #expect(noteName(60) == "C")
        #expect(noteName(60, withOctave: true) == "C4")
        #expect(noteName(61) == "C#")
        #expect(noteName(63) == "Eb")
    }

    @Test func noteFromNameParsing() {
        #expect(noteFromName("C4") == 60)
        #expect(noteFromName("A4") == 69)
        #expect(noteFromName("F#3") == 54)
        #expect(noteFromName("Eb2") == 39)
        #expect(noteFromName("H2") == nil)
        #expect(noteFromName("") == nil)
    }
}

struct ScalesTests {
    @Test func degreeToSemitonesMajor() {
        let major = SCALES["Major"]!
        #expect(degreeToSemitones(major, 0) == 0)
        #expect(degreeToSemitones(major, 1) == 2)
        #expect(degreeToSemitones(major, 7) == 12) // octave
        #expect(degreeToSemitones(major, -1) == -1) // leading tone below
        #expect(degreeToSemitones(major, -7) == -12)
    }

    @Test func chromaticIsSemitones() {
        let chrom = SCALES["Chromatic"]!
        for d in -12...12 {
            #expect(degreeToSemitones(chrom, d) == d)
        }
    }

    @Test func rowOffsetTunings() {
        #expect(rowOffsets("Fourths [+5]", 4) == [0, 5, 10, 15])
        #expect(rowOffsets("Octaves [+12]", 3) == [0, 12, 24])
        #expect(rowOffsets("Guitar EADGBE", 6) == [0, 5, 10, 15, 19, 24])
        // Rows beyond explicit offsets continue in fourths.
        #expect(rowOffsets("Guitar EADGBE", 7)[6] == 29)
        // Unknown tunings fall back to fourths.
        #expect(rowOffsets("Nope", 2) == [0, 5])
    }
}

struct MidiMathTests {
    private func value(_ b: (lsb: UInt8, msb: UInt8)) -> Int {
        Int(b.lsb) | (Int(b.msb) << 7)
    }

    @Test func bendBytesCenter() {
        #expect(value(bendBytes(0, 48)) == 8192)
    }

    @Test func bendBytesExtremes() {
        #expect(value(bendBytes(48, 48)) == 16383)
        #expect(value(bendBytes(-48, 48)) == 1)
        // Clamped beyond range.
        #expect(value(bendBytes(96, 48)) == 16383)
    }

    @Test func bendBytesScale() {
        let v = value(bendBytes(1, 2))
        #expect(abs(v - (8192 + 8191 / 2)) <= 1)
    }

    @Test func channelAllocatorRotates() {
        let alloc = ChannelAllocator()
        let c1 = alloc.acquire(100)
        let c2 = alloc.acquire(200)
        #expect(c1 != c2)
        #expect(alloc.channelOf(100) == c1)
        // Same id re-acquires the same channel.
        #expect(alloc.acquire(100) == c1)
        alloc.release(100)
        // Released channel goes to the back of the queue.
        var used: Set<Int> = [c2]
        for i in 0..<13 {
            used.insert(alloc.acquire(300 + i))
        }
        #expect(used.count == 14)
        // Next acquire wraps to the released channel.
        #expect(alloc.acquire(999) == c1)
    }

    @Test func channelAllocatorStealsOldest() {
        let alloc = ChannelAllocator()
        for i in 0..<15 { _ = alloc.acquire(i) }
        let oldest = alloc.channelOf(0)!
        #expect(alloc.acquire(99) == oldest)
        #expect(alloc.channelOf(0) == nil)
    }
}

struct StateTests {
    @Test func setEmitsWebPath() {
        let store = Store()
        var got: [String] = []
        store.subscribe { _, path in got.append(path) }
        store.set(\.synth.gen1.morph, 0.5)
        #expect(got == ["synth.gen1.morph"])
        #expect(store.state.synth.gen1.morph == 0.5)
    }

    @Test func setSameValueDoesNotEmit() {
        let store = Store()
        var count = 0
        store.subscribe { _, _ in count += 1 }
        store.set(\.pad.rows, store.state.pad.rows)
        #expect(count == 0)
    }

    @Test func pathMapEntriesUniqueAndComplete() {
        var seen = Set<String>()
        for (_, path) in PathMap.entries {
            #expect(!seen.contains(path), "duplicate: \(path)")
            seen.insert(path)
        }
        #expect(seen.count >= 60)
    }

    @Test func loadToleratesStaleShapes() {
        // Stale key, wrong-typed key, and one good override.
        let json = """
        {"pad": {"rows": 6, "cols": "nope", "junk": 1}, "gone": true}
        """.data(using: .utf8)!
        let store = Store.load(from: json)
        #expect(store.state.pad.rows == 6)
        #expect(store.state.pad.cols == defaultState().pad.cols)
    }

    @Test func loadRoundTrip() throws {
        let store = Store()
        store.set(\.appearance.scheme, "Rainbow")
        store.set(\.pad.layout, .hex)
        let data = try JSONEncoder().encode(store.state)
        let loaded = Store.load(from: data)
        #expect(loaded.state == store.state)
    }

    @Test func loadCorruptedFallsBack() {
        let store = Store.load(from: "not json".data(using: .utf8)!)
        #expect(store.state == defaultState())
    }

    @Test func applyPresetPatchesLeaves() {
        let store = Store()
        var paths: [String] = []
        store.subscribe { _, path in paths.append(path) }
        applyPreset("Growl Dark", to: store)
        #expect(store.state.synth.preset == "Growl Dark")
        #expect(store.state.synth.gen1.morph == 0.95)
        #expect(store.state.synth.lfo.target == .filter)
        #expect(paths.contains("synth.gen1.morph"))
        #expect(paths.contains("synth.filter.cutoff"))
    }

    @Test func allPresetNamesResolve() {
        for name in PRESET_NAMES {
            #expect(SYNTH_PRESETS[name] != nil, "\(name)")
        }
    }
}

struct ColorsTests {
    private func key(note: Int, kind: KeyKind = .rect) -> KeyShape {
        KeyShape(id: 0, note: note, row: 0, col: 0, kind: kind,
                 x: 0, y: 0, w: 50, h: 50, cx: 25, cy: 25)
    }

    @Test func accidentalGridKeysAreDarker() {
        let opts = ColorOpts(brightness: 0.65, contrast: 0.5, baseNote: 48)
        let natural = keyColors("Ocean", key(note: 48), opts) // C
        let accidental = keyColors("Ocean", key(note: 49), opts) // C#
        #expect(accidental.fill.l < natural.fill.l)
    }

    @Test func pianoWhitesBrighterThanBlacks() {
        let opts = ColorOpts(brightness: 0.65, contrast: 0.5, baseNote: 48)
        let white = keyColors("Magenta", key(note: 60, kind: .white), opts)
        let black = keyColors("Magenta", key(note: 61, kind: .black), opts)
        #expect(white.fill.l > black.fill.l + 10)
    }

    @Test func labelPicksReadableTone() {
        let opts = ColorOpts(brightness: 0.65, contrast: 0.5, baseNote: 48)
        for scheme in SCHEME_NAMES {
            for note in 48...59 {
                for kind in [KeyKind.rect, .white, .black] {
                    let c = keyColors(scheme, key(note: note, kind: kind), opts)
                    #expect(contrastRatio(c.label, c.fill) >= 2.0, "\(scheme) note \(note) \(kind)")
                }
            }
        }
    }

    @Test func brightnessLiftsLightness() {
        let dim = ColorOpts(brightness: 0.2, contrast: 0.5, baseNote: 48)
        let brightOpts = ColorOpts(brightness: 1.0, contrast: 0.5, baseNote: 48)
        #expect(
            keyColors("Ocean", key(note: 50), dim).fill.l
                < keyColors("Ocean", key(note: 50), brightOpts).fill.l
        )
    }
}
