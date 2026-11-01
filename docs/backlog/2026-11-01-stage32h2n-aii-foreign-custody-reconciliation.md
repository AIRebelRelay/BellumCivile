# Stage32H2N — AII foreign-war custody score reconciliation with Revamp OFF

Date: 2026-11-01. **Internal Native Bellum stage only.** The owner requires one *integrated* alpha QA, not incremental DLL swaps. All executable tests and game/save cases are registered PENDING at [Bellum Bridge alpha QA #92](https://github.com/AIRebelRelay/Bannerlord2-AiInfluence-BellumCivile/issues/92). No live DLL/game/PowerShell tests were run; a source diff audit does not prove behavior.

## Source and ancestry

- Correct repo: **Native Bellum Civile** `AIRebelRelay/BellumCivile` (not either Bridge), branch `feature/stage32h2n-aii-foreign-custody-reconciliation-2026-11-01`, based on Native H2H `9d6c4c76c75bce3ac29ec3a422662b24ebee6e01`. RED-first regression commit `36b333951edf4ca25f3bfe03d8a1d4ba87fdcddd`, then one production commit `d2548494040e8682386b7bcb7be9ddf828ec6f84`.
- Planned Bellum Civile **mod** 1.4.5 targets Bannerlord **game** 1.4.8; current source manifest still says mod 1.4.4, separate alpha metadata gate.
- Bellum Bridge H2M candidate `AIRebelRelay/Bannerlord2-AiInfluence-BellumCivile@4ce6187aaf2f3c9c0f0510c144abd137fae33d19` registers an AII war ledger only after exact final verified AII war and is unchanged in this stage. Separate Relay Bridge and Relay backend unchanged.

## ROOT CAUSE (source demonstrated, runtime not yet confirmed)

Native `WarScoreBehavior.OnHeroPrisonerTaken` already permits crediting `WarScoreRecord.RecordPrisoner` under `Revamp OFF` when `HasOpenAiInfluenceForeignLedgers()`. It first filters by `IsAiInfluenceForeignLedger(war)`, so the score is **accounting only**.

The same Native behavior also subscribes `CampaignEvents.HeroPrisonerReleased` and `HeroKilledEvent` to `WarScoreCustody.RemoveCustodyScore`, and `OnDailyTick` / `OnSessionLaunched` to `WarScoreCustody.ReconcileReversibleScores`. Both methods previously began with an unconditional `!WarPeaceRevampBehavior.IsRevampEnabled() -> return`, which **skips reversing captured-prisoner score under Revamp OFF**. Consequently the AII ledger can keep stale prisoner-score credit after prisoner release/death or save load, even though fresh prisoner capture was counted. This is a source-proven asymmetric scoring condition, not yet a demonstrated gameplay incident.

## CHANGE BOUNDARY

**TOUCH:** ONLY Native `Behaviors/WarScoreCustody.cs`, with `RemoveCustodyScore` and `ReconcileReversibleScores`, plus RED source test `Tests/Stage32H2NAiiForeignCustody.Tests.ps1` and this Native handoff document.

**DO NOT TOUCH:** `WarScoreBehavior.OnHeroPrisonerTaken`, global `CanRegisterConflict`, `WarScoreAiInfluenceForeignLedger.cs`, `WarScoreRecord.cs`, existing SaveableFields, `CampaignEvents` subscriptions, `HostageCustodyGuard`, `RetainedTreatyPrisonerBehavior`, `CivilWarConflictBehavior`, `ClaimFeudWarBehavior`, diplomatic/treaty/forced peace routing, either Bridge, Relay, AI Influence 6.0.2 or Sidecar/ACK.

**MUST FIX:** With Revamp OFF **and** at least one open AII foreign ledger, the release/death event and daily/on-load custody reconciliation run **only for that ledger** and do not modify unrelated or internal war ledgers. Keep protected-hostage filter; do not create a new prisoner score when no matching opposing captor/victim exists.

**MUST NOT CHANGE:** With Revamp ON the existing all-war prisoner release/reconcile behavior and ClaimFeud objective reconciliation; with Revamp OFF and no open AII ledger retain old no-work early return. Preserve present `QueueTerminalWarScoreResolution` calls (already blocked by F1 `ShouldPreventAutonomousForeignResolution`, so no automatic Bellum peace) and all existing capture scores, caps and event metadata.

## Exact change

- Replace both old unconditional Revamp-only early-return guards with one local `bool revampEnabled = WarPeaceRevampBehavior.IsRevampEnabled();` and `(!revampEnabled && !HasOpenAiInfluenceForeignLedgers())` gate.
- In **each existing** `foreach (var war in GetActiveWars())`, add `if (!revampEnabled && !IsAiInfluenceForeignLedger(war)) continue;` **before any mutation**. This scopes OFF accounting to the exact opt-in ledger.
- Guard the existing trailing `ClaimFeudWarBehavior.ReconcileObjectiveControlScores()` with `if (revampEnabled)`; it must not suddenly run under OFF when an AII ledger exists.
- Keep the existing protected-hostage filter, release/death event callback, saved record, score/cap/event logic and terminal handling unchanged. No new Harmony.

## ALPHA REGRESSION CONTRACT (PENDING)

1. **H2N-01 OFF / active AII ledger:** capture prisoner → score credited; release → `PrisonerScore`/recorded custody decreases; `WarScoreEventType.PrisonerCustodyChanged` emitted, no `ForcedPeace`, no unsolicited `MakePeaceAction.Apply`.
2. **H2N-02 OFF / death:** captured prisoner dies → credit removed once; repeated release/death callbacks cause no double score/event.
3. **H2N-03 OFF / daily & save:** prisoner escaped/transferred/hostage became protected without release callback → daily `ReconcilePrisoners` and `OnSessionLaunched` match current actual captivity; source and sign correct, no stale saved credit on S1→S2→S1 reload.
4. **H2N-04 OFF / neighboring records:** an AII foreign ledger plus CivilWar, ClaimFeud, legacy/non-AII ForeignWar records; only AII ledger custody changes. ClaimFeud objective reconcile never runs in OFF.
5. **H2N-05 OFF / no AII ledger:** old early-return behavior remains, no expensive full hero scan, no other score mutation.
6. **H2N-06 ON:** normal Native CivilWar/ClaimFeud/ForeignWar custody updates and ClaimFeud objective reconciliation exactly as before, irrespective of AII ledger presence.
7. **H2N-07 protected hostage / mixed captures / net cap:** `HostageCustodyGuard.IsProtected` never credited by daily scan, opposite captors use signed scores, retained prisoner cap and `IsScoreTransferPending` protection unchanged.
8. **H2N-08 integration:** Native source `Tests/Stage32H2NAiiForeignCustody.Tests.ps1` and existing custody/war suite, full Native `net472` build against real Bannerlord 1.4.8 refs, Bellum Bridge H2L/H2M `Revamp OFF` treaty ownership and authoritative AII war outcome, save rollback and zero forced peace, full diff audit.

## Audit and game evidence

Authoring source audit **9/9 checks PASS** (2 intended paths at initial production commit: one C# file and one RED test, with no shared helper/saved changes). **Not an executable PASS.** After alpha compile, inspect saved `WarScoreRecord.PrisonerScore`, `Events` for `PrisonerCustodyChanged` and `ContextId=aii_foreign_ledger:v1:<exact EventId>`, compare pre/post prisoner status. A `War Score forced foreign peace`, unexpected `Foreign treaty parley queued` or forced `MakePeaceAction.Apply` remains a regression and release blocker. The `PrisonerCustodyChanged` item is **record state**, not a promised dedicated log line.

**Status:** narrow Native scoring regression source fixed; execution evidence and real 1.4.8 build/game/save are pending. This is NOT authorization to merge/release or mark P0 #89 closed.
