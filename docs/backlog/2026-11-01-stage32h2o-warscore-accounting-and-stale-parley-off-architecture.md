# Stage32H2O — F1 WarScore accounting invariants and stale player treaty OFF architecture review

**2026-11-01 — AUDIT + RED ONLY. NO PRODUCTION PATCH.** Native Bellum `AIRebelRelay/BellumCivile`, branch `audit/stage32h2o-reversible-warscore-and-parley-off-fence-2026-11-01` from H2N `924c812ce5604f4536926ea41d9142eb6e7a0fc5` (H2N includes Native H2H provenance). The paired **Bellum Bridge** H2M `AIRebelRelay/Bannerlord2-AiInfluence-BellumCivile@4ce6187aaf2f3c9c0f0510c144abd137fae33d19` already provides final-verified AII foreign ledger opt-in; **Relay Bridge** `AIRebelRelay/ai-rebel-relay-bridge` and Relay backend unchanged. Bellum Civile **MOD planned 1.4.5**, Bannerlord **GAME 1.4.8**.

### ROOT CAUSE / decision to stop patch chains

H2L fixed one Bellum Bridge entry to avoid treating a WarScore ledger as foreign-treaty authority; H2M added final verified opt-in registration; H2N restored prisoner custody reversal. These are multiple adjacent war/diplomacy changes. Per regression-first surgical mode **STOP adding independent flags to shared methods** until the invariant across every entry and saved pending-state is audited.

**Ownership invariant:** For a Native record marked `aii_foreign_ledger:v1:<exact AII event>`, Bellum is an **accountant only**. Revamp OFF denies Bellum settlement *regardless of where a treaty was queued, how it was restored, and whether a stale player UI remains open*. Only AII owns external peace/negotiation. This must not disable Bellum civil/claim conflicts or existing valid Bellum Revamp ON treaty flows.

### Complete source findings (HEAD pinned above)

1. `WarScoreBehavior` tracks AII foreign war occupation by recalculating against the saved starting fief snapshot daily (`UpdateOccupationScore` -> `CalculateOccupationScore`). Capture and recapture reverse the occupation component; not a second demonstrated bug. H2N now allows prisoner capture **and release/death/reconciliation** even with Revamp OFF, only if an open AII ledger exists. `WarScoreRecord` keeps reversible prisoner custody and occupation as components; ordinary battle and raid credits represent historical events, ticking leverage accumulates over time and is not automatically a refund on reversal. Do not assume they are all reversible or clear them on recapture.
2. The AII branch of `WarScoreBehavior.ProcessActiveWars` calls only `UpdateOccupationScore` and `ApplyTickingLeverage`, then `continue`: it intentionally bypasses `TryForceFullOccupation`, `ApplyLandlessRealmPressure`, `QueueTerminalWarScoreResolution`. `ShouldPreventAutonomousForeignResolution` also refuses queue/resolve and `ResolveTerminalConflict` for AII foreign ledgers, even if Revamp is toggled ON later. The daily `ReconcileAiInfluenceForeignLedgers` closes ended wars and clears old terminal flags; SaveableField 17 stores the exact AII ContextId, no schema migration required for H2N.
3. Bellum `ForeignTreatyBehavior.TryQueueParley` **does** explicitly reject Revamp OFF before creating new parley/proposal. The Native treaty `OnDailyTick` also exits when OFF, and `WarPeaceRevampBehavior` normal diplomacy entry checks `IsRevampEnabled`. So normal NEW Bellum peace is gated.
4. **Gap: direct STALE PLAYER PARLEY UI route is not covered.** `UI/Parley/PeaceParleyVM.ExecuteSignTreaty()` calls public `ForeignTreatyBehavior.TrySignPlayerParley(proposalId,...)` directly. That Native method finds already-`ParleyPending` saved proposal, uses `TryPreparePendingProposalDraft`, may `SpendCouncilCommitments` / `SpendRulerOverride`, then `ApplyTreaty` -> `ApplyTreatyCore` (territorial/financial terms and peace), **without checking `IsRevampEnabled` at the signing boundary**. `TryPreparePendingProposalDraft` and `ApplyTreaty` likewise lack the gate. This is a source-demonstrated bypass **only if a proposal/UI remains reachable after Revamp toggled OFF or a saved pending proposal is restored**; it is NOT yet a game-proven forced peace.
5. Adjacent `TryRejectPlayerParley` can spend a rejection override while OFF for an already pending proposal; `GetPendingProposalForPlayer` can still enumerate pending proposals. Whether to cancel, freeze, or let the player harmlessly reject an old offer under OFF is **not defined**. Do not silently decide the policy by modifying shared `TryPreparePendingProposalDraft`, `ApplyTreaty` or `ForeignTreatyBehavior` callers.

### CHANGE BOUNDARY (this stage)

**TOUCH:** only `Tests/Stage32H2OPendingParleyOffFence.RED.Tests.ps1` (intentionally RED on current source) and this architecture document; GitHub P0/alpha QA issue entries and Drive MASTER HANDOFF. No production C#.

**DO NOT TOUCH:** `ForeignTreatyBehavior.cs`, `WarScoreBehavior.cs`, `WarScoreRecord.cs`, `WarScoreCustody.cs`, `WarPeaceRevampBehavior.cs`, `UI/Parley`, civil/claim modules, save schema, Harmony, AII 6.0.2, Bellum Bridge H2L/H2M, Relay Bridge/Relay, Sidecar/ACK, or any `main`/release.

**MUST FIX in a future separately approved stage:** prevent an old pending Bellum treaty from ratifying or spending council/ruler influence after Revamp OFF; define explicit behavior for existing pending UI/proposal, same-save toggling, and OFF->ON reactivation before selecting the exact function patch. Existing new-treaty OFF guard and accounting/terminal protections stay intact.

**MUST NOT CHANGE:** Revamp ON player sign/reject/draft/council semantics, disabled new-queue, AII foreign peace, civil/claim settlement ownership, no-loss saved pending proposals, existing GUI and Council events.

### RED contract and exact test matrix — alpha PENDING

- `Tests/Stage32H2OPendingParleyOffFence.RED.Tests.ps1` created *without implementation* to assert direct player sign cannot reach `SpendCouncilCommitments` / `ApplyTreaty` when OFF. It intentionally expects a missing gate and **must not be called passing or shipped as a blocking CI assertion without a designed fix**. Do not use a fake source-only PASS as proof of safe in-game state.
- **H2O-01:** Revamp OFF + fresh F1 ledger: occupation captured/recaptured follows world-state owner (positive and negative), ticking advances once per day, no auto parley or forced peace.
- **H2O-02:** Revamp OFF prisoners: H2N capture/release/death/save restoration; raids and battles are historical bounded scores, not reversed merely because land is recaptured.
- **H2O-03:** Revamp OFF with **old Bellum player pending parley from Revamp ON** and an already-open PeaceParley UI; click Sign. NO council influence spend, treaty execution, fief/hostage/tribute transfer or `MakePeaceAction.Apply`. Verify actual GUI action and source-side logs.
- **H2O-04:** Same pending parley restored from a save with Revamp OFF; UI may reopen through `GetPendingProposalForPlayer`; sign/reject/draft should have explicit, no-surprise policy and no unauthorized influence spend.
- **H2O-05:** Revamp OFF->ON with existing pending treaty, separate legacy pending from F1 AII ledger; choose either replay/freeze/cancel behavior **before patch**. When ON normal Bellum treaty sign and civil/claim settlements must continue.
- **H2O-06:** With Revamp OFF new foreign `TryQueueParley` and Bellum treaty daily tick stay blocked, Bridge H2L four-way native-AII passthrough remains intact; no other external-war interception through UI.
- **H2O-07:** Native F1 `ReconcileAiInfluenceForeignLedgers` old terminal flag cleanup, peace/kingdom elimination, saved ContextId, S1→S2→S1 rollback and old Native saves preserve AII accounting; no false latest event/forced peace.
- **H2O-08:** Four-repo integrated alpha build/test with Bannerlord GAME 1.4.8, Bellum MOD planned 1.4.5, Bridge 0.8.6, Relay and Relay Bridge source heads pinned; Court/W7/Council/Crown and other war/peace/Sidecar/ACK unchanged.

### Evidence standard / release status

This stage makes no production change, performs no actual Windows PowerShell or C# execution, DLL compile, game or save tests, and no paid GitHub Actions. The future blocker is **source-proven possible execution path, not confirmed exploit in-game**. Until owner approves policy and a future surgical fix passes tests, classify *pending player treaty signing after Revamp OFF* as **P0 #89 alpha-blocking scenario to investigate**. P0 #89 remains OPEN; no main merge/alpha GO.

References: [Bellum Bridge P0 #89](https://github.com/AIRebelRelay/Bannerlord2-AiInfluence-BellumCivile/issues/89), [Alpha QA #92](https://github.com/AIRebelRelay/Bannerlord2-AiInfluence-BellumCivile/issues/92).
