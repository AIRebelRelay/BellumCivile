# Stage 7 result — NPC Crown ticket attached to the native Bellum 1.4.5 court docket
Date: 2026-10-21 | **PASS: isolated regression CI only. NOT cleared for main, game, or Bridge.**

## Pinned versions and git refs
- Game target: Bannerlord **1.4.8**, Bellum **1.4.5 stable**, upstream base `b1d9a4e8fb74d4f9dd045793c156abeac6f9f4eb`.
- Bellum fork `main` unchanged: `b1d9a4e8fb74d4f9dd045793c156abeac6f9f4eb`.
- Stage 6 baseline in feature branch: `57b39420e03980fed8092d3e39716a914679d3f5`.
- Stage 7 implementation: `f760eabfbbb6810c9fe69e39874a2484f3c9c025`.
- Isolation/safe-build follow-up: `0122745e391ab18af1b04d28589e1934aa5e681b`.
- Separate [Stage 7 pre-code regression contract](./AI_INFLUENCE_NPC_CROWN_STAGE7_CONTRACT.md).
- Verified [Stage 7 CI run 39574798449](https://github.com/AIRebelRelay/BellumCivile/actions/runs/39574798449): **success**, including Stage 5 baseline, Stage 6 contract & stub runtime, Bellum Court Executive Scheduler, Stage 7 source & stub runtime, and actual MSBuild compile-item evaluation.

## ROOT CAUSE addressed (bounded)
Stage 6 tickets were persisted but inert. Bellum Crown agendas in 1.4.5 are selected in `CourtAgendaBehavior.OpenTerm`, with higher-priority native decree, Royal Peace and council vacancy rules. Directly initiating a vote in Bridge or intercepting these schedulers via Harmony would violate Bellum ownership. A mere `assigned=true` is insufficient: native systems may subsequently replace unopened agendas.

## Implemented behavior
`OpenTerm` invokes `TryAttachStagedNpcTreason(agenda, context)` exactly once on a **fresh, empty NPC Crown agenda** and only after `AssignPriorityDecree`, `AssignPriorityRoyalPeace`, and `MaintainCouncilVacancyPriority`. If no ticket fits, normal automatic objective selection continues unchanged. It picks the oldest ticket, with ordinal intent-id tie breaking, requires the same current NPC ruling clan and legally eligible target, MCM toggle enabled, and `CourtExecutiveObjectiveSource.EvaluateCandidate(...).Selectable && .Viable`. It applies native `CourtObjectiveChoice`, marks `Announced`, and calls the existing `NotifyAgenda`. It does **NOT** call `TryPay`, `FileAgendaTreasonVote`, `QueueExpulsionVote`, or `ExpelClanFromKingdomDecision` — these belong to Bellum's later `AdvanceExecutive`.

A second existing SaveDefiner-supported `Dictionary<string,string>` tracks `externalIntentId -> CourtAgendaRecord.IntegrationId` under `BC_CourtNpcTreasonAgendaIds_v1`. The original `BC_CourtNpcTreasonIntents_v1` and ticket codec remain backward compatible. Read-only `GetNpcTreasonIntent` derives current `court_<state>` from Bellum's `IntegrationRecords()`. If a native priority replaces the objective, return `court_superseded`; if the linked court disappears, return `court_missing`. Neither is called a successful expulsion. Same-ID replay remains idempotent.

## TOUCH / audit of complete diff
Baseline compared: Stage 6 HEAD `57b39420`, feature Stage 7 HEAD `0122745e`; **13 scoped files total** (3 new commits, no behind commits):
- **Production (3 edited/new + .csproj):** `Behaviors/CourtAgendaBehavior.cs` (ONE new conditional, within NPC Crown branch); `Behaviors/CourtNpcTreasonAssignment.cs` (NEW local assignment/reconciliation); `Behaviors/CourtNpcTreasonIntents.cs` (second sync key + read-only current status); `NpcCrownTreasonIntentRecord.cs` (optional snapshot `CourtAgendaId`); `BellumCivile.csproj` (two exact test-stub exclusions).
- **Tests/build contract:** new `Tests/AiInfluenceNpcCrownStage7.Source.Tests.ps1`, `Tests/AiInfluenceNpcCrownStage7.Runtime.Tests.ps1`, `Tests/AiInfluenceNpcCrownStage7.Stubs.cs`, `Tests/AiInfluenceNpcCrownCompileItems.Tests.ps1`; updated Stage 6 test/stub, narrow workflow.
- **Documentation:** Stage 7 contract and this audit.
- **Not touched:** `CourtExecutiveAgendas.cs`, `IdeologyBehavior.cs`, `CourtObjectiveRecord.cs`, `CourtAgendaRecord.cs`, `BellumCivileSaveDefiner.cs`, `AdvanceExecutive`, `BellumIntegration.ApiVersion`, player Crown UI, Royal Peace, Relay, Relay Bridge, Bellum Bridge, any `main`.

### Important build regression caught by full audit
`BellumCivile.csproj` is SDK-style and includes all `*.cs` unless excluded. The Stage 6 test stub `Tests/AiInfluenceNpcCrownStage6.Stubs.cs` was unintentionally included in the **shipping compiler item set**, along with the new Stage 7 stub. Those fake TaleWorlds classes would conflict with real game DLLs. The fix adds **exact** `Compile Remove` elements for only these two tests. [Final CI](https://github.com/AIRebelRelay/BellumCivile/actions/runs/39574798449) calls `dotnet msbuild -getItem:Compile` to prove both are excluded while four production integration source files are included. These are source inclusion checks, **not a full DLL build**.

## Targeted regressions: observed CI
- **16 compiled mock runtime scenarios** passed: staging not a vote, exact assignment, stable linkage, same-ID dedup, live court-state tracking, native supersession, save/reload of both primitive maps, replay status, missing court fail-closed, unviable forecast, post-staging toggle-off, occupied Crown agenda, faction isolation, later free-slot assignment.
- **6 Stage 7 source contract checks** passed: priority order, fresh NPC Crown-only insertion, Bellum viability evaluator, dynamic court status, original Stage 6 codec/save key compatibility, no native execution shortcut.
- **6 compile-item checks** passed: two isolated stub exclusions and four production source inclusions.
- Existing Stage 5, Stage 6 and `CourtExecutiveScheduler.Tests.ps1` passed unchanged in intended functional contract.
- Test logs: `PASS STAGE7_NPC_CROWN_RUNTIME`, `STAGE7_NPC_CROWN_RUNTIME_PASS`, `STAGE7_NPC_CROWN_SOURCE_PASS`, `STAGE7_COMPILE_ITEMS_PASS`.

## Explicit remaining blockers
1. **NO full net472 compile with real Bannerlord 1.4.8 TaleWorlds DLLs yet.** CI compiled new Stage 7 adapter with stubs; MSBuild item evaluation confirms source inclusion, not API resolution against game.
2. **NO real Bannerlord save/load or live game Court term / player nomination regression yet.** Mock `IDataStore` is not Bannerlord serialization.
3. Stage 6's maximum 256 total / four per realm is a **bounded admission gate, not lifecycle cleanup**; old unassignable tickets can remain staged. Terminal expiry/rejection handling must be designed and tested separately *before connecting Bridge* to avoid invisible stale intentions.
4. Player-controlled treason follows a different Bellum path and is intentionally untouched. Bellum 1.3.1 Bridge ABI and Claim Feud Royal Peace P0 remain separate migration blockers.
5. Do not interpret `court_announced`, `court_deliberating` or `court_passed` as verified clan expulsion. Bellum remains authoritative.
6. No Bellum `main` merge, release package, new deployed DLL, or 0.8.6 Bridge patch occurred.

## Expected eventual live evidence, NOT YET OBSERVED
`AIInfluence NPC Crown intent staged; ... status=staged_not_scheduled` -> `AIInfluence NPC Crown intent attached; ... agenda=<id>; status=court_announced; vote_filed=false` -> Bellum native `Queued expulsion deliberation realm|target` only when scheduled -> `Court objective concluded; ... kind=treason; ... result=...`. Native decree/Royal Peace/council priority may replace agenda and then the API should report `court_superseded`.

**Stage 7 outcome:** implementation and audited isolated tests complete, but migration gate remains closed pending real-assembly compilation, native game validation, and a bounded ticket lifecycle.
