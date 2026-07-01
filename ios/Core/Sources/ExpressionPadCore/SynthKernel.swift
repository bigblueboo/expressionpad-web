/// SynthKernel — the entire instrument rendered in one real-time callback:
/// polyphonic wavetable synth + sampler voices → distortion → delay → reverb
/// → master → limiter, matching ../src/audio/engine.ts & sampler.ts node for
/// node. Everything is preallocated; the only communication with the outside
/// world is the lock-free EventRing and the output buffers.
///
/// Web Audio parity notes:
/// - setTargetAtTime(v, tau) → OnePole stepped per 32-sample block.
/// - Envelopes: linear attack to peak, one-pole decay to peak·sustain
///   (tau = d/3), one-pole release (tau = r/3), hard stop at r·2+0.1 s.
/// - Oscillator detune is captured at noteOn (the web build never re-writes
///   osc.detune after start); SEMI changes retune running voices, TUNE only
///   affects new ones — exactly engine.ts's retuneVoice behavior.
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
}

private let ENV_ATTACK: Int32 = 1
private let ENV_SUSTAIN: Int32 = 2
private let ENV_RELEASED: Int32 = 3
private let ENV_RETRIG_FADE: Int32 = 4

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
    var detune = [Float](repeating: 0, count: 4) // cents, fixed at noteOn
    var oscGen = [Int](repeating: 0, count: 4)
    var oscScale = [Float](repeating: 0, count: 4)
    var g1 = OnePole(0)
    var g2 = OnePole(0)
    var filter = Biquad()
    var cutoffSm = OnePole(1000) // Hz
    var qSm = OnePole(0) // dB
    var env: Float = 0
    var envStage: Int32 = 0
    var envPeak: Float = 0
    var envSustain: Float = 0
    var attackStep: Float = 0
    var decayAlpha: Float = 0
    var releaseAlpha: Float = 0
    var killSamples = 0
}

final class SamplerVoice {
    var active = false
    var id: Int32 = -1
    var order = 0
    var sample = SampleRef.none
    var pitch: Float = 60
    var vel: Float = 0.8
    var pressure: Float = 0
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
    private let defaultTables: UnsafeMutablePointer<Float>

    var currentSample = SampleRef.none

    // Modulation & mix smoothers.
    var lfoPhase: Float = 0
    var lfoFreqSm = OnePole(5)
    var lfoPitchGainSm = OnePole(0)
    var lfoFilterGainSm = OnePole(0)
    var master = OnePole(0.78)
    var samplerOut = OnePole(0.8)

    // FX
    var dist = Distortion()
    var delay: FeedbackDelay
    var reverb: FDNReverb
    var limiter: Limiter

    // Scratch (blockSize / per-voice, preallocated — the render path never allocates)
    var bus: [Float]
    var phaseIncScratch = [Float](repeating: 0, count: 4)
    var levelScratch = [Int](repeating: 0, count: 4)

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
                if dest == .synth {
                    for v in voices where v.active && !v.released { releaseSynthVoice(v) }
                } else {
                    for v in sVoices where v.active && v.stage != ENV_RELEASED { releaseSamplerVoice(v) }
                }
            case let .param(pid, value):
                applyParam(pid, value)
            case let .wavetable(gen, table):
                if gen == 0 { table1 = table } else { table2 = table }
            case let .sample(ref):
                currentSample = ref
            }
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
        case .gen1Tune: params.gen1Tune = v
        case .gen1Level: params.gen1Level = v
        case .gen2Tune: params.gen2Tune = v
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

    // ------------------------------------------------------ synth voices ---

    func findSynth(_ id: Int32) -> SynthVoice? {
        for v in voices where v.active && !v.released && v.id == id { return v }
        return nil
    }

    func synthNoteOn(_ id: Int32, _ pitch: Float, _ vel: Float) {
        if let existing = findSynth(id) { releaseSynthVoice(existing) }
        // Voice stealing: release the oldest playing voice past the cap.
        // (Manual scans — no allocating filter/min on the audio thread.)
        var playingCount = 0
        var oldestPlaying: SynthVoice?
        var freeSlot: SynthVoice?
        var oldestActive: SynthVoice?
        for v in voices {
            if v.active && !v.released {
                playingCount += 1
                if oldestPlaying == nil || v.order < oldestPlaying!.order { oldestPlaying = v }
            }
            if !v.active && freeSlot == nil { freeSlot = v }
            if v.active && (oldestActive == nil || v.order < oldestActive!.order) { oldestActive = v }
        }
        if playingCount >= SynthKernel.maxVoices, let oldest = oldestPlaying {
            releaseSynthVoice(oldest)
        }
        // Slot: prefer inactive, else hard-steal the oldest released tail.
        guard let v = freeSlot ?? oldestActive else { return }

        orderCounter += 1
        v.active = true
        v.released = false
        v.id = id
        v.order = orderCounter
        v.pitch = pitch
        v.vel = vel
        v.pressure = 0

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
            let f = Float(midiToFreq(Double(pitch + semi)))
            v.phase[k] = 0
            v.freqCur[k] = f
            v.freqTgt[k] = f
            v.detune[k] = tune + layerDet
            v.oscGen[k] = gen
            v.oscScale[k] = layerScale
        }
        v.g1.snap(params.gen1Level)
        v.g2.snap(params.gen2Level)
        v.filter.reset()
        let norm = clamp(params.filterCutoff + params.filterEnv * v.pressure, 0, 1)
        v.cutoffSm.snap(Float(cutoffToHz(Double(norm))))
        v.qSm.snap(params.filterRes * 18)

        v.envPeak = Float(velocityToGain(Double(vel)))
        v.env = 0
        v.envStage = ENV_ATTACK
        let a = max(0.001, params.envA)
        v.attackStep = v.envPeak / (a * sr)
        v.envSustain = v.envPeak * params.envS
        let dTau = max(0.01, params.envD) / 3
        v.decayAlpha = 1 - exp(-1 / (dTau * sr))
    }

    func synthGlide(_ id: Int32, _ pitch: Float) {
        guard let v = findSynth(id) else { return }
        v.pitch = pitch
        for k in 0..<v.oscCount {
            let semi = v.oscGen[k] == 0 ? params.gen1Semi : params.gen2Semi
            v.freqTgt[k] = Float(midiToFreq(Double(pitch + semi)))
        }
    }

    func releaseSynthVoice(_ v: SynthVoice) {
        let r = max(0.02, params.envR)
        v.released = true
        v.envStage = ENV_RELEASED
        v.releaseAlpha = 1 - exp(-1 / (r / 3 * sr))
        v.killSamples = Int((r * 2 + 0.1) * sr)
    }

    func synthNoteOff(_ id: Int32) {
        guard let v = findSynth(id) else { return }
        releaseSynthVoice(v)
    }

    // ---------------------------------------------------- sampler voices ---

    func findSampler(_ id: Int32) -> SamplerVoice? {
        for v in sVoices where v.active && v.stage != ENV_RELEASED && v.stage != ENV_RETRIG_FADE && v.id == id {
            return v
        }
        return nil
    }

    func samplerNoteOn(_ id: Int32, _ pitch: Float, _ vel: Float) {
        guard currentSample.data != nil else { return }
        if let existing = findSampler(id) { releaseSamplerVoice(existing) }
        var freeSlot: SamplerVoice?
        var oldestActive: SamplerVoice?
        for v in sVoices {
            if !v.active && freeSlot == nil { freeSlot = v }
            if v.active && (oldestActive == nil || v.order < oldestActive!.order) { oldestActive = v }
        }
        guard let v = freeSlot ?? oldestActive else { return }

        orderCounter += 1
        v.active = true
        v.id = id
        v.order = orderCounter
        v.sample = currentSample
        v.pitch = pitch
        v.vel = vel
        v.pressure = 0
        v.pos = 0
        v.centsSm.snap((pitch - currentSample.root) * 100)
        v.peak = Float(velocityToGain(Double(vel)))
        v.gain = 0
        v.stage = ENV_ATTACK
        let a = max(0.002, params.samplerAttack)
        v.attackStep = v.peak / (a * sr)
        v.filter.reset()
        v.cutoffSm.snap(Float(cutoffToHz(0.8)))
        v.killSamples = 0
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

    func releaseSamplerVoice(_ v: SamplerVoice) {
        let r = max(0.02, params.samplerRelease)
        v.stage = ENV_RELEASED
        v.releaseAlpha = 1 - exp(-1 / (r / 3 * sr))
        v.killSamples = Int((r * 2 + 0.1) * sr)
    }

    func samplerNoteOff(_ id: Int32) {
        guard let v = findSampler(id) else { return }
        releaseSamplerVoice(v)
    }

    // ---------------------------------------------------------- render ---

    public func render(frames: Int, outL: UnsafeMutablePointer<Float>, outR: UnsafeMutablePointer<Float>) {
        drainEvents()
        var offset = 0
        while offset < frames {
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
        let a05 = smoothingAlpha(dt: dt, tau: 0.05)
        let a03 = smoothingAlpha(dt: dt, tau: 0.03)

        // LFO (block-rate; max 30 Hz vs 1.5 kHz block rate).
        lfoFreqSm.target = clamp(params.lfoRate, 0.05, 30)
        let lfoFreq = lfoFreqSm.step(a02)
        let lfoValue = sin(2 * .pi * lfoPhase)
        lfoPhase += lfoFreq * dt
        if lfoPhase >= 1 { lfoPhase -= floor(lfoPhase) }
        lfoPitchGainSm.target = params.lfoTargetFilter < 0.5 ? params.lfoDepth * 60 : 0
        lfoFilterGainSm.target = params.lfoTargetFilter >= 0.5 ? params.lfoDepth * 2400 : 0
        let lfoPitchCents = lfoValue * lfoPitchGainSm.step(a02)
        let lfoFilterCents = lfoValue * lfoFilterGainSm.step(a02)

        for i in 0..<n { bus[i] = 0 }

        // ----- synth voices
        let glideTau = lerp(0.004, 0.06, params.slide)
        let glideAlpha = smoothingAlpha(dt: dt, tau: glideTau)
        for v in voices where v.active {
            renderSynthVoice(v, n, glideAlpha: glideAlpha, a02: a02, a015: a015,
                             lfoPitchCents: lfoPitchCents, lfoFilterCents: lfoFilterCents)
        }

        // ----- sampler voices
        samplerOut.target = params.samplerLevel
        let sampGain = samplerOut.step(a02)
        for v in sVoices where v.active {
            renderSamplerVoice(v, n, glideAlpha: glideAlpha, a015: a015, a03: a03, outGain: sampGain)
        }

        // ----- FX chain: dist → delay → reverb → master → limiter
        dist.k = 1 + clamp(params.distortAmt, 0, 1) * 30
        dist.wet.target = params.distortOn > 0.5 ? 1 : 0
        dist.dry.target = params.distortOn > 0.5 ? 0 : 1
        let dWet = dist.wet.step(a02)
        let dDry = dist.dry.step(a02)

        delay.timeSm.target = clamp(params.delayTime, 0.01, 2)
        delay.fdbkSm.target = clamp(params.delayFdbk, 0, 0.9)
        delay.wetSm.target = params.delayOn > 0.5 ? params.delayMix : 0
        let dlTime = delay.timeSm.step(a05)
        let dlFdbk = delay.fdbkSm.step(a02)
        let dlWet = delay.wetSm.step(a02)

        reverb.setDecay(seconds: lerp(0.4, 5, clamp(params.reverbFdbk, 0, 1)))
        reverb.wetSm.target = params.reverbOn > 0.5 ? params.reverbMix : 0
        let rvWet = reverb.wetSm.step(a02)

        master.target = params.synthLevel
        let masterGain = master.step(a02)

        var rv: (l: Float, r: Float) = (0, 0)
        for i in 0..<n {
            let distorted = dist.process(bus[i], wetGain: dWet, dryGain: dDry)
            let delayed = delay.process(distorted, time: dlTime, fdbk: dlFdbk, wet: dlWet)
            reverb.process(delayed, into: &rv)
            var l = (delayed + rv.l * rvWet) * masterGain
            var r = (delayed + rv.r * rvWet) * masterGain
            limiter.process(l: &l, r: &r)
            outL[i] = l
            outR[i] = r
        }
    }

    private func renderSynthVoice(
        _ v: SynthVoice, _ n: Int, glideAlpha: Float, a02: Float, a015: Float,
        lfoPitchCents: Float, lfoFilterCents: Float
    ) {
        // Per-block modulation & coefficient updates.
        v.g1.target = params.gen1Level
        v.g2.target = params.gen2Level
        let g1 = v.g1.step(a02)
        let g2 = v.g2.step(a02)

        let norm = clamp(params.filterCutoff + params.filterEnv * v.pressure, 0, 1)
        v.cutoffSm.target = Float(cutoffToHz(Double(norm)))
        v.qSm.target = params.filterRes * 18
        let cutoffHz = v.cutoffSm.step(a015) * exp2(lfoFilterCents / 1200)
        v.filter.setLowpass(freq: cutoffHz, qDb: v.qSm.step(a02), sampleRate: sr)

        for k in 0..<v.oscCount {
            v.freqCur[k] += (v.freqTgt[k] - v.freqCur[k]) * glideAlpha
            let eff = v.freqCur[k] * exp2((v.detune[k] + lfoPitchCents) / 1200)
            phaseIncScratch[k] = eff / sr
            levelScratch[k] = Wavetable.level(forFreq: Double(eff), sampleRate: sampleRate)
        }

        for i in 0..<n {
            var mix: Float = 0
            for k in 0..<v.oscCount {
                let table = v.oscGen[k] == 0 ? table1 : table2
                let base = levelScratch[k] * Wavetable.stride
                let x = v.phase[k] * Float(Wavetable.size)
                let ti = Int(x)
                let frac = x - Float(ti)
                let p = table + base + ti
                let sample = p[0] + (p[1] - p[0]) * frac
                mix += sample * v.oscScale[k] * (v.oscGen[k] == 0 ? g1 : g2)
                v.phase[k] += phaseIncScratch[k]
                if v.phase[k] >= 1 { v.phase[k] -= 1 }
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
            default: // released
                v.env += (0 - v.env) * v.releaseAlpha
                v.killSamples -= 1
                if v.killSamples <= 0 || v.env < 1e-5 {
                    v.active = false
                    bus[i] += filtered * v.env
                    return
                }
            }
            bus[i] += filtered * v.env
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

        v.cutoffSm.target = Float(cutoffToHz(Double(0.8 + 0.2 * v.pressure)))
        // Web Audio's default BiquadFilter Q is 1 (dB for lowpass).
        v.filter.setLowpass(freq: v.cutoffSm.step(a015), qDb: 1, sampleRate: sr)

        // Pressure swell toward peak·(1+0.35·p), tau 0.03 (sustain stage only).
        let swellTarget = v.peak * (1 + 0.35 * v.pressure)
        let swellAlpha = smoothingAlpha(dt: 1 / sr, tau: 0.03)
        let retrigAlpha = smoothingAlpha(dt: 1 / sr, tau: 0.008)

        for i in 0..<n {
            // Sample read with linear interpolation.
            var pos = v.pos
            if loop {
                while pos >= loopEnd { pos -= (loopEnd - loopStart) }
            } else if pos >= Double(count - 1) {
                v.active = false
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
                v.gain += (swellTarget - v.gain) * swellAlpha
            case ENV_RETRIG_FADE:
                v.gain += (0 - v.gain) * retrigAlpha
                v.killSamples -= 1
                if v.killSamples <= 0 {
                    v.active = false
                    return
                }
            default: // released
                v.gain += (0 - v.gain) * v.releaseAlpha
                v.killSamples -= 1
                if v.killSamples <= 0 || v.gain < 1e-5 {
                    v.active = false
                    return
                }
            }
            bus[i] += v.filter.process(sample) * v.gain * outGain
        }
    }
}
