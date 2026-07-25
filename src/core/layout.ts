/**
 * Layout engine: builds key geometry for the square grid, hexagon grid, and
 * stacked-piano layouts, and answers hit-tests and continuous-pitch queries.
 *
 * Coordinate system: (0,0) top-left, y grows downward (canvas convention).
 * Row 0 is the BOTTOM row (lowest pitch), matching the original app.
 */
import { degreeToSemitones } from './scales'
import { pitchClass } from './notes'

export type LayoutKind = 'square' | 'hex' | 'piano' | 'kbd-chromatic' | 'kbd-piano'

export interface KeyShape {
  id: number
  /** MIDI note number. */
  note: number
  row: number
  col: number
  kind: 'rect' | 'hex' | 'white' | 'black'
  /** Bounding box. */
  x: number
  y: number
  w: number
  h: number
  /** Center. */
  cx: number
  cy: number
  /** Polygon outline for hexes. */
  poly?: Array<[number, number]>
  /** KeyboardEvent.code that triggers this key (keyboard layouts). */
  code?: string
  /** Printed keycap character, shown as a corner label. */
  char?: string
  /** Visual inset override for the renderer. */
  inset?: number
}

export interface LayoutParams {
  kind: LayoutKind
  rows: number
  cols: number
  width: number
  height: number
  baseNote: number
  /** Semitone offset per row, row 0 = bottom. */
  rowOffsets: number[]
  /** Scale step pattern for columns (ignored by piano). */
  scale: number[]
  /** Mirror the surface down the middle (square/hex/piano only). */
  mirror?: boolean
  /** Semitone offset applied to the mirrored (right) half. */
  mirrorOffset?: number
}

export interface Layout {
  params: LayoutParams
  keys: KeyShape[]
  hitTest(x: number, y: number): KeyShape | null
  /** Continuous (fractional) MIDI pitch at horizontal position x within `row`. */
  pitchAt(x: number, row: number): number
  /** Pixel height of one row band. */
  rowHeight: number
  /** Set when the surface is a mirrored two-thumb split. */
  mirrored?: boolean
}

const WHITE_PCS = [0, 2, 4, 5, 7, 9, 11]

function noteFor(p: LayoutParams, row: number, col: number): number {
  return p.baseNote + (p.rowOffsets[row] ?? 0) + degreeToSemitones(p.scale, col)
}

/** Piecewise-linear interpolation of pitch across a row of key centers. */
function interpPitch(centersX: number[], notes: number[], x: number): number {
  const n = centersX.length
  if (n === 1) return notes[0]
  if (x <= centersX[0]) {
    const slope = (notes[1] - notes[0]) / (centersX[1] - centersX[0])
    return notes[0] + (x - centersX[0]) * slope
  }
  if (x >= centersX[n - 1]) {
    const slope = (notes[n - 1] - notes[n - 2]) / (centersX[n - 1] - centersX[n - 2])
    return notes[n - 1] + (x - centersX[n - 1]) * slope
  }
  for (let i = 0; i < n - 1; i++) {
    if (x <= centersX[i + 1]) {
      const t = (x - centersX[i]) / (centersX[i + 1] - centersX[i])
      return notes[i] + t * (notes[i + 1] - notes[i])
    }
  }
  return notes[n - 1]
}

// ---------------------------------------------------------------- square ---

function buildSquare(p: LayoutParams): Layout {
  const cellW = p.width / p.cols
  const cellH = p.height / p.rows
  const keys: KeyShape[] = []
  let id = 0
  for (let row = 0; row < p.rows; row++) {
    const y = p.height - (row + 1) * cellH
    for (let col = 0; col < p.cols; col++) {
      const x = col * cellW
      keys.push({
        id: id++, note: noteFor(p, row, col), row, col, kind: 'rect',
        x, y, w: cellW, h: cellH, cx: x + cellW / 2, cy: y + cellH / 2,
      })
    }
  }
  const rowPitches = (row: number) => {
    const centersX: number[] = []
    const notes: number[] = []
    for (let col = 0; col < p.cols; col++) {
      centersX.push((col + 0.5) * cellW)
      notes.push(noteFor(p, row, col))
    }
    return { centersX, notes }
  }
  return {
    params: p, keys, rowHeight: cellH,
    hitTest(x, y) {
      if (x < 0 || y < 0 || x >= p.width || y >= p.height) return null
      const row = Math.min(p.rows - 1, Math.max(0, p.rows - 1 - Math.floor(y / cellH)))
      const col = Math.min(p.cols - 1, Math.max(0, Math.floor(x / cellW)))
      return keys[row * p.cols + col]
    },
    pitchAt(x, row) {
      const { centersX, notes } = rowPitches(row)
      return interpPitch(centersX, notes, x)
    },
  }
}

// ------------------------------------------------------------------- hex ---

function hexPoly(cx: number, cy: number, rx: number, ry: number): Array<[number, number]> {
  const pts: Array<[number, number]> = []
  for (let i = 0; i < 6; i++) {
    const a = (Math.PI / 180) * (60 * i - 30) // pointy-top
    pts.push([cx + rx * Math.cos(a), cy + ry * Math.sin(a)])
  }
  return pts
}

function buildHex(p: LayoutParams): Layout {
  // Pointy-top hexes; odd rows shift right by half a hex width. Start from
  // the largest regular hex that fits, then stretch (capped) to fill the
  // surface like the original app did.
  const rByWidth = p.width / (Math.sqrt(3) * (p.cols + 0.5))
  const rByHeight = p.height / (1.5 * p.rows + 0.5)
  const r = Math.min(rByWidth, rByHeight)
  const MAX_STRETCH = 1.6
  const sx = Math.min(MAX_STRETCH, rByWidth / r)
  const sy = Math.min(MAX_STRETCH, rByHeight / r)
  const hexW = Math.sqrt(3) * r * sx
  const ry = r * sy
  const gridW = hexW * (p.cols + 0.5)
  const gridH = ry * (1.5 * p.rows + 0.5)
  const ox = (p.width - gridW) / 2
  const oy = (p.height - gridH) / 2
  const keys: KeyShape[] = []
  let id = 0
  for (let row = 0; row < p.rows; row++) {
    const cy = oy + gridH - (ry + 1.5 * ry * row)
    const rowShift = row % 2 === 1 ? hexW / 2 : 0
    for (let col = 0; col < p.cols; col++) {
      const cx = ox + hexW * (col + 0.5) + rowShift
      keys.push({
        id: id++, note: noteFor(p, row, col), row, col, kind: 'hex',
        x: cx - hexW / 2, y: cy - ry, w: hexW, h: 2 * ry, cx, cy,
        poly: hexPoly(cx, cy, hexW / 2 / (Math.sqrt(3) / 2), ry),
      })
    }
  }
  return {
    params: p, keys, rowHeight: 1.5 * ry,
    hitTest(x, y) {
      // Nearest center in the unstretched lattice space is the exact
      // Voronoi cell of a hex grid, so measure distances un-scaled.
      let best: KeyShape | null = null
      let bestD = Infinity
      for (const k of keys) {
        const dx = (x - k.cx) / sx
        const dy = (y - k.cy) / sy
        if (Math.abs(dx) > 2 * r || Math.abs(dy) > 2 * r) continue
        const d = dx * dx + dy * dy
        if (d < bestD) { bestD = d; best = k }
      }
      // Reject touches well outside the grid.
      if (best && bestD > (2 * r) * (2 * r)) return null
      return best
    },
    pitchAt(x, row) {
      const centersX: number[] = []
      const notes: number[] = []
      const rowShift = row % 2 === 1 ? hexW / 2 : 0
      for (let col = 0; col < p.cols; col++) {
        centersX.push(ox + hexW * (col + 0.5) + rowShift)
        notes.push(noteFor(p, row, col))
      }
      return interpPitch(centersX, notes, x)
    },
  }
}

// ----------------------------------------------------------------- piano ---

/** White-key MIDI notes for a row: `count` white keys starting at the first white note >= base. */
export function whiteNotesFrom(base: number, count: number): number[] {
  let start = base
  while (!WHITE_PCS.includes(pitchClass(start))) start++
  const notes: number[] = []
  let n = start
  while (notes.length < count) {
    if (WHITE_PCS.includes(pitchClass(n))) notes.push(n)
    n++
  }
  return notes
}

function buildPiano(p: LayoutParams): Layout {
  const rowH = p.height / p.rows
  const whiteW = p.width / p.cols
  const blackW = whiteW * 0.62
  const blackH = rowH * 0.6
  const keys: KeyShape[] = []
  const blacksByRow: KeyShape[][] = []
  const whitesByRow: KeyShape[][] = []
  let id = 0
  for (let row = 0; row < p.rows; row++) {
    const yTop = p.height - (row + 1) * rowH
    const whites = whiteNotesFrom(p.baseNote + (p.rowOffsets[row] ?? 0), p.cols)
    const whiteKeys: KeyShape[] = []
    const blackKeys: KeyShape[] = []
    for (let col = 0; col < p.cols; col++) {
      const x = col * whiteW
      whiteKeys.push({
        id: id++, note: whites[col], row, col, kind: 'white',
        x, y: yTop, w: whiteW, h: rowH, cx: x + whiteW / 2, cy: yTop + rowH / 2,
      })
    }
    for (let col = 0; col < p.cols - 1; col++) {
      if (whites[col + 1] - whites[col] === 2) {
        const cx = (col + 1) * whiteW
        blackKeys.push({
          id: id++, note: whites[col] + 1, row, col, kind: 'black',
          x: cx - blackW / 2, y: yTop, w: blackW, h: blackH,
          cx, cy: yTop + blackH / 2,
        })
      }
    }
    whitesByRow.push(whiteKeys)
    blacksByRow.push(blackKeys)
    keys.push(...whiteKeys, ...blackKeys)
  }
  return {
    params: p, keys, rowHeight: rowH,
    hitTest(x, y) {
      if (x < 0 || y < 0 || x >= p.width || y >= p.height) return null
      const row = Math.min(p.rows - 1, Math.max(0, p.rows - 1 - Math.floor(y / rowH)))
      for (const b of blacksByRow[row]) {
        if (x >= b.x && x < b.x + b.w && y >= b.y && y < b.y + b.h) return b
      }
      const col = Math.min(p.cols - 1, Math.max(0, Math.floor(x / whiteW)))
      return whitesByRow[row][col]
    },
    pitchAt(x, row) {
      const centersX = whitesByRow[row].map((k) => k.cx)
      const notes = whitesByRow[row].map((k) => k.note)
      return interpPitch(centersX, notes, x)
    },
  }
}

// -------------------------------------------------------- typing keyboard ---

interface KbdRow {
  codes: string[]
  chars: string
  /** Horizontal stagger in key units, relative to the digit row. */
  stagger: number
}

/** Physical rows bottom-to-top, so index matches pad row 0 = lowest pitch. */
export const KBD_ROWS: KbdRow[] = [
  {
    codes: ['KeyZ', 'KeyX', 'KeyC', 'KeyV', 'KeyB', 'KeyN', 'KeyM', 'Comma', 'Period', 'Slash'],
    chars: 'zxcvbnm,./', stagger: 1.25,
  },
  {
    codes: ['KeyA', 'KeyS', 'KeyD', 'KeyF', 'KeyG', 'KeyH', 'KeyJ', 'KeyK', 'KeyL', 'Semicolon', 'Quote'],
    chars: "asdfghjkl;'", stagger: 0.75,
  },
  {
    codes: ['KeyQ', 'KeyW', 'KeyE', 'KeyR', 'KeyT', 'KeyY', 'KeyU', 'KeyI', 'KeyO', 'KeyP', 'BracketLeft', 'BracketRight'],
    chars: 'qwertyuiop[]', stagger: 0.5,
  },
  {
    codes: ['Digit1', 'Digit2', 'Digit3', 'Digit4', 'Digit5', 'Digit6', 'Digit7', 'Digit8', 'Digit9', 'Digit0', 'Minus', 'Equal'],
    chars: '1234567890-=', stagger: 0,
  },
]

interface KbdGeom {
  u: number
  cell(physRow: number, col: number): { x: number; y: number }
}

function kbdGeometry(p: LayoutParams): KbdGeom {
  const widest = Math.max(...KBD_ROWS.map((r) => r.stagger + r.codes.length))
  const u = Math.min(p.width / widest, p.height / KBD_ROWS.length)
  const ox = (p.width - widest * u) / 2
  const oy = (p.height - KBD_ROWS.length * u) / 2
  return {
    u,
    cell(physRow, col) {
      return {
        x: ox + (KBD_ROWS[physRow].stagger + col) * u,
        y: oy + (KBD_ROWS.length - 1 - physRow) * u,
      }
    },
  }
}

function kbdHitAndPitch(keys: KeyShape[]): Pick<Layout, 'hitTest' | 'pitchAt'> {
  return {
    hitTest(x, y) {
      // Blacks (piano variant) are pushed after whites per pair; scan all,
      // last match wins so blacks take precedence within overlapping rows.
      let hit: KeyShape | null = null
      for (const k of keys) {
        if (x >= k.x && x < k.x + k.w && y >= k.y && y < k.y + k.h) hit = k
      }
      return hit
    },
    pitchAt(x, row) {
      const rowKeys = keys.filter((k) => k.row === row && k.kind !== 'black')
      const centersX = rowKeys.map((k) => k.cx)
      const notes = rowKeys.map((k) => k.note)
      return interpPitch(centersX, notes, x)
    },
  }
}

function buildKbdChromatic(p: LayoutParams): Layout {
  const geom = kbdGeometry(p)
  const keys: KeyShape[] = []
  let id = 0
  for (let row = 0; row < KBD_ROWS.length; row++) {
    const krow = KBD_ROWS[row]
    for (let col = 0; col < krow.codes.length; col++) {
      const { x, y } = geom.cell(row, col)
      keys.push({
        id: id++, note: noteFor(p, row, col), row, col, kind: 'rect',
        x, y, w: geom.u, h: geom.u, cx: x + geom.u / 2, cy: y + geom.u / 2,
        code: krow.codes[col], char: krow.chars[col], inset: geom.u * 0.05,
      })
    }
  }
  return { params: p, keys, rowHeight: geom.u, ...kbdHitAndPitch(keys) }
}

function buildKbdPiano(p: LayoutParams): Layout {
  const geom = kbdGeometry(p)
  const keys: KeyShape[] = []
  let id = 0
  // Two white/black row pairs: z-row + home-row blacks, q-row + digit blacks.
  const pairs = [
    { white: 0, black: 1 },
    { white: 2, black: 3 },
  ]
  pairs.forEach(({ white, black }, pair) => {
    const whiteRow = KBD_ROWS[white]
    const blackRow = KBD_ROWS[black]
    const count = 10 // letter keys only; brackets/quote stay silent
    const whites = whiteNotesFrom(p.baseNote + (p.rowOffsets[pair] ?? 0), count)
    for (let col = 0; col < count; col++) {
      const { x, y } = geom.cell(white, col)
      keys.push({
        id: id++, note: whites[col], row: pair, col, kind: 'white',
        x, y, w: geom.u, h: geom.u, cx: x + geom.u / 2, cy: y + geom.u / 2,
        code: whiteRow.codes[col], char: whiteRow.chars[col], inset: geom.u * 0.05,
      })
    }
    for (let col = 0; col < count - 1; col++) {
      if (whites[col + 1] - whites[col] !== 2) continue
      // The key physically above-right of white `col` sits at black index col+1.
      const idx = col + 1
      if (idx >= blackRow.codes.length) continue
      const { x, y } = geom.cell(black, idx)
      keys.push({
        id: id++, note: whites[col] + 1, row: pair, col: idx, kind: 'black',
        x, y, w: geom.u, h: geom.u, cx: x + geom.u / 2, cy: y + geom.u / 2,
        code: blackRow.codes[idx], char: blackRow.chars[idx], inset: geom.u * 0.05,
      })
    }
  })
  return { params: p, keys, rowHeight: geom.u, ...kbdHitAndPitch(keys) }
}

// ---------------------------------------------------------------- mirror ---

const MIRRORABLE = new Set<LayoutKind>(['square', 'hex', 'piano'])

/**
 * Two-thumb split: the left half is the base layout at half width; the right
 * half is its reflection, so both thumbs see identical geometry sweeping
 * inward, with an optional semitone offset on the mirrored side.
 */
function buildMirror(p: LayoutParams): Layout {
  const halfW = p.width / 2
  const base = buildSingle({ ...p, width: halfW })
  const offset = p.mirrorOffset ?? 0
  const twins = new Map<number, KeyShape>() // base key id → mirrored twin
  const keys: KeyShape[] = [...base.keys]
  let id = base.keys.length
  for (const k of base.keys) {
    const twin: KeyShape = {
      ...k,
      id: id++,
      note: k.note + offset,
      x: p.width - (k.x + k.w),
      cx: p.width - k.cx,
      poly: k.poly?.map(([px, py]) => [p.width - px, py] as [number, number]),
    }
    twins.set(k.id, twin)
    keys.push(twin)
  }
  // Keep reflected coordinates strictly inside the base surface so a touch
  // exactly on the seam still resolves to the innermost key.
  const reflect = (x: number) => Math.min(halfW - 1e-3, Math.max(0, p.width - x))
  return {
    params: p, keys, rowHeight: base.rowHeight, mirrored: true,
    hitTest(x, y) {
      if (x < halfW) return base.hitTest(x, y)
      const hit = base.hitTest(reflect(x), y)
      return hit ? twins.get(hit.id)! : null
    },
    pitchAt(x, row) {
      if (x < halfW) return base.pitchAt(x, row)
      return base.pitchAt(reflect(x), row) + offset
    },
  }
}

function buildSingle(p: LayoutParams): Layout {
  switch (p.kind) {
    case 'hex': return buildHex(p)
    case 'piano': return buildPiano(p)
    case 'kbd-chromatic': return buildKbdChromatic(p)
    case 'kbd-piano': return buildKbdPiano(p)
    default: return buildSquare(p)
  }
}

export function buildLayout(p: LayoutParams): Layout {
  if (p.mirror && MIRRORABLE.has(p.kind)) return buildMirror(p)
  return buildSingle(p)
}
