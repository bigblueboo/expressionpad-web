import Testing
import Foundation
@testable import ExpressionPadCore

private let SR = 48000.0

private extension SynthKernel {
    /// Render `frames` and return (left, right).
    func renderBuffer(_ frames: Int) -> ([Float], [Float]) {
        var l = [Float](repeating: 0, count: frames)
        var r = [Float](repeating: 0, count: frames)
        l.withUnsafeMutableBufferPointer { lp in
            r.withUnsafeMutableBufferPointer { rp in
                render(frames: frames, outL: lp.baseAddress!, outR: rp.baseAddress!)
            }
        }
        return (l, r)
    }
}

private func rms(_ xs: ArraySlice<Float>) -> Float {
    var sum: Float = 0
    for v in xs { sum += v * v }
    return sqrt(sum / Float(max(1, xs.count)))
}

private func allFinite(_ xs: [Float]) -> Bool {
    xs.allSatisfy { $0.isFinite }
}

struct EventRingTests {
    @Test func pushPopRoundTrip() {
        let ring = EventRing(capacity: 8)
        ring.push(.noteOn(dest: .synth, id: 7, pitch: 60, vel: 0.5))
        ring.push(.param(.synthLevel, 0.9))
        guard case let .noteOn(dest, id, pitch, vel)? = ring.pop() else {
            Issue.record("expected noteOn")
            return
        }
        #expect(dest == .synth)
        #expect(id == 7)
        #expect(pitch == 60)
        #expect(vel == 0.5)
        guard case let .param(pid, v)? = ring.pop() else {
            Issue.record("expected param")
            return
        }
        #expect(pid == .synthLevel)
        #expect(v == 0.9)
        #expect(ring.pop() == nil)
    }

    @Test func overflowDropsNotCorrupts() {
        let ring = EventRing(capacity: 8)
        for i in 0..<20 {
            ring.push(.param(.synthLevel, Float(i)))
        }
        #expect(ring.dropped == 12)
        var count = 0
        while ring.pop() != nil { count += 1 }
        #expect(count == 8)
    }

    @Test func overflowPreservesTerminalSafety() {
        let kernel = SynthKernel(sampleRate: SR)
        kernel.events.push(.noteOn(dest: .synth, id: 1, pitch: 60, vel: 1))
        _ = kernel.renderBuffer(64)
        for i in 0..<1100 {
            kernel.events.push(.param(.synthLevel, Float(i % 10) / 10))
        }
        kernel.events.push(.noteOff(dest: .synth, id: 1))
        _ = kernel.renderBuffer(64)
        #expect(!kernel.voices.contains(where: { $0.active && $0.id == 1 }))
    }

    @Test func overflowTerminalRunsAfterEarlierQueuedNoteOn() {
        let kernel = SynthKernel(sampleRate: SR)
        kernel.events.push(.noteOn(dest: .synth, id: 1, pitch: 60, vel: 1))
        for i in 0..<1100 {
            kernel.events.push(.param(.synthLevel, Float(i % 10) / 10))
        }
        kernel.events.push(.noteOff(dest: .synth, id: 1))
        _ = kernel.renderBuffer(64)
        #expect(!kernel.voices.contains(where: { $0.active && $0.id == 1 }))
    }
}

struct KernelTests {
    @Test func silenceWhenIdle() {
        let kernel = SynthKernel(sampleRate: SR)
        let (l, r) = kernel.renderBuffer(4800)
        #expect(allFinite(l))
        #expect(rms(l[0...]) < 1e-6)
        #expect(rms(r[0...]) < 1e-6)
    }

    @Test func noteOnProducesSoundNoteOffDecays() {
        let kernel = SynthKernel(sampleRate: SR)
        kernel.events.push(.noteOn(dest: .synth, id: 1, pitch: 60, vel: 0.9))
        let (attack, _) = kernel.renderBuffer(9600) // 200 ms
        #expect(allFinite(attack))
        #expect(rms(attack[4800...]) > 0.005)

        kernel.events.push(.noteOff(dest: .synth, id: 1))
        // Default release 0.3 s; render well past r*2+0.1 plus the reverb tail.
        var tail: [Float] = []
        for _ in 0..<40 {
            (tail, _) = kernel.renderBuffer(4800)
        }
        #expect(allFinite(tail))
        #expect(rms(tail[0...]) < 1e-4)
        #expect(kernel.voiceCount == 0)
    }

    @Test func sameDrainSynthTapStillProducesAnOnset() {
        let kernel = SynthKernel(sampleRate: SR)
        kernel.events.push(.param(.reverbOn, 0))
        kernel.events.push(.noteOn(dest: .synth, id: 1, pitch: 60, vel: 1))
        kernel.events.push(.noteOff(dest: .synth, id: 1))
        let (left, _) = kernel.renderBuffer(240)
        #expect(rms(left[0...]) > 1e-5)
    }

    @Test func polyphonyAndVoiceStealing() {
        let kernel = SynthKernel(sampleRate: SR)
        for i in 0..<12 {
            kernel.events.push(.noteOn(dest: .synth, id: Int32(i), pitch: Float(50 + i), vel: 0.8))
        }
        let (l, _) = kernel.renderBuffer(4800)
        #expect(allFinite(l))
        #expect(rms(l[2400...]) > 0.005)
        // Playing voices capped at 10 (released tails may linger).
        var playing = 0
        for v in kernel.voices where v.active && !v.released { playing += 1 }
        #expect(playing <= SynthKernel.maxVoices)
    }

    @Test func correlatedPolyphonyStaysWithinOutputHeadroom() {
        let kernel = SynthKernel(sampleRate: SR)
        kernel.events.push(.param(.reverbOn, 0))
        for id: Int32 in 1...10 {
            kernel.events.push(.noteOn(dest: .synth, id: id, pitch: 60, vel: 1))
        }
        let (left, right) = kernel.renderBuffer(4800)
        let peak = zip(left, right).reduce(Float(0)) {
            max($0, abs($1.0), abs($1.1))
        }
        #expect(peak <= 1, "peak was \(peak)")
    }

    @Test func rapidTapsStayFiniteAndContinuousAtRenderBoundaries() {
        let kernel = SynthKernel(sampleRate: SR)
        let frames = 240 // requested hardware I/O quantum: 5 ms @ 48 kHz
        var previous: Float = 0
        var largestBoundaryJump: Float = 0
        var nextId: Int32 = 0
        var activeId: Int32?

        // Fifty taps/second is intentionally beyond a normal single-finger
        // performance and forces release-tail slot reuse.
        for block in 0..<200 {
            if block % 4 == 0 {
                nextId += 1
                activeId = nextId
                kernel.events.push(.noteOn(dest: .synth, id: nextId, pitch: 60, vel: 1))
            } else if block % 4 == 1, let id = activeId {
                kernel.events.push(.noteOff(dest: .synth, id: id))
                activeId = nil
            }
            let (left, right) = kernel.renderBuffer(frames)
            #expect(allFinite(left))
            #expect(allFinite(right))
            largestBoundaryJump = max(largestBoundaryJump, abs(left[0] - previous))
            previous = left[frames - 1]
        }

        #expect(largestBoundaryJump < 0.1)
        #expect(kernel.voiceCount <= SynthKernel.voiceSlots)
    }

    @Test func slotPressureReclaimsAReleasedTailBeforeAHeldSynthVoice() {
        let kernel = SynthKernel(sampleRate: SR)
        kernel.events.push(.noteOn(dest: .synth, id: 1, pitch: 48, vel: 0.7))
        _ = kernel.renderBuffer(240)

        for id: Int32 in 2...24 {
            kernel.events.push(.noteOn(dest: .synth, id: id, pitch: 72, vel: 1))
            _ = kernel.renderBuffer(64)
            kernel.events.push(.noteOff(dest: .synth, id: id))
            _ = kernel.renderBuffer(64)
        }
        kernel.events.push(.noteOn(dest: .synth, id: 25, pitch: 76, vel: 1))
        _ = kernel.renderBuffer(32)

        #expect(kernel.findSynth(1) != nil)
        _ = kernel.renderBuffer(64)
        #expect(kernel.findSynth(25) != nil)
    }

    @Test func glideMovesPitch() {
        let kernel = SynthKernel(sampleRate: SR)
        kernel.events.push(.param(.slide, 0.35))
        kernel.events.push(.noteOn(dest: .synth, id: 1, pitch: 60, vel: 0.9))
        _ = kernel.renderBuffer(4800)
        kernel.events.push(.glide(dest: .synth, id: 1, pitch: 72))
        _ = kernel.renderBuffer(9600) // let the one-pole settle
        let v = kernel.voices.first { $0.active && $0.id == 1 }!
        let expected = Float(midiToFreq(72))
        #expect(abs(v.freqCur[0] - expected) < expected * 0.02)
    }

    @Test func tuneUpdatesRetainGeneratorAndFattenAssignments() {
        let kernel = SynthKernel(sampleRate: SR)
        kernel.events.push(.param(.fattenOn, 1))
        kernel.events.push(.param(.fattenAmt, 0.4))
        kernel.events.push(.noteOn(dest: .synth, id: 1, pitch: 60, vel: 1))
        _ = kernel.renderBuffer(64)
        kernel.events.push(.param(.gen1Tune, 11))
        kernel.events.push(.param(.gen2Tune, -7))
        _ = kernel.renderBuffer(64)

        let voice = kernel.voices.first { $0.active && $0.id == 1 }!
        #expect(abs(voice.detune[0] - 11) < 0.001)
        #expect(abs(voice.detune[1] + 7) < 0.001)
        #expect(abs(voice.detune[2] - 24.6) < 0.001)
        #expect(abs(voice.detune[3] + 2.6) < 0.001)
    }

    @Test func pressureOpensFilter() {
        let kernel = SynthKernel(sampleRate: SR)
        kernel.events.push(.param(.filterCutoff, 0.3))
        kernel.events.push(.param(.filterEnv, 0.5))
        kernel.events.push(.noteOn(dest: .synth, id: 1, pitch: 60, vel: 0.9))
        _ = kernel.renderBuffer(4800)
        let before = kernel.voices.first { $0.active }!.cutoffSm.value
        kernel.events.push(.pressure(dest: .synth, id: 1, value: 1))
        _ = kernel.renderBuffer(9600)
        let after = kernel.voices.first { $0.active }!.cutoffSm.value
        #expect(after > before * 2)
    }

    @Test func allParamsAcceptedWithoutNaN() {
        let kernel = SynthKernel(sampleRate: SR)
        let ids: [ParamID] = [
            .gen1Semi, .gen1Tune, .gen1Level, .gen2Semi, .gen2Tune, .gen2Level,
            .envA, .envD, .envS, .envR, .filterCutoff, .filterRes, .filterEnv,
            .lfoRate, .lfoDepth, .lfoTargetFilter, .synthLevel,
            .reverbFdbk, .reverbMix, .reverbOn, .delayTime, .delayFdbk, .delayMix, .delayOn,
            .distortAmt, .distortOn, .fattenAmt, .fattenOn,
            .samplerLevel, .samplerAttack, .samplerRelease, .samplerRetrig, .slide,
        ]
        for v in [Float(0), 1] {
            for pid in ids { kernel.events.push(.param(pid, v)) }
            kernel.events.push(.noteOn(dest: .synth, id: 1, pitch: 60, vel: 0.9))
            let (l, r) = kernel.renderBuffer(4800)
            #expect(allFinite(l), "params=\(v) L")
            #expect(allFinite(r), "params=\(v) R")
            kernel.events.push(.allOff(dest: .synth))
            _ = kernel.renderBuffer(4800)
        }
    }

    @Test func fxChainAudibleAndTailsRing() {
        let kernel = SynthKernel(sampleRate: SR)
        kernel.events.push(.param(.distortOn, 1))
        kernel.events.push(.param(.distortAmt, 0.8))
        kernel.events.push(.param(.delayOn, 1))
        kernel.events.push(.param(.delayMix, 0.5))
        kernel.events.push(.param(.delayTime, 0.1))
        kernel.events.push(.noteOn(dest: .synth, id: 1, pitch: 60, vel: 1))
        let (l, _) = kernel.renderBuffer(9600)
        #expect(allFinite(l))
        #expect(rms(l[4800...]) > 0.005)
        // Kill the note; the delay + reverb tail should keep ringing for a bit.
        kernel.events.push(.noteOff(dest: .synth, id: 1))
        _ = kernel.renderBuffer(Int(SR * 0.8)) // past release hard-stop
        let (echo, _) = kernel.renderBuffer(4800)
        #expect(rms(echo[0...]) > 1e-5)
    }

    @Test func allOffIsImmediateAndClearsSharedFxWhenIdle() {
        let kernel = SynthKernel(sampleRate: SR)
        kernel.events.push(.param(.delayOn, 1))
        kernel.events.push(.param(.delayMix, 0.8))
        kernel.events.push(.param(.delayTime, 0.03))
        kernel.events.push(.param(.reverbOn, 1))
        kernel.events.push(.param(.reverbMix, 0.8))
        kernel.events.push(.noteOn(dest: .synth, id: 1, pitch: 60, vel: 1))
        let (before, _) = kernel.renderBuffer(4800)
        #expect(rms(before[2400...]) > 0.005)

        kernel.events.push(.allOff(dest: .synth))
        let (afterL, afterR) = kernel.renderBuffer(4800)
        #expect(kernel.voiceCount == 0)
        #expect(rms(afterL[0...]) < 1e-6)
        #expect(rms(afterR[0...]) < 1e-6)
    }

    @Test func wavetableSwapKeepsRunning() {
        let kernel = SynthKernel(sampleRate: SR)
        let pool = WavetablePool()
        kernel.events.push(.noteOn(dest: .synth, id: 1, pitch: 60, vel: 0.9))
        _ = kernel.renderBuffer(2400)
        kernel.events.push(.wavetable(gen: 0, publication: pool.build(morph: 1.0, bright: 0.9)!))
        kernel.events.push(.wavetable(gen: 1, publication: pool.build(morph: 0.5, bright: 0.9)!))
        let (l, _) = kernel.renderBuffer(4800)
        #expect(allFinite(l))
        #expect(rms(l[0...]) > 0.005)
    }

    @Test func pitchesAboveNyquistStayFiniteAndInBounds() {
        let kernel = SynthKernel(sampleRate: SR)
        kernel.events.push(.param(.gen1Semi, 24))
        kernel.events.push(.param(.gen2Semi, 24))
        kernel.events.push(.noteOn(dest: .synth, id: 1, pitch: 180, vel: 1))
        let (l, r) = kernel.renderBuffer(48_000)
        #expect(allFinite(l))
        #expect(allFinite(r))
        #expect(rms(l[0...]) < 1e-6)
    }

    @Test func stereoReverbDecorrelates() {
        let kernel = SynthKernel(sampleRate: SR)
        kernel.events.push(.param(.reverbOn, 1))
        kernel.events.push(.param(.reverbMix, 0.6))
        kernel.events.push(.noteOn(dest: .synth, id: 1, pitch: 72, vel: 1))
        let (l, r) = kernel.renderBuffer(48000)
        var differs = false
        for i in 24000..<48000 where abs(l[i] - r[i]) > 1e-4 {
            differs = true
            break
        }
        #expect(differs)
    }

    @Test func envelopeFollowsAdsrShape() {
        let kernel = SynthKernel(sampleRate: SR)
        // Slow attack so the ramp is observable; full sustain.
        kernel.events.push(.param(.envA, 0.2))
        kernel.events.push(.param(.envS, 1.0))
        kernel.events.push(.param(.reverbOn, 0)) // dry only for level reads
        kernel.events.push(.param(.fattenOn, 0))
        kernel.events.push(.noteOn(dest: .synth, id: 1, pitch: 60, vel: 1))
        let (first, _) = kernel.renderBuffer(4800) // first 100 ms of a 200 ms attack
        let (second, _) = kernel.renderBuffer(4800) // second 100 ms
        #expect(rms(second[0...]) > rms(first[0...]) * 1.5) // still ramping up
    }
}

struct SamplerKernelTests {
    func makeKernelWithSample(_ preset: String = "E-Piano") -> SynthKernel {
        let kernel = SynthKernel(sampleRate: SR)
        let registry = SampleRegistry(ring: kernel.events, sampleRate: SR)
        registry.select(preset: preset, userRoot: 60)
        return kernel
    }

    @Test func samplerNoteProducesSound() {
        let kernel = makeKernelWithSample()
        kernel.events.push(.noteOn(dest: .sampler, id: 1, pitch: 60, vel: 0.9))
        let (l, _) = kernel.renderBuffer(9600)
        #expect(allFinite(l))
        #expect(rms(l[2400...]) > 0.005)
    }

    @Test func samplerLevelIsIndependentFromSynthLevel() {
        let kernel = makeKernelWithSample()
        kernel.events.push(.param(.synthLevel, 0))
        kernel.events.push(.noteOn(dest: .sampler, id: 1, pitch: 60, vel: 0.9))
        let (l, _) = kernel.renderBuffer(9600)
        #expect(rms(l[2400...]) > 0.005)
    }

    @Test func samplerNoteOffReleases() {
        let kernel = makeKernelWithSample("English Horn") // looping — sustains forever
        kernel.events.push(.noteOn(dest: .sampler, id: 1, pitch: 57, vel: 0.9))
        _ = kernel.renderBuffer(9600)
        kernel.events.push(.noteOff(dest: .sampler, id: 1))
        var last: [Float] = []
        for _ in 0..<40 {
            (last, _) = kernel.renderBuffer(4800)
        }
        #expect(rms(last[0...]) < 1e-4)
    }

    @Test func sameDrainSamplerTapStillProducesAnOnset() {
        let kernel = makeKernelWithSample()
        kernel.events.push(.param(.reverbOn, 0))
        kernel.events.push(.noteOn(dest: .sampler, id: 1, pitch: 60, vel: 1))
        kernel.events.push(.noteOff(dest: .sampler, id: 1))
        let (left, _) = kernel.renderBuffer(240)
        #expect(rms(left[0...]) > 1e-5)
    }

    @Test func slotPressureReclaimsAReleasedTailBeforeAHeldSamplerVoice() {
        let kernel = makeKernelWithSample("English Horn")
        kernel.events.push(.noteOn(dest: .sampler, id: 1, pitch: 48, vel: 0.7))
        _ = kernel.renderBuffer(240)

        for id: Int32 in 2...16 {
            kernel.events.push(.noteOn(dest: .sampler, id: id, pitch: 72, vel: 1))
            _ = kernel.renderBuffer(64)
            kernel.events.push(.noteOff(dest: .sampler, id: id))
            _ = kernel.renderBuffer(64)
        }
        kernel.events.push(.noteOn(dest: .sampler, id: 17, pitch: 76, vel: 1))
        _ = kernel.renderBuffer(32)

        #expect(kernel.findSampler(1) != nil)
        _ = kernel.renderBuffer(64)
        #expect(kernel.findSampler(17) != nil)
    }

    @Test func loopingSampleSustains() {
        let kernel = makeKernelWithSample("Choir")
        kernel.events.push(.noteOn(dest: .sampler, id: 1, pitch: 57, vel: 0.9))
        _ = kernel.renderBuffer(Int(SR * 2)) // past the 1 s loop window
        let (l, _) = kernel.renderBuffer(4800)
        #expect(allFinite(l))
        #expect(rms(l[0...]) > 0.005)
    }

    @Test func oneShotEnds() {
        let kernel = makeKernelWithSample("Marimba") // 1.8 s one-shot
        kernel.events.push(.noteOn(dest: .sampler, id: 1, pitch: 69, vel: 0.9))
        _ = kernel.renderBuffer(Int(SR * 2.5))
        var active = 0
        for v in kernel.sVoices where v.active { active += 1 }
        #expect(active == 0)
    }

    @Test func pitchShiftChangesRate() {
        let kernel = makeKernelWithSample("E-Piano")
        kernel.events.push(.noteOn(dest: .sampler, id: 1, pitch: 72, vel: 0.9)) // +12 semis
        _ = kernel.renderBuffer(4800)
        let v = kernel.sVoices.first { $0.active }!
        // One octave up reads twice as fast: 0.1 s → ~9600 frames.
        #expect(abs(v.pos - 9600) < 200)
    }

    @Test func retrigRestartsOnSemitoneCross() {
        let kernel = makeKernelWithSample("E-Piano")
        kernel.events.push(.param(.samplerRetrig, 1))
        kernel.events.push(.noteOn(dest: .sampler, id: 1, pitch: 60, vel: 0.9))
        _ = kernel.renderBuffer(9600)
        kernel.events.push(.glide(dest: .sampler, id: 1, pitch: 62))
        _ = kernel.renderBuffer(480)
        // The new voice restarted near pos 0; the old one is fading.
        let fresh = kernel.sVoices.filter { $0.active && $0.id == 1 }
        #expect(fresh.count == 1)
        #expect(fresh.first!.pos < 2000)
    }

    @Test func userSampleSelection() throws {
        let kernel = SynthKernel(sampleRate: SR)
        let registry = SampleRegistry(ring: kernel.events, sampleRate: SR)
        // A 440 Hz beep as the "user file."
        let beep = (0..<Int(SR)).map { Float(sin(Double($0) * 2 * .pi * 440 / SR)) * 0.8 }
        try registry.setUserSample(beep, name: "beep.wav")
        #expect(registry.userSampleName == "beep.wav")
        registry.select(preset: USER_PRESET, userRoot: 69)
        kernel.events.push(.noteOn(dest: .sampler, id: 1, pitch: 69, vel: 1))
        let (l, _) = kernel.renderBuffer(9600)
        #expect(rms(l[2400...]) > 0.01)
    }

    @Test func userSampleRejectsEmptyAndOversizedBuffers() {
        let kernel = SynthKernel(sampleRate: SR)
        let registry = SampleRegistry(ring: kernel.events, sampleRate: SR)
        #expect(throws: SampleRegistry.RegistryError.self) {
            try registry.setUserSample([], name: "empty.wav")
        }
        #expect(throws: SampleRegistry.RegistryError.self) {
            try registry.setUserSample(
                [Float](repeating: 0, count: Int(SR * 30) + 1),
                name: "too-long.wav"
            )
        }
    }
}

struct BridgeTests {
    @Test func bridgeSyncsStoreToKernel() {
        let store = Store()
        let kernel = SynthKernel(sampleRate: SR)
        let bridge = StoreKernelBridge(store: store, ring: kernel.events, sampleRate: SR)
        _ = bridge
        _ = kernel.renderBuffer(64) // drain initial sync
        #expect(abs(kernel.params.synthLevel - Float(store.state.synth.level)) < 1e-6)
        #expect(kernel.params.reverbOn == 1)

        store.set(\.synth.level, 0.5)
        store.set(\.fx.reverb.on, false)
        store.set(\.synth.gen1.semi, 7)
        _ = kernel.renderBuffer(64)
        #expect(abs(kernel.params.synthLevel - 0.5) < 1e-6)
        #expect(kernel.params.reverbOn == 0)
        #expect(kernel.params.gen1Semi == 7)
    }

    @Test func morphChangeSwapsWavetables() {
        let store = Store()
        let kernel = SynthKernel(sampleRate: SR)
        let bridge = StoreKernelBridge(store: store, ring: kernel.events, sampleRate: SR)
        _ = bridge
        _ = kernel.renderBuffer(64)
        let before = kernel.table1
        store.set(\.synth.gen1.morph, 0.9)
        _ = kernel.renderBuffer(64)
        #expect(kernel.table1 != before)
    }

    @Test func samplerPresetSelectionThroughBridge() {
        let store = Store()
        let kernel = SynthKernel(sampleRate: SR)
        let bridge = StoreKernelBridge(store: store, ring: kernel.events, sampleRate: SR)
        _ = bridge
        _ = kernel.renderBuffer(64)
        #expect(kernel.currentSample.data != nil) // default preset E-Piano loaded
        store.set(\.sampler.preset, "Pluck")
        _ = kernel.renderBuffer(64)
        #expect(kernel.currentSample.loopStart == -1) // pluck is one-shot
    }
}
