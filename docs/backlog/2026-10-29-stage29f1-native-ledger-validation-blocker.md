# BACKLOG — P0 validation blocker: Stage29F1 AII-owned foreign WarScore while Revamp OFF

**2026-10-29 | OPEN / UNVERIFIED | Native repo AIRebelRelay/BellumCivile.** GitHub Issues are **disabled** for this repo (API 410); this tracked document is the Native-side backlog. **No source/build/game patch is claimed resolved.**

## HEAD and ownership

- Native feature branch `feature/stage29f1-ai-owned-foreign-ledger-native-2026-10-29@37fb6db864771d208177f2fc1959d93b34876c98`, based on latest Native development `feature/stage27b-unified-native-leave-provenance-2026-10-26@64b0005ba36f0697ab667a3c29767ed78ce782fc`. Native main b1d9a4e is 56 commits behind base; **do not overwrite this source with main**.
- Bellum Bridge F2 audit `AIRebelRelay/Bannerlord2-AiInfluence-BellumCivile@046dde8b3e854b54e31b6374776eab948b40223b`, architecture [Stage29F2 gate](https://github.com/AIRebelRelay/Bannerlord2-AiInfluence-BellumCivile/blob/audit/stage29f2-w1-native-ledger-integration-gate-2026-10-29/docs/compatibility/bellum-145/2026-10-29-stage29f2-w1-native-ledger-integration-gate.md).
- Relay 5.1.9 Stage29C 4f8dd72cf85d947c1e5f198de9546f43bbdda5f8 is not part of the patch. **Bellum Bridge ≠ Relay Bridge**.

## ROOT CAUSE — coupled foreign tracking and automatic peace

- `Behaviors/WarScoreBehavior.cs` `OnWarDeclared→ShouldTrackForeignWar→CanRegisterConflict` prevents foreign registration with Bellum War & Peace Revamp OFF. The same shared helper determines `ShouldProcessWar`; unscoped change would enable all daily foreign scoring and terminal behavior. `OnDailyTick` invokes both active processing and queued terminal resolutions without a blanket OFF gate.
- `QueueTerminalWarScoreResolution` latches terminal state and score, and `ResolveQueuedTerminalWarScore` attempts Native `TryQueueAiParley` then, if rejected, **can fall through to `ResolveTerminalConflict(ForeignWar)→MakePeaceAction.Apply`**. Bridge suppressing autonomous Bellum AI parley does **not** suppress this direct forced peace. Saved OFF-mode historical ForeignWar terminal queues are also risky.
- `ReconcileExistingWars` could randomly infer attacker in old wars. Same WarScoreBehavior maintains CivilWar/ClaimFeud and recent Oct12 mercenary settlement crash fixes; no global semantics changes permitted.
- New explicit AII-only ledger source exists but .NET test, build, game proof not run. `TryRegisterAiInfluenceForeignWar(Kingdom,Kingdom,string,out string)` validates hostile world-state and unique form ID but **cannot authenticate a caller-provided AII EventId**. This is deliberately left to a future exact W1 Bridge source proof, which cannot proceed before this Native gate.

## Current source patch — NOT validated

**Existing Native F1 files (not changed by this backlog entry):**
- `Behaviors/WarScoreAiInfluenceForeignLedger.cs`: opt-in explicit fresh AII ForeignWar record with `ContextId=aii_foreign_ledger:v1:<eventId>`, an existing `WarScoreRecord.SaveableField(17)`; no save-schema extension, no automatic war event hook.
- `Behaviors/WarScoreBehavior.cs`: AII-owned ForeignWar scoring under OFF only, with foreign-only terminal prevention at **queue**, **resolver** and **direct final fallback**; preserved CivilWar/ClaimFeud paths and baseline global CanRegisterConflict.
- `Tests/SuccessionEngineHarness/AiInfluenceForeignLedgerTests.cs` and `Program.cs`: tests-first `--ai-foreign-ledger` and default-suite registration. First test commit 6dbef8b; restored legacy OFF regression before patch in 0b14a6d.
- [Native Stage29F1 handoff](https://github.com/AIRebelRelay/BellumCivile/blob/feature/stage29f1-ai-owned-foreign-ledger-native-2026-10-29/AI_INFLUENCE_STAGE29F1_FOREIGN_LEDGER_HANDOFF_2026-10-29.md). Static source audit 17/17 **does not count as a .NET or game pass**. No GitHub Actions runs on branch at audit date.

## Regression-first contract / exit criteria

- [ ] On Windows with actual Bannerlord 1.4.8 binaries, **compile Native Bellum net472** using correct `-p:GameFolder`.
- [ ] Run `Tests/SuccessionEngineHarness` `--ai-foreign-ledger`: exact AII provenance, null/form invalid, no unowned/CivilWar confusion, idempotency and saved ContextId, score=100 does **not** queue forced foreign peace, restored pending safe.
- [ ] Run `--civil-war-settlement`, `--client-liberation`, `--treaty-balance`; preserve Oct12 civil-war mercenary retry and claimant/feud outcomes. Tests must be read from current HEAD, never replay old source files.
- [ ] Live game after future Bridge F2: exact fresh W1 war with **final verified world state** registers one Native AII ledger; battle/raid/siege/prisoner/ticking score, true attacker/defender and ID survive save/reload. Unowned/old/vanilla/Court war cannot be silently backfilled, no duplicate.
- [ ] At terminal score/full occupation/landless, **never** `War Score forced foreign peace`, unsolicited `Foreign treaty parley queued` or Native `MakePeaceAction.Apply` while AII owns peace; preserve old player/vanilla/AII native peace and Native civil/claim-feud outcomes.
- [ ] A new ledger alone **does not** execute `MakeClientKingdom/ReleaseClientState`, and model term remains shadow-only `execution=false`. Real clientage requires later, separately consented Native treaty executor.
- [ ] Full post-fix diff audit: no unrelated default, global Revamp/CanRegisterConflict change, save type IDs, Court foreign pressure #85, AII influence temporary_free W1, 5.1.9 NanoGPT headers/session/TTS, Relay Bridge, client bloc or civil-realm updates.

**Critical future integration dependency:** when Native ledger exists under OFF, Bellum Bridge `BridgeV1BellumWarResolver` now resolves a formerly absent ForeignWar. `SourceBackedForeignTreaty.Core.RouteForeignPackage` gates acceptance against Revamp OFF but currently allows proposals/counters/rejections to reach an execution branch. F2 MUST add an early explicit OFF guard for **all four** treaty kinds without losing AII native peace fallback. That is a separate Bridge-stage change, not this Native validation patch.

## Expected/forbidden evidence

**Expected later:** `transaction_verified_war_started; final_world_state_verified=true` **before** `AII foreign War Score ledger registered; ... accounting_only=true; bellum_autonomous_peace=false`; exact AII event/provenance, 1 saved record, source-backed world-state and no double charges.

**Forbidden:** Native `War Score forced foreign peace`, unexpected `Foreign treaty parley queued`, duplicate/resurrected world war, missing AII native peace fallback.

**Status:** BLOCKED pending runtime tests/build and integrated alpha; no merge to main, release or installable DLL. Existing test code is present but **NOT PASS**.
