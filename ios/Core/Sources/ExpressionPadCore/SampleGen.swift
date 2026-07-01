/// Built-in instrument samples, rendered as PCM with plain math so they ship
/// as code, not audio files — and stay unit-testable.
///
/// Sustained instruments are built from components whose frequencies all
/// complete an integer number of cycles over the loop window, so the loop
/// point is mathematically click-free. Detunes are ±1 Hz (integer cycles over
/// a 1 s loop) which gives slow ensemble beating that survives the loop.
import Foundation

public struct RenderedSample {
    public var data: [Float]
    /// MIDI note the sample is pitched at.
    public var root: Int
    /// Loop window in samples; absent = one-shot.
    public var loopStart: Int?
    public var loopEnd: Int?
}

struct Component {
    var freq: Double
    var amp: Double
    /// Exponential decay rate (1/s); 0 = sustain.
    var decay: Double = 0
    /// FM: modulator freq and index (for e-piano bark).
    var fmFreq: Double = 0
    var fmIndex: Double = 0
}

func normalize(_ data: inout [Float], peak: Float = 0.9) {
    var maxV: Float = 0
    for s in data { maxV = max(maxV, abs(s)) }
    if maxV > 0 {
        let k = peak / maxV
        for i in 0..<data.count { data[i] *= k }
    }
}

func renderComponents(
    _ sr: Double, _ seconds: Double, _ components: [Component],
    _ envelope: (Double) -> Double
) -> [Float] {
    let len = Int((seconds * sr).rounded())
    var data = [Float](repeating: 0, count: len)
    for i in 0..<len {
        let t = Double(i) / sr
        var s = 0.0
        for c in components {
            let fm = c.fmFreq != 0 ? c.fmIndex * sin(2 * .pi * c.fmFreq * t) : 0
            let d = c.decay != 0 ? exp(-c.decay * t) : 1
            s += c.amp * d * sin(2 * .pi * c.freq * t + fm)
        }
        data[i] = Float(s * envelope(t))
    }
    normalize(&data)
    return data
}

/// Sustained, looping instrument: attack segment + a 1 s loop window.
func sustained(_ sr: Double, _ root: Int, _ components: [Component], _ attack: Double) -> RenderedSample {
    let loopSec = 1.0
    let seconds = attack + loopSec
    let env: (Double) -> Double = { t in t < attack ? (t / attack) * (t / attack) : 1 }
    let data = renderComponents(sr, seconds, components, env)
    return RenderedSample(data: data, root: root, loopStart: Int((attack * sr).rounded()), loopEnd: data.count)
}

func oneShot(_ sr: Double, _ root: Int, _ seconds: Double, _ components: [Component]) -> RenderedSample {
    let env: (Double) -> Double = { t in min(1, t * 400) } // 2.5 ms anti-click ramp
    return RenderedSample(data: renderComponents(sr, seconds, components, env), root: root)
}

/// Karplus-Strong plucked string.
func pluck(_ sr: Double, _ root: Int, _ freq: Double, _ seconds: Double) -> RenderedSample {
    let n = max(2, Int((sr / freq).rounded()))
    var delay = [Float](repeating: 0, count: n)
    // Deterministic noise so renders are reproducible.
    var seed: Int64 = 1_234_567
    func rand() -> Float {
        seed = (seed * 1_103_515_245 + 12345) & 0x7fff_ffff
        return Float(seed) / Float(0x7fff_ffff) - 0.5
    }
    for i in 0..<n { delay[i] = rand() * 2 }
    let len = Int((seconds * sr).rounded())
    var data = [Float](repeating: 0, count: len)
    var idx = 0
    for i in 0..<len {
        let next = delay[(idx + 1) % n]
        let cur = delay[idx]
        let avg = 0.5 * (cur + next) * 0.996
        data[i] = cur
        delay[idx] = avg
        idx = (idx + 1) % n
    }
    normalize(&data)
    return RenderedSample(data: data, root: root)
}

// 220 Hz = A3 (midi 57) exactly; 110 Hz = A2 (midi 45); 440 Hz = A4 (midi 69).

let BUILDERS: [String: (Double) -> RenderedSample] = [
    "English Horn": { sr in
        sustained(sr, 57, [
            Component(freq: 220, amp: 0.4), Component(freq: 440, amp: 0.75), Component(freq: 660, amp: 1.0),
            Component(freq: 880, amp: 0.95), Component(freq: 1100, amp: 0.6), Component(freq: 1320, amp: 0.35),
            Component(freq: 1540, amp: 0.22), Component(freq: 1760, amp: 0.12), Component(freq: 1980, amp: 0.06),
        ], 0.12)
    },
    "Choir": { sr in
        sustained(sr, 57, [
            Component(freq: 220, amp: 1.0), Component(freq: 219, amp: 0.6), Component(freq: 221, amp: 0.6),
            Component(freq: 440, amp: 0.45), Component(freq: 441, amp: 0.3),
            Component(freq: 660, amp: 0.18), Component(freq: 880, amp: 0.4), Component(freq: 1100, amp: 0.25),
            Component(freq: 1320, amp: 0.07),
        ], 0.35)
    },
    "Strings": { sr in
        var comps: [Component] = []
        for k in 1...14 {
            let amp = (1 / Double(k)) * pow(0.92, Double(k))
            comps.append(Component(freq: 110 * Double(k), amp: amp))
            if k <= 4 {
                comps.append(Component(freq: 110 * Double(k) + 1, amp: amp * 0.6))
                comps.append(Component(freq: 110 * Double(k) - 1, amp: amp * 0.6))
            }
        }
        return sustained(sr, 45, comps, 0.3)
    },
    "E-Piano": { sr in
        oneShot(sr, 60, 3.2, [
            Component(freq: 261.63, amp: 1.0, decay: 1.1),
            Component(freq: 523.26, amp: 0.4, decay: 2.4),
            Component(freq: 1046.5, amp: 0.25, decay: 6, fmFreq: 261.63, fmIndex: 1.4),
            Component(freq: 2093.0, amp: 0.08, decay: 12),
        ])
    },
    "Marimba": { sr in
        oneShot(sr, 69, 1.8, [
            Component(freq: 440, amp: 1.0, decay: 4.5),
            Component(freq: 1760, amp: 0.5, decay: 16),
            Component(freq: 4048, amp: 0.25, decay: 40),
        ])
    },
    "Pluck": { sr in pluck(sr, 57, 220, 2.5) },
]

/// Menu order matches the web build.
public let SAMPLE_NAMES = ["English Horn", "Choir", "Strings", "E-Piano", "Marimba", "Pluck"]

public let USER_PRESET = "User Sample"

public func renderSample(_ name: String, _ sampleRate: Double) -> RenderedSample {
    let builder = BUILDERS[name] ?? BUILDERS[SAMPLE_NAMES[0]]!
    return builder(sampleRate)
}
