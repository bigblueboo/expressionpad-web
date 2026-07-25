import Testing
@testable import ExpressionPadCore

private let base = LayoutParams(
    kind: .square, rows: 4, cols: 12, width: 1200, height: 400,
    baseNote: 48, rowOffsets: [0, 5, 10, 15], scale: SCALES["Chromatic"]!
)

struct SquareLayoutTests {
    let layout = buildLayout(base)

    @Test func createsRowsTimesColsKeys() {
        #expect(layout.keys.count == 48)
    }

    @Test func baseNoteAtBottomLeft() {
        let k = layout.hitTest(10, 390)!
        #expect(k.note == 48)
        #expect(k.row == 0)
        #expect(k.col == 0)
    }

    @Test func advancesChromaticallyAndByFourths() {
        #expect(layout.hitTest(150, 390)!.note == 49) // col 1, bottom row
        #expect(layout.hitTest(10, 10)!.note == 48 + 15) // top row
    }

    @Test func keysTileSurfaceWithNoGaps() {
        var x = 5.0
        while x < 1200 {
            var y = 5.0
            while y < 400 {
                #expect(layout.hitTest(x, y) != nil)
                y += 37
            }
            x += 97
        }
    }

    @Test func missesOutsideSurface() {
        #expect(layout.hitTest(-5, 100) == nil)
        #expect(layout.hitTest(100, 500) == nil)
    }

    @Test func continuousPitchMonotonicAcrossRow() {
        var prev = -Double.infinity
        var x = 0.0
        while x <= 1200 {
            let p = layout.pitchAt(x, 0)
            #expect(p >= prev)
            prev = p
            x += 25
        }
    }

    @Test func continuousPitchMatchesKeyNoteAtCenter() {
        let k = layout.keys.first { $0.row == 1 && $0.col == 5 }!
        #expect(abs(layout.pitchAt(k.cx, 1) - Double(k.note)) < 1e-9)
    }

    @Test func respectsColumnScales() {
        var p = base
        p.scale = SCALES["Major Pentatonic"]!
        p.cols = 6
        let pent = buildLayout(p)
        let bottom = pent.keys.filter { $0.row == 0 }.map { $0.note }
        #expect(bottom == [48, 50, 52, 55, 57, 60])
    }
}

struct HexLayoutTests {
    var layout: Layout {
        var p = base
        p.kind = .hex
        p.rows = 5
        p.cols = 10
        p.rowOffsets = rowOffsets("Fourths [+5]", 5)
        return buildLayout(p)
    }

    @Test func createsHexesWithPolygons() {
        let l = layout
        #expect(l.keys.count == 50)
        for k in l.keys {
            #expect(k.poly?.count == 6)
        }
    }

    @Test func hitsHexAtOwnCenter() {
        let l = layout
        for k in l.keys {
            #expect(l.hitTest(k.cx, k.cy)?.id == k.id)
        }
    }

    @Test func oddRowsOffsetByHalfHex() {
        let l = layout
        let r0 = l.keys.first { $0.row == 0 && $0.col == 0 }!
        let r1 = l.keys.first { $0.row == 1 && $0.col == 0 }!
        #expect(abs((r1.cx - r0.cx) - r0.w / 2) < 0.001)
    }

    @Test func missesFarOutside() {
        #expect(layout.hitTest(-100, -100) == nil)
    }
}

struct PianoLayoutTests {
    var layout: Layout {
        var p = base
        p.kind = .piano
        p.rows = 2
        p.cols = 7
        p.baseNote = 60
        p.rowOffsets = [0, 12]
        return buildLayout(p)
    }

    @Test func whiteNoteRuns() {
        #expect(whiteNotesFrom(60, 8) == [60, 62, 64, 65, 67, 69, 71, 72])
        // Starting on an accidental advances to the next white.
        #expect(whiteNotesFrom(61, 3) == [62, 64, 65])
    }

    @Test func rowsHaveWhitesAndBlacks() {
        let l = layout
        let whites = l.keys.filter { $0.kind == .white }
        let blacks = l.keys.filter { $0.kind == .black }
        #expect(whites.count == 14)
        // C-major octave: 5 blacks per row.
        #expect(blacks.count == 10)
    }

    @Test func blackKeysHitBeforeWhites() {
        let l = layout
        let black = l.keys.first { $0.kind == .black }!
        #expect(l.hitTest(black.cx, black.cy)?.id == black.id)
    }

    @Test func whiteKeyHitBelowBlackBand() {
        let l = layout
        // Bottom row, first white key, at 90% depth — beneath any black.
        let white = l.keys.first { $0.kind == .white && $0.row == 0 && $0.col == 0 }!
        let hit = l.hitTest(white.cx, white.y + white.h * 0.9)
        #expect(hit?.id == white.id)
    }

    @Test func pitchAtUsesWhiteRow() {
        let l = layout
        let firstWhite = l.keys.first { $0.kind == .white && $0.row == 0 && $0.col == 0 }!
        #expect(abs(l.pitchAt(firstWhite.cx, 0) - Double(firstWhite.note)) < 1e-9)
    }
}

struct KbdLayoutTests {
    @Test func chromaticAssignsAllCodes() {
        var p = base
        p.kind = .kbdChromatic
        p.rows = 4
        let l = buildLayout(p)
        #expect(l.keys.count == KBD_ROWS.reduce(0) { $0 + $1.codes.count })
        #expect(l.keys.allSatisfy { $0.code != nil && $0.char != nil })
        // Bottom-left is KeyZ at the base note.
        let z = l.keys.first { $0.code == "KeyZ" }!
        #expect(z.note == 48)
        #expect(z.row == 0)
    }

    @Test func pianoVariantWhitesAndBlacks() {
        var p = base
        p.kind = .kbdPiano
        p.baseNote = 48
        p.rowOffsets = [0, 12]
        let l = buildLayout(p)
        let whites = l.keys.filter { $0.kind == .white }
        let blacks = l.keys.filter { $0.kind == .black }
        #expect(whites.count == 20) // 10 letters × 2 pairs
        #expect(!blacks.isEmpty)
        for b in blacks {
            #expect(b.code != nil)
        }
        // Hit test prefers blacks (later in scan order).
        let black = blacks[0]
        #expect(l.hitTest(black.cx, black.cy)?.id == black.id)
    }

    @Test func keyboardLayoutHasFourPhysicalRows() {
        var p = base
        p.kind = .kbdChromatic
        p.rows = 4 // pad view always passes 4 for kbd layouts
        let l = buildLayout(p)
        #expect(Set(l.keys.map { $0.row }).count == 4)
    }
}

struct MirrorLayoutTests {
    var layout: Layout {
        var p = base
        p.mirror = true
        p.mirrorOffset = 12
        return buildLayout(p)
    }

    @Test func doublesKeyCountAndFlagsTheLayout() {
        let l = layout
        #expect(l.keys.count == 96)
        #expect(l.mirrored)
    }

    @Test func leftHalfMatchesUnmirroredLayoutAtHalfWidth() {
        let k = layout.hitTest(10, 390)!
        #expect(k.note == 48)
        #expect(k.row == 0)
        #expect(k.col == 0)
    }

    @Test func reflectsGeometrySoBothThumbsSeeTheSameShape() {
        let l = layout
        for k in l.keys.prefix(48) {
            let twin = l.hitTest(1200 - k.cx, k.cy)!
            #expect(twin.note == k.note + 12)
            #expect(abs(twin.cx - (1200 - k.cx)) < 1e-6)
            #expect(abs(twin.cy - k.cy) < 1e-6)
        }
    }

    @Test func appliesTheSemitoneOffsetOnTheRightHalfOnly() {
        let l = layout
        #expect(l.hitTest(1190, 390)!.note == 60) // mirror of bottom-left C3
        #expect(l.hitTest(610, 390)!.note == 71) // innermost right key
        #expect(l.hitTest(590, 390)!.note == 59) // innermost left key
    }

    @Test func mirrorsContinuousPitchWithTheOffset() {
        let l = layout
        #expect(abs(l.pitchAt(25, 0) - 48) < 1e-9) // half-width keys: center at 25
        #expect(abs(l.pitchAt(1175, 0) - 60) < 1e-9)
        // Pitch rises toward the seam from both sides.
        #expect(l.pitchAt(590, 0) > l.pitchAt(500, 0))
        #expect(l.pitchAt(610, 0) >= l.pitchAt(700, 0))
    }

    @Test func resolvesTouchesExactlyOnTheSeam() {
        #expect(layout.hitTest(600, 390) != nil)
    }

    @Test func mirrorsHexesWithReflectedPolygonsInsideTheSurface() {
        var p = base
        p.kind = .hex
        p.mirror = true
        let hex = buildLayout(p)
        #expect(hex.keys.count == 96)
        for k in hex.keys {
            for pt in k.poly! {
                #expect(pt.x >= -1 && pt.x <= 1201)
            }
        }
    }

    @Test func mirrorsStackedPianos() {
        var p = base
        p.kind = .piano
        let solo = buildLayout(p)
        p.mirror = true
        let split = buildLayout(p)
        #expect(split.keys.count == 2 * solo.keys.count)
    }

    @Test func ignoredByTypingKeyboardLayouts() {
        var p = base
        p.kind = .kbdChromatic
        p.mirror = true
        let kbd = buildLayout(p)
        #expect(!kbd.mirrored)
        #expect(kbd.keys.count == 45) // 10 + 11 + 12 + 12 physical keys
    }
}
