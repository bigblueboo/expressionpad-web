/// MIDI math shared by the CoreMIDI layer and tests: 14-bit pitch bend and
/// the MPE rotating member-channel allocator.
import Foundation

/// 14-bit pitch bend bytes [lsb, msb] for a semitone offset within ±range.
public func bendBytes(_ semitones: Double, _ range: Double) -> (lsb: UInt8, msb: UInt8) {
    let norm = clamp(semitones / range, -1, 1)
    let value = clamp(Int((8192 + norm * 8191).rounded()), 0, 16383)
    return (UInt8(value & 0x7f), UInt8((value >> 7) & 0x7f))
}

/// Rotating member-channel allocator (channels 1–15, zero-indexed; 0 is the MPE master).
public final class ChannelAllocator {
    public struct Allocation: Equatable, Sendable {
        public var channel: Int
        public var evictedId: Int?
    }

    private var free: [Int] = []
    private var held: [(id: Int, channel: Int)] = [] // insertion-ordered

    public init(low: Int = 1, high: Int = 15) {
        for c in low...high { free.append(c) }
    }

    public func acquire(_ id: Int) -> Int {
        acquireWithEviction(id).channel
    }

    public func acquireWithEviction(_ id: Int) -> Allocation {
        if let existing = held.first(where: { $0.id == id })?.channel {
            return Allocation(channel: existing, evictedId: nil)
        }
        let stolen = free.isEmpty ? oldestHeld() : nil
        let ch = free.isEmpty ? stolen!.channel : free.removeFirst()
        held.append((id, ch))
        return Allocation(channel: ch, evictedId: stolen?.id)
    }

    @discardableResult
    public func release(_ id: Int) -> Int? {
        guard let idx = held.firstIndex(where: { $0.id == id }) else { return nil }
        let ch = held.remove(at: idx).channel
        free.append(ch) // back of the queue → maximum reuse distance
        return ch
    }

    public func channelOf(_ id: Int) -> Int? {
        held.first(where: { $0.id == id })?.channel
    }

    private func oldestHeld() -> (id: Int, channel: Int) {
        guard !held.isEmpty else { return (-1, 1) }
        return held.removeFirst()
    }
}
