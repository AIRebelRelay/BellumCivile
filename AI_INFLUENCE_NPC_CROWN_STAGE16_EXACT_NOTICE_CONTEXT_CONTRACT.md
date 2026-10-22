# Stage 16 — exact in-flight NPC Crown notice provenance
2026-10-22. **Regression contract BEFORE production change. No fact publication.**

## Source pins
Bellum source feature branch `feature/1.4.5-ai-influence-npc-crown` initial HEAD `ef7d98f1bc9246eda8a79c3073d460292783ee3a`, `main` untouched. Bellum Bridge (not Relay Bridge) Stage14 audit HEAD `91566b634c71b217db1e03b5772d3179914406e2`. Stage14 [CI PASS 39739353056](https://github.com/AIRebelRelay/Bannerlord2-AiInfluence-BellumCivile/actions/runs/39739353056), Bellum Stage15 [CI PASS 39741018563](https://github.com/AIRebelRelay/BellumCivile/actions/runs/39741018563).

## ROOT CAUSE, call chain
`TryAttachStagedNpcTreason` knows the selected exact external ticket and native `agenda.IntegrationId`; it persists that pairing and calls Stage15 dedicated `NotifyNpcCrownAgenda(agenda)`, which calls shared `BellumCivileNotifications.Show`. Bridge's existing Harmony capture recognizes the dedicated native caller but generic notification parameters do NOT carry the exact agenda ID. A list of saved `court_announced` tickets cannot prove which docket emitted this one notice (even when only one is presently visible). Never guess by text, clock time or first/last ticket.

**Minimal solution:** Bellum-owned, read-only in-flight scope around *only* the dedicated synchronous NPC Crown notice. Expose the exact immutable ticket snapshot, paired with the freshly assigned `CourtAgendaId`, only during that notice; guarantee clearing via `finally`. No Sidecar/Relay producer or alternate event engine.

## CHANGE BOUNDARY
**TOUCH** (Bellum only): `Behaviors/CourtNpcTreasonAssignment.cs` (one private ephemeral context field + internal getter + try/finally around existing NPC-only call), `BellumIntegrationNpcCrown.cs` (guarded public read-only getter), test-only `Tests/AiInfluenceNpcCrownStage7.Stubs.cs` (capture active context and error simulation), one NEW isolated `Tests/AiInfluenceNpcCrownStage16.NoticeContext.Tests.ps1`, single step/path in existing `.github/workflows/ai-influence-npc-crown-baseline.yml`, contract/audit docs.
**DO NOT TOUCH** shared `NotifyAgenda` and dedicated `NotifyNpcCrownAgenda` helper bodies, `BellumCivileNotifications.Show` and user scope filter, Court priority/agenda/voting, save keys/codec/SaveDefiner, Stage11 inventory, Bellum Bridge Stage14 observer/shadow, W7 publisher, shared notification Harmony, Bellum SidecarWriter, Relay, Relay Bridge, foreign diplomacy, `main`.
**MUST FIX** exact ID/realm/ruler/target/agenda shown synchronously, null outside call (including on exception), wrong realm/null/invalid snapshots reject; getter requires campaign thread.
**MUST NOT CHANGE** original native notification text/color/recipient, one notice per native attachment, no extra staging or vote, old public Crown getters, player and unrelated court behavior; no fabricated published event or claimed expulsion.

## Pre-code regression contract
1. Before native assignment, getter returns null; private `staged_not_scheduled` never generates public context.
2. Inside dedicated native notice, test witness captures immutable snapshot with **exact selected** `ExternalIntentId`, `RealmId`, `RulerClanId`, `TargetClanId`, `Status=court_announced`, and native `CourtAgendaId=agenda.IntegrationId`. Wrong realm returns null.
3. On return, context clears; saved original ticket still reads `court_announced`, no extra voting or notification.
4. If notice throws, `finally` clears context despite already-committed agenda attachment. Never claim transaction rollback from UI error.
5. Duplicate/ineligible/replayed tickets have no new notice; multiple pending tickets and unrelated Court agendas do not alias to the wrong ID.
6. Off-campaign-thread public read throws; missing Court returns null; transient scope never gets serialized.
7. Stage15 exact notice body equality/NoInlining, Stage7 priority and runtime, Stage11 mock reload, Stage5–9 compiled/source tests and all existing Bellum CI remain unchanged.
8. Existing native logs unchanged; no new sidecar or Relay ACK. Build green does not prove runtime with real Bannerlord 1.4.8 DLL.

**Expected future proof:** Bellum `AIInfluence NPC Crown intent attached; id=...; agenda=...; status=court_announced` and, only when UI notification allowed, Bridge `caller=...NotifyNpcCrownAgenda` accompanied by an exact active Bellum ticket; no `BELLUM_SIDECAR_SOURCE` from this stage. Source/mock-only until consolidated live verification.
