/// Control panel: top tab bar (SYNTH | SMPLR | FX | PAD | MIDI) with a
/// collapse chevron, and a sliding panel of grouped controls — the port of
/// controls.ts.
import SwiftUI
import UniformTypeIdentifiers
import ExpressionPadCore

private let TABS: [(id: UiTab, label: String)] = [
    (.synth, "SYNTH"),
    (.smplr, "SMPLR"),
    (.fx, "FX"),
    (.pad, "PAD"),
    (.midi, "MIDI"),
]

struct ControlsView: View {
    @ObservedObject var store: Store
    let audio: AudioEngine
    @ObservedObject var midi: MidiCenter
    let router: Router

    var body: some View {
        VStack(spacing: 0) {
            topBar
            if store.state.ui.panelOpen {
                panel
            }
        }
        .background(Theme.topbarBg)
    }

    private var topBar: some View {
        HStack(spacing: 4) {
            Text("expressionPad")
                .font(Theme.fontMedium(15))
                .foregroundColor(Theme.accent)
                .padding(.trailing, 10)
            ForEach(TABS, id: \.id) { tab in
                tabButton(tab.id, tab.label)
            }
            Button {
                store.set(\.ui.panelOpen, !store.state.ui.panelOpen)
            } label: {
                Text("«")
                    .font(.system(size: 20))
                    .foregroundColor(Theme.accent)
                    .rotationEffect(.degrees(store.state.ui.panelOpen ? 0 : 180))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("toggle control panel")
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity)
        .background(Theme.topbarBg)
        .overlay(alignment: .bottom) { Theme.line.frame(height: 1) }
    }

    private func tabButton(_ id: UiTab, _ label: String) -> some View {
        let active = store.state.ui.tab == id && store.state.ui.panelOpen
        return Button {
            if store.state.ui.tab == id && store.state.ui.panelOpen {
                store.set(\.ui.panelOpen, false)
            } else {
                store.set(\.ui.tab, id)
                store.set(\.ui.panelOpen, true)
            }
        } label: {
            HStack(spacing: 2) {
                if active {
                    Circle().fill(Theme.accent).frame(width: 4, height: 4)
                }
                Text(label)
                    .font(Theme.font(14))
                    .tracking(1.6)
                    .foregroundColor(active ? Theme.text : Theme.textDim)
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }

    private var panel: some View {
        ScrollView(.vertical) {
            page
                .padding(.init(top: 6, leading: 8, bottom: 8, trailing: 8))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxHeight: 320)
        .background(Theme.panelBg)
        .overlay(alignment: .bottom) { Theme.line.frame(height: 1) }
    }

    @ViewBuilder private var page: some View {
        switch store.state.ui.tab {
        case .synth: SynthPage(store: store)
        case .smplr: SmplrPage(store: store, audio: audio, router: router)
        case .fx: FxPage(store: store)
        case .pad: PadPage(store: store)
        case .midi: MidiPage(store: store, audio: audio, midi: midi)
        }
    }
}

/// SYNTH/SMPLR exclusivity switch — only one local sound source at a time.
private struct VoiceGroup: View {
    @ObservedObject var store: Store

    var body: some View {
        PanelGroup(title: "VOICE") {
            SelectMenu(
                selection: store.binding(\.voice), label: "active",
                options: [(VoiceSource.synth, "Synth"), (VoiceSource.sampler, "Sampler")]
            )
        }
    }
}

// ----------------------------------------------------------------- synth ---

private struct SynthPage: View {
    @ObservedObject var store: Store

    var body: some View {
        Flow {
            PanelGroup(title: "PRESET") {
                SelectMenu(
                    selection: Binding(
                        get: { store.state.synth.preset },
                        set: { applyPreset($0, to: store) }
                    ),
                    label: "preset", options: PRESET_NAMES
                )
                Knob(value: store.binding(\.synth.level), label: "level")
            }
            VoiceGroup(store: store)
            genGroup("GENERATOR 1", \.synth.gen1)
            genGroup("GENERATOR 2", \.synth.gen2)
            PanelGroup(title: "TONE") {
                Knob(value: store.binding(\.synth.bright), label: "bright")
            }
            PanelGroup(title: "ENVELOPE") {
                Knob(value: store.binding(\.synth.env.a), label: "attack", min: 0.001, max: 2, fmt: secFmt)
                Knob(value: store.binding(\.synth.env.d), label: "decay", min: 0.01, max: 3, fmt: secFmt)
                Knob(value: store.binding(\.synth.env.s), label: "sustain")
                Knob(value: store.binding(\.synth.env.r), label: "release", min: 0.02, max: 5, fmt: secFmt)
            }
            PanelGroup(title: "FILTER") {
                Knob(value: store.binding(\.synth.filter.cutoff), label: "cutoff")
                Knob(value: store.binding(\.synth.filter.res), label: "res")
                Knob(value: store.binding(\.synth.filter.env), label: "touch")
            }
            PanelGroup(title: "LFO") {
                Knob(value: store.binding(\.synth.lfo.rate), label: "rate", min: 0.05, max: 20,
                     fmt: { String(format: "%.1fHz", $0) })
                Knob(value: store.binding(\.synth.lfo.depth), label: "depth")
                SelectMenu(
                    selection: store.binding(\.synth.lfo.target), label: "target",
                    options: [(LfoTarget.pitch, "Pitch"), (LfoTarget.filter, "Filter")]
                )
            }
        }
    }

    private func genGroup(_ title: String, _ gen: WritableKeyPath<AppState, GenConfig>) -> some View {
        PanelGroup(title: title) {
            Knob(value: store.binding(gen.appending(path: \.morph)), label: "wave")
            StepperControl(
                value: store.binding(gen.appending(path: \.semi)), label: "semi",
                min: -24, max: 24, fmt: semiFmt
            )
            Knob(value: store.binding(gen.appending(path: \.tune)), label: "tune", min: -50, max: 50,
                 fmt: { "\(Int($0.rounded()))¢" })
            Knob(value: store.binding(gen.appending(path: \.level)), label: "level")
        }
    }
}

// ----------------------------------------------------------------- smplr ---

private struct SmplrPage: View {
    @ObservedObject var store: Store
    let audio: AudioEngine
    let router: Router

    @State private var importing = false
    @State private var status = ""

    var body: some View {
        Flow {
            PanelGroup(title: "SAMPLER") {
                SelectMenu(
                    selection: store.binding(\.sampler.preset), label: "preset",
                    options: SAMPLE_NAMES + [USER_PRESET]
                )
                ActionButton(label: "load") { importing = true }
                ToggleSquare(isOn: store.binding(\.sampler.retrig), label: "retrig")
                ActionButton(label: "panic") { router.allOff() }
                Text(statusText)
                    .font(Theme.font(10))
                    .foregroundColor(Theme.textDim)
                    .frame(maxWidth: 180, alignment: .leading)
            }
            PanelGroup(title: "LEVEL") {
                Knob(value: store.binding(\.sampler.level), label: "level")
                Knob(value: store.binding(\.sampler.attack), label: "attack", min: 0.002, max: 0.5, fmt: secFmt)
                Knob(value: store.binding(\.sampler.release), label: "release", min: 0.02, max: 3, fmt: secFmt)
            }
            PanelGroup(title: "USER ROOT") {
                StepperControl(
                    value: store.binding(\.sampler.userRoot), label: "root",
                    min: 24, max: 96, fmt: { noteName($0, withOctave: true) }
                )
            }
            VoiceGroup(store: store)
        }
        .fileImporter(isPresented: $importing, allowedContentTypes: [.audio]) { result in
            switch result {
            case let .success(url):
                do {
                    let name = try audio.loadUserSample(url: url)
                    store.set(\.sampler.preset, USER_PRESET)
                    status = "Loaded: \(name)"
                } catch {
                    status = "Could not decode \(url.lastPathComponent)."
                }
            case .failure:
                break
            }
        }
    }

    private var statusText: String {
        if !status.isEmpty && store.state.sampler.preset == USER_PRESET { return status }
        if store.state.sampler.preset == USER_PRESET {
            return audio.sampleRegistry.userSampleName.map { "Loaded: \($0)" }
                ?? "No sample loaded yet."
        }
        return "Built-in instrument."
    }
}

// -------------------------------------------------------------------- fx ---

private struct FxPage: View {
    @ObservedObject var store: Store

    var body: some View {
        Flow {
            PanelGroup(title: "REVERB") {
                Knob(value: store.binding(\.fx.reverb.fdbk), label: "fdbk")
                Knob(value: store.binding(\.fx.reverb.mix), label: "mix")
                ToggleSquare(isOn: store.binding(\.fx.reverb.on), label: "on")
            }
            PanelGroup(title: "DELAY") {
                Knob(value: store.binding(\.fx.delay.time), label: "time", min: 0.02, max: 1.5, fmt: secFmt)
                Knob(value: store.binding(\.fx.delay.fdbk), label: "fdbk", min: 0, max: 0.9)
                Knob(value: store.binding(\.fx.delay.mix), label: "mix")
                ToggleSquare(isOn: store.binding(\.fx.delay.on), label: "on")
            }
            PanelGroup(title: "DISTORT") {
                Knob(value: store.binding(\.fx.distort.amt), label: "amt")
                ToggleSquare(isOn: store.binding(\.fx.distort.on), label: "on")
            }
            PanelGroup(title: "FATTEN") {
                Knob(value: store.binding(\.fx.fatten.amt), label: "fatness")
                ToggleSquare(isOn: store.binding(\.fx.fatten.on), label: "on")
            }
        }
    }
}

// ------------------------------------------------------------------- pad ---

private struct PadPage: View {
    @ObservedObject var store: Store

    var body: some View {
        Flow {
            PanelGroup(title: "PADMATRIX") {
                SelectMenu(
                    selection: store.binding(\.pad.layout), label: "layout",
                    options: [
                        (LayoutKind.square, "Square"),
                        (.hex, "Hexagon"),
                        (.piano, "Piano"),
                        (.kbdChromatic, "Keys (Chromatic)"),
                        (.kbdPiano, "Keys (Piano)"),
                    ]
                )
                SelectMenu(selection: store.binding(\.pad.rowTuning), label: "row tuning", options: ROW_TUNING_NAMES)
                StepperControl(value: store.binding(\.pad.cols), label: "cols", min: 4, max: 24)
                StepperControl(value: store.binding(\.pad.rows), label: "rows", min: 1, max: 8)
                SelectMenu(selection: store.binding(\.pad.colScale), label: "col scale", options: SCALE_NAMES)
                StepperControl(
                    value: store.binding(\.pad.baseNote), label: "base",
                    min: 12, max: 96, fmt: { noteName($0, withOctave: true) }
                )
            }
            PanelGroup(title: "TOUCH") {
                Knob(value: store.binding(\.pad.slide), label: "slide")
                ToggleSquare(isOn: store.binding(\.pad.frets), label: "frets")
                ToggleSquare(isOn: store.binding(\.pad.touchVel), label: "tch vel")
                ToggleSquare(isOn: store.binding(\.pad.aftertouch), label: "aftrtch")
            }
            PanelGroup(title: "APPEARANCE") {
                SelectMenu(selection: store.binding(\.appearance.scheme), label: "coloring", options: SCHEME_NAMES)
                ToggleSquare(isOn: store.binding(\.appearance.labels), label: "labels")
                Knob(value: store.binding(\.appearance.brightness), label: "bright")
                Knob(value: store.binding(\.appearance.contrast), label: "contrast")
                ToggleSquare(isOn: store.binding(\.appearance.ripples), label: "ripples")
                Knob(value: store.binding(\.appearance.rippleAmount), label: "ripple")
            }
        }
    }
}

// ------------------------------------------------------------------ midi ---

private struct MidiPage: View {
    @ObservedObject var store: Store
    let audio: AudioEngine
    @ObservedObject var midi: MidiCenter

    var body: some View {
        Flow {
            PanelGroup(title: "MIDI OUT") {
                ToggleSquare(isOn: store.binding(\.midi.outEnabled), label: "active")
                SelectMenu(
                    selection: store.binding(\.midi.outputId), label: "output",
                    options: portOptions(midi.destinations)
                )
                StepperControl(value: store.binding(\.midi.bendRange), label: "bend rng", min: 1, max: 96)
                ToggleSquare(isOn: store.binding(\.midi.sendY), label: "send cc74")
            }
            PanelGroup(title: "MIDI IN") {
                ToggleSquare(isOn: store.binding(\.midi.inEnabled), label: "active")
                SelectMenu(
                    selection: store.binding(\.midi.inputId), label: "input",
                    options: portOptions(midi.sources)
                )
            }
            PanelGroup(title: "SYSTEM") {
                ToggleSquare(isOn: store.binding(\.midi.localSound), label: "synth")
                Text(statusText)
                    .font(Theme.font(10))
                    .foregroundColor(Theme.textDim)
                    .frame(maxWidth: 180, alignment: .leading)
            }
        }
    }

    private func portOptions(_ ports: [MidiEndpoint]) -> [(value: String, text: String)] {
        var options: [(value: String, text: String)] = [("", ports.isEmpty ? "No devices" : "Auto")]
        options.append(contentsOf: ports.map { ($0.id, $0.name) })
        return options
    }

    private var statusText: String {
        midi.available
            ? "MIDI ready — latency \(audio.latencyMs)ms"
            : "CoreMIDI unavailable."
    }
}
