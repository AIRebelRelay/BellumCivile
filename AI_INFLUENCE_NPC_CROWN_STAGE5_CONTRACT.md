# AI Influence + Bellum Civile 1.4.5 — Stage 5 baseline contract
Date: 2026-10-21 | Branch: `feature/1.4.5-ai-influence-npc-crown` | Status: tests only, no runtime integration.

### Fixed target
- **Bannerlord v1.4.8** (confirmed by game owner).
- Upstream Bellum **1.4.5 stable** commit `b1d9a4e8fb74d4f9dd045793c156abeac6f9f4eb`.
- Do not use Bellum 1.4.5b (compiled for Bannerlord 1.5.5 beta).
- Bellum Bridge 0.8.6 production main `dd84f60bd6b467e5ce72ce085471d5864b7cde33`.
- Prior audits in [Bellum Bridge audit archive](https://github.com/AIRebelRelay/Bannerlord2-AiInfluence-BellumCivile/tree/audit/bellum-145-compat-stage2-2026-10-21/docs/compatibility/bellum-145).

### Analysis / ROOT CAUSE
Bridge 0.8.6's Reflection code expects Bellum `CanRulerIndictClan` with 4 parameters; Bellum 1.4.5 supplies 5 including `readOnly=false`. Worse, the existing Bellum `TryStartTreasonVote` NPC path invokes `TryNominateTreason`, which is restricted to `Clan.PlayerClan`. Court agendas must be scheduled and filed by Bellum; direct vote queueing or arbitrary overriding of the Crown docket is unsafe. Released DLL ABI probe found 35/36 shapes, documenting the mismatch independently. No NPC integration API exists yet.

### Change boundary — current stage
**TOUCH:** only `Tests/AiInfluenceNpcCrownBaseline.Tests.ps1`, `.github/workflows/ai-influence-npc-crown-baseline.yml`, this Markdown contract.
**DO NOT TOUCH:** all `Behaviors/*.cs`, existing `BellumIntegration*.cs`, save schema, `SubModule.cs`, player UI, Bridge/Relay repositories, or `main`.
**MUST FIX in this stage:** create automated, cheap baseline regression evidence for read-only eligibility, original player Crown filing, NPC treason authorization, Crown priority, expulsion deduplication, vote scheduling, save identity, existing integration snapshots.
**MUST NOT CHANGE:** gameplay, native player authority, Bellum automatic court selection, politics toggle, influence accounting, or game save schema.

### Regression contract
- Positive for baseline: Bellum 1.4.5 Crown decree > Royal Peace > council vacancy > normal selector; filed/unopened cannot be displaced; direct player Crown still files; native expulsion queue duplicate guard; source-backed `readOnly=true` does not clear rejection locks; completed court outcomes are exactly-once.
- Neighbor: existing `Tests/CourtExecutiveScheduler.Tests.ps1` must pass.
- Negative for future implementation (specified, **not yet executable**): submitting NPC authority from non-ruler / player or invalid realm rejected; no duplicate intent on reload; no overwrites of existing Crown docket; priority always preserved; original automatic-treason MCM toggle respected; Court snapshots have stable IDs through save/load; changes in rulers/targets close pending intent; successful admission is never reported as completed expulsion.
- Scope: static source-contract tests. They are not a compiler, runtime simulation, save/load test, or approval for live campaign.

### Follow-on implementation boundary (NOT YET AUTHORIZED FOR THIS TEST STAGE)
After baseline green, design a **Bellum-owned persisted NPC Crown intent queue** and public API in a *separate* reviewed stage; test priority/preflight/identity/saves first. Never change the player-only semantics of `TryNominateTreason`, inject through `_agendas` from Bridge, or shortcut `AdvanceExecutive` or `QueueExpulsionVote`.

### Evidence
CI on this feature branch only; `AI_INFLUENCE_NPC_CROWN_BASELINE ...` lines for scenario checks, plus the existing CourtExecutiveScheduler checks. No source or game log expected. No claim of successful 1.4.5 Bridge migration.
