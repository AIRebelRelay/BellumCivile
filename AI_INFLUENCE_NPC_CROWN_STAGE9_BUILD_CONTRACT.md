# Stage 9 — real Bannerlord 1.4.8 Bellum build gate (contract before script)

Date: 2026-10-21 | Baseline feature HEAD `0227a97f75b57985e8a1b1a2d31405f85cdcbe8c` | Bellum upstream 1.4.5 `b1d9a4e8fb74d4f9dd045793c156abeac6f9f4eb`.

## ROOT CAUSE / evidence
Stage 5–8 CI exercises static/source regression and compiled test doubles, but **never compiles the actual shipping `BellumCivile.dll` against Bannerlord 1.4.8 game references**. The existing `BellumCivile.csproj` lists 25+ `GameFolder` DLL references (TaleWorlds, Harmony, UIExtenderEx, SandBox, etc.) and `Bannerlord.MCM` NuGet. Hosted GitHub runners have no licensed game install. A green stub or MSBuild item-list test does not establish compatibility with the real game.

## CHANGE BOUNDARY
**TOUCH:** new read-only Windows build script `scripts/Verify-Bellum148Build.ps1`, new negative regression tests `Tests/AiInfluenceNpcCrownStage9.BuildGate.Tests.ps1`, existing feature-only CI workflow for the new negative test, this permanent contract and later outcome audit.

**DO NOT TOUCH:** Bellum production `*.cs`, `BellumCivile.csproj`, `Directory.Build.props`, save data, player actions, Court Agenda, political defaults, the upstream Bellum repo, Bellum `main`, Bellum Bridge, Relay Bridge or Relay.

**MUST FIX:** identify exact unresolved build prerequisites; fail-closed for missing path, missing dependency DLLs, wrong/unverifiable game version, no SDK, restore/build errors or absent output DLL; run native `dotnet restore` plus `dotnet build -c Release --no-restore` with an explicit `-p:GameFolder` only on Windows with validated Bannerlord 1.4.8 references; report actual output path and SHA-256 after success. Never claim full compile when only prerequisites or synthetic CI are satisfied.

**MUST NOT CHANGE:** compilation options, MCM version, disabled Steam validation, optional Naval DLC behavior, any existing build output, package contents, game DLL licensing, or shipping mod manifests. Script must not fetch or redistribute proprietary game/dependency assemblies and must not copy the build into a player's game modules.

## Regression contract BEFORE implementation
- Missing `GameFolder` -> distinct `BLOCKED_MISSING_GAME_FOLDER`, exit code 20, no restore/build attempted.
- Existing directory but absent required native references -> `BLOCKED_MISSING_REFERENCES` with missing paths, exit 21, no restore/build attempted.
- Synthetic directory with stub-named files, no authentic game version metadata -> `BLOCKED_UNVERIFIED_GAME_VERSION`, exit 22; never green by file names alone.
- Installed but wrong major/minor/patch game version -> `BLOCKED_WRONG_GAME_VERSION`, exit 22.
- On non-Windows, preflight is possible but real native net472 build is blocked; no fake success or publishing.
- Positive future run: all actual Bannerlord 1.4.8 references present, version is verifiable, SDK usable, restore succeeds, Release net472 compile succeeds, built DLL exists and is non-empty, SHA-256 output logged. The positive case **cannot run in hosted CI without private game assemblies**; proof remains open, not skipped as a pass.
- No accidental compile of `Tests/AiInfluenceNpcCrownStage6.Stubs.cs` or Stage7 stubs (already guarded by existing MSBuild item tests).
- Existing Stage5–8 test suite, compile-item audit, CourtExecutiveScheduler continue to pass.
- Separate real game/save/reload tests required even after the build succeeds.

## Expected log states
`BELLUM148_BUILD blocked reason=...` on failure; `BELLUM148_BUILD success ... sha256=...` ONLY after actual successful net472 production build; `STAGE9_BUILD_GATE_NEGATIVE_PASS` from CI synthetic negative tests. Never treat the last as production compilation.
