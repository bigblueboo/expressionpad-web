# Direct iOS expressive MIDI/MPE performance surfaces

Research date: **2026-07-25**  
Scope owner: T1, direct expressive MIDI/MPE control surfaces  
Geography for prices and availability: **United States App Store**, unless stated otherwise

## 1. Scope and method

This file covers iPhone/iPad apps whose central interaction is to place fingers or a stylus on a musical surface, generate notes, and shape pitch or expression live. An app is treated as a **direct controller competitor** when it can send the resulting performance to another instrument over MIDI/MPE/OSC; an app can also be a direct **whole-product competitor** when it combines that surface with its own sound engine. Generic DAW remotes, modular knob-and-fader builders, workstations, and conventional synths are outside this branch except where a short cross-reference helps place the boundary.

The comparison gate is deliberately strict:

1. Is the surface playable as an instrument rather than merely a parameter dashboard?
2. Does expression remain attached to individual notes/touches, or is it only global?
3. Can it drive an external destination, and by which protocols?
4. Does it make sound without another app?
5. Is it actually purchasable on 2026-07-25?

Discovery was performed with Exa using app-specific and semantic category searches, followed by verification against live US App Store pages, Apple's public Lookup endpoint, current developer pages, and manuals. App Store price/version/platform claims below use the live Apple page or Lookup response, not cached search snippets. Specialist coverage and forum posts are used only for workflow evidence, historical details, or explicit contradictions. Every factual competitor claim is cited inline with the numbered source list in section 6.

The current ExpressionPad comparison baseline comes from the repository rather than from an assumed product pitch. It is a native-iOS and web/PWA continuous multitouch instrument with square, hex, stacked-piano, and two hardware-keyboard layouts; arbitrary supported row/column density; per-touch pitch bend; Y-derived onset velocity and aftertouch; fretted or continuous slides; spring-back vibrato; fret haptics; a mirrored two-thumb phone layout; internal synth, sampler, and effects; and MPE-style MIDI output. [47] The native implementation is a standalone app, not an AUv3, and uses CoreMIDI with a network session. [48] Its current “pressure” and CC74 output are driven by the same vertical-drag gesture rather than independent physical Z pressure, and current monetization is not established in the repository. [47]

### Category boundary

- **Deep profiles:** GeoShred Control, KB-1, Velocity Keyboard, KeyPad MIDI Controller, WoodTroller, Midi Poly Grid, ThumbJam, Ribbons, and TC-Data.
- **Screened/historical:** Pen2Bow, TC-11, and Aftertouch.
- **Cross-references only:** Musix Pro is a current isomorphic controller but documents touch velocity rather than MPE/per-note continuous expression; ChordUp is a chord controller without a documented MPE model; Gestrument Pro is a cursor/generative instrument with configurable MIDI CC output but no documented MPE; Seaboard 5D is an expressive internal instrument and MPE sound engine, but no first-party evidence was found that its onscreen surface sends MIDI to external synths. [50][51][52][53]

## 2. Evidence table

### 2.1 Market/status matrix

| App | Live US status and monetization | Platform / recency | Surface and expression model | External integration | Internal sound | Substitutability |
|---|---|---|---|---|---|---|
| **GeoShred Control** | Live; free controller; one-time Pro-functionality upgrade currently documented at $24.99, with further optional modeled-instrument IAPs. [1][3] | iPhone+iPad, iOS/iPadOS 15+; v7000.327.1.436, 2026-06-15. [1][2] | Isomorphic/diatonic, fretless-to-quantized pitch; per-note X pitch and Y expression; true Z depends on legacy 3D Touch. [5][6][7] | MIDI/MPE, virtual, Wi-Fi/network, BLE, wired, AUv3 MIDI sender; no documented OSC. [1][5] | None in free tier; physical-model engine after Pro upgrade. [1][3] | **High** for controller role; **high** for whole product after paid upgrade. |
| **KB-1 Keyboard Suite** | Live; $14.99 one-time; no IAP/subscription shown. [2][8] | iPhone+iPad, iOS/iPadOS 11+; v1.3.7, 2025-10-14. [2][8] | Eight layouts; MPE glide, slide, Y-position velocity, legacy-iPhone pressure; up to five independently routed surfaces in standalone. [8][9] | Standalone + AUv3 MIDI; inter-app, USB, BLE, network MIDI; no documented OSC. [8][9] | No. [8] | **High** as a multi-layout DAW keyboard; **medium** as an all-in-one instrument. |
| **Velocity Keyboard** | Live; $9.99 one-time; no IAP/subscription shown. [2][12] | iPhone+iPad, iOS/iPadOS 11+; v1.3.22, 2025-09-24. [2][12] | Piano/string/scale/drum; touch-derived velocity; pitch correction; touch area, Y, legacy force and four knobs as CC sources. [12][13] | Standalone + AUv3 MIDI; current official copy does not fully enumerate its non-AU routing; no documented OSC. [12][13] | No. [12][13] | **Medium-high** for expressive note entry; **low** for standalone sound. |
| **KeyPad MIDI Controller** | Live; free download; no paid tier is documented in the sources reviewed. [14][15] | iPhone+iPad, iOS/iPadOS 14+; v1.12, 2026-06-21. [14][15] | Piano, isomorphic grid, drums and XY pad; height velocity; mono/poly aftertouch; MPE X=pitch and Y=CC74. [14][16] | Standalone + AUv3; virtual, network, BLE and wired MIDI; OSC output. [14][16] | SF2/SFZ/ZBP/ZBB/WAV/M4A import and playback. [14][16] | **Very high** on paper; the closest new free “surface + sounds” entrant. |
| **WoodTroller** | Live; $9.99 one-time. [18][19] | iPad only, iPadOS 12+; v2.7.3, 2025-01-21. [18][19] | MPE/MIDI 2 touch bar: horizontal per-note pitch, vertical pressure/CC74 zones; macro knobs/buttons. [18][20] | Standalone + AUv3; MIDI 1/MPE, MIDI 2/CI/property exchange, network and BLE; no OSC documented. [18][20] | No. [18] | **Medium**: unusually deep protocol/macro control, but an iPad-only ribbon rather than a geometric instrument. |
| **Midi Poly Grid** | Live; $3.99 one-time; source code is GPL-3.0. [21][22][23] | iPhone+iPad, iOS/iPadOS 13+; v1.1.14, 2026-02-14. [21][22] | Resizable Push-like grid; MPE and poly aftertouch via touch/swipe; Y-position/random/fixed velocity; user-defined X/Y intervals. [21][23] | Virtual, USB, BLE and Wi-Fi MIDI; explicitly no AUv3; no OSC documented. [21][23] | No. [21][23] | **High** for configurable grid control; **low** as a self-contained instrument. |
| **ThumbJam** | Live; $8.99 one-time; extra sample packs described as free. [24][25] | iPhone+iPad, iOS/iPadOS 8+; v2.6.11, 2022-07-24. [24][25] | Scale-constrained vertical pitch surface, discrete/glide/continuum modes, splits, tilt/shake/drag/legacy force mappings; 5 touches on phone, 11 on iPad. [24][26][27] | CoreMIDI virtual/network/BLE/wired, channel-per-touch/MPE-like output, OSC output, Audiobus, IAA, Link; no AUv3 documented. [24][27][28] | 40+ multisampled instruments, custom multisamples, looping, arp, effects. [24][27] | **High** whole-product substitute despite aging integration. |
| **Ribbons** | Live; $3.99 one-time. [29][30] | iPhone+iPad, iOS/iPadOS 11+; v1.4, 2019-01-19. [29][30] | Polyphonic ribbon/Ondes surface, free pitch with adjustable snap, vertical parameter mapping and legacy 3D Touch; MPE or manual channel-per-touch. [29] | MIDI/MPE, Audiobus and IAA; no AUv3 or OSC documented. [29] | Wavetable/swarm synth, filter, delay, reverb. [29] | **Medium-high** conceptually; **medium-low** commercially because it has not been updated since 2019. |
| **TC-Data** | Live; $19.99 one-time. [31][32] | iPhone+iPad, iOS/iPadOS 16+; v2.3.3, 2026-02-16. [31][32] | 300+ touch-relation, timing, size and device-motion controllers/triggers; up to 11 historical touch voice IDs; not automatic MPE. [33][34] | CoreMIDI notes/CC/pitch/aftertouch/program, 14-bit CC, virtual/network/BLE, OSC; no AUv3 or documented MPE. [31][33][34] | No. [31][33] | **High** for programmable external control/OSC; **medium-low** as a direct melodic instrument. |
| **Pen2Bow** | **Delisted**; Apple returns 404/zero results. Last archived price $7.99 one-time. [39][40][41] | Historical iPad-only, Pencil-required, iPadOS 11+; last v1.1.2, 2020-06-22. [41] | Pencil bow velocity, force, tilt and orientation; linear or circular “infinite bow”; one expression stream per instance, not MPE. [41][42] | CoreMIDI, USB/network, AUv3 MIDI effect; no verified OSC. [41][42][43] | No. [41] | **No current commercial substitution**; strong bowed-string design precedent. |
| **TC-11** | Live; $24.99 one-time. [35][32] | iPhone+iPad, iOS/iPadOS 16+; v3.4.4, 2026-02-16. [35][32] | Deep multitouch-relational and motion-controlled synth, typically 8 and up to 11 touch voices. [36][37] | No MIDI/OSC performance control, no MPE/AUv3; standalone audio, Audiobus/IAA-era integration. [36][38] | Deep modular internal synth. [35][36] | **High** for experimental internal-synth job; **low** for controller job. |
| **Aftertouch** | **Delisted**; product ID 1133701231 currently returns no US listing. [44][45] | Historical iPhone/iPad app; last known generation depended on 3D Touch for Z. [45][46] | Historical X/Y/Z MIDI surface with MPE, pitch bend, CC and channel/poly pressure. [45][46] | Historical MIDI/MPE controller; present-day compatibility unavailable. [45][46] | No documented engine. [46] | Historical lineage only. |

### 2.2 Expression fidelity: what “MPE” means in practice

The headline “MPE” is not a uniform promise across this market:

| App | Attack velocity | X dimension | Y dimension | Independent Z/pressure on current hardware | Per-note channel behavior |
|---|---|---|---|---|---|
| GeoShred Control | Y position on iPad/non-3D devices; touch force on supported old iPhones. [7] | Pitch bend/slide with selectable pitch-rounding behavior. [5][6] | CC74 and/or channel pressure; on non-force hardware Y must serve multiple jobs. [5][7] | Generally no; only legacy 3D-Touch devices provide separate force. [7] | MPE channel mode plus string/channel-per-row and poly/channel-per-note modes. [5][6] |
| KB-1 | Initial Y position. [8] | Glide/pitch. [8] | Slide/assignable expression. [8] | “Pressure” is iPhone-only and protocol testing ties it to 3D Touch; vertical slide can substitute. [8][11] | MPE, with independently routed standalone keyboards. [8][9] |
| Velocity Keyboard | Proprietary glass-touch estimator. [12][13] | Smooth/corrected pitch bend. [12] | CC/aftertouch source. [12][13] | Touch-area proxy is current; actual force is legacy 3D Touch only. [12][13] | MPE plus dedicated conventional-MIDI fallback modes. [12] |
| KeyPad | Height-derived, with three response curves. [14][16] | Pitch bend in XY MPE. [14][16] | CC74 in XY MPE; mono/poly aftertouch modes also exist. [14][16] | Exact physical source/estimator for the advertised aftertouch is not documented clearly enough to call it true Z pressure. [14][16] | Member channels 2–16 in XY MPE. [14] |
| WoodTroller | Configurable note-on zone/velocity behavior. [20] | Per-note pitch in MPE or MIDI 2 Per-Note Pitch. [20] | Vertically separated pressure and CC74/controller zones. [20] | No physical-force claim; “pressure” is a value produced by vertical zones/motion. [20] | MPE plus MIDI 2 per-note controllers. [20] |
| Midi Poly Grid | Y position, random, or fixed. [21][23] | Push-style MPE bend. [21][23] | Push-style slide/poly aftertouch via swiping. [21][23] | No physical-Z claim. [21][23] | MPE or polyphonic aftertouch. [21][23] |
| ThumbJam | X position or legacy force, depending on mapping. [27] | Pitch travel is primarily along the long pitch axis; pitch bend can be drag or tilt. [27] | Configurable volume/pan/pressure mappings. [27] | Force only on old 3D-Touch hardware. [27] | Channel-per-touch output exists, but first-party discussion said onscreen output lacked CC74 “Y” and release velocity; no later source clearly closes that gap. [27][28] |
| Ribbons | Touch behavior; force can modify synthesis only on supported 3D-Touch devices. [29] | Continuous pitch/glide. [29] | Volume or synth parameter mapping. [29] | Legacy 3D Touch only. [29] | MPE, or manual port/channel per touch for poly pitch. [29] |
| TC-Data | Any chosen controller can set note-on velocity. [34] | Programmable pitch-bend output. [31][34] | Programmable CC/aftertouch output. [31][34] | Touch size and motion are available, but there is no automatic standardized X/Y/Z MPE mapping. [33][34] | Important limitation: a voiced controller feeding a normal MIDI CC sends only the newest touch's value, unless the user deliberately engineers separate channels/outputs; OSC preserves touch voice IDs more naturally. [34] |

**Interpretation:** the disappearance of 3D Touch makes genuinely independent X/Y/Z finger expression rare. Most current surfaces derive velocity, “pressure,” and timbre from position, motion, or touch area. ExpressionPad should be explicit that its pressure is gesture-derived, but it is not uniquely disadvantaged: GeoShred, KB-1, Ribbons, WoodTroller, Midi Poly Grid, and much of ThumbJam also remap 2D touch behavior rather than sensing three independent physical dimensions on modern hardware. [5][7][8][11][20][23][27][29][47]

## 3. Per-app profiles

### 3.1 GeoShred Control — strongest mature MPE benchmark

**Current offer.** GeoShred Control is a free universal iPhone/iPad controller at v7000.327.1.436, updated 2026-06-15, with iOS/iPadOS 15 as the current compatibility floor. The controller has no sound engine until the user buys the documented $24.99 Pro-functionality upgrade; modeled GeoSWAM/Naada instruments are additional optional purchases. [1][2][3]

**Playing model.** The surface is guitar-derived and isomorphic/diatonic rather than a conventional keyboard clone. It supports fretless-to-quantized playing, intelligent pitch rounding, alternative tunings, world scales/temperaments, monophonic, per-string, and channel-per-note poly modes, plus arpeggiation and backing tracks. [1][5][6] Horizontal movement drives pitch; on an iPad or other device without 3D Touch, initial Y position supplies velocity and later Y movement supplies Key-Y expression, while legacy pressure-capable iPhones can separate force into Key-Z/channel pressure. [5][6][7]

**Routing and customization.** GeoShred sends and receives MIDI/MPE and supports virtual MIDI, Wi-Fi/network, Bluetooth and wired/digital destinations; it can also run as an AUv3 that sends MIDI. Its editable control surface can add/move/delete knobs, sliders, buttons and two-dimensional expression pads, map multiple MIDI controls, apply curves, and save/share configurations with iCloud synchronization. [1][4][5] No current official OSC implementation was found. [1][5]

**Strengths.**

- Best combination of current maintenance, expressive pitch behavior, mature MPE routing and performance-specific controller editing in this set. [1][4][5][6]
- Free entry creates a very strong acquisition benchmark; the user can test a serious external controller before paying for sound. [1][3]
- The optional upgrade turns the same interaction model into a self-contained physically modeled instrument. [1][3]

**Weaknesses.**

- The product is broad and structurally complex; its guitar/string model is powerful but opinionated. [1][6]
- Modern devices lose independent force, so Y position/motion must encode velocity plus one or more ongoing expression dimensions. [5][7]
- The free tier is silent, while ExpressionPad is immediately audible. [1][3][47]

**Substitutability.** High. GeoShred Control is the clearest apples-to-apples benchmark for “turn glass into an MPE instrument.” It beats ExpressionPad on AUv3 workflow, MIDI configuration depth, custom/world tunings, arpeggiation, and mature preset sharing. ExpressionPad's defensible differences are square/hex/stacked-piano topology, unusually direct rows/columns and row-tuning control, mirrored two-thumb phone play, spring-back in-key vibrato, fret haptics, propagated visual ripples, and an included synth/sampler with no upgrade. [1][4][5][6][47]

### 3.2 KB-1 Keyboard Suite — the practical DAW keyboard replacement

**Current offer.** KB-1 is live at $14.99, universal on iPhone/iPad with iOS 11+, and was updated to v1.3.7 on 2025-10-14 for iOS 26 AU UI and Logic Pro MIDI-FX recording fixes. [2][8] No IAP or subscription is shown in the current listing. [8]

**Playing model.** The current listing describes eight template families: classic piano/wheels, Seaboard-like Uniform, String, Scale, Chord, Drum, XY, and CC. Users can create multiple rows/octaves, select 15+ scales, strum chords, run an arpeggiator, map up to 16 drum pads, use up to two XY pads, or expose up to 16 CC knobs. [8] Standalone mode supports as many as five independent keyboards in one session, each with its own MIDI output. [9]

MPE maps horizontal motion to glide/pitch, vertical motion to slide, initial Y to velocity, and pressure on iPhone only. That last dimension is a legacy-3D-Touch path; on modern hardware the vertical slide can still send aftertouch-like expression but is not an independent force sensor. [8][11]

**Integration.** KB-1 is both a standalone controller and AUv3 MIDI instrument with Inter-App, USB, BLE, and network MIDI. It has no internal synth and no documented OSC. [8][9]

**Strengths.**

- Strongest “one purchase, many conventional controller types” package in the direct set. [8]
- Multiple independently routed surfaces are useful for splits, layers, and playing several instruments from one screen. [8][9]
- AUv3 and low iOS minimum make it easy to insert into established mobile production workflows. [8]

**Weaknesses.**

- No sound; the first-run experience requires a host or destination. [8]
- Template breadth exceeds ExpressionPad, but note-surface topology and tactile pitch behavior are less distinctive; there is no documented mirror layout, fret haptics, or internal instrument. [8][47]
- First-party documentation is inconsistent: the developer product page still says five layouts while the App Store now says eight. [8][9]

**Substitutability.** High as an external controller and medium as a whole product. A user shopping specifically for an AUv3 master keyboard could choose KB-1 over ExpressionPad today; a user who values an instantly audible, phone-first continuous lattice has a different job. [8][9][47]

### 3.3 Velocity Keyboard — best velocity-specialist benchmark

**Current offer.** Velocity Keyboard is a $9.99 universal app at v1.3.22, updated 2025-09-24, requiring iOS/iPadOS 11+. [2][12] It is a controller only and deliberately loads no audio samples. [12][13]

**Playing model.** Four surface families cover piano, string, scale, and drums. The core claim is a proprietary estimator that extracts useful strike velocity from glass touch. It can use touch area, Y coordinate, actual force on old 3D-Touch hardware, velocity-to-CC, and four knobs as simultaneous CC sources; velocity can instead be sent as CC or aftertouch to accommodate synths whose patches do not respond well to note velocity. [12][13] Smooth cross-note pitch bend, pitch correction, custom-scale highlighting, and dedicated non-MPE modes make it a focused performance tool rather than merely a generic keyboard. [12]

**Integration.** It runs standalone and as an AUv3 MIDI controller. Current official text does not enumerate USB/network/virtual routing comprehensively enough to make a stronger claim, and no OSC support is documented. [12][13]

**Strengths.**

- Most direct benchmark for ExpressionPad's touch-derived onset velocity, because velocity quality is the product thesis rather than one checkbox. [12][13]
- Supports expressive fallbacks for non-MPE destinations. [12]
- Compact controller-only footprint and AUv3 integration. [12][13]

**Weaknesses.**

- No internal sound, no documented OSC, fewer layout/workflow tools than KB-1, and sparse current documentation. [12][13]
- Actual force is tied to obsolete 3D-Touch devices; contemporary behavior relies on position/area estimation. [12][13]
- Exact simultaneous-note limit and the full current standalone routing matrix are not published. [12][13]

**Substitutability.** Medium-high for users who primarily want responsive note entry into AUM/Logic/Cubasis; medium-low for ExpressionPad's broader surface, onboard sound, tactile slide, and phone-mirror jobs. [12][13][47]

### 3.4 KeyPad MIDI Controller — closest new free challenger

**Current offer.** KeyPad launched in 2026 and is currently free, universal, iOS/iPadOS 14+, and at v1.12 from 2026-06-21. [14][15] It is the only current direct entrant in this screen that combines a free download, AUv3 MIDI, OSC, an isomorphic MPE grid, and a built-in user-loadable sound engine. [14][16]

**Playing model.** It provides piano, isomorphic grid, nine drum pads, and an XY performance pad, with height-based velocity curves, pitch/mod/sustain controls, mono and poly aftertouch modes, and XY MPE. In that mode, channels 2–16 are per-note members, X maps to pitch bend, and Y maps to CC74. [14][16] The grid now includes scale remapping, piano-sharp shift, a minor-thirds interval mode, adjustable width, persistent root/layout state, and MPE-aware sustain. [14][15]

**Sound and routing.** KeyPad loads SF2 SoundFonts, SFZ instruments, Bliss ZBP/ZBB content, WAV, and M4A, automatically maps samples over the keyboard, persists imported files, and works both standalone and as an AUv3. It advertises virtual, network, Bluetooth and wired MIDI plus configurable OSC output. [14][16]

**Strengths.**

- On feature checkboxes and price, it is the most direct threat to ExpressionPad's combined controller/instrument value. [14][16][47]
- AUv3 and OSC cover two major current ExpressionPad gaps. [14][16][48]
- Free pricing makes it an immediate comparison download rather than a considered purchase. [14]

**Weaknesses and maturity risk.**

- Release notes as late as v1.12 are still fixing MPE pitch broadcast, MPE sustain, duplicated events, slide velocity, and pitch-bend stepping; an earlier specialist-forum report also described broken AUv3 MPE behavior before those fixes. [14][15][17]
- It is broad but conventional: no documented spring-back vibrato, semitone-crossing haptics, mirror surface, hex topology, ripple field, or dedicated continuous↔retrigger slide model. [14][16][47]
- The exact sensor/gesture source behind its separate aftertouch modes is not documented clearly enough to market it as real physical Z pressure. [14][16]

**Substitutability.** Very high on paper. This app should be treated as the most urgent hands-on comparison before ExpressionPad launch. Its differentiator is feature breadth and free price; ExpressionPad must win on feel, topology, phone ergonomics, musical legibility, tactile pitch behavior, and visual identity rather than on a checklist alone. [14][16][47]

### 3.5 WoodTroller — MPE ribbon plus MIDI 2 macro layer

**Current offer.** WoodTroller is live at $9.99, iPad-only with iPadOS 12+, and last updated to v2.7.3 on 2025-01-21. [18][19]

**Playing model.** Its note surface is a horizontal multitouch bar rather than a grid. Each held note can receive horizontal pitch movement, with vertical regions producing note-on, pressure/aftertouch, and CC74 or another controller. It supports MPE in MIDI 1 and the corresponding per-note pitch/controllers in MIDI 2. [18][20] The app also exposes macro rotaries and buttons capable of sending multiple commands to multiple channels; the current manual says v2.6 expanded this to 24 rotaries and 16 buttons, while the App Store description still says 8 and 8. [18][20]

**Integration and state.** WoodTroller runs standalone and as an AUv3, can advertise BLE MIDI, use network MIDI, store presets in iCloud, morph between four macro snapshots, and act as a MIDI 2 Capability Inquiry/Property Exchange initiator. It can populate control metadata from compatible endpoints. [18][20] No internal sound or OSC is documented. [18][20]

**Strengths.**

- Most forward-looking protocol story in the direct set: MIDI 2, CI and property exchange are unusual on iOS controller apps. [20]
- Deep macro fan-out, preset sync and snapshot morphing support live rigs beyond note playing. [18][20]
- AUv3 integration and explicit external routing are production-friendly. [18][20]

**Weaknesses.**

- iPad only and visually/utilitarily oriented around a ribbon plus macros, so it does not replace ExpressionPad's phone use or geometric scale surfaces. [18][20][47]
- Its “pressure” is a vertical-zone control message, not documented physical force. [20]
- Stale App Store copy understates current controls and increases evaluation friction. [18][20]

**Substitutability.** Medium. It competes for serious external-control rigs and exposes a protocol roadmap ExpressionPad lacks, but its musical surface and onboard-instrument story are fundamentally narrower. [18][20][47]

### 3.6 Midi Poly Grid — focused, open-source grid controller

**Current offer.** Midi Poly Grid is $3.99, universal on iPhone/iPad with iOS 13+, at v1.1.14 from 2026-02-14, and publishes its GPL-3.0 source. [21][22][23]

**Playing model.** The app intentionally avoids becoming a general MIDI Swiss Army knife. It offers a size-adjustable Push-like pad grid, saved surface presets, scale highlighting, optional pitch/mod/sustain controls, MPE and polyphonic aftertouch with graphical feedback, Push-style bend/slide, and Y-position, random or fixed velocity. [21][23] Users can set X/Y note intervals to build harmonic-table, Wicki-Hayden and other isomorphic arrangements; the grid can also receive notes and act like a Launchpad. [21][23]

**Integration.** It connects virtually to other iOS apps and via USB, BLE or Wi-Fi to other devices. The developer explicitly says AUv3 is not supported because of the Flutter implementation, and no OSC or internal sound is documented. [21][23]

**Strengths.**

- Extremely direct and legible proposition: inexpensive, expressive pads for people who prefer grids to piano keys. [21][23]
- Custom X/Y intervals and saved presets are meaningful competition to ExpressionPad's row-tuning/layout flexibility. [21][23][47]
- Open-source code gives users and competitors a transparent implementation reference. [23]

**Weaknesses.**

- No sound and no AUv3, so every performance requires a destination and standalone routing. [21][23]
- No documented hex or stacked-piano topology, mirrored thumb mode, haptic frets, spring vibrato, internal FX, or sampler. [21][23][47]
- Its Flutter constraint is an integration ceiling unless the implementation changes. [21][23]

**Substitutability.** High for a budget grid-only controller; low-to-medium for the whole ExpressionPad experience. It is also the clearest proof that a configurable MPE grid can be priced below $5. [21][22][23]

### 3.7 ThumbJam — aging but formidable all-in-one instrument

**Current offer.** ThumbJam is still live at $8.99 and supports iPhone/iPad as far back as iOS 8, but its current v2.6.11 dates to 2022-07-24 and primarily fixed iOS 16-era compatibility issues. [24][25]

**Playing model.** Notes rise along a scale-constrained long axis, and retrigger, glide and continuum modes range from discrete movement to continuous pitch with optional snapping. Up to four splits can use different keys, scales, ranges and instruments. [26][27] Gesture mappings include initial position or legacy force for velocity, position/force for volume, finger wiggle or shake for vibrato, shake for tremolo, device tilt for volume/pan/pitch, and drag for bend. [27] The current App Store listing says five simultaneous touches on iPhone and eleven on iPad, with up to 32 voices per instrument across as many as eight loaded instruments. [24]

**Sound and customization.** More than 40 multisampled instruments, downloadable extras, custom multisample recording/import, filters/effects, loops, recording, arpeggiation, microphone pitch tracking, hundreds of scales, cent-level editing and Scala/SXML import make it far broader than a pure controller. [24][27]

**Integration.** ThumbJam can mute its engine and operate as a controller over virtual, network, Bluetooth, or wired CoreMIDI, with channel-per-touch pitch and pressure output, MIDI clock, and extensive CC/RPN/NRPN handling. It also documents OSC output, Ableton Link, Audiobus and Inter-App Audio. [24][27] The App Store markets MPE input and output, but a first-party 2016 clarification said onscreen output still lacked MPE Y/CC74 and release “Lift”; no later release note clearly proves a complete five-dimensional output path. [24][27][28] No AUv3 instrument or MIDI extension is documented. [24][27]

**Strengths.**

- Best mature value bundle: playable surface, deep samples, custom instruments, splits, looper, arp, pitch tracker, scale system and broad MIDI/OSC. [24][27]
- The scale-safe promise makes sophisticated performance approachable to non-keyboardists. [24][26]
- It can genuinely replace several apps in a live setup. [24][27]

**Weaknesses.**

- Four-year update gap, no documented AUv3, and reliance on deprecated IAA/legacy 3D-Touch-era concepts create longevity risk. [24][25][27]
- Strict MPE output completeness remains uncertain. [27][28]
- Its menus and breadth make it feel like a mature sample-instrument workstation rather than a focused modern lattice. [24][27]

**Substitutability.** High as a standalone expressive instrument and medium-high as an external controller. ThumbJam beats ExpressionPad on sample depth, loops, arpeggiation, custom scales/instruments, splits and OSC. ExpressionPad is more modern and coherent around configurable topology, continuous/fretted slide, mirrored phone play, tactile/visual feedback, and explicit channel-per-touch pitch/pressure/CC74 output. [24][27][47]

### 3.8 Ribbons — elegant expressive lineage, maintenance risk

**Current offer.** Ribbons remains purchasable for $3.99 on iPhone/iPad with iOS 11+, but its only current version, 1.4, was released on 2019-01-19. [29][30]

**Playing model.** Inspired by the Ondes Martenot and Theremin, it uses a full-screen polyphonic ribbon: horizontal motion slides freely through pitch, note snapping is adjustable, vertical movement can control volume or synthesis, scale guidelines and alternative tunings aid intonation, and legacy 3D Touch can add force on supported iPhones. [29] MPE output assigns per-note expression automatically; a classic mode can manually assign each touch to a distinct MIDI port/channel for polyphonic pitch bend. [29]

**Sound and integration.** Ribbons includes a morphing wavetable/swarm synth, filter, ADSR modulation, delay and reverb. It supports MIDI plus Audiobus/Inter-App Audio and state saving, but the current listing documents neither AUv3 nor OSC. [29]

**Strengths.**

- One of the cleanest “glass is the instrument” metaphors in the market. [29]
- Internal synthesis and uncluttered performance surface make it immediately rewarding. [29]
- Cheap, universal, polyphonic and MPE-capable. [29][30]

**Weaknesses.**

- Seven-plus years without an update is the strongest maintenance warning among still-live direct competitors. [29][30]
- IAA/Audiobus-era architecture and no AUv3 limit modern host integration. [29]
- Pressure differentiation depends on legacy hardware. [29]

**Substitutability.** Medium-high in concept, medium-low as a purchase recommendation. It validates continuous pitch, scale-aware snapping and a visually spare surface, but ExpressionPad offers much broader topology, routing-independent onboard sound, haptics, and active modern implementation. [29][47][48]

### 3.9 TC-Data — relational gesture programming, not automatic MPE

**Current offer.** TC-Data is live at $19.99, universal with iOS/iPadOS 16+, and freshly maintained at v2.3.3 from 2026-02-16. [31][32] It makes no sound. [31][33]

**Control model.** Rather than showing knobs, keys or sliders, TC-Data turns touch position, size, speed, angle, distance, rotation, timing, chording, group relationships, accelerometer, gyro and compass data into more than 300 programmable controllers and triggers. AHDSR, LFO, table and sequencer modules can transform those streams before output. [31][33][34] Its historical manual allocates touch voice IDs 0–10, with global controls at voice -1; OSC preserves those voice/value pairs directly. [34]

**MIDI nuance.** TC-Data can emit notes, on/off velocity, poly or channel aftertouch, pitch bend, CC including 14-bit values, bank/program changes, and route separate outputs to ports/channels. It also provides virtual/network/BLE/external-interface MIDI and input passthrough. [31][33][34] It is not an MPE controller automatically: when a voiced touch source feeds a conventional MIDI CC, the manual says only the most recently created touch sends that CC to avoid interleaving, and per-finger pitch/pressure requires deliberate multi-channel patch design. [34] No AUv3 MIDI extension or formal MPE mode is documented. [31][33][34]

**OSC and customization.** OSC is a first-class Wi-Fi target with configurable addresses and voice IDs. Users can build unlimited patches from arbitrary outputs, ranges, slopes, scales, grids, modules and destinations, then tag, group and share them. [33][34]

**Strengths.**

- Deepest arbitrary gesture-to-message programmability and strongest OSC story in this direct set. [31][33][34]
- Touch relationships between fingers enable interactions that keyboard/grid apps do not attempt. [33][34]
- Current maintenance makes it more credible than its 2015 manual date suggests. [31][32][34]

**Weaknesses.**

- No internal sound, no AUv3, no automatic MPE channel allocation, and a configuration-heavy workflow. [31][33][34]
- Its own research paper/manual says conventional grid-note triggering is not its strongest role; it is often better used to augment a keyboard. [34]
- $19.99 is the highest controller-only price in this screened set. [31][32]

**Substitutability.** High for users who want custom OSC or abstract gesture data; medium-low for users who want to open an app and immediately play a labeled expressive instrument. It exposes a real ExpressionPad gap—OSC/arbitrary gesture routing—without displacing ExpressionPad's core musical immediacy. [31][33][34][47]

### 3.10 Pen2Bow — delisted niche precedent

Pen2Bow is no longer returned by the US App Store or Apple Lookup, and checks in several other storefronts also failed. An archived November 2025 listing showed $7.99, iPadOS 11+, iPad/Apple Pencil only, and v1.1.2 from 2020-06-22; a May 2026 community post placed delisting around spring 2026, but the exact date is unknown. [39][40][41][54]

The app converted Apple Pencil bow velocity, force, tilt and orientation into four continuous MIDI streams, recognized linear and circular/figure-eight movement, and used circular movement as an effectively infinite bow. It later added a touch piano, per-stream ranges/sensitivity, smoothing, selectable channel, and an AUv3 MIDI-effect mode whose multiple instances could be routed and state-saved separately. [41][42][43] It was not documented as MPE and had no internal sound. [41][42]

**Assessment:** not a current competitor, but an excellent product-design precedent. It solved one acoustic-instrument gesture exceptionally well instead of offering a generic surface. An Apple Pencil “bow” or “strum” mode could extend ExpressionPad without diluting the main lattice if treated as an optional performance mode. [41][42][47]

### 3.11 TC-11 — direct internal-instrument rival, rejected as controller

TC-11 is live at $24.99, universal with iOS/iPadOS 16+, and updated to v3.4.4 on 2026-02-16. [35][32] It is a deeply programmable modular synth in which individual touches become voices and distances, angles, speeds, timings, group relationships, accelerometer, gyro and compass can control synthesis; default/current documentation spans roughly eight to eleven touch voices and supports as many as four simultaneous patch panes on capable iPads. [35][36][37]

The developer FAQ is explicit that TC-11 itself is the synth and does not send MIDI/OSC performance data; it has no documented MPE or AUv3. TC-Data is the corresponding external controller product. [36][38] TC-11 therefore competes strongly with ExpressionPad's self-contained expressive-instrument job, especially for experimental sound design, but not with its MPE-controller job. [35][36][38][47]

### 3.12 Aftertouch — discontinued 3D-Touch/MPE lineage

Aftertouch's former App Store product ID is unavailable, and the developer site no longer exposes a live purchase link. [44][45] Historical first-party/launch material described an X/Y/Z expressive MIDI surface supporting MPE, pitch bend, assignable CC, and channel/poly pressure, with Z tied to 3D Touch. [45][46] It is useful historical evidence that the market once expected pressure-sensitive iPhones to become software MPE controllers; Apple's removal of 3D Touch explains why current apps increasingly synthesize the third dimension from Y motion, touch area, or stylus data. [45][46]

## 4. Implications for ExpressionPad

### 4.1 Positioning

**Own “the modern configurable instrument,” not “an iPad MIDI controller.”** The latter is crowded by free GeoShred Control and KeyPad, inexpensive Midi Poly Grid/Ribbons, and mature KB-1/Velocity Keyboard. [1][8][12][14][21][29] The repository supports a more distinctive claim: ExpressionPad combines square, hex and stacked-piano topology; continuous or fretted slide; spring-back vibrato; semitone haptics; mirror play; musical color/ripple feedback; internal synthesis/sampling/effects; and per-touch MPE-style output in one coherent instrument. [47]

**Make the phone story central.** Most rivals are universal, but their core merchandising and workflows remain tablet/DAW oriented; WoodTroller and the historical Pen2Bow are iPad-only. [8][12][18][41] ExpressionPad's reflected two-thumb layout with independent right-side pitch offset is a specific phone performance idea that no screened direct competitor documents. [47]

**Be honest and precise about expression.** “Each finger has independent pitch, velocity and aftertouch” is supportable, but “true three-dimensional pressure” is not: ExpressionPad derives velocity from touch position and aftertouch/CC74 from vertical drag. [47] This transparency can become a trust advantage because several competitors use “pressure” language even when modern hardware supplies no independent force dimension. [7][8][11][20][27][29]

### 4.2 Product priorities

1. **AUv3 MIDI must be the first ecosystem gap to close.** GeoShred Control, KB-1, Velocity Keyboard, KeyPad and WoodTroller can live inside a host with project-state recall; ExpressionPad currently cannot. [1][8][12][14][18][48] For iOS producers, this affects daily workflow more than another oscillator or color scheme.
2. **Fix foreground-only/native lifecycle before promising performance reliability.** The repository README describes background audio, but the current implementation stops/silences the engine in background and has no background-audio entitlement; the product should either implement background audio or document foreground-only behavior clearly. [48]
3. **Add named preset banks plus import/export.** GeoShred has shareable/iCloud presets, KB-1 has multi-keyboard sessions, Midi Poly Grid saves pad setups, WoodTroller syncs presets, ThumbJam stores deep instrument/split setups, and TC-Data shares arbitrary patches. [1][8][18][21][23][27][33][34] ExpressionPad currently auto-persists one state and shares only a subset through web URL parameters. [47]
4. **Add custom scale/tuning import.** GeoShred has world scales/temperaments, ThumbJam supports cent-level custom scales and Scala/SXML, and Midi Poly Grid exposes arbitrary X/Y grid intervals. [1][5][21][23][27] ExpressionPad's fixed built-in scales/tunings are good launch material but a clear ceiling for advanced isomorphic users. [47]
5. **Separate or explicitly route CC74 and pressure.** Current ExpressionPad sends the same gesture-derived value to channel pressure and optional CC74. [47] A configurable second-axis strategy—touch area, velocity-following envelope, tilt, Apple Pencil, or a dedicated expression strip—would make its MPE claim more musically meaningful even without physical Z sensing.
6. **Broaden MIDI input beyond note on/off.** GeoShred and ThumbJam can act as expressive sound engines for outside controllers, while ExpressionPad's current input ignores pitch bend, aftertouch, CC, program, clock and MPE expression. [5][27][47] Supporting MPE input would make its synth/sampler valuable even when the user reaches for a hardware Seaboard/LinnStrument.
7. **Expose BLE/network/wired setup as a guided workflow.** Competitors merchandise connection paths prominently. [1][8][14][18][21][27] ExpressionPad has CoreMIDI and a network session in code, but connection confidence is a product feature, not merely a protocol implementation. [48]
8. **Consider OSC after AUv3, not before it.** KeyPad, ThumbJam and TC-Data demonstrate real OSC demand, especially for desktop creative coding and visuals. [14][16][27][31][33][34] It is differentiating but less central to the core melodic-MPE job than host integration, presets, or full MIDI input.
9. **Treat Apple Pencil as an optional expansion surface.** Pen2Bow shows how velocity, pressure, tilt and orientation can form a compelling acoustic metaphor. [41][42] A Pencil bow/strum/controller mode could add a genuine extra dimension without altering finger behavior.
10. **Preserve and test tactile identity.** Haptic fret crossings, spring-recentering vibrato, mirror geometry and propagated note ripples are rare in this market and should not be buried under controller utilities. [47] They are the features most likely to make a side-by-side demo feel different from KeyPad, KB-1 or Midi Poly Grid. [8][14][21]

### 4.3 Packaging and pricing implications

The live market has three price bands:

- **Free acquisition anchors:** GeoShred Control and KeyPad. [1][14]
- **Low-cost specialists:** Ribbons and Midi Poly Grid at $3.99. [21][22][29][30]
- **Paid pro utilities/instruments:** ThumbJam $8.99, Velocity Keyboard and WoodTroller $9.99, KB-1 $14.99, TC-Data $19.99, and TC-11 $24.99. [2][18][19][24][25][31][32][35]

This makes a paid, silent controller difficult to launch without AUv3 or a unique hardware metaphor. ExpressionPad is not silent: its internal synth/sampler/FX and unusually differentiated phone/tactile surface justify monetization above the $3.99 grid-utility floor. [47] However, free GeoShred Control and free KeyPad mean the product needs either a free playable tier/demo or extremely persuasive video proof before asking users to pay. [1][14]

A plausible packaging hypothesis for the lead brief is:

- free download with a fully playable surface and limited saved setups/sounds;
- one-time “Pro” unlock for full synth/sampler/FX, preset banks and external MPE;
- no subscription unless it funds a continuing sound/preset library.

That is a recommendation, not a claim about current ExpressionPad implementation. Current v2 monetization is unknown; the historical original was described as free. [49]

### 4.4 Launch/demo implications

The category is easiest to understand through motion, not screenshots. A strong launch sequence should demonstrate:

1. two thumbs playing the mirrored phone layout;
2. one finger sliding continuously, enabling frets, feeling haptic semitone crossings, then adding spring-back vibrato;
3. multiple fingers bending independently while an MPE monitor shows separate channels;
4. instant switch from internal synth to sampler;
5. the same geometry on iPad and web;
6. a direct A/B against a conventional onscreen piano.

Those beats map to implemented repository behaviors rather than speculative roadmap. [47][48]

## 5. Unknowns, contradictions, and verification needs

1. **GeoShred price snippets conflict.** Cached Exa/App Store renderings surfaced a temporary-looking $16 Control→Pro IAP, while the current developer quick-start and direct App Store verification used by this research show $24.99. Treat $24.99 as the checked current/standard figure and re-check immediately before publication. [1][3]
2. **GeoShred minimum-OS copy conflicts.** The description still mentions iOS 13 for some features, while the live compatibility field and current guide require iOS 15. [1][3]
3. **GeoShred/KB-1/Velocity exact touch limits are unpublished.** MPE member channels impose an upper protocol bound, but software touch/voice caps were not found in current first-party text. [1][5][8][9][12][13]
4. **KB-1 layout count is stale on the developer site.** The live listing says eight; the product page still says five. [8][9]
5. **Velocity standalone connectivity is under-documented.** AUv3 and MPE are clear; USB/network/virtual behavior should be verified hands-on before a detailed routing claim. [12][13]
6. **KeyPad is moving quickly.** v1.12 release notes fix core MPE behavior, so its current feel/stability should be tested directly rather than inferred from earlier forum complaints or feature copy. [14][15][17]
7. **WoodTroller control counts conflict.** The store description says 8 knobs/8 buttons; the current manual says later versions expanded to 24/16. [18][20]
8. **ThumbJam polyphony copy conflicts.** The live App Store says 32 voices per instrument; the older homepage says 24. [24][26] Use 32 with attribution to the live listing.
9. **ThumbJam MPE output completeness is unresolved.** Marketing says MPE input/output; the manual documents channel-per-touch and pressure/pitch, while a developer post says onscreen output lacked CC74 Y and note-off velocity. [24][27][28]
10. **Ribbons is live but dormant.** Current-OS functionality beyond Apple's compatibility declaration has not been hands-on tested after its 2019 update. [29][30]
11. **TC-Data manuals are old.** They predate its 2026 UI work and some later routing additions; formal MPE/AUv3 still are not claimed, but current maximum touches and every transport feature need direct app inspection. [31][32][34]
12. **TC-11 documentation counts vary.** Sources say 160 or 185 presets, 22 or 24 oscillator waveforms, and 8 default/up to 11 voices. These do not change the scope decision: it is an expressive internal synth, not an external MIDI surface. [35][36][37][38]
13. **Pen2Bow removal date/redownload rights are unknown.** It was live in an archived November 2025 capture and absent by spring/summer 2026, but prior-purchaser compatibility was not tested. [39][40][41][54]
14. **Aftertouch historical details are not current product evidence.** Its inclusion is lineage only. [44][45][46]
15. **ExpressionPad current App Store price/status are not in the repository.** No StoreKit, subscription, ad, trial or entitlement path was found; do not present the historical app's free price as the new v2 price. [49]
16. **ExpressionPad background-audio docs and implementation conflict.** The engineering README describes background audio, but current lifecycle code stops it; verify and resolve before marketing. [48]
17. **Hands-on priority list:** KeyPad v1.12, GeoShred Control current build, KB-1 v1.3.7, Velocity v1.3.22, and ExpressionPad on the same iPhone/iPad with the same MPE synth. This is the minimum fair test of latency, false retriggers, pitch accuracy, stuck notes, host recall, and two-thumb ergonomics.

## 6. Numbered source list

1. GeoShred Control, US App Store: https://apps.apple.com/us/app/geoshred-control/id1336247116
2. Apple Lookup, GeoShred Control + KB-1 + Velocity Keyboard: https://itunes.apple.com/lookup?id=1336247116,1437919435,1462605052&country=us
3. GeoShred Control current quick-start/monetization guide: https://www.moforte.com/geoshred-control-quick-start-guide/
4. GeoShred control-surface editor manual: https://www.moforte.com/geoShredAssets7000/help/controlSurface.html
5. GeoShred current MIDI/MPE manual: https://www.moforte.com/geoShredAssets7000/help/midi.html
6. GeoShred performance/play-mode settings: https://www.moforte.com/geoShredAssets7000/help/effects/geoShredState.html
7. GeoShred 3D Touch / Key-Y settings: https://www.moforte.com/geoShredAssets7000/help/settings.html
8. KB-1 Keyboard Suite, US App Store: https://apps.apple.com/us/app/kb-1-keyboard-suite/id1437919435
9. KB-1 official product page: https://numericalaudio.com/kb1/
10. KB-1 v1.3.1 feature history, KVR: https://www.kvraudio.com/news/numerical-audio-updates-kb-1-expressive-keyboard-suite-to-v1-3-1-for-ios-55844
11. Audiobus Wiki software-MPE controller protocol observations: https://abwiki.loopypro.com/doku.php?id=mpe_sw_controller
12. Velocity Keyboard, US App Store: https://apps.apple.com/us/app/velocity-keyboard/id1462605052
13. Velocity Keyboard official developer page: http://www.bluemangoo.com/vecocity_keyboard.php
14. KeyPad MIDI Controller, US App Store: https://apps.apple.com/us/app/keypad-midi-controller/id6758680165
15. Apple Lookup, KeyPad MIDI Controller: https://itunes.apple.com/lookup?id=6758680165&country=us
16. KeyPad official discoDSP page: https://www.discodsp.com/keypad/
17. KeyPad release/user-testing thread, Loopy Pro Forum: https://forum.loopypro.com/discussion/67519/keypad-midi-controller-by-discodsp-released
18. WoodTroller, US App Store: https://apps.apple.com/us/app/woodtroller/id6445840179
19. Apple Lookup, WoodTroller: https://itunes.apple.com/lookup?id=6445840179&country=us
20. WoodTroller manual: https://forum.loopypro.com/uploads/editor/ir/1wte9vipqa63.pdf
21. Midi Poly Grid, US App Store: https://apps.apple.com/us/app/midi-poly-grid/id1633882803
22. Apple Lookup, Midi Poly Grid: https://itunes.apple.com/lookup?id=1633882803&country=us
23. Midi Poly Grid official/open-source repository: https://github.com/anzbert/beat_pads
24. ThumbJam, US App Store: https://apps.apple.com/us/app/thumbjam/id338977566
25. Apple Lookup, ThumbJam: https://itunes.apple.com/lookup?id=338977566&country=us
26. ThumbJam official site: https://thumbjam.com/
27. ThumbJam official v2.6 manual: https://thumbjam.com/docs.php
28. ThumbJam MPE-output developer clarification: https://forum.loopypro.com/discussion/13656/thumbjam-v2-5-is-finally-out/p3
29. Ribbons: Touch Instrument, US App Store: https://apps.apple.com/us/app/ribbons-touch-instrument/id898059305
30. Apple Lookup, Ribbons: https://itunes.apple.com/lookup?id=898059305&country=us
31. TC-Data, US App Store: https://apps.apple.com/us/app/tc-data/id883788579
32. Apple Lookup, TC-Data + TC-11: https://itunes.apple.com/lookup?id=883788579,488577050&country=us
33. TC-Data official product page: http://bitshapesoftware.com/instruments/tc-data/
34. TC-Data official user guide: http://www.bitshapesoftware.com/instruments/tc-data/tc-data-user-guide-1.0.pdf
35. TC-11, US App Store: https://apps.apple.com/us/app/tc-11/id488577050
36. TC-11 official product page: https://bitshapesoftware.com/instruments/tc-11/
37. TC-11 official user guide: http://www.bitshapesoftware.com/instruments/tc-11/tc-11-user-guide-2.0.pdf
38. TC-11 vs TC-Data official FAQ: http://www.bitshapesoftware.com/instruments/tc-11/tc-faq.html
39. Pen2Bow former US App Store URL, now 404: https://apps.apple.com/us/app/pen2bow/id1358113198
40. Apple Lookup, Pen2Bow, currently zero results: https://itunes.apple.com/lookup?id=1358113198&country=us
41. Archived Pen2Bow App Store listing, 2025-11-13: https://web.archive.org/web/20251113191845/https://apps.apple.com/us/app/pen2bow/id1358113198
42. Pen2Bow developer launch/update thread: https://vi-control.net/community/threads/violin-bow-midi-controller-using-the-apple-pencil.70168/
43. Pen2Bow AUv3/channel update thread: https://forum.loopypro.com/discussion/25444/apple-pencil-now-a-midi-controller/p3
44. Aftertouch former US App Store ID, now unavailable: https://apps.apple.com/us/app/id1133701231
45. Aftertouch developer site: https://rkn.la/
46. Aftertouch historical launch specification, Synthtopia: https://www.synthtopia.com/content/2016/11/12/aftertouch-for-ios-offers-three-axes-of-midi-control/
47. Local ExpressionPad product baseline: `/Users/cdeck/dev/expressionpad/README.md`
48. Local native-iOS implementation baseline: `/Users/cdeck/dev/expressionpad/ios/README.md` plus implementation cross-check in `ios/App/ExpressionPadApp.swift` and `ios/App/AudioEngine.swift`
49. Local historical ExpressionPad evidence: `/Users/cdeck/dev/expressionpad/reference/DESIGN.md`
50. Seaboard 5D, US App Store: https://apps.apple.com/us/app/seaboard-5d/id1173937855
51. Musix Pro, US App Store: https://apps.apple.com/us/app/musix-pro-midi-controller/id585857087
52. Gestrument Pro, US App Store: https://apps.apple.com/us/app/gestrument-pro/id1105890031
53. ChordUp, US App Store: https://apps.apple.com/us/app/chordup/id1058553903
54. 2026 Pen2Bow delisting observation: https://forum.loopypro.com/discussion/68490/auv3-apps-that-support-apple-pencil-or-point-out-ones-that-don-t

