# Stage 11 — durable read-only NPC Crown ticket inventory, Bellum-owned
Date: 2026-10-21 | **REGRESSION CONTRACT BEFORE PRODUCTION EDIT**

## Versions / branch pins
- Bellum Civile source `AIRebelRelay/BellumCivile`: `feature/1.4.5-ai-influence-npc-crown` HEAD `9a69fe33913a9e45640f60bde798142428eeba2e`; `main` `b1d9a4e8fb74d4f9dd045793c156abeac6f9f4eb` upstream Bellum 1.4.5 stable.
- Bannerlord 1.4.8; matching Bellum Bridge Stage 10 source verified build HEAD `01967aeb962c4f4dd29f7491b75ce4c9fac042c5` in `AIRebelRelay/Bannerlord2-AiInfluence-BellumCivile`.
- DO NOT confuse Bellum Bridge with `ai-rebel-relay-bridge`. Neither Bridge nor Relay is edited in this stage.

## ROOT CAUSE / call-chain trace
Bridge Stage 10 executes `indict_clan` -> `BellumIntegration.TryStageNpcTreasonIntent(realm,ruler,target,externalId)` -> reads exact `GetNpcTreasonIntent(realm,id)` -> logs **staged_pending** (not expulsion success) -> Bridge source-backed queue marks intent processed and deletes consumed input. Existing Bridge `PollPending` only tracks certain unrelated kinds (policy, council, civil), NOT NPC Crown. Across Bannerlord reload or Bridge session reset, the original external ID is no longer enumerated by Bridge. Bellum persists three dictionaries (`BC_CourtNpcTreasonIntents_v1`, `...AgendaIds_v1`, `...Closures_v1`) and derives live ticket state in `Behaviors/CourtNpcTreasonAssignment.DescribeNpcTreasonIntent`, but only exposes a **single-ID** read API `BellumIntegration.GetNpcTreasonIntent(realm,externalId)`. There is no public, read-only inventory of all persisted requests.

A Bridge-only in-memory poller would lose tickets after reload; a second Bridge persistence layer would duplicate Bellum-owned durable state and risk duplicate/lost status. Therefore the **minimum safe prerequisite** to cross-reload Stage 11 observation is a Bellum-owned enumeration API. Observer + Relay delivery belongs to a separate stage after this API is proven.

## CHANGE BOUNDARY
**TOUCH (Bellum only):**
1. `BellumIntegrationNpcCrown.cs`: append `GetNpcTreasonIntents(Kingdom realm)` (campaign-thread guarded, read-only, `IReadOnlyList<NpcCrownTreasonIntentSnapshot>`).
2. `Behaviors/CourtNpcTreasonIntents.cs`: implement an internal realm-scoped sorted inventory **by delegating to the current exact-ID getter**, preserving native `DescribeNpcTreasonIntent` status logic.
3. NEW `Tests/AiInfluenceNpcCrownStage11.Inventory.Tests.ps1` compiled isolated regression using existing Stage 6/7 test stubs and actual production C#.
4. `.github/workflows/ai-influence-npc-crown-baseline.yml`: one narrow test step and path trigger.
5. This contract and eventual audit.

**DO NOT TOUCH:** Bellum `CourtAgendaBehavior.OpenTerm`, existing Tick/scheduler, `CourtNpcTreasonAssignment.cs`, `CourtNpcTreasonLifecycle.cs`, save dictionary schemas/keys, `NpcCrownTreasonIntentRecord.cs`, `BellumCivileSaveDefiner`, `BellumIntegration.ApiVersion`, player Crown, vote/expulsion executor, any Harmony path; Bridge/Relay repos or `main`.

**MUST FIX:** Return deterministic immutable-snapshot **copies** (never raw saved dictionaries), only tickets for exact realm, including currently staged, attached native Court states, superseded/missing and terminal tombstones, regardless of current ruler. Omit invalid/corrupt records without manufacturing identity or vote status. Read-only API must be a pure query, not a new campaign poll/scheduler. Thread guard required.

**MUST NOT CHANGE:** eligibility, submission, capacity (256 historical IDs, 4 per realm unassigned), original ticket idempotency, save/reload semantics, native Crown priorities and autonomous votes, expiration, and 1.4.5 player mechanics.

## Regression contract before implementation
1. Positive: two different durable tickets in realm A returned sorted lexically by external ID, correct target/ruler and current status `staged_not_scheduled`.
2. Positive: attached ticket reports native `court_announced`, then `court_deliberating`; `CourtAgendaId` matches original.
3. Negative: realm B query cannot observe realm A's ticket; null realm and missing Court return an empty list.
4. Negative: injected corrupt ticket is skipped, never throws, never becomes a fabricated valid ticket; new API does not alter Bellum save dictionary, ticket count, or agenda state.
5. Positive: terminal tombstones (`cancelled_ruler_changed` etc.) are included with same original ID/status and remain visible after mock save/reload; linked `court_missing` and `court_superseded` remain explicit, never `verified` expulsion.
6. Negative: off-campaign-thread public API call throws existing Bellum thread guard and no mutation occurs.
7. Neighbor: old exact-ID `GetNpcTreasonIntent` remains unchanged; Stage 5–9 source/compiled tests, Court Executive Scheduler, SaveDefiner compile-item checks all remain green.
8. Fail closed: no new API use by Bridge yet, no false claim of Relay receiving court outcomes.
9. Performance: bounded enumeration (max 256 saved tickets), call on-demand; future Bridge observer MUST rate-limit and avoid per-frame/1s full polling.
10. Native Bannerlord 1.4.8 compile and copied-save game behavior remain a separate user/tester validation gate. **No merge/release** on this source-only stage.

## Evidence expected
`STAGE11_NPC_CROWN_INVENTORY_PASS` from compiled mock/source test; full feature-branch CI green. There is deliberately **no runtime log line** from this read-only API. The eventual Bridge observer will log status changes (and later, only verified native outcomes) with exact `external_intent_id` + `agenda_id`; never equate `court_passed` with actual expulsion until validated by independent native state.
