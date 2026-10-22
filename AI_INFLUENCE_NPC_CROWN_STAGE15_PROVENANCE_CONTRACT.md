# NPC Crown Stage 15 — source-backed public announcement provenance seam
**Date:** 2026-10-22. Regression contract written **before code**. **No Bellum Bridge / Relay fact publication**, no main merge/release.

## Pinned source and scope
- Bellum source: `AIRebelRelay/BellumCivile`, branch `feature/1.4.5-ai-influence-npc-crown`, pre-stage HEAD `d93c41733a82926d34a8f8a8fbd180b41630e084`.
- Bellum Bridge: `AIRebelRelay/Bannerlord2-AiInfluence-BellumCivile`, audit branch Stage14 current `91566b634c71b217db1e03b5772d3179914406e2`. **Not** `ai-rebel-relay-bridge`.
- Bridge Stage14 shadow `Publish=false`; [CI 39739353056](https://github.com/AIRebelRelay/Bannerlord2-AiInfluence-BellumCivile/actions/runs/39739353056).
- All Bridge, Relay, main branches remain unchanged in this Bellum-only stage.

## ROOT CAUSE and observed call chain
`CourtAgendaBehavior.TryAttachStagedNpcTreason` assigns the native Crown `CourtAgendaRecord`, persists exact `ExternalIntentId -> IntegrationId`, sets `Announced`, then calls **shared** `NotifyAgenda(agenda)`. That generic helper (`Behaviors/CourtAgendaPlayerFlow.cs`) is also used by the player's ordinary court agenda flow and other Bellum executive agenda routes. It builds `"Court of {REALM}:\\n{AGENDA}"` and calls `BellumCivileNotifications.Show`. **Do not change that shared helper.**

`BellumCivileNotifications.Show` first tests `ShouldShow`, honoring user notification scope (Disabled/Global/player context); a display notification is therefore NOT a reliable world-history event and may never reach Bridge. When shown, Bridge `BellumNotificationCapture.FindBellumCaller` sees the nearest non-notification Bellum function, ordinarily generic `CourtAgendaBehavior.NotifyAgenda`, which lacks NPC Crown identity or `IntegrationId`. A new source-backed Crown event cannot safely claim same-docket ownership by comparing localized text or time.

The separate W7 source-backed court/policy publisher observes faction member/leader/stress and policy changes, **not** the exact Crown treason agenda; W7 `sourceId` and native notification hashed `fact.Id` do not correlate with Crown ticket `CourtAgendaId`. Stage14 correctly blocks Crown publication.

## CHANGE BOUNDARY
**TOUCH — Bellum source, one NPC case only:**
1. `Behaviors/CourtNpcTreasonAssignment.cs`: replace **only** the native NPC Crown path's `NotifyAgenda(agenda)` call with dedicated `NotifyNpcCrownAgenda(agenda)`.
2. `Behaviors/CourtAgendaPlayerFlow.cs`: **append** dedicated `[MethodImpl(NoInlining)] NotifyNpcCrownAgenda` that reproduces the EXACT same player-visible message text, color, primaryKingdom, `DescribeAgenda` and native log message as the old shared notification; the distinct stack frame lets a future Bellum Bridge observe the exact source origin without parsing prose. Leave existing shared `NotifyAgenda` body unchanged.
3. `Tests/AiInfluenceNpcCrownStage7.Stubs.cs`: isolated test stub implementation for that dedicated call (increment existing notification counter). Not shipped in Bellum DLL.
4. `Tests/AiInfluenceNpcCrownStage7.Source.Tests.ps1`: assert the call graph split, NoInlining, display message equivalence, generic helper untouched and no direct Bellum sidecar/Relay mutation in either method.
5. This contract and result audit.

**DO NOT TOUCH:** Bellum UI notification scope filters, `BellumCivileNotifications.Show`, global `NotifyAgenda`, polling, bellum ticket save keys/records, Court agenda scheduling/eligibility/priority/voting, Crown executor, Harmony, Bridge `BellumNotificationCapture` and W7, sidecar writer, Relay, Relay Bridge or main.
**MUST FIX:** unique origin method `CourtAgendaBehavior.NotifyNpcCrownAgenda` appears as the nearest non-`BellumCivileNotifications` frame when the exact NPC Crown branch displays the native notice, with no changes to player-visible text/visibility. The Bellum persisted `CourtAgendaId` remains the **authoritative state identity**, not proof that an OS toast was shown.
**MUST NOT CHANGE:** exactly one notification attempt per attached NPC ticket, no extra notification for privately staged tickets, same color/text/kingdom/player notification scope, idempotency after reload, Court priority and timing, all other shared court notices and events.

## Regression contract — source and compiled fixtures
1. Positive: attaching an eligible NPC Crown ticket changes only native agenda to `Announced` with the same exact `IntegrationId`; exactly one display attempt and same log. The new method name is distinct and marked `NoInlining`.
2. Negative: staged-only, invalid ruler/target, occupied Court slot, stale/replay ticket remain unannounced and create no extra notification.
3. Neighbor: all existing other `NotifyAgenda(agenda)` callers remain bound to their original unmodified helper, with identical display/filter semantics.
4. Presentation equality: body has same `TextObject` key/content, same `REALM` and `AGENDA` vars, `DescribeAgenda` call, `BellumNotificationColors.Politics`, `primaryKingdom: agenda.Realm` and previous log template.
5. Bridge compatibility: current `FindBellumCaller` can name a dedicated method on the stack, but Bridge must NOT yet suppress/publish based only on this: no native `CourtAgendaId` exists in the existing notification parameters. A later stage must prove exact matching against Bellum `GetNpcTreasonIntents` and establish one owner.
6. MCM Bellum notification scopes (Disabled/Global/player realm) are not altered. When suppressed, Bellum persists the agenda and its read-only snapshot regardless of native toast visibility.
7. All existing Stage 5–11 source/compiled runtime tests and Bellum Court Executive Scheduler pass; owner-side native Bannerlord 1.4.8 build and live copied-save/game behavior remain pending.
8. Only exact named production files and test edits, no opportunistic refactor. No sidecar fact or extra public event until duplicate-owner and EventId knowledge correlation contract is later satisfied.

**Expected future evidence:** Bellum log `AIInfluence NPC Crown intent attached; ... agenda=...; status=court_announced`; Bridge (with future adapter) notification capture caller `BellumCivile.Behaviors.CourtAgendaBehavior.NotifyNpcCrownAgenda` only if scope allowed. `BRIDGE_V1_NPC_CROWN_ADMISSION_SHADOW` still `publication_blocked=true`; no Stage15 sidecar new fact.
