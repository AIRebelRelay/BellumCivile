# P0-08 — Bellum 1.4.9 → 1.4.10 → 1.4.11 save-schema ownership audit

**STATUS: EVIDENCE / DOCS ONLY. No feature import, Native DLL, Bridge edit, merge or release.**
Prepared against the *current stacked Native* `AIRebelRelay/BellumCivile@66e9f7df48345b5a96f3b1bb688db1b845d8e761` (Draft PR #18), not merely the old PR #13 snapshot. Original custom `main@71c7ab8b8b7a21fc2661f5f25e0a18d74b952ca7` remains the rollback baseline. Do not confuse Native Bellum with `AIRebelRelay/Bannerlord2-AiInfluence-BellumCivile` (Bellum Bridge) or separate Relay Bridge.

## Pinned source checkpoints / provenance

| Checkpoint | Official Vonbalt/BellumCivile source SHA | BellumCivileSaveDefiner.cs Git blob |
|---|---|---|
| 1.4.9 | `e2ff7d074adeef3b539e7ec47094171c388b6842` | `68dbd345e7b316e9bd47e85dc872c3565a80000f` |
| 1.4.10 | `fe799297ed931ee0d1b69d8a7d4f57a7c22dd983` | `5f2a494cb3933ba5c9f6e61d814e8880cf354569` |
| 1.4.11 | `da426b23c64f3a66ae2b389d2db8f23489736bf9` | `9f143d69b6478b7c2af271e6b6c493d848b8bef7` |

Current Native Draft #18 `BellumCivileSaveDefiner.cs` blob is `5b6f5021cf694becd05eda7be87db0ed90c54793`. These are pinned source-era checkpoints, **not independently verified Nexus release archive binary contents**. See the older 304-path matrix in Native Draft PR #14 for the complete historical interval sequence.

## Demonstrated version-by-version delta

Official 1.4.9 → 1.4.10 adds exactly **one new saved-class registration**: `AsylumVisitRecord` ID **142** with a `Dictionary<string, AsylumVisitRecord>` container. It has 15 `SaveableField` IDs. Official 1.4.10 → 1.4.11 adds exactly **two new saved-class registrations**: `LordshipCommandTransferRecord` ID **143** and `RetainerIndentureRecord` ID **144**, each with four saved field IDs and corresponding list containers. The additions are cumulative; 1.4.11 does not remove 142.

Earlier, official 1.4.9 already included `PersonalLordshipRecord` ID **138** (fields 1–10), `LordshipAppointmentRecord` ID **139** (1–7), `LordshipIncomeCredit` ID **140** (1–4) and `TitleAcquiredMapNotification` ID **141** (fields 10–15). These four have not entered our current Native stack.

**Critical stale-inventory correction:** the original P0-02 table in the 304-file matrix was computed against earlier Native Draft PR #13 and identified eight missing save classes, including `CivilWarGraceRecord` ID 136. **P0-04 Native Draft PR #15 added 136**, and it remains in Draft PR #18. Current missing count relative to official 1.4.11 is therefore **seven**, not eight. `RestoredRealmCreationRecord` ID 137 already exists in our staged tree.

Our current staged registry has **137 class+enum definitions / 99 container declarations**, versus official 1.4.11 **144 class+enum definitions / 106 containers**. The seven missing registrations are exactly:
- 138: `PersonalLordshipRecord` — `List<PersonalLordshipRecord>`;
- 139: `LordshipAppointmentRecord` — `List<LordshipAppointmentRecord>`;
- 140: `LordshipIncomeCredit` — `List<LordshipIncomeCredit>`;
- 141: `TitleAcquiredMapNotification` — `List<TitleAcquiredMapNotification>`;
- 142: `AsylumVisitRecord` — `Dictionary<string, AsylumVisitRecord>`;
- 143: `LordshipCommandTransferRecord` — `List<LordshipCommandTransferRecord>`;
- 144: `RetainerIndentureRecord` — `List<RetainerIndentureRecord>`.

No duplicate registered numeric class/enum IDs were found in the six checked source checkpoints (custom main, PR #13, PR #18, official 1.4.9, 1.4.10, 1.4.11). This is a **source-registry check, not a successful save/load test**. The 1.4.5† → 1.4.9 functionality remains subject to the separate checkpoint and caller audits.

## Owners, concrete call chains and blast radius

### ID 142 — exile asylum (added in official 1.4.10)

Official `Behaviors/ExiledClanRecoveryBehavior.cs::RegisterEvents/SyncData` calls `RegisterAsylumDialogues`, `ProcessAsylumVisits`, `OnAsylumTick` and `SyncAsylumVisits`. Official `Behaviors/ExileAsylumVisits.cs` owns `_asylumVisits`, saved as `BellumCivile_AsylumVisits`; `TryCreateAsylumVisit` → `PlaceAsylumGuest` teleports/holds the guest and may place its party in a settlement; `CompleteAsylumAdmission` executes `ChangeKingdomAction.ApplyByJoinToKingdom`, changes relations and can award a promised village via `LordshipBehavior.TryGrantVassal`.

**Current Draft #18** has the earlier `Behaviors/ExiledClanRecoveryBehavior.cs` with a preexisting immediate asylum-request flow but **does not contain** `AsylumVisitRecord.cs` or `Behaviors/ExileAsylumVisits.cs`. This is a **behavioral migration**, not a missing serializer line. Potential neighbors: pending player requests, in-flight exile recovery, caravan/party placement, village grant, old save with legacy asylum keys, duplicate invitation/acceptance and foreign kingdom state.

### IDs 138–141 and 143–144 — lordship, income, title notices, command, retainers

Official `SubModule.cs` registers `LordshipBehavior` and `TitleAcquisitionBehavior`. `Behaviors/LordshipBehavior.cs::SyncData` persists `BellumCivile_PersonalLordships`, `BellumCivile_LordshipAppointments`, `BellumCivile_LordshipCommandTransfers`, `BellumCivile_RetainerIndentures`, and `BellumCivile_LordshipIncomeCredits`; source owners span `PersonalLordshipRecord.cs`, `Behaviors/VassalLordships.cs`, `Behaviors/LordshipCommandTransfers.cs` and `Behaviors/RetainerIndentures.cs`. `TitleAcquiredMapNotification.cs` is owned by the title-acquisition notification path, not by our existing Bellum Bridge `kingdom_created` event.

`Behaviors/LordshipCommandTransfers.cs` consults `ExiledClanRecoveryBehavior.IsAwaitingAsylum`, replaces a party leader, may teleport a replacement and transfer gold. `Behaviors/RetainerIndentures.cs::TrySignIndenture` charges gold and persists a renewable, timed retainer agreement. `Behaviors/VassalLordships.cs::TryGrantVassal` stores grants, changes relations and calls the title-notice path.

**Current Draft #18** does not contain `Behaviors/LordshipBehavior.cs`, `PersonalLordshipRecord.cs`, `Behaviors/LordshipCommandTransfers.cs`, `Behaviors/RetainerIndentures.cs`, `RetainerIndentureRecord.cs` or `TitleAcquiredMapNotification.cs`. Current `SubModule.cs` does not register the two official behavior owners. This subsystem touches party commands, finances, titles, governor/retirement state, villages, and the asylum path; importing only the seven types would create a false sense of compatibility.

## Surgical boundary for P0-08

**ROOT CAUSE:** upstream added serialized *feature-owned* types across 1.4.8–1.4.11; an old source matrix still describes the PR #13 state and no longer accurately reflects staged PR #18. Cross-version features are not yet present in the current fork. This is a source-proven parity/coverage gap, **not** proof of corrupted user saves.

**TOUCH:** this new document only, added on a dedicated audit branch stacked upon PR #18. No production file or test executable is changed.

**DO NOT TOUCH:** Native `BellumCivileSaveDefiner.cs`, `SubModule.cs`, `ExiledClanRecoveryBehavior.cs`, `FactionManagerBehavior.cs`, `CivilWarResolutionBehavior.cs`, party/finance/title code, AI Influence external diplomacy and Bellum War & Peace Revamp OFF, Bellum Bridge, Relay, Relay Bridge, old save files or defaults. Avoid standalone registration of 138–144.

**MUST FIX (future separate feature-owned stages):** decide full owner-feature import vs explicit, evidenced deferral for 138–144, check original author defaults and all intermediate corrections, and establish old-save-safe initial values and actual feature functionality. Document scope before any production code change.

**MUST NOT CHANGE:** valid old-snapshot load, existing asylum request/decision behavior until its owner migration is explicitly designed, civil-war Grace 136, restored realm 137, all earlier class IDs/field IDs, existing Bridge protocols, notification uniqueness, party command and financial semantics, and AII foreign war/peace ownership.

### Regression contract BEFORE any later implementation

**Positive:** new game can persist/load each newly activated owner record, including 142 pending asylum visit, 143 party command transfer and 144 retainer renewal; correct saved keys and field IDs; proper dialogue/state/event receipt; no incomplete half-commit after interrupted game/save.

**Neighbors / negatives:** older 1.4.5-derived save without these records loads unchanged and initializes safe empty owner state; old immediate asylum flow is not silently duplicated or suppressed; no duplicate finance, title, party-transfer, kingdom-created or Bellum Bridge event; missed/expired asylum is not accepted; wrong clan cannot gain command or gold; P0-04 Grace and P1-01A–F recovery/succession still work; AII Revamp OFF retains external diplomacy.

**Verify logs / game after a future implementation:** no `SaveDefiner` unknown-class/duplicate-ID or missing-container errors, no repeated asylum invitation after reload, no duplicate title notification, retainer fee, transfer/teleport or income credit; old-save before/after state and present/absent save keys compare. Exact log tags for these owner paths must be sourced from code/runtime before claiming an expected literal string.

### Evidence and limits

- Direct GitHub file reads checked all six registry snapshots and the owning current/official source files; this document records the computed 137 → 144 class+enum and 99 → 106 container gaps.
- No source file modified, no PowerShell / .NET / game compilation, no CI, no copied-save load and no runtime observations. Static code presence or absent filenames are not complete ABI/game compatibility evidence.
- Original Native matrix [Draft PR #14](https://github.com/AIRebelRelay/BellumCivile/pull/14) still reports the **historical PR #13 statuses**. Do **not** overwrite that matrix's entire 304-row inventory based on this one subsystem check; link/update that row once a controlled reconciliation of the audit branch is planned.
- Future work may split into independent owner-specific stages (asylum vs lordship + title vs retainer/command). Do **not** mix them into a single blind multi-feature diff.

**STOP / go-no-go:** This stage documents the version-chain gap. It does not authorize mass source replacement, save-definer registration, production refactoring, merge to main or release. Remaining 1.4.9 → 1.4.10 → 1.4.11 repeated changes outside this schema family need independent comparison.
