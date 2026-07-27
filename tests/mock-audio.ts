/** Minimal Web Audio mock — enough graph surface to run the engines in tests. */

export class MockParam {
  value = 0
  held = false
  constructor(v = 0) {
    this.value = v
  }
  setValueAtTime(v: number): void {
    this.value = v
  }
  linearRampToValueAtTime(v: number): void {
    this.value = v
  }
  setTargetAtTime(v: number): void {
    this.value = v
  }
  cancelScheduledValues(): void {}
  cancelAndHoldAtTime(): void {
    this.held = true
  }
}

export class MockNode {
  connections: MockNode[] = []
  onended: (() => void) | null = null
  started = false
  stopped = false
  stopTime: number | null = null
  connect(n: MockNode): MockNode {
    this.connections.push(n)
    return n
  }
  disconnect(): void {}
  start(): void {
    this.started = true
  }
  stop(when = 0): void {
    this.stopped = true
    this.stopTime = when
    if (when <= 0) this.onended?.()
  }
  finish(): void {
    this.onended?.()
  }
}

export class MockGainNode extends MockNode {
  gain = new MockParam(1)
}

export class MockFilterNode extends MockNode {
  type = 'lowpass'
  frequency = new MockParam(350)
  Q = new MockParam(1)
  detune = new MockParam(0)
}

export class MockOscillatorNode extends MockNode {
  frequency = new MockParam(440)
  detune = new MockParam(0)
  wave: unknown = null
  setPeriodicWave(wave: unknown): void {
    this.wave = wave
  }
}

export class MockBufferSourceNode extends MockNode {
  buffer: unknown = null
  loop = false
  loopStart = 0
  loopEnd = 0
  detune = new MockParam(0)
  playbackRate = new MockParam(1)
}

class MockBuffer {
  constructor(
    public numberOfChannels: number,
    public length: number,
    public sampleRate: number,
  ) {}
  get duration(): number {
    return this.length / this.sampleRate
  }
  copyToChannel(): void {}
}

export class MockAudioContext {
  currentTime = 0
  sampleRate = 8000
  state = 'running'
  baseLatency = 0.005
  destination = new MockNode()
  created: Record<string, number> = {}
  instances: Record<string, MockNode[]> = {}

  private make<T extends MockNode>(kind: string, node: T): T {
    this.created[kind] = (this.created[kind] ?? 0) + 1
    ;(this.instances[kind] ??= []).push(node)
    return node
  }

  /** Typed registries, so tests read node params without casts. */
  get gains(): MockGainNode[] {
    return (this.instances.gain ?? []) as MockGainNode[]
  }
  get filters(): MockFilterNode[] {
    return (this.instances.filter ?? []) as MockFilterNode[]
  }
  get oscs(): MockOscillatorNode[] {
    return (this.instances.osc ?? []) as MockOscillatorNode[]
  }

  resume(): Promise<void> {
    return Promise.resolve()
  }
  createGain() {
    return this.make('gain', new MockGainNode())
  }
  createBiquadFilter() {
    return this.make('filter', new MockFilterNode())
  }
  createDynamicsCompressor() {
    return this.make('comp', Object.assign(new MockNode(), {
      threshold: new MockParam(), knee: new MockParam(), ratio: new MockParam(),
      attack: new MockParam(), release: new MockParam(),
    }))
  }
  createWaveShaper() {
    return this.make('shaper', Object.assign(new MockNode(), {
      curve: null as Float32Array | null, oversample: 'none',
    }))
  }
  createDelay() {
    return this.make('delay', Object.assign(new MockNode(), { delayTime: new MockParam() }))
  }
  createConvolver() {
    return this.make('conv', Object.assign(new MockNode(), { buffer: null as unknown }))
  }
  createOscillator() {
    return this.make('osc', new MockOscillatorNode())
  }
  createPeriodicWave(real: Float32Array, imag: Float32Array) {
    return { real, imag }
  }
  createBuffer(channels: number, length: number, sampleRate: number) {
    return new MockBuffer(channels, length, sampleRate)
  }
  createBufferSource() {
    return this.make('src', new MockBufferSourceNode())
  }
  decodeAudioData(_bytes: ArrayBuffer): Promise<MockBuffer> {
    return Promise.resolve(new MockBuffer(1, 8000, this.sampleRate))
  }
}

// --------------------------------------------------- engine graph helpers ---
// Creation-order knowledge about the engines' node graphs lives here, in one
// place, so behavioral tests read node roles semantically instead of by index.

/**
 * The gain nodes a synth voice creates (engine.ts noteOn order), given
 * `ctx.gains.length` captured just before the noteOn.
 */
export function synthVoiceGains(ctx: MockAudioContext, since: number) {
  const [vca, exp, lfoAmtPitch, lfoAmtFilter] = ctx.gains.slice(since, since + 4)
  return { vca, exp, lfoAmtPitch, lfoAmtFilter }
}

/**
 * The nodes a sampler voice creates (sampler.ts startVoice order), given
 * gain/filter counts captured just before the noteOn.
 */
export function samplerVoiceNodes(
  ctx: MockAudioContext, gainsBefore: number, filtersBefore: number,
) {
  const [vca, exp] = ctx.gains.slice(gainsBefore, gainsBefore + 2)
  return { vca, exp, filter: ctx.filters[filtersBefore] }
}

/** The shared pre-FX voice bus (second gain the engine's buildGraph creates). */
export function voiceBusGain(ctx: MockAudioContext): MockGainNode {
  return ctx.gains[1]
}
