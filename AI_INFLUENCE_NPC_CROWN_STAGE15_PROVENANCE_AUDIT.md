# NPC Crown Stage 15 — native notice provenance, surgical audit
**Date:** 2026-10-22. **Status: CI PASS (source/mock only); native game build + runtime + Relay delivery NOT VALIDATED.**

## Verified authority
- Correct repo **Bellum source**, `AIRebelRelay/BellumCivile`, branch `feature/1.4.5-ai-influence-npc-crown`, validated source HEAD `9f2ce2aaeec4dbd9ba363c93aede2e079708926c`. `main` untouched.
- Pre-code contract `9e5ac94c4e3bbdb84545a11dd894044534bd16bc`, [read it here](./AI_INFLUENCE_NPC_CROWN_STAGE15_PROVENANCE_CONTRACT.md). Earlier Stage 11 inventory HEAD `d93c41733a82926d34a8f8a8fbd180b41630e084`.
- Separate Bellum Bridge (NOT Relay Bridge) unchanged, Stage 14 audit branch `AIRebelRelay/Bannerlord2-AiInfluence-BellumCivile` prior HEAD `91566b634c71b217db1e03b5772d3179914406e2`. Relay unchanged. No merge/release.
- [**CI run 39741018563 — SUCCESS**](https://github.com/AIRebelRelay/BellumCivile/actions/runs/39741018563). First run `39740860310` failed on a test-only PowerShell comment `//` (corrected to `#`); no production changes were made after that.

## ROOT CAUSE and correction
The native Bellum AI Crown attachment method `CourtAgendaBehavior.TryAttachStagedNpcTreason` was calling a shared `NotifyAgenda(agenda)` from `CourtAgendaPlayerFlow.cs`. Shared helper is also used by ordinary player/executive court flows. The Bridge's notification Harmony postfix `FindBellumCaller` determines fact provenance using the nearest non-`BellumCivileNotifications` stack frame, so **all these cases looked like the same generic `CourtAgendaBehavior.NotifyAgenda`** and lacked native `CourtAgendaId`. Bellum `BellumCivileNotifications.Show` itself is player-scoped and can skip delivery. Thus native UI toast is neither globally reliable nor an authoritative unique NPC Crown fact.

One local dedicated native notice method now adds a distinct, non-inlined origin frame **without changing the UI message or display filtering**. Exact Bellum native Court agenda/ticket `IntegrationId` remains the authoritative identity; the dedicated method's name is only the provenance hint, not an event receipt.

## TOUCH — full diff exactly FOUR source/test files from contract to validated HEAD
1. `Behaviors/CourtNpcTreasonAssignment.cs`: single call changed `NotifyAgenda(agenda)` → `NotifyNpcCrownAgenda(agenda)` **only after** successful exact ticket/agenda association and native Court `Announced` state; no scheduling/priority/payment/vote code changed.
2. `Behaviors/CourtAgendaPlayerFlow.cs`: imported `System.Runtime.CompilerServices` and appended `[MethodImpl(MethodImplOptions.NoInlining)] private void NotifyNpcCrownAgenda(CourtAgendaRecord agenda)`. Body duplicates the previous shared helper exactly (same log, TextObject key `BC_CourtAgendaUpdated`, template `Court of {REALM}:\\n{AGENDA}`, `REALM` and `AGENDA` substitution, same `BellumNotificationColors.Politics` and `primaryKingdom`). **Shared original method untouched**, with other callers still using it. No new options or Sidecar event.
3. `Tests/AiInfluenceNpcCrownStage7.Stubs.cs`: mock-only exact new notification method increments existing `NotificationCount` just as original stub did; only compiled in isolated tests, never shipped.
4. `Tests/AiInfluenceNpcCrownStage7.Source.Tests.ps1`: explicit source-backed one-call-only boundary; `NoInlining` provenance; regex-extracts both method bodies and asserts **literal byte-for-byte body equality**; confirms ordinary helper and MCM scope-bearing native Show call remain. Corrected one comment syntax in same test.
Documentation contract and this audit are additional non-production files.

## Regression proof
- `STAGE7_NPC_CROWN_SOURCE_PASS` including `generic_and_exact_crown_notice_bodies_are_identical`, `native_notice_caller_stack_frame_is_distinct`, `exact_npc_crown_notice_uses_distinct_origin`, and prior native priority/legality checks.
- `STAGE7_NPC_CROWN_RUNTIME_PASS`: compiled mock attachment once + rejected replay/slot pressure, idempotent ticket identity.
- `STAGE8_NPC_CROWN_RUNTIME_PASS`, `STAGE11_NPC_CROWN_INVENTORY_PASS` and rest of scheduled source regression suite green.
- Native Bannerlord 1.4.8 DLL build **NOT rerun**; user's earlier native Bellum source compilation predates this source HEAD. Full-game save/scene/notifications and Bridge Harmony call-stack provenance NOT directly observed.

## DO NOT TOUCH verified
No Bellum notifications shared helper `NotifyAgenda` changes, `BellumCivileNotifications.Show/ShouldShow` changes, native save schema changes, Hall/Crown Court priority, laws/treason vote/expulsion paths, player court text/colors, Harmony; no Bridge notification-capture modification, W7 or Relay-side event publication, Sidecar spool/ACK, or foreign diplomacy.

## Log/game proof still needed in eventual consolidated integration test
- Bellum persistent: `AIInfluence NPC Crown intent attached; realm=...; id=...; agenda=...; status=court_announced`.
- If native UI notification is allowed by Bellum scope, existing Bridge `BELLUM_NOTIFY_CAPTURE` should show `caller=BellumCivile.Behaviors.CourtAgendaBehavior.NotifyNpcCrownAgenda` after this feature DLL is installed. **Not claimed as observed.**
- If UI notification is suppressed, there may be no capture at all; durable Bellum `GetNpcTreasonIntents` readback remains valid. An absent capture is not a missing native Court agenda.
- Stage14 `BRIDGE_V1_NPC_CROWN_ADMISSION_SHADOW publication_blocked=true` still applies. No new `BELLUM_SIDECAR_SOURCE` or duplicate fact from Stage15.

## Next single stage / unresolved architecture
Bellum now exposes a distinct native NPC Crown **notification source** while its durable ticket API provides the actual `CourtAgendaId`. Stage 16 must **prove exact caller+docket association** and pick one Crown public fact producer, while preserving UI scope behavior, existing native notification fact and unrelated W7. The notification's existing parameters do NOT carry `CourtAgendaId`; the method tag by itself is not enough. No publication until the collision/duplicate ownership regression is solved; do not patch shared notification semantics for one case.
