/**
 * PadView — renders the playing surface to a canvas and feeds pointer
 * events to a TouchTracker. Touched keys glow white; each new touch pokes
 * a BrightnessField whose fluid-like wave spreads across neighboring keys.
 */
import { buildLayout, type Layout, type KeyShape } from '../core/layout'
import { rowOffsets, SCALES } from '../core/scales'
import { noteName } from '../core/notes'
import type { Store } from '../core/state'
import { TouchTracker, touchesToPad } from './touch'
import { keyColors, keyMaterial, parseHsl, type KeyMaterial } from './colors'
import { BrightnessField } from './field'
import type { VoiceSink } from '../audio/sink'

/** Pad paths whose change alters key geometry and forces a layout rebuild. */
const GEOMETRY_PATHS = new Set([
  'pad.layout',
  'pad.rows',
  'pad.cols',
  'pad.rowTuning',
  'pad.colScale',
  'pad.baseNote',
  'pad.mirror',
  'pad.mirrorOffset',
])

export class PadView {
  readonly canvas: HTMLCanvasElement
  readonly tracker: TouchTracker
  private ctx2d: CanvasRenderingContext2D | null
  private layout: Layout
  private field: BrightnessField
  private accessibleKeys: HTMLDivElement
  private accessibilityNoteId = 3_000_000
  private reducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)')
  private lastFrame = performance.now()
  private lastHaptic = 0
  private raf = 0
  private dpr = 1
  private bounds: { left: number; top: number } | null = null
  private inputOffsets = new Map<number, { x: number; y: number }>()

  constructor(
    private store: Store,
    sink: VoiceSink,
    private container: HTMLElement,
  ) {
    container.tabIndex = -1
    container.setAttribute('aria-label', 'Playing surface')
    this.canvas = document.createElement('canvas')
    this.canvas.className = 'pad-canvas'
    this.canvas.style.touchAction = 'none'
    this.canvas.setAttribute('aria-hidden', 'true')
    container.appendChild(this.canvas)
    this.accessibleKeys = document.createElement('div')
    this.accessibleKeys.className = 'pad-accessible-keys'
    this.accessibleKeys.setAttribute('role', 'group')
    this.accessibleKeys.setAttribute('aria-label', 'Playable note grid')
    container.appendChild(this.accessibleKeys)
    this.ctx2d = this.canvas.getContext('2d')
    this.layout = this.computeLayout(1, 1)
    this.field = new BrightnessField(this.layout.keys)
    this.tracker = new TouchTracker({
      getLayout: () => this.layout,
      getPad: () => store.state.pad,
      sink,
      onChange: () => {
        for (const id of this.inputOffsets.keys()) {
          if (!this.tracker.active.has(id)) this.inputOffsets.delete(id)
        }
        this.requestRender()
      },
      // Every note onset drops a "pebble" whose wave spreads across the
      // lattice — at event time, so even sub-frame taps make a splash.
      onTrigger: (key) => {
        if (store.state.appearance.ripples && !this.reducedMotion.matches)
          this.field.poke(key.id, 1.3)
      },
      onFret: () => this.hapticTick(),
    })
    this.bindPointer()
    this.reducedMotion.addEventListener('change', () => {
      this.field = new BrightnessField(this.layout.keys)
      this.requestRender()
    })
    void document.fonts.ready.then(() => this.requestRender())
    store.subscribe((_s, path) => {
      if (path.startsWith('pad') || path.startsWith('appearance')) {
        // Only geometry changes rebuild (and thus cancel held touches);
        // performance knobs like slide/vib/haptic just repaint.
        if (GEOMETRY_PATHS.has(path) || path === 'pad') this.rebuild()
        if (!store.state.appearance.ripples) {
          this.field = new BrightnessField(this.layout.keys)
        }
        this.requestRender()
      }
    })
    new ResizeObserver(() => this.resize()).observe(container)
    this.resize()
  }

  get currentLayout(): Layout {
    return this.layout
  }

  private computeLayout(width: number, height: number): Layout {
    const pad = this.store.state.pad
    // Keyboard layouts have a fixed physical row count regardless of config.
    const rows = pad.layout.startsWith('kbd') ? 4 : pad.rows
    return buildLayout({
      kind: pad.layout,
      rows,
      cols: pad.cols,
      width,
      height,
      baseNote: pad.baseNote,
      rowOffsets: rowOffsets(pad.rowTuning, rows),
      scale: SCALES[pad.colScale] ?? SCALES.Chromatic,
      mirror: pad.mirror,
      mirrorOffset: pad.mirrorOffset,
    })
  }

  /** Short vibration tick on fret crossings, scaled by the HAPTIC knob. */
  private hapticTick(): void {
    const amt = this.store.state.pad.haptics
    if (amt <= 0) return
    const nav = navigator as Navigator & { vibrate?: (ms: number) => boolean }
    if (typeof nav.vibrate !== 'function') return
    const now = performance.now()
    if (now - this.lastHaptic < 40) return
    this.lastHaptic = now
    nav.vibrate(Math.max(1, Math.round(2 + amt * 10)))
  }

  rebuild(): void {
    this.tracker.cancelAll()
    this.inputOffsets.clear()
    this.layout = this.computeLayout(
      this.canvas.width / this.dpr,
      this.canvas.height / this.dpr,
    )
    this.field = new BrightnessField(this.layout.keys)
    this.rebuildAccessibility()
  }

  private rebuildAccessibility(): void {
    this.accessibleKeys.replaceChildren()
    for (const key of this.layout.keys) {
      const button = document.createElement('button')
      button.type = 'button'
      button.textContent = noteName(key.note, true)
      button.setAttribute(
        'aria-label',
        `${noteName(key.note, true)}, row ${key.row + 1}, column ${key.col + 1}`,
      )
      button.addEventListener('click', () => {
        const id = this.accessibilityNoteId++
        const current = this.layout.keys.find(
          (candidate) => candidate.id === key.id,
        )!
        this.tracker.down(id, current.cx, current.cy)
        window.setTimeout(() => this.tracker.up(id), 160)
      })
      this.accessibleKeys.appendChild(button)
    }
  }

  resize(): void {
    const rect = this.container.getBoundingClientRect()
    if (rect.width === 0 || rect.height === 0) return
    // Measure the content box: the enclosure border is outside the play area.
    const width = this.container.clientWidth
    const height = this.container.clientHeight
    if (width < 1 || height < 1) return
    this.dpr = Math.min(2.5, window.devicePixelRatio || 1)
    this.canvas.width = Math.round(width * this.dpr)
    this.canvas.height = Math.round(height * this.dpr)
    this.canvas.style.width = `${width}px`
    this.canvas.style.height = `${height}px`
    const previous = this.layout
    const before = new Map(
      [...this.tracker.active].map(([id, t]) => [id, { x: t.x, y: t.y }]),
    )
    this.layout = this.computeLayout(width, height)
    this.tracker.reflow(previous)
    const nextBounds = this.canvas.getBoundingClientRect()
    for (const [id, touch] of this.tracker.active) {
      const old = before.get(id)!
      const offset = this.inputOffsets.get(id) ?? { x: 0, y: 0 }
      // Keep a stationary finger at the same musical position when controls
      // move the canvas. Future motion remains relative to that held note.
      this.inputOffsets.set(id, {
        x:
          touch.x -
          (old.x -
            offset.x +
            (this.bounds?.left ?? nextBounds.left) -
            nextBounds.left),
        y:
          touch.y -
          (old.y -
            offset.y +
            (this.bounds?.top ?? nextBounds.top) -
            nextBounds.top),
      })
    }
    this.bounds = { left: nextBounds.left, top: nextBounds.top }
    this.field = new BrightnessField(this.layout.keys)
    if (!this.accessibleKeys.childElementCount) this.rebuildAccessibility()
    this.requestRender()
  }

  private position(id: number, x: number, y: number): [number, number] {
    const offset = this.inputOffsets.get(id)
    return [x + (offset?.x ?? 0), y + (offset?.y ?? 0)]
  }

  private bindPointer(): void {
    // Touches are handled via native touch events below: iOS Safari aligns
    // pointer events to rAF and can drop near-simultaneous pointerdowns,
    // while touch events batch every new contact in changedTouches. Pointer
    // events here serve mouse and pen only.
    const pos = (e: PointerEvent): [number, number] => {
      const r = this.canvas.getBoundingClientRect()
      return this.position(e.pointerId, e.clientX - r.left, e.clientY - r.top)
    }
    this.canvas.addEventListener('pointerdown', (e) => {
      if (e.pointerType === 'touch') return
      e.preventDefault()
      this.container.focus({ preventScroll: true })
      this.inputOffsets.delete(e.pointerId)
      this.canvas.setPointerCapture(e.pointerId)
      const [x, y] = pos(e)
      this.tracker.down(e.pointerId, x, y)
    })
    this.canvas.addEventListener('pointermove', (e) => {
      if (e.pointerType === 'touch') return
      if (!e.buttons && e.pointerType === 'mouse') return
      const [x, y] = pos(e)
      this.tracker.move(e.pointerId, x, y)
    })
    const end = (e: PointerEvent) => {
      if (e.pointerType === 'touch') return
      e.preventDefault()
      this.tracker.up(e.pointerId)
    }
    this.canvas.addEventListener('pointerup', end)
    this.canvas.addEventListener('pointercancel', end)
    this.canvas.addEventListener('contextmenu', (e) => e.preventDefault())

    // preventDefault on touchstart also tells Safari the page owns these
    // touches, suppressing its own gesture recognition where possible.
    const rect = () => this.canvas.getBoundingClientRect()
    this.canvas.addEventListener(
      'touchstart',
      (e) => {
        e.preventDefault()
        for (const t of touchesToPad(e.changedTouches, rect())) {
          this.inputOffsets.delete(t.id)
          this.tracker.down(t.id, t.x, t.y)
        }
      },
      { passive: false },
    )
    this.canvas.addEventListener(
      'touchmove',
      (e) => {
        e.preventDefault()
        for (const t of touchesToPad(e.changedTouches, rect())) {
          this.tracker.move(t.id, ...this.position(t.id, t.x, t.y))
        }
      },
      { passive: false },
    )
    const touchEnd = (e: TouchEvent) => {
      e.preventDefault()
      for (const t of touchesToPad(e.changedTouches, rect())) {
        this.tracker.up(t.id)
      }
    }
    this.canvas.addEventListener('touchend', touchEnd, { passive: false })
    this.canvas.addEventListener('touchcancel', touchEnd, { passive: false })
  }

  requestRender(): void {
    if (this.raf) return
    this.raf = requestAnimationFrame(() => {
      this.raf = 0
      this.render()
      // Keep animating while touches are live or the field is still moving.
      if (this.tracker.active.size > 0 || this.field.energy > 0.002)
        this.requestRender()
    })
  }

  render(): void {
    const ctx = this.ctx2d
    if (!ctx) return
    const { width, height } = this.layout.params
    ctx.setTransform(this.dpr, 0, 0, this.dpr, 0, 0)
    ctx.clearRect(0, 0, width, height)
    ctx.fillStyle = '#292e26'
    ctx.fillRect(0, 0, width, height)

    const app = this.store.state.appearance
    const activeKeyIds = new Map<number, number>() // key id → pressure
    for (const t of this.tracker.active.values()) {
      activeKeyIds.set(
        t.key.id,
        Math.max(activeKeyIds.get(t.key.id) ?? 0, t.pressure),
      )
    }

    // Advance the brightness field by wall-clock time (pokes happen at
    // event time in the tracker's onTrigger hook).
    const now = performance.now()
    const dt = Math.min(0.08, Math.max(0, (now - this.lastFrame) / 1000))
    this.lastFrame = now
    this.field.step(dt)

    const opts = {
      brightness: app.brightness,
      contrast: app.contrast,
      baseNote: this.store.state.pad.baseNote,
    }
    const rippleGain = 7 * app.rippleAmount
    // Whites under blacks: draw in array order (whites first per row).
    for (const key of this.layout.keys) {
      const colors = keyColors(app.scheme, key, opts)
      const active = activeKeyIds.has(key.id)
      let fill = colors.fill
      const f = this.field.get(key.id)
      if (!active && Math.abs(f) > 0.008) {
        const hsl = parseHsl(fill)
        if (hsl) {
          // Crests lighten toward white; troughs dip darker at reduced gain
          // so the rebound reads as a gentle dip, not a flicker. Crest gain
          // compensates for the wave's energy thinning as it spreads.
          const amt =
            f >= 0
              ? Math.min(1, f * rippleGain)
              : Math.max(-0.18, f * rippleGain * 0.35)
          const l = Math.max(3, Math.min(94, hsl.l + (90 - hsl.l) * amt))
          fill = `hsl(${hsl.h}, ${hsl.s}%, ${l}%)`
        }
      }
      const pressure = activeKeyIds.get(key.id) ?? 0
      const material = keyMaterial(
        active ? `hsl(29, 70%, ${77 + pressure * 8}%)` : fill,
      )
      this.drawKey(ctx, key, material, colors.stroke, active)
      if (app.labels && (key.kind !== 'black' || key.char)) {
        ctx.fillStyle = material.label
        ctx.font = `${Math.max(9, Math.min(16, key.w * 0.22))}px 'IBM Plex Sans', sans-serif`
        ctx.textAlign = 'center'
        ctx.textBaseline = 'middle'
        const labelY =
          key.kind === 'white' && !key.char ? key.y + key.h * 0.78 : key.cy
        const isRoot = (key.note - this.store.state.pad.baseNote) % 12 === 0
        const pressOffset = active ? Math.min(3, key.h * 0.07) * 0.75 : 0
        ctx.fillText(noteName(key.note, isRoot), key.cx, labelY + pressOffset)
      }
      if (app.labels && key.char) {
        ctx.save()
        ctx.globalAlpha = 1
        ctx.fillStyle = material.label
        ctx.font = `${Math.max(8, key.w * 0.16)}px 'IBM Plex Sans', sans-serif`
        ctx.textAlign = 'left'
        ctx.textBaseline = 'top'
        ctx.fillText(
          key.char,
          key.x + key.w * 0.12,
          key.y + key.h * 0.1 + (active ? Math.min(3, key.h * 0.07) * 0.75 : 0),
        )
        ctx.restore()
      }
    }

    // Mark the mirror seam so each thumb knows its half.
    if (this.layout.mirrored) {
      ctx.strokeStyle = 'rgba(233, 116, 65, 0.65)'
      ctx.lineWidth = 2
      ctx.beginPath()
      ctx.moveTo(width / 2, 0)
      ctx.lineTo(width / 2, height)
      ctx.stroke()
    }
  }

  private drawKey(
    ctx: CanvasRenderingContext2D,
    key: KeyShape,
    face: KeyMaterial,
    stroke: string,
    active: boolean,
  ): void {
    ctx.save()
    const gap = Math.min(3.5, key.w * 0.045, key.h * 0.06)
    const depth = Math.min(3, key.h * 0.07)
    const pressed = active ? depth * 0.75 : 0
    const path = (inset: number, offset: number) => {
      ctx.beginPath()
      if (key.poly) {
        const scale = Math.max(0.1, 1 - (inset * 2) / Math.min(key.w, key.h))
        key.poly.forEach(([x, y], i) => {
          const px = key.cx + (x - key.cx) * scale
          const py = key.cy + (y - key.cy) * scale + offset
          if (i === 0) ctx.moveTo(px, py)
          else ctx.lineTo(px, py)
        })
        ctx.closePath()
      } else {
        const baseInset = key.inset ?? 0
        const i = Math.max(baseInset, inset)
        const w = Math.max(0.1, key.w - i * 2)
        const h = Math.max(0.1, key.h - i * 2 - depth)
        roundRect(
          ctx,
          key.x + i,
          key.y + i + offset,
          w,
          h,
          Math.min(6, w * 0.08, h * 0.15),
        )
      }
    }
    // A dark skirt and bevel give every layout the same molded key construction.
    path(gap, depth)
    ctx.fillStyle = stroke
    ctx.fill()
    const material = ctx.createLinearGradient(
      key.x,
      key.y,
      key.x + key.w * 0.3,
      key.y + key.h,
    )
    material.addColorStop(0, face.top)
    material.addColorStop(1, face.bottom)
    path(gap, pressed)
    ctx.fillStyle = material
    ctx.fill()
    ctx.strokeStyle = active ? '#f8c497' : stroke
    ctx.lineWidth = 0.7
    ctx.stroke()
    // Fine directional highlights stay inside the face rather than glowing outside it.
    ctx.save()
    ctx.clip()
    path(gap + 0.7, pressed + 0.8)
    ctx.strokeStyle = 'rgba(255, 251, 231, 0.18)'
    ctx.lineWidth = 1
    ctx.stroke()
    ctx.restore()
    ctx.restore()
  }
}

function roundRect(
  ctx: CanvasRenderingContext2D,
  x: number,
  y: number,
  w: number,
  h: number,
  r: number,
): void {
  ctx.moveTo(x + r, y)
  ctx.arcTo(x + w, y, x + w, y + h, r)
  ctx.arcTo(x + w, y + h, x, y + h, r)
  ctx.arcTo(x, y + h, x, y, r)
  ctx.arcTo(x, y, x + w, y, r)
  ctx.closePath()
}
