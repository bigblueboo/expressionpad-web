/// Main-thread side of the kernel boundary: VoiceSink proxies that write
/// note events into the ring, the store→param adapter (the port of
/// engine.ts applyParams), the wavetable pool, and the sample registry.
import Foundation

/// A VoiceSink that forwards to one kernel destination through the ring.
public final class KernelVoiceSink: VoiceSink {
    let ring: EventRing
    let dest: KernelDest

    public init(ring: EventRing, dest: KernelDest) {
        self.ring = ring
        self.dest = dest
    }

    public func noteOn(_ id: Int, _ pitch: Double, _ vel: Double) {
        ring.push(.noteOn(dest: dest, id: Int32(truncatingIfNeeded: id), pitch: Float(pitch), vel: Float(vel)))
    }

    public func glide(_ id: Int, _ pitch: Double) {
        ring.push(.glide(dest: dest, id: Int32(truncatingIfNeeded: id), pitch: Float(pitch)))
    }

    public func pressure(_ id: Int, _ value: Double) {
        ring.push(.pressure(dest: dest, id: Int32(truncatingIfNeeded: id), value: Float(value)))
    }

    public func noteOff(_ id: Int) {
        ring.push(.noteOff(dest: dest, id: Int32(truncatingIfNeeded: id)))
    }

    public func allOff() {
        ring.push(.allOff(dest: dest))
    }
}

/// Round-robin pool of wavetable slabs for one generator. The main thread
/// builds into the next slab and passes the pointer through the ring; with
/// 8 slabs the kernel (draining every ~5 ms) has long since moved on before
/// a slab is reused.
public final class WavetablePool {
    static let slabs = 8
    private let memory: UnsafeMutablePointer<Float>
    private var next = 0

    public init() {
        memory = .allocate(capacity: Wavetable.totalSize * WavetablePool.slabs)
        memory.initialize(repeating: 0, count: Wavetable.totalSize * WavetablePool.slabs)
    }

    deinit {
        memory.deallocate()
    }

    /// Build tables for (morph, bright) and return a kernel-lifetime pointer.
    public func build(morph: Double, bright: Double) -> UnsafePointer<Float> {
        let slab = memory + next * Wavetable.totalSize
        next = (next + 1) % WavetablePool.slabs
        Wavetable.build(morph: morph, bright: bright, into: slab)
        return UnsafePointer(slab)
    }
}

/// Owns every PCM buffer the kernel may reference. Buffers are copied into
/// manually-allocated memory and intentionally never freed: a sampler voice
/// may hold a pointer for as long as its release tail runs, and the total is
/// bounded (6 built-ins + user loads) for the life of the process.
public final class SampleRegistry {
    let ring: EventRing
    public let sampleRate: Double
    private var builtins: [String: SampleRef] = [:]
    private var user: (name: String, data: UnsafePointer<Float>, count: Int)?

    public init(ring: EventRing, sampleRate: Double) {
        self.ring = ring
        self.sampleRate = sampleRate
    }

    public var userSampleName: String? { user?.name }

    private func pin(_ data: [Float]) -> UnsafePointer<Float> {
        let mem = UnsafeMutablePointer<Float>.allocate(capacity: max(1, data.count))
        data.withUnsafeBufferPointer { mem.update(from: $0.baseAddress!, count: data.count) }
        return UnsafePointer(mem)
    }

    /// Store a decoded user sample (mono, engine sample rate).
    public func setUserSample(_ data: [Float], name: String) {
        user = (name, pin(data), data.count)
    }

    /// Render/cache the preset and point the kernel at it.
    public func select(preset: String, userRoot: Int) {
        if preset == USER_PRESET {
            guard let user else { return }
            ring.push(.sample(SampleRef(
                data: user.data, count: Int32(user.count), root: Float(userRoot),
                loopStart: -1, loopEnd: -1
            )))
            return
        }
        let name = SAMPLE_NAMES.contains(preset) ? preset : SAMPLE_NAMES[0]
        var ref = builtins[name]
        if ref == nil {
            let r = renderSample(name, sampleRate)
            ref = SampleRef(
                data: pin(r.data), count: Int32(r.data.count), root: Float(r.root),
                loopStart: Int32(r.loopStart ?? -1), loopEnd: Int32(r.loopEnd ?? -1)
            )
            builtins[name] = ref
        }
        ring.push(.sample(ref!))
    }
}

/// Subscribes to the store and keeps the kernel in sync — the port of
/// engine.ts applyParams + rebuildWaves and sampler.ts's level/preset logic.
public final class StoreKernelBridge {
    let store: Store
    let ring: EventRing
    public let registry: SampleRegistry
    let pool1 = WavetablePool()
    let pool2 = WavetablePool()

    public init(store: Store, ring: EventRing, sampleRate: Double) {
        self.store = store
        self.ring = ring
        registry = SampleRegistry(ring: ring, sampleRate: sampleRate)
        store.subscribe { [weak self] _, path in self?.onChange(path) }
        pushAll()
    }

    func onChange(_ path: String) {
        let s = store.state
        if path.hasPrefix("synth") || path.hasPrefix("fx") || path == "pad.slide"
            || path.hasPrefix("sampler") {
            if path.contains("morph") || path.contains("bright") { pushWavetables() }
            if path == "sampler.preset" || path == "sampler.userRoot" {
                registry.select(preset: s.sampler.preset, userRoot: s.sampler.userRoot)
            }
            pushParams()
        }
    }

    func pushWavetables() {
        let s = store.state.synth
        ring.push(.wavetable(gen: 0, table: pool1.build(morph: s.gen1.morph, bright: s.bright)))
        ring.push(.wavetable(gen: 1, table: pool2.build(morph: s.gen2.morph, bright: s.bright)))
    }

    /// Push the full parameter set; the kernel treats repeats as no-ops.
    func pushParams() {
        let s = store.state
        let p: [(ParamID, Double)] = [
            (.gen1Semi, Double(s.synth.gen1.semi)), (.gen1Tune, s.synth.gen1.tune), (.gen1Level, s.synth.gen1.level),
            (.gen2Semi, Double(s.synth.gen2.semi)), (.gen2Tune, s.synth.gen2.tune), (.gen2Level, s.synth.gen2.level),
            (.envA, s.synth.env.a), (.envD, s.synth.env.d), (.envS, s.synth.env.s), (.envR, s.synth.env.r),
            (.filterCutoff, s.synth.filter.cutoff), (.filterRes, s.synth.filter.res), (.filterEnv, s.synth.filter.env),
            (.lfoRate, s.synth.lfo.rate), (.lfoDepth, s.synth.lfo.depth),
            (.lfoTargetFilter, s.synth.lfo.target == .filter ? 1 : 0),
            (.synthLevel, s.synth.level),
            (.reverbFdbk, s.fx.reverb.fdbk), (.reverbMix, s.fx.reverb.mix), (.reverbOn, s.fx.reverb.on ? 1 : 0),
            (.delayTime, s.fx.delay.time), (.delayFdbk, s.fx.delay.fdbk), (.delayMix, s.fx.delay.mix),
            (.delayOn, s.fx.delay.on ? 1 : 0),
            (.distortAmt, s.fx.distort.amt), (.distortOn, s.fx.distort.on ? 1 : 0),
            (.fattenAmt, s.fx.fatten.amt), (.fattenOn, s.fx.fatten.on ? 1 : 0),
            (.samplerLevel, s.sampler.level), (.samplerAttack, s.sampler.attack),
            (.samplerRelease, s.sampler.release), (.samplerRetrig, s.sampler.retrig ? 1 : 0),
            (.slide, s.pad.slide),
        ]
        for (pid, v) in p { ring.push(.param(pid, Float(v))) }
    }

    public func pushAll() {
        pushWavetables()
        pushParams()
        registry.select(preset: store.state.sampler.preset, userRoot: store.state.sampler.userRoot)
    }
}
