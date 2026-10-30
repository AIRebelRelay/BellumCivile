# Stage 31E — Court Agenda terminal event retention: source-backed architectural gate

**2026-10-30 — ANALYSIS / REGRESSION CONTRACT ONLY.** No Native/Bridge/Relay production edits, build, game, Actions or release. This closes the **architecture analysis** stage, **not** the end-to-end NPC event delivery feature. User constraint: one full integrated alpha, no per-stage owner DLL tests. Related integrated alpha gates: Bellum Bridge #90 / Relay #468. Court foreign pressure #85 stays frozen. P0 ExpelClan #88 and WarScore/peace #89 remain separate.

## 1. Exact repositories / branch / HEAD at investigation

- Native Bellum, **AIRebelRelay/BellumCivile**: Stage31D production/handoff HEAD `3197cd2d3087b5a4446b9fbb02e78d52cce43c55`, branch `feature/stage31d-court-objective-outcome-snapshot-2026-10-30`. Work here: `audit/stage31e-court-terminal-retention-architecture-2026-10-30`.
- **Bellum Bridge** separate repo `AIRebelRelay/Bannerlord2-AiInfluence-BellumCivile`: Stage31C HEAD `f7ab2707f2844d45b40c435add7430e9064c4567`, **unmodified**.
- Relay `AIRebelRelay/ai-rebel-relay`: `97d10bfaee4eb2949e8d66be8b5107591513ed9b`, **unmodified**.
- **Relay Bridge** `AIRebelRelay/ai-rebel-relay-bridge` is a different product; not involved.

## 2. ROOT CAUSE: terminal records are not a durable feed

The supported, campaign-thread-only `BellumIntegration.GetCourtAgendas(Kingdom)` in `BellumIntegration.cs` calls `CourtAgendaBehavior.Current?.GetIntegrationSnapshots`, which returns a snapshot of `IntegrationRecords() = _agendas ∪ _recentResults ∪ _rallies ∪ _claimGrace`.

Stage31D exposed correct `ObjectiveState/ObjectiveCredit/ObjectiveResultReason/ObjectiveTerminal/CancellationReason` on **currently surviving** `CourtAgendaSnapshot`. It did **not** create durable terminal history. The current `GetCourtAgendas` API is a *current-record snapshot*, not an event log or an acknowledgment protocol.

Source-backed removal windows, independent of Bridge's 5-second poll:

| Native owner / exact method | Removal / retention behavior | Why a finished event can disappear |
| --- | --- | --- |
| `CourtAgendaBehavior.OpenTerm` | `_agendas.RemoveAll(a => a.Realm == realm && !a.IsFiled && !a.IsUnopened && !a.IsOngoingObjective)` | Ordinary final policy/executive/activity record removed on term rollover; Bridge need not have sampled it |
| `CourtAgendaBehavior.Tick` | Invalid-realm `_agendas.RemoveAll` | Closed records of invalid/destroyed realms removed, with a separate lifecycle; never turn invalid realm into invented defeat |
| `CourtReactionHistory.RecordResultHistory` / `Tick` | Records retained ONLY with `Faction != null`, nonzero mood shock, eligible `ReactionApproval`, limited `ResultVisibleUntil.IsFuture` | Crown and no-shock / technical / neutral results not all retained; remaining results eventually expire |
| `CourtClaimAgendas` | `_agendas.Remove(agenda)` when entering claim grace; `_claimGrace.RemoveAll(a => a.ResultApplied)` | A claim may migrate collections and then be deleted separately |
| `CourtRallyAgendas` | `_rallies.RemoveAll(a => a.ResultApplied && now > DeadlineDay + 1)` | Rally terminal record expires independent of general Court term |

The current `IntegrationId` is stable through saves (`CourtAgendaRecord [SaveableField(51)]`, restored for old saves by `RestoreIntegrationIds`) but identity alone does not retain missing entries.

**One important existing precedent:** `FreezeNpcCouncilTerminalResults(realm)` runs **before** term pruning and freezes exact NPC council *intent* outcomes into the `_npcCouncilClosures` persisted `Dictionary<string,string>`, under `BC_CourtNpcCouncilClosures_v1`. It demonstrates a safe pattern for a **specific consumer**, not a universal history feed. Do not re-purpose its codes, capacity, or semantics for unrelated Court outcomes.

## 3. Terminal event producers / shared callers — why a generic hook is unsafe

The following modules all own their own state, completion, and/or cancellation semantics. Most produce `CourtObjectiveState` independently, often with `ResultApplied`, `TryClaimResult`, or credit before reporting. Do not treat all as the same "vote":

- `CourtAgendaBehavior.Conclude` (policy); `Cancel`, `Advance` (crisis, withdrawal, technical cancellation, fulfilled elsewhere).
- `CourtExecutiveAgendas.FinishExecutive` and `ConcludeExecutiveVote` (treason, land revocation, decree, etc.).
- `CourtCouncilAgendas.ConcludeCouncilAppointment` (actual appointed candidate may differ from preferred one); NPC council intent tombstones are separate.
- `CourtActivityAgendas.FinishActivity` (partial effects can count as `Completed`; do not narrate every target as completed).
- `CourtPeaceAgendas`, `CourtCampaignAgendas`, `CourtClaimAgendas`, `CourtSubjugationAgendas`, `CourtDynasticAgendas`, `CourtTradeAgendas`, `CourtTitleGrantAgendas` (different terminal deadlines, credit and visibility).
- `CourtProtectionAgendas`, `CourtClientGrantAgendas`, `CourtLiberationAgendas`, `CourtRallyAgendas`, `CourtMandateAgendas`, `CourtRoyalPeaceAgendas` (some direct `ResultApplied` paths, some via `FinishExecutive`).
- `CourtAgendaPlayerFlow` personal nomination expiration and reminder notices are `isPersonal:true`; cannot be translated into worldwide news.

A patch inside shared `CourtObjectiveRecord.Finish()` is **not acceptable without caller audit**: it can run before agenda `State`, `ResultApplied`, effects, credit verification or actual Council office outcome settle. Reusing `BellumCivileNotifications.Show()` as an authoritative result source is also unsafe: UI visibility / personal notices, wording and exact legal outcomes are different concepts.

## 4. DESIGN DECISION / boundary for future stages

**Stage31E outcome: STOP speculative patches in shared Court state. Use a new, independent terminal receipt architecture with strict causal ordering.** This is a design direction, **not implemented**.

Recommended separation:

1. **Native truth owner.** Capture an immutable exact terminal record with `IntegrationId`, source realm/faction/sponsor IDs, kind/target/action, agenda state, objective state/credit/reason, result-applied flag and actual terminal observation day. Do not infer finality from `SessionDay` or `NotProposed`; do not silently assign sponsor credit if `FulfilledElsewhere`. Capture only after the owner finishes mutation; for all pruned records, final capture must occur *before* any eviction, including special claim/rally and invalid-realm paths. Technical cancellations and unknown/incomplete states must be explicitly classed as **private/diagnostic/unknown**, not automatically public news.
2. **Persistence and recovery.** Separate pending terminal receipts from scheduler and `_recentResults`, serialize under a unique save key. Existing `Dictionary<string,string>` container is registered in `BellumCivileSaveDefiner`, but do **not** choose a string-packed format / retention cap until schema, corruption behavior, migration, and collision tests exist. Preserve duplicate protection after save/reload, no retroactive invented old outcomes; expose read-only API on the active campaign thread.
3. **Bridge transaction boundary.** Read Native API without side effects, validate source/campaign identity, copy into durable, idempotent Bridge sidecar with exact source ID, and only then acknowledge Native receipt if a write-confirmed ACK API is intentionally designed. No ACK based merely on seeing a record or on successful provider call. If the native save is old or a record already pruned, expose coverage gap; never backfill from generic toast. Journal overflow MUST have explicit evidence/fail-closed behavior, not silently discard "low priority" unacknowledged events.
4. **Relay/AII knowledge boundary.** Existing Relay `court_politics_transition`/digest and `bellum_court_notification` may overlap; investigate exact duplicates before selecting new event type. Keep finite allowlist & category checkbox, 3-bundle × 12-fact limits and civil/Crown canonical owners. A Relay ACK proves sidecar consumption only; actual success requires a matching AII persisted DynamicEvent ID and a named NPC `DynamicEvents[]` receipt. Public realm/personal/secret classification must be explicit, never treat game notification scope as a universal broadcast authorization.
5. **No Native behavior change.** Keep all current `_agendas` removal, `_recentResults` mood/UI history, Council intent closures, save schema IDs, influence payments/refunds, Mood shock, rewards, votes, and Crown/war mechanics. Do **not** extend `_agendas` lifetime to solve delivery.

**High-risk unresolved design questions (must close before implementing full pipeline):** existing Native terminal callbacks vs prune-only capture completeness; ordered mutation and finalization for Council / allocation; definition of public vs private for technical cancellations; campaign epoch identity across saves; duplicate event ownership with W7/notification feed; Native-to-Bridge ACK crash windows; bounded-capacity/backpressure; precise external method/ABI and serialization versioning.

## 5. Regression contract BEFORE any future production patch

**Positive:**
- 1 vote PASSED / objective Succeeded / sponsor credit → one correct immutable receipt; survives rollover, reload; exact ID unchanged across repeated reads.
- 1 vote DEFEATED / Failed, no law change → do not emit enacted law; no fake `policy_vote_closed_without_law_change` outcome from W7.
- 1 objective Expired / `NotProposed` → failure-by-deadline, not parliamentary rejection.
- 1 `FulfilledElsewhere` / Succeeded / another actor credit → true success, no false sponsor claim.
- 1 Council appointment → actual appointed candidate vs preferred nominee correctly distinguished, no duplicate NPC council intent closure.
- 1 interrupted Court Activity → only observed effects, no false all-target success.
- 1 decree/royal peace → exact Native outcome, no additional war/peace overwrite.
- 1 claim grace + terminal result, rally expiry, invalid realm + term rollover → receipts survive **every** removal path.
- Save/reload, delayed Bridge read, restart between Native terminal and Bridge admission, and Bridge retry after sidecar receipt → one persistent source fact, never duplicate.

**Negative/protection:**
- `ResultApplied=false` technical cancellation/withdrawal/nomination expiration may be recorded internally but is NOT declared a finalized public vote.
- `isPersonal=true` reminder or private nomination, secret foreign plot, NPC-only intent ticket, Crown canonical announcement: not leaked/doubled.
- No fabricated receipts for old save with already-pruned outcomes; no cross-campaign ID/epoch collision.
- Missing/corrupted/unavailable receipt and full/overflow queue must fail closed, never silently call `Finish`, `TryClaimResult`, `GetObjective` or other state mutation in getters.
- Existing `_agendas` cleanup and `_recentResults` UI history remain exactly as before; all current callers of `CourtObjectiveRecord.Finish` unchanged.
- Relay disabled categories work; unrelated Civil War, generic war, ExpelClan #88, WarScore/peace #89, Crown, Hostages, NanoGPT routing and TTS remain unchanged.

**Minimum log evidence for future live test:** Native `BC_COURT_TERMINAL_RECEIPT recorded|deduped` (proposed tag), `BC_COURT_TERMINAL_QUEUE pending=N`/overflow diagnostics; Bridge `BELLUM_SIDECAR_SOURCE status=recorded|deduped; source_kind=court_terminal`; Relay `[BellumInject] applied=true` and exact fact ACK; AII active saved EventID and named NPC `DynamicEvents[]`. These proposed Native log tags **do not exist yet**. Expected absence: generic duplicated Court/civil/Crown facts, false sponsor credit, private events in public news, cross-save replay, missing receipt silently treated as success.

## 6. Stage 31E change boundary & verification

**ROOT CAUSE** exact: current-record API does not own a terminal ledger; multiple Native event owners prune records before Bridge is guaranteed to see them.

**TOUCH in Stage31E:** ONLY this analysis document and `Tests/Stage31ECourtTerminalRetentionSourceAudit.Tests.ps1`. The PowerShell test asserts *current source boundaries* and explicitly emits `STAGE31E_DURABLE_TERMINAL_RECEIPTS_NOT_IMPLEMENTED`. It **must not** be interpreted as integrated event correctness or a completed durability fix.

**DO NOT TOUCH in Stage31E:** all production files including `CourtAgendaBehavior`, `CourtAgendaRecord`, `CourtObjectiveRecord`, `BellumCivileSaveDefiner`, `BellumIntegration`, Bridge, Relay and all notice/Harmony.

**MUST FIX in a future stage**: durable exact terminal evidence for all eligible Court outcomes without modifying gameplay semantics; semantics and public routing must be separately validated.

**MUST NOT CHANGE**: existing term pruning, saved identity, original source of political truth, no automatic read-side mutation, no personal or secret leaks, no new empty/invented provider context, no foreign Crown/war regressions.

**Stage31E validation:** read-only source inspection of current pinned Native HEAD; check complete diff contains only docs/audit fixture. No PowerShell/.NET/Bannerlord execution, no Actions, no release or runtime PASS.

**Next (separate) Stage31F proposal:** choose and prove a single Native *terminal receipt* invariant with a runtime regression harness and save/reload test on real source; re-audit all caller/prune sites before code. Implement smallest bounded scope justified by fixtures. Do not patch only one removal path and declare Court coverage complete. Bridge publishing and Relay event type selection belong to subsequent stages, after Native ledger is demonstrated.
