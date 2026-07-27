/// Expression policy — the single definition of what the pressure axis does
/// to a voice for each routing target, plus the kernel-side typed routes.
///
/// The event ring stays a plain-Float channel (allocation-free), but the
/// serialization format is decoded exactly once in `applyParam`; everything
/// past that boundary works with these enums. The render path consumes
/// `pressureModulation` instead of branching on the route itself, so a route
/// change is atomic: every destination gets an explicit value, and abandoned
/// destinations return to neutral (filter 0, level 1, lfo 1).

/// Kernel-side pressure routing, decoded from the ring's Float payload.
enum KernelPressureRoute: Int32 {
    case filter = 0, level, lfo, off

    init(_ target: PressureTarget) {
        switch target {
        case .filter: self = .filter
        case .level: self = .level
        case .lfo: self = .lfo
        case .off: self = .off
        }
    }

    init(payload: Float) {
        self = KernelPressureRoute(rawValue: Int32(payload.rounded())) ?? .filter
    }
}

/// Kernel-side tilt routing, decoded from the ring's Float payload.
enum KernelTiltRoute: Int32 {
    case off = 0, filter, level, lfo

    init(_ target: TiltTarget) {
        switch target {
        case .off: self = .off
        case .filter: self = .filter
        case .level: self = .level
        case .lfo: self = .lfo
        }
    }

    init(payload: Float) {
        self = KernelTiltRoute(rawValue: Int32(payload.rounded())) ?? .off
    }
}

/// Quietest a voice gets when pressure is routed to level (swell floor).
let EXPR_LEVEL_FLOOR: Float = 0.3

enum VoiceProfile {
    case synth, sampler
}

struct PressureModulation {
    /// Routed pressure 0..1 for the filter; engines scale to their cutoff range.
    var filter: Float
    /// Post-envelope gain multiplier.
    var level: Float
    /// Per-voice scale on the LFO send (synth only; samples have no LFO).
    var lfo: Float

    static let neutral = PressureModulation(filter: 0, level: 1, lfo: 1)
}

func pressureModulation(
    _ route: KernelPressureRoute, _ pressure: Float, _ profile: VoiceProfile
) -> PressureModulation {
    let p = clamp(pressure, 0, 1)
    switch route {
    case .filter:
        // The sampler's classic touch response brightens AND gently swells.
        return PressureModulation(
            filter: p, level: profile == .sampler ? 1 + 0.35 * p : 1, lfo: 1
        )
    case .level:
        return PressureModulation(filter: 0, level: lerp(EXPR_LEVEL_FLOOR, 1, p), lfo: 1)
    case .lfo:
        return PressureModulation(filter: 0, level: 1, lfo: profile == .synth ? p : 1)
    case .off:
        return .neutral
    }
}
