# iOS workstation, groovebox, and all-in-one instrument substitutes

**Evidence date:** 2026-07-25  
**Scope:** T5 adjacent substitutes: apps whose main job is production, hosting, sequencing, looping, or beatmaking, but which can absorb the budget, attention, or “all-in-one instrument” job that ExpressionPad targets. This is not a census of iOS DAWs.

## Scope and classification

None of the eight products below is a direct competitor in the strict sense. A direct competitor would lead with a continuous, configurable multitouch pitch surface; generate independent per-finger pitch/timbre/pressure; send that expression to external instruments; and also provide an immediate internal synth/sampler. These products instead lead with a DAW, groovebox, looper, sampler, or modular studio.

Two are **adjacent hybrids**:

- **Drambo** can be assembled into instruments and controller-like interfaces, but its center of gravity is modular construction and sequencing.
- **Loopy Pro** can build custom touch-control canvases and even run as an AUv3 MIDI processor, but its center of gravity is looping, routing, hosting, and live-rig automation.

The other six are **adjacent substitutes**. They reset expectations for price, built-in sound breadth, touch playability, plugin integration, onboarding, and the ability to finish a musical idea without leaving the app.

The disciplined set is: **Logic Pro for iPad, GarageBand, Cubasis 3, KORG Gadget 3, Drambo, Loopy Pro, Koala Sampler, and Roland Zenbeats**. AUM, BeatMaker 3, Groovebox, and NanoStudio 2 were screened but not profiled: AUM is ecosystem infrastructure with no native instrument engine; BeatMaker substantially overlaps the sampler/DAW territory covered by Koala and Cubasis; Groovebox is narrower and its last public update was in April 2024; NanoStudio 2 returned no result in Apple’s live US lookup and its last documented release was in 2021. [S1][S41][S43][S44][S45]

## Executive findings

1. **“Playable” is now table stakes, but “expressive” is not.** Apple supplies keyboards, drum pads, chord strips, guitar/fretboard views, Smart Instruments, and Live Loops; Cubasis, Gadget, Koala, and Zenbeats add scale lock, chord modes, pads, XY controls, and note repeat. Most surfaces still behave like convenient note-entry widgets. ExpressionPad’s defensible gap is continuous geometry, independent finger expression, configurable tunings, thumb-first mirroring, vibrato, haptics, and MPE output—not merely having an on-screen keyboard.

2. **The substitute price ladder runs from free to $50 upfront, then into subscriptions and expansions.** GarageBand is free; Koala is $4.99 plus $3.99/$4.99 add-ons; Gadget was observed at $19.99; Drambo is $24.99; Loopy Pro unlocks for $29.99; Cubasis is $49.99 plus optional instruments/effects. Logic is now foregrounded through the $12.99/month or $129/year Apple Creator Studio bundle, while legacy Logic-specific $4.99/month and $49/year SKUs remain visible in the App Store. [S2][S7][S8][S11][S12][S17][S22][S26][S27][S31]

3. **AUv3 is the ecosystem baseline for “studio” apps.** Logic, Cubasis, Drambo, Loopy Pro, Zenbeats (paid unlock), and—since May 2026—Koala with its Mixer add-on host plugins. GarageBand hosts AUv3 instruments/effects in a simpler environment. Gadget’s “AUv3 support” mainly exports many Gadgets into other hosts; KORG does not document Gadget as an open third-party plugin host. [S3][S9][S13][S18][S23][S27][S31][S33][S38]

4. **MPE support is fragmented enough to be a positioning opportunity.** GarageBand explicitly accepts MPE controllers; Logic instruments such as Sample Alchemy and Sculpture expose MPE/Mono Mode; Drambo supports MPE in its polyphonic modular path; Loopy Pro records incoming MPE into MIDI clips. By contrast, current official Cubasis, Gadget, Koala, and Zenbeats materials do not establish full per-note MPE capture/editing; a Steinberg forum report documents Cubasis losing per-note expression in recorded playback. [S5][S9][S15][S20][S25][S29][S34][S38]

5. **Sound breadth creates a severe value anchor.** Logic advertises 5,700+ patches, 6,300+ samples, and 12,900+ loops; Gadget’s full ecosystem exceeds 6,000 programs; Zenbeats ranges from a meaningful free library to 14,000+ presets/loops/sounds in Max; Cubasis bundles three instruments and 550+ loops; GarageBand gives away Alchemy, Touch Instruments, Drummer, Smart Instruments, and downloadable packs. ExpressionPad should sell the quality of interaction and immediacy of its internal voices, not claim workstation-level content breadth. [S11][S18][S22][S27][S37][S38]

6. **The strongest onboarding patterns shorten time-to-sound.** GarageBand opens into a Touch Instrument browser and provides coaching overlays; Logic has guided Lessons; Gadget’s Genre Select starts from a 5×5 phrase grid; Koala is deliberately “record, tap, resample”; Zenbeats includes lessons and Key Lock. Drambo and Loopy reduce complexity with automatic patching or templates, but their deeper value still requires configuration. [S3][S7][S14][S19][S27][S32][S38]

## Evidence matrix

Prices are current US storefront observations unless qualified. “Last update” uses Apple’s live catalog metadata checked on 2026-07-25. [S1]

| Product | Relation to ExpressionPad | Current price / monetization | Devices / minimum OS | Play surface | Host / routing | MIDI / MPE | Built-in sound depth | Last public update |
|---|---|---|---|---|---|---|---|---|
| **Drambo 2.54** | Adjacent hybrid | $24.99; Waves, Formants, DSP $4.99 each; Visual $14.99 | iPhone+iPad; iOS/iPadOS 15.6+; Apple-silicon Mac | Keyboard, pads, step grid, clip launcher, XY modules, morph controls | Hosts AUv3 instrument/effect/MIDI FX standalone; is itself all three AUv3 types | Deep MIDI routing/mapping/feedback; receives MPE; no verified native MPE-generating surface | 140–150+ modular DSP/MIDI modules; synth, sampler, physical modeling, Plaits-derived engines | 2026-07-10 |
| **Loopy Pro 2.0.5** | Adjacent hybrid | Free 7-day trial; $29.99 permanent unlock; optional $14.99 future update year; no subscription | iPhone+iPad; iOS/iPadOS 13+ | Multipage custom canvas: clips, buttons, faders, dials, encoders, XY, grids, slicers; conventional keyboard | Full AUv3 host, mixer, buses, stems, audio/MIDI routing; AUv3 mode cannot nest plugins | USB/BLE/network/virtual MIDI, learn, feedback, SysEx; records MPE clips; no verified widget-generated per-note MPE | Sampling/looping; no native synth or bundled sound library | 2025-11-26 |
| **Logic Pro for iPad 3.3** | Adjacent substitute | Free shell; Apple foregrounds Creator Studio at $12.99/mo or $129/yr; legacy $4.99/mo/$49/yr Logic SKUs remain listed | iPad only; iPadOS 26+, A12 Bionic+; some features need newer chips | Keyboard, drums, fretboard, chord strips, guitar strips; velocity/pitch/mod side controls | AUv3 instruments/effects, external audio and MIDI, full mixer | External MIDI and MIDI Learn; several native instruments accept MPE | 5,700+ patches, 6,300+ samples, 12,900+ loops; Alchemy, Sample Alchemy, Quick Sampler, drums, effects | 2026-06-30 |
| **GarageBand 2.3.18** | Adjacent substitute / free anchor | Free | iPhone+iPad; iOS/iPadOS 26+ | Touch keyboards, drums, guitar, bass, strings, Smart Instruments, chord strips, Live Loops, Alchemy Transform Pad | AUv3 instruments/effects; up to 32 tracks; comparatively closed routing | Bluetooth/USB MIDI input and explicit MPE-controller mode; no documented flexible MIDI-out matrix | Alchemy, sampler, Drummer, world instruments, amps, loops and free downloadable packs | 2025-11-03 |
| **Cubasis 3.8.3** | Adjacent substitute | $49.99; optional instruments/effects from $4.99 to $19.99 | iPhone+iPad; iOS/iPadOS 17.7+ | Keyboard, chord buttons, chord/drum pads, note repeat | AUv3 instruments/effects/MIDI FX, multi-output, Audiobus/IAA, 24 physical I/O, advanced mixer | MIDI learn, MCU/HUI, BLE, clock/thru, CC/aftertouch; full MPE recording/editing not established | Micrologue 126 presets, MicroSonic 120+, MiniSampler 20, 550+ loops, 17 effects; more via IAP | 2026-02-23 |
| **KORG Gadget 3 / app 6.3.4** | Adjacent substitute | $19.99 observed; 12 IAP Gadgets at $6.99–$9.99 plus cross-unlocks from other KORG apps | iPhone+iPad; iOS/iPadOS 13+; KORG recommends iPhone XS / iPad 6th gen or newer | Gadget-specific keys/pads, Play page with chord/scale/arpeggiator; Genre Select 5×5 phrase pads | Many Gadgets export as AUv3; no documented open third-party AUv3 hosting | External/BLE MIDI, per-track channel/device, CC mapping, Native Mode; MPE not documented | 20 Gadgets included, 45 possible; 6,000+ programs in full collection | 2026-07-01 |
| **Koala Sampler 2.0** | Adjacent substitute | $4.99; Samurai $3.99; Mixer $4.99; $13.97 fully enabled | iPhone+iPad; Apple live API says iOS/iPadOS 14+ | 64 sample pads, chromatic/9-scale keyboard, resizable grid, 16 performance FX | Runs as AUv3; Mixer add-on now hosts AUv3 instruments/effects standalone | MIDI learn, note/CC, velocity, BLE, clock; MIDI out with Samurai; no MPE claim | User sampling/resampling, 250 built-in sounds, stem split, 8 input FX, 16 performance FX | 2026-07-09 |
| **Roland Zenbeats 3.1.12** | Adjacent substitute | Free; Roland documents $14.99 iOS Platform Unlock and $149.99 Max, but that price page is dated 2023; current Cloud membership starts $2.99/mo | iPhone+iPad; iOS/iPadOS 11+; Roland confirms iOS/iPadOS 26 compatibility | On-screen keys/pads/note grid, ZC1 XY pad, Key Lock, LoopBuilder | AUv3 hosting requires Platform/Max unlock or paid Cloud membership; cross-platform projects | MIDI/audio editing, BLE hardware integration, Link; current official pages do not establish MPE behavior | Free: 450 loops/presets plus ZR1/ZC1/SampleVerse cores; Platform 2,500+; Max 14,000+ | 2025-06-03 |

## Product profiles

### 1. Drambo — the build-your-own-studio alternative

Drambo is the deepest adjacent hybrid. BeepStreet positions it as a modular groovebox, audio-processing environment, sequencer, synth/sampler builder, plugin host, and “all-in-one sound laboratory.” Its cableless left-to-right patching, automatic connections, color coding, nesting, and module help make modular work unusually approachable, but the downloadable manual still assumes basic synthesis literacy. [S2][S3][S5]

The performance layer includes a keyboard, pads, step and clip grids, XY UI modules, and 16-scene morphing. Nearly the whole interface can be mapped to hardware, with reusable controller profiles and bidirectional feedback. MPE is transparent in an Instrument Rack’s polyphonic path, but the clearest support evidence recommends using an external MPE controller; no current official page claims that Drambo’s own surface generates independent per-note expression. [S3][S4][S5]

**Competitive implication:** Drambo is a compelling destination, not a feature checklist to chase. ExpressionPad should demonstrate “ExpressionPad → Drambo” and own the ready-made expressive front end. Drambo’s $24.99 base price and active six-release 2026 cadence also show that serious iOS musicians will pay for maintained specialist tools. Its newest Code module and Visual expansion reinforce that Drambo competes on open-ended construction, while ExpressionPad should compete on embodied play. [S2][S6]

### 2. Loopy Pro — the customizable live-rig mothership

Loopy Pro comes closest to a general control-surface builder. A project canvas can contain scalable buttons, faders, dials, encoders, XY pads, clip grids, slicers, labels, state feedback, and action sequences. It routes USB, Bluetooth, network, and virtual MIDI; offers MIDI Learn, relative controls and feedback; emits notes, CC, program change, pitch bend, SysEx and 14-bit CC; and can run as an AUv3 MIDI processor. [S7][S9]

Its primary product is nevertheless a looper/DAW: audio and MIDI clips, sampler behavior, piano roll, arranger, automation, plugin hosting, mixer, buses, stems, and external gear control. It records incoming MPE into MIDI clips and turns audio clips into polyphonic samplers, but no evidence shows its widgets generating a purpose-built continuous per-note MPE performance. It also includes no native synth library, relying on recordings, samples, plugins, or external inputs. [S7][S9][S10]

The unusual license is a strong market signal: $29.99 keeps the current feature set permanently, includes 12 months of new features and lifetime bug/compatibility fixes, and allows optional $14.99 update years later. [S8]

**Competitive implication:** Loopy Pro competes when a live performer wants one configurable control room. ExpressionPad can win the narrower job of opening directly into a coherent expressive instrument with opinionated tunings, haptics, sensors, and independent finger articulation. Integration content is again stronger than replacement rhetoric.

### 3. Logic Pro for iPad — the professional breadth ceiling

Logic sets the category ceiling for sound content, arrangement, mixing, and Apple-native touch production. Its Play Surfaces cover keyboard, drums, fretboard, chord and guitar strips, with side controls for velocity, pitch bend, modulation, expression, and note repeat. Those are broad, useful entry surfaces, but they remain conventional compared with ExpressionPad’s configurable continuous grid. [S11][S12][S16]

Logic hosts AUv3, connects class-compliant audio/MIDI devices, offers guided Lessons, and includes a vast library plus Sample Alchemy, Quick Sampler, Drum Machine Designer, Live Loops, Step Sequencer, Session Players, effects, and a pro mixer. Several native instruments explicitly accept MPE/Mono Mode with per-voice pitch bend, aftertouch, modulation and controller data. [S11][S13][S14][S15]

Pricing is currently messy. Apple now promotes Logic inside Creator Studio at $12.99/month or $129/year, but the US App Store still lists $4.99 and $49 Logic-specific IAPs. Existing standalone subscribers can reactivate that path; Apple does not make the new-user boundary entirely clear on the listing. [S11][S12][S13]

**Competitive implication:** Do not position ExpressionPad as a DAW substitute. Position it as the touch instrument Logic’s Play Surfaces do not provide: richer continuous expression, non-piano tunings, phone-first playing, and an MPE source for Logic’s capable receiving instruments.

### 4. GarageBand — the free expectation setter

GarageBand is the most important price and onboarding anchor. It turns both iPhone and iPad into a collection of Touch Instruments plus a 32-track studio, with keyboards, drums, guitar/bass, strings, Smart Instruments, Live Loops, Beat Sequencer, sampler, amps, Alchemy, free downloadable packs, and AUv3 instruments/effects. The first screen is a sound/instrument browser, and coaching overlays explain the current instrument while remaining playable. [S17][S18][S19]

GarageBand explicitly accepts MPE controllers and applies pitch, timbre and expression per note. Its own many Touch Instruments are highly approachable, but they are instrument-specific rather than a single deeply configurable lattice. [S18][S20]

**Competitive implication:** “It has a synth, sampler, keys, and effects” cannot justify price by itself because Apple gives away more breadth. ExpressionPad must merchandise the first-touch experience: slide a chord, bend one finger, feel fret crossings, mirror the phone for two thumbs, switch tunings, then route the same gesture to any MPE instrument.

### 5. Cubasis 3 — the conventional mobile DAW

Cubasis offers perhaps the clearest one-time-purchase professional DAW benchmark: unlimited audio/MIDI tracks, 24 physical I/O, a 32-bit float engine, AUv3 instruments/effects/MIDI effects including multi-output, MIDI Learn, MCU/HUI, BLE MIDI, clock and thru, plus a mature mixer and editors. Its built-in keyboard, chord buttons, drum/chord pads, velocity, and note repeat make ideas playable without hardware. [S22][S23][S24]

The included sound set is respectable rather than overwhelming: Micrologue, MicroSonic, MiniSampler, 550+ loops and 17 effects, with HALion, FM, drum-machine, Waves and other IAPs. Full MPE remains a weakness: current official pages do not claim it, and Steinberg’s own forum contains a reproducible report that monitored MPE worked live but recorded only the latest note’s expression and lacked per-note editing. Treat current support as unverified rather than categorically absent. [S22][S25]

**Competitive implication:** Cubasis demonstrates how readily ExpressionPad can fit into a serious conventional workflow via MIDI. Host-specific setup recipes and tested MPE/bend-range templates will matter more than adding DAW features.

### 6. KORG Gadget 3 — the curated instrument ecosystem

Gadget’s appeal is coherence: dozens of intentionally limited “Gadgets” share one clip/scene production workflow. Twenty are included and 45 are possible through IAPs or ownership of other KORG apps; the full collection exceeds 6,000 programs. The current Play page adds easy scale, chord, and arpeggiator entry, while Genre Select offers 5×5 phrase pads so a user can begin from stylistically matched patterns. [S26][S27][S28]

External and Bluetooth MIDI, per-track device/channel assignment, CC mapping, and KORG Native Mode are well supported. Gadget 3 also makes many individual Gadgets available as AUv3 instruments in GarageBand, Logic and other hosts, although several utility and app-linked Gadgets are excluded. KORG does not document a third-party AUv3 host inside Gadget or MPE support. [S27][S28][S29]

The $19.99 observed price requires a caveat: KORG’s official summer sale was scheduled to end July 21, four days before this check, while its comparison chart shows a $39.99 regular iOS price. The live storefront had not reverted, so $19.99 is the verified current observation but not a safe long-term anchor. [S1][S26][S30]

**Competitive implication:** Gadget shows the power of curated constraints and recognizable sound identities. ExpressionPad should give its presets equally legible musical jobs and make layout/tuning presets feel like instruments, not settings dumps.

### 7. Koala Sampler — the immediacy and value benchmark

Koala is the strongest benchmark for focus. Its pitch is to record any sound immediately, tap it across up to 64 pads, sequence, perform effects, and resample without interrupting flow. It adds 250 built-in sounds, stem splitting, a chromatic or nine-scale keyboard, MIDI mapping, velocity, BLE MIDI and Ableton Link. [S31][S32][S34]

The $3.99 Samurai add-on supplies time-stretch, piano roll, auto-chop, EQ and MIDI output; the $4.99 Mixer add-on adds four buses, deeper processing, and—since May 2026—AUv3 instrument/effect hosting. The complete $13.97 configuration is therefore much closer to a small all-in-one workstation than its $4.99 entry price suggests. [S31][S33][S36]

Koala does not claim MPE and its MIDI settings describe conventional note/CC mapping. Version 2.0 landed in July 2026 after repeated 2026 maintenance and feature releases, signaling unusually active stewardship for a low-cost app. [S30][S34][S35]

**Competitive implication:** Koala proves that a narrow instrument can grow into a platform without losing a one-sentence job. ExpressionPad should preserve “touch, slide, express” as its front door even if the internal synth/sampler expands.

### 8. Roland Zenbeats — the freemium, cross-platform library play

Zenbeats combines LoopBuilder, timeline/automation, mixing, audio/MIDI editing, ZR1 drums, ZC1 ZEN-Core synthesis, SampleVerse, on-screen instruments, a note grid, XY control, and Key Lock. The free tier includes meaningful instruments/effects and roughly 450 loops/presets; Platform Unlock expands to 2,500+ sounds and AUv3 support, and Max to 14,000+ across platforms. [S37][S38]

Its monetization is broad but difficult to parse. Roland’s current product page offers free, Platform Unlock, Max Unlock, or Roland Cloud membership; the App Store lists Cloud Core from $2.99/month plus store-point packs. Roland’s only explicit one-time price table found—$14.99 iOS Platform, $59.99 all-OS, $149.99 Max—was last updated in 2023, so those one-time prices require in-app confirmation. [S37][S38][S39]

The public app has not updated since June 2025, although Roland’s May 2026 compatibility table confirms Zenbeats works on iOS/iPadOS 26. Current official materials do not substantiate earlier third-party descriptions of MPE, so its present MPE fidelity remains unknown. [S1][S38][S40]

**Competitive implication:** Zenbeats competes through brand sounds, cross-device continuity, and a large content funnel. ExpressionPad cannot match that catalog, but can be easier to understand, require no account/store funnel, and offer a much more distinctive playing technique.

## Ecosystem baseline and strategic implications

### What users can reasonably expect in 2026

- Immediate playable keys or pads, scale assistance, presets/templates, and a path to sound without external hardware.
- CoreMIDI/Bluetooth MIDI input; serious products add clock, learn, routing, hardware feedback, or external MIDI sequencing.
- AUv3 interoperability in any app positioned as a production environment.
- A built-in synth and/or sampler plus effects; otherwise a strong plugin-host or live-routing story.
- Active OS compatibility work. Seven of the eight profiled apps had a public update or official compatibility confirmation within the preceding year; Zenbeats is the cadence outlier.
- One-time pricing remains viable for indie/pro tools, but expansions, optional update years, content stores, and subscriptions are all normalized.

### Where ExpressionPad is differentiated

1. **A single surface with a real gesture vocabulary.** Competitors provide many playable widgets; ExpressionPad can provide one instrument that rewards technique: independent touch voices, continuous slide, fretted slide, in-key vibrato, onset velocity, aftertouch, tilt routing, and haptic pitch crossings.
2. **Configurable musical geometry.** Square/hex/stacked-piano layouts, independent row tunings and column scales, guitar/open tunings, arbitrary dimensions, and mirror split are materially different from conventional keys/pads plus scale lock.
3. **Phone-first performance.** Most workstations technically support iPhone, but dense arrangement and patching workflows favor iPad. Mirror split, collapsed full-screen controls, haptics, and two-thumb symmetry create a clearer phone use case.
4. **Internal sound without host dependence.** Unlike a pure controller, ExpressionPad can make sound immediately; unlike a workstation, the synth/sampler exists to reward the surface rather than become the product’s organizing metaphor.
5. **An MPE source for the ecosystem.** Logic, GarageBand, Drambo and Loopy already receive or preserve meaningful MPE data. These are partnership/demo targets.

### Where ExpressionPad is exposed

- It does not offer AUv3 hosting, multitrack production, clip launching, piano-roll editing, a mixer, or a content marketplace. Those omissions are acceptable only if positioning stays performance-first.
- Its included sound catalog is tiny against even free GarageBand and Zenbeats. Sound quality, preset curation, and fast sample loading matter more than raw count.
- MPE interoperability must be proven host by host. Pitch-bend range, channel allocation, pressure type, CC74 behavior, note release, and recording fidelity differ across hosts.
- Apple’s free and bundled products create a low willingness to pay for generic “mobile music studio” language.

### Recommended competitive stance

- Use **“expressive instrument and MPE controller with sound built in”**, not “all-in-one studio.”
- Show one-finger and two-finger gestures in the first App Store video; UI screenshots alone will under-communicate the product.
- Publish short recipes for **Logic, GarageBand, Drambo, Loopy Pro, AUM, and hardware MPE synths**.
- Merchandise layout/tuning presets as named instruments or playing systems.
- Keep first-run friction below Koala/GarageBand: sound on first touch, then a 30–60 second overlay for slide, pressure, vibrato, mirror and MIDI.
- Treat $24.99 Drambo and $29.99 Loopy as premium specialist anchors, but GarageBand free and Koala $4.99 as the stronger mass-market anchors. Pricing should reflect whether launch marketing can prove professional MPE reliability.

## Unknowns and verification needs

1. Hands-on host tests are still required for the complete MPE stream: per-note pitch bend, channel pressure/poly pressure, CC74, release velocity, bend-range negotiation, recording, playback and editing.
2. Logic’s current purchase path is ambiguous: Creator Studio is foregrounded, while legacy Logic-specific IAPs remain visible.
3. KORG Gadget’s observed $19.99 price persisted after the announced July 21 sale end and may change without notice.
4. Koala’s Apple live catalog reports iOS 14 minimum while some rendered App Store snapshots still say iOS 13; the live API was used here.
5. Zenbeats’ one-time unlock prices need in-app confirmation because Roland’s explicit price table is dated 2023.
6. Drambo’s current on-screen surface needs hands-on verification for native MPE generation and full incoming-MPE recording fidelity.
7. Loopy Pro’s manual establishes incoming MPE clip recording but not widget-generated polyphonic expression.
8. NanoStudio 2’s US availability should be checked directly on a US Apple device; the live US lookup returned zero results despite indexed App Store pages elsewhere.

## Sources

1. [S1] https://itunes.apple.com/lookup?id=1469365718,1492670451,1615087040,408709785,1207839273,791077159,1449584007,1473380367,1055636344&country=us&entity=software
2. [S2] https://apps.apple.com/us/app/drambo/id1469365718
3. [S3] https://www.beepstreet.com/ios/drambo
4. [S4] https://www.beepstreet.com/drambo-docs/midi-mapping.html
5. [S5] https://www.beepstreet.com/public/downloads/Drambo%20manual.pdf
6. [S6] https://www.beepstreet.com/drambo-docs/code-module.html
7. [S7] https://apps.apple.com/us/app/loopy-pro-looper-daw-sampler/id1492670451
8. [S8] https://loopypro.com/pricing/
9. [S9] https://loopypro.com/manual/
10. [S10] https://loopypro.com/why-loopy-pro/
11. [S11] https://apps.apple.com/us/app/logic-pro-make-music/id1615087040
12. [S12] https://www.apple.com/logic-pro/
13. [S13] https://support.apple.com/en-us/101825
14. [S14] https://support.apple.com/guide/logicpro-ipad/whats-new-in-logic-pro-for-ipad-lpipaf69c334/ipados
15. [S15] https://support.apple.com/guide/logicpro-ipad/more-menu-lpip1a29aae9/ipados
16. [S16] https://support.apple.com/guide/logicpro-ipad/intro-to-play-surfaces-lpip9ac51271/ipados
17. [S17] https://apps.apple.com/us/app/garageband/id408709785
18. [S18] https://www.apple.com/ios/garageband/
19. [S19] https://help.apple.com/pdf/garagebandipad/en_US/garageband-ipad-user-guide.pdf
20. [S20] https://support.apple.com/guide/garageband-ipad/use-mpe-controllers-chsc2cc0d4f8/ipados
21. [S21] https://support.apple.com/en-us/106346
22. [S22] https://apps.apple.com/us/app/cubasis-3-daw-music-studio/id1207839273
23. [S23] https://download.steinberg.net/downloads_software/Cubasis/Cubasis_3_Operation_Manual.pdf
24. [S24] https://www.steinberg.help/r/cubasis/3.8/en/cubasis/topics/version_history_x.html
25. [S25] https://forums.steinberg.net/t/cubasis-3-4-3-has-no-real-mpe-support/794989
26. [S26] https://apps.apple.com/us/app/korg-gadget-3/id791077159
27. [S27] https://www.korg.com/us/products/software/korg_gadget/
28. [S28] https://www.korg.com/us/products/software/korg_gadget/specifications.php
29. [S29] https://www.korguser.net/gadget/manual/studioguide/Gadget_SG_E1.pdf
30. [S30] https://www.korg.com/us/news/2026/0623/
31. [S31] https://apps.apple.com/us/app/koala-sampler-beat-maker/id1449584007
32. [S32] https://www.koalasampler.com/
33. [S33] https://manual.koalasampler.com/mobile/10-in-app-purchases/
34. [S34] https://manual.koalasampler.com/mobile/8-settings/
35. [S35] https://cdn.koalasampler.com/builds/release-notes.html
36. [S36] https://synthanatomy.com/2026/05/koala-sampler-you-can-now-mix-your-tracks-with-auv3-effects-plugins.html
37. [S37] https://apps.apple.com/us/app/roland-zenbeats/id1473380367
38. [S38] https://www.roland.com/us/products/rc_zenbeats/
39. [S39] https://support.roland.com/hc/en-us/articles/360050114191-Zenbeats-How-much-does-Zenbeats-cost
40. [S40] https://www.roland.com/nz/support/support_news/25090811ios1/
41. [S41] https://apps.apple.com/us/app/aum-audio-mixer/id1055636344
42. [S42] https://kymatica.com/aum/help
43. [S43] https://apps.apple.com/us/app/beatmaker-3/id1060317024
44. [S44] https://apps.apple.com/us/app/groovebox-beat-synth-studio/id1242847278
45. [S45] https://apps.apple.com/us/app/nanostudio-2/id1112601015
