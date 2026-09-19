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
import { bindTheme } from './ui/theme'

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
  theme: ['appearance.theme', String],
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
router.add(
  engine,
  () => store.state.midi.localSound && store.state.voice === 'synth',
)
router.add(
  sampler,
  () => store.state.midi.localSound && store.state.voice === 'sampler',
)
router.add(midiOut, () => store.state.midi.outEnabled)

buildControls(store, engine, sampler, midiOut, router, app)

const surfaceStrip = document.createElement('div')
surfaceStrip.className = 'surface-strip'
surfaceStrip.innerHTML =
  '<span class="surface-title">Playing surface</span><span class="surface-detail"></span>'
const themeControl = document.createElement('label')
themeControl.className = 'theme-control'
themeControl.innerHTML = `<span>Theme</span><select aria-label="Theme">
  <option value="system">System</option>
  <option value="light">Light</option>
  <option value="dark">Dark</option>
</select>`
const themeSelect = themeControl.querySelector('select')!
themeSelect.value = store.state.appearance.theme
themeSelect.addEventListener('change', () =>
  store.set('appearance.theme', themeSelect.value),
)
store.subscribe((state) => {
  themeSelect.value = state.appearance.theme
})
surfaceStrip.appendChild(themeControl)
app.appendChild(surfaceStrip)
const syncSurface = () => {
  const p = store.state.pad
  const names: Record<string, string> = {
    square: 'Square',
    hex: 'Hexagon',
    piano: 'Piano',
    'kbd-chromatic': 'Keyboard · chromatic',
    'kbd-piano': 'Keyboard · piano',
  }
  surfaceStrip.querySelector('.surface-detail')!.textContent =
    `${names[p.layout]} / ${p.layout.startsWith('kbd') ? 'QWERTY' : `${p.rows} × ${p.cols}`}${p.mirror ? ' / mirror' : ''}`
}
syncSurface()
store.subscribe((_s, path) => {
  if (path.startsWith('pad')) syncSurface()
})

const padContainer = document.createElement('main')
padContainer.className = 'pad-container'
app.appendChild(padContainer)

const footer = document.createElement('footer')
footer.className = 'instrument-footer'
footer.innerHTML =
  '<span class="screw" aria-hidden="true"></span><span class="playing-hint">Touch to play · slide to bend</span><span class="footer-model">POLYPHONIC EXPRESSION / EP–02</span><span class="screw" aria-hidden="true"></span>'
app.appendChild(footer)
const syncHint = () => {
  footer.querySelector('.playing-hint')!.textContent =
    store.state.pad.layout.startsWith('kbd')
      ? 'Type to play · Esc returns to the pad'
      : 'Touch to play · slide to bend'
}
syncHint()
store.subscribe((_s, path) => {
  if (path === 'pad.layout') syncHint()
})

const pad = new PadView(store, router, padContainer)
bindTheme(store, () => pad.requestRender())

// Typing-keyboard input drives the kbd-* layouts.
const keyboard = new KeyboardInput(() => pad.currentLayout, pad.tracker)
keyboard.attach(window)

// MIDI in drives whichever local voice is active (never MIDI out — no echo).
const localVoice: VoiceSink = {
  noteOn: (id, p, v) =>
    (store.state.voice === 'sampler' ? sampler : engine).noteOn(id, p, v),
  glide: (id, p) =>
    (store.state.voice === 'sampler' ? sampler : engine).glide(id, p),
  pressure: (id, v) =>
    (store.state.voice === 'sampler' ? sampler : engine).pressure(id, v),
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
  if (midiOut.access && store.state.midi.inEnabled)
    midiIn.attach(midiOut.access)
  else midiIn.detach()
})
store.subscribe((_s, path) => {
  if (
    (path === 'midi.inEnabled' || path === 'midi.inputId') &&
    midiOut.access
  ) {
    if (store.state.midi.inEnabled) midiIn.attach(midiOut.access)
    else midiIn.detach()
  }
})

// Device tilt feeds the engine whenever the EXPRESSION tilt routing is on.
// The source owns its whole lifecycle, re-centering to 0 on deactivation
// included; this only says what is wanted.
const tiltSource = new TiltSource((v) => engine.setTilt(v))
const syncTilt = () => tiltSource.setRequested(store.state.expr.tilt !== 'off')
store.subscribe((_s, path) => {
  if (path === 'expr.tilt') syncTilt()
})
syncTilt()

// Wake/resume the audio context from the first gesture anywhere. Tilt is
// re-armed here too: iOS only grants the orientation sensor from a gesture.
const wake = () => {
  engine.ensure()
  void tiltSource.activateFromGesture()
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
