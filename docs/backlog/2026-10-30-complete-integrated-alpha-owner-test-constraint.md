# P0 — complete integrated alpha release gate (confirmed 2026-10-30)

**Canonical project issue:** [Bellum Bridge #90](https://github.com/AIRebelRelay/Bannerlord2-AiInfluence-BellumCivile/issues/90). Related Relay [#468](https://github.com/AIRebelRelay/ai-rebel-relay/issues/468).

## Stable owner constraint

The project owner is on military service and **cannot test each development Stage in Bannerlord** or repeatedly compile, copy and replace Native/Bridge DLLs. Do not offer partial builds to the owner for testing or ask for manual per-Stage saves/logs. This restriction has been restated repeatedly; treat it as **permanent until explicitly changed by the owner**.

Required delivery is **ONE functionally complete integrated alpha** of the **planned/applicable** Bellum Civile 1.4.5 + AI Influence 6.0.2 + Bellum Bridge 0.8.6 + AI Rebel Relay 5.1.9 interaction, suitable for external tester validation and then (after fixes) Nexus early alpha. No unilateral cut-down MVP or intentionally incomplete tester package. This does **not** require enabling every Native Bellum mechanic; respect intentional exclusions and Revamp OFF.

## Native team backlog / acceptance

1. Enumerate Native relevant systems, exact API/feature authority and existing implementation in a current-HEAD coverage matrix (war/peace/WarScore, civil/claim, succession, factions/court, hostages/retained prisoners, events/foreign politics).
2. Track each planned integration as complete/partial/absent/blocked with Bellum Bridge and Relay consumers and actor-visibility requirements. Protect working saved Native semantics, Revamp OFF and original custody outcomes.
3. Continue **regression-first surgical development** with separate internal stages: tests before production, root cause/callers/blast radius, small diff, compile+automated harness+real game evidence **when genuinely available**. Do not use successful text checks as a substitute for a net472 build and game.
4. Build and test by developer/Bhelogan/automation, not by owner's nightly DLL/game test loop. Avoid GitHub Actions for every small commit.
5. Cross-system integration testing and unified feature-complete, pinned package are **one terminal owner/external tester gate**, not a sequence of incomplete drops. No public release/main merge until validated.

## Current Native blocker

Stage30C read-only hostage API at `bdec0e2468e14cc382fd156bb9653449fdc57dce` has source-only checks and lacks net472 build/targeted harness and game proof. Native WarScore ledger Stage29F1 also unvalidated; Bellum Bridge P0 foreign-war/peace issue #89 is OPEN. These are internal backlog blockers; **not requests for the owner to test a partial DLL**.

**Future Stage handoff header:** "INTERNAL DEVELOPMENT ONLY. No owner incremental DLL rebuild/playtest. Complete integrated alpha gate: Bellum Bridge #90."
