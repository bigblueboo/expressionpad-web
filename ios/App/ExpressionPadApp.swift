/// App entry point — the port of main.ts: build the store, engines, router,
/// MIDI, and compose the UI.
import SwiftUI
import ExpressionPadCore

private let STORAGE_KEY = "expressionpad-state-v1"

/// MIDI in drives whichever local voice is active (never MIDI out — no echo).
private final class LocalVoice: VoiceSink {
    let store: Store
    let synth: VoiceSink
    let sampler: VoiceSink

    init(store: Store, synth: VoiceSink, sampler: VoiceSink) {
        self.store = store
        self.synth = synth
        self.sampler = sampler
    }

    private var current: VoiceSink { store.state.voice == .sampler ? sampler : synth }

    func noteOn(_ id: Int, _ pitch: Double, _ vel: Double) { current.noteOn(id, pitch, vel) }
    func glide(_ id: Int, _ pitch: Double) { current.glide(id, pitch) }
    func pressure(_ id: Int, _ value: Double) { current.pressure(id, value) }

    func noteOff(_ id: Int) {
        synth.noteOff(id)
        sampler.noteOff(id)
    }

    func allOff() {
        synth.allOff()
        sampler.allOff()
    }
}

@main
struct ExpressionPadApp: App {
    @StateObject private var store: Store
    @StateObject private var audio: AudioEngine
    @StateObject private var midi: MidiCenter
    private let router: Router
    @Environment(\.scenePhase) private var scenePhase

    init() {
        let store = Store.load(from: UserDefaults.standard.data(forKey: STORAGE_KEY))
        store.saver = { UserDefaults.standard.set($0, forKey: STORAGE_KEY) }

        let audio = AudioEngine(store: store)
        let midi = MidiCenter(store: store)

        let router = Router()
        router.add(audio.synthSink) { store.state.midi.localSound && store.state.voice == .synth }
        router.add(audio.samplerSink) { store.state.midi.localSound && store.state.voice == .sampler }
        router.add(midi.out) { store.state.midi.outEnabled }

        midi.attachInput(to: LocalVoice(store: store, synth: audio.synthSink, sampler: audio.samplerSink))

        _store = StateObject(wrappedValue: store)
        _audio = StateObject(wrappedValue: audio)
        _midi = StateObject(wrappedValue: midi)
        self.router = router
    }

    var body: some Scene {
        WindowGroup {
            RootView(store: store, audio: audio, midi: midi, router: router)
                .preferredColorScheme(.dark)
                .statusBarHidden()
                .persistentSystemOverlays(.hidden)
                .onChange(of: scenePhase) { _, phase in
                    // Silence everything if the app is hidden mid-performance.
                    if phase == .background {
                        router.allOff()
                        audio.stop()
                        store.flushSave()
                    }
                    if phase == .active { audio.start() }
                }
        }
    }
}

struct RootView: View {
    @ObservedObject var store: Store
    let audio: AudioEngine
    let midi: MidiCenter
    let router: Router

    var body: some View {
        VStack(spacing: 0) {
            ControlsView(store: store, audio: audio, midi: midi, router: router)
            PadView(store: store, router: router)
        }
        .background(Theme.bg)
        .ignoresSafeArea(.container, edges: .bottom)
    }
}
