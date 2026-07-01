/// Lock-free single-producer/single-consumer ring carrying ALL control
/// traffic into the audio render thread: note events, parameter changes,
/// wavetable and sample-buffer pointers. The kernel drains it at the top of
/// every render block; the UI/main thread is the only producer.
///
/// Payloads are plain values and raw pointers — nothing refcounted crosses
/// the boundary, so neither side ever allocates, retains, or locks.
import Synchronization

public enum KernelDest: UInt8 {
    case synth = 0
    case sampler = 1
}

/// Kernel-side parameter IDs (values are what the web engine's applyParams
/// pushes into AudioParams).
public enum ParamID: Int32 {
    case gen1Semi, gen1Tune, gen1Level
    case gen2Semi, gen2Tune, gen2Level
    case envA, envD, envS, envR
    case filterCutoff, filterRes, filterEnv
    case lfoRate, lfoDepth, lfoTargetFilter // 0 = pitch, 1 = filter
    case synthLevel
    case reverbFdbk, reverbMix, reverbOn
    case delayTime, delayFdbk, delayMix, delayOn
    case distortAmt, distortOn
    case fattenAmt, fattenOn
    case samplerLevel, samplerAttack, samplerRelease, samplerRetrig
    case slide
}

/// A PCM buffer reference the kernel can play. The pointed-to memory is owned
/// by the main-thread SampleRegistry and outlives every voice.
public struct SampleRef {
    public var data: UnsafePointer<Float>?
    public var count: Int32
    /// MIDI root the sample is pitched at.
    public var root: Float
    /// Loop window in samples; loopStart < 0 = one-shot.
    public var loopStart: Int32
    public var loopEnd: Int32

    public init(data: UnsafePointer<Float>?, count: Int32, root: Float, loopStart: Int32, loopEnd: Int32) {
        self.data = data
        self.count = count
        self.root = root
        self.loopStart = loopStart
        self.loopEnd = loopEnd
    }

    public static let none = SampleRef(data: nil, count: 0, root: 60, loopStart: -1, loopEnd: -1)
}

public enum KernelEvent {
    case noteOn(dest: KernelDest, id: Int32, pitch: Float, vel: Float)
    case glide(dest: KernelDest, id: Int32, pitch: Float)
    case pressure(dest: KernelDest, id: Int32, value: Float)
    case noteOff(dest: KernelDest, id: Int32)
    case allOff(dest: KernelDest)
    case param(ParamID, Float)
    /// Pointer to Wavetable.totalSize floats (all mip levels) for a generator.
    case wavetable(gen: Int32, table: UnsafePointer<Float>)
    /// Switch the sample the *next* sampler voices will play.
    case sample(SampleRef)
}

public final class EventRing: @unchecked Sendable {
    private let capacity: Int
    private let mask: Int
    private let buffer: UnsafeMutablePointer<KernelEvent>
    private let head = Atomic<Int>(0) // consumer position
    private let tail = Atomic<Int>(0) // producer position
    /// Events dropped because the ring was full (diagnostic, producer-side).
    public private(set) var dropped = 0

    public init(capacity: Int = 1024) {
        precondition(capacity & (capacity - 1) == 0, "capacity must be a power of two")
        self.capacity = capacity
        self.mask = capacity - 1
        buffer = .allocate(capacity: capacity)
        buffer.initialize(repeating: .allOff(dest: .synth), count: capacity)
    }

    deinit {
        buffer.deinitialize(count: capacity)
        buffer.deallocate()
    }

    /// Producer side (main thread only).
    @discardableResult
    public func push(_ event: KernelEvent) -> Bool {
        let t = tail.load(ordering: .relaxed)
        let h = head.load(ordering: .acquiring)
        if t - h >= capacity {
            dropped += 1
            return false
        }
        buffer[t & mask] = event
        tail.store(t + 1, ordering: .releasing)
        return true
    }

    /// Consumer side (audio thread only).
    public func pop() -> KernelEvent? {
        let h = head.load(ordering: .relaxed)
        let t = tail.load(ordering: .acquiring)
        if h == t { return nil }
        let event = buffer[h & mask]
        head.store(h + 1, ordering: .releasing)
        return event
    }
}
