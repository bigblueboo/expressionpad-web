/**
 * PadView — renders the playing surface to a canvas and feeds pointer
 * events to a TouchTracker. Touched keys glow white; optional ripples.
 */
import { buildLayout, type Layout, type KeyShape } from '../core/layout'
import { rowOffsets, SCALES } from '../core/scales'
import { noteName } from '../core/notes'
import type { Store } from '../core/state'
import { TouchTracker } from './touch'
import { keyColors } from './colors'
import type { VoiceSink } from '../audio/sink'

interface Ripple {
  x: number
  y: number
  start: number
}

export class PadView {
  readonly canvas: HTMLCanvasElement
  readonly tracker: TouchTracker
  private ctx2d: CanvasRenderingContext2D | null
  private layout: Layout
  private ripples: Ripple[] = []
  private raf = 0
  private dpr = 1

  constructor(private store: Store, sink: VoiceSink, private container: HTMLElement) {
    this.canvas = document.createElement('canvas')
    this.canvas.className = 'pad-canvas'
    this.canvas.style.touchAction = 'none'
    container.appendChild(this.canvas)
    this.ctx2d = this.canvas.getContext('2d')
    this.layout = this.computeLayout(1, 1)
    this.tracker = new TouchTracker(
      () => this.layout,
      () => store.state.pad,
      sink,
      () => this.requestRender(),
    )
    this.bindPointer()
    store.subscribe((_s, path) => {
      if (path.startsWith('pad') || path.startsWith('appearance')) {
        if (path.startsWith('pad') && !path.includes('slide')) this.rebuild()
        this.requestRender()
      }
    })
    new ResizeObserver(() => this.resize()).observe(container)
    this.resize()
  }

  private computeLayout(width: number, height: number): Layout {
    const pad = this.store.state.pad
    return buildLayout({
      kind: pad.layout,
      rows: pad.rows,
      cols: pad.cols,
      width,
      height,
      baseNote: pad.baseNote,
      rowOffsets: rowOffsets(pad.rowTuning, pad.rows),
      scale: SCALES[pad.colScale] ?? SCALES.Chromatic,
    })
  }

  rebuild(): void {
    this.tracker.cancelAll()
    this.layout = this.computeLayout(
      this.canvas.width / this.dpr,
      this.canvas.height / this.dpr,
    )
  }

  resize(): void {
    const rect = this.container.getBoundingClientRect()
    if (rect.width === 0 || rect.height === 0) return
    this.dpr = Math.min(2.5, window.devicePixelRatio || 1)
    this.canvas.width = Math.round(rect.width * this.dpr)
    this.canvas.height = Math.round(rect.height * this.dpr)
    this.canvas.style.width = `${rect.width}px`
    this.canvas.style.height = `${rect.height}px`
    this.rebuild()
    this.requestRender()
  }

  private bindPointer(): void {
    const pos = (e: PointerEvent): [number, number] => {
      const r = this.canvas.getBoundingClientRect()
      return [e.clientX - r.left, e.clientY - r.top]
    }
    this.canvas.addEventListener('pointerdown', (e) => {
      e.preventDefault()
      this.canvas.setPointerCapture(e.pointerId)
      const [x, y] = pos(e)
      this.tracker.down(e.pointerId, x, y)
      if (this.store.state.appearance.ripples) {
        this.ripples.push({ x, y, start: performance.now() })
        this.requestRender()
      }
    })
    this.canvas.addEventListener('pointermove', (e) => {
      if (!e.buttons && e.pointerType === 'mouse') return
      const [x, y] = pos(e)
      this.tracker.move(e.pointerId, x, y)
    })
    const end = (e: PointerEvent) => {
      e.preventDefault()
      this.tracker.up(e.pointerId)
    }
    this.canvas.addEventListener('pointerup', end)
    this.canvas.addEventListener('pointercancel', end)
    this.canvas.addEventListener('contextmenu', (e) => e.preventDefault())
  }

  requestRender(): void {
    if (this.raf) return
    this.raf = requestAnimationFrame(() => {
      this.raf = 0
      this.render()
      // Keep animating while touches or ripples are live.
      if (this.tracker.active.size > 0 || this.ripples.length > 0) this.requestRender()
    })
  }

  render(): void {
    const ctx = this.ctx2d
    if (!ctx) return
    const { width, height } = this.layout.params
    ctx.setTransform(this.dpr, 0, 0, this.dpr, 0, 0)
    ctx.clearRect(0, 0, width, height)
    ctx.fillStyle = '#06080c'
    ctx.fillRect(0, 0, width, height)

    const app = this.store.state.appearance
    const activeKeyIds = new Map<number, number>() // key id → pressure
    for (const t of this.tracker.active.values()) {
      activeKeyIds.set(t.key.id, Math.max(activeKeyIds.get(t.key.id) ?? 0, t.pressure))
    }

    const opts = { brightness: app.brightness, baseNote: this.store.state.pad.baseNote }
    // Whites under blacks: draw in array order (whites first per row).
    for (const key of this.layout.keys) {
      const colors = keyColors(app.scheme, key, opts)
      const active = activeKeyIds.has(key.id)
      this.drawKey(ctx, key, colors.fill, colors.stroke, active, activeKeyIds.get(key.id) ?? 0)
      if (app.labels && key.kind !== 'black') {
        ctx.fillStyle = active ? '#10141c' : colors.label
        ctx.font = `${Math.max(9, Math.min(16, key.w * 0.22))}px 'Avenir Next Condensed', 'Arial Narrow', sans-serif`
        ctx.textAlign = 'center'
        ctx.textBaseline = 'middle'
        const labelY = key.kind === 'white' ? key.y + key.h * 0.78 : key.cy
        ctx.fillText(noteName(key.note), key.cx, labelY)
      }
    }

    this.drawRipples(ctx)
  }

  private drawKey(
    ctx: CanvasRenderingContext2D,
    key: KeyShape,
    fill: string,
    stroke: string,
    active: boolean,
    pressure: number,
  ): void {
    ctx.save()
    if (active) {
      ctx.shadowColor = 'rgba(255,255,255,0.95)'
      ctx.shadowBlur = 18 + pressure * 22
    }
    ctx.fillStyle = active ? `hsl(0, 0%, ${86 + pressure * 12}%)` : fill
    ctx.strokeStyle = active ? '#ffffff' : stroke
    ctx.lineWidth = active ? 2 : 1
    ctx.beginPath()
    if (key.poly) {
      ctx.moveTo(key.poly[0][0], key.poly[0][1])
      for (const [px, py] of key.poly.slice(1)) ctx.lineTo(px, py)
      ctx.closePath()
      // Inset hexes slightly for a grout line.
      ctx.fill()
      ctx.stroke()
    } else {
      const inset = key.kind === 'black' ? 1 : 1.5
      const r = Math.min(6, key.w * 0.08)
      roundRect(ctx, key.x + inset, key.y + inset, key.w - inset * 2, key.h - inset * 2, r)
      ctx.fill()
      ctx.stroke()
    }
    ctx.restore()
  }

  private drawRipples(ctx: CanvasRenderingContext2D): void {
    const now = performance.now()
    const DURATION = 600
    this.ripples = this.ripples.filter((r) => now - r.start < DURATION)
    for (const r of this.ripples) {
      const t = (now - r.start) / DURATION
      ctx.beginPath()
      ctx.arc(r.x, r.y, 12 + t * 70, 0, Math.PI * 2)
      ctx.strokeStyle = `rgba(255,255,255,${0.5 * (1 - t)})`
      ctx.lineWidth = 2
      ctx.stroke()
    }
  }
}

function roundRect(
  ctx: CanvasRenderingContext2D,
  x: number, y: number, w: number, h: number, r: number,
): void {
  ctx.moveTo(x + r, y)
  ctx.arcTo(x + w, y, x + w, y + h, r)
  ctx.arcTo(x + w, y + h, x, y + h, r)
  ctx.arcTo(x, y + h, x, y, r)
  ctx.arcTo(x, y, x + w, y, r)
  ctx.closePath()
}
