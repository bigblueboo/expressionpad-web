/** Minimal Web Audio mock — enough graph surface to run the engines in tests. */

export class MockParam {
  value = 0
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
}

export class MockNode {
  connections: MockNode[] = []
  onended: (() => void) | null = null
  started = false
  stopped = false
  connect(n: MockNode): MockNode {
    this.connections.push(n)
    return n
  }
  disconnect(): void {}
  start(): void {
    this.started = true
  }
  stop(): void {
    this.stopped = true
    this.onended?.()
  }
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

  resume(): Promise<void> {
    return Promise.resolve()
  }
  createGain() {
    return this.make('gain', Object.assign(new MockNode(), { gain: new MockParam(1) }))
  }
  createBiquadFilter() {
    return this.make('filter', Object.assign(new MockNode(), {
      type: 'lowpass', frequency: new MockParam(350), Q: new MockParam(1),
      detune: new MockParam(0),
    }))
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
    return this.make('osc', Object.assign(new MockNode(), {
      frequency: new MockParam(440), detune: new MockParam(0),
      setPeriodicWave(): void {},
    }))
  }
  createPeriodicWave(real: Float32Array, imag: Float32Array) {
    return { real, imag }
  }
  createBuffer(channels: number, length: number, sampleRate: number) {
    return new MockBuffer(channels, length, sampleRate)
  }
  createBufferSource() {
    return this.make('src', Object.assign(new MockNode(), {
      buffer: null as unknown, loop: false, loopStart: 0, loopEnd: 0,
      detune: new MockParam(0), playbackRate: new MockParam(1),
    }))
  }
  decodeAudioData(_bytes: ArrayBuffer): Promise<MockBuffer> {
    return Promise.resolve(new MockBuffer(1, 8000, this.sampleRate))
  }
}
