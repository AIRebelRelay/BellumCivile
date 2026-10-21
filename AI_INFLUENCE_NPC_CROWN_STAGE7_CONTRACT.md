# Stage 7 — Bind staged AI NPC treason intents to native Bellum Crown agendas
2026-10-21. Regression contract defined **before** production edit.
Target: Bannerlord 1.4.8; Bellum 1.4.5 stable pinned 1.4.5 SHA `b1d9a4e8fb74d4f9dd045793c156abeac6f9f4eb`.
Stage 6 branch HEAD `57b39420e03980fed8092d3e39716a914679d3f5`.
Work only on `feature/1.4.5-ai-influence-npc-crown`. No merge to main or Relay/Bridge patch.

## Root cause / chain
`BellumIntegration.TryStageNpcTreasonIntent` stores a `staged_not_scheduled` idempotent ticket, but `CourtAgendaBehavior.OpenTerm` ignores it. Bellum owns Crown agenda slot allocation: `OpenCrownTerm` -> existing filed/unopened preserve -> `AssignPriorityDecree` -> `AssignPriorityRoyalPeace` -> `MaintainCouncilVacancyPriority` -> `_objectiveSelector.SelectBatch` -> later `AdvanceExecutive` -> `FileAgendaTreasonVote`.
Daily `ScanDecreeCases` or `MaintainCouncilVacancyPriority` can **subsequently replace** an unopened ordinary Crown agenda; the external ticket must reflect native removal/supersession rather than pretending execution.

## TOUCH
- `Behaviors/CourtAgendaBehavior.cs`: one conditional at NPC-only fresh Crown slot, after native priority guards, before automatic selector.
- `Behaviors/CourtNpcTreasonAssignment.cs` NEW: scoped assignment, read-only status linked to Bellum's existing `CourtAgendaRecord.IntegrationId`; persist just a `Dictionary<string,string>` intent→agenda ID.
- `Behaviors/CourtNpcTreasonIntents.cs`: add second dictionary save key and delegate existing getter/replay to status reconciliation.
- `NpcCrownTreasonIntentRecord.cs`: add nullable `CourtAgendaId` to immutable snapshot via optional constructor arg, backwards compatible with Stage 6 codec.
- Targeted Stage7 isolated compiled test and source contract; extend Stage6 test stubs only as necessary to compile new same production files. Update *existing* narrow CI workflow. This audit report.

## DO NOT TOUCH
- `CourtExecutiveAgendas.cs`, `IdeologyBehavior.cs`, `CourtExecutiveObjectiveSource.cs`, `CourtAgendaRecord.cs`, `BellumCivileSaveDefiner.cs`, `AdvanceExecutive`, `BellumIntegration.ApiVersion`, Harmony, existing automatic treason MCM defaults, player Crown direct filing.
- Other repositories, Bellum main, actual saves.

## MUST FIX / MUST NOT CHANGE
- Accept precisely one earliest valid staged NPC intent for a **new unoccupied Crown slot** (not a faction agenda), after decree/Royal Peace/council reservations and before random automatic selection.
- Native `CourtExecutiveObjectiveSource.EvaluateCandidate` **must be viable and selectable**: no forced agenda, no direct queue, no influence charged before Bellum `AdvanceExecutive`.
- Bind intent ID permanently to `CourtAgendaRecord.IntegrationId`, persist mapping across save/load. Existing Stage6 primitive codec v1 stays accepted byte for byte; identity/replay semantics unchanged.
- The snapshot reads actual linked Court agenda status (`court_announced`, `court_deliberating`, `court_voting`, `court_passed`, etc.). If agenda gone/replaced return explicit `court_missing`/`court_superseded` (never completed). No second filing from replay or after supersession.
- Retain native future higher-priority takeover behavior. No new periodic scheduler or disabled-toggle bypass.

## Regression cases, before code
1. Valid NPC Crown, newly free term, viable exact target: one `CourtExecutiveRules.Treason` motion and one bound ID; announce without immediate expulsion.
2. Source evaluation unviable / missing target / player ruler / disabled toggle: no attachment and native automatic selector unchanged.
3. Another open/filed Crown motion, decree, royal peace, council vacancy: no takeover.
4. Same external ID replay; other target collision: no duplicate.
5. Subsequent native takeover modifies agenda: ticket reports `court_superseded`; missing agenda reports `court_missing`; no retry.
6. Persist and reload both Stage6 ticket map and Stage7 agenda-id mapping: existing attachment survives; no extra filing.
7. Player direct Crown vote remains immediate if legal, Bellum normal `AdvanceExecutive` defers NPC vote and charges only at its native term date.
8. Source regression Stage5 and Stage6 and upstream `CourtExecutiveScheduler.Tests.ps1` remain passing.
9. Pure synthetic test-only Bellum stubs MAY compile adapter but do not establish real game build/save compatibility.
10. No MCM default change, new SaveDefiner IDs, broad Harmony, artificial `ExpelClanFromKingdomDecision` or native direct execution.

## Expected evidence
- CI `PASS STAGE7_NPC_CROWN_RUNTIME` + Stage5/6 existing tests.
- On actual game after external API later integrated: `AIInfluence NPC Crown intent attached; ... agenda=...; status=court_announced`; Bellum `Court agenda announced`, then `Queued expulsion deliberation` after its native session. This stage DOES NOT connect Bridge.
- Missing: real Bannerlord 1.4.8 compile, game save/reload, Bellum runtime, and ticket expiry/cleanup. Do not merge before those pass. Missing ticket expiry is explicitly **out of Stage 7**; avoid Bridge hookup until resolved.
