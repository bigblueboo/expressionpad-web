import Testing
import Foundation
@testable import ExpressionPadCore

struct DSPTests {
    @Test func clampAndLerp() {
        let hi: Double = clamp(5.0, 0.0, 1.0)
        let lo: Double = clamp(-1.0, 0.0, 1.0)
        let mid: Double = lerp(0.0, 10.0, 0.5)
        #expect(hi == 1.0)
        #expect(lo == 0.0)
        #expect(mid == 5.0)
    }

    @Test func morphZeroIsPureSine() {
        let amps = harmonicAmps(0, 0.5)
        #expect(abs(abs(amps[0]) - 1) < 0.01)
        for a in amps.dropFirst() {
            #expect(abs(a) < 0.01)
        }
    }

    @Test func morphOneIsSquareLike() {
        let amps = harmonicAmps(1, 0.5)
        // Even harmonics absent.
        var k = 2
        while k <= amps.count {
            #expect(abs(amps[k - 1]) < 0.01)
            k += 2
        }
        #expect(abs(amps[2]) > 0.05) // 3rd harmonic present
    }

    @Test func sawRegionHasEvenHarmonics() {
        let amps = harmonicAmps(0.66, 0.5)
        #expect(abs(amps[1]) > 0.05) // 2nd harmonic present
    }

    @Test func ampsNormalizedToPeakOne() {
        for morph in [0.0, 0.25, 0.5, 0.75, 1.0] {
            for bright in [0.0, 0.5, 1.0] {
                let amps = harmonicAmps(morph, bright)
                let peak = amps.map { abs($0) }.max()!
                #expect(abs(peak - 1) < 1e-9)
            }
        }
    }

    @Test func brightnessLiftsUpperHarmonics() {
        let dark = harmonicAmps(0.66, 0)
        let bright = harmonicAmps(0.66, 1)
        #expect(abs(bright[15]) > abs(dark[15]))
    }

    @Test func driveCurveBoundedOddMonotonic() {
        let curve = driveCurve(0.7, 257)
        #expect(abs(curve[0] - -1) < 0.1)
        #expect(abs(curve[256] - 1) < 0.1)
        #expect(abs(curve[128]) < 1e-5)
        for i in 1..<curve.count {
            #expect(curve[i] >= curve[i - 1])
        }
    }

    @Test func cutoffToHzRange() {
        #expect(abs(cutoffToHz(0) - 40) < 1e-9)
        #expect(abs(cutoffToHz(1) - 20480) < 0.001)
        #expect(cutoffToHz(0.76) > cutoffToHz(0.75))
    }

    @Test func velocityToGainCurve() {
        #expect(abs(velocityToGain(0)) < 1e-9)
        #expect(abs(velocityToGain(1) - 1) < 1e-9)
        #expect(velocityToGain(0.8) > velocityToGain(0.4))
    }

    @Test func wavetableBuild() {
        let buf = UnsafeMutablePointer<Float>.allocate(capacity: Wavetable.totalSize)
        defer { buf.deallocate() }
        Wavetable.build(morph: 0.66, bright: 0.5, into: buf)
        // Full-band level peaks at 1.
        var peak: Float = 0
        for i in 0..<Wavetable.size { peak = max(peak, abs(buf[i])) }
        #expect(abs(peak - 1) < 0.001)
        // All levels finite; guard sample wraps.
        for level in 0..<Wavetable.levels {
            let base = level * Wavetable.stride
            for i in 0...Wavetable.size {
                #expect(buf[base + i].isFinite)
            }
            #expect(abs(buf[base + Wavetable.size] - buf[base]) < 1e-9)
        }
        // Higher mip levels carry fewer partials → less high-frequency wiggle.
        // (Sign changes are a crude spectral proxy.)
        func signChanges(_ level: Int) -> Int {
            let base = level * Wavetable.stride
            var changes = 0
            for i in 1..<Wavetable.size where (buf[base + i] >= 0) != (buf[base + i - 1] >= 0) {
                changes += 1
            }
            return changes
        }
        #expect(signChanges(0) >= signChanges(Wavetable.levels - 1))
    }

    @Test func wavetableLevelSelection() {
        // 100 Hz @48k: all 32 partials fit.
        #expect(Wavetable.level(forFreq: 100, sampleRate: 48000) == 0)
        // 2 kHz: 32 partials would reach 64 kHz — needs a higher mip.
        #expect(Wavetable.level(forFreq: 2000, sampleRate: 48000) > 0)
        // Absurd frequency: falls back to top (single sine) level.
        #expect(Wavetable.level(forFreq: 30000, sampleRate: 48000) == Wavetable.levels - 1)
    }

    @Test func biquadLowpassAttenuatesHighs() {
        var f = Biquad()
        f.setLowpass(freq: 500, qDb: 1, sampleRate: 48000)
        // Feed an 8 kHz sine; output RMS should be much lower than input.
        var inRms: Float = 0
        var outRms: Float = 0
        for i in 0..<4800 {
            let x = sin(Float(i) * 2 * .pi * 8000 / 48000)
            let y = f.process(x)
            if i > 480 { // skip transient
                inRms += x * x
                outRms += y * y
            }
        }
        #expect(sqrt(outRms) < sqrt(inRms) * 0.05)
    }

    @Test func biquadPassesLows() {
        var f = Biquad()
        f.setLowpass(freq: 5000, qDb: 1, sampleRate: 48000)
        var inRms: Float = 0
        var outRms: Float = 0
        for i in 0..<48000 {
            let x = sin(Float(i) * 2 * .pi * 100 / 48000)
            let y = f.process(x)
            if i > 4800 {
                inRms += x * x
                outRms += y * y
            }
        }
        #expect(abs(sqrt(outRms) - sqrt(inRms)) < sqrt(inRms) * 0.05)
    }

    @Test func onePoleApproachesTarget() {
        var p = OnePole(0)
        p.target = 1
        let alpha = smoothingAlpha(dt: 0.001, tau: 0.02)
        for _ in 0..<200 { _ = p.step(alpha) } // 200 ms >> 5 tau
        #expect(abs(p.value - 1) < 0.001)
    }

    @Test func limiterCurbsLoudPeaks() {
        var lim = Limiter(sampleRate: 48000)
        var maxOut: Float = 0
        for i in 0..<9600 {
            var l = sin(Float(i) * 2 * .pi * 440 / 48000) * 2.0 // +6 dB over full scale
            var r = l
            lim.process(l: &l, r: &r)
            if i > 960 { maxOut = max(maxOut, abs(l)) }
        }
        #expect(maxOut < 1.1)
        #expect(maxOut > 0.4)
    }
}

struct SampleGenTests {
    let SR = 8000.0

    @Test func instrumentList() {
        #expect(SAMPLE_NAMES.count >= 5)
        #expect(SAMPLE_NAMES.contains("English Horn"))
        #expect(!SAMPLE_NAMES.contains(USER_PRESET))
    }

    @Test func everyInstrumentRendersBoundedNonSilentPCM() {
        for name in SAMPLE_NAMES {
            let s = renderSample(name, SR)
            #expect(s.data.count > Int(SR / 2), "\(name)")
            #expect(s.root >= 36 && s.root <= 84, "\(name)")
            var peak: Float = 0
            var bounded = true
            for v in s.data {
                if abs(v) > 1 { bounded = false }
                peak = max(peak, abs(v))
            }
            #expect(bounded, "\(name)")
            #expect(peak > 0.5, "\(name)")
        }
    }

    @Test func sustainedInstrumentsHaveValidLoops() {
        for name in ["English Horn", "Choir", "Strings"] {
            let s = renderSample(name, SR)
            #expect(s.loopStart != nil, "\(name)")
            #expect(s.loopEnd == s.data.count, "\(name)")
            #expect(s.loopEnd! - s.loopStart! == Int(SR), "\(name)") // exactly 1 s
        }
    }

    @Test func loopPointsAreClickFree() {
        for name in ["English Horn", "Choir", "Strings"] {
            let s = renderSample(name, SR)
            var maxStep: Float = 0
            for i in (s.loopStart! + 1)..<s.loopEnd! {
                maxStep = max(maxStep, abs(s.data[i] - s.data[i - 1]))
            }
            let wrapStep = abs(s.data[s.loopStart!] - s.data[s.loopEnd! - 1])
            #expect(wrapStep <= maxStep * 1.5, "\(name)")
        }
    }

    @Test func oneShotsDecayToNearSilence() {
        for name in ["E-Piano", "Marimba", "Pluck"] {
            let s = renderSample(name, SR)
            #expect(s.loopStart == nil, "\(name)")
            func rms<S: Sequence>(_ xs: S) -> Float where S.Element == Float {
                var sum: Float = 0
                var n = 0
                for v in xs {
                    sum += v * v
                    n += 1
                }
                return sqrt(sum / Float(max(1, n)))
            }
            let tail = rms(s.data.suffix(s.data.count / 20))
            let head = rms(s.data.prefix(s.data.count / 5))
            #expect(tail < head * 0.3, "\(name)")
        }
    }

    @Test func unknownNameFallsBack() {
        let s = renderSample("Nope", SR)
        #expect(s.root == renderSample(SAMPLE_NAMES[0], SR).root)
    }
}
