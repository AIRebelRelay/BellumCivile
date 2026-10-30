# Stage 31L — Native read-only joined Court policy vote provenance

**2026-10-30 | isolated Native source patch | NOT compiled/game-tested.**
Owner runs only final full integrated alpha. No per-stage DLL replace, GitHub Actions, main merge or release.

## Git source / pin
- Correct repo **AIRebelRelay/BellumCivile**. Branch `feature/stage31l-native-court-policy-vote-joined-readonly-2026-10-30`.
- Parent **Stage31K HEAD** `ec93ccd7c3b88b4401f62fffface8208835cceb0`; source contract first RED `3e48586c2f0fc985f020f2c4a54f4c61844412f2`.
- Bellum Bridge **AIRebelRelay/Bannerlord2-AiInfluence-BellumCivile** remains Stage31I `50ab265e598a452a038d4139258b7026504a1590`.
- Relay **AIRebelRelay/ai-rebel-relay** remains `97d10bfaee4eb2949e8d66be8b5107591513ed9b`; separate `ai-rebel-relay-bridge` untouched.

## ROOT CAUSE / call chain

- Stage31K `CourtAgendaBehavior.Conclude()` saves explicit source-authored realm-court policy **vote-result provenance** during its actual completion, by persistent `IntegrationId`, with policy, sponsor, realm, action, passed/defeated, obsolete mandate marker, and **vote observation day**.
- Stage31F `CaptureEvictedCourtTerminals` saves an independent receipt when a finalized agenda is about to be evicted in the Native Court/Claim/Rally maintenance paths; it does not promise simultaneous availability with Stage31K.
- Stage31G `GetCourtTerminalEvictionInventory` exposes private *raw technical* receipts separately; Stage31I Bridge diagnostic observer deliberately does not publish them. A later Bridge publisher must not independently trust either stream: joining only on ID without checking all source fields could produce false credit, wrong realm or unauthorized news.
- Native internal maps both persist with `Dictionary<string,string>` containers already known to `BellumCivileSaveDefiner` and have distinct 1024 caps/overflow counters. W7 remains canonical owner of actual `policy_enacted|policy_repealed`, independent of vote result.

## CHANGE BOUNDARY

**TOUCH**:
1. New `Behaviors/CourtPolicyVoteProvenanceJoin.cs` — read-only partial `CourtAgendaBehavior.GetPolicyVoteProvenanceJoin(Kingdom)`; parses saved **proof v1 10 fields** and terminal **v1 13 fields**, reuses existing `TryReadCourtTerminalPayload` Native validation, cross-checks source identity and chronology.
2. New `CourtPolicyVoteProvenanceJoinSnapshot.cs` — immutable public projection: `Matched[]` of `Id`, `RealmId`, `PolicyId`, `SponsorId`, `Action`, `VoteOutcome`, `ObsoleteMandate`, `Audience=realm_court`, `VoteDay`, `ReceiptObservedDay`, plus explicit source-health counters.
3. `BellumIntegration.cs` +12 lines: new `GetCourtPolicyVoteProvenanceJoin(Kingdom realm)` with `RequireCampaignThread()`; null/unavailable behavior fails closed.
4. New `Tests/Stage31LPolicyVoteJoinedReadOnly.Tests.ps1`, this handoff.

**DO NOT TOUCH**:
- Native Stage31F/G `CourtTerminalEvictionReceipts.cs` and its 13-field v1 schema, Stage31K `CourtPolicyVotePublicProvenance.cs` and its 10-field v1 schema, shared Court `SyncData`, `GetObjective`, `CourtPolicyObjectiveBridge`, save registration or any Court mechanics.
- Stage31I Bridge diagnostic, Stage31H inert fact-specific spool seam, W7, Relay ACK/event filters, AII, NPC memories, personal notifications, Crown/civil/foreign rules and Relay Bridge.

**MUST FIX**:
- Expose only **matched, explicitly realm-court source-authored votes**, not raw terminal data or unauthenticated vote candidates.
- Join exact saved `IntegrationId` GUID-N; prove exact realm, sponsor, policy target, policy kind, action `enact|repeal`, `Passed/Succeeded/Sponsor` or `Defeated/Failed/None`, cancelled reason empty, and Native policy objective `ResultReason` exactly Passed/Defeated.
- Source proof must explicitly say `v1|...|realm_court|court_policy_conclude|current_mandate/obsolete_mandate|vote_day`. Terminal capture observation day must not be before vote day.
- Strict UTF-8/base64 and finite nonnegative double day; ignore malformed/unsupported future schemas; no world-public authorization from UI settings or completed state.
- Return per-realm matched votes in stable ID order, global terminal/proof invalid and overflow counts, per-realm conflicts/missing proof/awaiting eviction metrics. On **any invalid record, conflict or overflow**, `IsHealthy=false` and `Matched` empty. Old saves missing Stage31K proof are *held*, never retroactively promoted.

**MUST NOT CHANGE**:
- Existing world state, vote outcomes, UI messages, mood, costs, schedule, Native ledger content/limits, law effects, W7 canonical law events, previously registered API semantics. No acknowledgement, Relay event publication or private content in new DTO.

## Regression contract (defined before implementation)

Positive:
- Stage31K policy vote concludes, Stage31F later archives same agenda; matching v1 records yield **one** `Matched` receipt per ID for the correct realm. IDs persist through save/load. Reading twice cannot modify either map. Same policy but different agenda IDs remain distinguishable.
- Passed requires `Passed/Succeeded/Sponsor`; defeated requires `Defeated/Failed/None`. `obsolete_mandate` retained as distinct marker; no endorsement implied.
- Absent terminal receipt while Native agenda remains active → `AwaitingEvictionCount`; policy terminal without source proof → `MissingProofCount`; no premature event.

Negative:
- Wrong ID, realm, sponsor, policy, action, outcome, objective reason/credit, flipped observed days, cancellation, `FulfilledElsewhere`, `NotProposed`, secret/technical records, old schema or malformed GUID/base64/UTF-8/day never match.
- Corrupt data or `OverflowCount>0` → global health fails closed with `Matched=[]`, not a spurious success. Proof/receipt same ID but incompatible semantics → `ConflictCount`, blocks matching. Null behavior or missing realm → `SourceAvailable=false`.
- No changes to neighboring native old APIs, W7, Bridge, Relay; no cross-realm leakage, no additional Harmony or event scheduler.

## Evidence / what is not proven

- Test-first source RED: before implementation new DTO/API/join did not exist.
- Source-only post-patch checks covered strict v1 decode, source/audience, cross-field outcome/credit/chronology, conservative bad-health behavior, absence of mutation/ACK/publishing, old save keys and previous Stage31K source contract. Existing `BellumIntegration.cs` reconstructed byte-for-byte from changed file after stripping its only additive method; Native existing ledgers are not edited.
- **PowerShell test not executed, no dotnet/mcs/csc/pwsh available**, no .NET build, DLL replacement, save/reload, game logs or AII named NPC `DynamicEvents[]` evidence. Compiles and source tests remain release gates.
- No automatic Stage31L log (read-only); current Native logs still `BC_COURT_PUBLIC_PROVENANCE status=recorded|held|overflow` and `BC_COURT_TERMINAL_EVICTION status=recorded|overflow`.

## Next single stage

**Stage31M**: Bellum Bridge read-only consumer for Native `GetCourtPolicyVoteProvenanceJoin`. Validate campaign thread, `IsHealthy`, realm scoping and full DTO schema before an allowlisted source publication. Report only aggregate evidence; do not change Stage31I diagnostics or W7 or publish to Sidecar until real Windows atomic spool/disk durability, duplicate semantic ownership and exact Relay-to-AII named NPC EventID contract are proven. Native ACK remains absent. Integrated alpha remains blocked by both 1024 bounded stores and no live test.
