/// FX building blocks for the render kernel. Everything here is allocation-
/// free after init and processes single samples or small blocks.
///
/// Smoothing note: Web Audio's setTargetAtTime(v, t, tau) is a one-pole
/// exponential approach; `OnePole` reproduces it (stepped per 32-sample
/// block by the kernel, which is far below audibility for the taus used).
import Foundation

/// One-pole parameter smoother with setTargetAtTime semantics.
public struct OnePole {
    public var value: Float
    public var target: Float

    public init(_ initial: Float = 0) {
        value = initial
        target = initial
    }

    /// alpha = 1 - exp(-dt/tau) for the stepping interval.
    @inlinable public mutating func step(_ alpha: Float) -> Float {
        value += (target - value) * alpha
        return value
    }

    @inlinable public mutating func snap(_ v: Float) {
        value = v
        target = v
    }
}

@inlinable public func smoothingAlpha(dt: Float, tau: Float) -> Float {
    tau <= 0 ? 1 : 1 - exp(-dt / tau)
}

// ---------------------------------------------------------------- biquad ---

/// RBJ lowpass with Web Audio semantics: Q is in dB (α = sinω / 2·10^(Q/20)),
/// detune in cents multiplies the frequency by 2^(detune/1200).
public struct Biquad {
    @usableFromInline var b0: Float = 1
    @usableFromInline var b1: Float = 0
    @usableFromInline var b2: Float = 0
    @usableFromInline var a1: Float = 0
    @usableFromInline var a2: Float = 0
    @usableFromInline var s1: Float = 0
    @usableFromInline var s2: Float = 0

    public init() {}

    public mutating func setLowpass(freq: Float, qDb: Float, sampleRate: Float) {
        let nyquist = sampleRate / 2
        let f = min(max(freq, 10), nyquist * 0.999)
        let omega = 2 * Float.pi * f / sampleRate
        let cosw = cos(omega)
        let sinw = sin(omega)
        let q = pow(10, qDb / 20)
        let alpha = sinw / (2 * q)
        let a0 = 1 + alpha
        b0 = ((1 - cosw) / 2) / a0
        b1 = (1 - cosw) / a0
        b2 = ((1 - cosw) / 2) / a0
        a1 = (-2 * cosw) / a0
        a2 = (1 - alpha) / a0
    }

    /// Transposed direct form II.
    @inlinable public mutating func process(_ x: Float) -> Float {
        let y = b0 * x + s1
        s1 = b1 * x - a1 * y + s2
        s2 = b2 * x - a2 * y
        return y
    }

    public mutating func reset() {
        s1 = 0
        s2 = 0
    }
}

// ------------------------------------------------------------ distortion ---

/// tanh(kx)/tanh(k) soft clip, 2×-oversampled with a 17-tap half-band FIR
/// (the web shaper's `oversample: '2x'`). Dry/wet crossfade by the ON toggle.
public struct Distortion {
    /// Equiripple half-band; odd taps (except center) are zero.
    static let taps: [Float] = [
        -0.0105, 0, 0.0301, 0, -0.0821, 0, 0.3095, 0.5, 0.3095,
        0, -0.0821, 0, 0.0301, 0, -0.0105,
    ]
    var upState = [Float](repeating: 0, count: Distortion.taps.count)
    var downState = [Float](repeating: 0, count: Distortion.taps.count)
    public var k: Float = 1 + 0.3 * 30
    public var wet = OnePole(0)
    public var dry = OnePole(1)

    public init() {}

    static func fir(_ x: Float, _ state: inout [Float]) -> Float {
        for i in stride(from: state.count - 1, to: 0, by: -1) { state[i] = state[i - 1] }
        state[0] = x
        var acc: Float = 0
        for (i, t) in Distortion.taps.enumerated() where t != 0 { acc += t * state[i] }
        return acc
    }

    func shape(_ x: Float) -> Float {
        tanh(k * x) / tanh(k)
    }

    public mutating func process(_ x: Float, wetGain: Float, dryGain: Float) -> Float {
        // Upsample 2× (zero-stuff → half-band, ×2 gain), shape, filter, decimate.
        let u0 = Distortion.fir(x * 2, &upState)
        let u1 = Distortion.fir(0, &upState)
        let s0 = shape(u0)
        let s1v = shape(u1)
        let d0 = Distortion.fir(s0, &downState)
        _ = Distortion.fir(s1v, &downState)
        return x * dryGain + d0 * wetGain
    }
}

// ----------------------------------------------------------------- delay ---

/// Feedback delay with smoothly modulated (interpolated) delay time, like
/// Web Audio's DelayNode. Dry passes at unity; wet = mix when ON.
public struct FeedbackDelay {
    var buffer: [Float]
    var writeIdx = 0
    let sampleRate: Float
    public var timeSm: OnePole
    public var fdbkSm: OnePole
    public var wetSm: OnePole

    public init(maxSeconds: Float, sampleRate: Float) {
        self.sampleRate = sampleRate
        buffer = [Float](repeating: 0, count: Int(maxSeconds * sampleRate) + 2)
        timeSm = OnePole(0.34)
        fdbkSm = OnePole(0.35)
        wetSm = OnePole(0)
    }

    public mutating func process(_ x: Float, time: Float, fdbk: Float, wet: Float) -> Float {
        let n = buffer.count
        let delaySamples = min(Float(n - 2), max(1, time * sampleRate))
        var readPos = Float(writeIdx) - delaySamples
        if readPos < 0 { readPos += Float(n) }
        let i0 = Int(readPos)
        let frac = readPos - Float(i0)
        let i1 = i0 + 1 == n ? 0 : i0 + 1
        let out = buffer[i0] * (1 - frac) + buffer[i1] * frac
        buffer[writeIdx] = x + out * fdbk
        writeIdx += 1
        if writeIdx == n { writeIdx = 0 }
        return x + out * wet
    }
}

// ---------------------------------------------------------------- reverb ---

/// 8-line feedback delay network with Householder feedback and per-line
/// damping. Replaces the web build's generated-noise convolver: same diffuse
/// exponential tail, but the decay time tracks the FDBK knob continuously
/// (T60 = lerp(0.4, 5, fdbk) — the web IR's length mapping).
public struct FDNReverb {
    static let baseLengths = [1129, 1447, 1801, 2099, 2393, 2683, 3079, 3469] // @48k, mutually prime
    var lines: [[Float]]
    var idx = [Int](repeating: 0, count: 8)
    var damp = [Float](repeating: 0, count: 8)
    var lengths = [Int](repeating: 0, count: 8)
    var gains = [Float](repeating: 0, count: 8)
    let sampleRate: Float
    public var wetSm = OnePole(0)
    var t60: Float = -1

    public init(sampleRate: Float) {
        self.sampleRate = sampleRate
        let scale = sampleRate / 48000
        lines = FDNReverb.baseLengths.map { base in
            [Float](repeating: 0, count: max(64, Int(Float(base) * scale)))
        }
        for i in 0..<8 { lengths[i] = lines[i].count }
        setDecay(seconds: 2.7)
    }

    /// Per-line feedback gain for a target T60.
    public mutating func setDecay(seconds: Float) {
        if seconds == t60 { return }
        t60 = seconds
        for i in 0..<8 {
            gains[i] = pow(10, -3 * Float(lengths[i]) / (max(0.05, seconds) * sampleRate))
        }
    }

    var read = [Float](repeating: 0, count: 8)

    public mutating func process(_ x: Float, into out: inout (l: Float, r: Float)) {
        for i in 0..<8 { read[i] = lines[i][idx[i]] }
        // Householder feedback: y = x - (2/N)·sum(x), orthogonal for N=8.
        var sum: Float = 0
        for i in 0..<8 { sum += read[i] }
        let h = sum * 0.25
        let inScale: Float = 0.35
        for i in 0..<8 {
            let fb = (read[i] - h) * gains[i]
            // One-pole damping keeps the tail darkening like the IR's rolloff.
            damp[i] += (fb - damp[i]) * 0.55
            lines[i][idx[i]] = damp[i] + x * inScale
            idx[i] += 1
            if idx[i] == lengths[i] { idx[i] = 0 }
        }
        out.l = (read[0] - read[2] + read[4] - read[6]) * 0.6
        out.r = (read[1] - read[3] + read[5] - read[7]) * 0.6
    }
}

// --------------------------------------------------------------- limiter ---

/// The Web Audio DynamicsCompressor static curve (threshold −3 dB, knee 6,
/// ratio 12, attack 2 ms, release 100 ms) with its spec makeup gain, minus
/// the node's ~6 ms lookahead delay.
public struct Limiter {
    let thresholdDb: Float = -3
    let kneeDb: Float = 6
    let ratio: Float = 12
    var attackCoef: Float
    var releaseCoef: Float
    var envelope: Float = 0
    let makeup: Float

    public init(sampleRate: Float) {
        attackCoef = exp(-1 / (0.002 * sampleRate))
        releaseCoef = exp(-1 / (0.1 * sampleRate))
        // Spec makeup: (1 / gain-at-0dBFS)^0.6.
        let g0 = Limiter.staticGainDb(0, threshold: -3, knee: 6, ratio: 12)
        makeup = pow(1 / pow(10, g0 / 20), 0.6)
    }

    /// Gain reduction (dB, <= 0) for an input level (dB).
    static func staticGainDb(_ levelDb: Float, threshold: Float, knee: Float, ratio: Float) -> Float {
        let lower = threshold - knee / 2
        if levelDb <= lower { return 0 }
        if levelDb >= threshold + knee / 2 {
            return threshold + (levelDb - threshold) / ratio - levelDb
        }
        let x = levelDb - lower
        return (1 / ratio - 1) * x * x / (2 * knee)
    }

    public mutating func process(l: inout Float, r: inout Float) {
        let peak = max(abs(l), abs(r))
        // Envelope follower in linear domain (attack when rising).
        let coef = peak > envelope ? attackCoef : releaseCoef
        envelope = peak + coef * (envelope - peak)
        let levelDb = 20 * log10(max(envelope, 1e-6))
        let gainDb = Limiter.staticGainDb(levelDb, threshold: thresholdDb, knee: kneeDb, ratio: ratio)
        let gain = pow(10, gainDb / 20) * makeup
        l *= gain
        r *= gain
    }
}
