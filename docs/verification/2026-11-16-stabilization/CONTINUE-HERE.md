# Bellum 1.4.12b candidate — stabilization checkpoint

This candidate is NOT a finished release. Native Windows/game gates remain open.
Source baseline: 389fb3f74c84c62d65678295e064d9cf6afbf213.
Tested source head before this evidence-only commit: 2575ac1445f11f3539594de7a826e072e3c0591c.
Main and integration branches were not merged or released.

## What changed

Production stage: ForeignTreatyBehavior.OnTick restores one early Revamp-OFF operand. While OFF, pending deferred player-parley IDs stay unchanged, including cancelled/missing-war entries, so the existing ON path can process them after resumption. The old downstream OFF UI guard remains. This does not demonstrate that the unpatched code executed treaties while OFF.
Draft PR #46: https://github.com/AIRebelRelay/BellumCivile/pull/46

Test-only stages: update 26 existing source-observer files to follow current ported helpers/routes; add actual family XML composition and eight named nonlinear rally math scenarios. These are not 26 gameplay bug fixes. Each stage has a separate evidence note/commit. No production changes relative to the deferred-parley base.
Draft PR #47: https://github.com/AIRebelRelay/BellumCivile/pull/47

The inherited baseline also contains the previous two-line restoration membership correction and native drift-harness candidate (PRs #43–45); native validation of those candidates is still pending.

## Verified here

- Original read-only source manifest: 156/158 suites PASS, 2 FAIL. The same frozen set was rerun in separate processes; no failing test removed or skipped.
- 229 PowerShell test scripts parse with 0 errors.
- Exact OnTick fixture: 14 named cases; before 5 fail, after 14 pass. Boundary doubles do not exercise actual Bannerlord UI.
- Exact rally/PeaceReadiness math: 8 named scenarios PASS.
- Current CourtRedesignHarness sources compiled using PowerShell 7.5.4 Roslyn with the csproj compile list and embedded policy resource; actual Main invoked. 200486 assertion invocations PASS, including loops. Not 200486 independent scenarios; not native/game proof.
- Full modified-file diff audited against frozen baseline. Only changed pre-existing production file is ForeignTreatyBehavior.cs, one additional guard operand. All other existing changes are test observers; new files are tests/evidence. No production defaults, persistence, authority, Bridge/Relay or unrelated helpers changed in this round.

See RESULTS.json and individual logs. No external LLM calls or Actions reruns were triggered.

## Two visible source failures

1. EncyclopediaConcepts requires docs/encyclopedia-articles-draft.md, absent from tracked baseline and available sources. Do not reverse-generate an expected manuscript from the shipped XML and claim independent content validation. The original test remains unchanged/failing.
2. Stage32H2TMod145ReleaseMetadata pins the historical Bellum 1.4.6 / Bannerlord 1.4.8 release and separate Naval version. Preserve it as historical evidence; do not change expected versions merely to turn it green. Current release version remains a native/release-stage decision.

## Required next stage: real Windows build and native regression

Use the ZIP source root. The existing script explicitly resolves Harmony/UIExtenderEx/MCM from the user's Workshop IDs and forwards their paths to the native build. It writes logs outside the game and does not install a DLL:

~~~powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\Verify-Bellum1412Regression.ps1 -AllRoutes
~~~

Defaults: game F:\Steam\steamapps\common\Mount & Blade II Bannerlord; Workshop F:\Steam\steamapps\workshop\content\261550. Requires .NET SDK, .NET Framework runtime, complete matching real game references and Harmony's Mono.Cecil.dll. This script has NOT been executed on the user's PC. Current environment preflight explicitly blocks at missing_game_folder; the Drive reference folder has CampaignSystem plus Naval DLLs only and cannot substitute for a complete native reference set.

If native regression fails, fix its demonstrated root cause in a new bounded stage. Do not merge/release on source/math results alone. Once native gates pass, game evidence must include: OFF pending parley remains frozen; re-enabling resumes once without duplicate dialog/payment; ordinary ON parley/rejection unchanged; saved restoration retries preserve ownership and membership; save/reload retains valid receipts; no new relevant exception/duplicate UI. Runtime guard is intentionally silent, so unchanged queue/state and later single resumption are the expected evidence, not an invented log line.

## Remaining project work

The Bellum-to-Calradia Remembers integration/API coverage work is not completed by this stabilization checkpoint. Prior source inventory and verified CR 2.8.12 API limits live under ../2026-11-16-drift. Maintain authority and private-audience boundaries, event delivery receipts, Feed quota and separate NanoGPT/Relay routes. Do not start new overlapping production stages before native validation of the current candidates. Bellum Bridge and Relay Bridge remain distinct; no AI Influence code reuse.

