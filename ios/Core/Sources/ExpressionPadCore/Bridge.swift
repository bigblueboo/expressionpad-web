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

    /// One row per kernel-addressable store leaf: web dot-path → param id +
    /// value extractor. The single source of truth for param plumbing — a
    /// change pushes exactly one event; startup replays the whole table.
    static let paramTable: [String: (ParamID, (AppState) -> Float)] = [
        "synth.gen1.semi": (.gen1Semi, { Float($0.synth.gen1.semi) }),
        "synth.gen1.tune": (.gen1Tune, { Float($0.synth.gen1.tune) }),
        "synth.gen1.level": (.gen1Level, { Float($0.synth.gen1.level) }),
        "synth.gen2.semi": (.gen2Semi, { Float($0.synth.gen2.semi) }),
        "synth.gen2.tune": (.gen2Tune, { Float($0.synth.gen2.tune) }),
        "synth.gen2.level": (.gen2Level, { Float($0.synth.gen2.level) }),
        "synth.env.a": (.envA, { Float($0.synth.env.a) }),
        "synth.env.d": (.envD, { Float($0.synth.env.d) }),
        "synth.env.s": (.envS, { Float($0.synth.env.s) }),
        "synth.env.r": (.envR, { Float($0.synth.env.r) }),
        "synth.filter.cutoff": (.filterCutoff, { Float($0.synth.filter.cutoff) }),
        "synth.filter.res": (.filterRes, { Float($0.synth.filter.res) }),
        "synth.filter.env": (.filterEnv, { Float($0.synth.filter.env) }),
        "synth.lfo.rate": (.lfoRate, { Float($0.synth.lfo.rate) }),
        "synth.lfo.depth": (.lfoDepth, { Float($0.synth.lfo.depth) }),
        "synth.lfo.target": (.lfoTargetFilter, { $0.synth.lfo.target == .filter ? 1 : 0 }),
        "synth.level": (.synthLevel, { Float($0.synth.level) }),
        "fx.reverb.fdbk": (.reverbFdbk, { Float($0.fx.reverb.fdbk) }),
        "fx.reverb.mix": (.reverbMix, { Float($0.fx.reverb.mix) }),
        "fx.reverb.on": (.reverbOn, { $0.fx.reverb.on ? 1 : 0 }),
        "fx.delay.time": (.delayTime, { Float($0.fx.delay.time) }),
        "fx.delay.fdbk": (.delayFdbk, { Float($0.fx.delay.fdbk) }),
        "fx.delay.mix": (.delayMix, { Float($0.fx.delay.mix) }),
        "fx.delay.on": (.delayOn, { $0.fx.delay.on ? 1 : 0 }),
        "fx.distort.amt": (.distortAmt, { Float($0.fx.distort.amt) }),
        "fx.distort.on": (.distortOn, { $0.fx.distort.on ? 1 : 0 }),
        "fx.fatten.amt": (.fattenAmt, { Float($0.fx.fatten.amt) }),
        "fx.fatten.on": (.fattenOn, { $0.fx.fatten.on ? 1 : 0 }),
        "sampler.level": (.samplerLevel, { Float($0.sampler.level) }),
        "sampler.attack": (.samplerAttack, { Float($0.sampler.attack) }),
        "sampler.release": (.samplerRelease, { Float($0.sampler.release) }),
        "sampler.retrig": (.samplerRetrig, { $0.sampler.retrig ? 1 : 0 }),
        "pad.slide": (.slide, { Float($0.pad.slide) }),
    ]

    func onChange(_ path: String) {
        if path == "synth.gen1.morph" || path == "synth.gen2.morph" || path == "synth.bright" {
            pushWavetables()
        }
        if path == "sampler.preset" || path == "sampler.userRoot" {
            registry.select(preset: store.state.sampler.preset, userRoot: store.state.sampler.userRoot)
        }
        if let (pid, value) = Self.paramTable[path] {
            ring.push(.param(pid, value(store.state)))
        }
    }

    func pushWavetables() {
        let s = store.state.synth
        ring.push(.wavetable(gen: 0, table: pool1.build(morph: s.gen1.morph, bright: s.bright)))
        ring.push(.wavetable(gen: 1, table: pool2.build(morph: s.gen2.morph, bright: s.bright)))
    }

    public func pushAll() {
        pushWavetables()
        for (pid, value) in Self.paramTable.values {
            ring.push(.param(pid, value(store.state)))
        }
        registry.select(preset: store.state.sampler.preset, userRoot: store.state.sampler.userRoot)
    }
}
