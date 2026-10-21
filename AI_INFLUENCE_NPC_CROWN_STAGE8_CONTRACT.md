# Stage 8 — bounded lifecycle for unassigned NPC treason intents (regression-first)

2026-10-21. Target Bannerlord 1.4.8, Bellum Civile 1.4.5 (upstream base b1d9a4e8fb74d4f9dd045793c156abeac6f9f4eb).
Before editing: feature HEAD `49c024ae690c25abf5b162984f4f2742b85dd3db`. Source: Stage 7 audit in this branch.
**Stage scope: unassigned pending tickets ONLY.** No modifications to native Court decision lifecycle.

## ROOT CAUSE
1. Stage 6 admission counts *all recorded tickets* against four-per-realm, including IDs already attached to Court Agenda or historically terminal.
2. Stage 7 only selects a ticket if its ruler/target still match, silently leaving invalid, obsolete, or forever unviable unassigned tickets in staging.
3. Original v1 codec only represents `staged_not_scheduled`; there is no persisted terminal tombstone state to support safe replay and read-only follow-up.
4. Stage 7 attached tickets already have a native Bellum agenda record and must **not** be revoked or expired by an independent scheduler.

## TOUCH / precise boundary
- NEW `Behaviors/CourtNpcTreasonLifecycle.cs`: Bellum-owned *read-only evaluation of unassigned tickets*, daily maintenance of terminal tombstones, active queue count; no direct gameplay mutations.
- `Behaviors/CourtNpcTreasonIntents.cs`: serialize one new existing-type `Dictionary<string,string>` for terminal state, route status/duplicate replay, count only unassigned pending for per-realm capacity.
- `Behaviors/CourtNpcTreasonAssignment.cs`: exclude closed IDs from assignment.
- `Behaviors/CourtAgendaBehavior.cs`: one daily-gated lifecycle call at existing campaign Tick after required behavior checks.
- Narrow integration stub tests, source audit, CI workflow.
- NO change to `NpcCrownTreasonIntentRecord.cs` v1 codec bytes, `CourtAgendaRecord.cs`, `BellumCivileSaveDefiner.cs`, or saved native agenda identity.

## DO NOT TOUCH
Bellum player Crown, NPC automatic decree/Royal Peace/council priorities, shared schedulers outside the one call site, native voting, `AdvanceExecutive`, `IdeologyBehavior`, Bellum `main`, AI Influence / Relay / Bellum Bridge / Relay Bridge. No Harmony. No new game-save type registrations or MCM defaults.

## MUST FIX
- For staged-unassigned tickets only, maintain terminal states: `cancelled_realm_invalid`, `cancelled_ruler_changed`, `cancelled_target_invalid`, `cancelled_automatic_disabled`, `expired_unassigned`. Preserve same external intent ID as a permanently idempotent tombstone (no retry or silent recreation).
- A previously staged, terminal ID returns `Accepted=false` with exact reason/status; current snapshot provides the reason; a collision with another realm/ruler/target remains `external_intent_id_collision`.
- Choose explicit pending expiry threshold: **max(three Bannerlord years, two current Bellum court terms)** in campaign days. Evaluate only for still-unassigned tickets, never terminate an attached native proceeding. MCM term length changes affect threshold for unassigned tickets only; document this known policy.
- Free per-realm four-ticket capacity as soon as the ticket is attached OR terminal, while preserving historical IDs for replay. Maintain global *256-ID lifetime hard limit* and reject new IDs at it rather than evicting historical tombstones; this is a separate scaling limit, intentionally not hidden by this stage.
- One read-only status API; maintenance runs no more than once per in-game day inside Bellum's existing Tick and never calls native scheduling, vote, influence or clan removal.

## MUST NOT CHANGE and regression contract (before code)
1. Positive: 4 fresh staged tickets fill the staging window; 5th rejected.
2. Positive: after one ticket becomes attached to a native Court Agenda, one additional ticket can stage without breaking its ID/status/agenda.
3. Negative: expired, removed-target, changed-ruler, disabled-toggle, eliminated realm tickets terminalize with correct reason and never attach.
4. Positive: closed ticket survives serialization roundtrip, readable through `GetNpcTreasonIntent`, and replay returns terminal refusal with the same original scope and time.
5. Negative: replaying historical ID for a different target still fails as collision; different ID can stage when active queue has room.
6. Neighbor: attached `court_announced` and `court_deliberating` stay under Bellum native ownership even past the staging expiry; no extra voting, refund or timeout from integration.
7. Negative: missing/corrupt history entry fails closed; no runaway repeated logging of terminal state (write once).
8. Neighbor: Stage5 baseline, Stage6/7 compiled stub tests, CourtExecutiveScheduler tests and CompileItems audit pass, with no shipping stubs included.
9. Game compile using actual Bannerlord 1.4.8 assemblies and game save/load are **separate gates**. This stage is not a release approval.

## Expected logs/evidence
`AIInfluence NPC Crown intent closed; id=...; status=expired_unassigned|cancelled_ruler_changed|...` exactly once per closed ticket.
`PASS STAGE8_NPC_CROWN_RUNTIME`; `STAGE8_NPC_CROWN_RUNTIME_PASS`; former Stage5-7 tests unchanged.
In the future live game, attached ticket logs still lead to Bellum native `Queued expulsion deliberation`, never a bridge-side direct expulsion.

## Exclusions / architectural note
The global 256 total historical-ID cap deliberately remains (fail closed); permanently idempotent history cannot be automatically pruned without a defined durable replay window. If the game eventually hits it, design an explicit bounded dedup/tombstone policy as a separate stage; do not quietly delete historical IDs here. Stage 8 does NOT claim to resolve all Bellum 1.4.5 conflicts or the separate Royal Peace P0.
