/// AVAudioEngine glue: an AVAudioSourceNode pulls the SynthKernel on the
/// audio I/O thread; AVAudioSession is tuned for low latency (5 ms buffers,
/// 48 kHz). Everything the kernel needs arrives through the lock-free ring.
import AVFoundation
import CoreMotion
import ExpressionPadCore

final class AudioEngine: ObservableObject {
    let store: Store
    let kernel: SynthKernel
    let bridge: StoreKernelBridge
    let synthSink: KernelVoiceSink
    let samplerSink: KernelVoiceSink

    private var engine = AVAudioEngine()
    private var sourceNode: AVAudioSourceNode?
    private var applicationSuspended = false
    private let motion = CMMotionManager()
    private var tiltSmoothed = 0.0

    var running: Bool { engine.isRunning }

    init(store: Store) {
        self.store = store

        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setPreferredSampleRate(48000)
            #if targetEnvironment(simulator)
            // Simulator audio shares host scheduling with the debugger and UI.
            // A 5 ms preference is unnecessarily brittle there, particularly
            // while rapidly creating release tails. Hardware keeps the lower
            // touch-to-sound latency below.
            try session.setPreferredIOBufferDuration(0.010)
            #else
            // ~240 frames @48 kHz. The web build's AudioContext 'interactive'
            // hint typically lands at 128–256 frames; this matches or beats it.
            try session.setPreferredIOBufferDuration(0.005)
            #endif
            try session.setActive(true)
        } catch {
            // Session config failure is non-fatal; the engine still runs with defaults.
        }

        let sampleRate = session.sampleRate > 0 ? session.sampleRate : 48000
        kernel = SynthKernel(sampleRate: sampleRate)
        bridge = StoreKernelBridge(store: store, ring: kernel.events, sampleRate: sampleRate)
        synthSink = KernelVoiceSink(ring: kernel.events, dest: .synth)
        samplerSink = KernelVoiceSink(ring: kernel.events, dest: .sampler)

        buildGraph()
        start()
        observeSession()

        store.subscribe { [weak self] _, path in
            if path == "expr.tilt" { self?.syncTilt() }
        }
        syncTilt()
    }

    var sampleRegistry: SampleRegistry { bridge.registry }

    /// Touch-to-sound estimate shown in the MIDI tab, like the web build.
    var latencyMs: Int {
        let session = AVAudioSession.sharedInstance()
        return Int(((session.outputLatency + session.ioBufferDuration) * 1000).rounded())
    }

    /// Attach the kernel's source node to the (fresh) engine. Called once at
    /// init and again only when media services reset hands us a dead engine.
    private func buildGraph() {
        let format = AVAudioFormat(
            standardFormatWithSampleRate: kernel.sampleRate, channels: 2
        )!
        // Capture the kernel directly: the render closure must not touch self.
        let kernel = self.kernel
        let node = AVAudioSourceNode(format: format) { _, _, frameCount, audioBufferList -> OSStatus in
            let abl = UnsafeMutableAudioBufferListPointer(audioBufferList)
            guard abl.count >= 2,
                  let l = abl[0].mData?.assumingMemoryBound(to: Float.self),
                  let r = abl[1].mData?.assumingMemoryBound(to: Float.self)
            else {
                // The requested format is planar stereo, but route/graph
                // failures must produce silence rather than stale audio.
                for buffer in abl {
                    buffer.mData?.initializeMemory(
                        as: UInt8.self, repeating: 0, count: Int(buffer.mDataByteSize)
                    )
                }
                return noErr
            }
            kernel.render(frames: Int(frameCount), outL: l, outR: r)
            return noErr
        }
        engine.attach(node)
        engine.connect(node, to: engine.mainMixerNode, format: format)
        sourceNode = node
    }

    /// Idempotent: safe to call on every foregrounding.
    func start() {
        applicationSuspended = false
        syncTilt()
        guard !engine.isRunning else { return }
        try? AVAudioSession.sharedInstance().setActive(true)
        try? engine.start()
    }

    /// Relinquish the audio session while the app is in the background. This
    /// app has no background-playback feature, so retaining the session would
    /// waste power and interfere with the user's other audio.
    func stop() {
        applicationSuspended = true
        if motion.isDeviceMotionActive { motion.stopDeviceMotionUpdates() }
        if engine.isRunning { engine.stop() }
        try? AVAudioSession.sharedInstance().setActive(
            false, options: .notifyOthersOnDeactivation
        )
    }

    /// Start/stop the motion feed to match the EXPRESSION tilt routing. The
    /// gravity vector's z-component folds to the same "uprightness" 0 (flat on
    /// a table) → 1 (screen vertical) the web build derives from
    /// DeviceOrientation, in any rotation.
    private func syncTilt() {
        let wanted = store.state.expr.tilt != .off && !applicationSuspended
        if wanted && motion.isDeviceMotionAvailable && !motion.isDeviceMotionActive {
            motion.deviceMotionUpdateInterval = 1.0 / 30
            motion.startDeviceMotionUpdates(to: .main) { [weak self] dm, _ in
                guard let self, let gravity = dm?.gravity else { return }
                let upright = 1 - min(1, abs(gravity.z))
                self.tiltSmoothed += (upright - self.tiltSmoothed) * 0.25
                self.kernel.events.push(.param(.tilt, Float(self.tiltSmoothed)))
            }
        } else if !wanted && motion.isDeviceMotionActive {
            motion.stopDeviceMotionUpdates()
            tiltSmoothed = 0
            kernel.events.push(.param(.tilt, 0))
        }
    }

    private func observeSession() {
        let center = NotificationCenter.default
        center.addObserver(
            forName: AVAudioSession.interruptionNotification, object: nil, queue: .main
        ) { [weak self] note in
            guard let self,
                  let raw = note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
                  let type = AVAudioSession.InterruptionType(rawValue: raw)
            else { return }
            if type == .began {
                self.kernel.events.push(.allOff(dest: .synth))
                self.kernel.events.push(.allOff(dest: .sampler))
            } else if type == .ended {
                let rawOptions =
                    note.userInfo?[AVAudioSessionInterruptionOptionKey] as? UInt ?? 0
                let options = AVAudioSession.InterruptionOptions(rawValue: rawOptions)
                if options.contains(.shouldResume), !self.applicationSuspended {
                    self.start()
                }
            }
        }
        center.addObserver(
            forName: AVAudioSession.mediaServicesWereResetNotification, object: nil, queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            // The old engine (and its nodes) are dead after a reset; rebuild.
            self.engine = AVAudioEngine()
            self.buildGraph()
            if !self.applicationSuspended { self.start() }
        }
    }

    /// Decode an audio file into the user sample slot (mono, kernel rate) —
    /// the port of sampler.ts decodeFile.
    func loadUserSample(url: URL) throws -> String {
        let secured = url.startAccessingSecurityScopedResource()
        defer { if secured { url.stopAccessingSecurityScopedResource() } }

        let byteCount = try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize
        if let byteCount, byteCount > 50 * 1024 * 1024 {
            throw NSError(
                domain: "expressionpad", code: 6,
                userInfo: [NSLocalizedDescriptionKey: "Sample files must be 50 MB or smaller."]
            )
        }
        let file = try AVAudioFile(forReading: url)
        let inFormat = file.processingFormat
        let duration = Double(file.length) / inFormat.sampleRate
        guard file.length > 0, duration.isFinite, duration <= 30 else {
            throw NSError(
                domain: "expressionpad", code: 4,
                userInfo: [NSLocalizedDescriptionKey: "Samples must contain audio and be 30 seconds or shorter."]
            )
        }
        let frames = AVAudioFrameCount(file.length)
        guard let inBuf = AVAudioPCMBuffer(pcmFormat: inFormat, frameCapacity: frames) else {
            throw NSError(domain: "expressionpad", code: 1)
        }
        try file.read(into: inBuf)

        let outFormat = AVAudioFormat(
            standardFormatWithSampleRate: kernel.sampleRate, channels: 1
        )!
        var mono: [Float]
        if inFormat.sampleRate == outFormat.sampleRate {
            mono = mixdown(inBuf)
        } else {
            guard let converter = AVAudioConverter(from: inFormat, to: outFormat) else {
                throw NSError(domain: "expressionpad", code: 2)
            }
            let ratio = outFormat.sampleRate / inFormat.sampleRate
            let outFrames = AVAudioFrameCount(Double(frames) * ratio) + 1024
            guard let outBuf = AVAudioPCMBuffer(pcmFormat: outFormat, frameCapacity: outFrames) else {
                throw NSError(domain: "expressionpad", code: 3)
            }
            var fed = false
            converter.convert(to: outBuf, error: nil) { _, status in
                if fed {
                    status.pointee = .endOfStream
                    return nil
                }
                fed = true
                status.pointee = .haveData
                return inBuf
            }
            mono = mixdown(outBuf)
        }

        guard !mono.isEmpty else {
            throw NSError(domain: "expressionpad", code: 5)
        }
        let name = url.lastPathComponent
        try sampleRegistry.setUserSample(mono, name: name)
        if store.state.sampler.preset == USER_PRESET {
            sampleRegistry.select(preset: USER_PRESET, userRoot: store.state.sampler.userRoot)
        }
        return name
    }

    private func mixdown(_ buf: AVAudioPCMBuffer) -> [Float] {
        let frames = Int(buf.frameLength)
        guard let data = buf.floatChannelData, frames > 0 else { return [] }
        let channels = Int(buf.format.channelCount)
        var out = [Float](repeating: 0, count: frames)
        for c in 0..<channels {
            let ch = data[c]
            for i in 0..<frames { out[i] += ch[i] }
        }
        if channels > 1 {
            let scale = 1 / Float(channels)
            for i in 0..<frames { out[i] *= scale }
        }
        return out
    }
}
