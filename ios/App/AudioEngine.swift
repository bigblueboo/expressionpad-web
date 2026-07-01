/// AVAudioEngine glue: an AVAudioSourceNode pulls the SynthKernel on the
/// audio I/O thread; AVAudioSession is tuned for low latency (5 ms buffers,
/// 48 kHz). Everything the kernel needs arrives through the lock-free ring.
import AVFoundation
import ExpressionPadCore

final class AudioEngine: ObservableObject {
    let store: Store
    let kernel: SynthKernel
    let bridge: StoreKernelBridge
    let synthSink: KernelVoiceSink
    let samplerSink: KernelVoiceSink

    private let engine = AVAudioEngine()
    private var sourceNode: AVAudioSourceNode?
    private(set) var running = false

    init(store: Store) {
        self.store = store

        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setPreferredSampleRate(48000)
            // ~240 frames @48 kHz. The web build's AudioContext 'interactive'
            // hint typically lands at 128–256 frames; this matches or beats it.
            try session.setPreferredIOBufferDuration(0.005)
            try session.setActive(true)
        } catch {
            // Session config failure is non-fatal; the engine still runs with defaults.
        }

        let sampleRate = session.sampleRate > 0 ? session.sampleRate : 48000
        kernel = SynthKernel(sampleRate: sampleRate)
        bridge = StoreKernelBridge(store: store, ring: kernel.events, sampleRate: sampleRate)
        synthSink = KernelVoiceSink(ring: kernel.events, dest: .synth)
        samplerSink = KernelVoiceSink(ring: kernel.events, dest: .sampler)

        start()
        observeSession()
    }

    var sampleRegistry: SampleRegistry { bridge.registry }

    /// Touch-to-sound estimate shown in the MIDI tab, like the web build.
    var latencyMs: Int {
        let session = AVAudioSession.sharedInstance()
        return Int(((session.outputLatency + session.ioBufferDuration) * 1000).rounded())
    }

    func start() {
        guard !running else { return }
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
            else { return noErr }
            kernel.render(frames: Int(frameCount), outL: l, outR: r)
            return noErr
        }
        engine.attach(node)
        engine.connect(node, to: engine.mainMixerNode, format: format)
        sourceNode = node
        do {
            try engine.start()
            running = true
        } catch {
            running = false
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
                try? AVAudioSession.sharedInstance().setActive(true)
                if !self.engine.isRunning { try? self.engine.start() }
            }
        }
        center.addObserver(
            forName: AVAudioSession.mediaServicesWereResetNotification, object: nil, queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            try? AVAudioSession.sharedInstance().setActive(true)
            self.running = false
            self.start()
        }
    }

    /// Decode an audio file into the user sample slot (mono, kernel rate) —
    /// the port of sampler.ts decodeFile.
    func loadUserSample(url: URL) throws -> String {
        let secured = url.startAccessingSecurityScopedResource()
        defer { if secured { url.stopAccessingSecurityScopedResource() } }

        let file = try AVAudioFile(forReading: url)
        let inFormat = file.processingFormat
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

        let name = url.lastPathComponent
        sampleRegistry.setUserSample(mono, name: name)
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
