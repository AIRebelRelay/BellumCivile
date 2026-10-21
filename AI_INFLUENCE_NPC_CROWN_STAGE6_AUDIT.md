# Stage 6 — NPC Crown staging only; explicit non-executable gate
Date: 2026-10-21. Status: candidate implementation in isolated Bellum 1.4.5 stable fork branch, pending tests and live save verification.

## Pinned base and root cause
Bannerlord 1.4.8; Bellum Civile 1.4.5 tag `b1d9a4e8fb74d4f9dd045793c156abeac6f9f4eb`.
Stage 5 baseline `4265e220d01dce9edb870da7212d0235b74552dc`.
Bellum currently has no **public** API for *exact NPC Crown treason intent*; player-only `TryNominateTreason` and `TryPlayerTreasonBusiness` are not legal for an NPC. The Bridge v0.8.6 has a separate 4-vs-5 parameter ABI mismatch. Avoid an illegal direct `QueueExpulsionVote` shim.

## CHANGE BOUNDARY
**TOUCH:** `BellumIntegrationNpcCrown.cs` (new public, campaign-thread API), `Behaviors/CourtNpcTreasonIntents.cs` (new private state and admission), `NpcCrownTreasonIntentRecord.cs` (new read-only DTOs and pure versioned ticket codec), a **single** new `SyncNpcTreasonIntents(dataStore)` call after `BC_CourtAgendas` in `Behaviors/CourtAgendaBehavior.cs`; dedicated Stage6 test and this audit.

**DO NOT TOUCH:** native treason scheduling `CourtExecutiveAgendas.cs`, `IdeologyBehavior.cs`, `CourtAgendaBehavior.OpenTerm`, `Advance`, `CourtAgendaRecord`, `BellumCivileSaveDefiner`, `SubModule`, `BellumIntegration.ApiVersion=1`, player UI, any other repos or their `main` branches.

**MUST FIX THIS STAGE:** native, read-only-eligible NPC ruler can stage exact bounded ticket into existing `Dictionary<string,string>` save container; idempotent replay and collision detection; explicit `staged_not_scheduled` outcome; no gameplay action or false success.

**MUST NOT CHANGE:** court priorities, player direct filing, native expulsion dedup, save schema class/enum IDs, automatic treason MCM toggle, NPC influence/relation preflight, existing integration API and campaign threading.

## Method semantics
- `BellumIntegration.TryStageNpcTreasonIntent(Kingdom realm, Clan rulerClan, Clan targetClan, string externalIntentId)` returns submission `Accepted`, `Reason`, `Intent`. Only `Reason=staged_not_scheduled` means a **recorded ticket**; it does not mean court agenda, pending vote, influence spent, faction shock, or expulsion.
- `BellumIntegration.GetNpcTreasonIntent(Kingdom realm, string externalIntentId)` returns the matching persisted ticket or null.
- Stage 6 does **not** expose this to Bridge, Relay, or the LLM: no caller change and no new model-action capability.
- Existing `BC_CourtNpcTreasonIntents_v1` key is new; saves created before this stage load with empty map. `Dictionary<string,string>` is already registered in SaveDefiner, so no serializer ID changes.
- Deterministic ticket format `1\nrealmId\nrulerId\ntargetId\nsubmittedDay\nstaged_not_scheduled` is validated and read-only. A different request with the same ID is rejected; replay of same ID and scope returns `already_staged` without mutating existing ticket.
- Capacity is 256 total, four outstanding per realm; stage 7 must implement lifecycle / expiry / terminal status before this API is used by Bridge in production.

## Regression contract defined BEFORE implementation
1. Positive: pure codec roundtrip with realm, ruler, target, submitted game day and staged-only state; key and snapshot preserve exact identity.
2. Negative: rejected malformed, overlong, control-character ID and unexpected saved status.
3. Positive: read-only Bellum gate `CanRulerIndictClan(...readOnly:true)`; no rejected-lock mutation.
4. Negative: invalid realm/ruler/target; player ruler; target relation at decree floor; automatic treason disabled.
5. Negative: replay idempotent, cross-target ID collision, corrupt ticket rejected, capacity enforced.
6. Neighbor: existing player actions & Crown priority source contracts and ExecutiveScheduler source regression pass.
7. Neighbor: no `_agendas.Add`, `TryStartTreasonVote`, `QueueExpulsionVote`, paid vote, direct exile or event dispatch in this feature.
8. Neighbor: campaign-thread protected, current SaveDefiner IDs untouched; historical saves must load (not proven until game).
9. Positive future stage (NOT YET IMPLEMENTED): pending accepted ticket attached to Crown at next eligible term **without** displacing native priorities; native queue, save/reload, result readback.

## Evidence and limitations
Expected from Stage 6 source/codec tests: `PASS STAGE6_NPC_CROWN` and `STAGE6_NPC_CROWN_SOURCE_AND_CODEC_PASS`.
Expected if an integration caller voluntarily invokes this API in game: `AIInfluence NPC Crown intent staged; ... status=staged_not_scheduled; state_changes=false`. This is a new **log message** but not proof of assignment. **No game code from Bridge calls it yet.**
Full Bellum compilation requires real Bannerlord 1.4.8 TaleWorlds assemblies and project `GameFolder`; isolated GitHub source contract tests do not replace compiled or live save evidence.
No release or merge to `main` until gameplay and save migration verified.
