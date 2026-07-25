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
    private var destinationsById: [String: MIDIEndpointRef] = [:]

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
        network.connectionPolicy = .hostsInContactList

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
        out.sender = { [weak self] words, destinationId in
            self?.sendWords(words, destinationId: destinationId)
        }
        out.destinationResolver = { [weak self] in
            guard let self, let endpoint = self.destination() else { return nil }
            return self.uniqueId(endpoint)
        }
        refreshEndpoints()

        store.subscribe { [weak self] _, path in
            if path == "midi.inEnabled" || path == "midi.inputId" {
                self?.syncInputConnection()
            }
            if path == "midi.outputId" {
                self?.out.allOff()
                self?.cachedDestination = nil
                self?.out.invalidateConfiguration()
                self?.out.configureCurrentDestination()
            }
            if path == "midi.bendRange" {
                self?.out.configureCurrentDestination()
                self?.out.refreshActiveBends()
            }
        }
    }

    /// Local voice sink for MIDI input (set by the app once engines exist).
    func attachInput(to sink: VoiceSink) {
        inSink = sink
        syncInputConnection()
    }

    func refreshEndpoints() {
        if out.hasActive { out.allOff() }
        cachedDestination = nil
        destinationsById.removeAll()
        out.invalidateConfiguration()
        var dests: [MidiEndpoint] = []
        for i in 0..<MIDIGetNumberOfDestinations() {
            let ep = MIDIGetDestination(i)
            let id = uniqueId(ep)
            destinationsById[id] = ep
            dests.append(MidiEndpoint(id: id, name: displayName(ep)))
        }
        destinations = dests
        var srcs: [MidiEndpoint] = []
        for i in 0..<MIDIGetNumberOfSources() {
            let ep = MIDIGetSource(i)
            srcs.append(MidiEndpoint(id: uniqueId(ep), name: displayName(ep)))
        }
        sources = srcs
        syncInputConnection()
        out.configureCurrentDestination()
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

    private func destination(id explicitId: String? = nil) -> MIDIEndpointRef? {
        if let explicitId, !explicitId.isEmpty {
            if let cached = destinationsById[explicitId] { return cached }
            for i in 0..<MIDIGetNumberOfDestinations() {
                let ep = MIDIGetDestination(i)
                if uniqueId(ep) == explicitId {
                    destinationsById[explicitId] = ep
                    return ep
                }
            }
            return nil
        }
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

    @discardableResult
    private func sendWords(_ words: [UInt32], destinationId: String?) -> String? {
        guard available, !words.isEmpty, let dest = destination(id: destinationId) else { return nil }
        var list = MIDIEventList()
        var packet = MIDIEventListInit(&list, ._1_0)
        for word in words {
            packet = MIDIEventListAdd(&list, MemoryLayout<MIDIEventList>.size, packet, 0, 1, [word])
        }
        guard MIDISendEventList(outPort, dest, &list) == noErr else { return nil }
        return uniqueId(dest)
    }

    // ----------------------------------------------------------- input ---

    private func syncInputConnection() {
        guard available else { return }
        releaseInputNotes()
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

    private func releaseInputNotes() {
        guard let sink = inSink else {
            noteIds.removeAll()
            return
        }
        for id in noteIds.values { sink.noteOff(id) }
        noteIds.removeAll()
    }

    private func handleMessage(_ statusByte: UInt8, _ d1: UInt8, _ d2: UInt8) {
        guard store.state.midi.inEnabled, let sink = inSink else { return }
        let status = statusByte & 0xf0
        let ch = statusByte & 0x0f
        let key = "\(ch):\(d1)"
        if status == 0x90 && d2 > 0 {
            if let previous = noteIds[key] { sink.noteOff(previous) }
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
    private struct ActiveVoice {
        var channel: Int
        var noteNum: Int
        var pitch: Double
        var destinationId: String
    }

    private let store: Store
    private let alloc = ChannelAllocator()
    private var active: [Int: ActiveVoice] = [:]
    private var configuredDestinations: [String: Int] = [:]
    var sender: (([UInt32], String?) -> String?)?
    var destinationResolver: (() -> String?)?

    var hasActive: Bool { !active.isEmpty }

    init(store: Store) {
        self.store = store
    }

    private func word(_ status: UInt8, _ d1: UInt8, _ d2: UInt8) -> UInt32 {
        (UInt32(0x2) << 28) | (UInt32(status) << 16) | (UInt32(d1) << 8) | UInt32(d2)
    }

    func noteOn(_ id: Int, _ pitch: Double, _ vel: Double) {
        if active[id] != nil { noteOff(id) }
        configureCurrentDestination()
        let allocation = alloc.acquireWithEviction(id)
        let ch = UInt8(allocation.channel)
        if let evictedId = allocation.evictedId, let stolen = active.removeValue(forKey: evictedId) {
            _ = sender?([
                word(0x80 | UInt8(stolen.channel), UInt8(stolen.noteNum), 0)
            ], stolen.destinationId)
        }
        let noteNum = Int(clamp(pitch.rounded(), 0, 127))
        let range = Double(store.state.midi.bendRange)
        let (lsb, msb) = bendBytes(pitch - Double(noteNum), range)
        let velByte = UInt8(clamp(Int((vel * 127).rounded()), 1, 127))
        guard let destinationId = sender?([
            word(0xe0 | ch, lsb, msb),
            word(0x90 | ch, UInt8(noteNum), velByte),
        ], nil) else {
            alloc.release(id)
            return
        }
        active[id] = ActiveVoice(
            channel: Int(ch), noteNum: noteNum, pitch: pitch, destinationId: destinationId
        )
    }

    func glide(_ id: Int, _ pitch: Double) {
        guard let v = active[id] else { return }
        let range = Double(store.state.midi.bendRange)
        let (lsb, msb) = bendBytes(pitch - Double(v.noteNum), range)
        _ = sender?([word(0xe0 | UInt8(v.channel), lsb, msb)], v.destinationId)
        active[id]?.pitch = pitch
    }

    func pressure(_ id: Int, _ value: Double) {
        guard let v = active[id] else { return }
        let val = UInt8(clamp(Int((value * 127).rounded()), 0, 127))
        var words = [word(0xd0 | UInt8(v.channel), val, 0)]
        if store.state.midi.sendY {
            words.append(word(0xb0 | UInt8(v.channel), 74, val))
        }
        _ = sender?(words, v.destinationId)
    }

    func noteOff(_ id: Int) {
        guard let v = active[id] else { return }
        _ = sender?([word(0x80 | UInt8(v.channel), UInt8(v.noteNum), 0)], v.destinationId)
        alloc.release(id)
        active.removeValue(forKey: id)
    }

    func allOff() {
        var destinationIds = Set(active.values.map(\.destinationId))
        for id in Array(active.keys) { noteOff(id) }
        if let current = destinationResolver?() { destinationIds.insert(current) }
        for destinationId in destinationIds {
            for ch: UInt8 in 0..<16 {
                _ = sender?([
                    word(0xb0 | ch, 64, 0),
                    word(0xb0 | ch, 120, 0),
                    word(0xb0 | ch, 123, 0),
                    word(0xe0 | ch, 0, 64),
                ], destinationId)
            }
        }
    }

    func invalidateConfiguration() {
        configuredDestinations.removeAll()
    }

    func configureCurrentDestination() {
        guard let destinationId = destinationResolver?() else { return }
        let range = clamp(store.state.midi.bendRange, 1, 96)
        guard configuredDestinations[destinationId] != range else { return }

        _ = sender?(rpn(channel: 0, msb: 0, lsb: 6, dataMsb: 15, dataLsb: 0), destinationId)
        for channel: UInt8 in 1..<16 {
            _ = sender?(
                rpn(channel: channel, msb: 0, lsb: 0, dataMsb: UInt8(range), dataLsb: 0),
                destinationId
            )
        }
        configuredDestinations[destinationId] = range
    }

    func refreshActiveBends() {
        let range = Double(store.state.midi.bendRange)
        for voice in active.values {
            let (lsb, msb) = bendBytes(voice.pitch - Double(voice.noteNum), range)
            _ = sender?([
                word(0xe0 | UInt8(voice.channel), lsb, msb)
            ], voice.destinationId)
        }
    }

    private func rpn(
        channel: UInt8, msb: UInt8, lsb: UInt8, dataMsb: UInt8, dataLsb: UInt8
    ) -> [UInt32] {
        let cc = 0xb0 | channel
        return [
            word(cc, 101, msb),
            word(cc, 100, lsb),
            word(cc, 6, dataMsb),
            word(cc, 38, dataLsb),
            word(cc, 101, 127),
            word(cc, 100, 127),
        ]
    }
}
