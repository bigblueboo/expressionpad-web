/// TouchTracker — translates pointer events on the pad surface into voice
/// events. Pure logic (no UIKit) so it is fully unit-testable.
///
/// Behavior, matching the original app:
/// - Each touch is an independent voice (continuous multi-touch).
/// - slide = 0: dragging across keys retriggers discrete notes.
/// - slide > 0: pitch follows the finger continuously across columns and rows;
///   FRETS snaps the slid pitch to semitones.
/// - TCH VEL: velocity from vertical position within the key at onset.
/// - AFTERTOUCH: vertical movement after onset becomes pressure 0..1.
/// - VIB: horizontal wiggle around a spring-loaded anchor bends the fretted
///   note by up to ±depth semitones; the anchor trails the finger so a held
///   offset re-centers (string-like vibrato with spring-back).
import Foundation

/// Time (ms) for a sustained vibrato offset to relax back to the fretted pitch.
private let VIB_RECENTER_MS: Double = 250

public struct ActiveTouch {
    public var id: Int
    public var key: KeyShape
    public var currentRow: Int
    public var startY: Double
    public var pitch: Double
    public var pressure: Double
    public var x: Double
    public var y: Double
    /// Spring anchor for in-key vibrato; trails x to re-center the bend.
    public var anchorX: Double
    /// Current vibrato bend in semitones.
    public var bend: Double
    /// Nearest semitone last heard — fret-crossing haptics fire on change.
    public var lastSemi: Int
    public var lastMs: Double
}

public final class TouchTracker {
    public private(set) var active: [Int: ActiveTouch] = [:]

    private let getLayout: () -> Layout
    private let getPad: () -> PadConfig
    private let sink: VoiceSink
    private let onChange: () -> Void
    /// Fires at event time for every note onset (down or drag retrigger).
    private let onTrigger: (KeyShape) -> Void
    /// Fires whenever a voice crosses onto a new semitone (fret haptics).
    private let onFret: () -> Void
    private let now: () -> Double

    public init(
        getLayout: @escaping () -> Layout,
        getPad: @escaping () -> PadConfig,
        sink: VoiceSink,
        onChange: @escaping () -> Void = {},
        onTrigger: @escaping (KeyShape) -> Void = { _ in },
        onFret: @escaping () -> Void = {},
        now: @escaping () -> Double = { ProcessInfo.processInfo.systemUptime * 1000 }
    ) {
        self.getLayout = getLayout
        self.getPad = getPad
        self.sink = sink
        self.onChange = onChange
        self.onTrigger = onTrigger
        self.onFret = onFret
        self.now = now
    }

    public func down(_ id: Int, _ x: Double, _ y: Double) {
        let layout = getLayout()
        let pad = getPad()
        guard let key = layout.hitTest(x, y) else { return }
        if active[id] != nil { up(id) }
        let vel = pad.touchVel ? velocityFromKey(key, y) : 0.8
        let touch = ActiveTouch(
            id: id, key: key, currentRow: key.row, startY: y,
            pitch: Double(key.note), pressure: 0, x: x, y: y,
            anchorX: x, bend: 0, lastSemi: key.note, lastMs: now()
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

        // Vibrato only makes sense when pitch is otherwise quantized — discrete
        // keys or fretted slides. A free slide already follows the finger.
        let vibrato = pad.vibrato > 0 && (pad.slide == 0 || pad.frets)
        if vibrato {
            let t = now()
            let dt = max(0, t - touch.lastMs)
            touch.lastMs = t
            touch.anchorX += (x - touch.anchorX) * (1 - exp(-dt / VIB_RECENTER_MS))
            let span = max(1, touch.key.w)
            touch.bend = max(-1, min(1, (x - touch.anchorX) / span)) * pad.vibrato
        }

        if pad.slide > 0 {
            // Adopt the row beneath the finger before calculating pitch. Keeping
            // the same touch id makes row changes glides rather than retriggers.
            if let over = layout.hitTest(x, y) {
                touch.currentRow = over.row
                touch.key = over
            }
            var pitch = layout.pitchAt(x, touch.currentRow)
            if pad.frets { pitch = pitch.rounded() + (vibrato ? touch.bend : 0) }
            pitch = clampMidi(pitch)
            if pitch != touch.pitch {
                touch.pitch = pitch
                sink.glide(id, pitch)
            }
        } else {
            if let over = layout.hitTest(x, y), over.id != touch.key.id {
                sink.noteOff(id)
                let vel = pad.touchVel ? velocityFromKey(over, y) : 0.8
                touch.key = over
                touch.currentRow = over.row
                touch.startY = y
                touch.pitch = Double(over.note)
                touch.pressure = 0
                touch.anchorX = x
                touch.bend = 0
                sink.noteOn(id, clampMidi(Double(over.note)), vel)
                onTrigger(over)
            } else if vibrato {
                let pitch = clampMidi(Double(touch.key.note) + touch.bend)
                if pitch != touch.pitch {
                    touch.pitch = pitch
                    sink.glide(id, pitch)
                }
            }
        }

        let semi = Int(touch.pitch.rounded())
        if semi != touch.lastSemi {
            touch.lastSemi = semi
            onFret()
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
