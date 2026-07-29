/**
 * TiltSource — device orientation as a modulation source. Emits "uprightness"
 * 0..1: 0 with the device flat on a table, 1 with the screen vertical, in any
 * rotation (portrait/landscape agnostic).
 *
 * Activation is a small state machine because iOS Safari gates the sensor
 * behind a permission prompt that must come from a user gesture, and the app
 * retries from every pointerdown: `requested` records what the routing wants,
 * `state` records where the sensor actually is, and the in-flight activation
 * promise is shared so concurrent gestures cannot attach duplicate listeners.
 * `requested` is re-checked after every await so turning the routing off
 * mid-prompt wins over a late grant.
 */

const EMIT_INTERVAL_MS = 33

export type TiltState = 'idle' | 'authorizing' | 'active' | 'denied'

interface OrientationEventCtor {
  requestPermission?: () => Promise<string>
}

export class TiltSource {
  private requested = false
  private tiltState: TiltState = 'idle'
  private activation: Promise<boolean> | null = null
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

  get state(): TiltState {
    return this.tiltState
  }

  /** Routing on/off. Turning off detaches immediately, even mid-authorization. */
  setRequested(value: boolean): void {
    this.requested = value
    if (!value) this.deactivate()
    else void this.activate()
  }

  /**
   * Retry activation from a user gesture — the only context where iOS grants
   * the sensor. Clears a previous denial so a fresh gesture can re-prompt.
   */
  activateFromGesture(): Promise<boolean> {
    if (!this.requested) return Promise.resolve(false)
    if (this.tiltState === 'denied') this.tiltState = 'idle'
    return this.activate()
  }

  private activate(): Promise<boolean> {
    if (!this.supported || !this.requested) return Promise.resolve(false)
    if (this.tiltState === 'active') return Promise.resolve(true)
    if (this.tiltState === 'denied') return Promise.resolve(false)
    if (this.activation) return this.activation // share the in-flight attempt
    this.tiltState = 'authorizing'
    this.activation = this.requestAndAttach().finally(() => {
      this.activation = null
    })
    return this.activation
  }

  private async requestAndAttach(): Promise<boolean> {
    const ctor = DeviceOrientationEvent as unknown as OrientationEventCtor
    if (typeof ctor.requestPermission === 'function') {
      let granted = false
      try {
        granted = (await ctor.requestPermission()) === 'granted'
      } catch {
        granted = false // not called from a user gesture yet — retried later
      }
      if (!granted) {
        this.tiltState = this.requested ? 'denied' : 'idle'
        return false
      }
    }
    // Routing may have turned off while the prompt was up; the off wins.
    if (!this.requested) {
      this.tiltState = 'idle'
      return false
    }
    this.listener = (e) => this.handle(e.beta, e.gamma)
    window.addEventListener('deviceorientation', this.listener)
    this.tiltState = 'active'
    return true
  }

  private deactivate(): void {
    if (this.listener) {
      window.removeEventListener('deviceorientation', this.listener)
      this.listener = null
    }
    this.smoothed = 0
    this.lastEmit = -Infinity
    this.tiltState = 'idle'
    // Deactivation owns re-centering: callers never reset the axis themselves.
    this.onTilt(0)
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
