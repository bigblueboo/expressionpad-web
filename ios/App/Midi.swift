/// CoreMIDI output with MPE-style expression (each touch gets its own member
/// channel for independent bend/pressure/CC74) and a simple input that drives
/// a VoiceSink — the port of midi.ts. The original app's network session
/// comes back via MIDINetworkSession.
import CoreMIDI
import Foundation
import ExpressionPadCore

struct MidiEndpoint: Identifiable, Equatable {
    var id: String
    var name: String
}

final class MidiCenter: ObservableObject {
    let store: Store

    private var client = MIDIClientRef()
    private var outPort = MIDIPortRef()
    private var inPort = MIDIPortRef()
    private var connectedSource: MIDIEndpointRef = 0
    /// Resolved output endpoint, so per-message sends (glides run at 120 Hz)
    /// don't re-enumerate CoreMIDI. Cleared on device or selection changes.
    private var cachedDestination: MIDIEndpointRef?

    @Published private(set) var destinations: [MidiEndpoint] = []
    @Published private(set) var sources: [MidiEndpoint] = []
    private(set) var available = false

    let out: MidiOut
    private var inSink: VoiceSink?

    init(store: Store) {
        self.store = store
        out = MidiOut(store: store)

        // CoreMIDI network session — the original's Session/IP group.
        let network = MIDINetworkSession.default()
        network.isEnabled = true
        network.connectionPolicy = .anyone

        var clientRef = MIDIClientRef()
        let status = MIDIClientCreateWithBlock("expressionPad" as CFString, &clientRef) { [weak self] _ in
            DispatchQueue.main.async { self?.refreshEndpoints() }
        }
        guard status == noErr else { return }
        client = clientRef
        available = true

        MIDIOutputPortCreate(client, "expressionPad out" as CFString, &outPort)
        MIDIInputPortCreateWithProtocol(client, "expressionPad in" as CFString, ._1_0, &inPort) {
            [weak self] eventList, _ in
            self?.handleEventList(eventList)
        }
        out.sender = { [weak self] words in self?.sendWords(words) }
        refreshEndpoints()

        store.subscribe { [weak self] _, path in
            if path == "midi.inEnabled" || path == "midi.inputId" {
                self?.syncInputConnection()
            }
            if path == "midi.outputId" {
                self?.cachedDestination = nil
            }
        }
    }

    /// Local voice sink for MIDI input (set by the app once engines exist).
    func attachInput(to sink: VoiceSink) {
        inSink = sink
        syncInputConnection()
    }

    func refreshEndpoints() {
        cachedDestination = nil
        var dests: [MidiEndpoint] = []
        for i in 0..<MIDIGetNumberOfDestinations() {
            let ep = MIDIGetDestination(i)
            dests.append(MidiEndpoint(id: uniqueId(ep), name: displayName(ep)))
        }
        destinations = dests
        var srcs: [MidiEndpoint] = []
        for i in 0..<MIDIGetNumberOfSources() {
            let ep = MIDIGetSource(i)
            srcs.append(MidiEndpoint(id: uniqueId(ep), name: displayName(ep)))
        }
        sources = srcs
        syncInputConnection()
    }

    private func displayName(_ ep: MIDIEndpointRef) -> String {
        var name: Unmanaged<CFString>?
        MIDIObjectGetStringProperty(ep, kMIDIPropertyDisplayName, &name)
        return name?.takeRetainedValue() as String? ?? "MIDI \(ep)"
    }

    private func uniqueId(_ ep: MIDIEndpointRef) -> String {
        var uid: Int32 = 0
        MIDIObjectGetIntegerProperty(ep, kMIDIPropertyUniqueID, &uid)
        return String(uid)
    }

    private func destination() -> MIDIEndpointRef? {
        if let cached = cachedDestination { return cached == 0 ? nil : cached }
        let wanted = store.state.midi.outputId
        var found: MIDIEndpointRef?
        for i in 0..<MIDIGetNumberOfDestinations() {
            let ep = MIDIGetDestination(i)
            if found == nil { found = ep }
            if !wanted.isEmpty && uniqueId(ep) == wanted {
                found = ep
                break
            }
        }
        cachedDestination = found ?? 0 // cache the miss too
        return found
    }

    private func sendWords(_ words: [UInt32]) {
        guard available, let dest = destination() else { return }
        var list = MIDIEventList()
        var packet = MIDIEventListInit(&list, ._1_0)
        for word in words {
            packet = MIDIEventListAdd(&list, MemoryLayout<MIDIEventList>.size, packet, 0, 1, [word])
        }
        MIDISendEventList(outPort, dest, &list)
    }

    // ----------------------------------------------------------- input ---

    private func syncInputConnection() {
        guard available else { return }
        if connectedSource != 0 {
            MIDIPortDisconnectSource(inPort, connectedSource)
            connectedSource = 0
        }
        guard store.state.midi.inEnabled else { return }
        let wanted = store.state.midi.inputId
        var chosen: MIDIEndpointRef = 0
        for i in 0..<MIDIGetNumberOfSources() {
            let ep = MIDIGetSource(i)
            if chosen == 0 { chosen = ep }
            if !wanted.isEmpty && uniqueId(ep) == wanted { chosen = ep }
        }
        guard chosen != 0 else { return }
        if MIDIPortConnectSource(inPort, chosen, nil) == noErr {
            connectedSource = chosen
        }
    }

    private func handleEventList(_ eventList: UnsafePointer<MIDIEventList>) {
        // Parse MIDI 1.0-protocol UMP words (mt == 2) into status/d1/d2.
        var messages: [(UInt8, UInt8, UInt8)] = []
        for packet in eventList.unsafeSequence() {
            for word in packet.words() where (word >> 28) & 0xf == 0x2 {
                messages.append((
                    UInt8((word >> 16) & 0xff),
                    UInt8((word >> 8) & 0x7f),
                    UInt8(word & 0x7f)
                ))
            }
        }
        guard !messages.isEmpty else { return }
        DispatchQueue.main.async { [weak self] in
            for (status, d1, d2) in messages {
                self?.handleMessage(status, d1, d2)
            }
        }
    }

    private static let MIDI_IN_VOICE_ID_BASE = 1_000_000 // clear of touch ids, like the web build
    private var noteIds: [String: Int] = [:]
    private var nextInVoiceId = MidiCenter.MIDI_IN_VOICE_ID_BASE

    private func handleMessage(_ statusByte: UInt8, _ d1: UInt8, _ d2: UInt8) {
        guard store.state.midi.inEnabled, let sink = inSink else { return }
        let status = statusByte & 0xf0
        let ch = statusByte & 0x0f
        let key = "\(ch):\(d1)"
        if status == 0x90 && d2 > 0 {
            nextInVoiceId += 1
            noteIds[key] = nextInVoiceId
            sink.noteOn(nextInVoiceId, Double(d1), Double(d2) / 127)
        } else if status == 0x80 || (status == 0x90 && d2 == 0) {
            if let id = noteIds[key] {
                sink.noteOff(id)
                noteIds.removeValue(forKey: key)
            }
        }
    }
}

/// MPE-style MIDI out implementing VoiceSink — the port of midi.ts MidiOut.
/// Bytes become MIDI 1.0-protocol UMP words handed to MidiCenter's sender.
final class MidiOut: VoiceSink {
    private let store: Store
    private let alloc = ChannelAllocator()
    private var active: [Int: (channel: Int, noteNum: Int)] = [:]
    var sender: (([UInt32]) -> Void)?

    init(store: Store) {
        self.store = store
    }

    private func word(_ status: UInt8, _ d1: UInt8, _ d2: UInt8) -> UInt32 {
        (UInt32(0x2) << 28) | (UInt32(status) << 16) | (UInt32(d1) << 8) | UInt32(d2)
    }

    func noteOn(_ id: Int, _ pitch: Double, _ vel: Double) {
        let ch = UInt8(alloc.acquire(id))
        let noteNum = Int(clamp(pitch.rounded(), 0, 127))
        let range = Double(store.state.midi.bendRange)
        let (lsb, msb) = bendBytes(pitch - Double(noteNum), range)
        let velByte = UInt8(clamp(Int((vel * 127).rounded()), 1, 127))
        sender?([
            word(0xe0 | ch, lsb, msb),
            word(0x90 | ch, UInt8(noteNum), velByte),
        ])
        active[id] = (Int(ch), noteNum)
    }

    func glide(_ id: Int, _ pitch: Double) {
        guard let v = active[id] else { return }
        let range = Double(store.state.midi.bendRange)
        let (lsb, msb) = bendBytes(pitch - Double(v.noteNum), range)
        sender?([word(0xe0 | UInt8(v.channel), lsb, msb)])
    }

    func pressure(_ id: Int, _ value: Double) {
        guard let v = active[id] else { return }
        let val = UInt8(clamp(Int((value * 127).rounded()), 0, 127))
        var words = [word(0xd0 | UInt8(v.channel), val, 0)]
        if store.state.midi.sendY {
            words.append(word(0xb0 | UInt8(v.channel), 74, val))
        }
        sender?(words)
    }

    func noteOff(_ id: Int) {
        guard let v = active[id] else { return }
        sender?([word(0x80 | UInt8(v.channel), UInt8(v.noteNum), 0)])
        alloc.release(id)
        active.removeValue(forKey: id)
    }

    func allOff() {
        for id in Array(active.keys) { noteOff(id) }
        var words: [UInt32] = []
        for ch: UInt8 in 0..<16 { words.append(word(0xb0 | ch, 123, 0)) }
        sender?(words)
    }
}
