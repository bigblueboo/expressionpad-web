/// VoiceSink: the contract between the touch surface and anything that makes
/// sound — the internal synth, MIDI out, or both via the Router.
public protocol VoiceSink: AnyObject {
    /// Start a voice. `pitch` is a (possibly fractional) MIDI note, vel 0..1.
    func noteOn(_ id: Int, _ pitch: Double, _ vel: Double)
    /// Continuous pitch update for an active voice.
    func glide(_ id: Int, _ pitch: Double)
    /// Pressure/timbre update 0..1 (aftertouch).
    func pressure(_ id: Int, _ value: Double)
    func noteOff(_ id: Int)
    func allOff()
}

/// Fans touch events out to whichever sinks are currently enabled.
public final class Router: VoiceSink {
    private var sinks: [(sink: VoiceSink, enabled: () -> Bool)] = []
    private var active: [Int: [VoiceSink]] = [:]

    public init() {}

    public func add(_ sink: VoiceSink, enabled: @escaping () -> Bool) {
        sinks.append((sink, enabled))
    }

    public func noteOn(_ id: Int, _ pitch: Double, _ vel: Double) {
        let targets = sinks.filter { $0.enabled() }.map { $0.sink }
        active[id] = targets
        for t in targets { t.noteOn(id, pitch, vel) }
    }

    public func glide(_ id: Int, _ pitch: Double) {
        for t in active[id] ?? [] { t.glide(id, pitch) }
    }

    public func pressure(_ id: Int, _ value: Double) {
        for t in active[id] ?? [] { t.pressure(id, value) }
    }

    public func noteOff(_ id: Int) {
        for t in active[id] ?? [] { t.noteOff(id) }
        active.removeValue(forKey: id)
    }

    public func allOff() {
        for (sink, _) in sinks { sink.allOff() }
        active.removeAll()
    }
}
