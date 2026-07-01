/// Pure DSP math — kept free of audio-engine objects so it is unit-testable.
import Foundation

@inlinable public func clamp<T: Comparable>(_ v: T, _ lo: T, _ hi: T) -> T {
    min(hi, max(lo, v))
}

@inlinable public func lerp(_ a: Double, _ b: Double, _ t: Double) -> Double {
    a + (b - a) * t
}

@inlinable public func lerp(_ a: Float, _ b: Float, _ t: Float) -> Float {
    a + (b - a) * t
}

public let PARTIAL_COUNT = 32

/// Additive harmonic amplitude recipe.
/// morph 0..1 sweeps sine → triangle → saw → square; bright tilts the
/// harmonic rolloff darker (0) or brighter (1).
public func harmonicAmps(_ morph: Double, _ bright: Double, _ n: Int = PARTIAL_COUNT) -> [Double] {
    let m = clamp(morph, 0, 1)
    let recipes: [(Int) -> Double] = [
        { k in k == 1 ? 1 : 0 }, // sine
        { k in k % 2 == 1 ? Double(k % 4 == 1 ? 1 : -1) / Double(k * k) : 0 }, // triangle
        { k in 1 / Double(k) }, // saw
        { k in k % 2 == 1 ? 1 / Double(k) : 0 }, // square
    ]
    let seg = m * Double(recipes.count - 1)
    let i = min(recipes.count - 2, Int(floor(seg)))
    let t = seg - Double(i)
    let tilt = lerp(-0.9, 0.7, clamp(bright, 0, 1))
    var amps: [Double] = []
    var peak = 0.0
    for k in 1...n {
        var a = lerp(recipes[i](k), recipes[i + 1](k), t)
        if k > 1 { a *= pow(Double(k), tilt) }
        amps.append(a)
        peak = max(peak, abs(a))
    }
    return peak > 0 ? amps.map { $0 / peak } : amps
}

/// Soft-clip waveshaper curve; amount 0..1. (The kernel evaluates the same
/// tanh transfer directly; this sampled form exists for test parity.)
public func driveCurve(_ amount: Double, _ n: Int = 1024) -> [Double] {
    let k = 1 + clamp(amount, 0, 1) * 30
    var curve = [Double](repeating: 0, count: n)
    let norm = tanh(k)
    for s in 0..<n {
        let x = (Double(s) / Double(n - 1)) * 2 - 1
        curve[s] = tanh(k * x) / norm
    }
    return curve
}

/// Map normalized filter cutoff 0..1 to Hz on a log scale.
@inlinable public func cutoffToHz(_ norm: Double) -> Double {
    40 * pow(2, clamp(norm, 0, 1) * 9) // 40 Hz .. ~20.5 kHz
}

/// Perceptual velocity → gain.
@inlinable public func velocityToGain(_ vel: Double) -> Double {
    let v = clamp(vel, 0, 1)
    return v * v * 0.85 + v * 0.15
}

// ------------------------------------------------------------- wavetables ---

/// Band-limited wavetable mipmap for one generator.
///
/// The web build hands the browser a PeriodicWave and gets band-limiting for
/// free (implementations render octave-banded copies). Here the same additive
/// recipe is baked into `LEVELS` tables with successively halved partial
/// counts; the oscillator picks the highest level whose top partial stays
/// below Nyquist and cross-fades between neighboring levels while gliding.
public enum Wavetable {
    public static let size = 2048
    /// Max partial count per mip level.
    public static let levelPartials = [32, 16, 8, 4, 2, 1]
    public static var levels: Int { levelPartials.count }
    /// Floats per level: table + 1 guard sample for interpolation.
    public static var stride: Int { size + 1 }
    /// Total floats in one generator's table set.
    public static var totalSize: Int { levels * stride }

    /// Exact integer-harmonic sine synthesis needs sin(2π·k·i/N) only at
    /// table resolution, so one shared sine table gives error-free partials.
    static let sine: [Double] = (0..<size).map { sin(2 * .pi * Double($0) / Double(size)) }

    /// Build all mip levels into `out` (length >= totalSize).
    /// Matches PeriodicWave normalization: the full-band waveform is scaled
    /// to peak 1 and every level shares that factor so loudness is stable
    /// across octaves.
    public static func build(morph: Double, bright: Double, into out: UnsafeMutablePointer<Float>) {
        let amps = harmonicAmps(morph, bright)
        var scratch = [Double](repeating: 0, count: size)
        var norm = 1.0
        for (level, partials) in levelPartials.enumerated() {
            for i in 0..<size { scratch[i] = 0 }
            for k in 0..<partials {
                let a = amps[k]
                if a == 0 { continue }
                let harmonic = k + 1
                var idx = 0
                for i in 0..<size {
                    scratch[i] += a * sine[idx]
                    idx += harmonic
                    if idx >= size { idx -= size }
                }
            }
            if level == 0 {
                var peak = 0.0
                for v in scratch { peak = max(peak, abs(v)) }
                norm = peak > 0 ? 1 / peak : 1
            }
            let base = level * stride
            for i in 0..<size { out[base + i] = Float(scratch[i] * norm) }
            out[base + size] = out[base] // guard sample
        }
    }

    /// Mip level so that `partials(level) * freq <= nyquist` (falls back to
    /// the single-sine top level).
    @inlinable public static func level(forFreq freq: Double, sampleRate: Double) -> Int {
        let nyquist = sampleRate / 2
        for (level, partials) in levelPartials.enumerated() {
            if Double(partials) * freq <= nyquist { return level }
        }
        return levels - 1
    }
}
