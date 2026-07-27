# Touch-native expressive iOS instruments: competitive research for ExpressionPad

**Research date:** 2026-07-25  
**Scope:** iOS/iPadOS instruments whose touchscreen performance surface and internal sound engine make them substitutes for, or expectation-setters around, ExpressionPad. Generic workstations, conventional piano-key synths, and controller-builder apps are excluded except where a product’s touch grammar is itself competitively important.

## Executive findings

The closest current substitutes are not all in the same App Store subcategory. GeoShred, Animoog Z, MorphWiz Studio, TC-11, Etherpad, and ThumbJam compete as complete expressive instruments: a distinctive surface, immediate internal sound, and at least some route into a larger MIDI or host workflow. Samplr, Borderlands Granular, SpaceCraft, and Fluss are not general note controllers, but they set a higher bar for what “made for touch” means because the sound object itself—the waveform, grain cloud, or kinetic modulation—is directly under the fingers. iFretless and Steel Guitar PRO show that a narrower, instrument-specific surface can outperform a general grid at articulation and physical coherence.

The market’s strongest recurring promises are:

1. **This is an instrument, not a miniature desktop synth.**
2. **You can sound musical immediately** through scale constraints, intelligent pitch correction, or gesture-to-sound mappings.
3. **Every finger is expressive**, although products use “MPE” imprecisely: some accept MPE but do not emit it, some emit it only from an AUv3 plug-in, and some still depend on discontinued 3D Touch hardware for true Z pressure.
4. **Touch should expose a relationship that a mouse cannot.** The best examples map continuous motion to continuous pitch, sample position, timbre, feedback, or physical-model articulation.

ExpressionPad’s unusually broad combination—continuous polyphonic pitch, configurable square/hex/piano layouts, internal additive synth and sampler, MPE-style output, two-thumb phone play, haptics, tilt, and user samples—does not have a perfect one-app equivalent. GeoShred is the strongest direct performance benchmark; ThumbJam is the strongest historical “complete instrument plus controller” benchmark; MorphWiz Studio and Animoog Z set the contemporary sound-design/host-integration bar; Samplr and Borderlands remain the category’s clearest interaction-design references. The principal competitive exposure is the lack of an AUv3 instrument/MIDI plug-in path: modern products increasingly make the expressive surface recordable inside the host, while admired IAA/Audiobus-era classics now look isolated.

## Method and normalization

- I screened products through live US App Store pages and Apple’s lookup API, then used official developer sites and manuals for gesture mappings and protocol direction. Specialist reviews were used for learning curve, reputation, and workflow observations, not for current price or availability.
- **Available** means a live US listing and current Apple lookup record were observed on 2026-07-25. It does not prove bug-free operation on iOS 26.
- Update cadence is normalized as:
  - **active:** updated since 2025-01-25;
  - **aging:** last update 2021-01-25 through 2025-01-24;
  - **dormant:** older than that but still listed;
  - **legacy/delisted:** unavailable to new US users or explicitly superseded.
- Protocol claims are directional. “MPE in” does not imply “MPE out”; “AUv3” may mean an audio instrument, effect, or MIDI plug-in; IAA and Audiobus are listed separately because IAA is deprecated.
- “On-ramp” and “accessibility burden” are analyst assessments from the documented interface, unless a cited source explicitly discusses accessibility. No hands-on VoiceOver, Switch Control, motor-access, latency, or current-host test was performed.
- US prices are point-in-time list prices. Sales, regional prices, bundles, restored purchases, and IAP collections can differ.

## Market map

| Interaction lineage | Current leaders | What the user learns | Competitive relevance |
|---|---|---|---|
| Continuous pitch / multidimensional note surface | GeoShred, Animoog Z, MorphWiz Studio, Etherpad, ThumbJam | Horizontal and vertical motion become pitch and timbre; scale aids keep motion musical | Most direct substitutes for ExpressionPad |
| Blank gestural synthesis canvas | TC-11, Bebot, Shoom | Position, distance, angle, motion, and device tilt are the instrument | Sets the bar for immediacy and “screen-native” identity |
| Waveform / granular field | Samplr, Borderlands, SpaceCraft, Fluss | Touch selects and reshapes recorded sound directly | Strongest expectation-setters for sampler UX |
| Instrument-specific physical geometry | iFretless, Steel Guitar PRO, DrumJam | Familiar string/percussion actions are remapped coherently to glass | Shows the value of opinionated articulation over generality |
| Branded MPE lineage | ROLI NOISE, Seaboard 5D | “Five dimensions of touch” and sound packs make expression legible to consumers | Historically influential, but now a maintenance-risk warning |

## Normalized evidence table

Abbreviations: **A3** = AUv3; **AB** = Audiobus; **IAA** = Inter-App Audio; **MI/MO** = MIDI input/output; **MPE I/O** = MPE input/output.

| Product | Status, US price, devices, cadence | Play surface and sound | External integration | Customization, learning/accessibility, role |
|---|---|---|---|---|
| **GeoShred** | Available; $24.99 + instrument IAPs; iPhone/iPad, iOS 15+; v7000.327.1.436, 2026-06-15; **active** [S3][S53] | Guitar-derived isomorphic/string surface; continuous slide, finger vibrato, intelligent pitch rounding, Y expression and legacy pressure; physically modeled guitar plus optional GeoSWAM/Naada models | MI/MO, MPE I/O, A3 instrument/automation, virtual/network/BLE MIDI; can control external synths | Deep tunings, world scales, MIDI profiles, control widgets and effects. Immediate presets but high expert ceiling. **Closest direct substitute.** |
| **Animoog Z** | Available; free shell, $14.99 full unlock plus sound packs; iPhone/iPad/Mac, iOS 14.4+; v1.3.4, 2026-06-08; **active** [S1][S53] | Configurable scale keyboard with polyphonic pitch/pressure gestures; 16-voice Anisotropic Synth Engine morphs through X/Y/Z timbre space; user WAV/recorded timbres | MIDI and MPE I/O, A3 instrument/effect, Ableton Link | Deep timbre editor, 10-lane modulation matrix, envelopes/LFOs/effects. Presets are easy; synthesis depth is substantial. **Sound-design-led direct substitute.** |
| **TC-11** | Available; $24.99; iPhone/iPad, iOS 16+; v3.4.4, 2026-02-16; **active** [S6][S53] | Full-screen canvas with no keys/knobs during play; touch positions, distances, angles, timing and speed plus accelerometer/gyro/compass can drive an 8-voice modular synth | IAA audio generator, AB with state saving; built-in audio recording. No current A3, MIDI-note, MPE, or controller-output claim found | Nearly every synthesis parameter can map to touch/motion; roughly 160–185 presets are claimed inconsistently, plus unlimited patches. Very high programming burden, low conventional transfer. **Strong interaction reference, partial substitute.** |
| **MorphWiz Studio** | Available; $19.99; iPad/Mac, no iPhone; v1.1.2, 2026-06-20; **active** [S9][S53] | Fretless/isomorphic multidimensional surface inspired by Continuum/MorphWiz lineage; spectral engine morphs among four samples; record/import samples | A3 instrument; MIDI/MPE input. Current official material does not clearly prove general expressive MIDI output | Deep modulation, four-sample morphing, arpeggiator, effects and iCloud. Play surface is immediate; sound design is advanced. **Contemporary premium benchmark.** |
| **Etherpad** | Available; free, no paid unlock observed; iPhone/iPad/Mac, iOS 17+; v1.9.1, 2026-07-12; **active/new** [S12][S54] | Scale-based fluid canvas: slide for pitch, vertical drift for tone, per-finger Csound voices; custom/microtonal scales, split iPad surface, nine evolving sounds | A3 instrument; MIDI/MPE and per-note expression are explicitly beta/experimental; MIDI recording/playback advertised | Presets, themes, custom scales, jam tracks; no user sample loading. Extremely low on-ramp, sparse formal documentation, no accessibility claim. **Emerging price/onboarding threat.** |
| **ThumbJam** | Available; $8.99; iPhone/iPad, iOS 8+; v2.6.11, 2022-07-24; **aging** [S25][S54] | Scale-constrained vertical surface with glissando/bends, split instruments, tilt/shake/finger wiggle; 40+ multisampled instruments plus custom multisampling | MI/MO and MPE I/O; AB3 audio/MIDI, IAA, Ableton Link; no A3 | Huge scale/tuning library, Scala import, loops, arpeggiator, physical-control mappings. Easy “no wrong note” start; unusually good VoiceOver/education evidence. **Broad historical direct substitute.** |
| **Samplr** | Available; $19.99; iPad only, iPadOS 12+; v1.5.1, 2026-02-27 with iOS 26 support; **active** [S14][S54] | Waveform is the instrument; eight multitouch grammars including slicer, looper, bow/granular, tape/scratch and keyboard; six sample slots ×16 voices | MIDI keyboard/controller/sync input; Link, IAA, AB input/output; no MPE, MIDI out or A3 claim | File/mic recording, resampling, five effects/sample, gesture recorder. Immediate direct manipulation, then mode-learning. **Canonical touch-sampler expectation-setter.** |
| **Borderlands Granular** | Available; $19.99; iPad only, iPadOS 8+; v2.1.3, 2020-05-13; **dormant** [S18][S54] | Spatial canvas of waveform “sound quads” and movable/throwable grain clouds; gravity, rotation, overlap, probability, ADSR and gesture automation | AB3, IAA-era routing/fixes, Ableton Link; no current MIDI, MPE or A3 | Live buffers, waterfall recording, overdub/resampling, scenes and artist presets. Basic drag is clear; full gesture grammar is deep and visually dependent. **Canonical spatial-sound reference.** |
| **SpaceCraft Granular Synth** | Available; $9.99; iPhone/iPad, iOS 9.3+; v1.2.2, 2021-02-08; **aging** [S21][S54] | Two parallel granular engines; XY panels move through sample position/filter and grain frequency/length, continuously spanning smooth grains, layers and arpeggiation | MIDI/MPE input and CC; A3 instrument/effect, IAA effect; no MIDI-out claim; GarageBand A3 caveat | File/mic/live input, embedded-sample presets, “Infinite” live granulation, standalone recorder. Focused single-page on-ramp; advanced settings hide complexity. **Modern granular bridge.** |
| **Fluss** | Available; $13.99; iPhone/iPad, iOS 12+; v1.4.1, 2025-03-22; **active** [S24][S55] | Three-voice granular engine with kinetic, physics-driven sliders/XY pads that can be flicked into motion as a tactile LFO substitute | MIDI input; A3 instrument, record effect and live-processing effect; no MPE/output claim | Files, recording/live input, custom/Scala scales, light/dark UI. Playful but less note-surface-like than ExpressionPad. **Better current granular comparator than some named legacy apps.** |
| **Mononoke** | Available; $8.99; iPhone/iPad, iOS 10+; v1.2.2, 2021-09-17; **aging** [S29][S54] | Eight X/Y/pressure-style pads drive two four-voice feedback/FM-like engines; pads latch into evolving drones | A3 instrument with MIDI/MPE I/O; separate Mononoke Pads A3 MIDI controller; standalone has no connectivity | Tunable/quantized pads, feedback routing, presets; elegant two-screen model, but intentionally narrow sound world. **Excellent pad-to-sound coherence reference.** |
| **Shoom** | Available; $6.99; iPad only, iPadOS 9+; v1.2.2, 2020-12-18; **dormant** [S32][S54] | Three independent XY subtractive synths; X spans pitch, Y maps to up to three parameters; free, scale-snapped, microtonal and non-octave tunings | MIDI/MPE input, CC, clock, BLE; IAA multi-outs, AB3 and Link; no A3 or MIDI-output claim | 120+ presets, custom scales/tunings, CC-map import/export. Very playable drones/leads; no gesture recorder. **Strong continuous-canvas lineage.** |
| **iFretless Bass / family** | Bass $14.99; Guitar/Sax/Brass $9.99 each; universal iPhone/iPad; all updated 2025-09-24; **active** [S35][S56] | Dense eight-string fret grid, lateral slides/vibrato, accelerometer-derived touch-force selection of sampled dynamic layers; instrument-specific libraries | MIDI I/O and A3 throughout; Bass/Brass explicitly advertise MPE; do not infer MPE for Guitar/Sax | Closed libraries, tunings and tone tools rather than sampling. String players adapt fastest; dense visual grid and precise slide demand practice. **Niche but serious substitute.** |
| **Steel Guitar PRO** | Available; $9.99; iPhone/iPad, iOS 14+; v1.1, 2022-07-08; **aging** [S37][S54] | Two-handed pluck-and-slide interface; multi-touch bar slant/damping, high-resolution vibrato, virtual bend pedals, configurable copedent; modeled/generated guitars, amps and FX | A3 instrument/MIDI plug-in and traditional MIDI input; custom multi-channel sub-protocol; no MPE/general controller-output claim | Deep surface geometry, handedness, tunings, rigs, pedals and signal chain. High motor/technique burden. **Best specialist articulation benchmark.** |
| **DrumJam** | Available; $7.99 + optional world-percussion packs; iPhone/iPad, iOS 9+; v1.4.5, 2022-07-24; **aging** [S40][S54] | Layered recorded percussion loops plus quantized solo pad/XY performance; drag gestures select/play rhythmic material and effects | MIDI I/O and clock, virtual/wireless MIDI, IAA, AB and Link; no A3/MPE | Loop layering, randomization, time signatures, effects, performance recording/export. Very low novice barrier; strong percussion specificity. **Indirect rhythmic substitute.** |
| **Bebot** | Available; $1.99; iPhone/iPad, iOS 8+; v2.1.1, 2017-09-11; **dormant** [S43][S54] | Friendly animated robot over a polyphonic touch canvas; scale lock, slides and gestures feed a surprisingly editable synth | AB3 and IAA; no current MIDI, MPE or A3 claim | Presets plus editable synth/effects. Extremely approachable and memorable, but isolated and stale. **Historical onboarding/character reference.** |
| **ROLI NOISE** | **Delisted in US:** direct page returned 404 and Apple lookup returned no record on 2026-07-25; historically free + sound-pack IAP; last update 2018-04-30 [S44][S45] | Grid/Seaboard-style touch instrument for beats, melodies and loops; tap, slide, press and lift; large branded sound-pack catalog | Historically A3 kits and tight ROLI BLOCKS integration; not a dependable current workflow | Strong consumer onboarding and artist packs; account/content dependence plus abandonment make it a cautionary lineage case. |
| **Seaboard 5D** | Still listed free; iPhone/iPad, iOS 9+; v1.8.5, 2016-11-16; **legacy/dormant** [S46][S54] | On-screen “keywaves” advertise Strike, Glide, Slide, Press and Lift; 25 included sounds plus historical packs; true Press required specific 3D Touch iPhones | Bluetooth MIDI and MPE input/sound-module role; no current A3 or general screen-controller output claim found | Surface size/macros/sounds are adjustable. Easy brand story, but hardware assumptions and decade-old build make it a lineage reference, not a safe recommendation. |
| **touchscaper** | Available; $4.99; iPad only; v1.6.2, 2025-01-30; explicitly **maintenance mode** [S47] | Radar, ribbon and keyboard surfaces with a semi-generative sampled engine; movement affects per-note volume/pan | MIDI out with optional MPE, IAA, Link; no A3 | Chords, scenes, instruments, arrangements and sequencer are deep; “good notes” create fast success. Relevant but more generative/compositional than ExpressionPad. |
| **VOLT Synth** | Available; $19.99; iPhone/iPad; v1.4.5, 2020-10-27; **dormant** [S48][S55] | Virtual-analog synth with five on-screen layouts and a 4D/2D expressive keyboard | MPE input, A3, IAA, AB, Link; no expressive MIDI-out claim | Strong preset synth and MPE sound module, but its surface is less distinctive and less configurable than direct leaders. |
| **BEATSURFING 2** | Available; free + IAP; iPad; v1.0.34, 2025-05-01; **active** [S49][S55] | User-built motion-based drum/sample instruments and visual layouts | MIDI out, Link, A3 added; current reviews report host instability | Highly customizable and relevant to touch-native percussion, but belongs primarily with controller/surface builders. App copy says “no subscriptions” while the listing exposes a monthly premium IAP—see contradictions. |
| **MOUND** | Available; free + IAP; iPad-first; v1.0.3, 2026-07-06; **new** [S50][S55] | Collage/paint canvas generates four SoundFont layers with Euclidean sequencing and brush-driven XY effects | A3 instrument and MIDI advertised | Fresh and visually native, but too new and generative to count as a proven direct substitute. Worth watching. |
| **Saucillator** | Available; free; iPhone/iPad, iOS 16.6+; v4.9.0, 2026-07-21; **active/new** [S51][S55] | XY synth pad with user-built harmonic timbres, effects, looping and beat tools | External MIDI input and A3 instrument; no MPE/output claim | Beginner-friendly surface plus community patch sharing. A useful 2025–26 signal that free/A3/touch-first is becoming an entry-level expectation. |

## Deep profiles

### 1. GeoShred: the closest complete performance benchmark

**Marketing promise.** GeoShred explicitly sells itself as an instrument rather than an app: a pitch-fluid surface that still helps the player land accurately in any temperament. Its awards, Jordan Rudess association, world-scale support, and optional physically modeled instruments reinforce a serious-performer identity rather than a casual synth-toy identity. [S3][S4]

**Interaction and expression.** The main surface is a guitar-derived isomorphic/string grid. Horizontal movement produces continuous pitch, finger vibrato and slides; intelligent pitch rounding allows the player to move between fretless and diatonic behavior. Vertical position/movement is available as expression, commonly CC74/timbre, while true Z pressure is limited by device hardware; on modern devices the product must reuse position/motion rather than rely on discontinued 3D Touch. Mono, per-string and per-note/MPE routing make the same surface useful for modeled guitar, solo winds/strings, and external synths. [S4][S5]

**Sound and connectivity.** The base paid app includes a physically modeled guitar and a substantial modeled FX chain. GeoSWAM and Naada IAPs extend it into orchestral and global instruments, though some of those models are monophonic. MIDI/MPE input and output, A3, virtual/network/Bluetooth/wired MIDI, preset sync and an editable control surface make GeoShred one of the few products that is both a complete instrument and a credible external controller. [S3][S5]

**Customization, learning and accessibility.** Tunings, ragas/world scales, diatonic layouts, MIDI profiles, surface widgets, effects and presets are unusually deep. Pitch rounding and help bubbles reduce the initial penalty, but the product vocabulary—strings, per-string channels, modeled articulation, effects, MIDI profiles, and IAP families—is substantial. No current official VoiceOver claim was found. Visual note guidance and pitch assistance help learning; exact spatial touch and many small controls remain accessibility burdens.

**Strengths.**

- Best combination of pitch intelligence, continuous articulation, serious sound and external control.
- Active 2026 maintenance and cross-device/desktop ecosystem expansion.
- Strong non-Western scale/temperament credibility.
- Performance presets and modeled instruments demonstrate why an expressive surface needs sounds designed around it.

**Weaknesses.**

- The opinionated guitar/isomorphic model is less geometrically free than ExpressionPad.
- Product/IAP architecture is complex and can become expensive.
- Pressure claims need device-specific qualification.
- Its depth can obscure the “pick up and play” story.

**Implication for ExpressionPad.** Treat GeoShred, not a generic MIDI keyboard, as the primary benchmark for pitch rounding, vibrato, MPE reliability, scale/tuning breadth, and “real instrument” marketing. ExpressionPad’s configurable square/hex/piano layouts and mirrored two-thumb phone mode are credible differentiators only if their pitch behavior feels equally intentional.

### 2. Animoog Z: the sound-design-led direct substitute

**Marketing promise.** Animoog Z promises multidimensional performance and sound design inside one visually animated Moog instrument. The Anisotropic Synth Engine moves each voice through a three-dimensional field of timbres; the surface and sound engine are marketed as one multisensory system rather than separate keyboard and synthesizer modules. [S1][S2]

**Interaction and expression.** Its scale keyboard supports configurable key spacing, pitch correction and glide. Each voice can receive independent pitch and pressure-like movement from the keys, while the animated Wave Cube exposes the evolving timbral orbit. The result is a more familiar note surface than TC-11 or Borderlands, but with continuous per-note motion that conventional piano apps do not provide. [S1][S2]

**Sound and connectivity.** The 16-voice ASE combines wavetable/vector-like motion with Moog-derived and digital timbres. Users can record or import WAV material into the Timbre Editor; three envelopes, three LFOs, a 10-lane modulation matrix, effects, arpeggiator and looper turn it into a deep synthesizer. It supports MIDI and MPE input/output, A3 instrument/effect operation, and Ableton Link. [S1][S2]

**Customization, learning and accessibility.** The free shell and polished presets create an excellent first-session funnel, while the full editor supports expert exploration. The animated display makes modulation legible, but it also makes the app highly visual; no formal VoiceOver claim was found. The full unlock at $14.99 positions it below several $19.99–$24.99 premium instruments while using sound packs for continuing revenue.

**Strengths.**

- Strongest union of premium brand, rich internal sound and an expressive keyboard.
- User timbre import turns the sampler into synthesis material rather than a separate mode.
- Current 2026 maintenance and modern A3 integration.
- Free-to-try acquisition model with a clear full unlock.

**Weaknesses.**

- Layout is far less configurable than ExpressionPad.
- Visual synthesis depth can dominate the performance-surface story.
- Official materials are clearer about MPE input than standards-compliant MPE output; do not overstate controller parity.

**Implication for ExpressionPad.** A compelling internal sound is not merely a checkbox. Animoog Z shows that the gesture, animation, preset, and engine should communicate the same expressive idea. ExpressionPad should demonstrate pressure/slide changing musically meaningful timbre, not only advertise that MIDI messages are emitted.

### 3. MorphWiz Studio: the current premium Continuum lineage

**Marketing promise.** MorphWiz Studio revives the influential Jordan Rudess/MorphWiz lineage as a serious spectral morphing instrument. It promises that movement, pressure and nuance become part of the performance, while four-sample spectral morphing, MPE and A3 make the product relevant in a modern studio. [S9][S10][S11]

**Interaction and expression.** The iPad surface is fretless and multidimensional, explicitly compared with a violin in the manual. It can control pitch and voice character continuously and is designed for MPE performance. This is one of the clearest current comparisons for ExpressionPad’s slide/frets continuum: both products ask the player to move between quantized note certainty and continuous pitch expression. [S10]

**Sound and connectivity.** The engine analyzes, records or imports up to four sample sources and morphs among them, with a modulation matrix, four envelopes, four LFOs, filters, effects and a programmable arpeggiator. A3 and MPE input are documented. General expressive MIDI output from the screen is not documented clearly enough to claim parity with ExpressionPad’s MPE-style controller role. [S9][S10][S11]

**Customization, learning and accessibility.** Surface play is conceptually direct, but sample analysis, spectral morphing and modulation are advanced. iCloud preset/sample synchronization supports continuity. It is iPad-only on mobile, giving ExpressionPad a phone opportunity. The App Store’s minimum-OS wording conflicts with the manual (see Unknowns); no formal accessibility claim was found.

**Strengths.**

- Strong current touch-performance identity and high-end sound design.
- Modern A3/MPE workflow.
- User sampling integrated into the synthesis model.
- Clear premium one-time price with no subscription.

**Weaknesses.**

- No iPhone version.
- High sound-design and modulation learning curve.
- MIDI-output/controller capability is unclear.

**Implication for ExpressionPad.** MorphWiz Studio raises expectations around sample ownership, modulation depth, and hostability. ExpressionPad need not match its spectral engine, but its simpler synth/sampler story should be positioned as speed and playability, not as an equivalent sound-design environment.

### 4. TC-11: the purest programmable gestural-synth reference

**Marketing promise.** TC-11 calls itself a fully programmable multi-touch synthesizer and removes keys, sliders and knobs from the performance canvas. The promise is radical: distances, angles, touch timing, motion and device orientation are synthesis controllers. [S6][S7][S8]

**Interaction and expression.** During play, the whole screen is a sensing field. A patch can map absolute touch position, relationships between multiple touches, rotation, speed and timing to synthesis parameters. Accelerometer, gyroscope and compass can drive vibrato, filters, effects or sequencer behavior. This supports gestures that cannot be represented cleanly as conventional notes, but also makes learned technique patch-specific. [S7][S8]

**Sound and connectivity.** TC-11 provides an eight-voice synth with oscillator, filter, effect, AHDSR, LFO, table and sequencer objects; current official surfaces inconsistently claim 160 or 185 presets, plus unlimited patches, recording, IAA generator operation and Audiobus state saving. It does not advertise A3, MIDI note/MPE I/O, or use as a general controller. The 2026 update is a valuable maintenance signal, but it does not modernize the published integration model. [S6][S7][S8]

**Customization, learning and accessibility.** Patch construction is exceptionally deep, and display appearance is customizable. Presets provide instant results, but understanding why a patch responds to a particular two-finger angle or device tilt is harder than understanding a labeled grid. The blank surface can be visually uncluttered yet cognitively opaque. Motion dependence may exclude desk use or some motor-access contexts; no formal VoiceOver claim was found.

**Strengths.**

- Most audacious exploitation of multi-touch relationships and device motion.
- A decade-plus product with a 2026 maintenance release.
- Demonstrates how a full-screen performance mode can feel alive and uncluttered.

**Weaknesses.**

- Patch-specific technique and steep programming burden.
- Limited modern host/controller interoperability.
- Hard to communicate precise, repeatable note behavior.

**Implication for ExpressionPad.** ExpressionPad should borrow TC-11’s conviction, not its opacity: collapse controls completely during performance, show responsive visual/haptic feedback, and make advanced expression mappings powerful—but keep pitch geometry stable enough that practice transfers between presets.

### 5. Etherpad: the 2026 low-friction challenger

**Marketing promise.** Etherpad’s message is essentially “no keys, no rules—touch and feel.” It targets ambient/drone creation, beginners, children, improvisers and experimental musicians with scale safety, reactive visuals and a free price. [S12][S13]

**Interaction and expression.** A finger’s horizontal movement glides through scale-constrained pitch; vertical movement changes tone; lift shapes the release. Multiple fingers behave independently, and iPad split mode provides two instruments side-by-side. Custom scales include conventional and microtonal choices. [S12][S13]

**Sound and connectivity.** Nine Csound-based voices, effects, presets, jam tracks and performance recording make it self-contained. A3 and MIDI/MPE output/playback are being developed rapidly, but the developer labels important pieces beta or experimental. Community reports from July 2026 document active fixes to pitch-bend/MPE recording, which is encouraging but also confirms workflow immaturity. [S12][S13]

**Customization, learning and accessibility.** The on-ramp is among the lowest in the survey: choose a key/scale/sound and move. Custom scales and split mode add meaningful depth without a large editor. It does not currently offer user sampling or extensive surface geometry. No formal VoiceOver claim was found, though the large continuous field and simple control set may be easier to approach than dense synth panels.

**Strengths.**

- Free, actively updated, universal, and A3-capable.
- Very clear gesture-to-sound story.
- Strong beginner/ambient positioning.
- Split surface validates two-handed iPad performance.

**Weaknesses.**

- New and lightly validated.
- MIDI/MPE and A3 behavior is still labeled beta/experimental.
- Limited sound count and surface customization.

**Implication for ExpressionPad.** Free and immediate is now a credible competitive floor. ExpressionPad’s marketing must make its added geometry, sampler, haptics and MIDI depth obvious within seconds; a dense control screenshot alone will lose against Etherpad’s simpler promise.

### 6. ThumbJam: the durable “complete musical performance” benchmark

**Marketing promise.** ThumbJam promises high-quality real instruments, hundreds of scales, and “no wrong notes” for novices without dismissing professionals. It is explicitly positioned as an expressive substitute for an instrument the performer did not bring. [S25][S26]

**Interaction and expression.** The main strip/grid constrains notes to a selected scale while preserving glissando, bends and per-touch expression. Tilt, shake, X movement, finger wiggle and (on old hardware) 3D Touch can map to volume, pitch, vibrato, tremolo or filter. It supports up to five iPhone or eleven iPad touches and can split/load multiple instruments. [S25][S26]

**Sound and connectivity.** More than 40 multisampled instruments, free downloads, a looper and arpeggiator are supplemented by user-created multisampled instruments. CoreMIDI and channel-per-touch/MPE input and output are unusually complete for an older app. AB3, IAA and Link remain, but there is no A3. [S25][S26]

**Customization, learning and accessibility.** Users can build/import scales (including Scala), customize instruments, assign physical expression, create splits and layer loops. This is the strongest accessibility evidence in the group: accessible-music education material exists, and AppleVis demonstrates VoiceOver/Direct Touch workflows and custom instrument creation. The old, dense settings model still creates discoverability cost. [S27][S28]

**Strengths.**

- Broadest historical combination of internal instruments, custom sampling, scales, looping and expressive MIDI output.
- Proven beginner and accessibility story.
- Strong world-scale and user-content support.
- Low $8.99 one-time price.

**Weaknesses.**

- No A3/multi-instance modern-host path.
- Last update in 2022.
- Some official polyphony and feature copy is stale or contradictory.

**Implication for ExpressionPad.** ThumbJam is the benchmark for progressive disclosure: instant scale-safe play, followed by deep instrument creation and MIDI. ExpressionPad can surpass its integration and visual polish, but should study its accessibility materials and make a real VoiceOver/Direct Touch plan rather than assume a full-screen canvas is self-explanatory.

### 7. Samplr: the canonical direct-manipulation sampler

**Marketing promise.** Samplr calls itself “The Multitouch Sampler” and argues that its instrument is possible only on a multi-touch device. Its artist validation—including Fred again.. describing the feeling of playing the sample—supports a studio/live-performance identity rather than novelty. [S14][S15][S16]

**Interaction and expression.** The waveform is both visualization and performance surface. Eight modes give it different grammars: tap slices, hold loop regions, bow/granulate around fingers, scrub tape/scratch, arpeggiate, play chromatically, or run a loop. Gestures can be recorded and continue while the player changes modes, converting improvisation into composition. [S14][S15]

**Sound and connectivity.** Six sample slots support sixteen voices each, five effects per sample, mic/input recording and resampling. The 2024 update added MIDI keyboard/controller input; the 2026 update explicitly added iOS 26 support. Link, IAA and AB are present, but A3, MPE and expressive MIDI output are not. [S14][S16]

**Customization, learning and accessibility.** File import and resampling provide broad sonic ownership even though the surface geometry itself is fixed. Immediate directness is excellent; the deeper burden is learning eight mode-specific gesture vocabularies and legacy routing/export conventions. Sound On Sound described it as accessible in the general usability sense, but no formal VoiceOver support was verified. [S17]

**Strengths.**

- Best model of “touch the sound itself.”
- Gesture recording preserves improvisation.
- Active compatibility maintenance despite its age.
- Focused visual language and strong reputation.

**Weaknesses.**

- iPad-only, no A3/multi-instance state restoration.
- No expressive MIDI output or MPE.
- Fixed six-slot structure.

**Implication for ExpressionPad.** ExpressionPad’s sampler currently behaves like a note source selected behind the same grid. Samplr shows the opportunity for a future sample-edit/play view in which start, loop, scrub or grain position is directly touchable, without compromising the main note surface.

### 8. Borderlands Granular: the spatial-sound benchmark

**Marketing promise.** Borderlands asks users to “explore, touch, and transform sound” and explicitly prioritizes gesture over knobs and sliders. Its reputation rests on making audio files and grain clouds feel like manipulable objects in a sonic landscape. [S18][S19]

**Interaction and expression.** Waveforms become “sound quads”; movable, throwable, scalable and rotatable grain clouds read from those sources. Position, overlap, size, gravity, automation and cloud parameters create a playable ecology. Touch paths and parameter movements can be recorded; later versions added trigger pads, ADSR, semitone tuning, probability, ring modulation and waterfall input. [S18][S20]

**Sound and connectivity.** The app imports/records audio, accepts live inputs, overdubs and resamples. Scenes save sounds, clouds and automation for performance. AB3, Link and IAA-era workflows are documented. MIDI, MPE and A3 were roadmap aspirations, not shipped current capabilities. [S18][S20]

**Customization, learning and accessibility.** Spatial object manipulation is discoverable at a basic level, but multi-finger rotation, ghost clouds, background-touch modes, automation and scene management create a dense hidden grammar. The app is iPad-only and highly visual, with no verified VoiceOver claim. Its last update was in 2020.

**Strengths.**

- Most distinctive spatial/kinesthetic model in the category.
- Excellent improvisation-to-scene/automation workflow.
- Makes multiple simultaneous audio sources legible.

**Weaknesses.**

- Dormant, no A3/MIDI/MPE.
- IAA/Audiobus-era isolation.
- Hidden gestures can cause accidental actions and poor recall.

**Implication for ExpressionPad.** Visual delight should express a sound relationship, not decorate it. ExpressionPad’s ripples are memorable; they will become strategically stronger if they also convey pitch/pressure/voice state or can affect sound in a controlled way.

### 9. SpaceCraft Granular Synth: focused modern granular expression

**Marketing promise.** SpaceCraft promises to transform any sound into a playable musical instrument and deliberately optimizes for immediate, single-page creative flow. [S21][S22][S23]

**Interaction and expression.** Two engines expose large XY regions. One controls source playhead/filter; another changes grain frequency/length such that a continuous drag traverses arpeggiated ticks, layered sample playback and smooth granulation. In MPE mode, X can bend pitch, Y can move through source position/timbre, and Z can control level; an alternate MPE Grain mode changes that emphasis. [S22]

**Sound and connectivity.** Each engine uses multiple grain streams, supports built-in, imported, mic and live input, and can run an “Infinite” near-zero-latency live granular buffer. It is an A3 instrument and effect, supports IAA effect use and accepts MIDI/MPE/CC. It does not advertise expressive MIDI output. GarageBand compatibility has explicit restrictions. [S21][S22]

**Customization, learning and accessibility.** The stable one-page architecture is a strong beginner bridge. Presets embed source samples; advanced MPE, interpolation, filter and quality options remain tucked away. It is universal and inexpensive, but has not been updated since 2021. No formal accessibility claim was found.

**Strengths.**

- Best balance of touch clarity, A3 and MPE among the older granular group.
- Source position is a meaningful expression dimension.
- Universal and $9.99.

**Weaknesses.**

- Aging build and host-specific caveats.
- Less spatial/multilayered than Borderlands.
- Input-only expressive MIDI role.

**Implication for ExpressionPad.** Meaningful default expression mappings matter more than the number of messages. SpaceCraft’s Y-to-source-position mapping is easy to hear. ExpressionPad presets should make pressure/CC74 audibly purposeful out of the box.

### 10. Fluss: a better current comparator than several legacy names

**Marketing promise.** Fluss is a tactile granular playground designed by Bram Bos and Hainbach. Its central claim is that kinetic controls—sliders and pads connected to a physics model—are a reason to use a touchscreen rather than a substitute for mouse-controlled knobs. [S24]

**Interaction and expression.** Three grain voices have independent playheads. Sliders/XY pads can be flicked, bounced and allowed to coast, turning touch momentum and friction into modulation. This is less of a note grid than ExpressionPad, but it is an important current example of gesture leaving a persistent, audible trace after release.

**Sound and connectivity.** Files, recording and live processing feed the granular engine; custom scales, unquantized operation and Scala import support pitch experimentation. The app ships separate A3 instrument, record-effect and process-effect forms and accepts MIDI. MPE and MIDI output are not advertised. [S24]

**Customization, learning and accessibility.** Physics makes experimentation inviting, while granular parameters and multiple plug-in roles create a moderate expert curve. Light/dark modes help environment fit, but no VoiceOver claim was found. The 2025 update makes it a more credible current comparator than dormant Shoom, Borderlands or SpaceCraft when evaluating support expectations.

**Strengths.**

- Touch-native modulation that remains active after the finger lifts.
- Modern multi-role A3 architecture.
- Universal, custom-scale aware, current enough to be commercially relevant.

**Weaknesses.**

- Narrow granular role and only three voices.
- Not a general external expressive controller.

**Implication for ExpressionPad.** Consider recordable or inertial expression beyond note hold—gesture capture, throwable modulation, or pressure/tilt trails—only if it remains predictable. Fluss succeeds because physics is the explicit instrument concept.

### 11. Mononoke: narrow sound, exceptionally coherent pads

**Marketing promise.** Mononoke is an “expressive drone synthesizer” for evolving soundscapes, not a general-purpose synth. The developer says the player steers a complex entity rather than controlling every internal process. [S29][S30]

**Interaction and expression.** Eight independently tunable pads map X to pitch bend, Y/aftertouch-like motion to expression, and touch position to velocity-like behavior. Each pad can latch, so some voices drone while others are performed. Two four-voice engines feed back into each other, making all eight touches parts of one interacting sound. [S29][S31]

**Sound and connectivity.** The engine behaves like a network of FM/feedback operators with simple front-panel controls and hidden interconnected modulation. In an A3 host it accepts and emits MIDI/MPE; a separate included Mononoke Pads A3 MIDI plug-in exposes the surface as a controller. Standalone mode is intentionally isolated. [S29]

**Customization, learning and accessibility.** Pad tuning/quantization, feedback routing, synth parameters and presets offer useful depth, but the sonic identity remains intentionally constrained. The two-screen interface is elegant and learnable. No formal accessibility claim was found; the large pads are promising, but expression depends on continuous spatial touch.

**Strengths.**

- One of the clearest examples of surface and engine co-design.
- A3 MIDI-output plug-in makes touch performance recordable.
- Latching supports layered one-person performance.

**Weaknesses.**

- Narrow drone/texture palette.
- Standalone connectivity is deliberately absent.
- Last update in 2021.

**Implication for ExpressionPad.** A broad engine benefits from a few presets where every gesture clearly belongs to the sound. Mononoke proves that constraint can make an instrument memorable; ExpressionPad should market a handful of signature “play behaviors,” not only a feature inventory.

### 12. Shoom: expressive XY synthesis and microtonal breadth

**Marketing promise.** Shoom is an expressive XY-pad synthesizer—three identical synths in one app—capable of continuous pitch across the audible range or scale-snapped conventional, xenharmonic and non-octave tunings. [S32][S33]

**Interaction and expression.** X is pitch across a large field; Y can modulate up to three destinations. Notes may glide freely or snap to a scale with adjustable glide, and voices can hold indefinitely. The surface is unusually good for drones, leads and microtonal motion because pitch space is not forced into a piano geometry. [S33][S34]

**Sound and connectivity.** Each section is a two-oscillator subtractive synth with FM, filters, envelopes, LFOs, delay and reverb. MIDI/MPE input, CC, clock, Bluetooth, IAA multi-outs, AB3 and Link are supported; no A3 or MIDI-output/controller claim was found. [S32][S33]

**Customization, learning and accessibility.** Custom scales, non-octave tunings, preset/CC-map import/export and three independent layers are strong. The main XY field is easy to approach, while modulation routing and microtonal setup take time. No gesture recorder or formal accessibility support was found. The last update was 2020.

**Strengths.**

- Excellent continuous-pitch and microtonal exploration.
- Clear full-screen performance field.
- Low $6.99 price.

**Weaknesses.**

- iPad-only, dormant and no A3.
- MPE input but not screen-generated MPE output.
- Missing gesture recording/arpeggiation limits repeatability.

**Implication for ExpressionPad.** ExpressionPad’s column scales, row tunings and fret/slide continuum can own a broader “continuous but musically guided” position. Microtonal and non-octave support would deepen that claim if implemented without overwhelming the main setup flow.

## Secondary profiles and lineage

### iFretless family

The iFretless apps compress an eight-string fretboard into a dense, piano-color-coded grid. Lateral motion makes independent slides and vibrato; an accelerometer-derived force algorithm selects dynamic sample layers even without 3D Touch. Bass and Brass explicitly advertise MPE, while Guitar and Sax do not, so family-wide MPE claims are unsafe. All four were maintained in September 2025 and support A3. The family’s strengths are high note density, string-player transfer and nuanced sampled dynamics; weaknesses are four fragmented purchases ($44.96 total), closed libraries, inconsistent feature claims and a dense visual/motor surface. [S35][S36][S56]

### Steel Guitar PRO

Steel Guitar PRO deliberately separates plucking and pitch between two hands. A continuous bar can slant with two fingers, damp strings, vibrate, and actuate up to seven configurable bend pedals through tilt, touch or MIDI. The copedent, tunings, string spacing, handedness, rigs, amps and effects are deeply editable. Its custom A3 MIDI-derived protocol preserves internal steel semantics but is not general MPE. It is an excellent lesson in coherent specialist articulation and a poor template for a universal controller. [S37][S38][S39]

### DrumJam

DrumJam combines recorded world-percussion loops with quantized solo-pad improvisation, effects, randomization and time-stretching. MIDI in/out and clock, virtual/wireless MIDI, IAA, AB and Link make the live pad externally useful, but the product has no A3 or MPE. Its “even a novice can get a groove immediately” design is a useful rhythm/onboarding reference, not a direct melodic substitute. [S40][S41][S42]

### Bebot

Bebot’s animated robot gives an approachable face to a polyphonic scale-locked continuous surface, while an editable synth and effects reward experimentation. Its $1.99 price, stage use and memorable character made it influential; lack of MIDI/A3 and a 2017 last update make it historical rather than strategically dangerous. [S43]

### ROLI NOISE and Seaboard 5D

These apps popularized a consumer story around Strike, Glide, Slide, Press and Lift, artist sound packs, and hardware/software continuity. NOISE’s US URL now returns 404 and Apple’s API no longer returns a US record, even though ROLI support pages and cached App Store text still describe it. Seaboard 5D remains listed, but its build dates to 2016 and full “Press” depended on particular 3D Touch phones. Their lasting lesson is the clarity of naming expression dimensions; their commercial lesson is the trust damage caused when purchased sound ecosystems outlive maintained software. [S44][S45][S46]

### touchscaper, VOLT, BEATSURFING 2 and the new 2026 cohort

touchscaper is a touch-native, semi-generative instrument with MIDI/MPE out, but the developer explicitly placed it in maintenance mode because of IAA dependence. VOLT remains a capable A3/MPE sound module with several expressive layouts, though its last update was 2020 and its surface is less distinctive. BEATSURFING 2 brings user-designed movement/sample surfaces and A3/MIDI out but belongs primarily in the controller-builder/percussion category and has reported host roughness. MOUND and Saucillator are more important as trend signals: new entrants are launching free, visually native and A3-aware, narrowing the merchandising window for a paid app that does not demonstrate immediate differentiation. [S47][S48][S49][S50][S51]

## Cross-market patterns

### 1. “Expressive” splits into at least five technical claims

The listings routinely collapse distinct abilities:

1. per-finger movement affects internal sound;
2. the engine accepts external MPE;
3. the screen emits per-note expressive MIDI;
4. the screen’s MIDI can be recorded and replayed correctly inside an A3 host;
5. the device senses real pressure rather than initial Y position, touch area, motion, or a proxy.

GeoShred and ThumbJam cover most of the chain. Mononoke covers it inside A3 but not standalone. Animoog Z is strong as an MPE sound engine and expressive MIDI keyboard, while its exact output mode deserves hands-on verification. SpaceCraft, Shoom and VOLT mainly accept MPE. TC-11 is highly expressive internally without presenting itself as MPE. Seaboard 5D’s “Press” was hardware-contingent. ExpressionPad should market its concrete outputs—per-touch channels, pitch bend, channel pressure and CC74—and show a recorded/replayed performance rather than merely display an MPE badge.

### 2. Stable dimensional mappings beat feature counts

The most learnable surfaces give each axis a durable musical meaning:

- GeoShred: horizontal pitch, vertical timbre/articulation, pressure/dynamics where available.
- SpaceCraft: pitch and location inside the source recording.
- Mononoke: per-pad pitch/expression inside a feedback network.
- Steel Guitar: one hand excites strings; the other controls pitch.

TC-11’s arbitrary mapping is more powerful but less transferable. ExpressionPad’s default mappings should remain stable across presets even while expert routing is configurable.

### 3. Scale safety is the dominant onboarding device

GeoShred, Animoog Z, Etherpad, ThumbJam, Bebot, Shoom and touchscaper all promise some combination of pitch rounding, scale constraint, “good notes,” or no wrong notes. This is not merely a beginner feature: it frees experts to use continuous motion aggressively. ExpressionPad’s frets/slide controls, row tunings, column scales and in-key vibrato are highly marketable if explained as a continuum between precision and fluidity.

### 4. User sound ownership is common in category leaders

Animoog Z records/imports timbres; MorphWiz Studio analyzes four user samples; Samplr, Borderlands, SpaceCraft and Fluss build the instrument around imported/live sound; ThumbJam creates multisampled instruments. ExpressionPad’s one user-sample slot is valuable, but it will be compared with preset libraries, sample management, recording and gesture workflows rather than with “sample import: yes/no.”

### 5. AUv3 is becoming the longevity boundary

MorphWiz Studio, Animoog Z, GeoShred, Mononoke, SpaceCraft, Fluss, iFretless and newer entrants can live inside modern hosts. Samplr, Borderlands, ThumbJam, Shoom, Bebot and DrumJam remain admired but depend on standalone, IAA or Audiobus-era workflows. touchscaper explicitly links maintenance mode to deprecated IAA technology. A3 is therefore both a workflow feature and a buyer-confidence signal.

### 6. One-time pricing dominates, with two broad bands

The credible paid set clusters around:

- **$6.99–$13.99:** Shoom, DrumJam, ThumbJam, Mononoke, SpaceCraft, Steel Guitar PRO, Fluss;
- **$14.99–$24.99:** iFretless Bass, Animoog Z full unlock, MorphWiz Studio, Samplr, Borderlands, GeoShred and TC-11.

Free acquisition is increasingly common through Animoog Z’s shell, Etherpad, BEATSURFING 2, MOUND and Saucillator. Subscriptions are rare and can conflict with category expectations; BEATSURFING’s listing/copy contradiction is conspicuous.

### 7. Accessibility is under-documented

ThumbJam is the exception, with accessible-music education material and documented VoiceOver/Direct Touch workflows. Most products make no VoiceOver, Dynamic Type, reduced-motion, alternative-input or haptic claim. Continuous spatial surfaces can be large and uncluttered but still exclude blind users without semantic regions and audio/haptic landmarks. ExpressionPad’s note labels, hardware-keyboard layouts and fret haptics are differentiating raw materials, but they need an explicit accessibility design and test story.

### 8. Cadence matters more than age

Samplr (2012 lineage) and TC-11 (2011 lineage) received 2026 compatibility releases; GeoShred, Animoog Z and MorphWiz Studio are actively evolving. Borderlands, Shoom, Bebot, SpaceCraft, Seaboard 5D and NOISE show the opposite risk. Buyers in this category have seen IAP sound libraries and unique techniques stranded, so “built for current iOS and actively maintained” is a meaningful promise.

## Strategic implications for ExpressionPad

### Product priorities

1. **Treat A3 as the largest competitive gap.** The ideal implementation is both an A3 instrument and an A3 MIDI surface so a player can record the internal synth or route the same touch/MPE data to another instrument without app switching. Mononoke’s separate Pads plug-in is a particularly useful precedent. [S29]
2. **Make expression audible by default.** Ship signature presets where horizontal vibrato, vertical drag/pressure, tilt and haptic fret crossings each have an unmistakable musical result. SpaceCraft and GeoShred demonstrate that meaningful mappings outperform a generic CC feature list. [S3][S22]
3. **Preserve the geometry advantage.** No deep instrument in this set combines square, hex and stacked-piano surfaces, arbitrary rows/columns/tunings, continuous slide/frets, and mirrored two-thumb phone play. This should be the center of the product story, not a PAD settings footnote.
4. **Add progressive pitch assistance.** Explain and visualize the continuum from discrete retriggering to fret snapping, pitch rounding, free slide and in-key vibrato. GeoShred’s intelligent rounding and Shoom’s free-versus-scale-snapped glide are direct expectations. [S3][S33]
5. **Deepen sample ownership selectively.** Near-term improvements with high competitive value are in-app recording, multiple named user slots, simple trim/loop points, and preset portability. A separate touch-the-waveform mode or gesture recorder would be a larger Samplr-inspired expansion. [S14][S15]
6. **Keep motion optional and calibratable.** Tilt is memorable in ThumbJam, TC-11 and Steel Guitar, but it conflicts with desk use and can create accessibility problems. Include center/calibrate, range, smoothing and an obvious off state.
7. **Design an explicit accessibility layer.** At minimum: VoiceOver semantic note regions/control labels, a documented Direct Touch workflow, reduced-motion/ripple setting, large-control mode, hardware-keyboard completeness, high-contrast palettes, optional audio note announcements and haptic landmarks. ThumbJam proves this category can serve disability arts rather than treating accessibility as incompatible with performance. [S27][S28]

### Onboarding and UX

1. **Start with sound, scale and touch—not setup.** Etherpad, Bebot and ThumbJam win the first 30 seconds because the user cannot easily fail. Open on one signature preset with a musically safe layout and a short animated gesture hint. [S12][S25][S43]
2. **Teach one axis at a time.** A three-step overlay—tap for note/velocity, move sideways for pitch/vibrato, move vertically for expression—will make “multidimensional” concrete.
3. **Use full-screen play as the hero state.** TC-11, Borderlands and Samplr derive identity from removing desktop chrome during performance. ExpressionPad already collapses its control panel; marketing and onboarding should foreground that mode.
4. **Save/share the whole instrument.** Layout, tuning, synth/sample, FX, MIDI bend range and expression routing should travel together. GeoShred’s preset ecosystem and Borderlands scenes show that performance state is the product unit, not a synth patch alone. [S3][S18]
5. **Separate novice presets from expert construction.** A user should reach a musically rewarding surface before learning rows, tunings, MPE zones or harmonic partials.

### Positioning and marketing

1. **Position as “the configurable expressive instrument for both thumbs and all ten fingers.”** iPhone mirror mode is especially defensible because many deep competitors remain iPad-only or are awkward on phones.
2. **Show gesture-to-sound cause and effect.** Short clips should isolate slide, in-key vibrato, pressure-to-filter, tilt, fret haptics, mirror play, sampler swap and external MPE control. Competitors sell motion; static UI screenshots undersell ExpressionPad.
3. **Use precise protocol language.** “MPE-style MIDI out: per-touch channel, pitch bend, pressure and CC74” is more credible than “MPE compatible.”
4. **Merchandise breadth through use cases, not controls.** Suggested story set:
   - *Fretless lead* — continuous slide plus in-key vibrato;
   - *Two-thumb phone bass/lead split* — mirror mode;
   - *Hex world-scale instrument* — alternate tuning;
   - *Expressive sampler* — user voice/sample;
   - *External MPE controller* — recorded into a host/hardware synth;
   - *Eyes-up performance* — haptic fret crossings.
5. **Lead with maintenance and ownership.** One-time purchase, local presets/samples, exportability and current-iOS support address the trust failure illustrated by ROLI NOISE and the dormant classics.

### Pricing hypothesis

For this instrument subgroup, a one-time **$14.99–$19.99** full price is defensible if the app is actively maintained and the full synth/sampler/MIDI value is visible. A free playable tier or time-limited full demo would counter Etherpad and Animoog Z’s zero-cost acquisition without forcing subscription economics. Avoid fragmenting essential expression or MIDI output into many IAPs; optional sound/layout packs are more aligned with category precedent.

## Unknowns, contradictions, and verification needs

1. **ROLI NOISE availability:** cached App Store/search text and ROLI support still describe the app, but the live US URL returned HTTP 404 and Apple’s US lookup API returned no result on 2026-07-25. Treat it as delisted for new US users, not “available but stale.” [S44][S45]
2. **App Store device labels:** “Designed for iPad” can coexist with an iPhone compatibility record. This brief reports practical compatibility from Apple metadata but does not claim equal UI quality on every device.
3. **MorphWiz Studio minimum OS:** the App Store metadata reports unusual `10.13` wording while the official manual says iPadOS 12+. The manual is more plausible, but hands-on installation should settle it. [S9][S10]
4. **Animoog Z output:** expressive on-screen MIDI out is documented; full standards-compliant MPE output behavior and host recording should be tested before positioning it as equivalent to GeoShred/ThumbJam controller output. [S1][S2]
5. **Pressure semantics:** GeoShred, ThumbJam, Seaboard 5D and other older listings mix actual 3D Touch pressure with Y-position, touch-area, accelerometer or channel-pressure proxies. Current-device comparison requires instrumented testing.
6. **iFretless family inconsistency:** Bass and Brass explicitly advertise MPE, Guitar and Sax do not. Audiobus claims also vary. Do not extrapolate family-wide support. [S35][S36]
7. **Steel Guitar PRO MIDI:** its custom multi-channel protocol records proprietary string/slide gestures inside compatible hosts, but it is not MPE or a general external synth controller. [S38][S39]
8. **BEATSURFING monetization:** product copy says there are no subscriptions and describes annual feature windows; the live listing exposes a monthly premium IAP. Current entitlement behavior needs purchase-screen inspection. [S49]
9. **IAA/AB claims:** a listing’s IAA or Audiobus badge does not prove a reliable iOS 26 workflow. Borderlands, ThumbJam, Shoom, Bebot, DrumJam and touchscaper need hands-on current-host testing.
10. **Update date is not runtime proof:** Borderlands, SpaceCraft, Shoom, Mononoke, Steel Guitar PRO, Bebot and Seaboard 5D remain listed despite long update gaps.
11. **Accessibility:** only ThumbJam had credible explicit VoiceOver/disability-arts evidence. All other accessibility notes are interface-based risk assessments pending hands-on audits.
12. **Latency/polyphony:** advertised voice counts are not comparable to touch-to-sound latency, CPU stability or sustained MPE performance. No controlled device benchmark was run.
13. **Regional/IAP pricing:** GeoShred instrument collections and Animoog Z packs vary by region and bundle. The table reports visible US point-in-time examples rather than total cost of ownership.
14. **TC-11 current scope:** the live app is universal and was updated in 2026, while portions of its marketing/manual still describe an iPad-only product and older integration assumptions. [S6][S7]

## Numbered sources

1. **Apple App Store — Animoog Z Synthesizer.** https://apps.apple.com/us/app/animoog-z-synthesizer/id1586841361
2. **Moog — Animoog Z manual / quick overview.** https://animoog-z-manual.webflow.io/quick-overview
3. **Apple App Store — GeoShred.** https://apps.apple.com/us/app/geoshred/id1064769019
4. **moForte — GeoShred Pro quick-start guide.** https://www.moforte.com/geoshred-pro-quick-start-guide/
5. **moForte — GeoShred 7 MIDI help.** https://www.moforte.com/geoShredAssets7000/help/midi.html
6. **Apple App Store — TC-11.** https://apps.apple.com/us/app/tc-11/id488577050
7. **Bit Shape — TC-11 product page.** https://www.bitshapesoftware.com/instruments/tc-11/
8. **Bit Shape — TC-11 user guide 2.0.** http://www.bitshapesoftware.com/instruments/tc-11/tc-11-user-guide-2.0.pdf
9. **Apple App Store — MorphWiz Studio.** https://apps.apple.com/us/app/morphwiz-studio/id6739972511
10. **One Red Dog Media — MorphWiz Studio user guide.** https://www.morphwiz2.com/manual.html
11. **Create Digital Music — MorphWiz 2 hands-on overview.** https://cdm.link/morphwiz-2-ipad/
12. **Apple App Store — Etherpad.** https://apps.apple.com/us/app/etherpad/id6772439909
13. **Etherpad official product site.** https://etherpad.app/
14. **Apple App Store — Samplr.** https://apps.apple.com/us/app/samplr/id560756420
15. **Samplr official site and mode descriptions.** http://samplr.net/
16. **Create Digital Music — Samplr 1.5 MIDI update.** https://cdm.link/samplr-midi-update/
17. **Sound On Sound — Samplr review.** https://www.soundonsound.com/reviews/samplr
18. **Apple App Store — Borderlands Granular.** https://apps.apple.com/us/app/borderlands-granular/id561369733
19. **Borderlands official product page.** http://www.borderlands-granular.com/app/
20. **Borderlands official changelog.** http://www.borderlands-granular.com/app/changelog.html
21. **Apple App Store — SpaceCraft Granular Synth.** https://apps.apple.com/us/app/spacecraft-granular-synth/id1391256308
22. **Tracktion — SpaceCraft user manual.** https://assets.tracktion.com/pdf/2024/spacecraft-user-manual.pdf
23. **Tracktion — SpaceCraft product page.** https://www.tracktion.com/products/spacecraft
24. **Apple App Store — Fluss: Granular Playground.** https://apps.apple.com/us/app/fluss-granular-playground/id6443472888
25. **Apple App Store — ThumbJam.** https://apps.apple.com/us/app/thumbjam/id338977566
26. **Sonosaurus — ThumbJam user guide.** https://thumbjam.com/docs.php
27. **Drake Music — ThumbJam accessible-music education guide.** https://www.drakemusic.org/learning/resources-for-music-education/using-ipads-for-music/thumbjam-choosing-an-instrument/
28. **AppleVis — Creating instruments in ThumbJam with VoiceOver.** https://www.applevis.com/podcasts/thumbjam-ios-creating-new-instruments
29. **Apple App Store — Mononoke.** https://apps.apple.com/us/app/mononoke/id1492577124
30. **Ruismaker — Mononoke user guide.** https://ruismaker.com/manuals/mononoke_guide.pdf
31. **TabMuse — Mononoke review and pad mapping.** https://tabmuse.com/get-your-drone-on-with-mononoke-for-ios/
32. **Apple App Store — Shoom Synthesizer.** https://apps.apple.com/us/app/shoom-synthesizer/id1086363141
33. **Phonolyth — Shoom product page.** https://phonolyth.com/products/shoom
34. **AudioNewsRoom — Shoom review.** https://audionewsroom.net/2016/04/shoom-review-a-new-ipad-synth-with-plenty-of-va-va-voom.html
35. **Apple App Store — iFretless Bass.** https://apps.apple.com/us/app/ifretless-bass/id512929963
36. **Blue Mangoo — iFretless family.** http://www.bluemangoo.com/ifretless.php
37. **Apple App Store — Steel Guitar PRO.** https://apps.apple.com/us/app/steel-guitar-pro/id1619441235
38. **Yonac — Steel Guitar PRO product page.** https://www.yonac.com/steelguitarpro/
39. **Yonac — Steel Guitar PRO manual.** https://yonac.com/steelguitarpro/steelguitarpro_manual.html
40. **Apple App Store — DrumJam.** https://apps.apple.com/us/app/drumjam/id530162824
41. **Sonosaurus — DrumJam official site.** https://drumjamapp.com/
42. **Sonosaurus — DrumJam user guide.** https://drumjamapp.com/docs.php
43. **Apple App Store — Bebot: Robot Synth.** https://apps.apple.com/us/app/bebot-robot-synth/id300309944
44. **Apple App Store — ROLI NOISE legacy URL (returned 404 on research date).** https://apps.apple.com/us/app/noise/id1011132019
45. **ROLI Support — recommended mobile apps / NOISE description.** https://support.roli.com/support/solutions/articles/36000019143-recommended-mobile-apps
46. **Apple App Store — Seaboard 5D.** https://apps.apple.com/us/app/seaboard-5d/id1173937855
47. **Apple App Store — touchscaper.** https://apps.apple.com/us/app/touchscaper/id1250344299
48. **Apple App Store — VOLT Synth.** https://apps.apple.com/us/app/volt-synth/id1185984394
49. **Apple App Store — BEATSURFING 2.** https://apps.apple.com/us/app/beatsurfing-2/id1579693136
50. **Apple App Store — MOUND: Music Generator.** https://apps.apple.com/us/app/mound-music-generator/id6768479656
51. **Apple App Store — Saucillator.** https://apps.apple.com/us/app/saucillator/id6752227604
52. **Apple App Store — original MorphWiz (lineage reference).** https://apps.apple.com/us/app/morphwiz/id377345348
53. **Apple lookup API — active synth/performance set, live US metadata.** https://itunes.apple.com/lookup?id=1586841361,1064769019,488577050,6739972511&country=us
54. **Apple lookup API — current/legacy instrument set, live US metadata.** https://itunes.apple.com/lookup?id=6772439909,560756420,561369733,1391256308,338977566,1492577124,1086363141,1619441235,530162824,300309944,1173937855&country=us
55. **Apple lookup API — adjacent/current entrants, live US metadata.** https://itunes.apple.com/lookup?id=6443472888,1250344299,1185984394,1579693136,6768479656,6752227604&country=us
56. **Apple lookup API — iFretless family, live US metadata.** https://itunes.apple.com/lookup?id=512929963,623167340,681765126,915761815&country=us
