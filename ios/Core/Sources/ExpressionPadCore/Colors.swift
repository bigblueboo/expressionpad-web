/// Key coloring schemes, riffing on the original app's looks:
/// Ocean (blue grid), Magenta (red/pink pianos), Rainbow (colored hexes),
/// Mono (grayscale hexes/pianos).
///
/// Platform-agnostic HSL math; the renderer converts HSL → its color type.
import Foundation

public struct HSL: Equatable, Sendable {
    public var h: Double
    public var s: Double
    public var l: Double

    public init(h: Double, s: Double, l: Double) {
        self.h = h
        self.s = s
        self.l = l
    }
}

public struct KeyColors: Sendable {
    public var fill: HSL
    public var stroke: HSL
    public var label: HSL
}

public let SCHEME_NAMES = ["Studio", "Ocean", "Magenta", "Rainbow", "Mono"]

public struct ColorOpts: Sendable {
    /// 0..1 overall brightness.
    public var brightness: Double
    /// 0..1 light/dark spread between piano whites and blacks.
    public var contrast: Double
    /// Base note of the pad — its pitch class is emphasized as the root.
    public var baseNote: Int
    public var dark: Bool

    public init(brightness: Double, contrast: Double, baseNote: Int, dark: Bool = false) {
        self.brightness = brightness
        self.contrast = contrast
        self.baseNote = baseNote
        self.dark = dark
    }
}

func schemeHsl(_ scheme: String, _ key: KeyShape, _ opts: ColorOpts) -> HSL {
    let pc = pitchClass(key.note)
    let rootPc = pitchClass(opts.baseNote)
    let fromRoot = Double((pc - rootPc + 12) % 12)
    let isRoot = fromRoot == 0
    switch scheme {
    case "Studio":
        let black = key.kind == .black
        let accidental = BLACK_PCS.contains(pc) && key.kind != .white
        let c = opts.contrast
        if opts.dark {
            let l = black ? 14 - 4 * c : isRoot ? 37 + 3 * c : accidental ? 21 - 5 * c : 28 + 6 * c
            return HSL(h: 76, s: 17, l: l * (0.7 + 0.45 * opts.brightness))
        }
        let l = black ? 27 - 10 * c : (isRoot ? 66 + 4 * c : accidental ? 66 - 8 * c : 72 + 8 * c) + (opts.brightness - 0.65) * 24
        return HSL(h: 76, s: 19, l: l)
    case "Rainbow":
        return HSL(h: fromRoot * 30, s: 62, l: isRoot ? 56 : 42)
    case "Magenta":
        return HSL(h: 320 + fromRoot * 4, s: 60, l: isRoot ? 52 : 30 + fromRoot.truncatingRemainder(dividingBy: 5) * 5)
    case "Mono":
        return HSL(h: 210, s: 6, l: isRoot ? 62 : 26 + fromRoot.truncatingRemainder(dividingBy: 6) * 5)
    default: // Ocean
        return HSL(h: 196 + fromRoot * 5, s: 64, l: isRoot ? 55 : 30 + fromRoot.truncatingRemainder(dividingBy: 5) * 6)
    }
}

/// Pitch classes that are black keys on a conventional piano.
let BLACK_PCS: Set<Int> = [1, 3, 6, 8, 10]

public func keyColors(_ scheme: String, _ key: KeyShape, _ opts: ColorOpts) -> KeyColors {
    var hsl = schemeHsl(scheme, key, opts)
    // CONTRAST widens or narrows the light/dark spread between whites and
    // blacks (0.5 keeps blacks at their resting depth).
    let c = opts.contrast
    if scheme != "Studio" {
    // Grid keys take a cue from the piano: conventional black-key pitch
    // classes go dark like piano blacks, so the natural lattice is legible
    // at a glance. An accidental root keeps a little extra light.
    if (key.kind == .rect || key.kind == .hex) && BLACK_PCS.contains(pitchClass(key.note)) {
        hsl.s = min(hsl.s, 50)
        hsl.l = (pitchClass(key.note) == pitchClass(opts.baseNote) ? 32 : 22) - 12 * c
    }
    // Piano rows: whites stay bright, blacks stay dark, both tinted by the
    // scheme — richly for colored schemes, near-neutral for Mono.
    if key.kind == .white {
        hsl.s = scheme == "Mono" ? 6 : min(hsl.s + 5, 62)
        hsl.l = scheme == "Mono" ? 58 + 36 * c : 46 + 30 * c
    } else if key.kind == .black {
        hsl.s = min(hsl.s, 55)
        hsl.l = 22 - 12 * c
    }
    hsl.l = max(4, min(92, hsl.l * (0.55 + 0.9 * opts.brightness)))
    }
    let fill = hsl
    let stroke = HSL(h: hsl.h, s: max(0, hsl.s - 15), l: max(0, hsl.l - 14))
    return KeyColors(fill: fill, stroke: stroke, label: labelColor(fill))
}

/// Recalculate contrast after ripples and held-note inversion as well.
public func labelColor(_ fill: HSL) -> HSL {
    let dark = HSL(h: fill.h, s: 10, l: 1)
    let light = HSL(h: fill.h, s: 10, l: 99.5)
    return contrastRatio(dark, fill) >= contrastRatio(light, fill) ? dark : light
}

/// WCAG-ish relative luminance (approximate, for contrast checks).
public func hslLuminance(_ hsl: HSL) -> Double {
    let (h, s, l) = (hsl.h, hsl.s, hsl.l)
    let a = (s / 100) * min(l / 100, 1 - l / 100)
    func f(_ n: Double) -> Double {
        let k = (n + h / 30).truncatingRemainder(dividingBy: 12)
        return l / 100 - a * max(-1, min(min(k - 3, 9 - k), 1))
    }
    func lin(_ c: Double) -> Double {
        c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
    }
    return 0.2126 * lin(f(0)) + 0.7152 * lin(f(8)) + 0.0722 * lin(f(4))
}

public func contrastRatio(_ c1: HSL, _ c2: HSL) -> Double {
    let l1 = hslLuminance(c1)
    let l2 = hslLuminance(c2)
    let (hi, lo) = l1 > l2 ? (l1, l2) : (l2, l1)
    return (hi + 0.05) / (lo + 0.05)
}
