# Stage 31K — Native realm-court policy vote disclosure proof

**2026-10-30 | Surgical Native source patch, NOT build/save-load/game/release PASS.**
Owner only tests one final integrated alpha. No Actions, user DLL swap, main merge or release.

## Git identity
- Correct repo **AIRebelRelay/BellumCivile** (Native Bellum 1.4.5).
- Base audit Stage31J HEAD **d36e6ee7d8f565b3a3eb049e7149e9dd9908f012**.
- Branch **feature/stage31k-native-policy-vote-realm-court-proof-2026-10-30**.
- Test-first RED commit **ad6a082dc587cb95904b62c238e804f7db7453d5**.
- Bellum Bridge distinct repo **AIRebelRelay/Bannerlord2-AiInfluence-BellumCivile** remains Stage31I **50ab265e598a452a038d4139258b7026504a1590**. Relay **AIRebelRelay/ai-rebel-relay** remains **97d10bfaee4eb2949e8d66be8b5107591513ed9b**; separate ai-rebel-relay-bridge NOT touched.

## Root cause, call chain and blast radius

Native source shows concrete Bellum vote chain:
`KingdomPolicyDecision.ApplyChosenOutcome` → existing Harmony `PolicyVoteResolutionPatch.Postfix` → calculates `motionSucceeded` against `kingdom.ActivePolicies` and calls `CourtAgendaBehavior.Current?.Conclude(kingdom, policy, proposer, abolish, motionSucceeded, __state)`.
`CourtAgendaBehavior.Conclude` identifies the matching agenda, avoids re-application, writes `ResultApplied`, `PaymentSettled`, `Passed|Defeated`, calls existing `GetObjective`, checks obsolete faction mandate, applies existing reaction history, renders the existing realm-filtered UI notice and logs conclusion.

Source search for the exact call via GitHub code-search did not surface results, so the specific checked callsite is source-backed by `Patches/PolicyVoteResolutionPatch.cs`, not a claim of exhaustive whole-repository caller enumeration. Any downstream caller invoking the *public* `Conclude` directly is a validation risk; real game call-chain regression remains required. Other known consumers of `CourtAgendaBehavior`, `SyncData`, `CourtAgendaRecord` and `CourtObjectiveRecord` remain untouched.

Existing Stage31F/G source archive is merely technical terminal state; Stage31I Bridge cannot safely publish its payload as public news. Bellum `ShouldShow` gates **human player UI**, not audience of an in-world vote. W7 already owns actual `policy_enacted|policy_repealed` effects.

## Declared boundary

**ROOT CAUSE:** completed Native Court policy votes have stable outcome identity but no separately saved source-local **realm-court disclosure provenance**. Cannot establish it from `Passed` alone, from UI settings, from old notifications or by guessing from the future eviction archive.

**TOUCH (2 production files only):**
1. **NEW** `Behaviors/CourtPolicyVotePublicProvenance.cs` — isolated partial `CourtAgendaBehavior`, saved primitive `Dictionary<string,string>` `BC_CourtPolicyVotePublicProvenance_v1` keyed by exact existing `IntegrationId`, separate int `BC_CourtPolicyVotePublicProvenanceOverflow_v1`. Copy-only v1 record with base64-UTF8 realm/policy/sponsor IDs, action, vote outcome, exact `realm_court`, origin `court_policy_conclude`, `obsolete_mandate|current_mandate`, invariant **observation day**. Cap 1024, dedupe, explicit overflow, fail closed with held/error diagnostics.
2. `Behaviors/CourtAgendaBehavior.cs` — one `SyncCourtPolicyVotePublicProvenance(dataStore)` in existing save sequence and one `RecordCourtPolicyVotePublicProvenance(agenda, policy, abolish, passed, obsoleteMandate)` **after existing conclusion UI and log**.
3. **NEW** `Tests/Stage31KPolicyVotePublicProvenance.Tests.ps1`; this handoff.

**DO NOT TOUCH:** source `Patches/PolicyVoteResolutionPatch.cs`, `BellumCivileNotifications` / UI settings, native shared `CourtPolicyObjectiveBridge.Refresh`, `CourtAgendaRecord` / `CourtObjectiveRecord` save fields, `BellumCivileSaveDefiner`, Court session scheduler/mood/influence/refunds, executive/council/Crown/civil/war/peace code, Native Stage31F/G saved terminal ledger and API, W7 Court Event Feed, Bellum SidecarWriter, Relay, AI Influence and Relay Bridge.

**MUST FIX:** exact realm-court source evidence for completed Native **policy votes only**, based on validated `ResultApplied`, exact `Passed/Succeeded/Sponsor` or `Defeated/Failed/None`, matching objective kind=policy, target=policy ID, action=enact|repeal, valid realm, sponsor, GUID IntegrationId, no technical cancellation; preserve `obsoleteMandate` to avoid false faction endorsement. Record independently of Bellum notification UI option. No duplicate proof for same ID.

**MUST NOT CHANGE:** law enactment owner (W7), result or original notification text, source vote approval/expense, appearance of Court dialogue, finite Relay events, NPC knowledge, existing save schema, any other Court objective. No `world_public` inference and no automated event injection.

## Regression-first and exact diff audit

- At test-first commit, both save call and Conclude proof hook were demonstrably absent (expected **source RED**). The PowerShell regression script itself has NOT been executed in this environment.
- After patch, **18/18 deterministic read-only source assertions PASS**, including fixed patch caller, two hooks, saved keys/primitive registration, exact objective outcome/credit, dedupe/overflow and strict realm identity, no Bridge or Native ACK, existing UI / Stage31F/G preservation, previous Stage31J source test present.
- **Full diff audit before this document:** only `Behaviors/CourtAgendaBehavior.cs` (+2, -0), NEW `Behaviors/CourtPolicyVotePublicProvenance.cs` (+115), NEW PS1 source regression (+65). Verified the existing `CourtAgendaBehavior.cs` reconstructs byte-for-byte to Stage31J HEAD when the two intended insertions are removed. No refactors, changed conditions or deletions.

## Live and negative tests to execute before alpha acceptance

**Positive:** real native post-policy-decision `Passed` and `Defeated` through `PolicyVoteResolutionPatch.Postfix`; exact same IntegrationId after game save/load; realm-court proof persists even with player UI `Disabled`; retry of already-concluded vote creates no second proof; obsolete-mandate preserves a neutral vote result, not faction endorsement; source proof action corresponds to enact/repeal regardless of law being active.

**Neighbor:** actual policy active/inactive state remains source truth in W7, and `policy_vote_closed_without_law_change` is not misreported as defeat. Existing faction mood, turncoat/relation changes, influence costs/refunds, election/override, notifications and personal toasts unchanged. Council appointments, partial activities, executive treason, peace/war, crown, civil and other Court paths create NO policy provenance.

**Fail-closed:** malformed/legacy IntegrationId, invalid/temporary realm, null sponsor/target, cancellation, mismatched objective state/credit/action/kind must not record. Missing source proof remains `unknown`, not retroactively inferred. Duplicate same ID is a no-op; overflow is logged and blocks final alpha. One corrupted save or external incompatible mod method call cannot be assumed safe without the actual game regression.

**Expected Native log:** `BC_COURT_PUBLIC_PROVENANCE status=recorded; id=...; realm=...; audience=realm_court; source=court_policy_conclude; result=passed|defeated; ... law_effect_owner=w7; relay_emitted=false`.
Negative logs: `status=held; reason=invalid_policy_vote_identity|unverified_policy_vote`, `status=overflow`, `status=capture_error`. **Any overflow or unexpected error is a release blocker.**

**Not tested:** PowerShell test run, dotnet/MSBuild, actual Bannerlord load/save, game event sequencing, Relay acceptance, NPC `DynamicEvents[]`. No .NET or `pwsh` available in this workspace. This stage does NOT emit Bellum Sidecar events.

## Next isolated Stage31L

Source-first review of how a Bridge reader can join Stage31F/G terminal receipts with Stage31K independently persisted policy-vote provenance by `IntegrationId`, while preserving campaign/realm scope, strict v1 schema, action/result agreement, W7 ownership and private-results exclusion. DO NOT immediately modify Stage31G’s opaque 13-field v1 record format or Stage31I raw terminal candidate classifier. Add a dedicated safe **Native read-only proof projection** before Bridge uses the saved map; require strict data provenance and audience. Actual publish/ACK requires a proven source-specific transport + crash semantics and an independent Relay/named-NPC E2E contract.
