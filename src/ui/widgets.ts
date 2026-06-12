/** Small DOM control widgets: knob, toggle, select, stepper — store-bound. */
import type { Store } from '../core/state'
import { clamp } from '../audio/dsp'

export interface KnobOpts {
  min?: number
  max?: number
  /** Format the readout. Default: percent. */
  fmt?: (v: number) => string
}

function el<K extends keyof HTMLElementTagNameMap>(
  tag: K,
  className: string,
  parent?: HTMLElement,
): HTMLElementTagNameMap[K] {
  const node = document.createElement(tag)
  node.className = className
  parent?.appendChild(node)
  return node
}

function labeled(label: string, child: HTMLElement): HTMLElement {
  const wrap = el('div', 'widget')
  wrap.appendChild(child)
  const lab = el('span', 'widget-label', wrap)
  lab.textContent = label
  return wrap
}

export function knob(store: Store, path: string, label: string, opts: KnobOpts = {}): HTMLElement {
  const min = opts.min ?? 0
  const max = opts.max ?? 1
  const fmt = opts.fmt ?? ((v: number) => `${Math.round(((v - min) / (max - min)) * 100)}%`)
  const initial = store.get<number>(path)

  const node = el('div', 'knob')
  node.tabIndex = 0
  node.setAttribute('role', 'slider')
  node.setAttribute('aria-label', label)
  node.setAttribute('aria-valuemin', String(min))
  node.setAttribute('aria-valuemax', String(max))
  const dial = el('div', 'knob-dial', node)
  const readout = el('span', 'knob-readout', node)

  const draw = (v: number) => {
    const t = (v - min) / (max - min)
    const deg = -135 + t * 270
    dial.style.setProperty('--angle', `${deg}deg`)
    dial.style.setProperty('--sweep', `${t * 270}deg`)
    readout.textContent = fmt(v)
    node.setAttribute('aria-valuenow', String(Math.round(v * 1000) / 1000))
  }
  draw(initial)
  store.subscribe((_s, p) => {
    if (p === path) draw(store.get<number>(path))
  })

  let dragStart: { y: number; v: number } | null = null
  node.addEventListener('pointerdown', (e) => {
    e.preventDefault()
    e.stopPropagation()
    node.setPointerCapture(e.pointerId)
    dragStart = { y: e.clientY, v: store.get<number>(path) }
  })
  node.addEventListener('pointermove', (e) => {
    if (!dragStart) return
    const scale = e.shiftKey ? 600 : 150
    const dv = ((dragStart.y - e.clientY) / scale) * (max - min)
    store.set(path, clamp(dragStart.v + dv, min, max))
  })
  const endDrag = () => (dragStart = null)
  node.addEventListener('pointerup', endDrag)
  node.addEventListener('pointercancel', endDrag)
  node.addEventListener('dblclick', () => store.set(path, initial))
  node.addEventListener('keydown', (e) => {
    const step = (max - min) / 20
    if (e.key === 'ArrowUp' || e.key === 'ArrowRight') {
      store.set(path, clamp(store.get<number>(path) + step, min, max))
    } else if (e.key === 'ArrowDown' || e.key === 'ArrowLeft') {
      store.set(path, clamp(store.get<number>(path) - step, min, max))
    }
  })

  return labeled(label, node)
}

export function toggle(store: Store, path: string, label: string): HTMLElement {
  const btn = el('button', 'toggle')
  btn.type = 'button'
  btn.setAttribute('aria-label', label)
  const sync = () => {
    const on = store.get<boolean>(path)
    btn.classList.toggle('on', on)
    btn.setAttribute('aria-pressed', String(on))
  }
  sync()
  btn.addEventListener('click', () => store.set(path, !store.get<boolean>(path)))
  store.subscribe((_s, p) => {
    if (p === path) sync()
  })
  return labeled(label, btn)
}

export function select(
  store: Store,
  path: string,
  label: string,
  options: Array<{ value: string; text: string }> | string[],
): HTMLElement {
  const sel = el('select', 'select')
  sel.setAttribute('aria-label', label)
  const opts = options.map((o) => (typeof o === 'string' ? { value: o, text: o } : o))
  for (const o of opts) {
    const opt = document.createElement('option')
    opt.value = o.value
    opt.textContent = o.text
    sel.appendChild(opt)
  }
  sel.value = store.get<string>(path)
  sel.addEventListener('change', () => {
    store.set(path, sel.value)
    // Drop focus so the typing keyboard goes back to playing notes —
    // a focused select would otherwise swallow keydowns.
    sel.blur()
  })
  store.subscribe((_s, p) => {
    if (p === path) sel.value = store.get<string>(path)
  })
  return labeled(label, sel)
}

export function stepper(
  store: Store,
  path: string,
  label: string,
  opts: { min: number; max: number; step?: number; fmt?: (v: number) => string },
): HTMLElement {
  const step = opts.step ?? 1
  const fmt = opts.fmt ?? ((v: number) => String(v))
  const wrap = el('div', 'stepper')
  const down = el('button', 'stepper-btn', wrap)
  down.type = 'button'
  down.textContent = '−'
  down.setAttribute('aria-label', `decrease ${label}`)
  const value = el('span', 'stepper-value', wrap)
  const upBtn = el('button', 'stepper-btn', wrap)
  upBtn.type = 'button'
  upBtn.textContent = '+'
  upBtn.setAttribute('aria-label', `increase ${label}`)
  const sync = () => (value.textContent = fmt(store.get<number>(path)))
  sync()
  const bump = (dir: number) => {
    const v = clamp(store.get<number>(path) + dir * step, opts.min, opts.max)
    store.set(path, v)
  }
  down.addEventListener('click', () => bump(-1))
  upBtn.addEventListener('click', () => bump(1))
  store.subscribe((_s, p) => {
    if (p === path) sync()
  })
  return labeled(label, wrap)
}

/** A momentary action button (e.g. PANIC). */
export function button(label: string, onClick: () => void): HTMLElement {
  const btn = el('button', 'action-btn')
  btn.type = 'button'
  btn.textContent = label
  btn.setAttribute('aria-label', label)
  btn.addEventListener('click', onClick)
  return labeled(label, btn)
}

/** A titled group box, like the original's PADMATRIX / REVERB frames. */
export function group(title: string, ...children: HTMLElement[]): HTMLElement {
  const g = el('div', 'group')
  const t = el('span', 'group-title', g)
  t.textContent = title
  const body = el('div', 'group-body', g)
  for (const c of children) body.appendChild(c)
  return g
}
