# Stage32H2Q — Deferred Bellum player parley fast-return on Revamp OFF

Date: 2026-11-02. **NATIVE Bellum only; regression-first surgical source candidate, not a verified build/game fix.** Planned Bellum Civile **mod** 1.4.5 for Bannerlord **game** 1.4.8. User requires one integrated alpha QA, not per-stage DLL changes. Permanent alpha checks: [Bellum Bridge QA #92](https://github.com/AIRebelRelay/Bannerlord2-AiInfluence-BellumCivile/issues/92).

**Repo/ancestry:** `AIRebelRelay/BellumCivile` branch `feature/stage32h2q-deferred-parley-tick-off-gate-2026-11-02`, based on H2P `29ff60213bcbfb98a885f86bf60041f95ce7dde0` (includes Native H2H/H2N and five H2P player-action freeze guards). Test created `fc108945f49e92f0f6d8c965fd65c7ad4bd6b0cc`, corrected source contract `ca5393be3ec3b251a6b9a2e1fb1a436698aa945c` **before** production commit `edcd4e97f25941740f99ecc263f3dccb7affa384`. Bellum Bridge H2M `4ce6187aaf2f3c9c0f0510c144abd137fae33d19`, **distinct Relay Bridge** and Relay backend unchanged.

## ROOT CAUSE / exact call chain

`ForeignTreatyBehavior.RegisterEvents` subscribes `CampaignEvents.TickEvent` -> `OnTick(float dt)`. If a player has accepted the forced envoy inquiry, its callback sets `_pendingPlayerParleyOpenProposalId`. The H2P `TryOpenPlayerParley(...)` public action now **refuses** when War & Peace Revamp is OFF. But `OnTick` previously kept the pending ID, performed `EnsureCollectionsInitialized`, queried `_proposals` and `WarScoreBehavior.GetActiveWars`, resolved the drafter, then called the guaranteed-failing `TryOpenPlayerParley` on every eligible tick. The failure intentionally did not clear the ID, to allow delayed UI opening. Thus OFF caused repeated **source-proven avoidable work**, but **there is no measured FPS degradation or observed log storm**.

`WarPeaceRevampBehavior.IsRevampEnabled()` simply returns `BellumCivileOptions.EnableWarPeaceLogicRevamp` (verified). It is not a shared-state mutation or expensive lookup.

## Surgical boundary

**TOUCH:** one conditional in **`Behaviors/ForeignTreatyBehavior.cs::OnTick`** and one new RED-first `Tests/Stage32H2QDeferredParleyTickOff.Tests.ps1`, this doc, central alpha QA #92, P0 #89 and MASTER HANDOFF on Drive.

Exact production delta, adjacent to preexisting empty-ID/inquiry/overlay gate:

```cs
|| PeaceParleyInterface.Instance.IsShown
|| !WarPeaceRevampBehavior.IsRevampEnabled())
```

With OFF, early-return before scanning proposals/war, **preserving the deferred proposal ID**. With ON, original lookup, UI transition retries, success logs and invalid-war/proposal cleanup remain intact.

**DO NOT TOUCH:** H2P public Sign/Reject/Vote/Edit/Open guards, `TryOpenPlayerParley`, `TryQueueParley`, `OnDailyTick`, `OnHourlyTick` (already applied treaty effects), Native WarScore/F1/Custody, `SyncData` and save schema, H2H inheritance, internal civil/claim conflict, AII 6.0.2, Bellum Bridge or **separate Relay Bridge**, Relay backend, Harmony, Sidecar or ACK, NanoGPT routes.

**MUST FIX:** when OFF + a nonempty deferred ID + no modal/overlay, avoid repeatedly scanning war/proposal and calling guaranteed-refused `TryOpenPlayerParley` every tick. Return without clearing stored request. When ON again, try normally on next eligible tick.

**MUST NOT CHANGE:** no-pending ID cheap return, active inquiry/overlay safety, valid ON deferred opening/closing, transient screen transition retry, expired/missing proposal and ended-war cleanup upon ON, forced inquiry flag lifecycle, old proposal saved states, UI/player actions and treaty results.

## Alpha regression contract — all pending

- **H2Q-01 OFF pending valid:** simulate forced envoy callback → `_pendingPlayerParleyOpenProposalId` nonempty → multiple ticks OFF; **zero proposal collection scan, WarScore query or `TryOpenPlayerParley`**, no new error log/peace/side effect, ID remains.
- **H2Q-02 OFF after inquiry:** callback may set ID after OFF toggle; still no repeated UI work, inquiry and screen management unaffected; valid UI Close remains possible.
- **H2Q-03 OFF→ON same session:** pending ID resumes exact ON opening at first safe campaign tick; no duplicate overlay, `Player parley opened after deferred inquiry handoff` at most once; both pending/forced flags cleared only after success.
- **H2Q-04 ON screen transition:** inquiry active or overlay shown causes early return and later retry, identical to baseline; missing proposal, canceled state or ended war clears IDs, no stale loop.
- **H2Q-05 OFF→ON with pending proposal and save S1→S2→S1:** preserve **saved** proposal, respect explicitly transient/non-SyncData deferred ID and old H2P semantics; do not invent persistence guarantee for the in-memory callback ID.
- **H2Q-06 H2P:** OFF Sign/Reject/Vote/Edit/Open freeze continues with zero council expense; ON behavior still works; Native new parley queue/daily stay OFF; `OnHourlyTick` applied-treaty consequences untouched.
- **H2Q-07 PERF:** instrument exact OnTick invocation/collection scans and UI opening attempts before/after (disable debug before alpha package); compare OFF idle frame rate and logs under the same loaded campaign. Never claim FPS gain without a measurement.
- **H2Q-08** Run `Tests/Stage32H2QDeferredParleyTickOff.Tests.ps1`, H2P/H2O source contracts and all adjacent Treaty/WarScore/GUI regressions; compile real Native net472 against Bannerlord 1.4.8, Bellum Bridge 0.8.6 H2M and AII 6.0.2, then full integrated game/save validation.

**Audit:** RED-first test committed before production. Source comparison confirms **exactly one additional boolean operand in one existing `OnTick` guard**, with all other Native code byte-identical. Initial source audit **7/7**; complete final branch diff must have only one changed C# method, one new PowerShell test, one doc. **No pwsh, C# compiler, Windows .NET, Bannerlord, save or FPS tests executed, no Actions or main merge.**

**Expected in game:** under OFF, no new `Player parley opened after deferred inquiry handoff`, `Foreign treaty applied` or unexpected `MakePeaceAction.Apply` from pending old proposal; when ON, opening should log exactly once after successful safe UI handoff. For performance use profiler/temporary debug instrumentation in dedicated QA, not production logging.

**Status:** H2Q source-level improvement only. P0 #89 OPEN, integrated alpha no-GO until Windows+game evidence; do not ask owner to install DLL for every stage.
