# User Voice, Category History, and Unmet Needs in iOS Music Control Surfaces

**Research date:** 2026-07-25

**Scope:** User discourse, specialist reviews, category lineage, unmet needs, and reputational signals around expressive iOS instruments and MIDI/OSC control surfaces. This is a qualitative companion to the competitor feature matrices; it does not repeat current price or capability grids.

## Executive synthesis

The category’s strongest and most durable praise is not “it replaces a keyboard.” It is the opposite: the best-loved apps make a sheet of glass behave like a new instrument. Reviews of Bebot, Mugician, MorphWiz, ThumbJam, TC-11, GeoShred, and Lemur repeatedly celebrate continuous pitch, per-finger expression, scale-aware layouts, motion, simultaneous parameter control, and interfaces designed for touch rather than miniature hardware panels [S1][S8][S9][S10][S16][S19][S23]. Users describe the resulting experience in instrumental terms—something that rewards practice, changes phrasing, and produces ideas they would not reach on a piano keyboard. This is the category’s emotional center.

The corresponding failure mode is also consistent: an expressive surface can be delightful in isolation yet fail as part of a real rig. The recurring problems are latency and jitter, opaque MIDI/MPE routing, incomplete capture of expressive data, fragile state recall, standalone-versus-AUv3 friction, fiddly small-screen controls, absent tactile landmarks, weak documentation, and fear that a practiced instrument or carefully built template will disappear after an OS or App Store change [S3][S4][S21][S25][S26][S27][S28][S29][S30][S34][S35]. The cost of those failures rises with user investment. Losing a novelty app is disappointing; losing Lemur templates that coordinate a studio, or a surface on which a player has developed muscle memory, is closer to losing part of an instrument.

The market therefore does not simply divide into “simple” and “powerful.” It divides along two independent axes:

1. **How quickly the app yields a musically satisfying first result.**
2. **How safely the app supports long-term investment in technique, mappings, presets, and projects.**

ThumbJam is repeatedly praised because it scores well on both: scale locking and strong presets create immediate musicality, while customization, sample import, microtonal support, MIDI, and accessibility provide depth [S15][S16][S17][S18]. TC-11 and Lemur demonstrate the reputational upside and adoption tax of near-limitless programmability [S2][S3][S19][S21]. The original expressionPad demonstrates a different commercial hazard: a capable, differentiated instrument can remain obscure if its value and learning path are not made legible [S12]. Lemur’s 2022 withdrawal demonstrates the trust hazard: deep customization becomes a liability when ownership, migration, and reinstallation are uncertain. Its 2024–25 rerelease is a hopeful continuity story, but the separate app, required repurchase, and old-version update risk show how difficult trust is to restore [S4][S5][S30][S53][S55].

For ExpressionPad, the opportunity is to promise both **immediacy and permanence**: a playable result in under a minute; a surface worth practicing; transparent routing and MPE behavior; reliable session recall; and a credible continuity story for presets, projects, and OS transitions.

## Method and evidence standard

This review used Exa semantic discovery across official developer pages and release notes, Apple App Store pages, peer-reviewed NIME/ICMC papers, specialist music-technology reviews, the Audiobus/Loopy Pro forum, VI-Control, ModWiggler, Gearspace, AppleVis, accessibility-music organizations, and selected independent reviews. Sources span 2005–2026 so that contemporary expectations could be separated from early-platform constraints.

Evidence was weighted in this order:

- **Primary evidence:** developer documentation, release notes, source repositories, conference papers, and contemporaneous launch material. Strong for intent, chronology, and implementation; weak for independent evaluation.
- **Specialist reviews:** MusicRadar, Sound On Sound, Create Digital Music, Macworld, Synthtopia, AudioNewsRoom, and I Care If You Listen. Stronger for usability and historical reception, though often based on short review periods.
- **Community evidence:** Audiobus/Loopy Pro, VI-Control, ModWiggler, Gearspace, and App Store reviews. Strong for workflow failures and long-term use, but anecdotal and self-selecting.
- **Accessibility evidence:** AppleVis, Drake Music, and accessible-music practitioners. Treated as domain expertise, not a proxy for all disabled users.

A theme is called **repeated** when it appears in at least two independent sources, distinct communities, or materially separated time periods. A single report is labeled **anecdotal**. This is not a sentiment count: search ranking, surviving archives, and enthusiast communities all favor unusually engaged users. Short quotations are included only where the wording itself captures a recurrent attitude.

### Explicit anecdote labels

Several vivid reports are useful illustrations but should not be generalized:

- The claim that the original expressionPad was commercially wounded by price, learning curve, and weak promotion is **one contemporary developer’s interpretation**, not verified sales analysis [S12].
- The 2017 expressionPad phone-layout criticism is **one reviewer’s first impression**; it supports the broader small-screen pattern but does not establish how most users responded [S13].
- TC-Data failing to appear to some AUv3 destinations is **a single App Store review** and needs direct compatibility testing [S22].
- GeoShred’s reported two-second preset reload, ThumbJam’s mismatched expressive-MIDI playback, and LK’s changed routing are **specific user incidents** [S32][S37][S45]. They illustrate recurring recall/routing classes, not universal behavior.
- The 2025 discussion of iPad weight, stands, and lap stability is **a small self-selected thread** [S33]. It surfaces a real ergonomic question without measuring prevalence.
- The TC-11 paper’s quoted App Store/blog reactions are **an informal sample selected by the app’s author** [S19]. Its measured latency and documented design changes are stronger evidence than its review excerpts.

## Theme evidence table

| Theme | Evidence and recurrence | Confidence | What it means |
|---|---|---:|---|
| Touch-native expression is the category’s central delight | Bebot, Mugician, MorphWiz, ThumbJam, TC-11, GeoShred, and Lemur reviews independently praise interfaces that do not merely reproduce keys and knobs [S1][S8][S9][S10][S16][S19][S23]. Users value polyphonic slides, finger vibrato, continuous timbre, and several parameters moving together. | High | Sell a new performance vocabulary, not “a keyboard on an iPad.” |
| Responsiveness is part of sound quality | Mugician’s developer treated finger-to-ear delay above roughly 30 ms as instrument-breaking; TC-11’s paper measured about 40 ms while users still reported crisp response; later community reports show perceived latency varies by app, buffer, device, effects chain, and playing style [S10][S11][S19][S26]. | High that it matters; medium on universal thresholds | Publish reproducible measurements and tested configurations. “Low latency” without conditions is not persuasive. |
| Presets are onboarding infrastructure | ThumbJam, MorphWiz, TC-11, and GeoShred use presets/scales to give novices a satisfying first encounter, while retaining deeper editing [S9][S15][S16][S20][S23]. TC-11 users explicitly say presets help but do not fully solve the programming curve [S21]. | High | A preset should teach a gesture and a musical job, not only showcase a timbre. |
| Customization creates both devotion and abandonment | Lemur and TC-11 win extraordinary praise for depth, but independent reviews and forum threads repeatedly describe scripting, patch design, and routing as “pros only,” counter-intuitive, or easy to abandon [S2][S3][S19][S21]. ThumbJam’s gentler progressive disclosure is a positive counterexample [S16][S17]. | High | Progressive disclosure is a product requirement, not cosmetic onboarding. |
| Discoverability can defeat technical differentiation | The original expressionPad reportedly existed from June 2010 yet was almost unknown to another developer obsessively surveying the category; contemporary commentary blamed a modest learning curve, niche pricing, and no player-acquisition plan [S12]. TC-11’s community later created its own teaching thread because users could not find enough practical tutorials [S21]. | Medium-high | Search language, demonstrations, tutorials, and community examples are part of the product. |
| Glass lacks reliable tactile and pressure cues | Current users note that most iPads do not sense finger pressure directly; apps infer expression from Y position, touch radius, or motion, with contested results. Players must often watch the screen because there are no physical note boundaries [S25][S34]. A 2025 discussion adds mounting and device-weight problems when playing two-handed [S33]. | High on hardware constraint; medium on preferred workaround | Offer visible/audible landmarks, adjustable gesture curves, generous targets, and optional boundary feedback. Never imply true pressure sensing where it is inferred. |
| Small screens magnify every design compromise | Forum reports across instruments and hosts describe tiny text, hard-to-hit preset arrows, cropped AUv3 views, awkward portrait support, and controls that become “fiddly” on iPhone [S34][S36]. The 2017 expressionPad build was described as too small in iPhone portrait but much easier in landscape [S13]. | High | Treat phone, iPad mini, and hosted AUv3 sizes as distinct performance environments. |
| MIDI routing is powerful but cognitively expensive | Users routinely construct multi-app pipelines with ports, channel filters, converters, hosts, and desktop bridges. Failures include missing aftertouch, feedback loops, stale virtual ports, messages routed to the wrong instrument, and connections that differ between saved and current versions [S27][S37]. | High | Destination-first routing, a live message monitor, loop detection, and tested recipes can be differentiators. |
| “MPE support” is too ambiguous | Community discussion distinguishes generation, transport, recording, playback, note editing, and expressive-data editing. A 2026 thread concludes that full per-note expressive editing remains rare on iOS and warns that the phrase “full MPE support” deserves skepticism [S35]. A current controller discussion disputes velocity, touch-radius, CC74, and custom-scale behavior among otherwise capable apps [S25]. | High | Specify every supported message, direction, channel convention, bend range, host, and recording behavior. |
| AUv3 solved some workflows and exposed new ones | AUv3 enables host-managed state and routing, but users report plugin-state bugs, preset names not matching restored state, samples loading only after opening a UI, and hosted windows that are too small. Older IAA apps have separate or absent state-saving paths [S29][S36][S38]. TC-Data reviews complain that a standalone/IAA-era controller is invisible to some AUv3 apps [S22]. | High | Standalone and AUv3 should share presets and behavior; session state should be testable and visible. |
| Live users want snapshots, not just presets | Requests recur for one action that recalls a coordinated performance state across apps, mappings, effects, roots, scales, and routing. Users call manual combinations an “absolute creativity killer”; GeoShred performers report dropouts or cumbersome menus when changing scales mid-song [S28][S32]. | High | Add atomic scenes/setlists with safe transitions and clear changed-state indicators. |
| Microtonality is valued intensely but remains fragmented | Mugician was built around fretless and quarter-tone performance; ThumbJam and GeoShred are repeatedly recommended for Scala/custom tuning; community users report limited preset scales, coarse tuning resolution, inconsistent MIDI translation, and abandoned microtonal utilities [S10][S11][S15][S31]. | High within a niche; low confidence on market size | Microtonality is a credibility and inclusion feature. Import/export and predictable per-note MIDI behavior matter more than a long static scale list. |
| Accessibility benefits from the same “immediacy” features | Scale lock, large continuous surfaces, hidden menus, custom colors/backgrounds, one-finger play, and Guided Access have made ThumbJam useful in disability arts and special-needs education [S17][S18][S39]. AppleVis calls it fully VoiceOver accessible, though navigation could improve [S18]. | High for ThumbJam; medium for category-wide prevalence | Accessibility should cover performance, setup, saved configurations, and feedback—not only labels. |
| Reliability is remembered at version boundaries | Mugician reviews connect low latency and stability to particular releases, and its developer documented sound loss, skips, and OS-related regressions [S11]. TC-11 users reported host crashes after iOS updates [S20]. LK routing changed in an update and broke an old project until diagnosed as a bug [S37]. | High | Compatibility testing and migration notes are reputational assets. Preserve old projects and mappings. |
| Discontinued-app fear is a purchase and practice barrier | Lemur users considered buying spare iPads, freezing OS versions, and preserving old templates because no replacement matched their setups [S4][S5]. Similar discussions follow other removed music apps, with users saying app loss reduces willingness to spend “professional” money [S30][S40]. expressionPad itself was later reported removed [S14]. Lemur’s eventual rerelease reduced the availability risk but required a new purchase and did not make the legacy binary safe to update [S53]. | High | Trust requires exportable data, explicit support policy, migration tools, and advance end-of-life communication. |
| Developer presence strongly shapes reputation | ThumbJam’s responsive solo developer and long compatibility history are repeatedly praised [S16][S41]. TC-11’s developer publicly tested compatibility fixes [S42]. Lemur’s forum disappearance and long silence were interpreted as abandonment before its formal end [S4][S43]. | Medium-high | Visible maintenance and candid status updates are more persuasive than undated “professional” claims. |

## What users praise repeatedly

### 1. An instrument native to the device

Across eras, reviewers react most strongly when an app makes the touchscreen necessary rather than merely acceptable. Macworld’s 2009 Bebot review called it a new class of instrument hiding beneath a playful character [S8]. MorphWiz combined the Haken Continuum and Bebot lineages into an interface with independent pitch expression, visual feedback, and pitch rounding [S9]. Mugician rejected familiar fretted or keyboard metaphors in favor of a fast, practice-heavy surface [S10][S11]. TC-11 removed knobs, keys, and sliders from the performance view and generated control from relationships among touches and device motion [S19]. GeoShred later paired this continuous surface with physical modeling [S23].

The repeated praise has four parts:

- **Continuous gestures map to continuous sound.** Sliding, bending, rolling, tilting, and changing touch geometry feel causally connected to pitch and timbre.
- **Polyphonic independence matters.** Bending one note while holding another is repeatedly used to explain why these apps feel different from conventional MIDI.
- **Constraint can be enabling.** Scale locks and pitch rounding let beginners achieve coherence while experienced players retain bend, vibrato, or fretless control.
- **The surface changes musical thought.** Users report reaching phrases, soundscapes, and articulations they would not attempt on a hardware keyboard [S16][S44].

This explains why copying a desktop synth panel to iOS often draws criticism even if the sound engine is excellent. Users are not only buying portability; they are buying a different coupling between hand and sound.

### 2. Immediacy without a shallow ceiling

ThumbJam is the clearest reputational benchmark. An independent long-form review praises how quickly tilt, shake, scales, and high-quality sounds become musically legible, then praises the developer, custom instruments, MIDI, and community as deeper layers [S16]. Accessibility practitioners reach the same conclusion from a different use case: one finger, a stylus, or a reduced set of active screen areas can produce meaningful music immediately, while teachers can customize span, octave, sound, color, and imagery [S17][S39].

MorphWiz similarly used a large preset library and strong visual response to serve both casual play and professional demonstration [S9]. TC-11 shows the limit of presets alone: the included patches are inspiring, but many users could not infer how to build reliable new ones, so the community created informal lessons and blank starting patches [S21]. The lesson is not “make it simple.” It is:

> Make the first gesture obvious, the first result rewarding, and the path to authorship visible.

### 3. Flexibility that produces personal workflow

Lemur users remained fiercely loyal because its templates could become exact representations of an individual studio, live set, or software instrument [S1][S3][S4]. Physics, scripting, dynamic objects, OSC, and feedback meant that it could model behavior, not merely place generic widgets. TC-11 and TC-Data earned a similar reputation for turning touch relationships into user-programmed control streams [S19][S22].

This loyalty is materially different from liking many features. Once a user invests in mappings and muscle memory, the interface becomes personal infrastructure. That produces exceptional retention—but also exceptional switching costs, support expectations, and end-of-life harm.

### 4. Microtonal and culturally broader pitch systems

Mugician’s explicit mission was to make fretless and quarter-tone performance practical; its developer argued that an instrument should allow the performer to be out of tune rather than erase that expressive dimension [S10][S11]. ThumbJam became a later community favorite because it could import Scala tunings, map scale degrees to a playable surface, and combine microtonality with channel-per-touch/MPE behavior [S15][S31]. GeoShred offers a large tuning vocabulary and expressive pitch rounding, though users still ask for faster live scale switching [S25][S32].

The repeated unmet need is not “more exotic scale names.” It is a coherent workflow:

- discover or import a tuning;
- understand the layout;
- play it expressively;
- route it to another instrument without losing per-note pitch;
- save it with the performance setup;
- and recall it without a dropout.

### 5. Evidence of care

Long-lived niche apps accumulate trust through maintenance, direct support, and respect for old work. ThumbJam’s “still alive” compatibility update prompted unusually emotional community responses more than a decade after launch [S41]. TouchOSC explicitly kept Mk1 available while launching a rewritten successor, citing users who depended on old devices and workflows [S7]. These acts communicate a continuity contract.

Conversely, a vanished forum, an old App Store update date, or silence after OS breakage is interpreted as a leading indicator of abandonment even when the app still runs [S4][S43]. In this category, update cadence is not merely a feature signal. It is a proxy for whether practicing the instrument is safe.

## Recurring pain points and contradictions

### Latency: measurable, perceptual, and contextual

Mugician’s source notes are unusually explicit: its developer considered latency above roughly 30 ms unacceptable for serious playing and removed features or graphical overhead to protect responsiveness [S10][S11]. TC-11’s NIME paper reported measured response around 40 ms, yet users described it as crisp; the authors hypothesized that immediate capacitive activation affected perception [S19]. A later Audiobus/Loopy Pro discussion shows why there is no single reputation score: the same app can feel fine or unplayable depending on buffer size, device generation, hosted effects, external MIDI, and whether the player is performing pads or precise bass lines [S26].

The contradiction is real, not an error. Latency should be treated as a distribution and a workflow:

- finger-to-event;
- event-to-MIDI or event-to-audio;
- host and plugin buffering;
- output hardware;
- wireless transport;
- and jitter under load.

**Unmet need:** an in-app performance diagnostic that reports audio buffer, estimated path, active destinations, overloads, and whether transport is wired, Bluetooth, or Wi-Fi. Marketing should publish a test method, devices, buffer settings, and median/range rather than an adjective.

### Gesture discoverability: magical after learning, invisible before it

Touch-native interfaces often remove familiar controls precisely to unlock new interaction. That can make capability invisible. TC-11’s own research found that users had trouble understanding device-axis motion and that novice users wanted easier note/scale generation [S19]. Its forum thread describes an initial “what do I do?” moment severe enough that owners stopped using the app after trying presets [S21]. Mugician’s lock and symbolic controls similarly required documentation; the developer deliberately chose expressivity over ease [S11].

**Unmet need:** a performance-first teaching layer that demonstrates gestures in context—touch here, slide this far, add a second finger, then hear and see the result—without turning the app into a modal tutorial. Each preset should optionally expose a compact “why this responds” map.

### Customization versus immediacy

Lemur’s history makes the tradeoff stark. Reviews consistently praise limitless customization, then warn that programming is time-consuming, documentation is dry, and only committed users will build serious templates [S1][S2][S3]. The 2024 discussion comparing GeoShred and Velocity Keyboard makes the modern version of the same tradeoff: Velocity Keyboard is praised as quicker and more focused, while GeoShred is recognized as deeper, microtonal, and more feature-rich [S25].

The usual product response—choose either a simple app or a power-user app—is unnecessarily binary. ThumbJam shows a better pattern: a strong default instrument, scale-constrained immediate play, then optional layers for presets, sampling, MIDI, splits, and microtonality [S15][S16].

**Unmet need:** reusable “surface recipes” that can be auditioned like sounds, then forked safely. A recipe should include layout, gesture mapping, scale, MIDI/MPE behavior, and explanatory metadata. Editing should never destroy the last known-good live version.

### No tactile landmarks and unreliable pressure proxies

The iPad’s glass enables frictionless slides but removes key travel, edges, and force response. Community debate around MPE controllers repeatedly returns to this: without physical landmarks, players often have to watch the screen; without native finger pressure, apps infer dynamics from position, contact radius, or accelerometer data [S25][S34]. Preferences differ—some players value a continuous surface precisely because it has no frets—but the limitation becomes acute when playing and singing, holding the device, or using both hands [S33][S34].

**Unmet need:** multi-sensory orientation rather than a claim to simulate hardware:

- configurable high-contrast pitch and scale landmarks;
- large safe margins around destructive controls;
- optional audio ticks or subtle pitch-center cues;
- optional haptic boundary cues where supported;
- per-gesture calibration and curves;
- a no-look/live mode with locked controls;
- and support for physical overlays or external controllers without degrading the touch-native workflow.

### MIDI routing and MPE fragility

MPE increases expressive bandwidth by distributing notes and per-note control across channels. It also increases failure modes. Community examples include aftertouch dropped by a bridge, CC-to-pressure conversion, multiple virtual ports, channel filters, feedback loops, stuck or degraded notes, and recordings whose playback does not match the live performance [S27][S35][S45]. Users can spend more time proving where a message disappeared than performing.

The phrase “MPE support” hides at least seven separate questions:

1. Does the surface emit a separate channel per touch?
2. Which dimensions are sent—pitch bend, channel pressure, poly pressure, CC74, or something else?
3. Is pitch-bend range negotiated or merely assumed?
4. Can the destination receive those messages correctly?
5. Can the host route them without merging or filtering?
6. Can a recorder preserve and replay them sample-accurately?
7. Can the data be edited without destroying the relationship among note and expression streams?

As of a 2026 Loopy Pro discussion, accurate recording/playback exists, but full per-note expressive editing inside AUv3 workflows is still described as rare [S35]. This is community evidence rather than an exhaustive technical census, but it is a strong warning about user expectations.

**Unmet need:** an MPE setup assistant that can create a known-good route, show per-touch channel assignment, display bend range and expressive dimensions, flag feedback, and run a loopback test. Product copy should state exact behavior instead of “full MPE.”

### AUv3/standalone friction and state recall

AUv3 provides a host contract for plugin state, but users still encounter three different layers of recall:

- the plugin’s own named preset;
- the serialized state the plugin gives the host;
- and the host’s project/session routing and window state.

AUM users explain that a restored sound may be correct even when the preset name is blank or different; other threads document actual bugs where parameters or samples fail to restore until a UI is opened [S29][S38]. Older IAA apps may support Audiobus-specific state saving, no state saving, or different behavior in another host. TC-Data’s App Store feedback provides a controller-specific example: users report that some AUv3 destinations do not see an older standalone/IAA-era controller [S22].

**Unmet need:** a visible recall contract:

- show what will be saved by the app, by the host, and externally;
- share presets between standalone and AUv3;
- allow users to validate a session before a performance;
- preserve preset identity and mark modification;
- embed or explicitly reference imported samples/scales;
- and make state versioning backward compatible.

### Project and performance snapshots

Users want a higher-level object than an app preset. A performance scene may include root and scale, layout, active instrument, controller mapping, effect values, MIDI destinations, and external program changes. Current workarounds involve multiple host sessions, duplicate plugin instances, long action lists, or manually coordinated preset names [S28][S32].

GeoShred users describe a two-second reload as unacceptable inside a solo and a 250-scale menu as cumbersome mid-performance [S32][S46]. Host users want snapshot recall precisely to avoid naming and manually combining many plugin presets [S28].

**Unmet need:** atomic, fast, reversible scenes with:

- setlist order;
- footswitch or MIDI triggering;
- optional tail preservation/crossfade;
- preflight validation of assets and destinations;
- clear current/modified state;
- and export as a portable bundle.

### Accessibility is often partial or accidental

ThumbJam shows that touch instruments can be unusually inclusive. Scale constraints reduce wrong-note anxiety; the playable area can fill the screen; menus can be hidden; color and imagery can be changed; Guided Access can prevent accidental exits; and VoiceOver covers the interface, albeit imperfectly [S17][S18][S39]. These capabilities support children, blind and low-vision musicians, disabled performers, educators, and anyone who benefits from reduced motor or cognitive load.

But touch-native musical gestures also create accessibility traps. A control may be labeled yet still unusable during direct multi-touch. Visual-only XY position, unlabeled performance regions, tiny hosted controls, color-only pitch feedback, and no state feedback can exclude users [S18][S34].

**Unmet need:** accessibility as an end-to-end performance workflow:

- VoiceOver labels, values, and adjustable actions for every setup control;
- a documented Direct Touch mode for the playing surface;
- non-color pitch and selection cues;
- scalable type and controls;
- switch-control and external-MIDI alternatives;
- left/right-handed layouts;
- reduced-motion and high-contrast modes;
- and presets designed with accessibility practitioners, not only checked after release.

### App disappearance and the fear of practicing software

Lemur is the category’s cautionary case. After Liine announced its 2022 removal, users described studio systems with no adequate replacement, bought or considered spare iPads, froze OS versions, and worried that a device failure would take years of controller work with it [S4]. MIDI Kinetics acquired Lemur in 2023 but initially warned that it remained unavailable and could not be re-downloaded to a new device [S5]. As of the 2023 community follow-up used here, users were still preserving old hardware [S40].

MIDI Kinetics subsequently rereleased Lemur on iOS in late 2024/early 2025 [S53][S54][S56]. The return is meaningful evidence that stewardship or acquisition can rescue a practiced instrument. It did not simply erase the continuity problem: the new version installs alongside Liine’s app, existing users must repurchase, and MIDI Kinetics warns that an iOS update may remove the old binary [S53]. The initial subscription model also drew enough resistance that the developer announced a $99 one-time purchase instead [S55]. The episode shows both sides of continuity reputation: users will advocate for a valued instrument’s survival, but ownership, pricing, and migration decisions are judged against years of prior investment.

This fear is not confined to Lemur. Forum threads about Jasuto, Final Touch, and other vanished apps debate whether purchased apps can be reinstalled, backed up, or survive a device migration. One user explicitly connected this risk to refusing “professional” app prices [S30].

**Unmet need:** a continuity promise backed by product design:

- human-readable, versioned export for layouts and mappings;
- portable bundles for samples and scales;
- documented local backup and restore;
- migration tests across devices;
- advance notice of OS minimum changes;
- a public compatibility/status page;
- an end-of-life process that includes export, final compatibility, and ideally code or format stewardship;
- and no cloud requirement for core performance or recall.

## Historical lineage

### 2004–2008: multi-touch control before the App Store

- **2004/2005 — JazzMutant Lemur.** The original dedicated hardware made a user-defined multi-touch MIDI/OSC surface commercially real. It offered many simultaneous touch points, bidirectional feedback, physics, and pages of custom controls, but at a price above €2,000 and with a significant programming burden [S1][S47]. Its visual and interaction language—floating objects, dynamic surfaces, and bespoke studio templates—became a reference point for the category.
- **2008 — TouchOSC.** Hexler launched an inexpensive iOS tool for custom OSC control while Lemur was still hardware-only. Its long support life and 2021 rewrite made it the most durable mass-market descendant of the modular control-surface branch [S6][S7].

### 2009: the phone becomes a playable instrument

- **2009 — Bebot.** Bebot paired a friendly animated character with a four-voice continuous surface and a surprisingly deep synth. Its ability to delight a child immediately while rewarding expert exploration foreshadowed the “toy outside, instrument inside” pattern [S8][S48]. Jordan Rudess’ demonstrations helped make its performance vocabulary visible.
- **December 2009 — ThumbJam.** ThumbJam launched with sampled instruments, scale-aware play, motion control, looping, and a deliberate novice-to-professional span [S15][S49]. Its later MIDI, MPE, Scala, Audiobus, and accessibility work turned it into a long-lived bridge between self-contained instrument and controller [S17][S18][S41].

### 2010: the first iPad-native expressive surfaces

- **April 2010 — Mugician.** Rob Fielding’s Mugician prioritized low latency, fretless technique, microtonality, and a minimal full-surface layout. It framed the app as an instrument to practice, not a shortcut, and later exposed its source and design rationale [S10][S11].
- **June 2010 — original expressionPad.** Contemporaneous sources place expressionPad in the store by June 2010. It combined continuous multi-touch pitch, dynamics and modulation with internal sound and MIDI control. It was technically adjacent to what Mugician users requested, but remained obscure [S12][S50].
- **June 2010 — MorphWiz.** Jordan Rudess and Kevin Chartier fused ideas from the Haken Continuum and Bebot with pitch rounding, per-note expression, animated feedback, presets, and scalable layouts [S9]. The result was highly demonstrable and award-winning, showing the commercial power of pairing a new instrument concept with a visible virtuoso.

These apps were not a simple chain of copies. They were parallel answers to the same new affordance. Mugician emphasized latency, fretless discipline, and microtonality; expressionPad emphasized a more configurable controller/instrument; MorphWiz emphasized pitch intelligence, audio-visual spectacle, and approachable presets.

### 2011–2014: depth, programmability, and ecosystem integration

- **February 2011 — Mugician open-sourced.** Fielding preserved the instrument as a lineage and invited derivatives, while moving to other experiments [S10].
- **December 2011 — Lemur comes to iOS.** Liine relaunched the formerly expensive hardware concept as a $49.99 iOS app, dramatically lowering the price of a professional customizable controller [S51]. The same flexibility and learning burden persisted [S3].
- **December 2011 — TC-11.** Kevin Schlei’s TC-11 made relationships among touches and device motion programmable sources for a built-in synthesis engine [S19][S20]. It demonstrated both the expressive ceiling of a screen without virtual knobs and the discoverability cost of a deep relational model [S21].
- **2014 — TC-Data.** TC-Data extracted TC-11’s control research into a general MIDI/OSC controller, turning touch distances, speeds, angles, and motion into external messages [S22][S42]. This branch foregrounded the routing, bandwidth, and latency challenges that appear when a coherent internal instrument becomes a multi-app system.

### 2015–2018: MPE and physical modeling consolidate the instrument/controller hybrid

- **2015 — GeoShred.** GeoShred explicitly fused the Geo Synthesizer surface lineage with moForte physical modeling. It joined intelligent pitch behavior, configurable controls, and guitar-like articulation to a touch-native sound engine [S23].
- **2016 — ThumbJam adds formal MPE support.** ThumbJam’s “channel per touch” ideas predated the label, but the 2.5 update made the MPE relationship explicit and added contemporary synchronization features [S44].
- **2017 — expressionPad returns in a new free build.** A free AudioKit-based expressionPad appeared as a universal synth/sampler/CoreMIDI instrument. Early coverage praised its configurability but immediately noticed phone portrait ergonomics and the absence of then-current host integration language [S13][S14].
- **2018 — GeoShred family.** GeoShred separated Play, Control, and Pro, formalizing three audience layers: immediate preset performance, dedicated MIDI/MPE control, and full instrument editing [S24].

### 2021–2026: mature capability, workflow fragmentation, and continuity anxiety

- **2021 — next-generation TouchOSC.** Hexler rewrote TouchOSC with an integrated cross-platform editor and scripting, while promising to keep Mk1 alive for dependent workflows [S6][S7]. This is a strong continuity model: innovation without immediately stranding old setups.
- **2022 — Lemur end-of-life; ThumbJam compatibility maintenance.** Lemur’s removal exposed the fragility of deeply customized app-based studios [S4]. ThumbJam’s iOS 16 maintenance update produced the opposite signal: modest compatibility work can renew community trust [S15][S41].
- **2023 — Lemur acquisition without immediate return.** MIDI Kinetics’ acquisition preserved hope but also made the App Store dependency explicit: existing systems could keep working, yet a new device could not download the app [S5].
- **Late 2024/early 2025 — Lemur returns.** MIDI Kinetics rereleased Lemur as a separate iOS app that could coexist with the legacy Liine build [S53][S54][S56]. Existing users had to repurchase, and the developer warned that OS updates could remove the old version. After resistance to an initial subscription, MIDI Kinetics announced a $99 one-time purchase [S55].
- **2024–2026 — current descendants.** Lemur, GeoShred, Velocity Keyboard, ThumbJam, KB-1, TouchOSC, TC-Data, Touchscaper, Loopy Pro’s custom surfaces, and other specialist tools occupy pieces of the original vision. Community comparison now focuses less on whether expressive touch is possible and more on velocity inference, MPE semantics, scale depth, AUv3 hosting, live recall, and reliability [S25][S28][S35][S36][S54]. The category has matured technically but remains fragmented operationally.

## Unmet-needs analysis

### 1. A trustworthy “play now” path

**Observed gap:** Deep apps often open on an inspiring preset but fail to explain the gesture system or routing model. Blank customizable surfaces demand work before reward [S2][S21].

**Opportunity:**

- Launch into a verified audible instrument with one obvious gesture.
- Offer three to five role-based starts: lead, chordal, microtonal, drum/trigger, external MPE.
- Pair every starter with a 20–40 second interactive gesture lesson.
- Keep a persistent “return to known-good sound” action.

### 2. A transparent performance signal path

**Observed gap:** Users cannot easily tell whether failure is caused by the surface, MIDI channel allocation, a host route, bend-range mismatch, a filtered message, an audio buffer, or a feedback loop [S27][S35][S37].

**Opportunity:**

- Present destinations by app/device name and role, not only port identifiers.
- Show per-touch note/channel/expression in a compact live monitor.
- Detect feedback and unmatched note-on/note-off behavior.
- Add one-tap routing recipes for AUM, Audiobus, Loopy Pro, Logic Pro for iPad, and desktop USB/Bluetooth paths, clearly date-stamped.
- Export a diagnostic report users can attach to support.

### 3. Exact MPE claims and faithful capture

**Observed gap:** “MPE support” does not tell users whether a performance can survive routing, recording, editing, and playback [S25][S35][S45].

**Opportunity:**

- Publish an MPE conformance card: input/output, master/member channels, pitch range, pressure type, CC74, program change, and tested receivers.
- Record the raw expressive stream or provide an integration with a recorder that can.
- Add a playback verification mode that compares emitted and returned messages.
- Preserve high-density expression without silently thinning or quantizing it.

### 4. Scenes and session recall designed for performance

**Observed gap:** App presets do not capture the full musical state, and host state may not preserve preset identity, assets, or external devices [S28][S29][S32][S38].

**Opportunity:**

- Make a scene include layout, tuning, sound, expressive curves, MIDI destinations, controller values, and external program changes.
- Preload scene assets to avoid mid-song dropout.
- Support ordered setlists, next/previous control, and optional smooth transitions.
- Mark unsaved changes visibly and allow instant rollback.
- Run a “will this recall?” preflight before a show.

### 5. Progressive customization

**Observed gap:** Users either accept a generic surface or become interface programmers [S2][S3][S21].

**Opportunity:**

- Let users remix proven templates rather than begin blank.
- Separate musical intent (“more vibrato,” “wider bend,” “denser chords”) from raw MIDI mapping where possible.
- Expose expert editing without moving it onto the performance surface.
- Make templates portable, inspectable, and versioned.

### 6. Ergonomics for real bodies and all screen contexts

**Observed gap:** A layout that looks clean in a screenshot may be too small in an AUv3 window, unstable on a lap, or impossible to play while looking elsewhere [S33][S34][S36].

**Opportunity:**

- Design and test separately for phone portrait, phone landscape, iPad mini, full-size iPad, large iPad, Split View, Slide Over, and common AUv3 window sizes.
- Allow independent scaling of play cells, labels, and utility controls.
- Provide left/right-handed and one-handed layouts.
- Lock or hide non-performance controls.
- Offer high-contrast, reduced-motion, and no-look modes.

### 7. Microtonality as a complete pipeline

**Observed gap:** Scale libraries are large, but import, tuning precision, layout, MIDI translation, and live recall do not consistently connect [S31][S32].

**Opportunity:**

- Import/export Scala and document tuning precision.
- Preview a scale visually and aurally before loading it.
- Save tuning with the surface and scene.
- Make per-note pitch transport explicit and testable.
- Provide culturally informed presets with source/interval notes rather than presenting all non-12TET material as “exotic.”

### 8. Accessibility as expressive capability

**Observed gap:** Accessible setup does not guarantee an accessible playing surface, and a simple playing surface does not guarantee recoverable configuration [S17][S18][S39].

**Opportunity:**

- Co-design with blind, low-vision, motor-disabled, and neurodivergent musicians and educators.
- Treat scale constraints, target size, accidental-touch prevention, and multi-sensory feedback as core expressive controls.
- Publish accessibility documentation and known limitations.
- Include accessible factory scenes, not just VoiceOver labels.

### 9. A continuity contract

**Observed gap:** Practiced technique and custom projects can be stranded by an app removal, developer exit, OS update, or incompatible state schema [S4][S5][S30][S40].

**Opportunity:**

- Use open, documented formats for user-authored surfaces and mappings.
- Support local export/import without an account.
- Bundle dependent assets or report missing ones.
- Publish support windows and compatibility status.
- Give meaningful advance notice and migration tooling if the product is retired.
- Consider source escrow, format stewardship, or an explicit open-source end-of-life trigger for a deeply practiced instrument.

## Reputational signals to track

Stars and celebrity demos are weak proxies for durable trust. More diagnostic signals are:

1. **Does the developer preserve old work?** Backward-compatible state, migration notes, Mk1 support, and non-destructive updates signal respect [S7].
2. **Can users export their investment?** Layout, scale, preset, sample, and scene portability lower abandonment risk.
3. **Are compatibility updates visible and candid?** ThumbJam’s modest maintenance generated stronger trust than feature-heavy but silent products [S41].
4. **Does the developer participate where problems are diagnosed?** Direct, technically specific forum responses build reputation; long silence is interpreted as abandonment [S16][S43].
5. **Are claims testable?** Measured latency, explicit MPE messages, named host/device tests, and a public known-issues list are more credible than “professional,” “zero latency,” or “full MPE.”
6. **Does the app have a learning ecosystem?** Manuals matter, but users repeatedly ask for short practical videos, annotated presets, template libraries, and examples of complete rigs [S2][S21].
7. **Does the app survive device transitions?** A practiced instrument must be re-downloadable or locally restorable; otherwise update anxiety becomes part of the brand [S4][S30].
8. **Does the owner respond when the business model threatens trust?** MIDI Kinetics’ announced shift from subscription to a one-time Lemur purchase after user feedback is a positive response, though it does not remove repurchase and legacy-migration concerns [S53][S55].

Endorsements from Jordan Rudess, Daft Punk, Björk, and other prominent artists helped make the category legible and aspirational [S4][S9][S15][S51]. They remain useful demonstrations of expressive ceiling, but should be treated as marketing evidence, not independent proof of usability, reliability, or broad fit.

## Implications for ExpressionPad

1. **Position it as “an instrument you can enter immediately and grow into.”** The lineage rewards serious playability, but the category punishes unexplained difficulty. Pair an under-one-minute first success with a credible practice ceiling.
2. **Demonstrate gestures, not feature lists.** Show one finger controlling pitch and timbre, then two independent notes, then the same gesture driving an external instrument. Display the emitted data unobtrusively.
3. **Make latency a proof point.** Publish finger-to-audio and finger-to-MIDI measurements for representative devices, buffers, and routes. Include jitter and load conditions.
4. **Spell out MPE.** Replace “MPE compatible” with an exact input/output and host-compatibility card. Include bend range, pressure/CC74, member channels, and recording limitations.
5. **Make routing self-explanatory.** A musician should be able to choose “play this app,” “play this hardware,” or “send to my Mac” without understanding CoreMIDI topology first.
6. **Treat scenes and recall as a headline capability.** A controller setup is not saved until layout, scale, expression curves, destinations, presets, and assets come back together.
7. **Use presets as lessons.** Name surfaces by musical job and gesture—“Gliding lead,” “Two-hand chords,” “Quarter-tone fretless,” “External MPE strings”—and explain the response in one sentence.
8. **Protect live performance.** Provide a locked, full-screen mode, large scene controls, no accidental edits, preflight diagnostics, and predictable behavior after sleep or audio-route changes.
9. **Own the continuity story.** Export everything locally, document formats, preserve old state, publish compatibility status, and say what happens if development ever stops.
10. **Build accessibility into the instrument identity.** Large configurable zones, scale constraints, high contrast, VoiceOver setup, alternate control methods, and one-handed layouts expand expression rather than merely satisfy compliance.
11. **Treat microtonality as a workflow, not a checkbox.** Support precise import, intelligible layouts, per-note transport, scene recall, and culturally respectful starter material.
12. **Market maintenance.** Compatibility work, migration tests, and responsive support are launch content in this category. They answer the fear created by Lemur and vanished predecessors.

## Contradictions, biases, and open questions

- **Enthusiast bias:** Audiobus/Loopy Pro, ModWiggler, Gearspace, and VI-Control overrepresent technically committed users. Their routing and recall pain is highly relevant to professional adoption, but not a measure of mainstream incidence.
- **Survivorship bias:** The apps with enduring communities are easier to research. Failed products leave fewer searchable discussions, so the brief may understate ordinary indifference and overstate passionate love/hate.
- **Developer-curated reviews:** Mugician’s archived review collection is unusually useful but is hosted by its developer. It acknowledges mixed unwritten ratings, yet the sample is not neutral [S52].
- **Review-period bias:** Specialist reviews often capture launch novelty and may miss long-term workflow problems. Later forum evidence was used to balance them.
- **Latency contradiction:** TC-11’s measured ~40 ms and user reports of crisp response show that a numeric threshold is not universal [S19]. Technique, transient shape, device, and path matter.
- **Tactility preference:** Some users see a fretless glass surface as liberating; others consider the need to look at it disqualifying [S34]. There is no single correct hardware emulation.
- **Customization preference:** One user’s “creative freedom” is another’s “time not making music.” Segment by authoring appetite rather than treating depth as universally better.
- **MPE evidence boundary:** Community reports strongly show confusion and workflow gaps, but this study did not bench-test every controller/host/DAW combination. Feature-specific claims require direct verification.
- **Accessibility boundary:** ThumbJam is a strong positive case, but evidence for many competitors is sparse. Absence of discussion is not proof of inaccessibility; hands-on testing with assistive technologies is still required.
- **Current availability:** Historical App Store pages and community links can persist after removal or vary by region. Availability belongs in the separately verified competitor matrix, not this qualitative brief.
- **Lemur status nuance:** Lemur’s 2022 removal and 2023 unavailability remain essential to the abandonment-risk evidence, but the app is no longer absent from iOS. MIDI Kinetics rereleased it as a separate product; this brief does not treat the legacy and current binaries as interchangeable [S53][S54].
- **Open question:** Would users pay a higher one-time price or maintenance plan for an explicit longevity/compatibility guarantee? Forum discourse suggests the fear is real, but not the preferred business model.
- **Open question:** Which feedback substitute—visual, audio, haptic, physical overlay, or wearable—best reduces no-look errors without disturbing continuous pitch? The community disagrees, so prototype testing is preferable to assumption.

## Sources

1. **[S1]** Sound On Sound, “Jazzmutant Lemur” — https://www.soundonsound.com/reviews/jazzmutant-lemur
2. **[S2]** MusicRadar, “JazzMutant Lemur OS 2.0 review” (2009) — https://www.musicradar.com/reviews/tech/jazzmutant-lemur-os-2-0-199805
3. **[S3]** MusicRadar, “Liine Lemur 5 review” (2014) — https://www.musicradar.com/reviews/guitars/liine-lemur-5-600258
4. **[S4]** VI-Control, “Lemur EOL, removal from app stores in September” (2022) — https://vi-control.net/community/threads/lemur-eol-removal-from-app-stores-in-september.128129/
5. **[S5]** Create Digital Music, “Lemur lives: iOS/Android app acquired by MIDI Kinetics” (2023) — https://cdm.link/lemur-lives/
6. **[S6]** Create Digital Music, “TouchOSC next-generation is here” (2021) — https://cdm.link/touchosc-next-generation-is-here-and-its-an-awesome-touch-controller-for-everything/
7. **[S7]** Hexler, “TouchOSC: The Next Generation” — https://hexler.net/news/post/touchosc-the-next-generation
8. **[S8]** Macworld, “BeBot—Robot Synth for iPhone” (2009) — https://www.macworld.com/article/196850/bebot.html
9. **[S9]** Wizdom Music, “MorphWiz” — https://www.wizdommusic.com/apps/morphwiz/
10. **[S10]** Rob Fielding, Mugician source repository and design notes — https://github.com/rfielding/Mugician
11. **[S11]** Rob Fielding, “The Mugician Manual – Deciphering the Hieroglyphics” — http://rrr00bb.blogspot.com/2010/08/mugician-heiroglyphics.html
12. **[S12]** Synthtopia, “ExpressionPad For The iPad – ‘An Alternate Path Down Reality’” (2011) — https://www.synthtopia.com/content/2011/01/26/expressionpadvid-m4v/
13. **[S13]** Create Digital Music, “expressionPad is a new free Synth/Sampler instrument” (2017) — https://cdm.link/newswires/expressionpad-new-free-synthsampler-instrument-better-expected/
14. **[S14]** Loopy Pro Forum, expressionPad release/removal discussion — https://forum.loopypro.com/discussion/21891/xpressionpad-synth-sampler-coremidi-instrument-ios-universal-music-free
15. **[S15]** Apple App Store, ThumbJam — https://apps.apple.com/us/app/thumbjam/id338977566
16. **[S16]** Pocket Musician, “ThumbJam review” (2011) — https://pocketmusician.wordpress.com/2011/07/24/thumbjam-review/
17. **[S17]** Drake Music, “Customising ThumbJam for accessible music” — https://www.drakemusic.org/blog/charles-matthews/customising-thumbjam/
18. **[S18]** AppleVis, “ThumbJam” accessibility entry — https://www.applevis.com/apps/ios/music/thumbjam
19. **[S19]** Kevin Schlei, “TC-11: A Programmable Multi-Touch Synthesizer for the iPad,” NIME 2012 — https://www.nime.org/proceedings/2012/nime2012_230.pdf
20. **[S20]** I Care If You Listen, “App Review: TC-11 Multi-Touch Synthesizer” (2014) — https://icareifyoulisten.com/2014/03/app-review-tc-11-multi-touch-synthesizer/
21. **[S21]** Loopy Pro Forum, “TC-11 (Totally Complicated) Discussion” (2014) — https://forum.loopypro.com/discussion/4304/tc-11-totally-complicated-discussion-swap-tips-to-help-us-all-use-an-amazing-app
22. **[S22]** Apple App Store, TC-Data — https://apps.apple.com/us/app/tc-data/id883788579
23. **[S23]** Jordan Rudess, “Introducing GeoShred!” (2015) — https://www.jordanrudess.com/introducing-geoshred/
24. **[S24]** AudioNewsRoom, “GeoShred Pro Review – iOS MPE Controller and Synth” (2018) — https://audionewsroom.net/2018/03/geoshred-pro-review-ios-mpe-controller-and-synth.html
25. **[S25]** Loopy Pro Forum, “Good MPE controller for iPad?” (2024) — https://forum.loopypro.com/discussion/60075/good-mpe-controller-for-ipad
26. **[S26]** Loopy Pro Forum, “Latency in synth apps – best/worst performers?” (2015) — https://forum.loopypro.com/discussion/8514/latency-in-synth-apps-best-worst-performers
27. **[S27]** Loopy Pro Forum, “How to route MPE MIDI from the iPad to PC” (2020) — https://forum.loopypro.com/discussion/39663/how-to-route-mpe-midi-from-the-ipad-to-pc
28. **[S28]** Loopy Pro Forum, “Let’s talk about snapshots in AU hosts” (2019) — https://forum.loopypro.com/discussion/34311/lets-talk-about-snapshots-in-au-hosts
29. **[S29]** Loopy Pro Forum, “App or Plugin Presets Not Being Saved with the AUM Session?” (2021) — https://forum.loopypro.com/discussion/48248/app-or-plugin-presets-not-being-saved-with-the-aum-session
30. **[S30]** Loopy Pro Forum, “Jasuto bites the dust” (2020) — https://forum.loopypro.com/discussion/40014/jasuto-bites-the-dust
31. **[S31]** Loopy Pro Forum, “Apps that support microtonal tunings” (2017) — https://forum.loopypro.com/discussion/22367/apps-that-support-microtonal-tunings
32. **[S32]** Loopy Pro Forum, “GeoShred real-time control of scales for live performance?” (2021) — https://forum.loopypro.com/discussion/46061/geoshred-real-time-control-of-scales-for-live-performance
33. **[S33]** Loopy Pro Forum, “How do you like to physically play your touch instruments?” (2025) — https://forum.loopypro.com/discussion/65143/how-do-you-like-to-physically-play-your-touch-instruments-what-s-your-setup
34. **[S34]** Loopy Pro Forum, “Virtual Keyboards with velocity/pressure & aftertouch” (2025) — https://forum.loopypro.com/discussion/63894/virtual-keyboards-with-velocity-pressure-aftertouch
35. **[S35]** Loopy Pro Forum, “Which editable AUv3 MIDI piano-roll sequencers support MPE?” (2026) — https://forum.loopypro.com/discussion/67916/which-of-the-editable-edit-auv3-midi-piano-roll-sequencers-are-mpe-supporting
36. **[S36]** Loopy Pro Forum, “SynthMaster 3 Player iOS” UI/host-size discussion (2025) — https://forum.loopypro.com/discussion/64133/synthmaster-3-player-ios-v1-0-5-on-appstore-with-all-iaps-20-off-intro-sale
37. **[S37]** Loopy Pro Forum, “Issues with MIDI Routing – LK in AUM” (2025) — https://forum.loopypro.com/discussion/65013/issues-with-midi-routing-lk-in-aum
38. **[S38]** Loopy Pro Forum, “Koala AUv3 state saving – samples not loading until app opened?” (2024) — https://forum.loopypro.com/discussion/60088/koala-auv3-state-saving-samples-not-loading-until-app-opened
39. **[S39]** WonderBaby, “ThumbJam Music App Review” (2012) — https://www.wonderbaby.org/articles/thumbjam-app-review
40. **[S40]** Loopy Pro Forum, “Will Lemur ever come back?” (2023) — https://forum.loopypro.com/discussion/58420/will-lemur-ever-come-back
41. **[S41]** Loopy Pro Forum, “ThumbJam ‘Still Alive’ Update” (2021) — https://forum.loopypro.com/discussion/47504/thumbjam-still-alive-update
42. **[S42]** Loopy Pro Forum, “TC-11?” developer beta/support discussion (2018–2019) — https://forum.loopypro.com/discussion/26837/tc-11
43. **[S43]** Loopy Pro Forum, “Lemur and forum.liine.net” (2018) — https://forum.loopypro.com/discussion/26053/lemur-and-forum-liine-net
44. **[S44]** Synthtopia, “ThumbJam Updated With Ableton Link, MPE Support & More” (2016) — https://www.synthtopia.com/content/2016/06/09/thumbjam-ableton-link-mpe-support/
45. **[S45]** Loopy Pro Forum, “ThumbJam MIDI output in pitch bending or glide mode records wonky” (2026) — https://forum.loopypro.com/discussion/68319/thumbjam-midi-output-in-pitch-bending-or-glide-mode-records-wonky
46. **[S46]** Loopy Pro Forum, “GeoShred – switch scales & layout without reloading preset” (2025) — https://forum.loopypro.com/discussion/66153/geoshred-switch-scales-layout-without-reloading-preset-instrument
47. **[S47]** MusicRadar, “JazzMutant Lemur review” (2007) — https://www.musicradar.com/reviews/tech/jazzmutant-lemur-21975
48. **[S48]** Synthtopia, “Bebot Robot Synth for iPhone and iPod Touch” (2009) — https://www.synthtopia.com/content/2009/02/13/bebot-robot-synth-for-iphone-and-ipod-touch/
49. **[S49]** Apple App Store (Canada), ThumbJam launch record — https://apps.apple.com/ca/app/thumbjam/id338977566
50. **[S50]** Rob Fielding, “expressionpad – an alternate path down reality” (2011) — http://rrr00bb.blogspot.com/2011/01/expressionpad.html
51. **[S51]** MusicRadar, “Lemur controller comes to iPad” (2011) — https://www.musicradar.com/news/tech/lemur-controller-comes-to-ipad-518456
52. **[S52]** Rob Fielding, “Every Commentary for 1.7.5 worldwide” — http://rrr00bb.blogspot.com/2010/12/every-commentary-for-175-worldwide.html
53. **[S53]** MIDI Kinetics, “Lemur Rerelease” (2024) — https://www.midikinetics.com/announcement/lemur-rerelease/
54. **[S54]** Apple App Store, Lemur by MIDI Kinetics — https://apps.apple.com/gb/app/lemur/id6739544164
55. **[S55]** Create Digital Music, “Re-released Lemur app is now a one-time purchase, not subscription” (2025) — https://cdm.link/lemur-dumps-subscription/
56. **[S56]** Create Digital Music, “The O.G. returns: Lemur controller app is back on the iPad” (2025) — https://cdm.link/the-o-g-returns-lemur-controller-app-is-back-on-the-ipad/
