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
    private let tilt: MotionTiltSource
    @Environment(\.scenePhase) private var scenePhase

    init() {
        var preferences = UserDefaults.standard
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--ui-testing") {
            preferences = UserDefaults(suiteName: "expressionpad-ui-tests")!
            if ProcessInfo.processInfo.arguments.contains("--reset-state") { preferences.removeObject(forKey: STORAGE_KEY) }
        }
        #endif
        let store = Store.load(from: preferences.data(forKey: STORAGE_KEY))
        store.saver = { preferences.set($0, forKey: STORAGE_KEY) }

        let audio = AudioEngine(store: store)
        let midi = MidiCenter(store: store)

        let router = Router()
        router.add(audio.synthSink) { store.state.midi.localSound && store.state.voice == .synth }
        router.add(audio.samplerSink) { store.state.midi.localSound && store.state.voice == .sampler }
        router.add(midi.out) { store.state.midi.outEnabled }

        midi.attachInput(to: LocalVoice(store: store, synth: audio.synthSink, sampler: audio.samplerSink))

        // Device tilt feeds the kernel whenever the EXPRESSION tilt routing is
        // on. The source owns the sensor; the app only says what is wanted.
        let tilt = MotionTiltSource { audio.kernel.events.push(.param(.tilt, $0)) }
        tilt.setRequested(store.state.expr.tilt != .off)
        store.subscribe { state, path in
            if path == "expr.tilt" { tilt.setRequested(state.expr.tilt != .off) }
        }

        _store = StateObject(wrappedValue: store)
        _audio = StateObject(wrappedValue: audio)
        _midi = StateObject(wrappedValue: midi)
        self.router = router
        self.tilt = tilt
    }

    var body: some Scene {
        WindowGroup {
            RootView(store: store, audio: audio, midi: midi, router: router)
                .preferredColorScheme(store.state.appearance.theme == "system" ? nil : store.state.appearance.theme == "dark" ? .dark : .light)
                .statusBarHidden()
                .persistentSystemOverlays(.hidden)
                .onChange(of: scenePhase) { _, phase in
                    // Silence everything if the app is hidden mid-performance.
                    if phase != .active {
                        router.allOff()
                        audio.stop()
                        tilt.setApplicationActive(false)
                        store.flushSave()
                    }
                    if phase == .active {
                        audio.start()
                        tilt.setApplicationActive(true)
                    }
                }
        }
    }
}

struct RootView: View {
    @ObservedObject var store: Store
    let audio: AudioEngine
    let midi: MidiCenter
    let router: Router
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var accessibleControlsPresented = false

    var body: some View {
        GeometryReader { geometry in
            let side = geometry.size.width > 700 && geometry.size.width > geometry.size.height * 1.3
            let short = geometry.size.height < 500
            let useSheet = typeSize.isAccessibilitySize || geometry.size.width < 360
            let showPanel = store.state.ui.panelOpen && !useSheet
            VStack(spacing: short ? 7 : 12) {
                InstrumentHeader(store: store, router: router, compact: geometry.size.width < 600, short: short)
                ControlsView(store: store, audio: audio, midi: midi, router: router, tabsOnly: true, compactNavigation: useSheet, onOpenControls: { accessibleControlsPresented = true })
                let arrangement = side ? AnyLayout(HStackLayout(alignment: .top, spacing: showPanel ? 14 : 0))
                    : AnyLayout(VStackLayout(spacing: showPanel ? 8 : 0))
                arrangement {
                    if !useSheet {
                        ControlsView(store: store, audio: audio, midi: midi, router: router)
                        .frame(width: side ? (showPanel ? min(350, geometry.size.width * 0.36) : 0) : nil,
                               height: side ? nil : (showPanel ? min(330, geometry.size.height * 0.32) : 0))
                        .frame(maxHeight: side ? .infinity : nil)
                        .clipped().opacity(showPanel ? 1 : 0)
                        .allowsHitTesting(showPanel).accessibilityHidden(!showPanel)
                    }
                    VStack(spacing: 5) {
                        surfaceStrip
                        PadView(store: store, router: router)
                            .clipShape(RoundedRectangle(cornerRadius: 2))
                            .padding(5).background(Color(hex: 0x41483a), in: RoundedRectangle(cornerRadius: 6))
                            .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(Theme.keyEdge, lineWidth: 1))
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                if !typeSize.isAccessibilitySize { HStack {
                    Image(systemName: "screwdriver.fill").font(.system(size: 7)).accessibilityHidden(true)
                    Spacer()
                    Text(store.state.pad.layout.isKeyboard ? "Type to play · slide to bend" : "Touch to play · slide to bend")
                        .font(Theme.font(10)).foregroundStyle(Theme.textDim)
                    Spacer()
                    Text("EP–02").font(Theme.mono(9)).accessibilityHidden(true)
                }.foregroundStyle(Theme.textDim) }
            }
            .padding(short ? 10 : 14)
            .background(LinearGradient(colors: [Theme.caseTop, Theme.caseBottom], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Theme.keyEdge, lineWidth: 1))
            .overlay(alignment: .top) { Theme.highlight.opacity(0.7).frame(height: 1).padding(.horizontal, 12) }
            .background(RoundedRectangle(cornerRadius: 12).fill(Theme.caseBottom).shadow(color: .black.opacity(0.22), radius: 3, y: 4))
        }
        .padding(8)
        .background(Theme.bg.ignoresSafeArea())
        .sheet(isPresented: $accessibleControlsPresented) {
            NavigationStack {
                ControlsView(store: store, audio: audio, midi: midi, router: router)
                    .padding(16).background(Theme.caseBottom)
                    .navigationTitle("\(store.state.ui.tab.controlTitle) controls")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Panic") { router.panic() }.accessibilityLabel("Panic, silence all voices")
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") { accessibleControlsPresented = false }.accessibilityIdentifier("close-controls")
                        }
                    }
            }.presentationDetents([.large])
        }
        // The instrument respects the window's safe area, including the home indicator.
    }

    @ViewBuilder private var surfaceStrip: some View {
        if typeSize.isAccessibilitySize {
            HStack { themeMenu; Spacer(minLength: 0) }.frame(minHeight: 44)
        } else { standardSurfaceStrip }
    }

    private var standardSurfaceStrip: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 8) {
                surfaceTitle
                Spacer(minLength: 0)
                Text("\(store.state.pad.rows) × \(store.state.pad.cols)").font(Theme.mono(10)).foregroundStyle(Theme.textDim)
                themeMenu
            }
            HStack { surfaceTitle; Spacer(minLength: 0); themeMenu }
        }
        .frame(minHeight: 44)
        .overlay(alignment: .top) { Theme.line.frame(height: 1) }
    }

    private var surfaceTitle: some View {
        HStack(spacing: 5) {
            Circle().fill(Theme.accent).frame(width: 5, height: 5)
            Text("PLAYING SURFACE").font(Theme.fontMedium(10)).tracking(0.6).lineLimit(1)
        }.foregroundStyle(Theme.text)
    }

    private var themeMenu: some View {
        Menu {
            Picker("Theme", selection: store.binding(\.appearance.theme)) {
                Text("System").tag("system")
                Text("Light").tag("light")
                Text("Dark").tag("dark")
            }
        } label: {
            HStack(spacing: 5) {
                Text("Theme").foregroundStyle(Theme.textDim)
                Text(store.state.appearance.theme.capitalized)
                Image(systemName: "chevron.down").font(.system(size: 8, weight: .semibold))
            }.font(Theme.font(11)).foregroundStyle(Theme.text).frame(minHeight: 44)
        }.accessibilityLabel("Theme").accessibilityValue(store.state.appearance.theme.capitalized)
            .accessibilityIdentifier("theme-menu")
    }
}

private struct InstrumentHeader: View {
    @ObservedObject var store: Store
    let router: Router
    let compact: Bool
    let short: Bool
    @Environment(\.dynamicTypeSize) private var typeSize

    @ViewBuilder var body: some View {
        if typeSize.isAccessibilitySize {
            HStack {
                Menu {
                    Picker("Sound source", selection: store.binding(\.voice)) {
                        Text("Synth").tag(VoiceSource.synth)
                        Text("Sampler").tag(VoiceSource.sampler)
                    }
                } label: {
                    HStack { Text(store.state.voice == .synth ? "Synth" : "Sampler"); Image(systemName: "chevron.down") }
                        .font(Theme.font(12)).foregroundStyle(Theme.text).frame(minHeight: 44)
                }.accessibilityLabel("Sound source")
                    .accessibilityValue("\(store.state.voice.rawValue), root \(noteName(store.state.pad.baseNote, withOctave: true))")
                Spacer(minLength: 8)
                panic
            }
        } else { standardHeader }
    }

    @ViewBuilder private var standardHeader: some View {
        let arrangement = compact ? AnyLayout(VStackLayout(spacing: 12)) : AnyLayout(HStackLayout(spacing: 20))
        arrangement {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 7) {
                        Rectangle().fill(Theme.accent).frame(width: 12, height: 21)
                        Text("expressionPad").font(Theme.fontMedium(short ? 24 : 28)).dynamicTypeSize(.large).tracking(-1.2).lineLimit(1).minimumScaleFactor(0.75)
                    }
                    if !short && !typeSize.isAccessibilitySize { Text("EP–02  /  CONTINUOUS TOUCH INSTRUMENT").font(Theme.mono(8)).foregroundStyle(Theme.textDim).lineLimit(1) }
                }.foregroundStyle(Theme.text)
                Spacer(minLength: 4)
                if compact { panic }
            }
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    caption("ROOT")
                    Text(noteName(store.state.pad.baseNote, withOctave: true)).font(Theme.mono(24)).foregroundStyle(Color(hex: 0xf1a66c))
                }
                Menu {
                    Picker("Sound source", selection: store.binding(\.voice)) {
                        Text("Synth").tag(VoiceSource.synth)
                        Text("Sampler").tag(VoiceSource.sampler)
                    }
                } label: {
                    VStack(alignment: .leading, spacing: 6) {
                        caption("VOICE")
                        HStack(spacing: 6) {
                            Text(store.state.voice == .synth ? "Synth" : "Sampler")
                            Image(systemName: "chevron.down").font(.system(size: 8))
                        }.font(Theme.mono(11))
                    }.frame(minHeight: 44)
                }.accessibilityLabel("Sound source").accessibilityValue(store.state.voice.rawValue)
                Spacer(minLength: 0)
                VStack(alignment: .leading, spacing: 6) {
                    caption(store.state.midi.localSound ? "SOUND" : "LOCAL SOUND OFF")
                    Text(store.state.voice == .synth ? store.state.synth.preset : store.state.sampler.preset)
                        .font(Theme.mono(11)).lineLimit(1).minimumScaleFactor(0.8)
                }
            }
            .foregroundStyle(Theme.screenInk).padding(.horizontal, 12).padding(.vertical, short ? 4 : 8)
            .background(LinearGradient(colors: [Color(hex: 0x343b30), Color(hex: 0x222823)], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 4))
            .overlay(RoundedRectangle(cornerRadius: 4).strokeBorder(Color(hex: 0x59614f), lineWidth: 3))
            .frame(maxWidth: compact ? .infinity : 390)
            if !compact { panic }
        }
    }
    private func caption(_ text: String) -> some View {
        Text(text).font(Theme.font(9)).tracking(1).foregroundStyle(Color(hex: 0xb0baa0))
    }
    private var panic: some View {
        Button { router.panic() } label: {
            Text("PANIC").font(Theme.fontMedium(10)).tracking(0.6).padding(.horizontal, 12).frame(minHeight: 44)
        }.buttonStyle(InstrumentButtonStyle(selected: true))
            .accessibilityLabel("Panic, silence all voices").accessibilityIdentifier("panic")
    }
}
