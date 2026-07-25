import Testing
@testable import ExpressionPadCore

private func squareParams(rows: Int = 8, cols: Int = 8, size: Double = 800) -> LayoutParams {
    LayoutParams(
        kind: .square, rows: rows, cols: cols, width: size, height: size,
        baseNote: 48, rowOffsets: rowOffsets("Fourths [+5]", rows), scale: SCALES["Chromatic"]!
    )
}

private func keyAt(_ layout: Layout, _ row: Int, _ col: Int) -> KeyShape {
    layout.keys.first { $0.row == row && $0.col == col && $0.kind != .black }!
}

struct BrightnessFieldTests {
    func run(_ field: BrightnessField, _ seconds: Double) {
        let frames = Int((seconds * 60).rounded())
        for _ in 0..<frames { field.step(1.0 / 60) }
    }

    @Test func pokeBrightensTouchedKeyImmediately() {
        let layout = buildLayout(squareParams())
        let field = BrightnessField(layout.keys)
        let center = keyAt(layout, 4, 4)
        field.poke(center.id)
        #expect(abs(field.get(center.id) - 1) < 0.001)
        #expect(field.energy > 0)
    }

    @Test func propagatesToNeighborsNearBeforeFar() {
        let layout = buildLayout(squareParams())
        let field = BrightnessField(layout.keys)
        field.poke(keyAt(layout, 4, 4).id)
        run(field, 0.1)
        let near = field.get(keyAt(layout, 4, 5).id)
        let far = field.get(keyAt(layout, 4, 7).id)
        #expect(near > 0.02)
        #expect(near > far)
    }

    @Test func waveReachesWholeGrid() {
        let layout = buildLayout(squareParams())
        let field = BrightnessField(layout.keys)
        field.poke(keyAt(layout, 4, 4).id)
        var cornerPeak: Float = 0
        for _ in 0..<90 {
            field.step(1.0 / 60)
            cornerPeak = max(cornerPeak, abs(field.get(keyAt(layout, 0, 0).id)))
        }
        #expect(cornerPeak > 0.01)
    }

    @Test func fieldDecaysToRest() {
        let layout = buildLayout(squareParams())
        let field = BrightnessField(layout.keys)
        field.poke(keyAt(layout, 4, 4).id, 1.3)
        run(field, 6)
        #expect(field.energy < 0.01)
    }

    @Test func worksOnHexAndPianoLattices() {
        for kind in [LayoutKind.hex, .piano] {
            var p = squareParams(rows: 4, cols: 8)
            p.kind = kind
            let layout = buildLayout(p)
            let field = BrightnessField(layout.keys)
            field.poke(layout.keys[0].id)
            run(field, 0.2)
            #expect(field.energy.isFinite)
        }
    }
}

/// Records VoiceSink calls for assertions.
final class MockSink: VoiceSink {
    enum Call: Equatable {
        case on(Int, Double, Double)
        case glide(Int, Double)
        case pressure(Int, Double)
        case off(Int)
        case allOff
    }

    var calls: [Call] = []

    func noteOn(_ id: Int, _ pitch: Double, _ vel: Double) { calls.append(.on(id, pitch, vel)) }
    func glide(_ id: Int, _ pitch: Double) { calls.append(.glide(id, pitch)) }
    func pressure(_ id: Int, _ value: Double) { calls.append(.pressure(id, value)) }
    func noteOff(_ id: Int) { calls.append(.off(id)) }
    func allOff() { calls.append(.allOff) }

    func ons() -> [Call] {
        calls.filter { if case .on = $0 { return true } else { return false } }
    }
}

final class TouchTrackerTests {
    var pad: PadConfig
    var layout: Layout
    let sink = MockSink()
    var tracker: TouchTracker!

    init() {
        pad = defaultState().pad
        var p = squareParams(rows: 4, cols: 12)
        p.width = 1200
        p.height = 400
        p.rowOffsets = rowOffsets("Fourths [+5]", 4)
        layout = buildLayout(p)
        tracker = TouchTracker(
            getLayout: { [unowned self] in self.layout },
            getPad: { [unowned self] in self.pad },
            sink: sink
        )
    }

    @Test func downStartsVoiceAtKeyNote() {
        tracker.down(1, 50, 390) // bottom-left key, near bottom = loud
        guard case let .on(id, pitch, vel) = sink.calls.first else {
            Issue.record("no noteOn")
            return
        }
        #expect(id == 1)
        #expect(pitch == 48)
        #expect(vel > 0.8) // touchVel: bottom of key is loud
    }

    @Test func touchVelOffUsesFixedVelocity() {
        pad.touchVel = false
        tracker.down(1, 50, 390)
        guard case let .on(_, _, vel) = sink.calls.first else {
            Issue.record("no noteOn")
            return
        }
        #expect(vel == 0.8)
    }

    @Test func slideGlidesWithinOriginRow() {
        pad.slide = 0.5
        pad.frets = false
        tracker.down(1, 50, 390)
        tracker.move(1, 500, 390)
        let glides = sink.calls.compactMap { call -> Double? in
            if case let .glide(_, p) = call { return p } else { return nil }
        }
        #expect(!glides.isEmpty)
        // Continuous — includes fractional pitch.
        #expect(glides.contains { $0 != $0.rounded() })
        // No retrigger while sliding.
        #expect(sink.ons().count == 1)
    }

    @Test func slideGlidesAcrossRowsWithoutRetriggeringVoice() {
        pad.slide = 0.5
        pad.frets = false
        tracker.down(1, 50, 390) // bottom row: C3
        tracker.move(1, 50, 10) // top row: D#4 with fourths tuning

        let glides = sink.calls.compactMap { call -> (Int, Double)? in
            if case let .glide(id, pitch) = call { return (id, pitch) }
            return nil
        }
        #expect(glides.last?.0 == 1)
        #expect(glides.last?.1 == 63)
        #expect(sink.ons().count == 1)
        #expect(!sink.calls.contains(.off(1)))
        #expect(tracker.active[1]?.key.row == 3)

        tracker.move(1, 50, 390)
        let returnGlides = sink.calls.compactMap { call -> Double? in
            if case let .glide(_, pitch) = call { return pitch }
            return nil
        }
        #expect(returnGlides.last == 48)
        #expect(sink.ons().count == 1)
    }

    @Test func continuousSlideDoesNotInjectNewRippleEnergyAcrossKeys() {
        pad.slide = 0.5
        var triggered: [Int] = []
        let localTracker = TouchTracker(
            getLayout: { [unowned self] in self.layout },
            getPad: { [unowned self] in self.pad },
            sink: sink,
            onTrigger: { triggered.append($0.id) }
        )
        localTracker.down(1, 50, 390)
        localTracker.move(1, 150, 390)
        localTracker.move(1, 250, 390)
        localTracker.move(1, 350, 390)
        #expect(triggered.count == 1)
        #expect(sink.calls.contains {
            if case .glide = $0 { return true }
            return false
        })
    }

    @Test func fretsSnapsSlidPitch() {
        pad.slide = 0.5
        pad.frets = true
        tracker.down(1, 50, 390)
        tracker.move(1, 500, 390)
        for call in sink.calls {
            if case let .glide(_, p) = call {
                #expect(p == p.rounded())
            }
        }
    }

    @Test func slideZeroRetriggersAcrossKeys() {
        pad.slide = 0
        tracker.down(1, 50, 390)
        tracker.move(1, 150, 390) // next column
        #expect(sink.ons().count == 2)
        #expect(sink.calls.contains(.off(1)))
    }

    @Test func aftertouchPressureFromUpwardDrag() {
        tracker.down(1, 50, 390)
        tracker.move(1, 50, 300) // drag up
        let pressures = sink.calls.compactMap { call -> Double? in
            if case let .pressure(_, v) = call { return v } else { return nil }
        }
        #expect(!pressures.isEmpty)
        #expect(pressures.last! > 0.5)
    }

    @Test func aftertouchOffSendsNoPressure() {
        pad.aftertouch = false
        tracker.down(1, 50, 390)
        tracker.move(1, 50, 200)
        for call in sink.calls {
            if case .pressure = call { Issue.record("pressure sent with aftertouch off") }
        }
    }

    @Test func upEndsVoice() {
        tracker.down(1, 50, 390)
        tracker.up(1)
        #expect(sink.calls.last == .off(1))
        #expect(tracker.active.isEmpty)
    }

    @Test func multiTouchIndependentVoices() {
        tracker.down(1, 50, 390)
        tracker.down(2, 500, 390)
        #expect(tracker.active.count == 2)
        tracker.up(1)
        #expect(tracker.active.count == 1)
        #expect(tracker.active[2] != nil)
    }

    @Test func downOutsideSurfaceIgnored() {
        tracker.down(1, -10, -10)
        #expect(sink.calls.isEmpty)
    }

    @Test func cancelAllSilencesEverything() {
        tracker.down(1, 50, 390)
        tracker.down(2, 500, 390)
        tracker.cancelAll()
        #expect(sink.calls.last == .allOff)
        #expect(tracker.active.isEmpty)
    }
}

struct RouterTests {
    @Test func routesToEnabledSinksAndRemembersTargets() {
        let a = MockSink()
        let b = MockSink()
        var aEnabled = true
        let router = Router()
        router.add(a, enabled: { aEnabled })
        router.add(b, enabled: { false })

        router.noteOn(1, 60, 0.8)
        #expect(a.ons().count == 1)
        #expect(b.ons().isEmpty)

        // Targets captured at noteOn survive an enabled() flip mid-note.
        aEnabled = false
        router.glide(1, 61)
        router.noteOff(1)
        #expect(a.calls.contains(.glide(1, 61)))
        #expect(a.calls.contains(.off(1)))

        router.allOff()
        #expect(a.calls.last == .allOff)
        #expect(b.calls.last == .allOff)
    }
}

struct KeyboardInputTests {
    @Test func keyDownUpDrivesTracker() {
        var p = squareParams(rows: 4, cols: 12, size: 1200)
        p.kind = .kbdChromatic
        let layout = buildLayout(p)
        let sink = MockSink()
        let pad = defaultState().pad
        let tracker = TouchTracker(getLayout: { layout }, getPad: { pad }, sink: sink)
        let kbd = KeyboardInput(getLayout: { layout }, tracker: tracker)

        kbd.keyDown("KeyZ")
        #expect(sink.ons().count == 1)
        kbd.keyUp("KeyZ")
        if case .off = sink.calls.last! {} else { Issue.record("expected off") }

        // Unmapped code is inert.
        kbd.keyDown("Escape")
        #expect(sink.ons().count == 1)

        // releaseAll ends everything.
        kbd.keyDown("KeyA")
        kbd.keyDown("KeyS")
        kbd.releaseAll()
        #expect(kbd.active.isEmpty)
    }
}
