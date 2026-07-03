/// Synth presets — names resurrected from the original app's preset menu.

public struct PresetPatch: Sendable {
    public var gen1: GenConfig
    public var gen2: GenConfig
    public var bright: Double
    public var env: EnvConfig
    public var filter: FilterConfig
    public var lfo: LfoConfig
}

public let SYNTH_PRESETS: [String: PresetPatch] = [
    "Super Sine": PresetPatch(
        gen1: GenConfig(morph: 0.08, semi: 0, tune: 0, level: 0.85),
        gen2: GenConfig(morph: 0.0, semi: 12, tune: 3, level: 0.22),
        bright: 0.4,
        env: EnvConfig(a: 0.01, d: 0.3, s: 0.75, r: 0.35),
        filter: FilterConfig(cutoff: 0.8, res: 0.1, env: 0.2),
        lfo: LfoConfig(rate: 5, depth: 0.08, target: .pitch)
    ),
    "Growl Dark": PresetPatch(
        gen1: GenConfig(morph: 0.95, semi: -12, tune: 0, level: 0.9),
        gen2: GenConfig(morph: 0.7, semi: -5, tune: -7, level: 0.55),
        bright: 0.35,
        env: EnvConfig(a: 0.03, d: 0.4, s: 0.6, r: 0.25),
        filter: FilterConfig(cutoff: 0.32, res: 0.55, env: 0.55),
        lfo: LfoConfig(rate: 3.2, depth: 0.25, target: .filter)
    ),
    "Square Tap": PresetPatch(
        gen1: GenConfig(morph: 1.0, semi: 0, tune: 0, level: 0.7),
        gen2: GenConfig(morph: 1.0, semi: 12, tune: 0, level: 0.3),
        bright: 0.55,
        env: EnvConfig(a: 0.002, d: 0.12, s: 0.25, r: 0.12),
        filter: FilterConfig(cutoff: 0.65, res: 0.3, env: 0.6),
        lfo: LfoConfig(rate: 6, depth: 0, target: .pitch)
    ),
    "Pole Position": PresetPatch(
        gen1: GenConfig(morph: 0.66, semi: 0, tune: -5, level: 0.75),
        gen2: GenConfig(morph: 0.66, semi: 0, tune: 6, level: 0.75),
        bright: 0.7,
        env: EnvConfig(a: 0.05, d: 0.35, s: 0.8, r: 0.5),
        filter: FilterConfig(cutoff: 0.45, res: 0.65, env: 0.45),
        lfo: LfoConfig(rate: 0.8, depth: 0.35, target: .filter)
    ),
    "Synolin": PresetPatch(
        gen1: GenConfig(morph: 0.4, semi: 0, tune: 0, level: 0.8),
        gen2: GenConfig(morph: 0.25, semi: 7, tune: 4, level: 0.35),
        bright: 0.6,
        env: EnvConfig(a: 0.12, d: 0.4, s: 0.85, r: 0.6),
        filter: FilterConfig(cutoff: 0.6, res: 0.2, env: 0.25),
        lfo: LfoConfig(rate: 5.5, depth: 0.18, target: .pitch)
    ),
    "Saw Demise": PresetPatch(
        gen1: GenConfig(morph: 0.62, semi: 0, tune: -8, level: 0.85),
        gen2: GenConfig(morph: 0.62, semi: -12, tune: 8, level: 0.6),
        bright: 0.8,
        env: EnvConfig(a: 0.01, d: 0.5, s: 0.55, r: 0.8),
        filter: FilterConfig(cutoff: 0.5, res: 0.4, env: 0.7),
        lfo: LfoConfig(rate: 4, depth: 0.12, target: .filter)
    ),
    "Room Drill": PresetPatch(
        gen1: GenConfig(morph: 1.0, semi: -24, tune: 0, level: 0.9),
        gen2: GenConfig(morph: 0.85, semi: -17, tune: 12, level: 0.5),
        bright: 0.9,
        env: EnvConfig(a: 0.001, d: 0.08, s: 0.9, r: 0.05),
        filter: FilterConfig(cutoff: 0.55, res: 0.75, env: 0.8),
        lfo: LfoConfig(rate: 12, depth: 0.4, target: .filter)
    ),
]

/// Menu order matches the web build.
public let PRESET_NAMES = [
    "Super Sine", "Growl Dark", "Square Tap", "Pole Position",
    "Synolin", "Saw Demise", "Room Drill",
]

/// Apply a preset through the store, one notification per changed leaf —
/// leaf-by-leaf so subscribers see the same dot-paths the web build emits.
public func applyPreset(_ name: String, to store: Store) {
    guard let p = SYNTH_PRESETS[name] else { return }
    store.set(\.synth.preset, name)
    store.set(\.synth.gen1.morph, p.gen1.morph)
    store.set(\.synth.gen1.semi, p.gen1.semi)
    store.set(\.synth.gen1.tune, p.gen1.tune)
    store.set(\.synth.gen1.level, p.gen1.level)
    store.set(\.synth.gen2.morph, p.gen2.morph)
    store.set(\.synth.gen2.semi, p.gen2.semi)
    store.set(\.synth.gen2.tune, p.gen2.tune)
    store.set(\.synth.gen2.level, p.gen2.level)
    store.set(\.synth.bright, p.bright)
    store.set(\.synth.env.a, p.env.a)
    store.set(\.synth.env.d, p.env.d)
    store.set(\.synth.env.s, p.env.s)
    store.set(\.synth.env.r, p.env.r)
    store.set(\.synth.filter.cutoff, p.filter.cutoff)
    store.set(\.synth.filter.res, p.filter.res)
    store.set(\.synth.filter.env, p.filter.env)
    store.set(\.synth.lfo.rate, p.lfo.rate)
    store.set(\.synth.lfo.depth, p.lfo.depth)
    store.set(\.synth.lfo.target, p.lfo.target)
}
