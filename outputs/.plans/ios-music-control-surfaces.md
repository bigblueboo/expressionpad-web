# Research Plan: Competitive analysis of iOS synth, MIDI, and music control surfaces

## Questions

1. Which currently available or historically influential iOS apps compete directly or indirectly with ExpressionPad?
2. How should the landscape be segmented by interaction model, use case, and degree of substitutability?
3. What are each competitor's current price, platform scope, core control surface, MIDI/MPE/OSC/AUv3 capabilities, internal sound engine, strengths, weaknesses, and positioning?
4. What patterns recur in App Store language, screenshots, demos, reviews, communities, update cadence, and monetization?
5. Which users and jobs-to-be-done are underserved?
6. Where is ExpressionPad meaningfully differentiated, where is it at parity, and where is it exposed?
7. What product, launch, merchandising, pricing, content, and partnership actions follow from the evidence?

## Strategy

- Round 1: seven parallel researchers, split into disjoint competitor and evidence categories.
- Round 2: targeted gap filling and contradiction resolution after the first evidence sweep.
- Lead synthesis: normalize the evidence into a market map, comparison matrix, positioning analysis, and prioritized recommendations.
- Verification: one citation/source verifier and one adversarial reviewer, followed by fixes for material issues.
- Source priority: official developer sites and Apple App Store pages first; manuals/support docs for protocols and workflows; credible specialist reviews and videos for usability and reputation; App Store review/rating data only when directly visible and dated.
- Time scope: current state as of 2026-07-25, with historically important discontinued apps included when they shaped category expectations.

## Acceptance Criteria

- [ ] At least 20 relevant apps are screened and at least 12 are profiled in depth.
- [ ] Every direct competitor has current or explicitly date-stamped evidence for availability, price, and major capabilities.
- [ ] All key questions are answered with at least two independent sources where practical.
- [ ] Critical findings do not rely on a single secondary source.
- [ ] Contradictions and unknowns are explicitly identified.
- [ ] Claims about ExpressionPad are checked against the repository, not assumed.
- [ ] The final brief distinguishes facts, interpretations, and recommendations.
- [ ] All cited URLs are checked in a verification pass.

## Task Ledger

| ID | Owner | Task | Status | Output |
|---|---|---|---|---|
| T0 | lead | Audit ExpressionPad's features, interaction model, and likely positioning from repository evidence | done | `README.md`, `ios/README.md`, `reference/DESIGN.md`, source |
| T1 | researcher | Direct expressive MIDI/MPE control surfaces | done | `outputs/ios-music-control-surfaces-research-direct.md` |
| T2 | researcher | Grid, isomorphic, chord, and alternative keyboard instruments | done | `outputs/ios-music-control-surfaces-research-grids.md` |
| T3 | researcher | Modular MIDI/OSC controller builders and performance utilities | done | `outputs/ios-music-control-surfaces-research-modular.md` |
| T4 | researcher | Expressive synth/instrument apps with touch-native control | done | `outputs/ios-music-control-surfaces-research-instruments.md` |
| T5 | researcher | Broad iOS synth/workstation substitutes and ecosystem expectations | done | `outputs/ios-music-control-surfaces-research-workstations.md` |
| T6 | researcher | App Store merchandising, pricing, ratings, update cadence, and category language | done | `outputs/ios-music-control-surfaces-research-appstore.md` |
| T7 | researcher | User discourse, reviews, pain points, communities, and historical lineage | done | `outputs/ios-music-control-surfaces-research-voice.md` |
| T8 | lead | Normalize landscape and resolve gaps/contradictions using Exa | done | `outputs/.drafts/ios-music-control-surfaces-draft.md` |
| T9 | verifier | Verify URLs and attach inline citations to the lead draft | done | `outputs/ios-music-control-surfaces-brief.md` |
| T10 | reviewer | Adversarial evidence and logic review | done — PASS | `outputs/ios-music-control-surfaces-verification.md` |
| T11 | lead | Revise and deliver final brief plus provenance to `marketing/` | done | `marketing/ios-music-control-surfaces-competitive-analysis.md` |

## Verification Log

| Item | Method | Status | Evidence |
|---|---|---|---|
| ExpressionPad feature set | Repository cross-read | pass | `README.md`, `ios/README.md`, `reference/DESIGN.md`, `ios/App/Midi.swift`, `ios/Core/Sources/ExpressionPadCore/TouchTracker.swift`, `src/midi/midi.ts` |
| Competitor availability and pricing | Official App Store/developer source cross-check | pass | seven research files + independent verifier |
| MIDI/MPE/OSC/AUv3 capability matrix | Official manuals and product pages | pass | direct, grids, instruments, modular, and workstation research |
| Review/reputation claims | Multiple specialist or user sources, date-labeled | pass | user-voice research |
| Strategic conclusions | Trace to comparison matrix and cited evidence | pass | final brief + reviewer PASS |

Round 1, gap-filling, lead synthesis, citation verification, adversarial
review, and final delivery are complete.

## Decision Log

- 2026-07-25: Treat both dedicated controllers and touch-native instruments as relevant. ExpressionPad combines a playable instrument, internal synth/sampler, and external MIDI controller, so substitutes cross conventional App Store categories.
- 2026-07-25: Include historically influential discontinued products only in a separate lineage/risk section; do not present them as purchasable current competitors.
- 2026-07-25: Use USD App Store pricing where it can be verified; mark regional, sale, bundle, IAP, and subscription caveats.
- 2026-07-25: Deliver the final brief in `marketing/` as requested, while keeping intermediate research under `outputs/`.
- 2026-07-25: Live Apple metadata overruled stale indexed snippets, notably
  for KB-1 pricing and the current 2026 update status of GeoShred, Musix Pro,
  TouchOSC, TC-11/TC-Data, and new entrants.
- 2026-07-25: KeyPad, Hexatone, iotaTONE, Rubberband, and several low-cost
  controller builders establish that the category is seeing new 2026 activity,
  not merely sustaining legacy apps.
- 2026-07-25: The lead positioning is “a continuous instrument that happens
  to speak MIDI”; generic controller construction is treated as TouchOSC's
  category, while whole-rig hosts are integration targets.
- 2026-07-25: Recommend $14.99 one-time only with AUv3 and durable named
  setups; otherwise use a free playable tier or lower first-release price.
- 2026-07-25: Adversarial review softened untested no-look, exact touch-count,
  and universal MPE claims; added Etherpad, Synthecaster, and Surface Builder;
  and normalized protocol states before issuing a final PASS.
