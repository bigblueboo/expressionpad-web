# Research provenance: iOS music control surfaces

**Research date:** July 25, 2026  
**Prepared for:** ExpressionPad  
**Final brief:** [iOS music control surfaces competitive analysis](ios-music-control-surfaces-competitive-analysis.md)

## Research question

Survey the current and historically influential iOS market for expressive synths, MIDI/MPE controllers, alternative grids/keyboards, touch-native instruments, modular controller builders, hosts, and broader workstation substitutes; determine ExpressionPad’s differentiation, gaps, positioning, pricing, merchandising, and launch priorities.

## Process

The work used a lead researcher plus seven parallel research tracks:

1. direct expressive MIDI/MPE controllers;
2. grid, isomorphic, chord, and microtonal surfaces;
3. touch-native synths and instruments;
4. modular MIDI/OSC builders and controller utilities;
5. DAWs, grooveboxes, hosts, and workstation substitutes;
6. App Store pricing, merchandising, language, update cadence, and privacy patterns;
7. user/community voice, historical lineage, accessibility, and continuity risk.

Exa was used aggressively for discovery, current-page retrieval, and contradiction resolution. Commercial metadata was then normalized against live US Apple App Store pages or Apple’s Lookup API wherever possible. First-party manuals and developer pages were preferred for MIDI, MPE, AUv3, OSC, device, expression, and workflow claims. Specialist/editorial and community sources were used primarily for usability, history, reputation, and failure modes.

The lead also audited ExpressionPad directly from the repository, especially:

- [README.md](../README.md)
- [iOS README](../ios/README.md)
- `ios/App/ExpressionPadApp.swift`
- `ios/App/AudioEngine.swift`
- `ios/App/Midi.swift`
- `ios/Core/Sources/ExpressionPadCore/TouchTracker.swift`
- `src/midi/midi.ts`
- `src/ui/touch.ts`

## Evidence volume

The seven research briefs contain approximately **48,192 words** and **298 unique external URLs** before deduplication and final selection:

| Track | Words | Research file |
|---|---:|---|
| Direct expressive controllers | 6,997 | [direct](../outputs/ios-music-control-surfaces-research-direct.md) |
| Grids, tunings, and alternative keyboards | 7,073 | [grids](../outputs/ios-music-control-surfaces-research-grids.md) |
| Touch-native instruments | 8,595 | [instruments](../outputs/ios-music-control-surfaces-research-instruments.md) |
| Modular builders, hosts, and utilities | 8,302 | [modular](../outputs/ios-music-control-surfaces-research-modular.md) |
| Workstations and broad substitutes | 3,695 | [workstations](../outputs/ios-music-control-surfaces-research-workstations.md) |
| App Store merchandising and economics | 5,750 | [App Store](../outputs/ios-music-control-surfaces-research-appstore.md) |
| User voice and historical lineage | 7,780 | [user voice](../outputs/ios-music-control-surfaces-research-voice.md) |

The final brief cites 72 selected external URLs inline or in its source appendix. More than 60 products were screened; over 20 are discussed materially and more than 12 were deeply profiled across the underlying research.

## Evidence rules

- Prices, versions, updates, and availability are a **US snapshot dated July 25, 2026**.
- Live Apple metadata overruled stale search snippets and third-party mirrors.
- “No documented support” means the feature was not found in current first-party material; it is not proof that a workaround is impossible.
- Historical products are labeled and are not mixed into current purchase comparisons.
- App Store statistics come from a purposive 27-app sample and are not presented as a census of all music apps.
- Ratings were not used as quality scores because geography, age, count, and version eras differ.
- Claims about ExpressionPad come from the repository rather than assumed roadmap intent.
- Facts, market interpretations, and recommendations are separated in the brief.

## Contradictions resolved

- GeoShred Control’s live Pro-functionality upgrade was normalized to $24.99 rather than stale lower indexed prices.
- KB-1’s current US price was normalized to $14.99 rather than cached $7.99 references.
- Musix Pro was classified as actively maintained after its July 2026 update, not as dormant legacyware.
- Pen2Bow, Aftertouch, AC Sabre, ROLI NOISE, and the original ExpressionPad were treated as unavailable when live Apple lookups returned no current record.
- Lemur was treated as a returned product with a new commercial model, not simply as discontinued.
- Hexatone’s current live product was separated from stale/disappearing search results.
- MPE claims were split into generation, input, output, recording, replay, and per-note tuning-only cases.
- ExpressionPad’s “pressure” was identified from code as vertical motion after onset, not physical Z-force.
- ExpressionPad’s background-audio documentation was flagged because lifecycle code currently stops audio and relinquishes the session when backgrounded.

## Verification

The lead ran an automated reachability check across all selected external URLs. Pages that reject automated requests—such as some App Store/developer sites—were retained only when corroborated in the research record. Two incorrect App Store IDs for MorphWiz Studio and Fluss were found and corrected.

An independent verifier checked the final draft against the research files and repository. An independent adversarial reviewer then checked support, logic, recency, overconfidence, and completeness. Their findings are recorded in:

- [verified output brief](../outputs/ios-music-control-surfaces-brief.md)
- [verification report](../outputs/ios-music-control-surfaces-verification.md)

## Known limitations

- Documentary research cannot establish real latency, jitter, touch accuracy, haptic timing, routing reliability, accessibility quality, or MPE record/replay fidelity.
- Storefront prices and compatibility can change at any time.
- New 2026 entrants have thin rating histories and limited independent coverage.
- Several feature absences are documentation findings and require hands-on confirmation.
- Logic, some subscription/IAP products, and regional offers can expose different current purchase paths.
- The brief recommends hands-on testing before final launch claims.
