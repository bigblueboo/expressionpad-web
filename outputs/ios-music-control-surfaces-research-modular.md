# Modular iOS MIDI, OSC, and Music-Control Surfaces

**Competitive research for ExpressionPad — task T3**  
**Evidence cutoff:** 2026-07-25  
**Storefront:** U.S. App Store unless noted

## Executive summary

The external-control market on iOS is not one category. It separates into three:

1. **Blank-canvas controller builders** such as TouchOSC, MIDI Designer Pro X, Lemur, and Surface Builder. These let users construct the exact faders, buttons, XY pads, logic, and messages their rig needs.
2. **Rig brains with editable control surfaces** such as Loopy Pro, AUM, and LK. Their on-screen controls are part of a larger host, looper, sequencer, or Ableton workflow.
3. **Focused performance and MIDI utilities** such as Ribn, sqsl Strips, midiLFOs, Mozaic, Midiflow, and MidiFire. They solve a narrow modulation, transformation, or routing job especially well.

The strongest current blank-canvas competitors are **TouchOSC**, **MIDI Designer Pro X (MDPx)**, **Lemur**, and the newly active **Surface Builder**. TouchOSC is the broad cross-platform MIDI/OSC construction kit; MDPx is the deepest MIDI-first, hardware-oriented builder; Lemur remains the maximal scriptable and physics-driven environment; Surface Builder is the accessible AUv3/standalone builder that can also play audio clips. All four demand more setup than an opinionated instrument. None documents a turnkey, touch-native MPE performance model comparable to a dedicated expressive controller. TouchOSC and Lemur could approximate sophisticated multichannel expression through manual routing or code, but this is not the same as a native MPE zone allocator and coherent per-touch gesture system. [S1][S4][S7][S10][S13][S15][S19]

The highest-pressure adjacent competitor is **Loopy Pro**. It combines a multipage canvas, widgets, actions, MIDI learn, state feedback, external MIDI output, AUv3 hosting, routing, looping, sampling, and sequencing. It is a control room rather than a focused instrument, but it can replace several apps in a performance rig. **AUM** is a complementary or substitute hub rather than a custom surface: it wins at routing, hosting, recording, and incoming MIDI learn, while offering only a conventional built-in keyboard and mixer. **LK** sits between these poles, with modular controller, XY, pads, chord, MPE keyboard, sequencing, AUv3, and Ableton integration. [S27][S29][S31][S33][S36][S37]

The market has also become more crowded at the low end. **MIDI Layout** ($1.99), **Jockey OSC & MIDI** ($9.99), **Mult Controller** (free), and **OSC Controller** ($3.99) all shipped or materially advanced in 2026. These apps make basic custom layouts inexpensive. Their evidence is still mostly developer and App Store copy, with little independent testing, but they raise the baseline expectation that users can build a panel on-device, save it, lock it for performance, and connect over common wired or wireless routes. [S21][S23][S25][S63]

The clearest defensible opening for ExpressionPad is therefore **not “customizable touch MIDI controller.”** Mature tools already own that language. The stronger space is:

> **An instrument-first, immediately playable expressive surface with coherent musical behavior, native per-touch expression, and useful internal sound—while still connecting cleanly to the rest of the iOS and hardware ecosystem.**

That position should be supported by excellent connection guidance, destination profiles, visible MIDI state, a panic control, performance locking, and first-class operation with AUM and Loopy Pro. A pure “draw any control you want” arms race would pull ExpressionPad toward the complexity of TouchOSC and Lemur and away from its more valuable instrument identity.

## Method

- Exa was used for broad discovery, product-name searches, current App Store pages, manuals, release histories, developer announcements, and specialist reviews.
- Availability, U.S. price, current version, release date, and minimum OS were normalized against Apple’s live U.S. storefront and public lookup catalog on 2026-07-25. The report cites product App Store pages rather than search-result pages.
- Feature claims were verified first against developer product pages and manuals. Independent specialist sources are used for workflow, reputation, and historical context, not as the sole authority for current price or availability.
- “No documented MPE/OSC/AUv3” means the current official listing, product page, and manual did not claim it. It does **not** prove that raw MIDI primitives cannot be scripted into a partial workaround.
- No apps were purchased or hands-on tested. Reliability, latency, reconnection behavior, and current IAP purchase flows remain documentary findings.
- A product is in scope when it can act as an external control surface, MIDI/OSC generator, controller builder, controller-aware host, or transformation/routing layer. Conventional keyboard/grid apps and MIDI sequencers are screened only where their controller surfaces materially overlap.
- Exact update dates are shown instead of treating continued App Store availability as proof of active maintenance.

## Market map

| Archetype | Representative products | What the user is really buying | Main competitive pressure on ExpressionPad |
|---|---|---|---|
| Blank-canvas MIDI/OSC builder | TouchOSC, MDPx, Lemur, Surface Builder, MIDI Layout, Jockey, Mult | A software-defined replacement for a hardware control panel | Arbitrary layouts, exact target mappings, feedback, scripting, community templates |
| Host/DAW with editable canvas | Loopy Pro | A whole live-performance environment with custom controls | One app can host sound, route MIDI/audio, loop, sequence, and control a rig |
| Fixed host/mixer control surface | AUM | A dependable routing, mixing, hosting, recording hub | Deep MIDI learn and session integration; natural downstream home for a controller |
| Modular controller suite | LK | A set of ready-made controller roles plus Ableton and AUv3 integration | MPE keyboard, XY modulation, pads/chords, sequencing, 128 assignable parameters |
| Focused gesture/modulation tool | Ribn, sqsl Strips, midiLFOs, Rozeta XY/LFO | A distinctive modulation gesture or automatic control source | One highly legible job with immediate value |
| Programmable MIDI utility | Mozaic, StreamByter, MidiFire, Midiflow | A solution to unusual routing/remapping/generation problems | Expert users can add missing behavior without waiting for the controller developer |
| Sequencer with controller affordances | Xequence 2; marginally Atom 2 and Piano Motifs | MIDI capture/edit/generation first, live control second | Less direct; competes for the “drive external synths from iOS” job |

## Evidence matrix A: direct and near-direct surface builders

| Product | U.S. price; current version | Devices / update | Editability | Protocols and connections | Expression / MPE | Learn / remap | Sound / hosting | Competitive read |
|---|---|---|---|---|---|---|---|---|
| **TouchOSC** | $19.99 upfront; no IAP/subscription listed. v1.5.2. [S1][S3] | iPhone/iPad, iOS 13+; 2026-07-01 | Full nested canvas, integrated editor, Lua, local messages, desktop/mobile synchronized editing | Bidirectional MIDI 1.0; OSC UDP/TCP; ten MIDI and ten OSC connections; USB, virtual, network, BLE, Bridge [S2][S4][S5] | No native MPE mode documented; raw note, per-channel pitch bend, pressure, and CC are available | Per-control message assignment; target-side learn common; no global capture-learn workflow documented | Controller only; no sound or AUv3 host documented | Category benchmark for arbitrary cross-platform control; high setup cost and little built-in musical opinion |
| **MIDI Designer Pro X** | Free; platform-scoped Premium from $1.49/month; iPhone+iPad $2.99/month or $29.99/year; lifetime $124.99. v10.25.0. [S7][S8] | iPhone/iPad, iOS 18.6+; 2026-07-15 | Full on-device builder; knobs, sliders, XY, pads/keys, pickers, accelerometer; super/subcontrols; 350+ shared layouts; 2026 multiselect | MIDI over USB, BLE, RTP/network, virtual ports; AUv3 MIDI Processor; Ableton Link; advanced SysEx/NRPN [S9][S10][S11] | No explicit MPE or MIDI 2.0 mode found; older official Q&A says no pressure-sensitive controls [S67] | Incoming learn for some message types; deep manual mapping; Stream Byter for transformations | No sound; embeds as AUv3 MIDI processor but does not host instruments | Best MIDI/hardware-synth specialist; strong no-code relationships and community; dense UI and severe free page limits |
| **Lemur** | Free shell; $99.99 lifetime listed, plus $12.99 monthly / $99.99 yearly legacy subscription entries. v5.7.5. [S13] | iPhone/iPad, iOS 13.6+; 2025-03-19; in-app editing is iPad-only | Desktop editor/Daemon; nearly full iPad editor; LemurLang, Canvas, images, physics, custom widgets, clocks, sequencers | Bidirectional MIDI and OSC; eight targets; Wi-Fi, USB/Thunderbolt, CoreMIDI [S14][S15] | No explicit MPE mode; poly pressure and multichannel scripting are primitives, not turnkey MPE | Manual assignment and Automap; no current input MIDI-learn workflow documented | No audio engine or AUv3; internal control sequencers only | Deepest programmable HMI and important design ancestor; premium price, steep learning, and lifecycle risk |
| **Surface Builder** | $14.99, no IAP listed. v1.23. [S19] | iPhone/iPad, iOS 13+; 2026-07-10 | Drag/drop controls, images, keyboard, XY, six scenes, hide/show objects, presentation mode, undo/redo | Bidirectional MIDI; CoreMIDI/Bluetooth; standalone and AUv3 MIDI/instrument forms | Sends pitch bend and conventional MIDI; no documented MPE allocator | Manual per-object configuration; incoming MIDI can drive interface objects | Hosts no third-party instruments, but passes audio and turns buttons into audio-clip players | Strong under-the-radar direct match: approachable surface builder plus AUv3/session state and simple audio triggering |
| **MIDI Layout** | $1.99, no IAP listed. v1.0. [S21] | iPad only, iPadOS 17.6+; 2026-03-12 | Drag/drop knobs, faders, buttons, pads, keyboard, Theremin pad; unlimited layouts; perform lock; bulk multiply; import/export | CoreMIDI; Network MIDI and USB to Mac are documented | Theremin pad sends continuous pitch bend or quantized scales; no MPE documented | Manual CC/channel/range configuration; no learn documented | No sound/host documented | Very low-price, on-device direct builder; expressive pad is notable, but protocol breadth and app-to-app evidence are limited |
| **Jockey OSC & MIDI** | $9.99, no IAP listed. v3.1.0. [S23] | iPhone/iPad/Mac/Vision, iOS 17+; 2026-07-20 | Grid UI builder: buttons, sliders, rotary, joystick, counters, lists, indicators, trails and control stacks; iCloud autosave | Bidirectional OSC and MIDI; device motion, Siri Shortcuts, Home/Control Center widgets, game controllers [S24] | Motion/joystick can be expressive; no native MPE documented | Per-module assignment; no MIDI-learn documentation found | No sound/host documented | Fresh, broad Apple-platform OSC/MIDI builder; differentiates with system widgets and motion, but specialist evidence is sparse |
| **Mult Controller** | Free; no IAP listed. v1.0. [S25] | iPhone/iPad, iOS 16+; 2026-06-22 | Canvas sessions; knob, slider, button, switch, XY, physics pad, image pad, gyro, AR coordinates, compass, mic envelope | OSC 1.0/UDP; CoreMIDI; BLE and Network MIDI; configurable per-control note/CC/channel | Strong sensor vocabulary; no MPE or per-note allocator documented | Manual message setup; no learn documented | Mic envelope is a control source, not a sound engine; no host | Most audacious free newcomer; unusually rich sensors, but v1.0 claims have almost no independent verification |
| **MidiPad 2** | $2.99. v2.0.3. [S39] | iPhone/iPad, iOS 10+; **2017-12-13** | Unlimited colored velocity-sensitive pads, multiple pages, multiple messages per pad, latch/momentary | Notes, CC, program change; CoreMIDI and RTP/Wi-Fi [S40] | Velocity inferred from device motion; no pitch surface or MPE | Manual pad actions; reviews request better numeric entry, copying, and page navigation [S41] | No sound/host | Still useful as a gig button board, but stale and pad-only |
| **Knob Lab** | Free single-knob layout; full-unlock IAP amount not exposed in current evidence. v2.1.2. [S42][S43] | iPhone/iPad, iOS 10.2+; **2021-09-25** | Knob-centric layouts; one knob can drive up to eight destinations with independent ranges | USB, Wi-Fi, BLE, virtual MIDI, Audiobus documented | Continuous CC only; no MPE | Destination mapping/range transformation; MIDI logger; no broad learn evidence | No sound | A useful macro-control idea, not a general modern canvas; maintenance risk |
| **OSC Controller** | $3.99. v2.2. [S63] | iPhone/iPad, iOS 15.6+; 2026-06-04 | Faders, knobs, buttons, switches, XY, radio, text, launchpad/matrix and sensors | Bidirectional OSC over UDP/TCP; configurable IP/port [S65] | Mic, accelerometer and gyro sources; no MIDI or MPE | Manual OSC assignment | No sound/host | New OSC-only budget alternative; less relevant to MIDI-first users |
| **Midi Controller – Remote & USB** | Free; $3.99/month or $29.99 lifetime. v2.0. [S64] | iPhone/iPad, iOS 17+; 2024-03-19 | Unlimited customizable pushes/buttons and sliders | USB, WLAN, BLE CoreMIDI; notes, CC, program change | No MPE documented | Send-only; description explicitly says it does not receive MIDI | No sound | Cheaper basic builder, but subscription messaging and lack of feedback make it less robust |

## Evidence matrix B: hosts, suites, and programmable utilities

| Product | U.S. price; current version | Devices / update | Control-surface relevance | Protocols / learn / expression | Sound / hosting | Competitive read |
|---|---|---|---|---|---|---|
| **Loopy Pro** | Free 7-day trial; $29.99 permanent unlock; optional $14.99 update year; no subscription. v2.0.5. [S27][S28] | iPhone/iPad, iOS 13+; 2025-11-26 | Multipage canvas with buttons, sliders, dials, encoders, XY, grids, slicers, labels, gestures, action chains and state feedback | Sends note/CC/PC/pitch bend/SysEx/14-bit CC; USB/BLE/network/virtual MIDI; deep MIDI learn; receives OSC but no arbitrary outbound OSC action; records/routes MPE but widgets are not documented as an MPE instrument [S29] | AUv3 host, looper, sampler, sequencer, arranger, mixer, recorder; no bundled synth/library | The strongest “build the whole performance rig” substitute, but heavier and less immediately expressive |
| **AUM** | $20.99; tip IAPs only. v1.4.8. [S31] | iPhone/iPad, iOS 12+; 2025-11-23 | Mixer/patch-bay composition is editable, but there is no blank widget canvas; built-in conventional keyboard | MIDI matrix, virtual/network/BLE/hardware, buses and filters; incoming learn for mixer, transport, sessions and AU parameters; no native OSC or MPE mode documented [S33] | Deep AUv3/IAA/Audiobus host, routing, processing, recording; no purpose-built synth | Adjacent substitute and likely ecosystem partner; wins at orchestration, not at touch-instrument design |
| **LK** | Free trials; Matrix $13; five other modules $6.49 each; all-modules bundle $32.49; no subscription listed. v1.15.11. [S36] | iPhone/iPad, iOS 17+; 2026-07-17 | Controller module exposes 128 assignable faders/knobs/buttons/pads; separate XY, pads, chorder, keyboard and Matrix sequencer modules | Virtual/USB MIDI, AUv3, UBRIDGE wired/wireless Ableton integration; XY CC/note with LFO/envelope; Keyboard explicitly supports MPE [S37][S38] | AUv3 MIDI tool and sequencer/controller; no internal audio engine | Closest modular suite to combining ready-made expression, DAW control, and sequencing; less free-form than blank-canvas builders |
| **Mozaic Plugin Workshop** | $1.99. v1.4.2. [S50] | iPhone/iPad, iOS 12.4+; 2025-07-10 | Scriptable MIDI control panels using five prefab GUI layouts, knobs, sliders, pads, labels and tilt | AUv3 MIDI; scripts handle notes, CC, SysEx, timers, scales, LFOs and host data; no OSC or explicit MPE mode [S51] | Requires a MIDI-capable AUv3 host for actual connections; standalone edits/tests/exports; no sound | Extremely cheap “build the missing MIDI tool” insurance; powerful logic, constrained visuals and coding requirement |
| **Rozeta Sequencer Suite** | $9.99. v1.3.16. [S53] | iPhone/iPad, iOS 11+; 2023-05-24 | Ten AUv3 MIDI tools; controller-relevant modules are double XY, triple LFO, scaler and Cells recorder | Configurable CC, pitch/mod sliders, tempo sync; host required; no standalone or MPE claim | AUv3 MIDI only, no sound | Good bundle of ready-made control/generation functions, not a custom surface |
| **Midiflow** | $7.99; Controller Remapping $3.99, Conditions $2.99, Send-on-load $1.99. v2.2.20. [S54] | iPhone/iPad, iOS 9+; 2024-05-08 | Routing and transformation UI, not a performance surface | Hardware/virtual/network/BLE CoreMIDI; custom ports; remaps channels, notes, velocity, CC, pressure, pitch, program; recallable presets [S55] | No sound/host | Important complement that repairs weak mappings; not a substitute for an expressive UI |
| **MidiFire** | $11.99. v2.1. [S56] | iPhone/iPad, iOS 8+; **2020-02-11** | Free-form canvas of MIDI ports and processing modules, not playable widgets | CoreMIDI, network, BLE, virtual ports; filter/remap/transpose/clock/monitor; Stream Byter logic; AUv3 MIDI FX host [S57] | Hosts MIDI effects only; no sound | Deep modular plumbing with significant update-age risk |
| **StreamByter** | Free. v1.10. [S58] | iPhone/iPad, iOS 14.5+; **2021-06-09** | Scriptable MIDI effect with optional linked GUI sliders | Standalone CoreMIDI virtual ports or AUv3; filters/remaps/clones/delays events; variables, loops, math | No sound; AUv3 MIDI processor | Expert transformation complement; not a complete controller surface |

## Evidence matrix C: focused controllers and screened sequencers

| Product | Price / update | Control-surface relevance | Key limits and status |
|---|---|---|---|
| **Ribn** | $3.99; v2.2, **2018-09-10** [S44] | Eight assignable CC ribbons record and loop finger gestures; independent channels, presets, wired/BLE/Wi-Fi output [S45] | CC only—no notes, AUv3, Audiobus, sound, or MPE. Elegant concept but very stale |
| **sqsl Strips** | $14.99; v1.2, 2025-08-05 [S46] | iPad-only 48 CC strips; per-strip gesture recorder, random walk and rate; 320 preset slots; progressive preset crossfade | Designed around VCV Rack; no background operation or sound; no AUv3/MPE claim |
| **midiLFOs** | $4.99; v3.1.1, **2020-04-22** [S48] | Four independent CC LFOs; shapes, cross-modulation, MIDI-clock/Ableton Link sync, BLE, AUv3 MIDI, host automation [S49] | Automatic modulation rather than a broad surface; no notes, MPE, OSC, or sound |
| **Xequence 2** | $19.99; v2.6.1, 2023-12-30 [S59] | MIDI workstation with configurable scale keyboard, pads, up to 150 control ribbons per instrument, tilt control, CC/aftertouch/pitch bend/(N)RPN [S60] | Controller is useful but subordinate to sequencing; no native sound/host and no explicit MPE |
| **Atom \| Piano Roll 2** | $19.99; v2.0.10, **2021-05-29** [S61] | AUv3 piano-roll clip system with external controller scripts and Launchpad integration | Receives/controllers clips rather than providing a general on-screen external-control surface; low substitutability |
| **Piano Motifs** | $5.99; AUv3 MIDI $3.99 and MIDI Out $1.99; v4.113, 2026-07-23 [S62] | Algorithmic MIDI motif generator; some live octave/velocity controls in AUv3 | Generator, not performance control surface; include only as an adjacent “drive another synth” option |

## Deep profile 1: TouchOSC

### Offer and product shape

TouchOSC is the clearest benchmark for a platform-independent custom controller. The $19.99 iOS purchase includes the same editor/runtime concept available on desktop and Android: a user can nest controls, attach any number of MIDI, OSC, or local messages, create local relationships without code, and use Lua when the layout needs state, math, timers, or custom interaction. Ten MIDI connections and ten OSC connections can be active, with OSC over UDP or TCP and MIDI over the device’s system, virtual, wired, Bluetooth, network, or Bridge ports. [S1][S2][S4][S5]

Its July 2026 release establishes that this is not a legacy-only threat. Apple and Hexler both report v1.5.2 on 2026-07-01. The release notes describe a substantially improved MIDI implementation and file/XML fixes, although they do not claim MPE. [S3]

### Strengths

- The broadest protocol and platform story in the direct set.
- An integrated editor on iPhone/iPad, with synchronized desktop editing and live preview when precision matters.
- Bidirectional messages, nested containers, local logic, Lua, scripting examples, game-controller support, and a mature community.
- A one-time mobile price with no currently listed IAP or subscription.
- Specialist validation: Create Digital Music calls it the default answer when someone wants a custom touch/mobile controller and highlights its reach, scripting, examples, and community. [S6]

### Weaknesses and opening

TouchOSC gives users primitives, not an instrument. A player must know the destination’s MIDI or OSC schema, decide how notes and controls should behave, build the surface, and debug ports and feedback. There is no documented global “touch the target, move a control” learn workflow inside TouchOSC; official getting-started material typically relies on the destination app’s MIDI learn. It has the MIDI 1.0 pieces from which an expert could construct multichannel expression, but no documented MPE mode, zone configuration, or voice allocator. It also has no documented internal synth, sampler, or AUv3 host.

**Interpretation:** TouchOSC is strongest when the job is “make my exact control panel.” ExpressionPad should win when the job is “let me play expressively now.” Trying to out-feature TouchOSC as a generic editor is strategically unattractive; showing a finished musical gesture model is much more defensible.

## Deep profile 2: MIDI Designer Pro X

### Current identity and economics

MIDI Designer Pro 2 is no longer a separate current listing. The original product ID became MIDI Designer Pro X in January 2024. It is free to install, with a surprisingly capable free tier: all control types, connections, full MIDI-message marketing coverage, relationships, community layouts, and unlimited controls remain usable. Premium mainly unlocks many pages/banks, popup panels, and richer styling. Current U.S. prices span $1.49/month for iPhone, $2.49/month for iPad, $2.99/month for iPhone+iPad, and $4.99/month across Mac/iPad/iPhone; visible annual equivalents are $14.99, $24.99, $29.99, and $49.99. Lifetime is $124.99. [S7][S8]

The current App Store build is 10.25.0 from 2026-07-15 and requires iOS/iPadOS 18.6. This unusually high current OS floor is both evidence of active development and a compatibility cost for users keeping older stage devices. [S7][S11]

### Strengths

- Deep MIDI-first coverage: 7-bit and 14-bit controls, notes, bank/program, channel pressure, pitch bend, NRPN, song/transport messages, and flexible SysEx.
- Strong hardware-synth orientation and a community library of more than 350 layouts.
- Supercontrols and subcontrols create control relationships, steppers, radio behavior, group presets, live transpose, and timed value changes without requiring a general scripting language.
- On-device editing, now improved by July 2026 lasso/multiselect operations.
- AUv3 MIDI Processor operation lets the controller layout and routing live inside an AUM, Loopy Pro, Cubasis, or Logic session.
- Older specialist reviews praised rapid setup and the fact that a user could build useful Kontakt and hardware-control surfaces entirely on iOS. [S12]

### Weaknesses and opening

The interface and concept are dense, attractive layouts take work, and free users are sharply constrained to one page/bank on iPhone or two on iPad. Incoming MIDI learn is useful but partial: official documentation says the user first selects a message type, and pitch, bank/program, SysEx interpretation, and value ranges are not automatically learned in the way a novice might expect. [S10]

The 2026 positioning contains an important unresolved promise. A developer press release promised OSC, but the current manual and July App Store listing still describe MIDI-only operation. No explicit MPE or MIDI 2.0 mode was found. The safest competitive statement is that MDPx is exceptionally deep at MIDI 1.x control, not that it currently supports OSC or MPE. [S7][S10][S66]

**Interpretation:** MDPx is the most serious competitor for users who want to replace a hardware programmer, create a synth-specific panel, or work heavily with SysEx/NRPN. ExpressionPad can differentiate on touch semantics, internal sound, elegance, and a much shorter path from launch to music.

## Deep profile 3: Lemur—current competitor and historical design ancestor

### Status correction

Calling Lemur “dead” is now wrong. Liine ended the old product and removed it from stores in 2022; MIDI Kinetics acquired it in 2023 and released a new, separately purchased iOS App Store product in January 2025. Existing Liine builds can coexist if still installed, but the new build is not a free restoration of the old purchase. [S14][S16]

The live U.S. listing offers a free shell, a $99.99 lifetime license, $12.99 monthly and $99.99 yearly subscription entries, and an $84.99 subscriber upgrade. This is the residue of a turbulent relaunch: MIDI Kinetics initially announced subscription-only access, then added a one-time license after strong negative feedback. The App Store description still says an active subscription is required, contradicting the visible lifetime IAP and later release notes. [S13][S17]

### What remains distinctive

Lemur is not simply a reskinnable fader bank. It combines:

- MIDI and OSC to eight targets;
- LemurLang scripting;
- reusable modules and variables;
- physics-driven controls and multiball behavior;
- Canvas for arbitrary vector widgets;
- images, animation, clocks, and sequencing objects;
- a desktop editor and Daemon;
- nearly full on-device editing on iPad.

The current user guide describes all MIDI messages, CoreMIDI, class-compliant interfaces, network MIDI through the Daemon, and bidirectional control. [S15] MusicRadar’s review of Lemur 5 praised the deep templates, physics, and sequencing while also identifying the learning curve and recommending a cable when timing matters. [S18]

### Lifecycle and competitive interpretation

The current build, 5.7.5, has not changed since 2025-03-19. That is not proof of abandonment, but it is material risk after a costly relaunch. Its headline “5.0” Canvas, Image, Sequencer, and in-app-editor features are historically important rather than brand-new 2025 inventions; they originated in the prior Liine era.

Lemur’s lasting legacy is the idea that glass should behave as a software-defined instrument rather than imitate a fixed hardware panel. It normalized multiple simultaneous touches, dynamic feedback, physics, song-specific interfaces, and custom MIDI/OSC logic. That makes it the closest conceptual ancestor to any expressive touch controller in this survey.

**Interpretation:** Lemur remains stronger than ExpressionPad at arbitrary interaction research and scripted OSC installations. ExpressionPad can be stronger as a coherent, approachable musical instrument with modern lifecycle trust and a price that does not require professional-template economics.

## Deep profile 4: Surface Builder

Surface Builder is a better direct match than several apps in the original seed list. At $14.99, it runs both standalone and as an AUv3 MIDI or instrument plug-in. Users drag buttons, switches, lights, knobs, faders, sliders, an XY pad, keyboards, labels, images, and boxes onto as many as six scenes. Incoming MIDI can update interface objects, and controls send notes, CC, program/bank changes, modulation, pitch bend, or recorded bulk MIDI. A button can also become an audio-clip player, with other controls assigned to its level, pan, or filter. [S19][S20]

### Strengths

- Lower conceptual barrier than Lua- or LemurLang-centered systems.
- AUv3 state saving plus standalone hardware control.
- Bidirectional MIDI and multiple scenes.
- Simple internal audio playback makes a layout useful without immediately adding a synth.
- Very current: v1.23 shipped 2026-07-10.

### Weaknesses and opening

Its MIDI vocabulary is conventional, native OSC is not advertised, the scene count is finite, and there is no documented MPE allocator or per-note multidimensional touch system. Audio clips are useful but do not equal a synth/sampler instrument with coherent expressive mapping. Its ecosystem and independent review footprint are also much smaller than TouchOSC or MDPx.

**Interpretation:** Surface Builder is the most important price-and-feature comparator for a paid iOS controller that wants AUv3 credibility. It demonstrates that $15 can buy active maintenance, a real editor, bidirectional MIDI, plug-in use, and simple audio.

## Deep profile 5: Loopy Pro

Loopy Pro is the most capable adjacent substitute because its control surface is embedded in a complete performance system. A project can have multiple canvas pages containing clips, one-shots, buttons, sliders, dials, encoders, XY pads, stepped/radio controls, labels, grids, and clip slicers. Widgets respond to presses, releases, toggles, value changes, double taps, long presses, two-finger gestures, and swipes; a single gesture can invoke several immediate or timed actions. [S29]

For external control, a widget can send note, CC, program change, pitch bend, 14-bit CC pairs, custom bytes, or SysEx to hardware, network MIDI, another app, or a hosted AUv3. Incoming MIDI learn and manually edited control profiles cover absolute and relative controls, action sequences, and state feedback. Loopy also receives OSC and can return state over TCP, but its current action vocabulary does not include arbitrary outbound OSC messages, so it is not a TouchOSC replacement for a general OSC panel. [S68]

MPE support is meaningful but asymmetric: MIDI clips record and play MPE, and audio clips can act as polyphonic MPE samplers. The manual does not describe Loopy’s widgets as a per-note MPE surface. [S29]

### Strengths

- The same canvas controls loops, audio, plugins, routing, scenes, MIDI, and external gear.
- Deep MIDI learn, profiles, feedback, enhanced support for common Launchpads/APC controllers, and rich action macros.
- Full AUv3 instrument/effect/MIDI hosting, mixer, buses, recording, sampling, sequencing, and arrangement.
- Loopy itself can run as an AUv3 MIDI processor “just as a MIDI controller.”
- Fair, intelligible economics: 7-day trial, $29.99 permanent unlock, one year of feature updates, lifetime fixes, and optional $14.99 later update years—not a subscription. [S27][S28]

### Weaknesses and opening

The user pays in configuration and conceptual weight. A dedicated controller surface lives inside a larger looper/DAW mental model, and hosting UI, audio, plugins, and MIDI on one device has CPU and failure-surface costs. Network MIDI is disabled by default because the manual warns of an iOS interference issue. AUv3 mode cannot itself nest other AUv3s. External feedback can require careful manual bindings.

WIRED characterized the app as a power-user wonderland and stable studio hub after deliberate tinkering, while noting that it ships with no sounds and takes acclimation. Its 2024 criticism of weak arrangement tools was partly superseded by Loopy 2.0’s 2025 MIDI clips, piano roll, sequencer, and automation. [S30]

**Interpretation:** Loopy Pro is the “control-room competitor.” ExpressionPad should be the instrument users route **into** Loopy, not a less capable imitation of Loopy’s whole rig.

## Deep profile 6: AUM

AUM is primarily a mixer, recorder, patch bay, and AUv3/IAA/Audiobus host. Users can construct arbitrary audio and MIDI channel-strip graphs, buses, sends, processing chains, and sessions, but cannot draw a page of free-form widgets. Its built-in play surface is a conventional keyboard with basic velocity/channel options. [S31][S32][S33]

Its incoming MIDI-control layer is excellent. AUM learns or manually maps CC, notes, program change, 14-bit pitch bend, and channel pressure to mixer volume, mute, solo, record, node bypass, transport, session loading, AU preset/window actions, built-in processing, and every writable parameter exposed by a plug-in. Control Finder identifies a parameter touched in a plug-in UI. Its MIDI matrix joins hardware, virtual endpoints, other apps, BLE/network sources, and hosted AUv3 MIDI generators, with channel, note-range, message, and CC filtering. [S33]

### Strengths

- Mature routing, hosting, recording, session recall, latency compensation, and hardware integration.
- One-time $20.99 purchase; current IAPs are optional tips rather than feature gates.
- Universal iPhone/iPad operation down to iOS 12.
- Natural destination for any external controller app.

### Weaknesses and opening

AUM does not replace the controller itself. It has no arbitrary widget canvas, native OSC, general CC-to-CC scripting, or documented MPE configuration. It can pass the constituent MIDI 1.0 events used by MPE, but AUM’s own learn layer is not a per-note expression system. Specialist coverage praises its stability, routing, sound quality, and live-rig role while identifying the lack of incoming external-MIDI-clock slave operation. [S34]

Community evidence also reports no universal pickup/takeover mode for reassigned hardware knobs, which can create parameter jumps after changing mappings or recalling state. This is practitioner evidence rather than an official specification. [S35]

**Interpretation:** AUM is more likely to be an ExpressionPad partner than a direct rival. AUv3 MIDI/instrument support, clean virtual MIDI, and documented AUM setup would materially improve ExpressionPad’s place in the ecosystem.

## Deep profile 7: LK

LK combines six paid modules inside a free shell:

- **Matrix** ($13): Ableton Session remote or standalone/AUv3 MIDI clip sequencer;
- **MIDI Controller** ($6.49): movable/resizable buttons, knobs, sliders, and pads with reusable JSON layouts;
- **X/Y Pad** ($6.49): four banks, three axes, Z envelope, LFO, CC or note operation;
- **MIDI Pads** ($6.49): 4×4 pads with positional velocity, chords, and arpeggiation;
- **Chorder** ($6.49): customizable chords, strumming, and arpeggiation;
- **Keyboard** ($6.49): three-axis expression and explicit MPE mode.

The all-modules bundle is $32.49, a material discount from the $45.45 individual total. Current listings show one-time IAPs, not a subscription. [S36][S37][S38]

LK sends MIDI to hardware or local apps, works as AUv3 MIDI, and uses the free UBRIDGE utility over USB or local network for deep Ableton Live integration. Matrix mirrors clips, scenes, mixer, track states and device parameters, while MIDI mode becomes an independent scene/clip sequencer. The current 1.15.11 build shipped 2026-07-17 after nine releases in roughly two months, making LK one of the most actively maintained apps surveyed.

### Strengths

- The only product in this T3 group that advertises both a customizable generic controller module and a native MPE keyboard.
- Broad ready-made musical vocabulary avoids forcing every user to build from an empty canvas.
- AUv3, virtual MIDI, hardware mappings, serious sequencing, and unusually deep Ableton integration.
- Modular pricing lets a user buy only the needed role.

### Weaknesses and opening

It still needs another sound source. Ableton operation requires UBRIDGE, a Live control-surface script, and desktop/network configuration. Matrix is visually and conceptually dense; older specialist review called the interface crowded, although this should be treated as historical rather than a verdict on the current build. Native OSC, SysEx, NRPN, 14-bit CC, Bluetooth behavior, and pickup/soft-takeover are not clearly documented.

**Interpretation:** LK is the closest modular-suite challenge to an expressive controller. It makes “MPE plus controller plus sequencing” available in one ecosystem, but it does not unify those capabilities with internal sound or a singular instrument identity.

## Deep profile 8: the 2026 low-cost builder wave

### MIDI Layout

MIDI Layout is an iPad-only, $1.99 drag-and-drop builder. It includes knobs, faders, buttons, pads, keyboard, and an unusually relevant Theremin control that can send continuous pitch bend or operate chromatically/in one of ten scales. Controls expose channel, CC, range, sensitivity, latch/momentary behavior, and velocity. A multiply tool clones rows with incrementing CC numbers; Perform Mode hides editing and provides a panic action; layouts import/export as files. [S21]

This is a credible direct substitute for users who want a cheap tailored panel or one continuous-pitch region. Its gaps are equally clear: no native OSC, MPE, BLE, AUv3, internal sound, or app-to-app virtual-MIDI workflow is documented. Independent coverage is enthusiastic but closely restates the listing, so hands-on confidence is limited. [S22]

### Jockey OSC & MIDI

Jockey’s $9.99 value proposition is broader Apple-platform integration. The grid builder has common controls plus stacks, trails, progress/indicator elements, and options/text fields. It saves through iCloud, broadcasts device motion, uses game controllers, and can send OSC/MIDI from Siri Shortcuts and Home/Control Center widgets. [S23][S24]

This makes Jockey relevant outside music—lighting, visual software, automation, and installation control—but it also means musical semantics are not its focus. No MPE, AUv3, sound engine, or deep MIDI learn is documented.

### Mult Controller

Mult is free and more experimental: a physics pad with momentum, RGB sampling from an image, gyro, AR position, compass, and microphone envelope can all become control streams. OSC uses UDP at selectable 30/60/120 Hz coalescing; MIDI uses Bluetooth or network CoreMIDI. Sessions are JSON files and multiple sessions can run with separate destinations. [S25]

These are differentiating sensors, but v1.0 has virtually no independent evidence. The listing also uses the phrase “CoreMIDI 2.0,” which should not be converted into a claim of MIDI 2.0/UMP support.
The only additional current discovery evidence found was a brief release mention in the specialist Loopy Pro community, not a hands-on review. [S26]

**Interpretation:** The cheap-builder wave commoditizes basic knobs, buttons, and XY pads. ExpressionPad’s paid value must come from the quality of playing, musical structure, expression, sound, and trust—not merely the existence of editable controls.

## Deep profile 9: Mozaic and programmable MIDI complements

Mozaic is a $1.99 AUv3 workshop for creating MIDI filters, generators, control panels, and unusual one-off tools. It supplies five fixed GUI layouts, an on-device editor, timers, LFOs, scales, random functions, tilt sensors, SysEx, host tempo/transport data, and sample-accurate MIDI scheduling. The standalone app edits, tests, and exports, but actual MIDI connections require a compatible AUv3 MIDI host. [S50][S51]

Create Digital Music accurately frames its appeal: users can build the missing MIDI gadget instead of waiting for a developer to add a niche feature. [S52] Its constraints are the other side of that design: users must script, the visual vocabulary is deliberately limited, there is no arbitrary OSC surface, and it makes no sound.

Midiflow, MidiFire, and StreamByter cover adjacent repair jobs:

- Midiflow provides friendly route graphs, virtual ports, presets, filtering, and paid transformations among notes, channels, CC, pressure, pitch bend, program changes, and values. [S54][S55]
- MidiFire provides a free-form module canvas, clock, monitoring, routing, AUv3 MIDI-effect hosting, and its own Stream Byter rules, but its iOS build has not changed since February 2020. [S56][S57]
- StreamByter is now free and can run standalone or as AUv3, transforming, cloning, delaying, filtering, and generating MIDI through rules and linked sliders; its last update was June 2021. [S58]

**Interpretation:** These utilities reduce the cost of a controller app’s missing edge cases for expert users, but they also expose a usability opportunity. A guided destination-profile and remapping layer inside ExpressionPad could satisfy common needs without asking users to assemble an AUM/Loopy + Mozaic/Midiflow stack.

## Deep profile 10: focused gesture and modulation surfaces

### Ribn

Ribn’s idea is still excellent: record a finger movement on one of up to eight ribbons and loop it as an organic MIDI CC modulation; turn looping off and the ribbon becomes a standard slider. Each strip gets a channel, CC number, label, and one of three preset configurations. [S44][S45]

The narrowness is deliberate—CC only, no note output, no MPE, no AUv3/Audiobus, and no sound—but the 2018 update date is a serious current-market liability. Early community reports about background behavior and freezes conflict with the later App Store description that background sending works, so reliability should not be asserted without testing.

### sqsl Strips

sqsl Strips is a modern, more expansive version of the “recordable strip” idea: 48 user-labeled CC strips, per-strip gesture recording, random walk, independent rates, 8×40 presets, and progressive manual crossfading between snapshots. It is iPad-only and explicitly says it does not work in the background or make sound. [S46][S47]

### midiLFOs and Rozeta

midiLFOs automates rather than records modulation. Four LFOs have conventional shapes, clock sync, offset, lag, min/max, output channel/CC, trigger options, and cross-modulation. It operates standalone or as AUv3 MIDI, responds to MIDI clock/Ableton Link, and exposes extensive host automation. [S48][S49]

Rozeta bundles triple LFO and double XY controllers with eight other AUv3 sequencer/generator tools. It is a better value for users already working in a host, but not an external standalone controller. [S53]

**Interpretation:** Focused apps win because their gesture is easy to explain in one sentence. ExpressionPad should preserve that legibility: a few memorable, musical expressive behaviors will merchandise better than a long undifferentiated feature list.

## Cross-cutting competitive findings

### 1. Generic layout construction is mature and newly inexpensive

TouchOSC, MDPx, and Lemur cover the expert end; Surface Builder is active at $14.99; MIDI Layout, Jockey, Mult, and OSC Controller create a 2026 low-cost wave. “Add knobs, pads, faders, and XY controls” is table stakes, not a strong differentiator.

### 2. MPE remains a real white space in generic builders

LK explicitly advertises MPE in its Keyboard module. Loopy records/routes MPE and turns samples into MPE-playable clips. AUM can pass MIDI events used by MPE. TouchOSC, MDPx, Lemur, Surface Builder, MIDI Layout, Jockey, and Mult do **not** document a turnkey combination of zone configuration, per-note channel assignment, and simultaneous pitch/timbre/pressure gesture semantics.

This does not mean those tools are incapable of sending multichannel pitch/pressure. It means the burden moves to the template author. That burden is exactly where an instrument-first controller can create value.

### 3. MIDI learn means different things in different products

- **Host-side learn:** AUM and Loopy excel at mapping incoming hardware/controller messages to app and plug-in actions.
- **Partial controller-side capture:** MDPx can learn several incoming message addresses but not the full semantics/ranges of every message type.
- **Manual builder mapping:** TouchOSC, Lemur, Surface Builder, MIDI Layout, Jockey, Mult, MidiPad, and Ribn generally expect the author to enter addresses/channels/CCs or use the destination’s learn feature.
- **Transformation:** Midiflow, Mozaic, StreamByter, and MidiFire solve message conversion after the fact.

An ExpressionPad mapping experience should state exactly which layer it handles and ideally provide both destination-side guidance and controller-side capture.

### 4. OSC is a meaningful separator, not a universal expectation

TouchOSC and Lemur have the strongest current OSC stories. Jockey, Mult, and OSC Controller also send OSC; Loopy exposes an OSC server/feedback but not arbitrary outbound OSC. MDPx promised OSC but does not yet document a shipped implementation. AUM, LK, Surface Builder, and the focused MIDI tools remain MIDI-centric.

OSC matters most for Max/Pd, SuperCollider, TouchDesigner, Resolume, lighting, theater, and custom installations. It expands addressable markets, but MIDI/AUv3 quality is likely more central for a music-first ExpressionPad launch.

### 5. Pure controllers rarely make sound

TouchOSC, MDPx, Lemur, MIDI Layout, Jockey, Mult, MidiPad, Knob Lab, Ribn, sqsl Strips, and midiLFOs all depend on another sound source. Surface Builder can trigger audio clips but is not a synthesizer. LK, Mozaic, Rozeta, Midiflow, MidiFire, and StreamByter also generate/process MIDI rather than audio.

Loopy and AUM host sound; neither includes a flagship playable synth. A controller that can make a satisfying sound immediately and then route the same gestures externally has a strong onboarding and demo advantage.

### 6. Update cadence sharply divides the field

Actively updated in 2026: TouchOSC, MDPx, Surface Builder, MIDI Layout, Jockey, Mult, LK, OSC Controller, and Piano Motifs. Strong 2025 activity: Loopy Pro, AUM, Mozaic, sqsl Strips. Aging or stale: Midiflow (2024), Xequence 2 and Rozeta (2023), Knob Lab and StreamByter/Atom (2021), midiLFOs and MidiFire (2020), Ribn (2018), MidiPad 2 (2017).

Continued availability makes old tools part of the choice set, but it should not be presented as evidence of current compatibility or developer responsiveness.

### 7. Pricing creates three anchors

- **Budget builders/utilities:** free to roughly $10.
- **Serious one-time tools:** Surface Builder $14.99, TouchOSC $19.99, AUM $20.99, Xequence $19.99, Loopy Pro $29.99.
- **Professional platform pricing:** Lemur $99.99 lifetime; MDPx $124.99 lifetime or platform subscriptions.

The market supports a premium when the product owns a professional workflow, community library, scripting ecosystem, or irreplaceable legacy. A new instrument/controller without those switching costs will need a clear experiential advantage to price above the $15–$30 cluster.

## Implications for ExpressionPad

The following are recommendations/inferences from the competitor evidence and should be cross-checked against the repository feature audit before appearing as factual product claims.

### Product

1. **Lead with the finished instrument, not the editor.** Default launch should produce an expressive, good-sounding result with no destination configuration.
2. **Make MPE a visible workflow, not a protocol checkbox.** Show per-touch pitch movement, timbre/CC74, pressure, voice allocation, bend-range negotiation/guidance, and an obvious MPE on/off state.
3. **Preserve conventional MIDI escape hatches.** Per-destination note/channel, pitch bend, channel pressure, CC, ranges, curves, polarity, return behavior, and panic should be editable without scripting.
4. **Add destination profiles before a blank canvas.** Curated AUM, Loopy Pro, common AUv3 synth, Ableton, Logic, and popular hardware mappings create more value than generic widgets. Profiles should explain what the target must enable.
5. **Treat reconnection and feedback as performance features.** Display the active output, transport/connection state, last message or diagnostics, and recover gracefully from device changes. Provide a layout/performance lock and an always-reachable panic.
6. **Consider AUv3 MIDI Processor or instrument operation.** MDPx, Surface Builder, LK, Loopy, Mozaic, Rozeta, and midiLFOs demonstrate the value of session-contained controller state. A first-class AUM/Loopy workflow would reduce app switching and improve project recall.
7. **Keep advanced automation musical.** A simple gesture looper, motion lane, or modulator could capture Ribn/sqsl/midiLFO appeal without turning the app into a general programming language.
8. **Do not chase full TouchOSC parity.** OSC, arbitrary scripting, dozens of widget types, and unlimited target routing are a different product strategy. Add them only if they reinforce the instrument.

### Positioning and merchandising

1. Use a contrast such as **“play first; map when you need to”** or **“an expressive instrument that also controls your rig.”**
2. Demonstrate one phone/tablet playing its own sound, then the same gesture controlling a synth in AUM/Loopy and external hardware.
3. Avoid the phrase “fully customizable MIDI controller” without qualification; TouchOSC, MDPx, Lemur, and Surface Builder set an extremely high expectation for that claim.
4. Make a short MPE compatibility guide and named list of tested destinations. Competitors frequently say “MPE” without helping users align bend range, channels, or destination settings.
5. Merchandise low setup, coherent layouts, expressive feedback, and stage safety. These are the recurring costs of blank-canvas systems.
6. A one-time price in the **$15–$30** zone is most legible relative to active competitors. A subscription would require a durable content/service rationale; Lemur’s relaunch shows the backlash risk.

### Ecosystem

1. Prioritize AUM and Loopy Pro as partners and tutorial targets rather than treating them only as competitors.
2. Export/import readable destination presets and make sharing easy. Community layouts are a major moat for TouchOSC and MDPx.
3. Publish exact support boundaries: CoreMIDI virtual ports, USB, BLE, Network MIDI, AUv3, background operation, OSC, MIDI clock, MPE, and MIDI 2.0 should never be left to inference.
4. Test older iPads used as dedicated controllers. MDPx’s iOS 18.6 floor creates an opening for broad, stable hardware support.

## Unknowns, contradictions, and verification needs

1. **Apple metadata caches:** Exa sometimes returned cached App Store excerpts one version behind Apple’s live lookup catalog. Exact version/update claims in the tables use the live catalog observed on 2026-07-25.
2. **Lemur pricing:** the current description says an active subscription is required, while IAPs and later release notes show a lifetime license. Report it as “lifetime or subscription options listed,” not subscription-only.
3. **MDPx OSC:** a developer press release promised OSC for early 2026; the current manual and July 2026 listing still omit it. Treat it as delayed/unverified. [S7][S10][S66]
4. **MPE absence:** no documented native MPE mode is not proof that TouchOSC/Lemur/MDPx scripts cannot approximate MPE messages. Compliance, zone setup, voice stealing, and bend-range behavior need hands-on tests.
5. **Surface Builder:** Apple reports v1.23 on 2026-07-10 while indexed App Store copy still surfaced older v1.16 notes. Current feature and reliability testing was not performed.
6. **New 2026 builders:** MIDI Layout, Jockey, Mult, and OSC Controller have little credible independent coverage. Developer claims about latency, CoreMIDI, sensors, session behavior, and bidirectional feedback need testing.
7. **Mult terminology:** “CoreMIDI 2.0” in the listing should not be treated as MIDI 2.0/UMP support.
8. **Loopy version:** the manual contains at least one “as of 2.0.6” reference while Apple lists 2.0.5. This likely reflects documentation ahead of the shipping storefront.
9. **Loopy outbound OSC:** the manual documents an OSC server and feedback but no Send OSC action; community evidence says arbitrary outbound OSC is absent. There is no explicit official “unsupported” sentence. [S68]
10. **AUM sample rate:** Apple copy says up to 192 kHz; Kymatica’s product page says 96 kHz and the manual says current hardware rate. This is not important to controller positioning and should not be normalized without testing.
11. **AUM MPE:** constituent MIDI messages can be routed, but no official MPE configuration or end-to-end compatibility claim was found.
12. **LK documentation drift:** current pricing/version differs from indexed older pages. The live listing controls. Official documentation also conflicts between four and eight Controller banks.
13. **Knob Lab IAP:** the current evidence proves a free single-knob trial layout but did not expose the full-unlock U.S. price.
14. **Ribn background behavior:** the listing says MIDI continues in background; early 2018 forum reports said it stopped. The later version may have fixed this, but current operation is untested.
15. **Stale listings:** MidiPad, Ribn, midiLFOs, MidiFire, StreamByter, and Atom remain purchasable despite five to nine years without updates. Compatibility and support cannot be inferred from availability.
16. **Ratings/reviews:** ratings were not used as comparable quality scores because counts, geography, version eras, and recency differ sharply.
17. **Connection reliability:** documentary support for BLE, RTP/network, Bridge/Daemon, USB, and virtual MIDI does not establish equal latency or stage reliability. Direct wired testing is still needed.

## Numbered sources

1. **[S1]** Apple — TouchOSC: https://apps.apple.com/us/app/touchosc/id1569996730
2. **[S2]** Hexler — TouchOSC product page: https://hexler.net/touchosc
3. **[S3]** Hexler — TouchOSC releases: https://hexler.net/touchosc/releases
4. **[S4]** Hexler — TouchOSC MIDI messages/manual: https://hexler.net/touchosc/manual/editor-messages-midi
5. **[S5]** Hexler — TouchOSC OSC connections: https://hexler.net/touchosc/manual/connections-osc
6. **[S6]** Create Digital Music — “TouchOSC … keeps getting better”: https://cdm.link/touchosc-keeps-getting-better/
7. **[S7]** Apple — MIDI Designer Pro X: https://apps.apple.com/us/app/midi-designer-pro-x/id492291712
8. **[S8]** MIDI Designer — Pro X overview and Premium comparison: https://mididesigner.com/home/mdpx/
9. **[S9]** MIDI Designer manual — connections: https://mididesigner.com/wiki/doku.php/manual:03_connections_redux
10. **[S10]** MIDI Designer manual — MIDI properties and learn: https://mididesigner.com/wiki/doku.php/manual:06_midi_properties
11. **[S11]** MIDI Designer — changelog: https://mididesigner.com/news/changelog/
12. **[S12]** Sound On Sound — MIDI Designer review: https://www.soundonsound.com/reviews/app-works-5
13. **[S13]** Apple — Lemur by MIDI Kinetics: https://apps.apple.com/us/app/lemur/id6739544164
14. **[S14]** MIDI Kinetics — Lemur rerelease statement: https://www.midikinetics.com/announcement/lemur-rerelease/
15. **[S15]** MIDI Kinetics — Lemur User Guide: https://support.midikinetics.com/wp-content/uploads/2024/10/Lemur-User-Guide.pdf
16. **[S16]** Create Digital Music — Lemur return/history: https://cdm.link/the-o-g-returns-lemur-controller-app-is-back-on-the-ipad/
17. **[S17]** Create Digital Music — Lemur drops subscription-only model: https://cdm.link/lemur-dumps-subscription/
18. **[S18]** MusicRadar — Liine Lemur 5 review: https://www.musicradar.com/reviews/guitars/liine-lemur-5-600258
19. **[S19]** Apple — Surface Builder: https://apps.apple.com/us/app/surface-builder/id6449735778
20. **[S20]** MWM — Surface Builder product summary: https://mwm.ai/apps/surface-builder/6449735778
21. **[S21]** Apple — MIDI Layout: https://apps.apple.com/us/app/midi-layout/id6760271807
22. **[S22]** iMusicNews — MIDI Layout overview: https://imusicnews.com/midi-layout-by-nathan-brand/
23. **[S23]** Apple — Jockey OSC & MIDI: https://apps.apple.com/us/app/jockey-osc-midi/id1553621603
24. **[S24]** Anton Heestand — Jockey OSC & MIDI: https://www.heestand.xyz/app/jockey-osc.html
25. **[S25]** Apple — Mult Controller: https://apps.apple.com/us/app/mult-controller/id6765664502
26. **[S26]** Loopy Pro Forum — 2026 iOS app discussion mentioning Mult: https://forum.loopypro.com/discussion/67133/2026-ios-app-sales-discussions/p120
27. **[S27]** Apple — Loopy Pro: https://apps.apple.com/us/app/loopy-pro-looper-daw-sampler/id1492670451
28. **[S28]** Loopy Pro — official pricing: https://loopypro.com/pricing/
29. **[S29]** Loopy Pro — user manual: https://loopypro.com/manual/
30. **[S30]** WIRED — Loopy Pro review: https://www.wired.com/story/loopy-pro-rave/
31. **[S31]** Apple — AUM: https://apps.apple.com/us/app/aum-audio-mixer/id1055636344
32. **[S32]** Kymatica — AUM product page: https://kymatica.com/apps/aum
33. **[S33]** Kymatica — AUM manual: https://kymatica.com/aum/help
34. **[S34]** Pianoo — AUM specialist review: https://pianoo.com/test/kymatica-aum/
35. **[S35]** Loopy Pro Forum — AUM pickup/takeover discussion: https://forum.loopypro.com/discussion/66142/aum-setting-midi-controller-pots-for-different-plugins
36. **[S36]** Apple — LK: https://apps.apple.com/us/app/lk-ableton-midi-controller/id944972221
37. **[S37]** Imaginando — LK product page: https://www.imaginando.pt/products/lk-ableton-live-and-midi-controller
38. **[S38]** Imaginando — LK user manual: https://help.imaginando.pt/en/article/lk-ableton-live-and-midi-controller-user-manual-gsnbq1/
39. **[S39]** Apple — MidiPad 2: https://apps.apple.com/us/app/midipad-2/id896879399
40. **[S40]** Codelle — MidiPad 2 product page: https://midipadapp.com/
41. **[S41]** Apple — MidiPad 2 U.S. reviews: https://apps.apple.com/us/app/midipad-2/id896879399?platform=iphone&see-all=reviews
42. **[S42]** Apple — Knob Lab: https://apps.apple.com/us/app/knob-lab/id727466234
43. **[S43]** Sonic Logic Apps — Knob Lab: https://www.soniclogicapps.com/knob-lab
44. **[S44]** Apple — Ribn: https://apps.apple.com/us/app/ribn/id1413777040
45. **[S45]** MusicRadar — Ribn overview: https://www.musicradar.com/news/ribn-for-ios-is-a-loopable-midi-controller-perfect-for-creative-modulation
46. **[S46]** Apple — sqsl Strips: https://apps.apple.com/us/app/sqsl-strips/id6746124079
47. **[S47]** Seqsual — sqsl Strips product listing: https://www.seqsual.com/other
48. **[S48]** Apple — midiLFOs: https://apps.apple.com/us/app/midilfos-midi-modulator/id998273841
49. **[S49]** Arthur Kerns — midiLFOs manual: http://artkerns.com/midiLFOs-manual-1.0.pdf
50. **[S50]** Apple — Mozaic Plugin Workshop: https://apps.apple.com/us/app/mozaic-plugin-workshop/id1457962653
51. **[S51]** Ruismaker — developer product catalog and Mozaic overview: https://ruismaker.com/
52. **[S52]** Create Digital Music — Mozaic review: https://cdm.link/mozaic-scriptable-midi-ipad-iphone/
53. **[S53]** Apple — Rozeta Sequencer Suite: https://apps.apple.com/us/app/rozeta-sequencer-suite/id1292546479
54. **[S54]** Apple — Midiflow: https://apps.apple.com/us/app/midiflow/id879915554
55. **[S55]** Midiflow — official documentation: https://www.midiflow.com/documentation/
56. **[S56]** Apple — MidiFire: https://apps.apple.com/us/app/midifire/id906600872
57. **[S57]** Audeonic — MidiFire manual: https://audeonic.com/midifire/manual/
58. **[S58]** Apple — StreamByter: https://apps.apple.com/us/app/streambyter/id1398712641
59. **[S59]** Apple — Xequence 2: https://apps.apple.com/us/app/xequence-2/id1464669442
60. **[S60]** seven.systems — Xequence 2 manual: https://www.seven.systems/xequence2/en/manual/
61. **[S61]** Apple — Atom \| Piano Roll 2: https://apps.apple.com/us/app/atom-piano-roll-2/id1536259776
62. **[S62]** Apple — Piano Motifs: https://apps.apple.com/us/app/piano-motifs/id1506065573
63. **[S63]** Apple — OSC Controller: https://apps.apple.com/us/app/osc-controller/id6756269807
64. **[S64]** Apple — Midi Controller – Remote & USB: https://apps.apple.com/us/app/midi-controller-remote-usb/id1470513354
65. **[S65]** SkyMage — OSC Controller product page: https://www.skymage.it/index.html
66. **[S66]** MIDI Designer — 2026 OSC/AUv3 press announcement: https://mididesigner.com/contact/press-kit/osc-and-auv3-support-for-midi-designer-pro-x/
67. **[S67]** MIDI Designer Q&A — pressure-sensitive controls: https://mididesigner.com/qa/5662/controls-responding-to-pressure-on-iphone-ipad?show=5674
68. **[S68]** Loopy Pro Forum — secondary-device controller and OSC/state-feedback discussion: https://forum.loopypro.com/discussion/66232/secondary-ios-device-as-synced-midi-controller
