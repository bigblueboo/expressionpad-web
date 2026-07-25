import './style.css'
import { Store } from './core/state'
import { SynthEngine } from './audio/engine'
import { SamplerEngine } from './audio/sampler'
import { Router } from './audio/sink'
import type { VoiceSink } from './audio/sink'
import { MidiIn, MidiOut } from './midi/midi'
import { PadView } from './ui/pad'
import { KeyboardInput } from './ui/keyboard'
import { buildControls } from './ui/controls'
import { TiltSource } from './ui/tilt'

const app = document.getElementById('app')!
const store = Store.load()

// URL overrides for sharable configs, e.g. ?layout=hex&scheme=Rainbow&panel=0
const params = new URLSearchParams(location.search)
const urlMap: Record<string, [path: string, parse: (v: string) => unknown]> = {
  layout: ['pad.layout', String],
  rows: ['pad.rows', Number],
  cols: ['pad.cols', Number],
  scale: ['pad.colScale', String],
  tuning: ['pad.rowTuning', String],
  base: ['pad.baseNote', Number],
  mirror: ['pad.mirror', (v) => v !== '0'],
  offset: ['pad.mirrorOffset', Number],
  vib: ['pad.vibrato', Number],
  haptics: ['pad.haptics', Number],
  press: ['expr.pressure', String],
  tilt: ['expr.tilt', String],
  scheme: ['appearance.scheme', String],
  panel: ['ui.panelOpen', (v) => v !== '0'],
  tab: ['ui.tab', String],
  voice: ['voice', String],
}
for (const [key, [path, parse]] of Object.entries(urlMap)) {
  const v = params.get(key)
  if (v !== null) store.set(path, parse(v))
}

const engine = new SynthEngine(store)
const sampler = new SamplerEngine(store, engine)
const midiOut = new MidiOut(store)

const router = new Router()
router.add(engine, () => store.state.midi.localSound && store.state.voice === 'synth')
router.add(sampler, () => store.state.midi.localSound && store.state.voice === 'sampler')
router.add(midiOut, () => store.state.midi.outEnabled)

buildControls(store, engine, sampler, midiOut, router, app)

const padContainer = document.createElement('main')
padContainer.className = 'pad-container'
app.appendChild(padContainer)

const pad = new PadView(store, router, padContainer)

// Typing-keyboard input drives the kbd-* layouts.
const keyboard = new KeyboardInput(() => pad.currentLayout, pad.tracker)
keyboard.attach(window)

// MIDI in drives whichever local voice is active (never MIDI out — no echo).
const localVoice: VoiceSink = {
  noteOn: (id, p, v) => (store.state.voice === 'sampler' ? sampler : engine).noteOn(id, p, v),
  glide: (id, p) => (store.state.voice === 'sampler' ? sampler : engine).glide(id, p),
  pressure: (id, v) => (store.state.voice === 'sampler' ? sampler : engine).pressure(id, v),
  noteOff: (id) => {
    engine.noteOff(id)
    sampler.noteOff(id)
  },
  allOff: () => {
    engine.allOff()
    sampler.allOff()
  },
}
const midiIn = new MidiIn(store, localVoice)
midiOut.onDevicesChanged(() => {
  if (midiOut.access && store.state.midi.inEnabled) midiIn.attach(midiOut.access)
  else midiIn.detach()
})
store.subscribe((_s, path) => {
  if ((path === 'midi.inEnabled' || path === 'midi.inputId') && midiOut.access) {
    if (store.state.midi.inEnabled) midiIn.attach(midiOut.access)
    else midiIn.detach()
  }
})

// Device tilt feeds the engine whenever the EXPRESSION tilt routing is on.
const tiltSource = new TiltSource((v) => engine.setTilt(v))
const syncTilt = () => {
  if (store.state.expr.tilt !== 'off') {
    void tiltSource.enable()
  } else {
    tiltSource.disable()
    engine.setTilt(0)
  }
}
store.subscribe((_s, path) => {
  if (path === 'expr.tilt') syncTilt()
})
syncTilt()

// Wake/resume the audio context from the first gesture anywhere. Tilt is
// re-armed here too: iOS only grants the orientation sensor from a gesture.
const wake = () => {
  engine.ensure()
  syncTilt()
}
window.addEventListener('pointerdown', wake, { passive: true })

// Silence everything if the tab is hidden mid-performance.
document.addEventListener('visibilitychange', () => {
  if (document.hidden) {
    router.allOff()
    store.flushSave()
  }
})
window.addEventListener('pagehide', () => store.flushSave())
