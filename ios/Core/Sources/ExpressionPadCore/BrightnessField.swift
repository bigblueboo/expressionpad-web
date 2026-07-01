/// BrightnessField — a damped-wave ("shallow water") simulation over the key
/// lattice. Touching a key injects brightness which propagates outward to
/// neighboring keys like a disturbance on a fluid surface: a wave term carries
/// the front, a viscosity term smooths it, and damping/fade pull everything
/// back to rest. The renderer reads per-key values and lightens fills.
///
/// Distances are normalized by key size, so propagation speed is measured in
/// key-units per second and the same constants work for squares, hexes,
/// pianos, and keycap layouts alike.
import Foundation

private let K_NEIGHBORS = 8
/// Drop candidate neighbors beyond this normalized distance² (adjacent ≈ 1, diagonal ≈ 2, two-away ≈ 4).
private let MAX_ND2 = 3.0
private let WAVE_SPEED2: Float = 380 // (key-units/s)² — how fast the front travels
private let VISCOSITY: Float = 4.0 // /s — Navier-Stokes-style diffusion of velocity
private let DAMPING: Float = 4.0 // /s — velocity drag
private let FADE: Float = 1.0 // /s — brightness relaxation toward rest
private let MAX_SUBSTEP = 1.0 / 90 // explicit integration stays stable below this

public final class BrightnessField {
    private let n: Int
    private var idToIndex: [Int: Int] = [:]
    private var b: [Float]
    private var v: [Float]
    private var lapB: [Float]
    private var lapV: [Float]
    /// Neighbor graph in CSR form; weights are 1/nd², normalized per key.
    private var nStart: [Int32]
    private var nIdx: [Int32]
    private var nW: [Float]
    private var _energy: Float = 0

    public init(_ keys: [KeyShape]) {
        let n = keys.count
        self.n = n
        for (i, k) in keys.enumerated() { idToIndex[k.id] = i }
        b = [Float](repeating: 0, count: n)
        v = [Float](repeating: 0, count: n)
        lapB = [Float](repeating: 0, count: n)
        lapV = [Float](repeating: 0, count: n)

        // Symmetrized k-nearest neighbors in size-normalized space.
        var adj: [[Int: Float]] = Array(repeating: [:], count: n)
        for i in 0..<n {
            var cands: [(Double, Int)] = []
            for j in 0..<n where j != i {
                let ndx = (keys[i].cx - keys[j].cx) / ((keys[i].w + keys[j].w) / 2)
                let ndy = (keys[i].cy - keys[j].cy) / ((keys[i].h + keys[j].h) / 2)
                let nd2 = ndx * ndx + ndy * ndy
                if nd2 > 0 && nd2 <= MAX_ND2 { cands.append((nd2, j)) }
            }
            cands.sort { $0.0 < $1.0 }
            for (nd2, j) in cands.prefix(K_NEIGHBORS) {
                let w = Float(1 / nd2)
                adj[i][j] = w
                adj[j][i] = w
            }
        }
        let total = adj.reduce(0) { $0 + $1.count }
        nStart = [Int32](repeating: 0, count: n + 1)
        nIdx = [Int32](repeating: 0, count: total)
        nW = [Float](repeating: 0, count: total)
        var at = 0
        for i in 0..<n {
            nStart[i] = Int32(at)
            var sum: Float = 0
            for w in adj[i].values { sum += w }
            for (j, w) in adj[i] {
                nIdx[at] = Int32(j)
                nW[at] = sum > 0 ? w / sum : 0
                at += 1
            }
        }
        nStart[n] = Int32(at)
    }

    /// Inject brightness at a key (id from KeyShape.id).
    public func poke(_ keyId: Int, _ amp: Float = 1) {
        guard let i = idToIndex[keyId] else { return }
        b[i] = min(1.5, b[i] + amp)
        _energy += amp
    }

    /// Current brightness at a key, roughly -0.5..1.5 (0 = rest).
    public func get(_ keyId: Int) -> Float {
        guard let i = idToIndex[keyId] else { return 0 }
        return b[i]
    }

    /// Total motion left in the field; ~0 means the surface is still.
    public var energy: Float { _energy }

    /// Advance the simulation by dt seconds (internally substepped).
    public func step(_ dt: Double) {
        if n == 0 || dt <= 0 { return }
        var remaining = min(dt, 0.25)
        while remaining > 1e-6 {
            let h = min(remaining, MAX_SUBSTEP)
            substep(Float(h))
            remaining -= h
        }
        var e: Float = 0
        for i in 0..<n { e += abs(b[i]) + 0.05 * abs(v[i]) }
        _energy = e
    }

    private func substep(_ h: Float) {
        for i in 0..<n {
            var lb: Float = 0
            var lv: Float = 0
            for k in Int(nStart[i])..<Int(nStart[i + 1]) {
                let j = Int(nIdx[k])
                let w = nW[k]
                lb += w * (b[j] - b[i])
                lv += w * (v[j] - v[i])
            }
            lapB[i] = lb
            lapV[i] = lv
        }
        let drag = exp(-DAMPING * h)
        let fade = exp(-FADE * h)
        for i in 0..<n {
            v[i] = (v[i] + (WAVE_SPEED2 * lapB[i] + VISCOSITY * lapV[i]) * h) * drag
            b[i] = max(-2, min(2, (b[i] + v[i] * h) * fade))
        }
    }
}
