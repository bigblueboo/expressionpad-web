/// App state: a typed store with path-string subscriptions + debounced persistence.
///
/// The web build addresses state by dot-paths ("synth.gen1.morph"); engine and
/// UI logic key off those strings. Here mutation goes through WritableKeyPaths
/// (compiler-checked) and PathMap translates each leaf back to the same dot-path
/// so all subscription logic ports verbatim.
import Foundation
import Combine

public enum VoiceSource: String, Codable, Sendable { case synth, sampler }
public enum LfoTarget: String, Codable, Sendable { case pitch, filter }
public enum UiTab: String, Codable, CaseIterable, Sendable { case synth, smplr, fx, pad, midi }

public struct PadConfig: Codable, Equatable, Sendable {
    public var layout: LayoutKind
    public var rows: Int
    public var cols: Int
    public var rowTuning: String
    public var colScale: String
    public var baseNote: Int
    /// 0 = retrigger per key; >0 = continuous pitch slide (value = glide amount).
    public var slide: Double
    /// Snap slid pitch to semitones.
    public var frets: Bool
    /// Derive velocity from vertical touch position within the key.
    public var touchVel: Bool
    /// Vertical drag after onset modulates pressure/timbre.
    public var aftertouch: Bool
}

public struct GenConfig: Codable, Equatable, Sendable {
    /// Waveform morph 0..1: sine → triangle → saw → square.
    public var morph: Double
    /// Semitone offset.
    public var semi: Int
    /// Fine tune in cents.
    public var tune: Double
    /// Mix level 0..1.
    public var level: Double
}

public struct EnvConfig: Codable, Equatable, Sendable {
    public var a: Double
    public var d: Double
    public var s: Double
    public var r: Double
}

public struct FilterConfig: Codable, Equatable, Sendable {
    public var cutoff: Double
    public var res: Double
    public var env: Double
}

public struct LfoConfig: Codable, Equatable, Sendable {
    public var rate: Double
    public var depth: Double
    public var target: LfoTarget
}

public struct SynthConfig: Codable, Equatable, Sendable {
    public var preset: String
    public var gen1: GenConfig
    public var gen2: GenConfig
    /// Additive brightness tilt 0..1.
    public var bright: Double
    public var env: EnvConfig
    public var filter: FilterConfig
    public var lfo: LfoConfig
    public var level: Double
}

public struct ReverbConfig: Codable, Equatable, Sendable {
    public var fdbk: Double
    public var mix: Double
    public var on: Bool
}

public struct DelayConfig: Codable, Equatable, Sendable {
    public var time: Double
    public var fdbk: Double
    public var mix: Double
    public var on: Bool
}

public struct DistortConfig: Codable, Equatable, Sendable {
    public var amt: Double
    public var on: Bool
}

public struct FattenConfig: Codable, Equatable, Sendable {
    public var amt: Double
    public var on: Bool
}

public struct FxConfig: Codable, Equatable, Sendable {
    public var reverb: ReverbConfig
    public var delay: DelayConfig
    public var distort: DistortConfig
    public var fatten: FattenConfig
}

public struct MidiConfig: Codable, Equatable, Sendable {
    public var outEnabled: Bool
    public var outputId: String
    public var bendRange: Int
    /// Send Y-axis as CC74 (MPE timbre).
    public var sendY: Bool
    public var inEnabled: Bool
    public var inputId: String
    /// Play the internal synth (off = pure MIDI controller).
    public var localSound: Bool
}

public struct AppearanceConfig: Codable, Equatable, Sendable {
    public var scheme: String
    public var labels: Bool
    public var brightness: Double
    public var ripples: Bool
    /// Strength of the ripple wave's visual effect, 0..1.
    public var rippleAmount: Double
    /// Light/dark spread between piano whites and blacks, 0..1.
    public var contrast: Double
}

public struct SamplerConfig: Codable, Equatable, Sendable {
    public var preset: String
    public var level: Double
    public var attack: Double
    public var release: Double
    /// Restart the sample when a slide crosses into a new semitone.
    public var retrig: Bool
    /// Root note assumed for a user-loaded sample.
    public var userRoot: Int
}

public struct UiConfig: Codable, Equatable, Sendable {
    public var panelOpen: Bool
    public var tab: UiTab
}

public struct AppState: Codable, Equatable, Sendable {
    /// Which local sound source touches play — synth or sampler.
    public var voice: VoiceSource
    public var pad: PadConfig
    public var synth: SynthConfig
    public var sampler: SamplerConfig
    public var fx: FxConfig
    public var midi: MidiConfig
    public var appearance: AppearanceConfig
    public var ui: UiConfig
}

public func defaultState() -> AppState {
    AppState(
        voice: .synth,
        pad: PadConfig(
            layout: .square, rows: 4, cols: 12,
            rowTuning: "Fourths [+5]", colScale: "Chromatic", baseNote: 48,
            slide: 0.35, frets: false, touchVel: true, aftertouch: true
        ),
        synth: SynthConfig(
            preset: "Super Sine",
            gen1: GenConfig(morph: 0.08, semi: 0, tune: 0, level: 0.85),
            gen2: GenConfig(morph: 0, semi: 12, tune: 3, level: 0.22),
            bright: 0.4,
            env: EnvConfig(a: 0.01, d: 0.3, s: 0.75, r: 0.35),
            filter: FilterConfig(cutoff: 0.8, res: 0.1, env: 0.2),
            lfo: LfoConfig(rate: 5, depth: 0.08, target: .pitch),
            level: 0.78
        ),
        sampler: SamplerConfig(
            preset: "E-Piano", level: 0.8, attack: 0.005, release: 0.35,
            retrig: false, userRoot: 60
        ),
        fx: FxConfig(
            reverb: ReverbConfig(fdbk: 0.5, mix: 0.3, on: true),
            delay: DelayConfig(time: 0.34, fdbk: 0.35, mix: 0.2, on: false),
            distort: DistortConfig(amt: 0.3, on: false),
            fatten: FattenConfig(amt: 0.4, on: true)
        ),
        midi: MidiConfig(
            outEnabled: false, outputId: "", bendRange: 48, sendY: true,
            inEnabled: false, inputId: "", localSound: true
        ),
        appearance: AppearanceConfig(
            scheme: "Ocean", labels: true, brightness: 0.65,
            ripples: true, rippleAmount: 0.5, contrast: 0.5
        ),
        ui: UiConfig(panelOpen: true, tab: .pad)
    )
}

// -------------------------------------------------------------- path map ---

/// Leaf keypath → the web build's dot-path, so subscription logic matches.
public enum PathMap {
    public static let entries: [(PartialKeyPath<AppState>, String)] = [
        (\AppState.voice, "voice"),
        (\AppState.pad.layout, "pad.layout"),
        (\AppState.pad.rows, "pad.rows"),
        (\AppState.pad.cols, "pad.cols"),
        (\AppState.pad.rowTuning, "pad.rowTuning"),
        (\AppState.pad.colScale, "pad.colScale"),
        (\AppState.pad.baseNote, "pad.baseNote"),
        (\AppState.pad.slide, "pad.slide"),
        (\AppState.pad.frets, "pad.frets"),
        (\AppState.pad.touchVel, "pad.touchVel"),
        (\AppState.pad.aftertouch, "pad.aftertouch"),
        (\AppState.synth.preset, "synth.preset"),
        (\AppState.synth.gen1.morph, "synth.gen1.morph"),
        (\AppState.synth.gen1.semi, "synth.gen1.semi"),
        (\AppState.synth.gen1.tune, "synth.gen1.tune"),
        (\AppState.synth.gen1.level, "synth.gen1.level"),
        (\AppState.synth.gen2.morph, "synth.gen2.morph"),
        (\AppState.synth.gen2.semi, "synth.gen2.semi"),
        (\AppState.synth.gen2.tune, "synth.gen2.tune"),
        (\AppState.synth.gen2.level, "synth.gen2.level"),
        (\AppState.synth.bright, "synth.bright"),
        (\AppState.synth.env.a, "synth.env.a"),
        (\AppState.synth.env.d, "synth.env.d"),
        (\AppState.synth.env.s, "synth.env.s"),
        (\AppState.synth.env.r, "synth.env.r"),
        (\AppState.synth.filter.cutoff, "synth.filter.cutoff"),
        (\AppState.synth.filter.res, "synth.filter.res"),
        (\AppState.synth.filter.env, "synth.filter.env"),
        (\AppState.synth.lfo.rate, "synth.lfo.rate"),
        (\AppState.synth.lfo.depth, "synth.lfo.depth"),
        (\AppState.synth.lfo.target, "synth.lfo.target"),
        (\AppState.synth.level, "synth.level"),
        (\AppState.sampler.preset, "sampler.preset"),
        (\AppState.sampler.level, "sampler.level"),
        (\AppState.sampler.attack, "sampler.attack"),
        (\AppState.sampler.release, "sampler.release"),
        (\AppState.sampler.retrig, "sampler.retrig"),
        (\AppState.sampler.userRoot, "sampler.userRoot"),
        (\AppState.fx.reverb.fdbk, "fx.reverb.fdbk"),
        (\AppState.fx.reverb.mix, "fx.reverb.mix"),
        (\AppState.fx.reverb.on, "fx.reverb.on"),
        (\AppState.fx.delay.time, "fx.delay.time"),
        (\AppState.fx.delay.fdbk, "fx.delay.fdbk"),
        (\AppState.fx.delay.mix, "fx.delay.mix"),
        (\AppState.fx.delay.on, "fx.delay.on"),
        (\AppState.fx.distort.amt, "fx.distort.amt"),
        (\AppState.fx.distort.on, "fx.distort.on"),
        (\AppState.fx.fatten.amt, "fx.fatten.amt"),
        (\AppState.fx.fatten.on, "fx.fatten.on"),
        (\AppState.midi.outEnabled, "midi.outEnabled"),
        (\AppState.midi.outputId, "midi.outputId"),
        (\AppState.midi.bendRange, "midi.bendRange"),
        (\AppState.midi.sendY, "midi.sendY"),
        (\AppState.midi.inEnabled, "midi.inEnabled"),
        (\AppState.midi.inputId, "midi.inputId"),
        (\AppState.midi.localSound, "midi.localSound"),
        (\AppState.appearance.scheme, "appearance.scheme"),
        (\AppState.appearance.labels, "appearance.labels"),
        (\AppState.appearance.brightness, "appearance.brightness"),
        (\AppState.appearance.ripples, "appearance.ripples"),
        (\AppState.appearance.rippleAmount, "appearance.rippleAmount"),
        (\AppState.appearance.contrast, "appearance.contrast"),
        (\AppState.ui.panelOpen, "ui.panelOpen"),
        (\AppState.ui.tab, "ui.tab"),
    ]

    static let byKeyPath: [PartialKeyPath<AppState>: String] = {
        var map: [PartialKeyPath<AppState>: String] = [:]
        for (kp, path) in entries { map[kp] = path }
        return map
    }()

    public static func path(for keyPath: PartialKeyPath<AppState>) -> String {
        byKeyPath[keyPath] ?? "?"
    }
}

// ----------------------------------------------------------------- store ---

public final class Store: ObservableObject {
    public typealias Listener = (AppState, String) -> Void

    @Published public private(set) var state: AppState
    private var listeners: [UUID: Listener] = [:]
    /// Debounced persistence hook; receives the encoded state.
    public var saver: ((Data) -> Void)?
    private var saveTimer: Timer?

    public init(initial: AppState? = nil) {
        self.state = sanitizeState(initial ?? defaultState())
    }

    /// Load persisted JSON merged over defaults (tolerates stale shapes).
    public static func load(from data: Data?) -> Store {
        guard let data else { return Store() }
        let base = defaultState()
        do {
            let defaults = try JSONSerialization.jsonObject(with: JSONEncoder().encode(base))
            let stored = try JSONSerialization.jsonObject(with: data)
            guard var target = defaults as? [String: Any] else { return Store() }
            deepMerge(&target, stored)
            let merged = try JSONSerialization.data(withJSONObject: target)
            let state = sanitizeState(try JSONDecoder().decode(AppState.self, from: merged))
            return Store(initial: state)
        } catch {
            // corrupted state — start fresh
            return Store()
        }
    }

    public func get<T>(_ keyPath: KeyPath<AppState, T>) -> T {
        state[keyPath: keyPath]
    }

    public func set<T: Equatable>(_ keyPath: WritableKeyPath<AppState, T>, _ value: T) {
        if state[keyPath: keyPath] == value { return }
        state[keyPath: keyPath] = value
        state = sanitizeState(state)
        emit(PathMap.path(for: keyPath))
        scheduleSave()
    }

    @discardableResult
    public func subscribe(_ fn: @escaping Listener) -> () -> Void {
        let id = UUID()
        listeners[id] = fn
        return { [weak self] in self?.listeners.removeValue(forKey: id) }
    }

    public func flushSave() {
        saveTimer?.invalidate()
        saveTimer = nil
        persist()
    }

    private func emit(_ path: String) {
        for fn in listeners.values { fn(state, path) }
    }

    private func scheduleSave() {
        guard saver != nil else { return }
        saveTimer?.invalidate()
        saveTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: false) { [weak self] _ in
            self?.saveTimer = nil
            self?.persist()
        }
    }

    private func persist() {
        guard let saver, let data = try? JSONEncoder().encode(state) else { return }
        saver(data)
    }
}

private func finite(_ value: Double, _ fallback: Double, _ lo: Double, _ hi: Double) -> Double {
    value.isFinite ? clamp(value, lo, hi) : fallback
}

/// Clamp numeric leaves and reject unknown named values after decoding and
/// after every typed mutation. This keeps stale defaults and future versions
/// from creating invalid layout/audio parameters.
public func sanitizeState(_ input: AppState) -> AppState {
    var state = input
    let d = defaultState()

    state.pad.rows = clamp(state.pad.rows, 1, 8)
    state.pad.cols = clamp(state.pad.cols, 4, 24)
    if ROW_TUNINGS[state.pad.rowTuning] == nil { state.pad.rowTuning = d.pad.rowTuning }
    if SCALES[state.pad.colScale] == nil { state.pad.colScale = d.pad.colScale }
    state.pad.baseNote = clamp(state.pad.baseNote, 12, 96)
    state.pad.slide = finite(state.pad.slide, d.pad.slide, 0, 1)

    state.synth.gen1.morph = finite(state.synth.gen1.morph, d.synth.gen1.morph, 0, 1)
    state.synth.gen1.semi = clamp(state.synth.gen1.semi, -24, 24)
    state.synth.gen1.tune = finite(state.synth.gen1.tune, d.synth.gen1.tune, -50, 50)
    state.synth.gen1.level = finite(state.synth.gen1.level, d.synth.gen1.level, 0, 1)
    state.synth.gen2.morph = finite(state.synth.gen2.morph, d.synth.gen2.morph, 0, 1)
    state.synth.gen2.semi = clamp(state.synth.gen2.semi, -24, 24)
    state.synth.gen2.tune = finite(state.synth.gen2.tune, d.synth.gen2.tune, -50, 50)
    state.synth.gen2.level = finite(state.synth.gen2.level, d.synth.gen2.level, 0, 1)
    if !PRESET_NAMES.contains(state.synth.preset) { state.synth.preset = d.synth.preset }
    state.synth.bright = finite(state.synth.bright, d.synth.bright, 0, 1)
    state.synth.env.a = finite(state.synth.env.a, d.synth.env.a, 0.001, 2)
    state.synth.env.d = finite(state.synth.env.d, d.synth.env.d, 0.01, 3)
    state.synth.env.s = finite(state.synth.env.s, d.synth.env.s, 0, 1)
    state.synth.env.r = finite(state.synth.env.r, d.synth.env.r, 0.02, 5)
    state.synth.filter.cutoff = finite(state.synth.filter.cutoff, d.synth.filter.cutoff, 0, 1)
    state.synth.filter.res = finite(state.synth.filter.res, d.synth.filter.res, 0, 1)
    state.synth.filter.env = finite(state.synth.filter.env, d.synth.filter.env, 0, 1)
    state.synth.lfo.rate = finite(state.synth.lfo.rate, d.synth.lfo.rate, 0.05, 30)
    state.synth.lfo.depth = finite(state.synth.lfo.depth, d.synth.lfo.depth, 0, 1)
    state.synth.level = finite(state.synth.level, d.synth.level, 0, 1)

    if !SAMPLE_NAMES.contains(state.sampler.preset) && state.sampler.preset != USER_PRESET {
        state.sampler.preset = d.sampler.preset
    }
    state.sampler.level = finite(state.sampler.level, d.sampler.level, 0, 1)
    state.sampler.attack = finite(state.sampler.attack, d.sampler.attack, 0.002, 0.5)
    state.sampler.release = finite(state.sampler.release, d.sampler.release, 0.02, 3)
    state.sampler.userRoot = clamp(state.sampler.userRoot, 24, 96)

    state.fx.reverb.fdbk = finite(state.fx.reverb.fdbk, d.fx.reverb.fdbk, 0, 1)
    state.fx.reverb.mix = finite(state.fx.reverb.mix, d.fx.reverb.mix, 0, 1)
    state.fx.delay.time = finite(state.fx.delay.time, d.fx.delay.time, 0.01, 2)
    state.fx.delay.fdbk = finite(state.fx.delay.fdbk, d.fx.delay.fdbk, 0, 0.9)
    state.fx.delay.mix = finite(state.fx.delay.mix, d.fx.delay.mix, 0, 1)
    state.fx.distort.amt = finite(state.fx.distort.amt, d.fx.distort.amt, 0, 1)
    state.fx.fatten.amt = finite(state.fx.fatten.amt, d.fx.fatten.amt, 0, 1)
    state.midi.bendRange = clamp(state.midi.bendRange, 1, 96)

    if !SCHEME_NAMES.contains(state.appearance.scheme) { state.appearance.scheme = d.appearance.scheme }
    state.appearance.brightness = finite(state.appearance.brightness, d.appearance.brightness, 0, 1)
    state.appearance.rippleAmount = finite(state.appearance.rippleAmount, d.appearance.rippleAmount, 0, 1)
    state.appearance.contrast = finite(state.appearance.contrast, d.appearance.contrast, 0, 1)
    return state
}

/// Merge `src` over `target`, keeping only keys that already exist with the
/// same JSON shape — the web build's localStorage tolerance, ported.
func deepMerge(_ target: inout [String: Any], _ src: Any) {
    guard let src = src as? [String: Any] else { return }
    for (k, v) in src {
        guard let t = target[k] else { continue }
        if var tDict = t as? [String: Any], v is [String: Any] {
            deepMerge(&tDict, v)
            target[k] = tDict
        } else if jsonKindMatches(t, v) {
            target[k] = v
        }
    }
}

private func jsonKindMatches(_ t: Any, _ v: Any) -> Bool {
    switch (t, v) {
    case (is String, is String): return true
    case (is NSNumber, is NSNumber):
        // NSNumber covers bools too; require bool-ness to match.
        let tb = (t as? NSNumber).map { CFGetTypeID($0) == CFBooleanGetTypeID() } ?? false
        let vb = (v as? NSNumber).map { CFGetTypeID($0) == CFBooleanGetTypeID() } ?? false
        return tb == vb
    case (is [Any], is [Any]): return true
    default: return false
    }
}
