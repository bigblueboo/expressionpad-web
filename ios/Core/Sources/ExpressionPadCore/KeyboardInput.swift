/// KeyboardInput — plays the pad from a typing keyboard (iPad hardware
/// keyboards via pressesBegan/Ended). Keydown/keyup on a key mapped by the
/// current layout (the kbd-* layouts assign key-code names to keycaps)
/// synthesize touches at the keycap center, so keyboard notes get the same
/// voicing, glow, and ripples as fingers. Other layouts assign no codes, so
/// typing is inert there.
import Foundation

public let KEYBOARD_VOICE_ID_BASE = 2_000_000

public final class KeyboardInput {
    public private(set) var active: [String: Int] = [:]
    private var nextId = KEYBOARD_VOICE_ID_BASE

    private let getLayout: () -> Layout
    private let tracker: TouchTracker

    public init(getLayout: @escaping () -> Layout, tracker: TouchTracker) {
        self.getLayout = getLayout
        self.tracker = tracker
    }

    /// `code` uses KeyboardEvent.code names ("KeyZ", "Digit1", …).
    public func keyDown(_ code: String) {
        guard let key = getLayout().keys.first(where: { $0.code == code }) else { return }
        if let stale = active[code] { tracker.up(stale) }
        nextId += 1
        active[code] = nextId
        tracker.down(nextId, key.cx, key.cy)
    }

    public func keyUp(_ code: String) {
        guard let id = active[code] else { return }
        active.removeValue(forKey: code)
        tracker.up(id)
    }

    public func releaseAll() {
        for id in active.values { tracker.up(id) }
        active.removeAll()
    }
}
