# expressionPad — system design

This documents the design of the **current** system: the models, dataflow,
invariants, and conventions both implementations follow. For what the
*original 2017 app* looked like and where this recreation deliberately
deviates, see [`reference/DESIGN.md`](reference/DESIGN.md) (ground truth for
look and behavior). For the iOS port's stack choices and its own deviations,
see [`ios/README.md`](ios/README.md).

## Principles

1. **Two implementations, one specification.** The web build (`src/`,
   TypeScript + Web Audio) and the native build (`ios/`, Swift + a custom
   real-time kernel) are *ports of each other*, not shared code. Every model,
   constant, and behavior described here exists twice, verbatim where
   possible — `harmonicAmps` recipes, smoothing time constants, envelope
   math, policy tables. Tests are mirrored the same way (`tests/` ↔
   `ios/Core/Tests/`). When you change a behavior on one platform, port it
   and its tests to the other in the same change.
2. **Continuous expression first.** Every touch is an independent voice with
   continuous pitch, velocity, and pressure. Anything that quantizes
   (frets, discrete keys) is a mode layered on top of a continuous model,
   never the other way around.
3. **Validate at every boundary.** Persisted state, URL parameters, MIDI
   input, and file imports are all sanitized before they reach layout,
   audio, or MIDI code (`sanitizeState` on both platforms).
4. **The audio thread allocates nothing** (iOS). All control traffic crosses
   one lock-free SPSC ring; buffers and wavetables live in preallocated
   pools. The web build approximates this discipline with per-voice node
   graphs built at note-on and a shared FX chain.

## System map

```
touches / hardware keyboard / MIDI in
        │
   TouchTracker  (pure logic: voices, slide, vibrato, fret crossings)
        │  VoiceSink events: noteOn / glide / pressure / noteOff / allOff
        ▼
      Router ──────────────┬──────────────┐
        │                  │              │
   SynthEngine        SamplerEngine    MidiOut (MPE)
        │                  │
        └── shared FX chain: distort → delay → reverb → limiter
                           │
                        output

Store (path-addressable state tree) ──► every box above subscribes by path
PadView (canvas / UIKit) ──► renders layout + BrightnessField ripples
TiltSource / MotionTiltSource ──► engine tilt axis
```

Key files: `src/core/state.ts`, `src/core/layout.ts`, `src/ui/touch.ts`,
`src/audio/{engine,sampler,expression}.ts`, `src/ui/{pad,tilt}.ts`,
`src/midi/midi.ts` — and their iOS counterparts under
`ios/Core/Sources/ExpressionPadCore/` plus the app shell in `ios/App/`.

## State model

One state tree (`AppState`) holds everything: `voice` (synth/sampler
exclusivity), `pad` (surface config), `expr` (expression routing), `synth`,
`sampler`, `fx`, `midi`, `appearance`, `ui`.

- **Path-string subscriptions.** Subscribers key off dot-paths
  (`"synth.gen1.morph"`). The iOS `Store` mutates through typed
  `WritableKeyPath`s but translates each leaf back to the same dot-path
  (`PathMap`), so subscription logic ports verbatim.
- **Sanitize on every write.** `sanitizeState` clamps numeric leaves and
  rejects unknown enum/named values after decode and after every mutation.
- **Tolerant persistence.** localStorage (web) / UserDefaults (iOS) via a
  deep-merge that keeps only keys that already exist with the same JSON
  shape — stale or future state degrades to defaults, never to invalid
  parameters.
- **URL parameters (web only)** override state at load for sharable setups
  (`?layout=hex&mirror=1&offset=12&vib=0.5…`); they pass through the same
  sanitizer.

## Layout engine

A `Layout` is keys plus three queries: `hitTest(x, y)`,
`pitchAt(x, row)` (continuous fractional MIDI pitch, piecewise-linear
between key centers, extrapolating at edges), and `rowHeight`. Coordinates
are canvas-style (y down); **row 0 is the bottom row** (lowest pitch),
matching the original app.

- **Builders:** square grid, hex grid (pointy-top, odd rows shifted, capped
  stretch-to-fill, Voronoi hit-test in unstretched space), stacked pianos,
  and two typing-keyboard layouts (desktop/iPad hardware keys).
- **Pitch mapping:** `baseNote` + per-row offsets (`ROW_TUNINGS`: intervals
  or explicit guitar-style offsets) + column scale degrees (`SCALES`).
- **Mirror split** is a *decorator*, not a fourth geometry: the base layout
  is built at half width, and the right half is its reflection (geometry
  mirrored, `note + mirrorOffset`). Both thumbs see identical shapes
  sweeping inward; pitch rises toward the seam from both sides. Touches
  exactly on the seam resolve to the innermost key. Keyboard layouts ignore
  mirroring. Ripples propagate across the seam because the brightness field
  only sees key adjacency.

## Interaction model (TouchTracker)

Pure logic (no DOM/UIKit), injectable clock, fully unit-tested. Each touch
id is an independent voice.

- **slide = 0:** dragging across keys retriggers discrete notes.
- **slide > 0:** pitch follows the finger continuously (`pitchAt`), across
  rows too (row changes are glides, not retriggers). **FRETS** snaps the
  slid pitch to semitones.
- **TCH VEL:** velocity from vertical position within the key at onset
  (bottom loud, top soft, 0.25–1.0).
- **AFTERTOUCH:** vertical drag after onset → pressure 0..1 over a
  `rowHeight × 1.2` range.
- **VIB (in-key vibrato):** horizontal wiggle bends around a spring-loaded
  anchor that trails the finger with a 250 ms time constant
  (`VIB_RECENTER_MS`); bend is clamped to ±1 key-width and scaled by the
  knob (max ±1 semitone). Fast wiggle = vibrato; a held offset relaxes back
  to the fretted pitch. Active only when pitch is otherwise quantized
  (slide = 0, or frets on); a free slide already follows the finger. The
  anchor resets on drag retrigger.
- **Fret crossings:** the tracker watches `round(pitch)` per touch and fires
  `onFret` whenever a voice lands on a new semitone (slides, fretted steps,
  drag retriggers — but *not* initial onsets). This single callback drives
  haptics on both platforms.

## Expression system

Two continuous performance axes with assignable destinations, configured in
`expr`:

| axis | source | targets |
|---|---|---|
| pressure | aftertouch (vertical drag) | `filter` (default) · `level` · `lfo` · `off` |
| tilt | device attitude | `off` (default) · `filter` · `level` · `lfo`, scaled by `tiltAmount` |

### The policy is the single source of truth

`pressureModulation(route, pressure, profile)` —
`src/audio/expression.ts` / `ios/Core/.../Expression.swift` — returns an
explicit value for **every** destination:

- `filter`: routed pressure 0..1 (each engine scales to its cutoff range;
  the synth through its `filter.env` knob, the sampler as `0.8 + 0.2·p`
  normalized cutoff). For the sampler this route also carries the classic
  gentle swell (`level = 1 + 0.35·p`), preserving the original app's touch
  response.
- `level`: pure volume swell from a 0.3 floor (`lerp(0.3, 1, p)`).
- `lfo`: per-voice LFO send scale (synth only; samples have no LFO).
- `off` / abandoned destinations: **neutral** (filter 0, level 1, lfo 1).

Because every destination always gets a value, re-routing is atomic: each
engine has one `applyVoiceExpression(voice)` path called from note
creation, pressure events, and `expr.*` store changes alike — including
release tails, matching the kernel, which re-applies the policy every
render block. Voice envelopes carry **velocity only**; everything the
pressure axis does lives in a dedicated post-envelope expression gain, so
routing changes never fight envelope automation.

The TypeScript switch is exhaustive (`assertNever`); the Swift routes are
`Int32` enums (`KernelPressureRoute`, `KernelTiltRoute`) decoded from the
event ring's Float payload exactly once in `applyParam` — no magic numbers
past that boundary. Malformed payloads fall back to defaults.

### Tilt

Tilt is "uprightness": 0 flat on a table → 1 screen-vertical, in any
rotation. Web derives it as `1 − |cos β · cos γ|` from DeviceOrientation;
iOS as `1 − |gravity.z|` from CoreMotion (30 Hz), both smoothed
(one-pole, factor 0.25) and rate-limited (33 ms web).

Destinations: `filter` shifts every voice's normalized cutoff by
`tilt × amount`; `level` ducks the shared pre-FX voice bus by
`lerp(1 − amount, 1, tilt)` (pre-FX so delay/reverb tails keep ringing);
`lfo` adds `tilt × amount` on top of the LFO depth knob.

**Sources own their lifecycle, re-centering included.** The web
`TiltSource` is a state machine (`idle / authorizing / active / denied`)
separating *requested* (what the routing wants) from *active* (sensor
attached): concurrent gesture activations share one in-flight promise;
`requested` is re-checked after every await so routing-off mid-permission-
prompt beats a late grant; denial re-prompts only from a fresh user gesture
(iOS Safari requires one). The iOS `MotionTiltSource` arms on
`requested && applicationActive`, so backgrounding always releases the
sensor. Both emit 0 on deactivation — composition roots only state what
they want.

## Audio engines

### Web (`src/audio/engine.ts`, `sampler.ts`)

Per synth voice: gen1 + gen2 oscillators (PeriodicWave from 32 additive
partials, morph sine→tri→saw→square, brightness tilt) plus two detuned
fatten copies when enabled → per-gen gains → lowpass biquad (cutoff =
knob + pressure term + tilt term; LFO on detune via per-voice send
scalers) → ADSR vca → expression gain → synth bus. Sampler voices:
AudioBufferSource (continuous `detune` for slides, RETRIG restarts on
semitone crossings) → filter → vca → expression gain. Both feed the shared
FX chain (distortion → delay → reverb → master → limiter). Voice caps:
10 playing / 24 live synth, 16 live sampler; oldest-steal with the FX chain
rebuilt on panic so tails can't ring.

### iOS (`ios/Core/.../SynthKernel.swift`)

The entire instrument renders in one `AVAudioSourceNode` callback:
wavetable mipmaps built from the same `harmonicAmps` recipe, RBJ biquad,
one-pole smoothers standing in for `setTargetAtTime` (same taus), FDN
reverb replacing convolution (same decay mapping — see ios/README for the
deviation rationale). Control traffic — notes, every knob, wavetable and
sample pointers, expression routes, live tilt — flows through the
`EventRing` (lock-free SPSC, plain values, emergency all-off flags for
overflow) and is drained at each 32-sample block boundary.

## Haptics

The HAPTIC knob (`pad.haptics`, 0–1, default 0.35) scales a tick fired on
every fret crossing (see TouchTracker above): iOS uses
`UIImpactFeedbackGenerator(.light)` with intensity `0.3 + 0.7 × knob`,
kept warm via `prepare()` on touch-down; web uses `navigator.vibrate`
where it exists (Android Chrome — iOS Safari has no vibration API). Both
throttle to one tick per 40 ms so fast glisses don't smear.

## MIDI

MPE-style output: master channel 0, rotating member channels 1–15 (one per
touch, oldest stolen when exhausted), per-note pitch bend against a
configurable bend range (default ±48, negotiated via RPN on every member
channel), channel pressure for the pressure axis, optional CC74 for the Y
axis. Continuous pitch (slides *and* vibrato) rides the same glide → bend
path as the internal synth. MIDI input drives whichever local voice is
active; local sound can be switched off to use the pad as a pure
controller. Device changes mid-performance release everything first.

## Rendering

Single-canvas (web) / CoreGraphics-in-UIView (iOS) renderer. Key fills
come from the color scheme (Ocean/Magenta/Rainbow/Mono; conventional
black-key pitch classes darkened, CONTRAST controls the spread), touched
keys glow white with pressure-scaled halo, and the **BrightnessField**
adds the signature ripples: a damped wave with viscosity over the key
adjacency graph (k-nearest neighbors in size-normalized space, so the same
constants work on every layout). Note onsets poke the field at event time;
the render loop runs only while touches are live or field energy remains.

**Geometry-only rebuilds:** rebuilding the layout cancels held touches, so
only the paths that change key geometry trigger it (`pad.layout`, rows,
cols, tuning, scale, base note, mirror, mirrorOffset — `GEOMETRY_PATHS` in
`src/ui/pad.ts` and `PadSurfaceView.geometryPaths`). Performance knobs
(slide, vib, haptic, expression routing) must never cut a note short.

## Testing conventions

- Interaction logic (TouchTracker, layout, state, tilt math, expression
  policy) is pure and tested directly, with injected clocks where timing
  matters.
- Web audio tests run the real engines against a typed mock context
  (`tests/mock-audio.ts`); knowledge of node-creation order lives only in
  its graph helpers (`synthVoiceGains`, `samplerVoiceNodes`,
  `voiceBusGain`).
- Kernel tests render real buffers and assert on RMS/finiteness — the DSP
  is exercised, not mocked.
- Cross-platform: behavioral tests are ported in pairs; a fix that adds a
  regression test on one platform adds its mirror on the other.
