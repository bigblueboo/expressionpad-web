/**
 * BrightnessField — a damped-wave ("shallow water") simulation over the key
 * lattice. Touching a key injects brightness which propagates outward to
 * neighboring keys like a disturbance on a fluid surface: a wave term carries
 * the front, a viscosity term smooths it, and damping/fade pull everything
 * back to rest. The renderer reads per-key values and lightens fills.
 *
 * Distances are normalized by key size, so propagation speed is measured in
 * key-units per second and the same constants work for squares, hexes,
 * pianos, and keycap layouts alike.
 */
import type { KeyShape } from '../core/layout'

const K_NEIGHBORS = 8
/** Drop candidate neighbors beyond this normalized distance² (adjacent ≈ 1, diagonal ≈ 2, two-away ≈ 4). */
const MAX_ND2 = 3.0
const WAVE_SPEED2 = 380 // (key-units/s)² — how fast the front travels
const VISCOSITY = 4.0 // /s — Navier-Stokes-style diffusion of velocity
const DAMPING = 4.0 // /s — velocity drag
const FADE = 1.0 // /s — brightness relaxation toward rest
const MAX_SUBSTEP = 1 / 90 // explicit integration stays stable below this

export class BrightnessField {
  private readonly n: number
  private readonly idToIndex = new Map<number, number>()
  private b: Float32Array
  private v: Float32Array
  private lapB: Float32Array
  private lapV: Float32Array
  /** Neighbor graph in CSR form; weights are 1/nd², normalized per key. */
  private nStart: Int32Array
  private nIdx: Int32Array
  private nW: Float32Array
  private _energy = 0

  constructor(keys: KeyShape[]) {
    const n = (this.n = keys.length)
    keys.forEach((k, i) => this.idToIndex.set(k.id, i))
    this.b = new Float32Array(n)
    this.v = new Float32Array(n)
    this.lapB = new Float32Array(n)
    this.lapV = new Float32Array(n)

    // Symmetrized k-nearest neighbors in size-normalized space.
    const adj: Array<Map<number, number>> = Array.from({ length: n }, () => new Map())
    for (let i = 0; i < n; i++) {
      const cands: Array<[number, number]> = []
      for (let j = 0; j < n; j++) {
        if (j === i) continue
        const ndx = (keys[i].cx - keys[j].cx) / ((keys[i].w + keys[j].w) / 2)
        const ndy = (keys[i].cy - keys[j].cy) / ((keys[i].h + keys[j].h) / 2)
        const nd2 = ndx * ndx + ndy * ndy
        if (nd2 > 0 && nd2 <= MAX_ND2) cands.push([nd2, j])
      }
      cands.sort((a, b) => a[0] - b[0])
      for (const [nd2, j] of cands.slice(0, K_NEIGHBORS)) {
        const w = 1 / nd2
        adj[i].set(j, w)
        adj[j].set(i, w)
      }
    }
    const counts = adj.map((m) => m.size)
    const total = counts.reduce((a, c) => a + c, 0)
    this.nStart = new Int32Array(n + 1)
    this.nIdx = new Int32Array(total)
    this.nW = new Float32Array(total)
    let at = 0
    for (let i = 0; i < n; i++) {
      this.nStart[i] = at
      let sum = 0
      for (const w of adj[i].values()) sum += w
      for (const [j, w] of adj[i]) {
        this.nIdx[at] = j
        this.nW[at] = sum > 0 ? w / sum : 0
        at++
      }
    }
    this.nStart[n] = at
  }

  /** Inject brightness at a key (id from KeyShape.id). */
  poke(keyId: number, amp = 1): void {
    const i = this.idToIndex.get(keyId)
    if (i === undefined) return
    this.b[i] = Math.min(1.5, this.b[i] + amp)
    this._energy += amp
  }

  /** Current brightness at a key, roughly -0.5..1.5 (0 = rest). */
  get(keyId: number): number {
    const i = this.idToIndex.get(keyId)
    return i === undefined ? 0 : this.b[i]
  }

  /** Total motion left in the field; ~0 means the surface is still. */
  get energy(): number {
    return this._energy
  }

  /** Advance the simulation by dt seconds (internally substepped). */
  step(dt: number): void {
    if (this.n === 0 || dt <= 0) return
    let remaining = Math.min(dt, 0.25)
    while (remaining > 1e-6) {
      const h = Math.min(remaining, MAX_SUBSTEP)
      this.substep(h)
      remaining -= h
    }
    let e = 0
    for (let i = 0; i < this.n; i++) e += Math.abs(this.b[i]) + 0.05 * Math.abs(this.v[i])
    this._energy = e
  }

  private substep(h: number): void {
    const { b, v, lapB, lapV, nStart, nIdx, nW, n } = this
    for (let i = 0; i < n; i++) {
      let lb = 0
      let lv = 0
      for (let k = nStart[i]; k < nStart[i + 1]; k++) {
        const j = nIdx[k]
        const w = nW[k]
        lb += w * (b[j] - b[i])
        lv += w * (v[j] - v[i])
      }
      lapB[i] = lb
      lapV[i] = lv
    }
    const drag = Math.exp(-DAMPING * h)
    const fade = Math.exp(-FADE * h)
    for (let i = 0; i < n; i++) {
      v[i] = (v[i] + (WAVE_SPEED2 * lapB[i] + VISCOSITY * lapV[i]) * h) * drag
      b[i] = Math.max(-2, Math.min(2, (b[i] + v[i] * h) * fade))
    }
  }
}
