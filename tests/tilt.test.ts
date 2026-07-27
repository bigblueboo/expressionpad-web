import { afterEach, describe, expect, it, vi } from 'vitest'
import { TiltSource } from '../src/ui/tilt'

function rig() {
  const seen: number[] = []
  let clock = 0
  const tilt = new TiltSource((v) => seen.push(v), () => clock)
  return { seen, tilt, tick: (ms = 40) => (clock += ms) }
}

/** Stub a permission-gated sensor (iOS Safari) and count real listeners. */
function permissionRig() {
  let grant: (v: string) => void = () => {}
  const pending = new Promise<string>((resolve) => {
    grant = resolve
  })
  vi.stubGlobal('DeviceOrientationEvent', { requestPermission: () => pending })
  const listeners: unknown[] = []
  vi.spyOn(window, 'addEventListener').mockImplementation((type, fn) => {
    if (type === 'deviceorientation') listeners.push(fn)
  })
  vi.spyOn(window, 'removeEventListener').mockImplementation((type, fn) => {
    if (type === 'deviceorientation') {
      const i = listeners.indexOf(fn)
      if (i >= 0) listeners.splice(i, 1)
    }
  })
  return { grant, listeners }
}

afterEach(() => {
  vi.unstubAllGlobals()
  vi.restoreAllMocks()
})

describe('TiltSource attitude math', () => {
  it('maps device attitude to uprightness 0..1 in any rotation', () => {
    const flat = rig()
    flat.tilt.handle(0, 0) // flat on a table
    expect(flat.seen.at(-1)).toBeCloseTo(0)

    // Screen vertical, portrait: smoothing walks toward 1.
    const portrait = rig()
    for (let i = 0; i < 60; i++) {
      portrait.tick()
      portrait.tilt.handle(90, 0)
    }
    expect(portrait.seen.at(-1)).toBeGreaterThan(0.95)

    // Screen vertical, landscape (gamma) reads the same.
    const landscape = rig()
    for (let i = 0; i < 60; i++) {
      landscape.tick()
      landscape.tilt.handle(0, 90)
    }
    expect(landscape.seen.at(-1)).toBeGreaterThan(0.95)
  })

  it('rate-limits emissions but keeps smoothing between them', () => {
    const { seen, tilt, tick } = rig()
    tilt.handle(90, 0)
    tilt.handle(90, 0) // same instant — suppressed
    tilt.handle(90, 0)
    expect(seen).toHaveLength(1)
    tick()
    tilt.handle(90, 0)
    expect(seen).toHaveLength(2)
    expect(seen[1]).toBeGreaterThan(seen[0]) // smoothing advanced regardless
  })

  it('ignores null readings', () => {
    const { seen, tilt } = rig()
    tilt.handle(null, null)
    expect(seen).toHaveLength(0)
  })
})

describe('TiltSource activation lifecycle', () => {
  it('shares one in-flight activation: concurrent gestures attach one listener', async () => {
    const { grant, listeners } = permissionRig()
    const tilt = new TiltSource(() => {})
    tilt.setRequested(true)
    const p1 = tilt.activateFromGesture()
    const p2 = tilt.activateFromGesture()
    expect(tilt.state).toBe('authorizing')
    grant('granted')
    expect(await Promise.all([p1, p2])).toEqual([true, true])
    expect(listeners).toHaveLength(1)
    expect(tilt.state).toBe('active')
  })

  it('turning routing off mid-prompt wins over a late grant', async () => {
    const { grant, listeners } = permissionRig()
    const tilt = new TiltSource(() => {})
    tilt.setRequested(true)
    const pending = tilt.activateFromGesture()
    tilt.setRequested(false) // routing switched off while the prompt is up
    grant('granted')
    expect(await pending).toBe(false)
    expect(listeners).toHaveLength(0)
    expect(tilt.state).toBe('idle')
  })

  it('records denial and retries only from a fresh gesture', async () => {
    const { grant, listeners } = permissionRig()
    const tilt = new TiltSource(() => {})
    tilt.setRequested(true)
    const pending = tilt.activateFromGesture()
    grant('denied')
    expect(await pending).toBe(false)
    expect(tilt.state).toBe('denied')
    expect(listeners).toHaveLength(0)

    // A fresh gesture re-prompts (the stub now grants immediately).
    vi.stubGlobal('DeviceOrientationEvent', {
      requestPermission: () => Promise.resolve('granted'),
    })
    expect(await tilt.activateFromGesture()).toBe(true)
    expect(listeners).toHaveLength(1)
  })

  it('attaches without a gesture where no permission gate exists', async () => {
    vi.stubGlobal('DeviceOrientationEvent', {}) // desktop/Android: no requestPermission
    const listeners: unknown[] = []
    vi.spyOn(window, 'addEventListener').mockImplementation((type, fn) => {
      if (type === 'deviceorientation') listeners.push(fn)
    })
    const tilt = new TiltSource(() => {})
    tilt.setRequested(true)
    await Promise.resolve() // let the fire-and-forget activation settle
    expect(tilt.state).toBe('active')
    expect(listeners).toHaveLength(1)
    tilt.setRequested(false)
    expect(tilt.state).toBe('idle')
  })

  it('does nothing when not requested', async () => {
    permissionRig()
    const tilt = new TiltSource(() => {})
    expect(await tilt.activateFromGesture()).toBe(false)
    expect(tilt.state).toBe('idle')
  })
})
