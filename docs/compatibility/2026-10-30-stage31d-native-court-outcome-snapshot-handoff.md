# Stage 31D — Native Court Agenda outcome provenance, read-only snapshot extension

**2026-10-30 · INTERNAL DEVELOPMENT STAGE ONLY. One functionally complete integrated alpha, NO owner per-stage DLL build/test.** Release gate: [Bellum Bridge #90](https://github.com/AIRebelRelay/Bannerlord2-AiInfluence-BellumCivile/issues/90) and [Relay #468](https://github.com/AIRebelRelay/ai-rebel-relay/issues/468). No main/release merge, CI, Binary, or in-game PASS from this stage.

## Verified repository and exact refs

- CORRECT **Native Bellum** repository: `AIRebelRelay/BellumCivile` (NOT Bellum Bridge and NOT ai-rebel-relay-bridge). Native Bellum 1.4.5.
- Base `feature/stage30c-hostage-readonly-realm-snapshot-2026-10-29@cab0e4029263ece4f7fc1f733cb9183c360d0163`.
- Working branch `feature/stage31d-court-objective-outcome-snapshot-2026-10-30`.
- TEST FIRST commit `59df03912b0af1d0cfc2fb26bf0c9987c4f3f308`: `Tests/Stage31DCourtObjectiveSnapshot.Tests.ps1`.
- PRODUCTION commit `bde11ac1892379600188e593f51fdf5d10490d2c`: `IntegrationSnapshots.cs` only, 15 added lines, zero removed.
- Read-only downstream baseline: Bellum Bridge Stage31C `f7ab2707f2844d45b40c435add7430e9064c4567`, Relay Stage30E1A `97d10bfaee4eb2949e8d66be8b5107591513ed9b`. Neither modified.

## ROOT CAUSE / actual method chain

Native Bellum already has a purpose-built `CourtAgendaSnapshot` with stable `CourtAgendaRecord.IntegrationId`, realm/faction/sponsor, kind/target/action, and `CourtAgendaState` and `ResultApplied`. `CourtAgendaBehavior.GetIntegrationSnapshots(Kingdom)` returns snapshots from `IntegrationRecords()` (the union of `_agendas`, `_recentResults`, `_rallies`, `_claimGrace`).

**But** `CourtAgendaState` is not an unambiguous truth source for completed objective outcomes: actual `CourtObjectiveRecord` separately holds `State` (`Selected,Active,Succeeded,Failed,Expired,Cancelled`), `Credit` (`None,Sponsor,FulfilledElsewhere`), `ResultReason`, and `IsTerminal`.

Source examples:
- A Court peace/campaign/claim/dynastic objective expires: `CourtAgendaState.NotProposed` with `CourtObjectiveState.Expired`. Not a rejected parliamentary vote.
- An initiative succeeds through another house: `CourtObjectiveCredit.FulfilledElsewhere`. Success ≠ sponsor-achieved success.
- `CourtCouncilAgendas.ConcludeCouncilAppointment` may produce `Passed` vs `Defeated` depending on whether the **preferred nominee** won; the actual office may nevertheless be filled with another candidate.
- Court activity `activity_partial_execution` can have `CourtAgendaState.Completed` with completed effects **and** interrupted targets. Do not narrate full completion.
- Technical `SettleCancellation(reason)` sets `CourtAgendaState.Cancelled` without setting `ResultApplied=true`; a private technical cancellation must not be emitted as public political defeat.
- Policy `CourtPolicyObjectiveBridge.Refresh` owns its mapping and may mutate `ObjectiveData`; a read-only integration snapshot must NOT invoke it for freshness.

Without a direct projection of objective semantics, a future Bridge reader risks inventing a passed/failed vote, assigning the wrong actor credit, or describing cancelled Court business as a political decision.

**Retention BLOCKER (NOT FIXED):** `CourtAgendaBehavior.OpenTerm` prunes `_agendas` not active/filed/ongoing. `_recentResults` retains only a subset with faction-related mood shock and time-limited visibility. Thus `GetIntegrationSnapshots` is **not** a durable complete terminal event journal. Polling only these snapshots can miss outcomes between polls/terms. Stage31D does **not** pretend to solve this by adding DTO fields.

## Change boundary

**TOUCH**
- Only `IntegrationSnapshots.cs::CourtAgendaSnapshot` — append 5 getters, assign from `record.ObjectiveData` and `record.CancellationReason`, null-safe, read-only:
  - `CourtObjectiveState? ObjectiveState`
  - `CourtObjectiveCredit? ObjectiveCredit`
  - `string ObjectiveResultReason`
  - `bool ObjectiveTerminal`
  - `string CancellationReason`
- New `Tests/Stage31DCourtObjectiveSnapshot.Tests.ps1` (test-first).
- This handoff document.

**DO NOT TOUCH** any `SaveableField` and `BellumCivileSaveDefiner`; `CourtAgendaRecord`; Native `CourtAgendaBehavior`/Court Executive/Policy/Council/civil/treason/royal peace; `CourtPolicyObjectiveBridge`/objective mutations; `HostageStatusSnapshot` co-located in the same source file; Harmony; game commands; Bellum Bridge; Relay; other bridges; NanoGPT routes/TTS; #85 frozen foreign pressure.

**MUST FIX:** expose **source-backed objective outcome status and credit** without inferring a final result from `CourtAgendaState` alone. If `record.ObjectiveData == null`, `ObjectiveState` and `ObjectiveCredit` remain **null** and `ObjectiveTerminal=false`; no on-read repair that could change saves.

**MUST NOT CHANGE:** identity, timestamps, actor/faction/realm scope, original 12 getters, all existing consumers, current Native rewards/payment/approval, result claiming, council/treason vote semantics, or hostage behavior. No new Native persistence fields/schema.

## Regression contract before implementation

**Positive fixture design (to run with actual .NET + Bannerlord refs):** `Passed/Succeeded/Sponsor`; `Defeated/Failed/None`; `Completed/Succeeded/FulfilledElsewhere`; `NotProposed/Expired/None`; `Cancelled/Cancelled/None`; `Completed/Succeeded` with independent partial activity reason; missing objective yields null and nonterminal.

**Neighbors to protect:** policy `Refresh` mapping, council appointment identity and actual winner, claim transfer proof, technical cancellation refunds vs public political results, no two rewards from a read, no action or `Guid.NewGuid` during DTO construction, prior hostage snapshot byte-for-byte unchanged, legacy agenda ID restoration in `SyncData`, saving/loading the same `IntegrationId`, no new changes to the scheduler.

**Test first RED:** new PowerShell test committed before any C# change; baseline source audit proved five new getters absent (5/5 expected RED). It checks original getters, direct null-safe fields, no `GetObjective`, no `Finish`, no `TryClaimResult`, no GUID generation or state mutation, prior API and retention truth.

**After patch GREEN:** **40/40** explicit V8 read-only assertions over latest pinned Native GitHub files passed. Full compare before documentation: exactly test script added + `IntegrationSnapshots.cs` changed (+15/-0); full source diff checked: five getters and six lines of direct projection (plus comments), no behavior method changes. `HostageStatusSnapshot` unchanged. **This is source inspection, not executed PowerShell / .NET / game regression.**

## Security / release acceptance implications

`ObjectiveResultReason` and `CancellationReason` are INTERNAL diagnostic provenance: raw technical reasons may be private, administrative, or opaque. They MUST NOT be forwarded indiscriminately to public Dynamic Events. A later Bridge publisher needs exact public/secret classification, source-ID/campaign epoch, actor/realm/target validation, and correct listener scoping.

Likewise, `ObjectiveState==Succeeded` alone must not become "sponsor succeeded"; use `ObjectiveCredit`. `ResultApplied` and `ObjectiveTerminal` are separate fields intentionally and must not be conflated. `SessionDay` is an agenda session time, NOT a verified terminal completion timestamp.

**Current Stage31D does not inject any Event, write any sidecar JSON, persist any new terminal journal, change Native mechanics, or prove that NPCs know a resulting event.**

## Developer / tester gate (later, NOT owner per-stage)

When real .NET / Bannerlord 1.4.8 assemblies are available, run `Tests/Stage31DCourtObjectiveSnapshot.Tests.ps1` plus the preexisting Native court regression tests and Native Release build/harness. Validate old save loading and new save reload, stable IntegrationId; null on missing objective, no read-side mutation. In final integrated alpha, compare native logs (Court objective concluded, Court council objective resolved, Court activity concluded, Court agenda concluded) to future Bridge exact `source_fact_id`, Relay verified event admission/ACK, AII DynamicEvent persistence and named NPC stored `DynamicEvents[]`. No invented completion or cross-realm leak.

Local audit host lacks `pwsh`, `dotnet`, `msbuild`, `csc`, `mono`. No GitHub Actions triggered (paid quota discipline). Existing new stage branch is not a release build.

## Next Stage31E — architecture review first

Before code changes, trace all `CourtAgendaBehavior` partial owner methods and the moment records are removed. Decide source-backed durable terminal receipt vs a bounded per-campaign publisher only after proving which callbacks can outlive a poll and how an actor's public/private knowledge is determined. **Do not solve by blindly reading private `_agendas`, hooking all `Show()`, or broad Relay `bellum_*` event imports.** If safe terminal persistence requires altering Native save semantics, treat it as a separate high-risk design with multi-caller regressions. Design either a Native exact terminal receipt producer or an explicit, fail-closed fallback for evicted outcomes; no silent inferred results.

Continue with Stage31E after Stage31D diff audit. Entire intended integrated alpha remains blocked until event delivery and #88/#89/hostages are complete and runtime tested.
