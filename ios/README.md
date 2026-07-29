# expressionPad — native iOS app

A native port of the web recreation (`../src`), which is itself a
resurrection of the original 2017 iOS app. `../reference/DESIGN.md` remains
ground truth for look and behavior; this port matches the web app
feature-for-feature and knob-for-knob.

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
  ExpressionPad.xcodeproj
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
  un-deviating DESIGN.md's web-only substitution.
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

The app itself (requires Xcode 16.4+, one-time license acceptance):

```sh
sudo xcodebuild -license accept  # if not yet accepted
export DEVELOPER_DIR=~/Applications/Xcode-16.4.0.app/Contents/Developer
xcodebuild -project ios/ExpressionPad.xcodeproj -scheme ExpressionPad \
  -destination 'generic/platform=iOS Simulator' build
```

Status: all 150 core tests pass; the app target compiles and links cleanly
against the iOS 18 simulator SDK (verified with the toolchain compiler
directly — the `xcodebuild` path just needs the license accepted once).
