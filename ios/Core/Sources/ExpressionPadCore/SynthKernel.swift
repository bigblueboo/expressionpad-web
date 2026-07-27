/// SynthKernel — the entire instrument rendered in one real-time callback:
/// polyphonic wavetable synth + sampler voices → distortion → delay → reverb
/// → limiter, matching ../src/audio/engine.ts & sampler.ts node for
/// node. Everything is preallocated; the only communication with the outside
/// world is the lock-free EventRing and the output buffers.
///
/// Web Audio parity notes:
/// - setTargetAtTime(v, tau) → OnePole stepped per 32-sample block.
/// - Envelopes: linear attack to peak, one-pole decay to peak·sustain
///   (tau = d/3), one-pole release (tau = r/3), hard stop at r·2+0.1 s.
/// - SEMI and TUNE updates retune running voices, including both generator-one
///   fatten layers, matching engine.ts's retuneVoice behavior.
import Foundation

struct KernelParams {
    var gen1Semi: Float = 0, gen1Tune: Float = 0, gen1Level: Float = 0.8
    var gen2Semi: Float = 12, gen2Tune: Float = 4, gen2Level: Float = 0.25
    var envA: Float = 0.01, envD: Float = 0.25, envS: Float = 0.7, envR: Float = 0.3
    var filterCutoff: Float = 0.75, filterRes: Float = 0.15, filterEnv: Float = 0.3
    var lfoRate: Float = 5, lfoDepth: Float = 0.1, lfoTargetFilter: Float = 0
    var synthLevel: Float = 0.78
    var reverbFdbk: Float = 0.5, reverbMix: Float = 0.3, reverbOn: Float = 1
    var delayTime: Float = 0.34, delayFdbk: Float = 0.35, delayMix: Float = 0.2, delayOn: Float = 0
    var distortAmt: Float = 0.3, distortOn: Float = 0
    var fattenAmt: Float = 0.4, fattenOn: Float = 1
    var samplerLevel: Float = 0.8, samplerAttack: Float = 0.005, samplerRelease: Float = 0.35
    var samplerRetrig: Float = 0
    var slide: Float = 0.35
    var pressureRoute: KernelPressureRoute = .filter
    var tiltRoute: KernelTiltRoute = .off
    var exprTiltAmount: Float = 0.5
    var tilt: Float = 0
}

private let ENV_ATTACK: Int32 = 1
private let ENV_SUSTAIN: Int32 = 2
private let ENV_RELEASED: Int32 = 3
private let ENV_RETRIG_FADE: Int32 = 4
private let ENV_STEAL_FADE: Int32 = 5
private let MIN_ONSET_SAMPLES = 64
private let STEAL_FADE_SAMPLES = 64

fileprivate struct PendingSynthStart {
    var id: Int32
    var pitch: Float
    var vel: Float
    var order: Int
}

fileprivate struct PendingSamplerStart {
    var id: Int32
    var pitch: Float
    var vel: Float
    var order: Int
    var sample: SampleRef
}

final class SynthVoice {
    var active = false
    var id: Int32 = -1
    var order = 0
    var pitch: Float = 60
    var vel: Float = 0.8
    var pressure: Float = 0
    var released = false
    var oscCount = 2
    var phase = [Float](repeating: 0, count: 4)
    var freqCur = [Float](repeating: 0, count: 4)
    var freqTgt = [Float](repeating: 0, count: 4)
    var detune = [Float](repeating: 0, count: 4) // generator tune + layer spread, cents
    var layerDetune = [Float](repeating: 0, count: 4)
    var oscGen = [Int](repeating: 0, count: 4)
    var oscScale = [Float](repeating: 0, count: 4)
    var g1 = OnePole(0)
    var g2 = OnePole(0)
    var filter = Biquad()
    var cutoffSm = OnePole(1000) // Hz
    var qSm = OnePole(0) // dB
    /// Expression gain after the envelope — pressure→level swells ride here.
    var expSm = OnePole(1)
    /// Per-voice scaler on the shared LFO — pressure→lfo rides here.
    var lfoAmtSm = OnePole(1)
    var env: Float = 0
    var envStage: Int32 = 0
    var envPeak: Float = 0
    var envSustain: Float = 0
    var attackStep: Float = 0
    var decayAlpha: Float = 0
    var releaseAlpha: Float = 0
    var killSamples = 0
    var renderedSamples = 0
    var pendingRelease = false
    var stealStep: Float = 0
    fileprivate var pendingStart: PendingSynthStart?
}

final class SamplerVoice {
    var active = false
    var id: Int32 = -1
    var order = 0
    var sample = SampleRef.none
    var pitch: Float = 60
    var vel: Float = 0.8
    var pressure: Float = 0
    /// Expression gain after the envelope — the pressure axis rides here.
    var expSm = OnePole(1)
    var pos: Double = 0
    var centsSm = OnePole(0)
    var gain: Float = 0
    var stage: Int32 = 0
    var peak: Float = 0
    var attackStep: Float = 0
    var releaseAlpha: Float = 0
    var filter = Biquad()
    var cutoffSm = OnePole(0)
    var killSamples = 0
    var renderedSamples = 0
    var pendingRelease = false
    var stealStep: Float = 0
    fileprivate var pendingStart: PendingSamplerStart?
}

public final class SynthKernel {
    public static let maxVoices = 10 // playing cap, matching MAX_VOICES
    static let voiceSlots = 24 // playing + release tails
    static let samplerSlots = 16
    static let blockSize = 32

    public let sampleRate: Double
    let sr: Float
    public let events: EventRing

    var params = KernelParams()
    var voices: [SynthVoice] = []
    var sVoices: [SamplerVoice] = []
    var orderCounter = 0

    // Wavetables: pointers into pool slabs owned by the main thread (or the
    // kernel's own default slabs from init).
    var table1: UnsafePointer<Float>
    var table2: UnsafePointer<Float>
    var tablePublication1: WavetablePublication?
    var tablePublication2: WavetablePublication?
    private let defaultTables: UnsafeMutablePointer<Float>

    var currentSample = SampleRef.none

    // Modulation & mix smoothers.
    var lfoPhase: Float = 0
    var lfoFreqSm = OnePole(5)
    var lfoPitchGainSm = OnePole(0)
    var lfoFilterGainSm = OnePole(0)
    var synthOut = OnePole(0.78)
    var samplerOut = OnePole(0.8)
    var busOut = OnePole(1)

    // FX
    var dist = Distortion()
    var delay: FeedbackDelay
    var reverb: FDNReverb
    var limiter: Limiter

    // Scratch (blockSize / per-voice, preallocated — the render path never allocates)
    var bus: [Float]
    var phaseIncScratch = [Float](repeating: 0, count: 4)
    var levelScratch = [Int](repeating: 0, count: 4)
    var audibleScratch = [Bool](repeating: false, count: 4)

    public init(sampleRate: Double) {
        self.sampleRate = sampleRate
        sr = Float(sampleRate)
        events = EventRing()
        delay = FeedbackDelay(maxSeconds: 2, sampleRate: sr)
        reverb = FDNReverb(sampleRate: sr)
        limiter = Limiter(sampleRate: sr)
        bus = [Float](repeating: 0, count: SynthKernel.blockSize)
        for _ in 0..<SynthKernel.voiceSlots { voices.append(SynthVoice()) }
        for _ in 0..<SynthKernel.samplerSlots { sVoices.append(SamplerVoice()) }
        defaultTables = .allocate(capacity: Wavetable.totalSize * 2)
        Wavetable.build(morph: 0.1, bright: 0.5, into: defaultTables)
        Wavetable.build(morph: 0.3, bright: 0.5, into: defaultTables + Wavetable.totalSize)
        table1 = UnsafePointer(defaultTables)
        table2 = UnsafePointer(defaultTables + Wavetable.totalSize)
    }

    deinit {
        defaultTables.deallocate()
    }

    /// Active synth+sampler voice count (diagnostic; audio thread writes,
    /// UI reads — benign race).
    public private(set) var voiceCount = 0

    // ---------------------------------------------------------- events ---

    func drainEvents() {
        // Capture overflow fallbacks first, but apply them after the queued
        // events that preceded the dropped terminal event. Otherwise a queued
        // note-on could run after the panic and recreate the stuck note.
        let emergencySynthOff = events.takeEmergencyAllOff(.synth)
        let emergencySamplerOff = events.takeEmergencyAllOff(.sampler)
        while let e = events.pop() {
            switch e {
            case let .noteOn(dest, id, pitch, vel):
                if dest == .synth { synthNoteOn(id, pitch, vel) } else { samplerNoteOn(id, pitch, vel) }
            case let .glide(dest, id, pitch):
                if dest == .synth { synthGlide(id, pitch) } else { samplerGlide(id, pitch) }
            case let .pressure(dest, id, value):
                if dest == .synth {
                    if let v = findSynth(id) { v.pressure = clamp(value, 0, 1) }
                } else {
                    if let v = findSampler(id) { v.pressure = clamp(value, 0, 1) }
                }
            case let .noteOff(dest, id):
                if dest == .synth { synthNoteOff(id) } else { samplerNoteOff(id) }
            case let .allOff(dest):
                hardAllOff(dest)
            case let .param(pid, value):
                applyParam(pid, value)
            case let .wavetable(gen, publication):
                if gen == 0 {
                    tablePublication1?.retire()
                    table1 = publication.table
                    tablePublication1 = publication
                } else {
                    tablePublication2?.retire()
                    table2 = publication.table
                    tablePublication2 = publication
                }
                publication.markCurrent()
            case let .sample(ref):
                currentSample = ref
            }
        }
        if emergencySynthOff { hardAllOff(.synth) }
        if emergencySamplerOff { hardAllOff(.sampler) }
    }

    /// Panic is intentionally immediate. Normal note-offs keep their release
    /// envelope; all-off is used for app suspension, MIDI disconnects, and
    /// recovery from a saturated event queue, where silence must be certain.
    func hardAllOff(_ dest: KernelDest) {
        if dest == .synth {
            for v in voices {
                v.active = false
                v.id = -1
                v.pendingStart = nil
                v.pendingRelease = false
            }
        } else {
            for v in sVoices {
                v.active = false
                v.id = -1
                v.pendingStart = nil
                v.pendingRelease = false
            }
        }

        // The FX are shared, so clear their history only after every source is
        // idle. Consecutive synth/sampler panic events reach this condition on
        // the second event without cutting off an unrelated active source.
        if !voices.contains(where: \.active) && !sVoices.contains(where: \.active) {
            dist.reset()
            delay.reset()
            reverb.reset()
            limiter.reset()
            bus.withUnsafeMutableBufferPointer { $0.initialize(repeating: 0) }
        }
    }

    func applyParam(_ pid: ParamID, _ v: Float) {
        switch pid {
        case .gen1Semi:
            if params.gen1Semi != v {
                params.gen1Semi = v
                retuneVoices()
            }
        case .gen2Semi:
            if params.gen2Semi != v {
                params.gen2Semi = v
                retuneVoices()
            }
        case .gen1Tune:
            params.gen1Tune = v
            retuneDetunes(generator: 0)
        case .gen1Level: params.gen1Level = v
        case .gen2Tune:
            params.gen2Tune = v
            retuneDetunes(generator: 1)
        case .gen2Level: params.gen2Level = v
        case .envA: params.envA = v
        case .envD: params.envD = v
        case .envS: params.envS = v
        case .envR: params.envR = v
        case .filterCutoff: params.filterCutoff = v
        case .filterRes: params.filterRes = v
        case .filterEnv: params.filterEnv = v
        case .lfoRate: params.lfoRate = v
        case .lfoDepth: params.lfoDepth = v
        case .lfoTargetFilter: params.lfoTargetFilter = v
        case .synthLevel: params.synthLevel = v
        case .reverbFdbk: params.reverbFdbk = v
        case .reverbMix: params.reverbMix = v
        case .reverbOn: params.reverbOn = v
        case .delayTime: params.delayTime = v
        case .delayFdbk: params.delayFdbk = v
        case .delayMix: params.delayMix = v
        case .delayOn: params.delayOn = v
        case .distortAmt: params.distortAmt = v
        case .distortOn: params.distortOn = v
        case .fattenAmt: params.fattenAmt = v
        case .fattenOn: params.fattenOn = v
        case .samplerLevel: params.samplerLevel = v
        case .samplerAttack: params.samplerAttack = v
        case .samplerRelease: params.samplerRelease = v
        case .samplerRetrig: params.samplerRetrig = v
        case .slide: params.slide = v
        case .exprPressure: params.pressureRoute = KernelPressureRoute(payload: v)
        case .exprTilt: params.tiltRoute = KernelTiltRoute(payload: v)
        case .exprTiltAmount: params.exprTiltAmount = v
        case .tilt: params.tilt = clamp(v, 0, 1)
        }
    }

    func retuneVoices() {
        for v in voices where v.active {
            for k in 0..<v.oscCount {
                let semi = v.oscGen[k] == 0 ? params.gen1Semi : params.gen2Semi
                v.freqTgt[k] = Float(midiToFreq(Double(v.pitch + semi)))
            }
        }
    }

    func retuneDetunes(generator: Int) {
        let tune = generator == 0 ? params.gen1Tune : params.gen2Tune
        for v in voices where v.active {
            for k in 0..<v.oscCount where v.oscGen[k] == generator {
                v.detune[k] = tune + v.layerDetune[k]
            }
        }
    }

    // ------------------------------------------------------ synth voices ---

    func findSynth(_ id: Int32) -> SynthVoice? {
        for v in voices where v.active && !v.released && v.id == id { return v }
        return nil
    }

    func synthNoteOn(_ id: Int32, _ pitch: Float, _ vel: Float) {
        if let existing = findSynth(id) { beginSynthRelease(existing) }
        // Voice stealing: release the oldest playing voice past the cap.
        // (Manual scans — no allocating filter/min on the audio thread.)
        var playingCount = 0
        var oldestPlaying: SynthVoice?
        var freeSlot: SynthVoice?
        var quietestReleased: SynthVoice?
        for v in voices {
            if v.active && !v.released {
                playingCount += 1
                if oldestPlaying == nil || v.order < oldestPlaying!.order { oldestPlaying = v }
            }
            if !v.active && freeSlot == nil { freeSlot = v }
            if v.active, v.released, v.pendingStart == nil,
               quietestReleased == nil || v.env < quietestReleased!.env {
                quietestReleased = v
            }
        }
        var newlyReleased: SynthVoice?
        if playingCount >= SynthKernel.maxVoices, let oldest = oldestPlaying {
            beginSynthRelease(oldest)
            newlyReleased = oldest
        }

        orderCounter += 1
        let start = PendingSynthStart(id: id, pitch: pitch, vel: vel, order: orderCounter)
        if let freeSlot {
            startSynthVoice(freeSlot, start)
        } else if let victim = quietestReleased ?? newlyReleased {
            scheduleSynthStart(start, replacing: victim)
        }
    }

    private func startSynthVoice(_ v: SynthVoice, _ start: PendingSynthStart) {
        v.active = true
        v.released = false
        v.id = start.id
        v.order = start.order
        v.pitch = start.pitch
        v.vel = start.vel
        v.pressure = 0
        v.renderedSamples = 0
        v.pendingRelease = false
        v.pendingStart = nil
        v.stealStep = 0

        let fatten = params.fattenOn > 0.5
        let spread = lerp(4, 28, params.fattenAmt)
        v.oscCount = fatten ? 4 : 2
        for k in 0..<v.oscCount {
            // Layers: gen1, gen2, then two detuned gen1 copies when fattened.
            let gen = k == 1 ? 1 : 0
            let layerDet: Float = k == 2 ? spread : (k == 3 ? -spread : 0)
            let layerScale: Float = k >= 2 ? 0.45 : 1
            let semi = gen == 0 ? params.gen1Semi : params.gen2Semi
            let tune = gen == 0 ? params.gen1Tune : params.gen2Tune
            let f = Float(midiToFreq(Double(start.pitch + semi)))
            v.phase[k] = 0
            v.freqCur[k] = f
            v.freqTgt[k] = f
            v.layerDetune[k] = layerDet
            v.detune[k] = tune + layerDet
            v.oscGen[k] = gen
            v.oscScale[k] = layerScale
        }
        v.g1.snap(params.gen1Level)
        v.g2.snap(params.gen2Level)
        v.filter.reset()
        let mod = pressureModulation(params.pressureRoute, v.pressure, .synth)
        v.cutoffSm.snap(Float(cutoffToHz(Double(synthCutoffNorm(mod)))))
        v.qSm.snap(params.filterRes * 18)
        v.expSm.snap(mod.level)
        v.lfoAmtSm.snap(mod.lfo)

        v.envPeak = Float(velocityToGain(Double(start.vel)))
        v.env = 0
        v.envStage = ENV_ATTACK
        let a = max(0.001, params.envA)
        v.attackStep = v.envPeak / (a * sr)
        v.envSustain = v.envPeak * params.envS
        let dTau = max(0.01, params.envD) / 3
        v.decayAlpha = 1 - exp(-1 / (dTau * sr))
    }

    private func scheduleSynthStart(_ start: PendingSynthStart, replacing v: SynthVoice) {
        // A released tail can still be far above zero. Fade it over a bounded
        // 64-sample window, then reuse the same preallocated slot. This avoids
        // turning slot pressure into a buffer-boundary amplitude step.
        v.released = true
        v.id = -1
        v.pendingRelease = false
        v.pendingStart = start
        v.envStage = ENV_STEAL_FADE
        v.killSamples = STEAL_FADE_SAMPLES
        v.stealStep = max(0, v.env) / Float(STEAL_FADE_SAMPLES)
    }

    func synthGlide(_ id: Int32, _ pitch: Float) {
        guard let v = findSynth(id) else { return }
        v.pitch = pitch
        for k in 0..<v.oscCount {
            let semi = v.oscGen[k] == 0 ? params.gen1Semi : params.gen2Semi
            v.freqTgt[k] = Float(midiToFreq(Double(pitch + semi)))
        }
    }

    func beginSynthRelease(_ v: SynthVoice) {
        let r = max(0.02, params.envR)
        v.released = true
        v.pendingRelease = false
        v.envStage = ENV_RELEASED
        v.releaseAlpha = 1 - exp(-1 / (r / 3 * sr))
        v.killSamples = Int((r * 2 + 0.1) * sr)
    }

    func synthNoteOff(_ id: Int32) {
        guard let v = findSynth(id) else { return }
        if v.renderedSamples < MIN_ONSET_SAMPLES {
            v.pendingRelease = true
        } else {
            beginSynthRelease(v)
        }
    }

    // ---------------------------------------------------- sampler voices ---

    func findSampler(_ id: Int32) -> SamplerVoice? {
        for v in sVoices where v.active && v.stage != ENV_RELEASED && v.stage != ENV_RETRIG_FADE && v.id == id {
            return v
        }
        return nil
    }

    func samplerNoteOn(_ id: Int32, _ pitch: Float, _ vel: Float) {
        let sample = currentSample
        guard sample.data != nil else { return }
        if let existing = findSampler(id) { beginSamplerRelease(existing) }
        var freeSlot: SamplerVoice?
        var quietestTail: SamplerVoice?
        var oldestPlaying: SamplerVoice?
        for v in sVoices {
            if !v.active && freeSlot == nil { freeSlot = v }
            if v.active, v.pendingStart == nil,
               v.stage == ENV_RELEASED || v.stage == ENV_RETRIG_FADE || v.stage == ENV_STEAL_FADE {
                if quietestTail == nil || v.gain < quietestTail!.gain { quietestTail = v }
            } else if v.active, v.pendingStart == nil,
                      oldestPlaying == nil || v.order < oldestPlaying!.order {
                oldestPlaying = v
            }
        }

        orderCounter += 1
        let start = PendingSamplerStart(
            id: id, pitch: pitch, vel: vel, order: orderCounter, sample: sample
        )
        if let freeSlot {
            startSamplerVoice(freeSlot, start)
        } else if let victim = quietestTail ?? oldestPlaying {
            scheduleSamplerStart(start, replacing: victim)
        }
    }

    private func startSamplerVoice(_ v: SamplerVoice, _ start: PendingSamplerStart) {
        v.active = true
        v.id = start.id
        v.order = start.order
        v.sample = start.sample
        v.pitch = start.pitch
        v.vel = start.vel
        v.pressure = 0
        v.pos = 0
        v.centsSm.snap((start.pitch - start.sample.root) * 100)
        // The envelope carries velocity only; the expression smoother after it
        // owns everything the pressure axis does, so route changes stay atomic.
        v.peak = Float(velocityToGain(Double(start.vel)))
        v.expSm.snap(pressureModulation(params.pressureRoute, v.pressure, .sampler).level)
        v.gain = 0
        v.stage = ENV_ATTACK
        let a = max(0.002, params.samplerAttack)
        v.attackStep = v.peak / (a * sr)
        v.filter.reset()
        v.cutoffSm.snap(Float(cutoffToHz(0.8)))
        v.killSamples = 0
        v.renderedSamples = 0
        v.pendingRelease = false
        v.pendingStart = nil
        v.stealStep = 0
    }

    private func scheduleSamplerStart(_ start: PendingSamplerStart, replacing v: SamplerVoice) {
        v.id = -1
        v.pendingRelease = false
        v.pendingStart = start
        v.stage = ENV_STEAL_FADE
        v.killSamples = STEAL_FADE_SAMPLES
        v.stealStep = max(0, v.gain) / Float(STEAL_FADE_SAMPLES)
    }

    func samplerGlide(_ id: Int32, _ pitch: Float) {
        guard let v = findSampler(id) else { return }
        if params.samplerRetrig > 0.5 && pitch.rounded() != v.pitch.rounded() {
            // Restart at the new semitone, like a harp glissando.
            v.stage = ENV_RETRIG_FADE
            v.killSamples = Int(0.05 * sr)
            v.id = -1
            samplerNoteOn(id, pitch.rounded(), v.vel)
            return
        }
        v.pitch = pitch
        v.centsSm.target = (pitch - v.sample.root) * 100
    }

    func beginSamplerRelease(_ v: SamplerVoice) {
        let r = max(0.02, params.samplerRelease)
        v.pendingRelease = false
        v.stage = ENV_RELEASED
        v.releaseAlpha = 1 - exp(-1 / (r / 3 * sr))
        v.killSamples = Int((r * 2 + 0.1) * sr)
    }

    func samplerNoteOff(_ id: Int32) {
        guard let v = findSampler(id) else { return }
        if v.renderedSamples < MIN_ONSET_SAMPLES {
            v.pendingRelease = true
        } else {
            beginSamplerRelease(v)
        }
    }

    // ---------------------------------------------------------- render ---

    public func render(frames: Int, outL: UnsafeMutablePointer<Float>, outR: UnsafeMutablePointer<Float>) {
        var offset = 0
        while offset < frames {
            // Apply control traffic at the next 32-sample boundary instead of
            // making events that arrive during a larger hardware callback wait
            // for the following callback.
            drainEvents()
            let n = min(SynthKernel.blockSize, frames - offset)
            renderBlock(n, outL + offset, outR + offset)
            offset += n
        }
        var count = 0
        for v in voices where v.active { count += 1 }
        for v in sVoices where v.active { count += 1 }
        voiceCount = count
    }

    private func renderBlock(_ n: Int, _ outL: UnsafeMutablePointer<Float>, _ outR: UnsafeMutablePointer<Float>) {
        let dt = Float(n) / sr
        let a02 = smoothingAlpha(dt: dt, tau: 0.02)
        let a015 = smoothingAlpha(dt: dt, tau: 0.015)
        let a03 = smoothingAlpha(dt: dt, tau: 0.03)

        // LFO (block-rate; max 30 Hz vs 1.5 kHz block rate).
        lfoFreqSm.target = clamp(params.lfoRate, 0.05, 30)
        let lfoFreq = lfoFreqSm.step(a02)
        let lfoValue = sin(2 * .pi * lfoPhase)
        lfoPhase += lfoFreq * dt
        if lfoPhase >= 1 { lfoPhase -= floor(lfoPhase) }
        // Tilt (when routed here) adds LFO depth on top of the knob.
        let tiltLfo = params.tiltRoute == .lfo ? params.tilt * params.exprTiltAmount : 0
        let lfoDepth = clamp(params.lfoDepth + tiltLfo, 0, 1)
        lfoPitchGainSm.target = params.lfoTargetFilter < 0.5 ? lfoDepth * 60 : 0
        lfoFilterGainSm.target = params.lfoTargetFilter >= 0.5 ? lfoDepth * 2400 : 0
        let lfoPitchCents = lfoValue * lfoPitchGainSm.step(a02)
        let lfoFilterCents = lfoValue * lfoFilterGainSm.step(a02)

        for i in 0..<n { bus[i] = 0 }

        // ----- synth voices
        synthOut.target = params.synthLevel
        let synthGain = synthOut.step(a02)
        let glideTau = lerp(0.004, 0.06, params.slide)
        let glideAlpha = smoothingAlpha(dt: dt, tau: glideTau)
        for v in voices where v.active {
            renderSynthVoice(v, n, glideAlpha: glideAlpha, a02: a02, a015: a015, a03: a03,
                             lfoPitchCents: lfoPitchCents, lfoFilterCents: lfoFilterCents,
                             outGain: synthGain)
        }

        // ----- sampler voices
        samplerOut.target = params.samplerLevel
        let sampGain = samplerOut.step(a02)
        for v in sVoices where v.active {
            renderSamplerVoice(v, n, glideAlpha: glideAlpha, a015: a015, a03: a03, outGain: sampGain)
        }

        // ----- FX chain: dist → delay → reverb → limiter
        dist.update(dt: dt, amt: params.distortAmt, on: params.distortOn > 0.5)
        delay.update(dt: dt, time: params.delayTime, fdbk: params.delayFdbk,
                     wet: params.delayOn > 0.5 ? params.delayMix : 0)
        reverb.update(dt: dt, fdbk: params.reverbFdbk,
                      wet: params.reverbOn > 0.5 ? params.reverbMix : 0)
        // Tilt→level rides the shared bus pre-FX, like the web voiceBus.
        busOut.target = params.tiltRoute == .level
            ? lerp(1 - params.exprTiltAmount, 1, params.tilt)
            : 1
        let busGain = busOut.step(a03)
        var rv: (l: Float, r: Float) = (0, 0)
        let rvWet = reverb.wetGain
        for i in 0..<n {
            let delayed = delay.process(dist.process(bus[i] * busGain))
            reverb.process(delayed, into: &rv)
            var l = delayed + rv.l * rvWet
            var r = delayed + rv.r * rvWet
            limiter.process(l: &l, r: &r)
            outL[i] = l
            outR[i] = r
        }
    }

    /// Normalized synth cutoff: base + pressure push (through the envelope
    /// amount) + tilt brightening when those axes are routed to the filter.
    private func synthCutoffNorm(_ mod: PressureModulation) -> Float {
        let tilt = params.tiltRoute == .filter ? params.tilt * params.exprTiltAmount : 0
        return clamp(params.filterCutoff + params.filterEnv * mod.filter + tilt, 0, 1)
    }

    private func renderSynthVoice(
        _ v: SynthVoice, _ n: Int, glideAlpha: Float, a02: Float, a015: Float, a03: Float,
        lfoPitchCents: Float, lfoFilterCents: Float, outGain: Float
    ) {
        // Per-block modulation & coefficient updates.
        v.g1.target = params.gen1Level
        v.g2.target = params.gen2Level
        let g1 = v.g1.step(a02)
        let g2 = v.g2.step(a02)

        // Expression routing: one policy call decides what pressure does.
        let mod = pressureModulation(params.pressureRoute, v.pressure, .synth)
        v.expSm.target = mod.level
        let vOut = outGain * v.expSm.step(a03)
        v.lfoAmtSm.target = mod.lfo
        let lfoAmt = v.lfoAmtSm.step(a03)

        v.cutoffSm.target = Float(cutoffToHz(Double(synthCutoffNorm(mod))))
        v.qSm.target = params.filterRes * 18
        let cutoffHz = v.cutoffSm.step(a015) * exp2(lfoFilterCents * lfoAmt / 1200)
        v.filter.setLowpass(freq: cutoffHz, qDb: v.qSm.step(a02), sampleRate: sr)

        for k in 0..<v.oscCount {
            v.freqCur[k] += (v.freqTgt[k] - v.freqCur[k]) * glideAlpha
            let eff = v.freqCur[k] * exp2((v.detune[k] + lfoPitchCents * lfoAmt) / 1200)
            phaseIncScratch[k] = eff / sr
            levelScratch[k] = Wavetable.level(forFreq: Double(eff), sampleRate: sampleRate)
            audibleScratch[k] = eff > 0 && eff < sr * 0.5
        }

        for i in 0..<n {
            var mix: Float = 0
            for k in 0..<v.oscCount where audibleScratch[k] {
                let table = v.oscGen[k] == 0 ? table1 : table2
                let base = levelScratch[k] * Wavetable.stride
                let x = v.phase[k] * Float(Wavetable.size)
                let ti = Int(x)
                let frac = x - Float(ti)
                let p = table + base + ti
                let sample = p[0] + (p[1] - p[0]) * frac
                mix += sample * v.oscScale[k] * (v.oscGen[k] == 0 ? g1 : g2)
                v.phase[k] += phaseIncScratch[k]
                v.phase[k] -= floor(v.phase[k])
            }
            let filtered = v.filter.process(mix)

            // Envelope per sample.
            switch v.envStage {
            case ENV_ATTACK:
                v.env += v.attackStep
                if v.env >= v.envPeak {
                    v.env = v.envPeak
                    v.envStage = ENV_SUSTAIN
                }
            case ENV_SUSTAIN:
                v.env += (v.envSustain - v.env) * v.decayAlpha
            case ENV_STEAL_FADE:
                v.env = max(0, v.env - v.stealStep)
                v.killSamples -= 1
                bus[i] += filtered * v.env * vOut
                if v.killSamples <= 0 {
                    if let pending = v.pendingStart {
                        startSynthVoice(v, pending)
                    } else {
                        v.active = false
                    }
                    return
                }
                continue
            default: // released
                v.env += (0 - v.env) * v.releaseAlpha
                v.killSamples -= 1
                if v.killSamples <= 0 || v.env < 1e-5 {
                    v.active = false
                    bus[i] += filtered * v.env * vOut
                    return
                }
            }
            bus[i] += filtered * v.env * vOut
            v.renderedSamples += 1
            if v.pendingRelease, v.renderedSamples >= MIN_ONSET_SAMPLES {
                beginSynthRelease(v)
            }
        }
    }

    private func renderSamplerVoice(
        _ v: SamplerVoice, _ n: Int, glideAlpha: Float, a015: Float, a03: Float, outGain: Float
    ) {
        guard let data = v.sample.data else {
            v.active = false
            return
        }
        let count = Int(v.sample.count)
        let loop = v.sample.loopStart >= 0
        let loopStart = Double(v.sample.loopStart)
        let loopEnd = Double(v.sample.loopEnd)

        let cents = v.centsSm.step(glideAlpha)
        let rate = Double(exp2(cents / 1200))

        // Expression routing: one policy call decides what pressure does.
        let mod = pressureModulation(params.pressureRoute, v.pressure, .sampler)
        v.cutoffSm.target = Float(cutoffToHz(Double(0.8 + 0.2 * mod.filter)))
        // Web Audio's default BiquadFilter Q is 1 (dB for lowpass).
        v.filter.setLowpass(freq: v.cutoffSm.step(a015), qDb: 1, sampleRate: sr)

        v.expSm.target = mod.level
        let vOut = outGain * v.expSm.step(a03)
        let sustainAlpha = smoothingAlpha(dt: 1 / sr, tau: 0.03)
        let retrigAlpha = smoothingAlpha(dt: 1 / sr, tau: 0.008)

        for i in 0..<n {
            // Sample read with linear interpolation.
            var pos = v.pos
            if loop {
                while pos >= loopEnd { pos -= (loopEnd - loopStart) }
            } else if pos >= Double(count - 1) {
                if let pending = v.pendingStart {
                    startSamplerVoice(v, pending)
                } else {
                    v.active = false
                }
                return
            }
            let i0 = Int(pos)
            let frac = Float(pos - Double(i0))
            let i1 = min(i0 + 1, count - 1)
            let sample = data[i0] + (data[i1] - data[i0]) * frac
            v.pos = pos + rate

            switch v.stage {
            case ENV_ATTACK:
                v.gain += v.attackStep
                if v.gain >= v.peak {
                    v.gain = v.peak
                    v.stage = ENV_SUSTAIN
                }
            case ENV_SUSTAIN:
                v.gain += (v.peak - v.gain) * sustainAlpha
            case ENV_RETRIG_FADE:
                v.gain += (0 - v.gain) * retrigAlpha
                v.killSamples -= 1
                if v.killSamples <= 0 {
                    v.active = false
                    return
                }
            case ENV_STEAL_FADE:
                v.gain = max(0, v.gain - v.stealStep)
                v.killSamples -= 1
                bus[i] += v.filter.process(sample) * v.gain * vOut
                if v.killSamples <= 0 {
                    if let pending = v.pendingStart {
                        startSamplerVoice(v, pending)
                    } else {
                        v.active = false
                    }
                    return
                }
                continue
            default: // released
                v.gain += (0 - v.gain) * v.releaseAlpha
                v.killSamples -= 1
                if v.killSamples <= 0 || v.gain < 1e-5 {
                    v.active = false
                    return
                }
            }
            bus[i] += v.filter.process(sample) * v.gain * vOut
            v.renderedSamples += 1
            if v.pendingRelease, v.renderedSamples >= MIN_ONSET_SAMPLES {
                beginSamplerRelease(v)
            }
        }
    }
}
