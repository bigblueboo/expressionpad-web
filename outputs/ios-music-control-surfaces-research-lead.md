# Lead Research Notes: iOS Music Control Surfaces

Research date: 2026-07-25

## ExpressionPad repository audit

ExpressionPad is best understood as three products in one:

1. A configurable multitouch instrument surface with square, hexagonal, stacked-piano, hardware-keyboard, and mirrored two-thumb layouts.
2. A self-contained additive synthesizer and sampler with effects.
3. A MIDI/MPE-style controller that sends per-touch note, pitch bend, pressure, and CC74 and can receive MIDI into its sound engine.

Repository-grounded differentiators:

- Continuous polyphonic movement across notes, with a user-controlled continuum between retriggered notes and smooth pitch.
- Arbitrary row/column geometry, multiple tunings and scale mappings, phone/tablet/portrait/landscape support.
- A mirrored, pitch-offset phone layout designed explicitly for two-thumb performance.
- Fret snapping, spring-centered in-key vibrato, and haptic ticks at semitone crossings.
- Per-touch onset velocity and vertical-drag aftertouch, plus device-tilt routing to filter, level, or LFO.
- Built-in additive synthesis, six generated sample instruments, user sample import, four effects, and seven restored presets.
- Network/CoreMIDI in/out on native iOS; Web MIDI in/out on supported web browsers.
- A propagated key-to-key brightness ripple, rather than a conventional touch halo.

Material current limitations visible in the repository:

- The native iOS target is a standalone app, not an AUv3 MIDI or instrument extension.
- There is no Audiobus integration, Ableton Link, AUv3 hosting, or DAW project recall surface visible in the code.
- Native iOS remembers one global state in `UserDefaults`, but has no visible named user setup/preset library, iCloud sync, import/export, or deep-link sharing. The web build can share URL configuration.
- MIDI output is MPE-style MIDI 1.0 channel rotation. There is no MIDI 2.0/UMP implementation visible.
- The bundled sound library is intentionally small and generated; it is a playable proof of immediacy rather than a content moat.
- Product analytics, onboarding, tutorial content, App Store metadata, localization, and accessibility marketing are not represented in the repository.

Primary repository evidence:

- `README.md`
- `ios/README.md`
- `reference/DESIGN.md`
- `ios/App/Midi.swift`
- `ios/App/PadView.swift`
- `ios/Core/Sources/ExpressionPadCore/TouchTracker.swift`
- `ios/Core/Sources/ExpressionPadCore/State.swift`
- `src/midi/midi.ts`

## Preliminary market frame

The market is not one category. It is a stack of substitutes:

| Layer | User hires it for | Representative forms |
|---|---|---|
| Expressive performance surface | Play another synth or hardware instrument with touch-native articulation | MPE keyboards, strings, ribbons, grids |
| Playable instrument | Get a distinctive sound and gesture vocabulary in one app | Physical-modeling, multidimensional and granular instruments |
| Configurable controller | Build the exact knobs, faders, pads, messages, and bidirectional feedback a rig needs | MIDI/OSC controller builders |
| Music-production environment | Host, route, sequence, loop, arrange, and recall a whole session | DAWs, modular hosts, loopers, grooveboxes |

ExpressionPad competes most directly in the first two layers. Its commercial risk is that experienced iOS musicians increasingly expect layer-three and layer-four integration—especially AUv3 and reliable session recall—even from products whose primary value is a playable surface.

## Lead-source checks

1. [AudioKit feature on the original expressionPad](https://audiokitpro.com/expressionpad/)
2. [Original expressionPad listing/history at SynthyFrog](https://synthyfrog.com/app/expressionpad-synth-sampler-coremidi-instrument/)
3. [Original expressionPad discussion and removed-App-Store status](https://forum.loopypro.com/discussion/21891/xpressionpad-synth-sampler-coremidi-instrument-ios-universal-music-free)
4. [Apple US App Store: GeoShred Control](https://apps.apple.com/us/app/geoshred-control/id1336247116)
5. [Apple US App Store: KB-1 Keyboard Suite](https://apps.apple.com/us/app/kb-1-keyboard-suite/id1437919435)
6. [Apple US App Store: Velocity Keyboard](https://apps.apple.com/us/app/velocity-keyboard/id1462605052)
7. [Apple US App Store: Midi Poly Grid](https://apps.apple.com/us/app/midi-poly-grid/id1633882803)
8. [Apple US App Store: GeoShred](https://apps.apple.com/us/app/geoshred/id1064769019)
9. [Apple US App Store: Animoog Z](https://apps.apple.com/us/app/animoog-z-synthesizer/id1586841361)
10. [Audiobus Wiki: MPE software controller apps](https://abwiki.loopypro.com/doku.php?id=mpe_sw_controller)
11. [MIDI Association: MIDI Polyphonic Expression](https://midi.org/mpe-midi-polyphonic-expression)
12. [Apple US App Store: KeyPad MIDI Controller](https://apps.apple.com/us/app/keypad-midi-controller/id6758680165)
13. [discoDSP product page: KeyPad](https://www.discodsp.com/keypad/)

## Live verification notes

- Apple's lookup endpoint returned zero results for the original app ID `1198834918` on 2026-07-25, consistent with removal from the US storefront: <https://itunes.apple.com/lookup?id=1198834918&country=us>.
- Apple's lookup endpoint on 2026-07-25 returned the following current US base prices: GeoShred Control free, KB-1 $14.99, Velocity Keyboard $9.99, Midi Poly Grid $3.99, GeoShred $24.99, and Animoog Z free with IAP. This conflicts with older search snippets that still show KB-1 at $7.99; the live Apple value should control: <https://itunes.apple.com/lookup?id=1336247116,1437919435,1462605052,1633882803,1064769019,1586841361&country=us>.

## Preliminary hypotheses to test

1. ExpressionPad's strongest whitespace is not “more MPE.” It is fast, self-contained playability across unusually flexible geometry, especially on a phone.
2. “Continuous polyphonic movement across a configurable lattice” is more ownable than generic “expressive MIDI controller.”
3. Named setup recall/export and AUv3 MIDI operation are likely the highest-leverage credibility gaps for serious iOS musicians.
4. The built-in synth/sampler should be sold as zero-setup immediacy and an expression demonstrator, not as a deeper synthesizer than Animoog Z, GeoShred, or specialist AUv3 instruments.
5. A relaunch must explicitly solve abandonment anxiety created by the first app's disappearance: provenance, compatibility commitment, support path, and update cadence should be visible.
6. Phone-specific two-thumb play, haptic frets, and cross-platform web access appear less crowded than tablet-first “virtual keyboard” positioning.

## Material 2026 entrant

KeyPad MIDI Controller, launched in 2026 by discoDSP, materially raises the
feature baseline. Its current official listing claims a piano surface,
isomorphic grid, drums, XY controls, MPE, mono/poly aftertouch, MIDI and OSC,
standalone and AUv3 operation, project-state recall, and a user-loadable
SF2/SFZ/sample engine, at a free base price [12][13]. Its small rating base
makes product quality and market traction uncertain, but it makes generic
“MPE controller with built-in sounds” positioning indefensible. ExpressionPad
must lead with the quality and originality of its playing model—continuous
cross-note motion, arbitrary square/hex/piano geometry, mirror mode, frets,
vibrato, haptics, and gesture-linked synthesis—while closing host-integration
and setup-recall gaps.
