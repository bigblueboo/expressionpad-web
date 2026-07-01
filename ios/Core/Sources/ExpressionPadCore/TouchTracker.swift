/// TouchTracker — translates pointer events on the pad surface into voice
/// events. Pure logic (no UIKit) so it is fully unit-testable.
///
/// Behavior, matching the original app:
/// - Each touch is an independent voice (continuous multi-touch).
/// - slide = 0: dragging across keys retriggers discrete notes.
/// - slide > 0: pitch follows the finger continuously within the origin row;
///   FRETS snaps the slid pitch to semitones.
/// - TCH VEL: velocity from vertical position within the key at onset.
/// - AFTERTOUCH: vertical movement after onset becomes pressure 0..1.
import Foundation

public struct ActiveTouch {
    public var id: Int
    public var key: KeyShape
    public var originRow: Int
    public var startY: Double
    public var pitch: Double
    public var pressure: Double
    public var x: Double
    public var y: Double
}

public final class TouchTracker {
    public private(set) var active: [Int: ActiveTouch] = [:]

    private let getLayout: () -> Layout
    private let getPad: () -> PadConfig
    private let sink: VoiceSink
    private let onChange: () -> Void
    /// Fires at event time for every note onset (down or drag retrigger).
    private let onTrigger: (KeyShape) -> Void

    public init(
        getLayout: @escaping () -> Layout,
        getPad: @escaping () -> PadConfig,
        sink: VoiceSink,
        onChange: @escaping () -> Void = {},
        onTrigger: @escaping (KeyShape) -> Void = { _ in }
    ) {
        self.getLayout = getLayout
        self.getPad = getPad
        self.sink = sink
        self.onChange = onChange
        self.onTrigger = onTrigger
    }

    public func down(_ id: Int, _ x: Double, _ y: Double) {
        let layout = getLayout()
        let pad = getPad()
        guard let key = layout.hitTest(x, y) else { return }
        if active[id] != nil { up(id) }
        let vel = pad.touchVel ? velocityFromKey(key, y) : 0.8
        let touch = ActiveTouch(
            id: id, key: key, originRow: key.row, startY: y,
            pitch: Double(key.note), pressure: 0, x: x, y: y
        )
        active[id] = touch
        sink.noteOn(id, clampMidi(Double(key.note)), vel)
        onTrigger(key)
        onChange()
    }

    public func move(_ id: Int, _ x: Double, _ y: Double) {
        guard var touch = active[id] else { return }
        let layout = getLayout()
        let pad = getPad()
        touch.x = x
        touch.y = y

        if pad.slide > 0 {
            var pitch = layout.pitchAt(x, touch.originRow)
            if pad.frets { pitch = pitch.rounded() }
            pitch = clampMidi(pitch)
            if pitch != touch.pitch {
                touch.pitch = pitch
                sink.glide(id, pitch)
            }
            // Highlight follows the nearest key in the origin row.
            if let over = layout.hitTest(x, y), over.row == touch.originRow, over.id != touch.key.id {
                touch.key = over
                onTrigger(over)
            }
        } else {
            if let over = layout.hitTest(x, y), over.id != touch.key.id {
                sink.noteOff(id)
                let vel = pad.touchVel ? velocityFromKey(over, y) : 0.8
                touch.key = over
                touch.originRow = over.row
                touch.startY = y
                touch.pitch = Double(over.note)
                touch.pressure = 0
                sink.noteOn(id, clampMidi(Double(over.note)), vel)
                onTrigger(over)
            }
        }

        if pad.aftertouch {
            // Moving up from the onset point increases pressure.
            let range = layout.rowHeight * 1.2
            let pressure = min(1, max(0, (touch.startY - y) / range))
            if abs(pressure - touch.pressure) > 0.01 {
                touch.pressure = pressure
                sink.pressure(id, pressure)
            }
        }
        active[id] = touch
        onChange()
    }

    public func up(_ id: Int) {
        guard active[id] != nil else { return }
        active.removeValue(forKey: id)
        sink.noteOff(id)
        onChange()
    }

    public func cancelAll() {
        active.removeAll()
        sink.allOff()
        onChange()
    }
}

/// Velocity from vertical position within the key: bottom = loud, top = soft.
public func velocityFromKey(_ key: KeyShape, _ y: Double) -> Double {
    let local = (y - key.y) / key.h
    return min(1, max(0.05, 0.25 + 0.75 * local))
}
