# Stage 8 — terminal lifecycle for unassigned NPC Crown treason intents
**Date:** 2026-10-21. **Result:** PASS in isolated regression CI; native Bannerlord compile and game/save validation NOT performed. Do not merge to main, install a DLL, or connect the Bridge.

## Pinned versions
Bannerlord 1.4.8; upstream Bellum Civile 1.4.5 stable at `b1d9a4e8fb74d4f9dd045793c156abeac6f9f4eb`.
Feature branch Stage 7 starting HEAD: `49c024ae690c25abf5b162984f4f2742b85dd3db`.
Stage 8 code commit: `77d03e97a26c3a03f89d7661316cda46714c4a41`; final passing tested HEAD `3a1fcd06bfb2575a4545ab044da8fd37a41877d5`.
Permanent [Stage 8 regression contract](./AI_INFLUENCE_NPC_CROWN_STAGE8_CONTRACT.md), written and committed **before implementation**.

## ROOT CAUSE
The old four-per-realm cap counted all IDs, including already assigned Court Agenda IDs; invalid, expired and stale unassigned requests never became terminal. Simply evicting IDs would have broken idempotency and allowed duplicate political actions. Native attached Court agendas cannot be canceled by external lifecycle cleanup.

## TOUCH
- NEW `Behaviors/CourtNpcTreasonLifecycle.cs` — maintains unassigned pending requests, at most once per in-game day, using existing Bellum Tick and external-ID tombstones.
- `Behaviors/CourtAgendaBehavior.cs` — exactly ONE inserted `MaintainNpcTreasonLifecycle();` after behavior-null checks, before realm court processing.
- `Behaviors/CourtNpcTreasonIntents.cs` — persists `BC_CourtNpcTreasonClosures_v1` using existing `Dictionary<string,string>` SaveDefiner type, returns terminal status on replay and counts only still-unassigned pending tickets for per-realm cap.
- `Behaviors/CourtNpcTreasonAssignment.cs` — reports terminal status in snapshots and excludes closed tickets from future assignment.
- NEW Stage 8 regression scripts and the narrowly expanded test workflow; existing Stage 6/7 compiled mock tests include new lifecycle source; stub gains fake campaign day/year and Kingdom.All; compile-item test includes new production source.
- No changes in `NpcCrownTreasonIntentRecord.cs` or its v1 payload, Bellum native SaveDefiner IDs, original Crown scheduling/selection/filing code, automatic-treason MCM defaults, player actions, Harmony or any other repository.

## Semantics
- Hard terminal reasons for **unassigned** intents: `cancelled_realm_invalid`, `cancelled_ruler_changed`, `cancelled_target_invalid`, `cancelled_automatic_disabled`, `expired_unassigned`.
- Expiry threshold for an unassigned intent is `max(3 * Bannerlord DaysInYear, 2 * Bellum CourtTermDays)`, measured in campaign days after submission. Because Bellum's court-term setting is configurable, modifying that setting may change a pending request's deadline. This is documented intentional policy, not an immutable admission-time deadline.
- Terminal reasons live in a separate saved primitive dictionary keyed by original external intent ID; the original ticket identity and submitted day are preserved for lookup, and replay is refused, never recreated. Unknown closure values fail closed as `corrupt_terminal_state`.
- Tickets linked to a Bellum Court Agenda are **never terminalized by Stage 8**, even if the ruler subsequently changes or staging-age threshold is passed. Bellum owns its own pending vote lifecycle and `GetNpcTreasonIntent` still reports the live linked agenda state.
- Four-per-realm admission now counts only currently **unassigned, nonterminal** tickets. Attached tickets no longer permanently block new staging. The original 256 historical-ID cap is **unchanged and absolute**, intentionally rejecting additional new IDs once reached; no tombstone garbage collection or ID recycling occurs.
- Same-day requests retain deterministic `SubmittedDay`, then ordinal external-ID tie-break (Stage 7 behavior); Stage 8 does not change ordering.

## Regression proof
[Final GitHub Actions run 39577415405](https://github.com/AIRebelRelay/BellumCivile/actions/runs/39577415405) **success**.
- 22 isolated compiled mock runtime assertions: four staged maximum, attached ticket frees one place, native ID tie-break, hard cancellation cases, early/late expiry, persisted terminal code and exact submitted day, terminal replay/collision, free slot after closure, attached agenda unaffected by lifecycle, no added court notification.
- 8 source-contract checks: daily gating, attached/closed exclusion, expiry and invalidation, primitive persisted tombstone, replay/collision guards, no direct vote/expulsion, old codec and SaveDefiner compatibility.
- Existing Stage 5 source baseline, Stage 6 source+compiled tests, Stage 7 source+compiled tests, `Tests/CourtExecutiveScheduler.Tests.ps1`, and MSBuild compile-item exclusion/inclusion checks all **PASS**.
- Earlier two red CI iterations (`39576969391`, `39577147339`) were caused by **test-only** mistakes: the first test assumed chronological `one` before `four` at identical submission timestamp (actual Stage 7 tie-break is ordinal ID), then PowerShell parameter `$day` shadowed test variable `$Day` due to case-insensitivity. Both corrected in **test code only**, without changing Stage 8 production semantics. No temporary diagnostic print remains.
- Expected CI lines: `STAGE8_NPC_CROWN_RUNTIME_PASS` and `STAGE8_NPC_CROWN_SOURCE_PASS`.
- Actual eventual game log **not yet observed**: `AIInfluence NPC Crown intent closed; id=...; realm=...; target=...; status=...; court_actions=false.` Once per closed ID. No direct `Queued expulsion deliberation` or `ExpelClan` from Stage 8.

## Full diff audit
Compared `49c024ae...` Stage 7 baseline with `3a1fcd06...` Stage 8 tested commit: 12 changed files across scoped lifecycle/registration/testing/workflow/contract. Production changes limited to **1 new lifecycle partial class + 3 small existing-method edits**; one insertion in shared Tick. Neither `main` nor any unrelated routes were modified. No fallback, existing defaults, Court priorities, native decision execution or SaveDefiner class IDs changed.

## NOT proven / release gate remains closed
- **Full net472 build using real Bannerlord 1.4.8 game assemblies is NOT complete.** The isolated C# mock compiler and MSBuild item listing are not substitutes.
- **Actual Bannerlord campaign load/save/reload and native politics vote lifecycle NOT tested.** Stub serialization is not actual TaleWorlds save system.
- Stage 8 only closes stale **unassigned** intents. Attached-but-superseded/vanished native motions still return `court_superseded`/`court_missing` from read-only status, and the global 256-ID historical limit remains; plan scaling only as a separate stage if needed.
- The Bellum 1.4.5 migration still has other independent blockers: Royal Peace/Claim Feud scope P0, Bridge `CanRulerIndictClan` ABI, treaties/war, council/titles/succession/events compatibility, and copied-save migration.
- No Relay, Relay Bridge, Bellum Bridge 0.8.6 or Bellum upstream production release changed.

**Next stage candidate:** real Bannerlord 1.4.8 assembly build and source-backed ABI check BEFORE any deployment; then test copied saves and only then start a separate Bridge adapter or the next independent semantic subsystem.
