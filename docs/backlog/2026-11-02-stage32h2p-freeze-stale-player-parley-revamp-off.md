# Stage32H2P — Freeze previously pending Bellum player treaties when Revamp OFF

**2026-11-02 · internal surgical candidate · not yet Windows/game verified.** User-approved continuation after Stage32H2O architecture HOLD; selected minimal **FREEZE** (not cancel, not AII handoff). Native Bellum Civile **mod** planned 1.4.5 for Bannerlord **game** 1.4.8. No per-stage DLL replacement; all executable tests deferred to the coordinated integrated alpha QA in [Bellum Bridge #92](https://github.com/AIRebelRelay/Bannerlord2-AiInfluence-BellumCivile/issues/92). No actions or main/release merge.

## Source lock

- **Native Bellum**, repo `AIRebelRelay/BellumCivile`, branch `feature/stage32h2p-freeze-stale-player-parley-when-revamp-off-2026-11-02`, based on H2O audit `b7ccf23b1b686079f209ce522e1961da0dee9ad0` which contains Native H2N/H2H fixes.
- Regression-first test `Tests/Stage32H2PFreezePendingParley.Tests.ps1` committed **before** production at `3bbc0057458981160ef9011c09d130d217e57421`; one-function-file production `7c1c03fb7337fb898cd62f748728a22b4913e7c8`.
- Related H2O deliberately RED `Tests/Stage32H2OPendingParleyOffFence.RED.Tests.ps1` is now addressed in source. It is still **not executed**.
- **Bellum Bridge** repo `AIRebelRelay/Bannerlord2-AiInfluence-BellumCivile` H2M `4ce6187aaf2f3c9c0f0510c144abd137fae33d19` unchanged; **separate Relay Bridge** `AIRebelRelay/ai-rebel-relay-bridge` and Relay backend unchanged.

## ROOT CAUSE / call-chain

1. Native `ForeignTreatyBehavior.TryQueueParley` and `OnDailyTick` correctly block **new** Native parley while Revamp OFF.
2. A **saved existing** `TreatyProposalState.ParleyPending` may still be referenced by `UI/Parley/PeaceParleyVM` after the toggle. `ExecuteSignTreaty` → public `TrySignPlayerParley` → `SpendCouncilCommitments`, `SpendRulerOverride`, `ApplyTreaty` / `ApplyTreatyCore` → `MakePeaceAction.Apply`, transfers and council effects. `ExecuteRejectTreaty` → `TryRejectPlayerParley` can spend refusal override.
3. Additional public UI mutation entry points: `TrySetPlayerVote` (vassal vote), `TryReplacePlayerDraft` (terms and council snapshot), and `TryOpenPlayerParley` (may normalize an existing pending draft and open new UI despite OFF). `OnTick` calls `TryOpenPlayerParley` for deferred handoff. Existing `ExecuteClose` simply invokes `_closeAction`, so no UI patch is needed.
4. An early guard *only* at `ApplyTreaty` would be insufficient to stop **earlier influence spending** or to preserve pending state. Guarding just Sign would not freeze Vote/Draft/Reject. Therefore use five **narrow public entry guards**, no shared helper changes.

**Scope of demonstrated defect:** source-callable stale player actions; **not a reproduced in-game incident**. AII foreign-ledger ownership and Bridge H2L/H2M remain independent. Internal/civil treaty semantics must not be globally rewritten.

## CHANGE BOUNDARY

**TOUCH:** `Behaviors/ForeignTreatyBehavior.cs` ONLY, and exactly these five methods:
`TrySetPlayerVote`, `TryRejectPlayerParley`, `TrySignPlayerParley`, the full `TryOpenPlayerParley(..., Kingdom drafter, Action onClosed, out string report)` overload, and `TryReplacePlayerDraft`.

Each begins, immediately after its existing initial `report`, with the same:
```cs
if (!WarPeaceRevampBehavior.IsRevampEnabled())
{
    report = "Bellum foreign treaty is frozen while War & Peace Revamp is disabled";
    return false;
}
```
No logging spam, no state change, no timer/saved migration. Preserve original ON code **byte-for-byte** outside these 5 inserted early exits. Two nonproduction files: RED-first test and this audit/handoff note.

**DO NOT TOUCH:** `ApplyTreaty`/`ApplyTreatyCore`, `TryPreparePendingProposalDraft`, `TryQueueParley`, `OnDailyTick`, `OnTick`, `OnHourlyTick`, UI VM, Native WarScore/Custody/F1, CivilWar/ClaimFeud, campaign SaveableFields, Harmony, either Bridge, Relay, Sidecar/ACK or LLM prompts.

**MUST FIX:** when OFF, existing player pending proposal is **frozen**: Sign/Reject/Vote/Edit/Open all return `false` with readable reason **before** any proposal changes, influence expense, terms transfer, UI reopening or peace. `ExecuteClose` remains usable and does not delete pending state.

**MUST NOT CHANGE:** normal Revamp ON signing, ruler/vassal influence, council acceptance, draft editing and player opening; OFF new queue and daily automatic treaty already blocked; existing pending foreign proposal and save retain state so ON can resume, subject to the **original** dynamic revalidation; internal CivilWar/ClaimFeud, AII/vanilla foreign diplomacy, treaty deliveries from an **already applied** treaty and all Native WarScore accounting.

## Regression contract (first source test, then one integrated alpha)

- **H2P-01** ON player ruler with ordinary existing foreign parley: Sign, Reject, Edit Draft and Open behave identically, including exact influence council/override, terms, peace and former failure paths.
- **H2P-02** ON player vassal: exact Vote/Commitment/Abstain and Sign paths preserved, no new costs or blocked callbacks.
- **H2P-03** OFF after ON while UI is still open: Sign, Reject, Edit Draft, Set Vote all return false + freeze message. Compare `TreatyProposalRecord.State/Terms`, `WarScoreRecord.ParleyPending`, council influence, gold/tribute, hostages/territories, war stance before/after. Close UI still works. No `MakePeaceAction.Apply`.
- **H2P-04** OFF restored save `ParleyPending` and deferred player inquiry/OnTick: no new UI/draft normalization or council change. Pending state retained, no new `Foreign treaty parley queued`.
- **H2P-05** OFF→ON same session or after save: pending treaty can reopen via original code, but source revalidation may cancel stale terms; *only original rules* decide; no phantom extra influence.
- **H2P-06** New Bellum treaty under OFF still denied; Bellum Bridge H2L four-kind AII passthrough, Native H2M F1 WarScore accounting, H2N prisoners remain fully functional; no autonomous foreign peace.
- **H2P-07** Mixed AII-ledger foreign war and old non-AII saved Bellum proposal, internal civil/claim cases, player vs NPC kingdoms, save S1→S2→S1, Revamp toggles: no wrong treaty key, no cross-state execution, default-OFF remains intact.
- **H2P-08** Run Native H2O RED and H2P source tests with PowerShell and verify success, existing Native treaty/council/WarScore tests, real net472 Bannerlord 1.4.8 build, Bellum Bridge H2M build and full game/GUI/log validation. Source audit alone not PASS.
- **H2P-09** Peripheral hourly behavior: `OnHourlyTick` executes `RecoverTreatyDeliveries` and previously-applied rebellion resolution independently of new treaty queue; validate pre/post save when OFF. Distinguish already-applied treaty consequences from stale `ParleyPending` freeze. **No code change in this stage**.
- **H2P-10** Deferred `OnTick` may attempt a protected `TryOpenPlayerParley` again each frame while OFF. Check for FPS/log churn; do not modify shared deferred-request lifetime without a separately scoped measured performance regression.

## Complete diff audit, evidence, expected logs

Post-code direct source comparison removes exactly **five identical inserted gates** and returns the **byte-identical original `ForeignTreatyBehavior.cs`**. Initial structured checks **7/7** passed; all five gates precede the first proposal access. RED test committed before production change. This is source inspection, **not execution of PowerShell, C#, Bannerlord or save tests**.

When clicking a frozen action, expect UI failure reason `Bellum foreign treaty is frozen while War & Peace Revamp is disabled`, with **no** `Foreign treaty applied`, `Foreign treaty rejected` or `Player treaty vote updated` generated by that click, and no new forced peace/MakePeaceAction. No new dedicated log line is emitted by these guards; inspect UI action + actual proposal/influence/war world-state.

**Status:** H2P Native source candidate only. H2O RED moves from intentionally unsatisfied code contract to source-addressed, but not executed. P0 #89 remains OPEN, release **NO-GO** pending coherent Bellum mod 1.4.5 / game 1.4.8 metadata, four repo build, integrated alpha test and save rollback. Do not replace per-stage DLLs or merge main yet.
