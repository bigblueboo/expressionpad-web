# expressionPad

A continuous, multi-touch music controller — resurrected for the web.

The original expressionPad (iOS, 2017–2020, built on AudioKit) was lost with
its source. This is a ground-up recreation with web technology: Web Audio for
the synth, Pointer Events for low-latency multi-touch, Web MIDI for
controlling external instruments.

## Run it

```sh
npm install
npm run dev        # local dev server
npm test           # vitest suite
npm run build      # production bundle (dist/)
node scripts/shots.mjs   # device-emulated screenshots (needs `npm run preview` running)
```

Serve over HTTPS (or localhost) for Web MIDI. On iOS Safari Web MIDI is not
available — the internal synth still works.

## What it does

- **Continuous multi-touch**: every finger is an independent voice with its
  own pitch bend (slide), velocity (vertical position at onset), and
  aftertouch (vertical drag).
- **Layouts**: square grid, hexagon grid, stacked piano — any rows × cols,
  portrait or landscape. Row tunings (fourths, fifths, guitar EADGBE,
  Open C…), column scales (chromatic, modes, pentatonics…), any base note.
  Conventional black-key pitch classes are darkened like piano blacks, so
  the lattice reads at a glance; the CONTRAST knob dials the white/black
  spread.
- **Fluid ripples**: every note onset drops a brightness "pebble" that
  propagates key-to-key through the lattice as a damped wave with viscosity
  — crests lighten keys toward white, troughs dip gently darker. The RIPPLE
  knob dials the effect from subtle to splashy.
- **Typing-keyboard layouts**: for desktop users, two layouts mapped to the
  physical keyboard. Keys (Chromatic) walks each QWERTY row chromatically
  (z x c v → C C# D Eb) with the row tuning between rows; Keys (Piano)
  makes z–/ and q–p white keys with the rows above as black keys (z x c →
  C D E, s d → C# Eb). Keycaps render on the pad and respond to mouse too.
- **Slide / frets**: slide knob morphs from discrete retriggering to fully
  continuous pitch; frets snaps slides to semitones.
- **Additive synth**: two morphing additive generators (sine→tri→saw→square
  via 32 harmonic partials), brightness tilt, ADSR, resonant filter with
  aftertouch control, LFO (pitch/filter). Original presets recreated:
  Super Sine, Growl Dark, Square Tap, Pole Position, Synolin, Saw Demise,
  Room Drill.
- **Sampler**: six built-in instruments rendered from pure math at load
  time (English Horn, Choir, Strings, E-Piano, Marimba, Pluck — with
  click-free loop points) plus user sample loading. RETRIG gives harp-gliss
  slides; PANIC kills everything. Synth and sampler swap via the VOICE
  switch, like the original.
- **FX**: reverb (generated impulse), delay, distortion, fatten (detuned
  unison) — the original's four inserts, shared by synth and sampler.
- **MIDI**: MPE-style output (per-touch channel, per-note pitch bend,
  channel pressure, CC74 timbre), configurable bend range, MIDI input to
  play the internal synth.
- **Collapsible controls**: tab bar (SYNTH | SMPLR | FX | PAD | MIDI) with a chevron
  to collapse everything and play full-screen. Tap the active tab to toggle.
- **URL config**: share setups, e.g. `?layout=hex&scheme=Rainbow&rows=6&cols=14`.

State persists to localStorage. The pad surface is a single canvas renderer;
audio voices are built per-touch with `latencyHint: 'interactive'`.

## Project layout

```
src/core    notes, scales, layout geometry, state store, presets
src/audio   pure DSP math, synth engine, voice routing
src/midi    Web MIDI out (MPE) + in
src/ui      canvas pad, touch tracking, widgets, control panel, color schemes
tests       vitest suite (134 tests)
reference   screenshots of the original app + rendered checks of this build
```
