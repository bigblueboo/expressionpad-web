import Testing
import Foundation
@testable import ExpressionPadCore

struct StudioDesignTests {
    private func params(_ kind: LayoutKind, width: Double = 800, height: Double = 400) -> LayoutParams {
        LayoutParams(kind: kind, rows: 4, cols: 12, width: width, height: height,
                     baseNote: 48, rowOffsets: rowOffsets("Fourths [+5]", 4), scale: SCALES["Chromatic"]!)
    }

    @Test func themeMigrationPreservesMusicalState() throws {
        let old = Data(#"{"pad":{"rows":6},"appearance":{"scheme":"Rainbow"}}"#.utf8)
        let migrated = Store.load(from: old)
        #expect(migrated.state.appearance.theme == "system")
        #expect(migrated.state.appearance.scheme == "Rainbow")
        #expect(migrated.state.pad.rows == 6)
        #expect(defaultState().appearance.scheme == "Studio")
        migrated.set(\.appearance.theme, "dark")
        let saved = try JSONEncoder().encode(migrated.state)
        #expect(Store.load(from: saved).state.appearance.theme == "dark")
        migrated.set(\.appearance.theme, "invalid")
        #expect(migrated.state.appearance.theme == "system")
        #expect(migrated.state.pad.rows == 6)
    }

    @Test func studioLabelsRemainReadableInBothThemesAndRipples() {
        let layout = buildLayout(params(.square))
        for dark in [false, true] {
            for brightness in [0.0, 0.65, 1.0] {
                for key in layout.keys {
                    let color = keyColors("Studio", key, ColorOpts(brightness: brightness, contrast: 0.5, baseNote: 48, dark: dark))
                    #expect(contrastRatio(color.fill, color.label) >= 4.5)
                    for lightness in stride(from: 3.0, through: 94.0, by: 3) {
                        let fill = HSL(h: color.fill.h, s: color.fill.s, l: lightness)
                        #expect(contrastRatio(fill, labelColor(fill)) >= 4.5)
                    }
                }
            }
        }
    }

    @Test func resizePreservesNotesAndExpressionAcrossEveryLayout() {
        for kind in [LayoutKind.square, .hex, .piano, .kbdChromatic, .kbdPiano] {
            var layout = buildLayout(params(kind))
            let pad = defaultState().pad
            let sink = MockSink()
            let tracker = TouchTracker(getLayout: { layout }, getPad: { pad }, sink: sink)
            let key = layout.keys[layout.keys.count / 2]
            tracker.down(1, key.cx, key.cy)
            tracker.move(1, key.cx, key.cy - key.h * 0.1)
            let before = tracker.active[1]!
            let count = sink.calls.count
            let previous = layout
            layout = buildLayout(params(kind, width: 350, height: 600))
            tracker.reflow(from: previous)
            let after = tracker.active[1]!
            #expect(after.pitch == before.pitch)
            #expect(after.pressure == before.pressure)
            #expect(after.key.id == before.key.id)
            #expect(sink.calls.count == count)
            tracker.move(1, after.x, after.y)
            #expect(abs(tracker.active[1]!.pitch - before.pitch) < 0.00001)
            #expect(tracker.active[1]!.pressure == before.pressure)
            tracker.up(1)
            #expect(sink.calls.last == .off(1))
        }
    }

    @Test func hexagonsStayRegularAndBlankGlassDoesNotPlay() {
        let layout = buildLayout(params(.hex, width: 350, height: 700))
        for key in layout.keys {
            let poly = key.poly!
            let edges = poly.indices.map { i in
                let d = poly[i] - poly[(i + 1) % poly.count]
                return (d.x * d.x + d.y * d.y).squareRoot()
            }
            #expect(edges.max()! - edges.min()! < 0.00001)
            #expect(layout.hitTest(key.cx, key.cy)?.id == key.id)
        }
        #expect(layout.hitTest(1, 1) == nil)
    }
    @Test func stationaryVibratoSettlesWithoutRetriggering() {
        let layout = buildLayout(params(.square))
        var pad = defaultState().pad
        pad.slide = 0; pad.vibrato = 1
        var clock = 0.0
        let sink = MockSink()
        let tracker = TouchTracker(getLayout: { layout }, getPad: { pad }, sink: sink, now: { clock })
        let key = layout.keys[12]
        tracker.down(1, key.cx, key.cy)
        tracker.move(1, key.cx + key.w * 0.3, key.cy)
        #expect(tracker.active[1]!.bend > 0.2)
        clock = 3000
        tracker.advance()
        #expect(tracker.active[1]!.pitch == Double(key.note))
        #expect(!tracker.needsAdvance)
        #expect(sink.ons().count == 1)
    }

    @Test func disablingExpressionNeutralizesHeldVoices() {
        for slide in [0.0, 0.5] {
            let layout = buildLayout(params(.square))
            var pad = defaultState().pad
            pad.slide = slide; pad.frets = true; pad.vibrato = 1; pad.aftertouch = true
            let sink = MockSink()
            let tracker = TouchTracker(getLayout: { layout }, getPad: { pad }, sink: sink, now: { 0 })
            let key = layout.keys[12]
            tracker.down(1, key.cx, key.cy)
            tracker.move(1, key.cx + key.w * 0.3, key.cy - key.h * 0.2)
            #expect(tracker.active[1]!.pressure > 0)
            #expect(tracker.active[1]!.bend > 0)
            pad.aftertouch = false; pad.vibrato = 0
            tracker.reconcileExpression()
            #expect(tracker.active[1]!.pressure == 0)
            #expect(tracker.active[1]!.bend == 0)
            #expect(tracker.active[1]!.pitch == tracker.active[1]!.pitch.rounded())
            #expect(sink.calls.contains(.pressure(1, 0)))
            #expect(sink.ons().count == 1)
        }
    }

    @Test func panicRequiresAFreshTouchBeforePlayingAgain() {
        let layout = buildLayout(params(.square))
        var pad = defaultState().pad
        pad.slide = 0
        let sink = MockSink()
        let tracker = TouchTracker(getLayout: { layout }, getPad: { pad }, sink: sink)
        tracker.down(1, layout.keys[0].cx, layout.keys[0].cy)
        tracker.cancelAll()
        tracker.move(1, layout.keys[1].cx, layout.keys[1].cy)
        #expect(tracker.active.isEmpty)
        #expect(sink.ons().count == 1)
        tracker.down(2, layout.keys[1].cx, layout.keys[1].cy)
        #expect(sink.ons().count == 2)
    }

}
