# iOS Music-Control Surfaces: App Store Merchandising and Commercial Patterns

**US storefront snapshot:** 2026-07-25  
**Scope:** 27 currently downloadable iOS/iPadOS apps spanning dedicated MIDI/MPE control surfaces, touch-native instruments, and host/workstation substitutes. Two separate lite/trial products are discussed but not counted in the 27-app calculations.

## Executive findings

The commercial center of gravity is still a paid, one-time purchase—not subscription software. In this purposive sample, 19 of 27 apps have an upfront price and the median among those paid apps is **$17.99**. The more directly substitutable controller/playable-surface segment is cheaper: its ten paid apps have a **$12.49 median**. Eight apps are free to download, but six of those eight are gateways to an unlock, modules, or a subscription. Only AudioKit Synth One and GarageBand are fully free with no visible IAP. Explicit subscriptions appear in just two listings, MIDI Designer Pro X and Logic Pro/Apple Creator Studio. Loopy Pro makes “no subscription” part of its merchandising and uses a seven-day trial, a $29.99 permanent unlock, and optional $14.99 feature-update years instead. [S10][S20][S25][S29][S30][S33]

The category’s store language divides cleanly by job. Direct-control apps name the technical object: “Expressive MIDI Controllers,” “MPE MIDI Controller Audio Unit,” “MPE & Polyphonic AT Controller,” “Modular control surface,” and “Custom MIDI Controller.” Workstations sell a desired outcome: “Make Music,” “Live looping. Your way.,” “A place to start musical ideas,” and “Make great music anywhere.” In the descriptions, **MIDI** appears in 24 of 27, **controller** in 18, **expressive** in 15, **touch/Multi-Touch** in 16, and **create/creation** in 22. Among the 13 direct-control/playable-surface apps, every description says MIDI, 12 say controller, nine say expressive, eight say MPE, and seven say customizable/customisable. These are app-level presence counts, not raw word counts.

Store media is often functional rather than cinematic. Every sampled app provides iPad media; the median is six media slots, with a range of three to ten. Nine of 27 offer at least one preview video on some storefront device, but eight put video only in the iPhone set; Samplr is the sole sample app with an iPad preview video. A manual review of the first four available static frames found a coherent benefit-headline campaign in 14 of 27. The rest largely show raw interface screens, sometimes with a single hero/brand frame. This creates a conspicuous opportunity for ExpressionPad: a short iPad preview can communicate touch, motion, pressure, pitch, and timbral response more directly than screenshots can.

Privacy and support are unusually strong hygiene signals in this niche. Fifteen listings say “Data Not Collected”; another four say data is not linked to the user. Only four—the three large ecosystem apps KORG Gadget, Logic Pro, and Ableton Note, plus GarageBand—declare data linked to the user. All 27 expose a developer-website/support link and 25 expose a privacy-policy link. The direct-control subset has **zero** listings declaring linked data. “Data Not Collected,” a credible support destination, and a current version date therefore read as category-table-stakes trust markers, not optional legal footer material.

## Method and evidence rules

1. Exa was used to discover official US App Store listings and developer pricing/support pages. Prices from search snippets were **not** accepted as current evidence.
2. Each app was then fetched from Apple’s US storefront. Base price, current version, release date, minimum OS, rating average, and rating count were normalized through Apple’s lookup endpoint; subtitle, platform scope, IAP rows, privacy labels, support/privacy links, screenshots, and preview-video markers were read from Apple’s rendered product-page data. [S1–S28]
3. “Visible IAP” means a product row Apple exposed on the US web listing on 2026-07-25. Apple usually shows at most ten IAP rows, and the order does not guarantee that the items are the developer’s main offers.
4. Ratings are US-storefront values at retrieval time and will move. “Review count” below uses Apple’s `userRatingCount`/“Ratings” value; it is not a count of written reviews.
5. Device scope uses Apple’s current storefront platform declaration. All 27 are in Apple’s **Music** category. An Apple-silicon compatibility badge is not treated as a native Mac edition unless the storefront declares Mac in the app platform set.
6. For description vocabulary, an app counts at most once per term; matching was case-insensitive. “Expressive” includes inflections of expression; “touch” includes touch, multitouch, and Multi-Touch; “customizable” includes US and UK spelling.
7. Media counts distinguish static screenshots (`s`) and preview videos (`v`). “Benefit-headline campaign” is a manual merchandising classification: multiple opening static frames use short capability/outcome headlines, rather than being uncaptioned UI captures.

This primary-source pass caught why search snippets cannot be used for pricing. During discovery, indexed snippets showed an older $16 GeoShred Control upgrade and older LK module prices. Apple’s live US page on 2026-07-25 instead showed a **$24.99** GeoShred Control upgrade, **$13.00** LK Matrix unlock, **$6.49** individual LK modules, and a **$32.49** LK bundle. Those live Apple values are used below. [S1][S12][S28][S32]

## The 27-app dated sample

All rows are Apple US storefront data as of 2026-07-25. “No visible IAP” is narrower than “the developer can never sell content”; it means Apple exposed no IAP row in this snapshot.

### Direct controller and playable-surface apps

| App — current subtitle | US base price and commercial model | US rating | Current version · last update | Device scope / OS floor | Store media | Privacy marker |
|---|---|---:|---|---|---|---|
| **GeoShred Control** — Music [S1] | **Free**; Pro-functionality unlock $24.99; instrument IAP commonly $14.99; visible collection bundles to $119.99 | 4.37 (120) | 7000.327.1.436 · 2026-06-15 | iPhone/iPad; iOS/iPadOS 15.0+ | ph 3s; pad 3s | Data Not Collected |
| **GeoShred** — GeoShred Musical Instrument [S2] | **$24.99 upfront**; individual modeled instruments $14.99; visible collections $59.99–$119.99 | 4.83 (1,395) | 7000.327.1.436 · 2026-06-15 | iPhone/iPad; 15.0+ | ph 4s; pad 4s | Data Not Collected |
| **KB-1 Keyboard Suite** — Expressive MIDI Controllers [S3] | **$14.99 upfront**; no visible IAP | 4.77 (270) | 1.3.7 · 2025-10-14 | iPhone/iPad; 11.0+ | ph 4s; pad 5s | Data Not Collected |
| **ChordPolyPad** — MIDI Chords Player [S4] | **$17.99 upfront**; three visible preset/content packs at $4.99 each | 4.62 (50) | 3.0.1 · 2026-03-16 | Mac/iPhone/iPad; 15.0+ | ph 3s; pad 3s; mac 4s | Data Not Collected |
| **Velocity Keyboard** — MPE MIDI Controller Audio Unit [S5] | **$9.99 upfront**; no visible IAP | 4.76 (100) | 1.3.22 · 2025-09-24 | iPhone/iPad; 11.0+ | ph 5s; pad 7s | Data Not Collected |
| **Ribbons : Touch Instrument** — Expressive Synth & MIDI Keys [S6] | **$3.99 upfront**; no visible IAP | 4.72 (71) | 1.4 · 2019-01-19 | iPhone/iPad; 11.0+ | ph 4s+1v; pad 4s | No Details Provided |
| **Midi Poly Grid** — MPE & Polyphonic AT Controller [S7] | **$3.99 upfront**; no visible IAP; description foregrounds open-source code | 5.00 (7) | 1.1.14 · 2026-02-14 | iPhone/iPad; 13.0+ | ph 8s; pad 6s | Data Not Collected |
| **TC-Data** — Music [S8] | **$19.99 upfront**; no visible IAP | 4.64 (14) | 2.3.3 · 2026-02-16 | iPhone/iPad; 16.0+ | ph 5s; pad 5s | Data Not Collected |
| **TouchOSC** — Modular control surface [S9] | **$19.99 upfront**; no mobile IAP/subscription. Desktop has an unrestricted try-before-buy download and a separate one-time license [S31] | 4.55 (209) | 1.5.2 · 2026-07-01 | iPhone/iPad; 13.0+ | ph 4s; pad 4s | Data Not Linked to You |
| **MIDI Designer Pro X** — Custom MIDI Controller [S10] | **Free**; Premium monthly/yearly tiers by platform ($1.49–$4.99 monthly-price rows; $14.99–$49.99 yearly-price rows); $124.99 lifetime row. Apple’s IAP labels omit duration, while the developer confirms monthly, yearly, and lifetime choices [S29] | 4.60 (266) | 10.25.0 · 2026-07-15 | iPhone/iPad; 18.6+ | ph 6s+1v; pad 6s | Data Not Linked to You |
| **MidiPad 2** — Powerful MIDI pad controller [S11] | **$2.99 upfront**; no visible IAP | 4.21 (126) | 2.0.3 · 2017-12-13 | iPhone/iPad; 10.0+ | ph 3s; pad 3s | No Details Provided |
| **LK - Ableton & Midi Controller** — Sequencer and Clip Launcher [S12] | **Free**; Matrix $13.00; five other modules $6.49 each; All Modules Bundle $32.49 | 4.31 (697) | 1.15.11 · 2026-07-17 | iPhone/iPad; 17.0+ | ph 8s; pad 8s | Data Not Collected |
| **ThumbJam** — Music [S13] | **$8.99 upfront**; no visible IAP | 4.67 (218) | 2.6.11 · 2022-07-24 | iPhone/iPad; 8.0+ | ph 6s; pad 5s | Data Not Linked to You |

### Expressive touch instruments

| App — current subtitle | US base price and commercial model | US rating | Current version · last update | Device scope / OS floor | Store media | Privacy marker |
|---|---|---:|---|---|---|---|
| **Animoog Z Synthesizer** — Multisensory Music Production [S14] | **Free**; full-app unlock $14.99; sound packs from free to $4.99 | 4.82 (1,155) | 1.3.4 · 2026-06-08 | Mac/iPhone/iPad; 14.4+ | ph 6s+1v; pad 6s; mac 6s | Data Not Linked to You |
| **Model 15 Modular Synthesizer** — Moog Modular Synthesizer [S15] | **$14.99 upfront**; preset packs from free to $2.99 | 4.88 (896) | 2.4.4 · 2026-06-08 | Mac/iPhone/iPad; 12.4+ | ph 5s; pad 5s; mac 5s | Data Not Collected |
| **AudioKit Synth One Synthesizer** — Feature-packed Pro Synthesizer [S16] | **Free**; no visible IAP; description explicitly says no ads and no IAP | 4.91 (26,827) | 1.9.2 · 2026-01-22 | iPhone/iPad; 13.0+ | ph 5s+1v; pad 7s | Data Not Collected |
| **Bebot - Robot Synth** — Music [S17] | **$1.99 upfront**; no visible IAP | 4.86 (202) | 2.1.1 · 2017-09-11 | iPhone/iPad; 8.0+ | ph 4s+1v; pad 4s | No Details Provided |
| **Borderlands Granular** — Discover sounds within sounds. [S18] | **$19.99 upfront**; no visible IAP | 4.82 (126) | 2.1.3 · 2020-05-13 | iPad only; 8.0+ | pad 10s | No Details Provided |
| **Samplr** — The Multitouch Sampler [S19] | **$19.99 upfront**; no visible IAP | 4.73 (153) | 1.5.1 · 2026-02-27 | iPad only; 12.0+ | pad 2s+1v | Data Not Collected |

### Hosts and workstation substitutes

| App — current subtitle | US base price and commercial model | US rating | Current version · last update | Device scope / OS floor | Store media | Privacy marker |
|---|---|---:|---|---|---|---|
| **Loopy Pro: Looper DAW Sampler** — Live looping. Your way. [S20] | **Free 7-day trial**; $29.99 permanent unlock; optional $14.99 later upgrade for another year of features; explicitly no subscription [S30] | 4.84 (947) | 2.0.5 · 2025-11-26 | iPhone/iPad; 13.0+ | ph 6s; pad 6s | Data Not Collected |
| **AUM - Audio Mixer** — Connect, route, mix, record! [S21] | **$20.99 upfront**; optional tip-jar IAP $0.99–$9.99, not feature gating | 4.72 (523) | 1.4.8 · 2025-11-23 | iPhone/iPad; 12.0+ | ph 8s; pad 8s | Data Not Collected |
| **Drambo** — Modular groovebox, synth & fx [S22] | **$24.99 upfront**; three $4.99 DSP/content extensions and a $14.99 visual extension | 4.83 (323) | 2.54 · 2026-07-10 | iPhone/iPad; 15.6+ | ph 7s+1v; pad 9s | Data Not Collected |
| **Cubasis 3 - DAW & Music Studio** — Music Production & Recording [S23] | **$49.99 upfront**; effects/instrument IAP $4.99–$19.99. A separate current Cubasis LE 3 listing is free and offers a full-feature-set unlock [S34] | 4.62 (3,448) | 3.8.3 · 2026-02-23 | iPhone/iPad; 17.7+ | ph 10s+1v; pad 10s | Data Not Collected |
| **KORG Gadget 3** — Make Music [S24] | **$19.99 upfront**; visible gadget expansions $6.99–$9.99 | 4.77 (2,910) | 6.3.4 · 2026-07-01 | iPhone/iPad; 13.0+ | ph 10s; pad 10s | Data Linked to You; Data Not Linked to You |
| **Logic Pro: Make Music** — Produce beats and edit audio [S25] | **Free download**; current Apple Creator Studio plan is $12.99/month or $129/year after one month free. The App Store still exposes generic legacy Logic rows at $4.99/$49.00, but Apple’s current official plan is the Creator Studio bundle [S33] | 4.53 (5,978) | 3.3 · 2026-06-30 | Mac/iPad; iPadOS 26.0+ and A12 Bionic+ | pad 10s; mac 10s | Data Linked to You; Data Not Linked to You |
| **Ableton Note** — A place to start musical ideas [S26] | **$6.99 upfront**; Drift instrument IAP $3.99 | 4.21 (671) | 2.0.1 · 2026-05-05 | iPhone/iPad; 15.0+ | ph 7s+2v; pad 7s | Data Linked to You; Data Not Linked to You |
| **GarageBand** — Make great music anywhere [S27] | **Free**; no visible IAP | 4.07 (116,134) | 2.3.18 · 2025-11-03 | iPhone/iPad/iMessage; 26.0+ | ph 5s; pad 5s | Data Linked to You |

## Transparent price calculations

These calculations use **base download price only**, not the value of optional IAP.

### Base-price bands

| Band | Apps | Share of 27 |
|---|---:|---:|
| Free download | 8 | 29.6% |
| $0.01–$4.99 | 4 | 14.8% |
| $5.00–$9.99 | 3 | 11.1% |
| $10.00–$19.99 | 8 | 29.6% |
| $20.00–$29.99 | 3 | 11.1% |
| $30.00+ | 1 | 3.7% |

- **Paid apps:** 19/27, or 70.4%.
- **All-app median base price:** $8.99. This includes eight zero-dollar downloads.
- **Paid-only median:** $17.99. The sorted paid prices are: $1.99, $2.99, $3.99, $3.99, $6.99, $8.99, $9.99, $14.99, $14.99, **$17.99**, $19.99, $19.99, $19.99, $19.99, $19.99, $20.99, $24.99, $24.99, $49.99.
- **Direct controller/playable-surface paid median:** $12.49, the midpoint of $9.99 and $14.99 across ten paid apps.
- **Expressive-instrument paid median:** $17.49, the midpoint of $14.99 and $19.99 across four paid apps.
- **Host/workstation paid median:** $20.99 across five paid apps.

The price distribution is bimodal in practice: a bargain/utility tier at $1.99–$9.99 and a serious-instrument tier clustered at $14.99–$24.99. Cubasis is the lone $49.99 upfront outlier. The five different $19.99 entries—TC-Data, TouchOSC, Borderlands, Samplr, and KORG Gadget—make that price a credible premium anchor across very different scopes. [S8][S9][S18][S19][S24][S28]

### IAP and subscription incidence

- **14/27 (51.9%)** expose at least one IAP row.
- **6/8 free downloads** are commercial gateways: GeoShred Control, MIDI Designer Pro X, LK, Animoog Z, Loopy Pro, and Logic Pro. AudioKit Synth One and GarageBand are the two free/no-visible-IAP exceptions.
- **8/19 paid apps** also expose IAP. Those IAPs serve different jobs: sound/preset expansions (GeoShred, Model 15, ChordPolyPad, Ableton Note), capability extensions (Drambo), workstation instruments/effects (Cubasis, KORG Gadget), and voluntary tips (AUM).
- **2/27** visibly use ongoing subscriptions: MIDI Designer Pro X Premium and Apple Creator Studio/Logic Pro. That is not enough to claim subscriptions are rejected by the whole market, but it does show that they are the exception rather than the default.
- **Loopy Pro is a notable hybrid:** a real free trial, a permanent unlock, one included year of feature updates, permanent compatibility fixes, and optional future update payments. Its store copy repeats “no subscription,” “no signup,” and “keep what you buy.” [S20][S30]

## Trial, free, lite, bundle, and expansion tactics

### 1. Free controller as the top of a product ladder

GeoShred Control is the clearest direct precedent. Its first screenshot says “stand alone MIDI/MPE controller only / no audio engine”; the listing immediately explains the difference from paid GeoShred and the $24.99 Pro-functionality upgrade. It then sells $14.99 instrument models and high-value collections. The free product is useful by itself, but its merchandising deliberately makes the paid sound engine and instrument store visible. [S1][S2][S32]

This is a strong model when a controller has a separable no-sound job: let musicians verify touch tracking, MIDI routing, layout, and hardware compatibility before buying the internal instrument. The risk is conceptual complexity. GeoShred needs several paragraphs and footnotes to explain the relationship among Control, Pro, GeoSWAM, Naada, and collections.

### 2. Free shell with à-la-carte modules

LK divides the product into six concrete jobs—Matrix, Pads, Controller, X/Y, Chorder, and Keyboard—and sells each separately, with a $32.49 all-modules bundle. The screenshots mirror that architecture: each frame names one module and shows its interface. This lowers initial commitment while making the upgrade menu legible. It also creates an obvious ceiling: buying Matrix plus four $6.49 modules already exceeds the bundle. [S12]

Animoog Z applies a simpler instrument version of the pattern: a free base, a $14.99 full unlock, then small $0.99–$4.99 sound packs. [S14]

### 3. Freemium professional editor

MIDI Designer Pro X leaves core MIDI types, connections, community layouts, and many advanced functions in the free tier, then reserves greater page/bank capacity, popup panels, and appearance options for Premium. Its developer page explicitly frames the redesign as a way to eliminate “sticker shock” and let users test a use case before committing. Monthly, yearly, platform-specific, cross-platform, and lifetime choices make the price ladder unusually complex. [S10][S29]

The lesson is not “offer every tier.” It is that a professional utility can make free useful if the boundary is based on project scale and convenience rather than basic protocol support.

### 4. True trial plus permanent ownership

Loopy Pro’s seven-day trial is the cleanest commercial story in the sample: no signup, no subscription, $29.99 to keep the current feature set, 12 months of feature updates, and optional $14.99 update years. It reduces purchase uncertainty without splitting the interface into “lite” and “pro” products. [S20][S30]

TouchOSC uses a related tactic outside the mobile storefront: the paid $19.99 iOS app, but unrestricted try-before-buy desktop downloads and one-time desktop licenses. Mobile and desktop licenses are separate. [S9][S31]

### 5. Separate lite app

Steinberg maintains **Cubasis LE 3** as a separate free App Store product, current at the same 3.8.3 version/date as Cubasis 3 in this snapshot. It operates in demo mode without supported hardware and offers a full Cubasis feature-set unlock plus the same plug-in expansion family. This creates search visibility for both “Cubasis” and “Cubasis LE,” but also forces the listing to explain hardware unlocks, demo state, full-feature unlocks, and IAP transfer. [S23][S34]

### 6. Ecosystem bundle subscription

Logic Pro is no longer merchandising only a music app. Its description opens with Apple Creator Studio, which bundles Logic with Final Cut Pro, Pixelmator Pro, Motion, Compressor, MainStage, and premium productivity-app content. Apple prices the suite at $12.99/month or $129/year after a one-month trial, with three months free after eligible hardware purchases. This is a cross-category ecosystem tactic that a standalone music developer cannot copy directly. [S25][S33]

### 7. Paid app plus optional expansions remains normal

The most common paid-IAP pattern is not feature ransom; it is additive content. Model 15 sells preset packs, ChordPolyPad sells chord/preset packs, KORG Gadget sells additional gadgets, Cubasis sells instruments/effects, GeoShred sells modeled instruments, and Ableton Note sells Drift. The base app still communicates a complete instrument or production system. [S2][S4][S15][S23][S24][S26]

## Update cadence and compatibility merchandising

Using 2026-07-25 as day zero:

| Age of current version | Apps | Share |
|---|---:|---:|
| 0–30 days | 6 | 22.2% |
| 31–180 days | 10 | 37.0% |
| 181–365 days | 6 | 22.2% |
| More than 365 days | 5 | 18.5% |

Thus **16/27 (59.3%)** had shipped an update within 180 days and **22/27 (81.5%)** within a year. The six 0–30-day apps were TouchOSC, MIDI Designer Pro X, LK, Drambo, KORG Gadget 3, and Logic Pro. [S9][S10][S12][S22][S24][S25]

The five apps more than a year old are not a single cohort:

- ThumbJam last updated in 2022, yet still has 218 ratings and an $8.99 price.
- Borderlands last updated in 2020 and still commands $19.99.
- Ribbons last updated in 2019 at $3.99.
- Bebot and MidiPad 2 last updated in 2017 and remain purchasable at $1.99 and $2.99.

That persistence shows that iOS musicians do buy and retain long-lived niche instruments. It does **not** show that stale software is harmless: old listings also carry low OS floors, dated screenshots, “No Details Provided” privacy labels, and obsolete ecosystem terms such as Inter-App Audio. A current version date is therefore useful reassurance, especially for a MIDI utility expected to survive OS and hardware changes.

All 27 apps support iPad. Twenty-four support iPhone; Borderlands and Samplr are iPad-only, while Logic declares iPad and Mac but not iPhone. Four declare a Mac platform—ChordPolyPad, Animoog Z, Model 15, and Logic Pro. The OS floor spans iOS/iPadOS 8.0 to 26.0. Current direct competitors range from deliberately broad compatibility (KB-1 and Velocity at iOS 11) to aggressively modern requirements (MIDI Designer Pro X at 18.6 and LK at 17.0). [S3][S5][S10][S12][S18][S19][S25][S28]

## Title, subtitle, and description language

### Subtitle conventions

Four listings leave the storefront subtitle at the generic category “Music”: GeoShred Control, TC-Data, ThumbJam, and Bebot. Every other listing uses one of three patterns.

**Technical category labels**

- “Expressive MIDI Controllers” — KB-1
- “MPE MIDI Controller Audio Unit” — Velocity Keyboard
- “MPE & Polyphonic AT Controller” — Midi Poly Grid
- “Modular control surface” — TouchOSC
- “Custom MIDI Controller” — MIDI Designer Pro X
- “MIDI Chords Player” — ChordPolyPad
- “The Multitouch Sampler” — Samplr

These make App Store search relevance and protocol fit immediately legible. [S3–S5][S7][S9][S10][S19]

**Scope labels**

- “Moog Modular Synthesizer”
- “Feature-packed Pro Synthesizer”
- “Modular groovebox, synth & fx”
- “Music Production & Recording”

These communicate breadth and category without promising a particular emotional outcome. [S15][S16][S22][S23]

**Job or benefit lines**

- “Live looping. Your way.”
- “A place to start musical ideas”
- “Make great music anywhere”
- “Discover sounds within sounds.”
- “Connect, route, mix, record!”

These are shorter, more memorable, and more common among products whose feature set is too broad for a protocol checklist. [S18][S20][S21][S26][S27]

### Description vocabulary

The following counts are transparent app-level presence counts across the 27 descriptions:

| Term or concept | Apps containing it |
|---|---:|
| create / creation | 22 |
| MIDI | 24 |
| controller | 18 |
| instrument | 17 |
| easy / easily | 16 |
| touch / multitouch / Multi-Touch | 16 |
| expressive / expression | 15 |
| powerful | 15 |
| performance / perform | 15 |
| scale / scales | 15 |
| AUv3 | 13 |
| hardware | 12 |
| customizable / customisable | 10 |
| MPE | 10 |
| intuitive | 9 |
| chord / chords | 9 |
| professional | 7 |

The direct 13-app subset is more specific: MIDI 13/13, controller 12/13, expressive 9/13, scales 9/13, MPE 8/13, powerful 8/13, customizable 7/13, and AUv3 7/13. “Professional” appears in only two direct descriptions. Technical confidence is being sold through concrete capability words, not repeated “pro” claims.

Several description openings are especially disciplined:

- GeoShred Control says it is a free MIDI/MPE controller for external sound sources, has no built-in sounds, and can be upgraded.
- Velocity Keyboard says it is a velocity-sensitive, MPE-compatible MIDI controller.
- TC-Data says it sends MIDI and OSC to other apps and hardware, then explicitly says it is not a synthesizer.
- MIDI Designer Pro X starts with the user’s job: make the perfect controller for music-making gear or adapt a community layout.
- Loopy Pro states the product form—live looper, sampler, sequencer, customizable DAW—then leads with a seven-day trial.

The recurring best practice is **define the product boundary before listing depth**. Controller-only products say “does not make sound”; hybrid products say standalone/AUv3 and identify whether they send MIDI, host instruments, or generate audio. [S1][S5][S8][S10][S20]

## Screenshot and preview-video patterns

### Quantitative media pattern

- iPad media slots per app: **median 6**, range **3–10**.
- Apps with at least one preview video on any declared device: **9/27 (33.3%)**.
- Apps with an iPad preview video: **1/27**, Samplr.
- The other video users—Ribbons, MIDI Designer Pro X, Animoog Z, AudioKit Synth One, Bebot, Drambo, Cubasis 3, and Ableton Note—place video only in their iPhone media set in Apple’s current page data. [S6][S10][S14][S16][S17][S19][S22][S23][S26]

### Static campaign styles

A manual review of the first four available static frames classified 14 apps as clear multi-frame benefit-headline campaigns:

GeoShred Control, GeoShred, KB-1, TouchOSC, MIDI Designer Pro X, MidiPad 2, LK, Animoog Z, Model 15, Samplr, Loopy Pro, Drambo, Cubasis 3, and Ableton Note. [S1–S3][S9–S12][S14][S15][S19][S20][S22][S23][S26]

Common mechanics:

1. **Three-to-seven-word headline, interface beneath it.** TouchOSC uses “The Next Generation is Here,” “Now With Integrated Editor,” “Create Connections Between Controls,” and “Advanced Options and Scripting.” The copy progresses from novelty to editor to relationship model to depth. [S9]
2. **One screenshot per module/job.** LK names Matrix, MIDI Pads, and other modules; Ableton Note uses “Begin with a beat,” “Start with a melody,” “Sample your environment,” and “Work with audio.” [S12][S26]
3. **Feature proof over decoration.** KB-1 shows its eight layouts, MPE, and arpeggiator. MIDI Designer shows community layouts for 300+ MIDI targets, supported hardware, on-device design, and control relationships. [S3][S10]
4. **Product UI remains the hero.** Even polished campaigns rarely use stock lifestyle art. GeoShred and Cubasis place the real interface in device frames; Drambo shows the same modular workflow at several device sizes. [S1][S2][S22][S23]
5. **Brand/product personality can substitute for feature copy.** Bebot’s illustrated robot campaign and Borderlands’ sparse black spatial interface are memorable without conventional feature cards, although both listings look older than the modern headline-led sets. [S17][S18]
6. **Raw UI is accepted among specialist tools.** ChordPolyPad, Velocity Keyboard, Midi Poly Grid, TC-Data, AUM, KORG Gadget, and GarageBand mostly show direct interface captures. This communicates depth to an informed buyer but puts more burden on the description and subtitle. [S4][S5][S7][S8][S21][S24][S27]
7. **Quotes and awards are selective proof.** Loopy Pro includes artist quotes in screenshots; GeoShred, Cubasis, and several instrument descriptions lead with awards or artist use. This is useful when the product form is unfamiliar, but concrete gesture/capability proof is generally more prominent. [S1][S2][S20][S23]

## Privacy and support markers

| Apple privacy label combination | Apps | Share |
|---|---:|---:|
| Data Not Collected | 15 | 55.6% |
| Data Not Linked to You only | 4 | 14.8% |
| Data Linked to You + Data Not Linked to You | 3 | 11.1% |
| Data Linked to You only | 1 | 3.7% |
| No Details Provided | 4 | 14.8% |

All 13 direct controller/playable-surface apps avoid an Apple “Data Linked to You” declaration: eight say Data Not Collected, three say Data Not Linked, and two older apps say No Details Provided. Every sampled listing has a developer website/support destination; 25/27 have a privacy-policy link. The two without a visible privacy-policy link are MidiPad 2 and Bebot. [S1–S27]

The merchandising implication is concrete. A new controller asking for Bluetooth, local-network, microphone, file, or motion access will be compared with tools that mostly claim no collection. Permission prompts should explain the musical reason in plain language, and the privacy label should avoid unnecessary account or analytics collection if the product can function locally.

## Implications for ExpressionPad

The following are App Store implications, not claims about the current ExpressionPad build. Each recommendation should be used only where the corresponding capability is accurate.

### 1. Use the subtitle to define the category, not to repeat the name

The most legible direct competitors combine one expressive word with one protocol/product word. Candidate structures:

- **Expressive MIDI/MPE Instrument**
- **Touch Instrument & MIDI Control**
- **Expressive Pads, Synth & MIDI**

The right choice depends on whether ExpressionPad makes sound, sends MIDI/MPE, and ships AUv3. “Music” wastes the strongest search-and-comprehension line. “Powerful” and “professional” are less discriminating than MIDI, MPE, expressive, touch, sampler, or instrument.

### 2. Price against the direct segment, then justify the step-up

The direct paid median is $12.49; the broader paid median is $17.99. That supports three plausible positions:

- **$7.99–$9.99** for a focused controller with a small scope.
- **$12.99–$14.99** for a polished expressive controller with multiple layouts, reliable MIDI/MPE, and AUv3.
- **$19.99–$24.99** for a hybrid instrument whose internal synth/sampler, preset content, recording, or performance environment is a material part of the value.

A price above $14.99 should be merchandised through visibly complete internal sound, performance, and routing capabilities—not a long feature list alone. A launch discount can create urgency, but the enduring comparison set is paid once, not ad-supported.

### 3. Prefer trial or useful free control over subscription

The market shows clear willingness to pay upfront, and only two sampled apps use subscriptions. If purchase uncertainty is the obstacle, the strongest precedents are:

- a useful controller-only free tier with a one-time sound/pro unlock, like GeoShred Control;
- a time-limited full trial with permanent ownership, like Loopy Pro;
- a separate LE version only if hardware partnerships or App Store search coverage justify the added explanation burden.

Subscription would need a credible recurring service—large ongoing content, cloud collaboration, or multi-app value—not ordinary maintenance.

### 4. Make the first three screenshots answer the purchase questions

A high-converting sequence should make the product boundary unmistakable:

1. **Play the surface:** one strong performance frame, a hand/touch trace if legible, and a headline such as “Shape every note with touch.”
2. **Explain the dimensions:** show the same note responding to horizontal, vertical, pressure/area, or gesture input, with no more than three short labels.
3. **Prove connection:** show MIDI/MPE/AUv3 and hardware/app routing. If the app makes sound, say “Play built-in sounds or control your synths”; if it is controller-only, say so explicitly.
4. Then show scale/chord assistance, internal synth/sampler, presets, customization, and recording as applicable.

Do not open with a settings page. Do not rely on users to infer expression from a colorful grid.

### 5. Invest in an iPad preview video

Only Samplr uses an iPad preview video in this 27-app set. Expressive interaction is inherently temporal: attack, movement, pressure, pitch rounding, vibrato, release, and visual feedback happen over time. A 15–25 second silent-readable preview can demonstrate:

- touch down → sound;
- lateral/vertical movement → two audible/visible dimensions;
- polyphonic gestures;
- instant scale/chord change;
- one routing shot to an external synth or AUv3 host.

This is a more meaningful whitespace opportunity than adding a tenth screenshot.

### 6. Merchandize trust

Ship the privacy policy and support destination with the listing. If accurate, foreground:

- no account required;
- music stays on device;
- data not collected;
- Bluetooth/local-network access is only for MIDI or device connection;
- a concise compatibility line for iPhone/iPad, minimum OS, AUv3 hosts, and external hardware.

The version history should read like active instrument maintenance—compatibility, latency, stuck-note prevention, MIDI reliability, crash fixes—not only “bug fixes and improvements.”

### 7. Use proof that matches an unfamiliar instrument

Awards, artist quotes, and creator counts help only after users understand the interaction. The most persuasive proof order for ExpressionPad is:

1. visible gesture-to-sound/control response;
2. protocol and routing compatibility;
3. real performance clip;
4. credible musician quote or award;
5. large numeric claims only when directly substantiated.

### 8. Keep the commercial ladder explainable in one screen

GeoShred and MIDI Designer show how quickly IAP trees become difficult to explain. If ExpressionPad uses IAP, prefer one of:

- free trial → one permanent Pro unlock;
- paid app → clearly optional sound/preset packs;
- controller free → instrument one-time unlock.

Avoid simultaneous feature tiers, content currencies, platform tiers, and subscriptions at launch.

## Caveats and unresolved data gaps

1. This is a purposive competitive sample, not a random sample of Apple’s Music category. Percentages describe these 27 apps only.
2. Apple’s lookup endpoint is authoritative for the retrieved storefront snapshot but not a historical price record. Sale prices can change without a version update.
3. Apple’s public web IAP table is truncated and sometimes exposes internal or residual product names. Loopy Pro’s “Internal Use Only” row and Logic’s generic $4.99/$49 rows are reported as visible storefront data, not interpreted as current public plans. Current Logic pricing was resolved against Apple’s Creator Studio page. [S20][S25][S33]
4. Subscription duration is not printed in MIDI Designer’s Apple IAP labels. The monthly/yearly/lifetime structure comes from the developer’s official page; the corresponding live dollar rows come from Apple. [S10][S29]
5. “Data Not Collected” and related privacy labels are developer disclosures relayed by Apple, not an independent privacy audit.
6. Screenshot classification is a merchandising judgment based on the first four available static frames. It is separately labeled from machine-readable counts.
7. No causal inference is made between price, rating, screenshot style, update recency, or commercial success. Rating counts are included as visible social proof, not revenue estimates.
8. Apple’s current storefront sometimes declares a native Mac platform and sometimes only compatibility on Apple-silicon Macs. This brief counts only the former in the platform summary.
9. App descriptions may mention deprecated technologies retained for older users. A mention of Inter-App Audio or 3D Touch is not evidence that those technologies should be copied.

## Sources

1. **[S1] Apple App Store — GeoShred Control.** https://apps.apple.com/us/app/geoshred-control/id1336247116
2. **[S2] Apple App Store — GeoShred.** https://apps.apple.com/us/app/geoshred/id1064769019
3. **[S3] Apple App Store — KB-1 Keyboard Suite.** https://apps.apple.com/us/app/kb-1-keyboard-suite/id1437919435
4. **[S4] Apple App Store — ChordPolyPad.** https://apps.apple.com/us/app/chordpolypad/id694599930
5. **[S5] Apple App Store — Velocity Keyboard.** https://apps.apple.com/us/app/velocity-keyboard/id1462605052
6. **[S6] Apple App Store — Ribbons: Touch Instrument.** https://apps.apple.com/us/app/ribbons-touch-instrument/id898059305
7. **[S7] Apple App Store — Midi Poly Grid.** https://apps.apple.com/us/app/midi-poly-grid/id1633882803
8. **[S8] Apple App Store — TC-Data.** https://apps.apple.com/us/app/tc-data/id883788579
9. **[S9] Apple App Store — TouchOSC.** https://apps.apple.com/us/app/touchosc/id1569996730
10. **[S10] Apple App Store — MIDI Designer Pro X.** https://apps.apple.com/us/app/midi-designer-pro-x/id492291712
11. **[S11] Apple App Store — MidiPad 2.** https://apps.apple.com/us/app/midipad-2/id896879399
12. **[S12] Apple App Store — LK: Ableton & Midi Controller.** https://apps.apple.com/us/app/lk-ableton-midi-controller/id944972221
13. **[S13] Apple App Store — ThumbJam.** https://apps.apple.com/us/app/thumbjam/id338977566
14. **[S14] Apple App Store — Animoog Z Synthesizer.** https://apps.apple.com/us/app/animoog-z-synthesizer/id1586841361
15. **[S15] Apple App Store — Model 15 Modular Synthesizer.** https://apps.apple.com/us/app/model-15-modular-synthesizer/id1041465860
16. **[S16] Apple App Store — AudioKit Synth One Synthesizer.** https://apps.apple.com/us/app/audiokit-synth-one-synthesizer/id1371050497
17. **[S17] Apple App Store — Bebot: Robot Synth.** https://apps.apple.com/us/app/bebot-robot-synth/id300309944
18. **[S18] Apple App Store — Borderlands Granular.** https://apps.apple.com/us/app/borderlands-granular/id561369733
19. **[S19] Apple App Store — Samplr.** https://apps.apple.com/us/app/samplr/id560756420
20. **[S20] Apple App Store — Loopy Pro: Looper DAW Sampler.** https://apps.apple.com/us/app/loopy-pro-looper-daw-sampler/id1492670451
21. **[S21] Apple App Store — AUM: Audio Mixer.** https://apps.apple.com/us/app/aum-audio-mixer/id1055636344
22. **[S22] Apple App Store — Drambo.** https://apps.apple.com/us/app/drambo/id1469365718
23. **[S23] Apple App Store — Cubasis 3: DAW & Music Studio.** https://apps.apple.com/us/app/cubasis-3-daw-music-studio/id1207839273
24. **[S24] Apple App Store — KORG Gadget 3.** https://apps.apple.com/us/app/korg-gadget-3/id791077159
25. **[S25] Apple App Store — Logic Pro: Make Music.** https://apps.apple.com/us/app/logic-pro-make-music/id1615087040
26. **[S26] Apple App Store — Ableton Note.** https://apps.apple.com/us/app/ableton-note/id1633243177
27. **[S27] Apple App Store — GarageBand.** https://apps.apple.com/us/app/garageband/id408709785
28. **[S28] Apple iTunes Lookup API — 27-app US metadata query, retrieved 2026-07-25.** https://itunes.apple.com/lookup?id=1336247116,1064769019,1437919435,694599930,1462605052,898059305,1633882803,883788579,1569996730,492291712,896879399,944972221,338977566,1586841361,1041465860,1371050497,300309944,561369733,560756420,1492670451,1055636344,1469365718,1207839273,791077159,1615087040,1633243177,408709785&country=us&entity=software
29. **[S29] MIDI Designer — MIDI Designer Pro X pricing and Premium-vs-free model.** https://mididesigner.com/midi-designer-pro-x/
30. **[S30] Loopy Pro — official pricing.** https://loopypro.com/pricing/
31. **[S31] Hexler — official TouchOSC product and licensing page.** https://hexler.net/touchosc
32. **[S32] moForte — GeoShred Control Quick Start Guide and pricing explanation.** https://www.moforte.com/geoshred-control-quick-start-guide/
33. **[S33] Apple — Apple Creator Studio pricing.** https://www.apple.com/apple-creator-studio/
34. **[S34] Apple App Store — Cubasis LE 3.** https://apps.apple.com/us/app/cubasis-le-3/id1479016819
