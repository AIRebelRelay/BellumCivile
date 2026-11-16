# Bellum 1.4.12b — drift harness isolation candidate

Date: 2026-11-16. Repository: AIRebelRelay/BellumCivile.
Base branch: port/bellum-1412b-upstream-sync-foundation-2026-11-15.
Verified base HEAD: bf1e019111674fba8f31e2315d38ab5d3b954985.
Main remains 59b2aee8268cf1633e052e6b44e1cdba0e3c15fb.

## ROOT CAUSE / evidence boundary

User's Windows run: build PASS; full harness FAIL in DeJureDriftConflictTests.
Call chain: Run -> reflection EvaluateAndMaintainRecord -> CalculateProgressDelta
-> CalculateSpeedMultiplier -> GetSkillValue(DefaultSkills.Steward/Roguery).
The test's Hero is deliberately uninitialized and must never reach native skill reads.
Its Delta prefix should supply .01 instead. Earlier pause evaluations execute the caller
BEFORE that prefix is installed. The stack demonstrates that this isolation failed.

JIT-inlining of the original short delta into an already compiled caller is the leading
mechanism, not a reproduced Windows diagnosis. The same suite already re-emits callers
after late mocks in CouncilCompetencePresentationTests. This patch applies that existing
test-only technique. Windows execution must confirm the proposed repair; no production
bug or final fix is claimed.

## TOUCH

- Tests/SuccessionEngineHarness/DeJureDriftConflictTests.cs: Delta call/elapsed counters,
  reset fixture state, re-emit EvaluateAndMaintainRecord after installing Delta.
- Tests/SuccessionEngineHarness/IndependentDriftTests.cs: equivalent caller re-emission
  and assertion that this fixture's Delta is called, including after another fixture.
- Tests/SuccessionEngineHarness/Program.cs: additive --de-jure-drift route, running
  conflict/independent/independent/conflict in one process. Default Run is unchanged.
- scripts/Verify-Bellum1412Regression.ps1: support runner, separate processes/logs,
  explicit Workshop references, failure/timeout collection, always run full harness.
- This documentation directory: read-only audit and verification evidence.

## DO NOT TOUCH / MUST NOT CHANGE

No shipping C#, formula, skill balance, title legality, temporary-realm handling,
save schema, Bridge, Relay, CR, project references, dependencies, UI or defaults change.
Harmony postfixes are owned by each fixture and removed by its existing finally.
No shared helper or global no-optimization setting is introduced.

## MUST FIX / regression contract

- Resumption reaches Delta exactly once with 7 elapsed days; progress .45 -> .46.
- Forty paused evaluations preserve record, legal destination and .45 progress.
- Civil-war/private-feud shells pause; genuine foreign/independent control reverses.
- Independent parent/child clocks, in-realm retargeting, completion isolation and
  one-time legacy migration keep all original assertions and numeric expectations.
- Repeat fixtures in both transition directions, and then run default full harness
  separately to check compatibility with its original order.
- Existing eight targeted Windows routes must pass on the candidate too.

## Verification actually performed here

- Roslyn syntax parse: all three modified C# files PASS. This is NOT compilation.
- PowerShell parser: runner PASS.
- Runner simulation: fake executable in a path with spaces; FAIL exit 7, PASS,
  TIMEOUT and subsequent full PASS collected; overall script correctly fails.
  This validates runner control flow ONLY, not Bannerlord or Harmony behavior.
- Seven existing PowerShell source suites PASS, 179 checks. See source-results.json.
- Full byte comparison to base ZIP: no shipping files changed.

Not performed: net472 compilation, native Harmony runtime tests, full harness, game,
save/load. This environment has no dotnet SDK and no complete matching game DLL set.
The inspected Drive DLL folder has CampaignSystem plus Naval assemblies, not the
complete references needed by the project. PowerShell was provisioned locally to
execute the source checks; it does not supply a dotnet SDK or Bannerlord.

## Windows validation — one command from extracted source root

```powershell
.\scripts\Verify-Bellum1412Regression.ps1 -AllRoutes
```

Build once, all 112 explicit routes in fresh processes, then unchanged full default.
Without -AllRoutes: new drift route + previous eight gates + default full.
No game DLLs are installed by this script. Default timeout is 600 seconds per process;
TIMEOUT is a failure, not a gameplay diagnosis. Increase -TimeoutSeconds if needed.
Return summary.csv and the failed route's .log and .stderr.log.

Expected: new seven-day Delta assertion, resumed .46 progress, independent Delta
assertion and final `de jure drift isolation and ordering checks passed.`
Unexpected: NRE at CalculateSpeedMultiplier, a wrong Delta count, changed progress,
or any previous gate failure. Do not add production null guards to hide a fixture failure.

Do not merge or release. After runtime confirmation, continue the next demonstrated
blocker in a separate stage. API work below remains read-only inventory meanwhile.

## Systematic inventory

harness-routes.csv: 112 explicit routes + full default, all runtime PENDING_WINDOWS.
fixture-risk-inventory.csv: 266 C# test files; 198 use uninitialized objects and 183
contain Harmony Patch calls. These are review indicators, NOT 198/183 confirmed bugs.
No other fixtures were changed speculatively. Separate CourtRedesign projects and
source scripts remain additional inventory; route discovery is not proof of coverage.

## Source freshness / ownership

The attached historical Bellum updating rules retain an older AI Influence diplomacy
ownership model. Current user instructions supersede it: CR is the integration target;
AI Influence code is not a development source. No such code was read or copied here.
The only existing CI workflow is limited to a different feature branch; no Actions
were manually triggered for this candidate.
