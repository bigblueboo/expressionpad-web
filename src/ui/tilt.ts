/**
 * TiltSource — device orientation as a modulation source. Emits "uprightness"
 * 0..1: 0 with the device flat on a table, 1 with the screen vertical, in any
 * rotation (portrait/landscape agnostic). iOS Safari gates the sensor behind
 * a permission prompt that must come from a user gesture, so enable() is
 * retried from the first pointerdown as well as when the routing changes.
 */

const EMIT_INTERVAL_MS = 33

interface OrientationEventCtor {
  requestPermission?: () => Promise<string>
}

export class TiltSource {
  private listener: ((e: DeviceOrientationEvent) => void) | null = null
  private smoothed = 0
  private lastEmit = -Infinity

  constructor(
    private onTilt: (value: number) => void,
    private now: () => number = () =>
      typeof performance !== 'undefined' ? performance.now() : Date.now(),
  ) {}

  get supported(): boolean {
    return typeof DeviceOrientationEvent !== 'undefined'
  }

  get enabled(): boolean {
    return this.listener !== null
  }

  async enable(): Promise<boolean> {
    if (!this.supported) return false
    if (this.listener) return true
    const ctor = DeviceOrientationEvent as unknown as OrientationEventCtor
    if (typeof ctor.requestPermission === 'function') {
      try {
        if ((await ctor.requestPermission()) !== 'granted') return false
      } catch {
        return false // not called from a user gesture yet — retried later
      }
    }
    this.listener = (e) => this.handle(e.beta, e.gamma)
    window.addEventListener('deviceorientation', this.listener)
    return true
  }

  disable(): void {
    if (!this.listener) return
    window.removeEventListener('deviceorientation', this.listener)
    this.listener = null
    this.smoothed = 0
  }

  /** Fold beta/gamma into uprightness and emit smoothed + rate-limited. */
  handle(beta: number | null, gamma: number | null): void {
    if (beta == null || gamma == null) return
    const b = (beta * Math.PI) / 180
    const g = (gamma * Math.PI) / 180
    // |cos β · cos γ| is the vertical component of the screen normal:
    // 1 face-up/face-down, 0 screen-vertical.
    const upright = 1 - Math.abs(Math.cos(b) * Math.cos(g))
    this.smoothed += (upright - this.smoothed) * 0.25
    const t = this.now()
    if (t - this.lastEmit < EMIT_INTERVAL_MS) return
    this.lastEmit = t
    this.onTilt(this.smoothed)
  }
}
