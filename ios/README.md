# expressionPad — native iOS app

A native port of the web recreation (`../src`), which is itself a
resurrection of the original 2017 iOS app. Musical behavior follows `../reference/DESIGN.md`; the interface follows the
current web Studio design in `../.impeccable.md`.

The enclosure uses warm grey or charcoal, physical control keys and knobs,
IBM Plex type, and a single recessed sage LCD with flat note indicators.
System / Light / Dark is available above the playing surface and persists
independently of the note palette. Existing saved settings keep their palette.

The layout follows the available window size: controls sit above the display
in portrait/narrow windows and beside it in wide landscape windows. Hide the
controls for a larger playing surface. Safe areas protect the notch and home
indicator. At accessibility text sizes, controls move into a full-height sheet
with scrollable bank navigation. Controls support VoiceOver, adjustable knobs,
and 44-point targets; Reduce Motion suppresses LCD ripples. Surface resizing
preserves tracked notes, while musical geometry changes intentionally silence
them. Panic clears audio, MIDI, touch, and keyboard state together.

## Approach and tech stack

| concern | choice |
|---|---|
| Language / UI | Swift, SwiftUI shell, UIKit `UIView` for the multi-touch pad surface |
| Audio I/O | `AVAudioEngine` + `AVAudioSourceNode` render callback |
| Synthesis | Custom pure-Swift DSP kernel (no AudioKit, no C++), all voices + FX rendered in one callback |
| Session | `AVAudioSession` `.playback`, `preferredIOBufferDuration = 5 ms`, 48 kHz, background-audio mode |
| MIDI | CoreMIDI (`MIDIEventList`, MIDI 1.0 protocol) with MPE per-note channels + network session |
| Project layout | `Core/` SwiftPM package (all logic + DSP, unit-tested on macOS with `swift test`) + `App/` thin platform shell |
| Project file | Hand-written `project.pbxproj` (Xcode 16 synchronized folder groups; no xcodegen dependency) |

### Why this stack for low-latency synthesis

- **`AVAudioSourceNode` over an AudioUnit extension or AudioKit.** The render
  block runs on the audio I/O thread with no graph overhead between the
  kernel and the hardware. AudioKit (which powered the original) would add a
  large dependency for DSP we already have fully specified in ~500 lines of
  web-audio math; owning the kernel gives sample-accurate parity with the
  web version and lets the whole thing be unit-tested off-device.
- **Latency budget.** 5 ms I/O buffers (240 frames @ 48 kHz) + output
  latency lands around 8–12 ms touch-to-sound on modern hardware — well
  under the web app's `AudioContext` path. The MIDI tab shows the measured
  figure like the web build does.
- **Real-time safety without C.** The kernel allocates nothing and locks
  nothing on the audio thread. All control traffic — note on/off/glide/
  pressure, every knob, wavetable and sample pointers — flows through one
  lock-free single-producer/single-consumer event ring
  (`Core/Sources/ExpressionPadCore/EventRing.swift`), drained at the top of
  each render block. Wavetables and PCM live in preallocated pools; the UI
  side builds them and passes pointers.
- **Web Audio semantics are ported, not approximated.** `setTargetAtTime`
  becomes the same one-pole exponential (`tau` values copied verbatim),
  the biquad is the RBJ lowpass with Q-in-dB exactly as the Web Audio spec
  defines it, envelopes/voice-stealing/glide time constants match
  `engine.ts`, and oscillators use band-limited wavetable mipmaps built
  from the same `harmonicAmps` recipe.

### Layout

```
ios/
  Core/                      SwiftPM package "ExpressionPadCore"
    Sources/ExpressionPadCore/
      Notes, Scales, Layout, Presets, State, Colors    ← ports of ../src/core + ui math
      DSP, SampleGen, EventRing, SynthKernel, Fx       ← the realtime engine
      TouchTracker, BrightnessField, VoiceSink, Midi math
    Tests/ExpressionPadCoreTests/                      ← ports of ../tests, run with `swift test`
  App/                       iOS-only shell
    ExpressionPadApp.swift   SwiftUI @main
    AudioEngine.swift        AVAudioEngine/session glue, store→kernel adapter
    Midi.swift               CoreMIDI in/out (MPE)
    PadView.swift            UIKit multi-touch surface + CoreGraphics renderer
    ControlsView.swift, Widgets.swift, Theme.swift     ← the control panel
  xpad.xcodeproj
  UITests/                   simulator theme, controls, persistence, and rotation tests
```

## Deliberate deviations from the web build

Mirroring the spirit of `DESIGN.md`'s deviations section:

- **Reverb is an 8-line FDN, not convolution.** The web build convolves with
  a generated exponentially-decaying noise IR and must rebuild it (throttled)
  when FDBK turns. A feedback-delay-network with per-line damping produces
  the same diffuse exponential tail, but the decay time (0.4–5 s, same
  mapping) tracks the knob *continuously* with zero rebuild cost on the
  audio thread.
- **Distortion oversamples 2× with a half-band FIR** (the web shaper asks
  the browser for `oversample: '2x'`); the transfer curve is the identical
  `tanh(kx)/tanh(k)`.
- **The limiter** implements the Web Audio `DynamicsCompressor` static curve
  (threshold −3 dB, knee 6, ratio 12, attack 2 ms, release 100 ms, spec
  makeup gain) without that node's 6 ms lookahead delay — less latency,
  same guardrail.
- **Web MIDI device pickers become CoreMIDI** destinations/sources, and the
  original's network session comes back for free (`MIDINetworkSession`),
  un-deviating DESIGN.md's web-only substitution. The app also publishes an
  **"expressionPad" virtual source** (stable unique ID) that always carries
  the full MPE stream — other apps select it as an input with no routing —
  and the MIDI tab hosts a Bluetooth LE MIDI pairing sheet
  (`CABTMIDICentralViewController`).
- **Typing-keyboard layouts** (Keys Chromatic / Keys Piano) work from
  hardware keyboards on iPad via `pressesBegan`.
- **URL-parameter config** has no meaning in an app and is dropped.
- State persists to `UserDefaults` (same tolerant deep-merge the web build
  applies to localStorage).

## Building

All core + DSP tests run on macOS, no simulator needed:

```sh
ios/Core/test.sh                 # works even before the Xcode license is accepted
cd ios/Core && swift test        # once `sudo xcodebuild -license accept` has been run
```

The app itself targets iOS 18+ (verified with Xcode 26.6 / iOS 26.5 simulator):

```sh
xcodebuild -project ios/xpad.xcodeproj -scheme ExpressionPad \
  -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build

# Choose an installed simulator name or ID from `xcrun simctl list devices`.
xcodebuild -project ios/xpad.xcodeproj -scheme ExpressionPad \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' CODE_SIGNING_ALLOWED=NO test
```

The UI tests use a separate preferences suite, covering theme selection and
persistence, panel navigation, and portrait/landscape transitions. Run them with
maximum accessibility text as well (`xcrun simctl ui DEVICE content_size
accessibility-extra-extra-extra-large`; restore `large` afterward).

Verified: 157 core tests pass, along with iPhone 17 Pro and iPad Pro 11-inch
simulator UI runs across all five layouts, plus maximum accessibility text on
iPhone in portrait and landscape. Two expert design passes approved the final
visual direction.

Core tests include palette contrast, saved-state migration, all five layouts'
resize continuity, vibrato spring-back, expression reset, and panic behavior.
Simulator tests do not establish physical audio latency, hardware MIDI/keyboard
behavior, haptics, or held multi-touch continuity during OS-driven rotation.
