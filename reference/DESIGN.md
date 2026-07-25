# Original expressionPad — design reference

Recovered material from reviews and App Store listings of the original iOS
app (mode of expression, LLC; released 2017-09-12, last update 1.3.1,
2020-04-13; 4.62★ from 68 ratings).

## Sources

- AudioKit Pro feature: <https://audiokitpro.com/expressionpad/>
  ("expressionPad, Awesome Free iPhone/iPad App Built with AudioKit!")
- iPad Loops review: <https://ipadloops.com/expressionpad-free-synth-sampler-controller/>
- SynthyFrog listing (screenshots, metadata): <https://synthyfrog.com/app/expressionpad-synth-sampler-coremidi-instrument/>
- Gearspace thread: "ExpressionPad: the best iPad app so far!"

## Screenshots (saved in `screenshots/`)

| file | shows |
|---|---|
| appstore-ipad-1.jpg | SMPLR tab open, blue square grid, full control panel |
| appstore-ipad-2.jpg | magenta stacked pianos + rainbow hex layout, FX panel |
| appstore-ipad-3.jpg | SYNTH tab, white/gray piano, MIDI in/out groups |
| appstore-iphone-1.jpg | full synth panel + blue grid (portrait) |
| appstore-iphone-2.jpg | red piano landscape, mono hex landscape |
| appstore-iphone-3.jpg | preset menu: Growl Dark, Square Tap, Super Sine, Pole Position, Synolin, Saw Demise, Room drill |
| audiokitpro-header.png / oblique-ipad.gif / app-icon.jpg | marketing assets |

## Original UI anatomy

- Top bar: `SYNTH | SMPLR | FX | MIDI | PAD` tabs, active tab marked with a
  cyan bullet, `«` chevron at right collapses the whole panel.
- Panels: thin-bordered group boxes with floating small-caps cyan titles —
  PADMATRIX (Layout, Row Tuning, Cols, Rows, Col Scale, Base, Slide, Tch
  Vel, Frets, Aftrtch), APPEARANCE (Coloring, Piano, Labels, BG, Bright,
  Ripples), SYSTEM (BG Audio, Latency, Reset, CPU usage), GENERATOR (Wave,
  Morph, Semi, Tune ×2), MODULATION, ENVELOPE, WAVE, LFO, FILTER, PRESET,
  REVERB (Fdbk, Mix, On), DELAY (Amt/Time, Mix, On), DISTORT (Amt, On),
  FATTEN (Fatness, On), MIDI OUT / MIDI IN (Session, Channel, Panic,
  Active, IP address).
- Knobs: small circles with cyan arc + % readout; toggles: rounded squares
  that glow cyan when on; labels in tiny tracking-wide caps below controls.
- Pad surface: full-bleed. Square grid in blues/teals with note labels;
  stacked piano rows in magenta/red (white keys colored, black keys dark);
  hexagons in rainbow pitch-class colors or grayscale. Touched keys glow
  white with a soft halo.
- Condensed techno sans-serif throughout.

## Deliberate deviations in the web recreation

- SMPLR tab: the original's sampled-instrument library is replaced by
  instruments synthesized to PCM at load time (English Horn, Choir,
  Strings, E-Piano, Marimba, Pluck) plus a user-loadable sample slot —
  no audio assets to ship. RETRIG restarts the sample on semitone
  crossings during slides; PANIC silences everything. The original's
  "only the SYNTH or SAMPLER can be active at a time" rule is the VOICE
  switch, present on both tabs.
- SYSTEM latency/CPU readouts replaced by the AudioContext latency shown in
  the MIDI tab status line.
- MIDI session/IP (CoreMIDI network) replaced by Web MIDI device pickers.
- Added URL-parameter config for sharable setups.
- Grid/hex keys with conventional black-key pitch classes (C# Eb F# Ab Bb)
  are darkened like piano blacks so the natural lattice reads at a glance.
- Ripples are a brightness wave propagating key-to-key through the lattice
  (damped wave + viscosity, shallow-water style) rather than a drawn circle —
  every note onset drops a "pebble" and the glow spreads to neighbor keys.
- Additions beyond the original: MIRROR two-thumb split (surface reflected
  down the middle, right half pitch-offsettable), VIB in-key vibrato with
  spring-back, HAPTIC fret-crossing ticks, and an EXPRESSION routing group
  (pressure → filter/level/LFO; device tilt → filter/level/LFO with amount).
