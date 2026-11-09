# P0-14B — Native Bellum earlier 58-commit regression audit (READ-ONLY)

**Date:** 2026-11-09. **STATUS: SOURCE-LEVEL AUDIT COMPLETE / NO-GO MERGE OR RELEASE.** This is documentation, NOT an implementation, test-execution report or 1.4.11 parity certificate.

## Pinned git boundary and factual scope

- **Only Native Bellum:** `AIRebelRelay/BellumCivile`. Never confuse with Bellum Bridge `AIRebelRelay/Bannerlord2-AiInfluence-BellumCivile`, Relay Bridge or AI Rebel Relay. The Bridge issue [#96](https://github.com/AIRebelRelay/Bannerlord2-AiInfluence-BellumCivile/issues/96) is merely an external QA tracker.
- Native `main`: `71c7ab8b8b7a21fc2661f5f25e0a18d74b952ca7` (unchanged).
- **Review boundary:** `main` → Draft [#20](https://github.com/AIRebelRelay/BellumCivile/pull/20) `81f02cfdd6fdac9644f2846dff5af8ba35f9600e` = **58 first-parent historical ahead commits, 42 changed paths** (GitHub compare reports 58 ahead, 0 behind). These are the commits underneath Drafts #21–30; they are not the #21–30 diff.
- Combined candidate inspected for interaction with later Drafts: [#30](https://github.com/AIRebelRelay/BellumCivile/pull/30) `8c55c7c7f3b73db9eaef76cfa56d4256f16b1aa2`. The previous #21–29 audit and P0-14A test wiring are recorded on QA #96; they have not been merged.
- Historical PR topology matters: old #1 is already an ancestor; #8's RED test commit is in these 58; #7's guard was subsequently reincorporated in P0-07/#18. **PR #2–6 foreign war/peace branches diverge from this Native stack** (not included by PR number). Do not cherry-pick them as part of this audit; user's actual foreign war/peace ownership is through AI Influence with Bellum War & Peace Revamp configured OFF.

### Exact functional inventory for the 42 paths
- **P1-01B–F restored-realm/civil-war collapse:** persistent `RestoredRealmCreationRecord`, restored realm coordinator, orphan cleanup, collapse challenge claimant + de jure Crown receipts, staged clan transfers, saved event receipt, scoped faction membership protection. Touches shared `CivilWarResolutionBehavior`, `FactionManagerBehavior`, `CivilWarCollapseContinuation`, `CivilWarCrownTransfer`, `CivilWarParentDestructionPatch`, records and callers.
- **P0-04 Civil War Grace:** author-proven `CivilWarGrace.cs`/record, new save keys, added MCM slider and preset, initial one-year pacification, court/ideology/player/politics/civil-war admission and cooldown callbacks across many files.
- **P0-05–07 Crown transition/rebellion/succession:** deferred post-accession faction opportunities, proper incoming RulingClan snapshot, legal claim/crown gating, deferred challenge recovery after unsuccessful clan transfer, preservation of active collapse kingdom IDs.
- **P0-08–09:** two documents only, recording missing owner-bound 1.4.9→1.4.11 save schema and Asylum/Lordship migration blockers, **not implementation**.
- Existing nine `Tests/P004*`, `P005*`, `P006*`, `P101A*`–`P101F*` scripts are structural contracts and some isolated extracted-C# simulations. **They were not executed in this audit; these are not full game/save integration tests.**

## ROOT CAUSE / TOUCH / DO NOT TOUCH

**ROOT CAUSE:** Review gap: the 58 earlier unmerged source commits had not been collectively audited after #21–30. No specific live crash is demonstrated by this fact. Shared ownership and save migration are the high-risk surfaces.

**TOUCH:** This one new docs report, and only a QA tracker comment. No source or test modifications in P0-14B.

**DO NOT TOUCH:** All production code, shared scheduling, saved data/schema, MCM settings/defaults, Harmony target owners, Bridge/Relay projects, existing game files, source branch HEADs, CI, DLL, `main` or releases. In particular no speculative patch to the shared `FactionManagerBehavior`/Civil War restoration mechanism.

**MUST FIX (audit deliverable):** correctly inventory 58/42 history and adjacent branch topology; trace actual call chains; enumerate positive/negative regression gates and next stages. **MUST NOT CHANGE:** existing legitimate war/peace ownership, working court/Crown features, pending saves and event cardinality.

## Evidence from current final staged source

**36/36 independent structural contract assertions PASS** (connector-based source inspection, no test execution) covering:
1. Save definer: 101 class IDs and 36 enum IDs (137 total class+enum); no duplicate class IDs; exactly two new classes relative to `main`: `CivilWarGraceRecord` ID **136** and `RestoredRealmCreationRecord` ID **137**; no existing class IDs changed. Explicit new list containers. `CivilWarCollapseRecord.CreatedNotified` is append-only **SaveableField(21)** (old fields 1–20 unchanged). Restored record has fields 1–17, Grace fields 1–6. Missing 138–144 intentionally NOT registered without their actual feature owners.
2. Save owners/initializers: `CivilWarResolutionBehavior.SyncData` persists `BC_RestoredRealmCreations` with null-to-empty fallback; `FactionManagerBehavior.SyncData` persists Grace and `BellumCivile_PendingSuccessionOpportunities`. Grace also persists initial game grace state, and record `Realms` lists are initialized.
3. Restored creation: source snapshots `Owner`, `Houses`, `ParentHouses`, external wars, and chosen successor ID before lifecycle. `_preparingRestoredCreations` prevents callback recursion; incomplete clan/parent transfer returns without marking `Ready`; valid ruling clan + sovereign title receipt are checked before `OnKingdomCreated`. `CreatedNotified=true` is recorded **before** dispatch to avoid duplicate callback delivery. `OnHourlyTick` retries pending saved restores.
4. Collapse: saved stages 0–4 with `_resumingCollapses` guard; Stage 2 aborts on failed winner/parent clan moves or war/Crown transfer; Stage 3 legal claimant/crown receipt check; Stage 4 saved `CreatedNotified` before creation event; no Stage 4 completion without Crown; expected eventual `Civil-war collapse completed` log. Orphan retainer checks valid alternate successor and rejects active ruler, fiefs, transfers, owner states and title claims.
5. Shared faction owner boundary: `OnClanChangedKingdom` exempts only journal-owned **active** winning coalition member transfers (Stage 2) or recorded restoration-household transfers (in `_preparingRestoredCreations`); ordinary defections otherwise fall through to original handling. RulingClanChanged callback now uses actual `kingdom.RulingClan` rather than treating event's old clan as incoming. `ProcessSuccessionOpportunities` is **hourly** and waits for valid Crown, no pending accession, no realm transfer/deposition, and no unresolved king-election decision. The original inline faction check is relocated to `FactionSuccessionSafety.cs`, not silently deleted.
6. Grace: on new campaign only `ArmInitialCivilWarGrace` sets one game-year protection, independent of MCM. Per completed civil war, `CivilWarGraceYears` **defaults to 2 game years**, range 0–5, and the period is snapshotted at settlement. The initial year persists even at slider 0; this is an **upstream author design**, with potential impact on user-preferred *controlled chaos*, not a proven defect. `PlayerLandedSecessionPatch` checks Grace for keep-fiefs secession **before** the `IsRevampEnabled()` OFF/vanilla fallback. This internal-policy gate thus remains even when Bellum external War & Peace Revamp is OFF. Verify intended RP behavior, do not silently remove it.
7. Three shared source families imported from author 1.4.11 are blob-exact: `CivilWarGrace.cs`/record, `FactionSuccessionSafety.cs`, `CivilWarCollapseContinuation.cs`/record, `RestoredRealmOrphanRecovery.cs`/record. `RestoredRealmRecovery.cs` differs from author by **only five additive lines**, the surgical `OwnsRestoredHouseholdTransfer` predicate used by custom faction manager (P1-01F); no whole-file fallback replacement.

**Evidence limit:** 36/36 textual/invariant checks are NOT proof of runtime flow, ABI or cross-mod Harmony compatibility. No PowerShell run, C# compiler, source scripts, real executable test, CI, Bannerlord launch, saved-game load, or DLL happened.

## Findings and prioritized risks

| Rank | Risk / reason | Regression contract still required |
| --- | --- | --- |
| **BLOCKING** | **No compiled/live/save-load evidence** for the 58-commit owner changes; source-only tests, including isolated Add-Type extracts, do not exercise the full TaleWorlds campaign. | Stage 0–4 interruption, pre/post native Crown transfer, owner membership cleanup, save-load, duplicate `OnKingdomCreated`, kingdom ID reuse, old-save empty journal, faction split, foreign war snapshot preservation. |
| **HIGH** | Shared faction/kingdom owners modified: `TransferClansToKingdom` changed void→bool; `OnRulingClanChanged` reconciliation moved to `FactionSuccessionSafety` and delayed, and old synchronous behavior removed from `FactionManagerBehavior`. Source callers were traced but actual gameplay regressions not tested. | Wrong incoming ruler, valid/invalid king elections, unrelated faction defection, active rebel shell, erroneous vanishing factions, zero/duplicate new Crown ultimatum, noble clan transfer failure, player-case callback after delayed prompt. |
| **HIGH** | New saved ID 136/137, collapse receipt field21, persisted old/new Grace and pending succession dictionaries; old saves have missing keys/default values. Schema uniqueness statically confirmed, not actual loader behavior. | Load old saved campaign and partial restoration saves across each stage, verify journal defaulting, no duplicate relation/war/event credits, no restored shell corruption. |
| **BALANCE / NOT A BUG** | Author's **2-year postwar + 1-year initial** civil-war grace may suppress controlled-chaos friction, even when postwar slider is 0. Grace also gates keep-fiefs player secession with Bellum War/Peace OFF. | Observe a fresh campaign, previously saved campaign, postwar expiry, treason/committed armed challenges, Court crisis behavior, player land-secession semantics before tuning. |
| **KNOWN FEATURE GAP** | Per [P0-08](https://github.com/AIRebelRelay/BellumCivile/pull/19) and [P0-09](https://github.com/AIRebelRelay/BellumCivile/pull/20), 1.4.11 Lordship/Asylum save types **138–144** and feature owners are missing; [P0-10](https://github.com/AIRebelRelay/BellumCivile/pull/21) confirms source/Harmony risk. Clan Household remains tracked separately in [#104](https://github.com/AIRebelRelay/Bannerlord2-AiInfluence-BellumCivile/issues/104). | Do **not** infer full 1.4.11 parity; any future owner-port requires separate call-graph/ABI audit, user-approved scoped implementation and RED-first runtime-safe tests. |

## Proposed next stage (separate; do not bundle code in this PR)

**P0-14C: executable recovery/Grace regressions** before additional production porting or any merge. Analyze original owner's compiled source tests versus our harness without wholesale transplant; define test-only minimum diff after call-graph. Priority ordered:
1. P1-01 restoration/collapse: failed clan transfer, interrupted/callback exception, old-save restore at stages 0/1/2/3/4, old-save absent journal, at-most-once creation event, valid Crown and all factions, unrelated clans not locked.
2. P0-04–07: initial year, postwar two years and zero setting (independent initial protection), pending accession, incoming-ruler snapshot, Grace exceptions, WPR OFF + player secession, claimant/tribunal Crown receipt, legitimate reattempt.
3. Re-run all previously staged P0-11–14 tests plus source scripts, then full build and actual game log/save once Windows test environment exists. Do not ask user for local tests while unavailable.

**Required live evidence:**
- Expected success: `Civil-war collapse completed; parent=...; successor=...`, `Civil-war grace settled; faction=...; realms=...; until=...`, restored realm physically owns required Crown and houses, exactly one kingdom-created notice, only valid protected clans preserved.
- Warnings requiring diagnosis: repeated `Restored realm creation deferred; ...` or `Civil-war collapse deferred; ...` with no eventual success, premature `Retired orphaned empty restored realm; ...`, repeated/dropped event delivery, wrong house promoted, dangling kingdom/party, extra claim, foreign war loss, stuck Grace/Court suppression, or `Failed to apply Harmony patch`.
- A successful source audit or green compilation **cannot** substitute for real game behavior.

**Decision: NO-GO MERGE/RELEASE.** The current stage is complete as read-only analysis. We know where to test; we do not have runtime proof and will not perform speculative code changes or CI without a separate qualified stage.
