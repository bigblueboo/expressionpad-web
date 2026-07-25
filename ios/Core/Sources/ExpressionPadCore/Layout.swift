/// Layout engine: builds key geometry for the square grid, hexagon grid, and
/// stacked-piano layouts, and answers hit-tests and continuous-pitch queries.
///
/// Coordinate system: (0,0) top-left, y grows downward (canvas convention).
/// Row 0 is the BOTTOM row (lowest pitch), matching the original app.
import Foundation

public enum LayoutKind: String, Codable, CaseIterable, Sendable {
    case square
    case hex
    case piano
    case kbdChromatic = "kbd-chromatic"
    case kbdPiano = "kbd-piano"

    public var isKeyboard: Bool { self == .kbdChromatic || self == .kbdPiano }
}

public enum KeyKind: Sendable {
    case rect, hex, white, black
}

public struct KeyShape: Sendable {
    public var id: Int
    /// MIDI note number.
    public var note: Int
    public var row: Int
    public var col: Int
    public var kind: KeyKind
    /// Bounding box.
    public var x: Double
    public var y: Double
    public var w: Double
    public var h: Double
    /// Center.
    public var cx: Double
    public var cy: Double
    /// Polygon outline for hexes.
    public var poly: [SIMD2<Double>]?
    /// Hardware key code (KeyboardEvent.code names) that triggers this key.
    public var code: String?
    /// Printed keycap character, shown as a corner label.
    public var char: String?
    /// Visual inset override for the renderer.
    public var inset: Double?
}

public struct LayoutParams: Sendable {
    public var kind: LayoutKind
    public var rows: Int
    public var cols: Int
    public var width: Double
    public var height: Double
    public var baseNote: Int
    /// Semitone offset per row, row 0 = bottom.
    public var rowOffsets: [Int]
    /// Scale step pattern for columns (ignored by piano).
    public var scale: [Int]
    /// Mirror the surface down the middle (square/hex/piano only).
    public var mirror: Bool
    /// Semitone offset applied to the mirrored (right) half.
    public var mirrorOffset: Int

    public init(
        kind: LayoutKind, rows: Int, cols: Int, width: Double, height: Double,
        baseNote: Int, rowOffsets: [Int], scale: [Int],
        mirror: Bool = false, mirrorOffset: Int = 0
    ) {
        self.kind = kind
        self.rows = rows
        self.cols = cols
        self.width = width
        self.height = height
        self.baseNote = baseNote
        self.rowOffsets = rowOffsets
        self.scale = scale
        self.mirror = mirror
        self.mirrorOffset = mirrorOffset
    }
}

public struct Layout {
    public var params: LayoutParams
    public var keys: [KeyShape]
    /// Pixel height of one row band.
    public var rowHeight: Double
    /// Set when the surface is a mirrored two-thumb split.
    public var mirrored: Bool = false
    let hitTestFn: (Double, Double) -> KeyShape?
    let pitchAtFn: (Double, Int) -> Double

    public func hitTest(_ x: Double, _ y: Double) -> KeyShape? { hitTestFn(x, y) }
    /// Continuous (fractional) MIDI pitch at horizontal position x within `row`.
    public func pitchAt(_ x: Double, _ row: Int) -> Double { pitchAtFn(x, row) }
}

let WHITE_PCS: Set<Int> = [0, 2, 4, 5, 7, 9, 11]

func noteFor(_ p: LayoutParams, _ row: Int, _ col: Int) -> Int {
    let offset = row < p.rowOffsets.count ? p.rowOffsets[row] : 0
    return p.baseNote + offset + degreeToSemitones(p.scale, col)
}

/// Piecewise-linear interpolation of pitch across a row of key centers.
func interpPitch(_ centersX: [Double], _ notes: [Double], _ x: Double) -> Double {
    let n = centersX.count
    if n == 1 { return notes[0] }
    if x <= centersX[0] {
        let slope = (notes[1] - notes[0]) / (centersX[1] - centersX[0])
        return notes[0] + (x - centersX[0]) * slope
    }
    if x >= centersX[n - 1] {
        let slope = (notes[n - 1] - notes[n - 2]) / (centersX[n - 1] - centersX[n - 2])
        return notes[n - 1] + (x - centersX[n - 1]) * slope
    }
    for i in 0..<(n - 1) where x <= centersX[i + 1] {
        let t = (x - centersX[i]) / (centersX[i + 1] - centersX[i])
        return notes[i] + t * (notes[i + 1] - notes[i])
    }
    return notes[n - 1]
}

// ---------------------------------------------------------------- square ---

func buildSquare(_ p: LayoutParams) -> Layout {
    let cellW = p.width / Double(p.cols)
    let cellH = p.height / Double(p.rows)
    var keys: [KeyShape] = []
    var id = 0
    for row in 0..<p.rows {
        let y = p.height - Double(row + 1) * cellH
        for col in 0..<p.cols {
            let x = Double(col) * cellW
            keys.append(KeyShape(
                id: id, note: noteFor(p, row, col), row: row, col: col, kind: .rect,
                x: x, y: y, w: cellW, h: cellH, cx: x + cellW / 2, cy: y + cellH / 2
            ))
            id += 1
        }
    }
    let frozenKeys = keys
    func rowPitches(_ row: Int) -> (centersX: [Double], notes: [Double]) {
        var centersX: [Double] = []
        var notes: [Double] = []
        for col in 0..<p.cols {
            centersX.append((Double(col) + 0.5) * cellW)
            notes.append(Double(noteFor(p, row, col)))
        }
        return (centersX, notes)
    }
    return Layout(
        params: p, keys: keys, rowHeight: cellH,
        hitTestFn: { x, y in
            if x < 0 || y < 0 || x >= p.width || y >= p.height { return nil }
            let row = min(p.rows - 1, max(0, p.rows - 1 - Int(floor(y / cellH))))
            let col = min(p.cols - 1, max(0, Int(floor(x / cellW))))
            return frozenKeys[row * p.cols + col]
        },
        pitchAtFn: { x, row in
            let (centersX, notes) = rowPitches(row)
            return interpPitch(centersX, notes, x)
        }
    )
}

// ------------------------------------------------------------------- hex ---

func hexPoly(_ cx: Double, _ cy: Double, _ rx: Double, _ ry: Double) -> [SIMD2<Double>] {
    var pts: [SIMD2<Double>] = []
    for i in 0..<6 {
        let a = (Double.pi / 180) * (60 * Double(i) - 30) // pointy-top
        pts.append(SIMD2(cx + rx * cos(a), cy + ry * sin(a)))
    }
    return pts
}

func buildHex(_ p: LayoutParams) -> Layout {
    // Pointy-top hexes; odd rows shift right by half a hex width. Start from
    // the largest regular hex that fits, then stretch (capped) to fill the
    // surface like the original app did.
    let rByWidth = p.width / (3.0.squareRoot() * (Double(p.cols) + 0.5))
    let rByHeight = p.height / (1.5 * Double(p.rows) + 0.5)
    let r = min(rByWidth, rByHeight)
    let MAX_STRETCH = 1.6
    let sx = min(MAX_STRETCH, rByWidth / r)
    let sy = min(MAX_STRETCH, rByHeight / r)
    let hexW = 3.0.squareRoot() * r * sx
    let ry = r * sy
    let gridW = hexW * (Double(p.cols) + 0.5)
    let gridH = ry * (1.5 * Double(p.rows) + 0.5)
    let ox = (p.width - gridW) / 2
    let oy = (p.height - gridH) / 2
    var keys: [KeyShape] = []
    var id = 0
    for row in 0..<p.rows {
        let cy = oy + gridH - (ry + 1.5 * ry * Double(row))
        let rowShift = row % 2 == 1 ? hexW / 2 : 0
        for col in 0..<p.cols {
            let cx = ox + hexW * (Double(col) + 0.5) + rowShift
            keys.append(KeyShape(
                id: id, note: noteFor(p, row, col), row: row, col: col, kind: .hex,
                x: cx - hexW / 2, y: cy - ry, w: hexW, h: 2 * ry, cx: cx, cy: cy,
                poly: hexPoly(cx, cy, hexW / 2 / (3.0.squareRoot() / 2), ry)
            ))
            id += 1
        }
    }
    let frozenKeys = keys
    return Layout(
        params: p, keys: keys, rowHeight: 1.5 * ry,
        hitTestFn: { x, y in
            // Nearest center in the unstretched lattice space is the exact
            // Voronoi cell of a hex grid, so measure distances un-scaled.
            var best: KeyShape?
            var bestD = Double.infinity
            for k in frozenKeys {
                let dx = (x - k.cx) / sx
                let dy = (y - k.cy) / sy
                if abs(dx) > 2 * r || abs(dy) > 2 * r { continue }
                let d = dx * dx + dy * dy
                if d < bestD {
                    bestD = d
                    best = k
                }
            }
            // Reject touches well outside the grid.
            if best != nil && bestD > (2 * r) * (2 * r) { return nil }
            return best
        },
        pitchAtFn: { x, row in
            var centersX: [Double] = []
            var notes: [Double] = []
            let rowShift = row % 2 == 1 ? hexW / 2 : 0
            for col in 0..<p.cols {
                centersX.append(ox + hexW * (Double(col) + 0.5) + rowShift)
                notes.append(Double(noteFor(p, row, col)))
            }
            return interpPitch(centersX, notes, x)
        }
    )
}

// ----------------------------------------------------------------- piano ---

/// White-key MIDI notes for a row: `count` white keys starting at the first white note >= base.
public func whiteNotesFrom(_ base: Int, _ count: Int) -> [Int] {
    var start = base
    while !WHITE_PCS.contains(pitchClass(start)) { start += 1 }
    var notes: [Int] = []
    var n = start
    while notes.count < count {
        if WHITE_PCS.contains(pitchClass(n)) { notes.append(n) }
        n += 1
    }
    return notes
}

func buildPiano(_ p: LayoutParams) -> Layout {
    let rowH = p.height / Double(p.rows)
    let whiteW = p.width / Double(p.cols)
    let blackW = whiteW * 0.62
    let blackH = rowH * 0.6
    var keys: [KeyShape] = []
    var blacksByRow: [[KeyShape]] = []
    var whitesByRow: [[KeyShape]] = []
    var id = 0
    for row in 0..<p.rows {
        let yTop = p.height - Double(row + 1) * rowH
        let offset = row < p.rowOffsets.count ? p.rowOffsets[row] : 0
        let whites = whiteNotesFrom(p.baseNote + offset, p.cols)
        var whiteKeys: [KeyShape] = []
        var blackKeys: [KeyShape] = []
        for col in 0..<p.cols {
            let x = Double(col) * whiteW
            whiteKeys.append(KeyShape(
                id: id, note: whites[col], row: row, col: col, kind: .white,
                x: x, y: yTop, w: whiteW, h: rowH, cx: x + whiteW / 2, cy: yTop + rowH / 2
            ))
            id += 1
        }
        for col in 0..<(p.cols - 1) where whites[col + 1] - whites[col] == 2 {
            let cx = Double(col + 1) * whiteW
            blackKeys.append(KeyShape(
                id: id, note: whites[col] + 1, row: row, col: col, kind: .black,
                x: cx - blackW / 2, y: yTop, w: blackW, h: blackH,
                cx: cx, cy: yTop + blackH / 2
            ))
            id += 1
        }
        whitesByRow.append(whiteKeys)
        blacksByRow.append(blackKeys)
        keys.append(contentsOf: whiteKeys)
        keys.append(contentsOf: blackKeys)
    }
    let frozenWhites = whitesByRow
    let frozenBlacks = blacksByRow
    return Layout(
        params: p, keys: keys, rowHeight: rowH,
        hitTestFn: { x, y in
            if x < 0 || y < 0 || x >= p.width || y >= p.height { return nil }
            let row = min(p.rows - 1, max(0, p.rows - 1 - Int(floor(y / rowH))))
            for b in frozenBlacks[row] {
                if x >= b.x && x < b.x + b.w && y >= b.y && y < b.y + b.h { return b }
            }
            let col = min(p.cols - 1, max(0, Int(floor(x / whiteW))))
            return frozenWhites[row][col]
        },
        pitchAtFn: { x, row in
            let centersX = frozenWhites[row].map { $0.cx }
            let notes = frozenWhites[row].map { Double($0.note) }
            return interpPitch(centersX, notes, x)
        }
    )
}

// -------------------------------------------------------- typing keyboard ---

public struct KbdRow: Sendable {
    public var codes: [String]
    public var chars: [String]
    /// Horizontal stagger in key units, relative to the digit row.
    public var stagger: Double
}

/// Physical rows bottom-to-top, so index matches pad row 0 = lowest pitch.
public let KBD_ROWS: [KbdRow] = [
    KbdRow(
        codes: ["KeyZ", "KeyX", "KeyC", "KeyV", "KeyB", "KeyN", "KeyM", "Comma", "Period", "Slash"],
        chars: "zxcvbnm,./".map(String.init), stagger: 1.25
    ),
    KbdRow(
        codes: ["KeyA", "KeyS", "KeyD", "KeyF", "KeyG", "KeyH", "KeyJ", "KeyK", "KeyL", "Semicolon", "Quote"],
        chars: "asdfghjkl;'".map(String.init), stagger: 0.75
    ),
    KbdRow(
        codes: ["KeyQ", "KeyW", "KeyE", "KeyR", "KeyT", "KeyY", "KeyU", "KeyI", "KeyO", "KeyP", "BracketLeft", "BracketRight"],
        chars: "qwertyuiop[]".map(String.init), stagger: 0.5
    ),
    KbdRow(
        codes: ["Digit1", "Digit2", "Digit3", "Digit4", "Digit5", "Digit6", "Digit7", "Digit8", "Digit9", "Digit0", "Minus", "Equal"],
        chars: "1234567890-=".map(String.init), stagger: 0
    ),
]

struct KbdGeom {
    var u: Double
    var cell: (Int, Int) -> (x: Double, y: Double)
}

func kbdGeometry(_ p: LayoutParams) -> KbdGeom {
    let widest = KBD_ROWS.map { $0.stagger + Double($0.codes.count) }.max()!
    let u = min(p.width / widest, p.height / Double(KBD_ROWS.count))
    let ox = (p.width - widest * u) / 2
    let oy = (p.height - Double(KBD_ROWS.count) * u) / 2
    return KbdGeom(u: u) { physRow, col in
        (
            x: ox + (KBD_ROWS[physRow].stagger + Double(col)) * u,
            y: oy + Double(KBD_ROWS.count - 1 - physRow) * u
        )
    }
}

func kbdHitAndPitch(_ keys: [KeyShape]) -> (hitTest: (Double, Double) -> KeyShape?, pitchAt: (Double, Int) -> Double) {
    (
        hitTest: { x, y in
            // Blacks (piano variant) are pushed after whites per pair; scan all,
            // last match wins so blacks take precedence within overlapping rows.
            var hit: KeyShape?
            for k in keys {
                if x >= k.x && x < k.x + k.w && y >= k.y && y < k.y + k.h { hit = k }
            }
            return hit
        },
        pitchAt: { x, row in
            let rowKeys = keys.filter { $0.row == row && $0.kind != .black }
            let centersX = rowKeys.map { $0.cx }
            let notes = rowKeys.map { Double($0.note) }
            return interpPitch(centersX, notes, x)
        }
    )
}

func buildKbdChromatic(_ p: LayoutParams) -> Layout {
    let geom = kbdGeometry(p)
    var keys: [KeyShape] = []
    var id = 0
    for row in 0..<KBD_ROWS.count {
        let krow = KBD_ROWS[row]
        for col in 0..<krow.codes.count {
            let (x, y) = geom.cell(row, col)
            keys.append(KeyShape(
                id: id, note: noteFor(p, row, col), row: row, col: col, kind: .rect,
                x: x, y: y, w: geom.u, h: geom.u, cx: x + geom.u / 2, cy: y + geom.u / 2,
                code: krow.codes[col], char: krow.chars[col], inset: geom.u * 0.05
            ))
            id += 1
        }
    }
    let (hit, pitch) = kbdHitAndPitch(keys)
    return Layout(params: p, keys: keys, rowHeight: geom.u, hitTestFn: hit, pitchAtFn: pitch)
}

func buildKbdPiano(_ p: LayoutParams) -> Layout {
    let geom = kbdGeometry(p)
    var keys: [KeyShape] = []
    var id = 0
    // Two white/black row pairs: z-row + home-row blacks, q-row + digit blacks.
    let pairs = [(white: 0, black: 1), (white: 2, black: 3)]
    for (pair, rows) in pairs.enumerated() {
        let whiteRow = KBD_ROWS[rows.white]
        let blackRow = KBD_ROWS[rows.black]
        let count = 10 // letter keys only; brackets/quote stay silent
        let offset = pair < p.rowOffsets.count ? p.rowOffsets[pair] : 0
        let whites = whiteNotesFrom(p.baseNote + offset, count)
        for col in 0..<count {
            let (x, y) = geom.cell(rows.white, col)
            keys.append(KeyShape(
                id: id, note: whites[col], row: pair, col: col, kind: .white,
                x: x, y: y, w: geom.u, h: geom.u, cx: x + geom.u / 2, cy: y + geom.u / 2,
                code: whiteRow.codes[col], char: whiteRow.chars[col], inset: geom.u * 0.05
            ))
            id += 1
        }
        for col in 0..<(count - 1) where whites[col + 1] - whites[col] == 2 {
            // The key physically above-right of white `col` sits at black index col+1.
            let idx = col + 1
            if idx >= blackRow.codes.count { continue }
            let (x, y) = geom.cell(rows.black, idx)
            keys.append(KeyShape(
                id: id, note: whites[col] + 1, row: pair, col: idx, kind: .black,
                x: x, y: y, w: geom.u, h: geom.u, cx: x + geom.u / 2, cy: y + geom.u / 2,
                code: blackRow.codes[idx], char: blackRow.chars[idx], inset: geom.u * 0.05
            ))
            id += 1
        }
    }
    let (hit, pitch) = kbdHitAndPitch(keys)
    return Layout(params: p, keys: keys, rowHeight: geom.u, hitTestFn: hit, pitchAtFn: pitch)
}

// ---------------------------------------------------------------- mirror ---

/// Two-thumb split: the left half is the base layout at half width; the right
/// half is its reflection, so both thumbs see identical geometry sweeping
/// inward, with an optional semitone offset on the mirrored side.
func buildMirror(_ p: LayoutParams) -> Layout {
    let halfW = p.width / 2
    var half = p
    half.width = halfW
    let base = buildSingle(half)
    let offset = p.mirrorOffset
    var keys = base.keys
    var twins: [Int: KeyShape] = [:] // base key id → mirrored twin
    var id = base.keys.count
    for k in base.keys {
        var twin = k
        twin.id = id
        twin.note = k.note + offset
        twin.x = p.width - (k.x + k.w)
        twin.cx = p.width - k.cx
        twin.poly = k.poly.map { $0.map { SIMD2(p.width - $0.x, $0.y) } }
        twins[k.id] = twin
        keys.append(twin)
        id += 1
    }
    let frozenTwins = twins
    // Keep reflected coordinates strictly inside the base surface so a touch
    // exactly on the seam still resolves to the innermost key.
    let reflect: (Double) -> Double = { x in min(halfW - 1e-3, max(0, p.width - x)) }
    return Layout(
        params: p, keys: keys, rowHeight: base.rowHeight, mirrored: true,
        hitTestFn: { x, y in
            if x < halfW { return base.hitTest(x, y) }
            guard let hit = base.hitTest(reflect(x), y) else { return nil }
            return frozenTwins[hit.id]
        },
        pitchAtFn: { x, row in
            if x < halfW { return base.pitchAt(x, row) }
            return base.pitchAt(reflect(x), row) + Double(offset)
        }
    )
}

func buildSingle(_ p: LayoutParams) -> Layout {
    switch p.kind {
    case .hex: return buildHex(p)
    case .piano: return buildPiano(p)
    case .kbdChromatic: return buildKbdChromatic(p)
    case .kbdPiano: return buildKbdPiano(p)
    case .square: return buildSquare(p)
    }
}

public func buildLayout(_ p: LayoutParams) -> Layout {
    if p.mirror && !p.kind.isKeyboard { return buildMirror(p) }
    return buildSingle(p)
}
