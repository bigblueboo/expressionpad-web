# iOS Isomorphic Grids, Chord Surfaces, and Alternative Playable Interfaces

**Competitive research slice for ExpressionPad**  
**Evidence snapshot:** 2026-07-25  
**Storefront:** United States unless stated otherwise

## Executive read

The alternative-surface market is not a graveyard of clever 2010s apps. It has had a real 2026 burst. KeyPad, Hexatone, iotaTONE, and Rubberband are new or newly material competitors; ChordPolyPad and Midi Poly Grid received meaningful 2026 updates; GeoShred remains active; and Musix Pro shipped an iOS 26 compatibility/stability release on July 7 with “big things coming soon.” [S1][S2][S4][S7][S8][S12][S19][S21][S23]

The market divides into four overlapping propositions:

1. **Geometry and theory first:** Musix Pro, Hexatone, iotaTONE, Isotope.
2. **Per-note expression first:** KeyPad, Midi Poly Grid, KB-1, GeoShred Control, Velocity Keyboard.
3. **Harmony safety and chord workflow:** Navichord, Chordion, Tonality, ScaleBud 2, ChordPolyPad.
4. **Touch-native instrument identity:** Rubberband, Synthecaster, ThumbJam, Gestrument Pro, Ribbons.

No surveyed product cleanly owns all four. The closest feature-bundle threat is **KeyPad**, because it is free and combines an isomorphic grid, full XY MPE, mono/poly aftertouch, AUv3, OSC, and an internal sample engine. The layout laboratory to beat is **Musix Pro**. The new microtonal package to beat is **Hexatone**. The mature expressive-instrument bar is **GeoShred**; the focused glass-velocity benchmark is **Velocity Keyboard**; the strongest host-native controller suite is **KB-1**. [S2–S17]

ExpressionPad’s defensible space is therefore not “an isomorphic MIDI controller.” That phrase is already crowded and, in KeyPad’s case, free. Its more distinctive combination is a continuous instrument with square, hex, and stacked-piano geometries; independent per-finger pitch and aftertouch/timbre; a morph from discrete keys to continuous sliding; frets, in-key vibrato, haptics, phone-specific mirror play, and a complete synth/sampler/FX path. Repository evidence supports that combination, but the current standalone architecture lacks the AUv3 workflow expected by several leading competitors.

## Scope and method

This slice covers playable iPhone/iPad interfaces whose note organization, harmony model, continuous gesture, tuning system, or chord surface could substitute for part of ExpressionPad. It includes currently available products and a small number of historically influential or forthcoming products when they clarify category expectations.

It excludes:

- generic modular MIDI dashboards and remote-control builders;
- clip launchers, DAW remotes, and mixer/controller apps without a distinctive note surface;
- mainstream synth workstations whose touchscreen keyboard is incidental to a larger production environment;
- theory/reference apps unless they include a genuinely playable MIDI surface.

Discovery used Exa broadly, then prioritized:

1. live US Apple App Store pages and Apple’s live lookup catalog for availability, price, version, update date, minimum OS, and rating count;
2. official developer pages and manuals for layouts, gesture semantics, MIDI/MPE/AUv3/OSC support, tuning, and sound;
3. specialist reviews and practitioner discussions only for usability, historical context, and contradictions.

“Not claimed” below means a capability was absent from the current official listing/manual; it is not proof that the capability is technically impossible. No hands-on latency, stuck-note, touch-capacity, host-compatibility, or MIDI-message capture testing was performed.

Apple live metadata was collected as a point-in-time snapshot; prices and IAPs can change after this date. [S1]

## Market map

| Product | Geometry depth | Per-note expression | Immediate sound | Host integration | Closest job |
|---|---:|---:|---:|---:|---|
| KeyPad | Medium | High | Medium: sample engine | High: AUv3 | General expressive controller/instrument |
| Musix Pro | Very high | Low–medium | Medium: 8 instruments | Low: legacy Audiobus/IAA | Isomorphic study and performance |
| Hexatone | Very high, including microtonal | Medium for pitch; low for Y/Z | Medium: voices + sampler/SFZ | High: AUv3 | Microtonal hex instrument |
| Midi Poly Grid | High | High | None | Medium: MIDI, no AUv3 | Push/LinnStrument-style grid input |
| KB-1 | Medium | High | None | High: AUv3 | Multi-layout DAW keyboard suite |
| GeoShred Control | Medium, guitar-centric | High | None until Pro upgrade | High: AUv3 | Serious fretless/diatonic MPE performance |
| Velocity Keyboard | Medium | Very high | None | High: AUv3 | Convincing velocity/expression on glass |
| ChordPolyPad | High for prepared harmony | Medium at pad level | Basic bank | High: AUv3 MIDI effect | Chord performance and generation |
| Rubberband | Low as a grid; high as a continuous concept | High in concept; exact messages opaque | High | Low: no AUv3 claim | Phone-first expressive microtonal instrument |
| ExpressionPad, repository build | High | High | High: synth + sampler + FX | Medium: standalone CoreMIDI/Web MIDI | Continuous, configurable instrument |

The important opening is the upper-right intersection: a surface that has both **learnable/configurable geometry** and **credible independent expression**, without making users assemble a controller, host, and sound source.

## Normalized evidence table

Prices, versions, dates, and OS requirements in this table come from Apple’s live US catalog on 2026-07-25 unless an IAP caveat is stated. [S1]

| Product | Current snapshot | Surface, scales, tuning | Multitouch and expression | MIDI / MPE / AUv3 / OSC; sound | Competitive read |
|---|---|---|---|---|---|
| **KeyPad MIDI Controller** | **Free**; v1.12; 2026-06-21; iOS 14+; iPhone/iPad | Piano, isomorphic grid, drum pads, XY pad; scale remap, minor-thirds mode, labels, persistent root/layout; less arbitrary geometry than Musix/Midi Poly Grid | Height velocity with three curves; mono/poly aftertouch; XY MPE with X→pitch bend and Y→CC74; remappable aftertouch/mod wheel | Standalone + AUv3; virtual, wired, BLE, network MIDI; OSC; SF2/SFZ/WAV/M4A sample engine | **Very high threat.** Broad modern spec at zero price; young product with only six US ratings and shallower layout design. [S2][S3] |
| **Musix Pro** | **$9.99**; v2.5.7; 2026-07-07; iOS 13.2+; iPhone/iPad | Hex and rectangular; Harmonic Table, Wicki-Hayden, Gerhard, Park and custom directional-interval layouts; resizable/colorable/labeled notes; 12-TET oriented | Touch-velocity dynamics; overlap can trigger triads; detailed within-key XY/touch IDs over OSC; no MPE/per-note bend claim | Core/virtual/BLE MIDI; OSC; Audiobus/IAA; eight internal instruments; no AUv3 claim | **Very high layout threat.** Best theory/layout story and renewed development; weaker continuous expression and host workflow. [S4][S5][S6] |
| **Hexatone** | **$6.99**; v1.3; 2026-06-20; **iPadOS 17+** | Bosanquet, Wicki-Hayden, Harmonic Table, Fourths, Accordion, custom; arbitrary N-EDO, Scala import, equave/A4/key-density controls | Note velocity and curve; hold mode; explicitly no continuous Y/CC74 or Z/pressure | Standalone + AUv3; per-note MPE pitch for microtonal tuning; two voices, single-sample, SFZ/zip, and sample-folder instruments | **Very high microtonal/layout threat.** Modern complete package, but “MPE” is tuning pitch only. [S7] |
| **Midi Poly Grid** | **$3.99**; v1.1.14; 2026-02-14; iOS 13+; iPhone/iPad | Size-adjustable Push-style square pads; many scale highlights; custom X/Y intervals can reproduce fourths, Harmonic Table, Wicki-Hayden, and other grids | Y-position/random/fixed velocity; MPE; poly aftertouch; Push/LinnStrument-style relative bend and slide; graphical feedback | Virtual, USB, BLE, Wi-Fi MIDI; explicitly no sound; explicitly no AUv3 because of Flutter; no OSC claim | **Very high controller threat.** Closest low-cost configurable-grid/MPE rival; setup requires another sound source. [S8][S9] |
| **KB-1 Keyboard Suite** | **$14.99**; v1.3.7; 2025-10-14; iOS 11+; iPhone/iPad | Eight templates: Classic, Uniform, String, Scale, Chord, Drum, XY, CC; multiple rows/octaves; 15+ scales; chords, strum, arp | MPE; horizontal glide, vertical slide, Y velocity, pressure only on supported iPhones | Standalone multi-keyboard + AUv3 MIDI; inter-app, USB, BLE, network MIDI; no sound or OSC claim | **High direct threat.** Mature, host-native, broad utility; template suite rather than coherent custom instrument. [S10][S11] |
| **GeoShred Control** | **Free**; v7000.327.1.436; 2026-06-15; iOS 15+; iPhone/iPad; Pro-functionality IAP currently $24.99 | Guitar-derived isomorphic/fretless and diatonic surface; configurable strings/frets; open/world tunings, scales, temperaments, ragas | Full MIDI/MPE; continuous pitch, vibrato, Key-Y; true Z pressure only on legacy 3D-Touch devices; intelligent pitch rounding | Standalone + AUv3 MIDI; virtual/Wi-Fi/BLE/wired; no sound in Control; Pro unlock adds modeled engine; no OSC claim | **Highest mature instrument threat.** Excellent pitch behavior and mapping; dense, guitar-specific, expensive sound ecosystem. [S12][S13][S14][S15] |
| **Velocity Keyboard** | **$9.99**; v1.3.22; 2025-09-24; iOS 11+; iPhone/iPad | Keyboard, String, Scale, Drum; adjustable density; custom scale highlighting | Category-leading attack-velocity focus; touch area, legacy force, Y, velocity→CC, four knobs; MPE, bend correction, aftertouch, non-MPE modes | Standalone + AUv3 MIDI; no internal sound; no OSC claim | **High expression threat.** Strong validation among LinnStrument/ROLI-style users; less geometry/theory depth. [S16][S17][S18] |
| **ChordPolyPad** | **$17.99**; v3.0.1; 2026-03-16; iOS 15+; iPhone/iPad/Mac | 128 pads/preset; chord library, arbitrary chords, custom scales, scale filtering/quantization, context-aware generation and voice leading | Per-pad configurable XY MIDI; per-note stored velocity; strumming; pad-level rather than note-level expression | Standalone + multi-instance AUv3 MIDI effect; virtual/hardware/Wi-Fi/BLE; internal sound bank; no MPE/OSC claim | **Strong adjacent threat.** Best active premium chord workflow; not a continuous melodic surface. [S19][S20] |
| **Rubberband: Microtonal** | **Free**; v1.1.0; 2026-07-20; **iPhone-designed**, iOS 17+; Pro IAP visible at $8.99, while copy still names €14.99 | Elastic string field with adjustable scale “gravity” from free glissando to hard lock; maqam/makam/dastgah, JI, 19/31-TET, harmonic-series and Western sets | Claimed pressure dynamics, along-string timbre, vertical pitch, tilt, haptics; exact MPE message mapping not documented | Pro-gated MPE output; 36 voices, drone, sympathetic resonance, looper, recording and room-key detection; no AUv3/OSC claim | **High conceptual threat.** Memorable modern interaction and phone focus; new, curated rather than authorable tunings, non-grid. [S21] |
| **Synthecaster** | **$0.99**; v3.5; 2024-06-24; iOS 12+; iPhone/iPad | Guitar-like rows, fourths default; each row independently tunable; hide/highlight scale notes; six-plus octaves | 5–10 simultaneous touches by device; horizontal legato/portamento, vertical pitch bend; device tilt modulates synth parameters | Core MIDI notes/pitch/legato; multi-channel voices but no formal MPE claim; dual-oscillator synth, 55+ presets, FX; Audiobus/IAA, no AUv3 | **Relevant legacy hybrid.** Extraordinary value and immediate sound; sporadic compatibility maintenance, narrow layout family. [S22] |
| **iotaTONE** | **$14.99**; v2.3; 2026-04-15; iOS 15+; iPhone/iPad; no US ratings yet | Harmonic Table, Tonnetz, Wicki-Hayden and more; JI, Pythagorean and user microtonal mappings; chords/inversions/arpeggios | Touch + tilt; mono/poly × touch/hold; quantized output; realtime FX/volume | Advertised as instrument + MIDI controller; MPE, AUv3, OSC, exact MIDI transport, and engine details not documented | **High watchlist relevance.** Premium geometry/tuning pitch with unusually opaque implementation detail. [S23] |
| **Isotope MIDI Keyboard** | **$6.99**; v1.1.8; 2024-09-27; iOS 16+; iPhone/iPad | Square fourths/string-like isomorphic grid; adjustable row interval; themes, key size, window size | Touch-area + accelerometer velocity; velocity-reactive haptics; no MPE/continuous per-note expression claim | MIDI/BLE; internal Element engine is AUv3; hosts third-party AU instruments; controller AUv3 unclear | **Secondary close comparable.** Elegant bridge for string players; narrow protocol/expression story. [S24] |
| **ScaleBud 2** | **$6.99**; v1.9; 2024-09-02; iOS 12+; iPhone/iPad | 110+ scales, custom scales, unlimited keyboard rows; each row can have key/scale/chord; off-scale rounding; hardware keyboard splits | Playable touch rows, but no official velocity/aftertouch/XY/bend claim | Standalone + AUv3 MIDI transformer; per-row channels/ranges/transpose; explicitly no sound; no MPE/OSC | **Workflow adjacency.** Owns “always in scale” and split transformation, not embodied performance. [S25][S26] |
| **Tonality** | **$7.99**; v10.1.1; 2023-11-20; iOS 12+; iPhone/iPad | Reference-first: 1,000+ chords/scales; chord-pad grids 2×2–12×12; circle-of-fifths controller; deep voicing edit | Multiple velocity modes, pad XY CC, strum bar, triggers and host automation | Four AUv3 MIDI tools; MIDI/XML export/import; custom SF2 playback; no MPE/OSC claim | **Adjacent hybrid.** Exceptional theory/chord breadth; performance is secondary to reference/composition. [S27][S28] |
| **Navichord** | **$7.99**; v2.6.15; 2021-02-22; iOS 8+; iPhone/iPad | Tonnetz-like harmonic grid + piano; one-finger triads, complex extensions, 28 scales, Roman numerals, chord pads, progression loop | True chord multitouch; keys/grid/pads can be XY MIDI controls; expression is chord/control-level | Virtual/hardware MIDI, footswitch mapping, Ableton Link, Audiobus/IAA; internal sampled sounds; no MPE/AUv3/OSC | **Influential legacy-live chord surface.** Strong reputation and 585 US ratings, but high maintenance risk. [S29][S30][S31] |
| **Gestrument Pro** | **Free trial**; v1.2.1; 2020-11-12; iOS 11.2+; $1.49/month or $14.99 lifetime | Free 2D cursor field; up to 16 instruments; advanced cents/ratio scale editor and scale slots; generative pitch/rhythm rules | Up to five cursors on iPhone/eight on iPad; cursor X/Y/gate/pressure; eight sliders; recordable automation | MIDI in/out and learn; microtonal pitch bend; Audiobus/IAA; internal sampler; no MPE/AUv3/OSC claim | **Conceptually important, explicitly dormant.** Deep constrained improvisation; legacy hosting and mothballed development. [S32][S33] |
| **Chordion** | **$2.99**; v1.51; 2017-03-17; iPad only, iOS 8+ | Chord hexes left + melody strip right; auto mode follows held harmony; scale locking; configurable chords/scales | Two-hand chord/melody play and strum; no velocity, aftertouch, continuous pitch, or MPE claim | Physical/virtual/network MIDI; separate chord/melody channels; synth/drums/arp, but internal sound is disabled in MIDI mode; no AUv3/OSC | **Historical UX precedent.** “One hand chords, one hand melody, never wrong notes”; effectively frozen. [S34][S35] |
| **ThumbJam** | **$8.99**; v2.6.11; 2022-07-24; iOS 8+; iPhone/iPad | Scale-locked vertical pitch field, splits, hundreds of scales, custom scales and Scala import | 5 touches iPhone/11 iPad; drag/retrigger/glide; X velocity, tilt and shake; some control is global/last-note rather than fully independent | MPE I/O; Wi-Fi/BLE/virtual MIDI; OSC, Ableton Link, Audiobus/IAA; 40+ multisampled instruments, user sampling, loops | **Accessible instrument benchmark.** Deep sound and “never wrong note” confidence; aging integration and UI. [S36][S37] |
| **mTonal** | **$4.99**; v1.1; 2025-01-09; iPad only, iOS 13+ | Fixed 24-tone piano-derived layouts: one, two, or seven octaves | Smooth glide; touch-size velocity; hold pedal | MPE channel-per-note pitch/volume; wired/Wi-Fi/BLE MIDI; internal quarter-tone synth and recording; no AUv3/OSC/Scala | **Narrow microtonal comparator.** Familiar entry point, not a flexible grid system. [S38][S39] |
| **Entonal Studio** | **$14.99**; v1.2.3; 2026-01-04; iPad only, iOS 11+ | Radial editor/lattice; arbitrary cents, ratios, EDO and expressions; non-octave equaves; mappings; Scala/XML I/O | MPE keyboard component; recent update improved multitouch play | Standalone/MIDI effect; hosts AUv3 instruments and retunes by MIDI/MPE bend; simple reference sound | **Strategic complement.** Best tuning-authoring benchmark, but primarily retuning infrastructure rather than a performance surface. [S40] |
| **keyboaredo** | **$2.99**; v1.0; 2022-11-06; iOS 9+; iPhone/iPad | Microtonal EDO keyboard | Touch keyboard; no richer expression documented | Standalone/AUv3 MIDI effect; separate-channel pitch bend required; explicitly no sound | **Narrow utility.** Proof that EDO routing can be inexpensive; weak instrument identity. [S41] |
| **Isomorphic Keyboard** | **Free**; v1.0; 2024-09-09; iOS 16+; iPhone/iPad | Basic Lumatone-style hex surface; three isomorphic layouts + 31-EDO; custom SoundFonts | No expressive controls claimed | Synth; no MIDI output claimed | **Screened, not a professional controller.** Visually relevant exploration toy with little validation. [S42] |
| **Ribbons** | **$3.99**; v1.4; 2019-01-19; iPhone/iPad | Continuous ribbon surface with free pitch or scale snap; microtonal scales | Sliding pitch and vertical modulation; MPE output | Internal synth + MIDI; legacy infrastructure | **Influential continuous-touch precedent, not active threat.** Philosophically close but dormant. [S43][S44] |
| **SoundPrism Pro** | **$4.99**; v2.9.2; 2022-01-03; iPhone/iPad | Geometric pitch-space/harmonic texture surface | Multitouch harmonies; accelerometer control | Standard MIDI and internal audio; no modern MPE claim | **Historical harmonic benchmark.** Influential geometry, now secondary to newer surfaces. [S45] |
| **AC Sabre** | **Delisted**; Apple returns zero results in the US and checked major storefronts; last known 1.2.1 in 2018 | Scale-aware virtual strings played by “plucking” in the air | Gyroscope/accelerometer, ribbons, shake vibrato; MPE added in 2017 | Wi-Fi/BLE/virtual MIDI, Audiobus; no sound or AUv3 | **Historical motion benchmark only.** Memorable one-handed stage identity; no current product/developer path. [S46][S47] |
| **HexyTime** | No live App Store listing verified; developer labels it “coming soon” | Preview promises Harmonic Table, Wicki-Hayden, Bosanquet-Wilson, JI/31-EDO | Preview claims Y velocity and slide aftertouch | Preview claims MPE plus virtual/BLE/USB/network MIDI | **Pipeline signal, not a purchasable competitor.** Do not present preview claims as shipped. [S48] |

## Deep profiles

### 1. KeyPad MIDI Controller — the free full-stack threat

KeyPad is the most important open-ended discovery because it attacks the generic version of ExpressionPad’s story at a price of zero. Its product pitch is broad rather than musical: a piano keyboard, isomorphic grid, drum pads, XY controller, pitch/mod/velocity faders, and an internal sample engine in one touch-first app. The grid now includes scale remapping and a minor-thirds mode, but the official material describes prescribed views rather than Musix-style arbitrary two-axis interval construction. [S2][S3]

Its expression implementation is unusually explicit. Initial height supplies velocity through linear, exponential, or logarithmic curves. Mono and poly aftertouch modes are available. XY MPE allocates notes to channels 2–16, maps X to pitch bend and Y to CC74, visualizes pressure, and lets users remap aftertouch or the mod wheel to another CC or pitch bend. The June 2026 release repaired MPE bend broadcasting, sustain across member channels, duplicate output, slide velocity, and bend stepping—evidence that the developer is actively working through the ugly edge cases of expressive MIDI rather than merely advertising MPE. [S2]

KeyPad also runs inside AUv3 hosts, saves settings with a project, sends OSC, and connects through virtual, wired, Bluetooth, and network MIDI. Its internal audio is a low-CPU mapping engine for SF2, SFZ, WAV, and M4A rather than a deep synthesis environment. [S2][S3]

**Strengths:** modern protocols, AUv3, full MPE mapping, sound without another app, rapid update cadence, no purchase barrier.

**Limitations:** only six US ratings in Apple’s live snapshot; less evidence of refined musical geometry, continuous fret behavior, sound design, phone-specific ergonomics, or long-term stability. It reads as a capable controller suite more than a distinctive new instrument.

**Implication:** “MPE + isomorphic grid + AUv3 + OSC + sound” is already non-differentiating. ExpressionPad must demonstrate why its pad feels and sounds different.

### 2. Musix Pro — the layout and music-theory incumbent

Musix Pro is the closest conceptual rival to ExpressionPad’s configurable grid. It offers hexagonal and rectangular keys, presets such as Harmonic Table and Wicki-Hayden, and a custom hex builder defined by two directional intervals plus orientation. Users can resize keys; color by scale, mode, or tone center; label by note or solfège; and use overlap to cover multiple notes with one touch. Its value proposition is unusually coherent: traditional layouts reflect physical constraints, while Musix arranges notes by harmonic relationship so one learned shape works in every key. [S4][S5]

It supports Core, virtual, and Bluetooth MIDI, plus OSC. The official OSC documentation can transmit within-key X/Y coordinates, touch identity, and transition state, which gives technically adventurous users more data than the standard MIDI note path. Touch velocity and eight internal instruments make it immediately playable. [S4][S6]

The missing pieces are equally clear. Official sources do not claim MPE, independent pitch bend, aftertouch, AUv3, Scala, arbitrary EDO, or a modern plug-in workflow. Its current integration story still names Audiobus and Inter-App Audio. It is best understood as a configurable 12-TET isomorphic instrument and theory laboratory, not a modern continuous-expression surface.

Musix Pro nevertheless cannot be dismissed as abandonware. Version 2.5.7 shipped July 7, 2026, adds iOS/iPadOS 26 compatibility, fixes live-performance crashes and Audiobus/IAA problems, and teases future work. [S4]

**Strengths:** deepest layout authoring and explanatory content; strong lineage among alternative-keyboard, concertina, accordion, LinnStrument, and theory users; mature reputation.

**Limitations:** legacy hosting, comparatively shallow per-note expression, strongly 12-TET orientation.

**Implication:** ExpressionPad should teach each layout as a transferable musical skill, not expose row/column settings as engineering controls.

### 3. Hexatone — the new microtonal geometry package

Hexatone is the clearest 2026 proof that a coherent microtonal grid package can be sold without becoming a theory textbook. It supports arbitrary equal divisions, Scala imports, concert pitch/equave/key density, and six named layout families including a custom layout. Its built-in Bell and Glass voices, single-sample mapping, SFZ/zip import, and sample-folder instrument builder let the user hear any tuning immediately. The app runs standalone or as AUv3 and can receive MIDI for host playback. [S7]

Hexatone also makes an important distinction that much iOS marketing blurs: it uses MPE member channels and per-note pitch bend to keep microtonal intervals in tune, but explicitly does not send continuous Y/CC74 timbre or Z/pressure. Its current copy calls it “a microtonal playing and routing instrument first.” [S7]

That limitation creates a clean comparison. Hexatone is deeper than ExpressionPad today in N-EDO, Scala, and sample-library import. ExpressionPad is deeper in continuous touch behavior, per-finger aftertouch/timbre, synthesized sound, FX, haptics, and phone ergonomics.

**Strengths:** excellent feature coherence; contemporary AUv3 workflow; serious tuning support; immediate local sound.

**Limitations:** iPadOS 17+ only; two US ratings; pitch-only MPE; no Y/Z expression; visual polish and playability are not yet validated at scale.

**Contradiction resolved:** one combined Apple/Exa query transiently failed to return the app. A direct US lookup and App Store URL both returned a live product at $6.99, v1.3, updated 2026-06-20. It is available and should not be labeled withdrawn. [S1][S7]

### 4. Midi Poly Grid — the low-cost configurable MPE grid

Midi Poly Grid is the closest architectural rival to ExpressionPad’s controller half. It is a size-adjustable square pad matrix inspired by Push. Users can choose or author grids by X/Y pitch interval, save presets, highlight many scales, and reproduce fourths, Harmonic Table, Wicki-Hayden, MidiMech, and similar arrangements. It receives MIDI notes for Launchpad-like feedback. [S8][S9]

Its expressive path includes MPE, polyphonic aftertouch, Push/LinnStrument-style relative pitch bend and slide, graphical feedback, and velocity derived from Y position, a fixed value, or randomness. Virtual, USB, Bluetooth, and Wi-Fi MIDI are supported. [S8][S9]

The developer deliberately positions it as a focused pad input device “for people that prefer pads to pianos,” not a MIDI Swiss army knife. The tradeoff is explicit: it produces no sound and cannot be AUv3 because its Flutter implementation does not support that extension model. The code is GPL3/open source, which reduces lock-in for technical users but also exposes maintenance notes about the need for a major internal refactor. [S9]

**Strengths:** arbitrary interval grids plus modern MPE at $3.99; clear product focus; cross-platform/open-source credibility.

**Limitations:** requires a separate sound source, no AUv3, no OSC, seven US ratings, ongoing framework/UI maintenance burden.

**Implication:** a premium ExpressionPad price must be justified by sound, native integration, polish, onboarding, and a superior gesture model—not grid configurability by itself.

### 5. KB-1 Keyboard Suite — the DAW-native controller benchmark

KB-1 is the most direct established controller-first comparison. Its current listing contains eight layouts: piano/wheels, uniform/Seaboard, string, scale, chord, drums, XY pads, and CC knobs. It supports multiple rows and octaves, 15+ scales, chord strumming, arpeggiation, and several independent keyboards with dedicated outputs in standalone mode. [S10][S11]

MPE is central. Horizontal travel provides glide/pitch, vertical movement supplies slide/timbre, and initial Y supplies velocity. Pressure is listed for iPhone only and is tied to legacy 3D-Touch hardware; on contemporary pressure-less hardware, vertical motion must carry more of the expressive burden. KB-1 runs as an AUv3 MIDI instrument and connects through inter-app, USB, Bluetooth, and network MIDI. It has no internal sound and no OSC claim. [S10][S11]

The product’s breadth is also its weakness. It behaves like a toolbox of good controller templates rather than one learnable instrument. The official site is stale—it still foregrounds five layouts while the App Store lists eight—so current Apple copy is the more reliable specification. [S10][S11]

**Strengths:** mature, popular, host-native, broad layout utility, multi-instrument splits.

**Limitations:** no audio, microtonal/Scala story, OSC, true contemporary pressure, free-form layout, haptics, or distinctive visual/instrument identity.

**Implication:** KB-1 sets the minimum DAW workflow expectation. ExpressionPad needs an AUv3 plan if it wants to price at the same premium-controller tier.

### 6. GeoShred Control — the mature expressive-instrument bar

GeoShred is the strongest mature competitor for serious touch performance. Its surface derives from fretted strings but can move between piano-like quantization, guitar-style one-semitone vibrato, and continuous slide. Snap, pitch rounding, slide speed, string/fret counts, tunings, world scales, ragas, and temperaments are all configurable. [S12][S13][S14]

Its full MIDI/MPE path supports virtual, network, Bluetooth, and wired connections plus an AUv3 MIDI-sender plug-in. The surface produces continuous pitch, Key-Y, and pressure where 3D Touch exists. Modern iPads have no true pressure sensor, so Y-position/contact proxies do more work—a category-wide constraint that marketing often obscures. [S12][S13]

The free Control product has no sound. A $24.99 Pro-functionality unlock adds GeoShred’s modeled engine; additional GeoSWAM and Naada instruments can become expensive, and some are monophonic. GeoShred’s secondary control-surface editor is exceptionally deep: buttons, sliders, knobs, and expression pads can drive multiple internal/MIDI targets through curves and mappings. [S13][S14][S15]

**Strengths:** mature pitch behavior, full MPE, active development, serious-instrument reputation, tuning depth, rich control mapping.

**Limitations:** dense UI, guitar-centric worldview, escalating IAP cost, no OSC claim, no square/hex/piano family, and legacy pressure caveats.

**Implication:** ExpressionPad should not try to outgrow GeoShred’s instrument ecosystem. It can be the faster, more legible, less guitar-specific continuous instrument.

### 7. Velocity Keyboard — the glass-velocity benchmark

Velocity Keyboard focuses on one hard problem: making an attack on glass produce believable velocity. It combines a proprietary touch-speed/area heuristic with touch force on legacy devices, Y position, velocity-to-CC, and four CC knobs. It supports aftertouch, smooth inter-note bending, pitch correction, MPE, and dedicated modes for synths that do not understand MPE. [S16][S17]

Its four surface families—Keyboard, String, Scale, and Drum—are less configurable than Musix or Midi Poly Grid, but keep the product legible and compact. It is an AUv3/standalone MIDI controller with no internal audio. [S16]

App Store review evidence is anecdotal but useful. Some experienced ROLI/LinnStrument users describe it as easier to dial in and highly playable; other reviews criticize the visual design, documentation, historical stuck notes, or the surprise that it makes no sound. The September 2025 release fixed iOS 26 problems, and a recent review says the fix restored its preferred AUM/Logic workflow. These are individual experiences, not prevalence data. [S18]

**Strengths:** clearest expression promise, credible user constituency, practical MPE/non-MPE fallbacks.

**Limitations:** no sound, deep geometry, microtonality, OSC, or broad controller environment; true force depends on obsolete hardware.

**Implication:** ExpressionPad must show repeatable onset velocity, bend accuracy, aftertouch behavior, and panic/stuck-note recovery in demos and QA.

### 8. ChordPolyPad — the premium chord-performance specialist

ChordPolyPad demonstrates that specialists will pay a premium for a narrow musical job done well. A preset stores 128 pads, each sourced from a library, custom note set, or generated chord. Pads can have their own MIDI port/channel, X/Y controllers, per-note velocities, and strum configuration. The 2026 generation system adds scale filtering, custom scales, voice leading, context-aware progression generation, and named musical moods. [S19][S20]

It works standalone or as a multi-instance AUv3 MIDI effect, supports virtual/hardware/Wi-Fi/Bluetooth MIDI, includes an internal sound bank, and has mature preset, group, iCloud, sharing, program-change, and undo/redo workflows. It does not claim MPE or OSC. [S19][S20]

**Strengths:** active development, polished host workflow, deep prepared-harmony editing, immediate audition, premium price validation.

**Limitations:** pad-level modulation rather than independent note-surface expression; no melodic geometry or continuous pitch.

**Implication:** a light chord-memory/overlay feature could broaden ExpressionPad’s songwriter appeal, but turning it into a progression generator would dilute “every finger is a voice.”

### 9. Rubberband — a new continuous-instrument identity

Rubberband is not a grid, which is precisely why it matters. Its entire story is an elastic string field where adjustable “gravity” attracts a glide toward the selected tuning. At zero it is free glissando; at maximum it cannot leave the scale. This makes the interaction itself, rather than protocol support, the product. [S21]

Its tuning catalog includes Arabic maqam, Turkish makam, Persian dastgah, just intonation, 19/31-TET, the harmonic series, and Western scales. It claims pressure dynamics, along-string timbre, vertical pitch, device tilt, haptics, MPE output, 36 voices, a drone, sympathetic resonance, looper, recording, and local room-key detection. Most of those features sit behind a one-time Pro unlock. [S21]

The official copy contains a pricing contradiction: it names €14.99 while the US storefront currently displays an $8.99 IAP. Use the in-store purchase sheet as the authority at transaction time. Exact MPE message mapping and AUv3/OSC support are not documented. [S21]

**Strengths:** memorable interaction, phone-specific design, continuous pitch attraction, haptics, tilt, internal sound, culturally broader tuning catalog.

**Limitations:** brand new, no US ratings in the live snapshot, iPhone-designed, curated rather than user-authored tunings, opaque MPE details, no AUv3 claim.

**Implication:** Rubberband validates the thesis “a continuous instrument that happens to speak MIDI.” ExpressionPad’s response is richer geometry, explicit full MPE mapping, two-thumb mirror ergonomics, and deeper sound design.

### 10. Synthecaster — the inexpensive guitar/synth hybrid

Synthecaster remains a useful historical and current comparator because it fuses a guitar-derived row layout with a real internal synth. Rows are tuned in fourths by default but independently adjustable; users can highlight or hide notes outside a scale; and the surface spans more than six octaves. [S22]

Its touch model supports up to ten simultaneous notes on iPad Pro, seven on iPad, and five on iPhone. Horizontal movement gives legato or portamento, vertical movement bends pitch, and device roll/pitch can modulate synth sliders. Its multi-channel MIDI mode assigns voices to different channels and sends note, pitch-wheel, and legato messages, but it predates and does not formally claim MPE. [S22]

The onboard engine contains dual oscillators, envelopes, filter, distortion, LFO, flanger, chorus, delay, and more than 55 presets. Audiobus and Inter-App Audio remain the integration path; AUv3 is absent. The June 2024 build was a compatibility update rather than evidence of active feature development. [S22]

**Strengths:** immediate sound, expressive guitar transfer, generous synth/FX, extraordinary $0.99 value.

**Limitations:** one layout family, legacy hosting, no standard MPE/AUv3/OSC, sparse modern development.

**Implication:** internal sound remains commercially meaningful. Controller-only products make users construct a rig; Synthecaster and ExpressionPad can start as instruments.

## Chord and scale-safety cluster

The chord products solve a different anxiety than expressive grids:

- **Navichord** teaches and sequences harmony through a Tonnetz-like lattice, one-finger triads, Roman numerals, saved pads, and progression looping. Every control can function as XY MIDI, but the underlying job is “write chords like a pro,” not continuous solo performance. Its 585 US ratings signal durable recognition, while its February 2021 update creates real maintenance risk. [S29][S30][S31]
- **Tonality** is a reference product with serious playable AUv3 chord pads: scalable grids, voicing edit, velocity modes, XY CC, strum, MIDI learn, automation, export, and community presets. It competes for theory and chord-search intent, not primarily for instrument feel. [S27][S28]
- **ScaleBud 2** turns scale discipline into infrastructure. Unlimited rows can each carry a different key/scale/chord; hardware input can be split and quantized; one key can yield a chord. It is excellent “never wrong note” plumbing but documents no touch-expression model and produces no sound. [S25][S26]
- **Chordion** remains the strongest UX precedent for two-zone play: one hand picks chords while the other plays a harmony-aware melody. It is effectively frozen, but the promise is still emotionally clear. [S34][S35]

ExpressionPad should borrow the confidence of this cluster—visible scale membership, optional safe-note behavior, perhaps chord-memory overlays—without making chord generation its category.

## Microtonal and tuning cluster

The 2026 market makes microtonality look like a segment, not a novelty:

- Hexatone packages N-EDO, Scala, layouts, AUv3, and sample playback.
- iotaTONE packages JI/Pythagorean mappings, isomorphic theory, touch, and tilt.
- Rubberband packages world tunings with a continuous gravity metaphor.
- Entonal Studio makes cents, ratios, EDO, expressions, mapping, and Scala/XML authoring legible, then retunes hosted instruments.
- mTonal offers a simpler quarter-tone piano route.
- keyboaredo proves that a focused EDO MIDI effect can sell for $2.99.
- ThumbJam’s longevity shows the value of custom scales and Scala import in an accessible instrument. [S7][S21][S23][S36–S41]

ExpressionPad’s current repository model offers strong 12-TET row tunings and column scales, but not arbitrary cents/ratios, N-EDO, or Scala import. “Any tuning” would therefore overstate the product today. A focused implementation—Scala import/export, EDO generator, cents/ratio note definitions, and MPE pitch-bend routing—would close the most visible specialist gap without recreating Entonal’s entire tuning laboratory.

## Strategic implications for ExpressionPad

### 1. Own the combination, not the checklist

Isomorphic grids, MPE, AUv3, OSC, internal samples, haptics, or microtonality each exist elsewhere. KeyPad offers an alarming portion of the checklist for free. The defensible unit is how geometry, continuous movement, snapping/fretting, haptics, sound, and phone ergonomics work together.

Suggested core framing:

> **A continuous instrument where every finger gets its own pitch, pressure, and timbre.**

That is stronger than “configurable MIDI controller” and avoids a feature-count contest.

### 2. AUv3 is the clearest workflow gap

KeyPad, Hexatone, KB-1, GeoShred, Velocity Keyboard, ScaleBud 2, Tonality, ChordPolyPad, and Entonal all participate directly in Audio Unit host workflows. [S2][S7][S10][S12][S16][S19][S25][S27][S40]

For Logic, AUM, Loopy Pro, Drambo, Cubasis, and GarageBand users, loading and restoring a controller/instrument inside the session is materially easier than arranging virtual CoreMIDI between apps. An AUv3 MIDI effect and/or instrument extension is the highest-leverage product follow-up if the intended audience includes iOS producers.

### 3. Be exact about MPE

The term covers different implementations:

- Hexatone uses member channels and pitch bend only for tuning.
- KB-1 and Velocity provide pitch plus slide/timbre, with pressure caveats.
- GeoShred’s true Z depends on legacy 3D Touch.
- KeyPad explicitly maps X to pitch and Y to CC74 and offers aftertouch modes.
- Musix Pro does not claim MPE.
- Synthecaster uses multichannel voices but does not claim the standard. [S2][S4][S7][S10][S12][S16][S22]

ExpressionPad can distinguish itself by showing the emitted signals in plain language: onset velocity, per-note pitch bend, channel pressure, and CC74—plus how each maps to a finger gesture.

### 4. Treat velocity and note lifecycle as product credibility

Velocity Keyboard’s entire reputation rests on extracting dynamics from glass. Recent KeyPad release notes focus on held-note bend, sustain across member channels, duplicate output, and glide velocity. These are not implementation trivia; they define whether a surface feels playable. [S2][S16][S18]

Competitive QA should explicitly cover:

- repeatability of onset velocity at different key heights and touch sizes;
- bends across cell boundaries and bend-range mismatch;
- aftertouch/timbre independence across simultaneous fingers;
- sustain, voice stealing, backgrounding, device rotation, and host reconnection;
- stuck-note recovery and a visible panic path;
- latency under internal sound, CoreMIDI, network MIDI, and AUv3 if added.

### 5. Make the layout system teachable

Musix Pro earns its depth by explaining what each arrangement does musically. Midi Poly Grid exposes flexible intervals, but its audience is already technical. ExpressionPad should ship task-oriented presets and diagrams:

- guitar/bass transfer;
- compact triads;
- widest melodic range;
- two-thumb phone play;
- microtonal/Scala layouts if added;
- chord shapes that remain constant across keys.

The setup UI should answer “what will this help me play?” before “what is the row interval?”

### 6. Phone ergonomics are underclaimed white space

Most competitors scale an iPad concept down to iPhone. Rubberband is the main new exception, while AC Sabre historically made the handheld interaction its identity. [S21][S46][S47]

ExpressionPad’s mirrored two-thumb surface, offset halves, fret haptics, device tilt, and collapsible full-screen play should be a lead demo and screenshot story, not an advanced settings footnote.

### 7. Internal sound is a commercial advantage, but describe its depth

KB-1, Velocity, Midi Poly Grid, ScaleBud 2, and GeoShred Control need another instrument. KeyPad and Hexatone provide sample playback; Musix Pro provides eight instruments; ThumbJam has a large sampled library; Rubberband has curated voices. [S2][S4][S7][S8][S10][S12][S16][S21][S25][S36][S37]

ExpressionPad has the opportunity to differentiate with a real two-generator synth, sampler, effects, presets, and the same gesture routing used for external MPE. That should be sold as “play immediately, connect later,” not treated as a preview tone.

### 8. Add microtonality deliberately

The fastest credible route is not a giant theory database. It is:

1. Scala `.scl` import/export;
2. arbitrary cents/ratio scale-degree entry;
3. N-EDO generator and non-octave equave;
4. clear keyboard mapping;
5. correct MPE pitch routing with bend-range diagnostics;
6. a small, curated starter library with plain-language descriptions.

This closes the gap with Hexatone/iotaTONE/Entonal while preserving ExpressionPad’s instrument-first identity.

### 9. Keep chord assistance subordinate

ChordPolyPad, Navichord, Tonality, ScaleBud, and Chordion already own prepared harmony, progression discovery, and “never wrong note” workflows. [S19][S25][S27][S29][S34]

Useful additions could include:

- optional chord-shape highlighting;
- chord memory/hold;
- scale-degree and Roman-numeral overlays;
- quick left/right split into chord and lead zones;
- chord-aware melody coloring.

A full chord-generation system would introduce a second product center and compete with much deeper incumbents.

### 10. Pricing evidence

The active paid market spans:

- **$3.99–$9.99:** Midi Poly Grid, Hexatone, Isotope, ScaleBud 2, Navichord, Tonality, ThumbJam, Velocity, Musix Pro;
- **$14.99–$17.99:** KB-1, iotaTONE, Entonal Studio, ChordPolyPad;
- **Free/freemium:** KeyPad, GeoShred Control, Rubberband, Gestrument Pro. [S1]

A polished ExpressionPad can plausibly occupy the premium controller/instrument tier because it includes synthesis, sampling, effects, and a distinct gesture model. Without AUv3, microtonal import, and demonstrated performance reliability, a price near the lower paid cluster is easier to defend. This is a competitive inference, not willingness-to-pay research.

## User-fit segmentation

| User | Best current alternatives | ExpressionPad opportunity |
|---|---|---|
| Grid/LinnStrument/Push player | Midi Poly Grid, Velocity, Musix, KB-1 | Familiar interval grids plus better sound, haptics, and phone play |
| Guitar/bass/string player | GeoShred, Synthecaster, Isotope, KB-1 | Transferable row tunings without committing to a guitar-only UI |
| MPE/SWAM performer | GeoShred, Velocity, KB-1, KeyPad | Explicit full per-note signal path plus integrated synth/sample practice |
| Microtonal/xenharmonic composer | Hexatone, iotaTONE, Entonal, ThumbJam, Rubberband | Continuous full-expression surface once Scala/N-EDO exists |
| Songwriter seeking safe harmony | Navichord, Chordion, ChordPolyPad, Tonality, ScaleBud | Optional chord/scale guidance without giving up individual voices |
| Phone-first performer | Rubberband; historically AC Sabre | Mirror/two-thumb play, haptic frets, tilt, instant sound |
| Beginner/educator | ThumbJam, Musix, Navichord, Tonality | Visual patterns, safe scale views, presets explained by musical outcome |
| Experimental gesture artist | Gestrument, Ribbons, Rubberband | Fretted-to-continuous motion with a more direct finger-to-note relationship |

## Unknowns and contradictions

1. **Hexatone availability:** a combined discovery query intermittently omitted it, but direct Apple US lookup and the live App Store page returned a purchasable app on 2026-07-25. Treat it as available. [S1][S7]
2. **Hexatone MPE:** official copy explicitly limits MPE to per-note microtonal pitch. It should not be scored as full X/Y/Z expression. [S7]
3. **Rubberband Pro price:** descriptive copy names €14.99 while the US storefront currently displays $8.99. The in-app purchase sheet should be checked at launch. [S21]
4. **GeoShred Control upgrade:** cached search snippets surfaced older/lower figures; the current official quick-start and US product evidence support a $24.99 Pro-functionality upgrade. [S12][S13]
5. **Musix Pro status:** cached listings show older builds, but Apple’s live catalog reports v2.5.7 on 2026-07-07. It is active, not abandoned. [S1][S4]
6. **iotaTONE protocols and audio:** the listing calls it an instrument and MIDI controller with FX but does not document the engine, MPE, AUv3, OSC, or precise MIDI behavior. Do not infer them. [S23]
7. **Isotope AUv3:** official copy says its Element sound engine is AUv3 and it can host third-party AU instruments. It does not clearly claim that the controller itself is an AUv3 MIDI plug-in. [S24]
8. **Modern pressure:** iPads and current iPhones lack legacy 3D Touch. Claims of “pressure” may mean contact area, Y movement, Apple Pencil, or an inferred value. Exact behavior needs device testing for GeoShred, KB-1, Velocity, Gestrument, Rubberband, and ExpressionPad.
9. **Maximum touch counts:** most current products do not publish a hard count. iOS device limits, app voice allocation, MPE member channels, and sound-engine polyphony are different limits and should not be conflated.
10. **Legacy-live does not mean reliable:** Navichord, Chordion, Gestrument, Ribbons, and ThumbJam remain listed, but current iOS runtime/host behavior was not tested.
11. **AC Sabre status:** the old App Store URL and Apple lookup return no product. Historical mirrors that still show a purchase link are stale. [S46][S47]
12. **HexyTime:** a polished developer preview exists, but no live App Store product was verified. It is a roadmap signal only. [S48]
13. **Prices and ratings:** all are US point-in-time values. Regional storefronts, sales, bundles, and IAPs vary.
14. **Ratings are directional only:** the newest entrants have tiny samples—KeyPad 6, Midi Poly Grid 7, Hexatone 2, iotaTONE and Rubberband 0—while Musix Pro (137), Velocity (100), KB-1 (270), and Navichord (585) have materially more history. Apple ratings do not measure active users or professional satisfaction. [S1]

## Sources

1. **[S1]** Apple live US lookup, current price/version/update/rating snapshot for the screened apps: https://itunes.apple.com/lookup?country=us&id=6758680165,585857087,6775283069,1633882803,1437919435,1336247116,1462605052,694599930,705067086,6739195820,1667140170,1605842538,1467552236,916452748,1105890031,552182095,6670605972,1433790768,1540587912,6444124951,6781069946,338977566,898059305,425733007
2. **[S2]** KeyPad MIDI Controller — US App Store: https://apps.apple.com/us/app/keypad-midi-controller/id6758680165
3. **[S3]** KeyPad — official discoDSP product page: https://www.discodsp.com/keypad/
4. **[S4]** Musix Pro — US App Store: https://apps.apple.com/us/app/musix-pro-midi-controller/id585857087
5. **[S5]** Musix Pro — official product and layout documentation: https://shiverware.com/musixpro/
6. **[S6]** Musix Pro — official OSC/MIDI details: http://www.shiverware.com/musixpro/oscmidi.html
7. **[S7]** Hexatone — US App Store: https://apps.apple.com/us/app/hexatone/id6775283069
8. **[S8]** Midi Poly Grid — US App Store: https://apps.apple.com/us/app/midi-poly-grid/id1633882803
9. **[S9]** Midi Poly Grid — official open-source repository/manual: https://github.com/anzbert/beat_pads
10. **[S10]** KB-1 Keyboard Suite — US App Store: https://apps.apple.com/us/app/kb-1-keyboard-suite/id1437919435
11. **[S11]** KB-1 — official Numerical Audio page: https://numericalaudio.com/kb1/
12. **[S12]** GeoShred Control — US App Store: https://apps.apple.com/us/app/geoshred-control/id1336247116
13. **[S13]** GeoShred Control — official quick-start and current upgrade explanation: https://www.moforte.com/geoshred-control-quick-start-guide/
14. **[S14]** GeoShred apps — official feature comparison: https://www.moforte.com/feature-comparison/
15. **[S15]** GeoShred — official control-surface manual: https://www.moforte.com/geoShredAssets7000/help/controlSurface.html
16. **[S16]** Velocity Keyboard — US App Store: https://apps.apple.com/us/app/velocity-keyboard/id1462605052
17. **[S17]** Velocity Keyboard — official Blue Mangoo page: http://www.bluemangoo.com/vecocity_keyboard.php
18. **[S18]** Velocity Keyboard — App Store ratings/reviews: https://apps.apple.com/us/app/velocity-keyboard/id1462605052?platform=ipad&see-all=reviews
19. **[S19]** ChordPolyPad — US App Store: https://apps.apple.com/us/app/chordpolypad/id694599930
20. **[S20]** ChordPolyPad — official product/manual page: https://dev.laurentcolson.com/chordpolypad/
21. **[S21]** Rubberband: Microtonal — US App Store: https://apps.apple.com/us/app/rubberband-microtonal/id6781069946
22. **[S22]** Synthecaster — US App Store: https://apps.apple.com/us/app/synthecaster/id705067086
23. **[S23]** iotaTONE — US App Store: https://apps.apple.com/us/app/iotatone-microtonal-keyboard/id6739195820
24. **[S24]** Isotope MIDI Keyboard — US App Store: https://apps.apple.com/us/app/isotope-midi-keyboard/id1667140170
25. **[S25]** ScaleBud 2 — US App Store: https://apps.apple.com/us/app/scalebud-2-auv3-midi-keyboard/id1605842538
26. **[S26]** ScaleBud 2 — official developer page: https://keybudapp.com/scalebud2
27. **[S27]** Tonality — US App Store: https://apps.apple.com/us/app/tonality-music-theory/id1467552236
28. **[S28]** Tonality — official AUv3/MIDI documentation: https://www.tonality-app.com/audio-units/
29. **[S29]** Navichord — US App Store: https://apps.apple.com/us/app/navichord-chord-sequencer/id916452748
30. **[S30]** Navichord — official product page: https://www.navichord.com/
31. **[S31]** Audio News Room — detailed Navichord 2.0 specialist review: https://audionewsroom.net/2016/04/navichord-2-0-review-navigating-the-oceans-of-music.html
32. **[S32]** Gestrument Pro — US App Store: https://apps.apple.com/us/app/gestrument-pro/id1105890031
33. **[S33]** Gestrument Pro — official user guide: https://gestrument.com/userguide/
34. **[S34]** Chordion — US App Store: https://apps.apple.com/us/app/chordion-musical-instrument-midi-controller/id552182095
35. **[S35]** Chordion — official manual: https://www.olympianoiseco.com/apps/chordion/manual/
36. **[S36]** ThumbJam — US App Store: https://apps.apple.com/us/app/thumbjam/id338977566
37. **[S37]** ThumbJam — official documentation: https://thumbjam.com/docs.php
38. **[S38]** mTonal — US App Store: https://apps.apple.com/us/app/mtonal/id1433790768
39. **[S39]** mTonal — official developer page and MPE details: https://skeflect.com/mTonal
40. **[S40]** Entonal Studio — US App Store: https://apps.apple.com/us/app/entonal-studio/id1540587912
41. **[S41]** keyboaredo — US App Store: https://apps.apple.com/us/app/keyboaredo/id6444124951
42. **[S42]** Isomorphic Keyboard — US App Store: https://apps.apple.com/us/app/isomorphic-keyboard/id6670605972
43. **[S43]** Ribbons — US App Store: https://apps.apple.com/us/app/ribbons-touch-instrument/id898059305
44. **[S44]** Ribbons — official Olympia Noise Co. page: https://olympianoiseco.com/apps/ribbons/
45. **[S45]** SoundPrism Pro — US App Store: https://apps.apple.com/us/app/soundprism-pro/id425733007
46. **[S46]** AC Sabre — Apple lookup returning no current product: https://itunes.apple.com/lookup?id=1039046999&country=us
47. **[S47]** Synthtopia — contemporaneous AC Sabre MPE update: https://www.synthtopia.com/content/2017/12/05/ac-sabre-gestural-controller-updated-with-mpe-support/
48. **[S48]** E-String apps page — HexyTime “Coming Soon”: https://e-string.com/apps/

## Internal ExpressionPad evidence consulted

- `README.md`
- `ios/README.md`
- `reference/DESIGN.md`

These local files ground comparisons about ExpressionPad’s actual layouts, touch model, MPE-style output, internal synth/sampler/FX, mirror mode, vibrato, haptics, and current standalone architecture. They are product-development evidence, not external competitive sources.
