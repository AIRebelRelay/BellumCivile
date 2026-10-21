# Stage 9 — native Bannerlord 1.4.8 build gate: evidence and remaining blocker

Date: **2026-10-21**. **Result: FAIL-CLOSED READINESS VERIFIED; ACTUAL GAME ASSEMBLY BUILD NOT PERFORMED.** Do not ship or merge.

## Pinned sources and branch
- Bellum 1.4.5 stable upstream: `b1d9a4e8fb74d4f9dd045793c156abeac6f9f4eb`, intended for Bannerlord 1.4.8.
- Bellum feature branch baseline after Stage 8: `0227a97f75b57985e8a1b1a2d31405f85cdcbe8c`.
- Stage 9 gate script commit: `a041ef351d251ccaa28f4eec92c5f73b0e80c7d5`.
- Final passing tested commit: `4bc3ab83f9cbf4e4f30ff8868843124c60a1a100`.
- Existing Bellum `main`: `b1d9a4e8fb74d4f9dd045793c156abeac6f9f4eb` **unchanged**.
- [Stage 9 pre-code regression contract](./AI_INFLUENCE_NPC_CROWN_STAGE9_BUILD_CONTRACT.md).
- [Final CI run 39579683194](https://github.com/AIRebelRelay/BellumCivile/actions/runs/39579683194): **success**, exercising all Stage 5–8 tests and Stage 9 negative checks.

## ROOT CAUSE
Past CI compiled integration helpers against *synthetic fake TaleWorlds classes* and checked MSBuild compile item inclusion, but did not build Bellum's actual `net472` game-facing `BellumCivile.dll`. `BellumCivile.csproj` references Bannerlord game assemblies and installed Harmony/UIExtenderEx modules via `$(GameFolder)`. GitHub's public runner has **no real Bannerlord 1.4.8 installation**; fake success would be dangerous for fragile saves.

## TOUCH
Only **four files changed** versus Stage 8:
1. `scripts/Verify-Bellum148Build.ps1` (NEW): verify explicit installed `GameFolder`, exact shipping `csproj` reference paths, Windows installed game version metadata equal to 1.4.8, platform/SDK, optional tracked-tree cleanliness, run `dotnet restore` and actual `dotnet build -c Release --no-restore`, verify real nonempty output and print SHA-256.
2. `Tests/AiInfluenceNpcCrownStage9.BuildGate.Tests.ps1` (NEW): subprocess negative fixture cases.
3. `.github/workflows/ai-influence-npc-crown-baseline.yml` (five scoped lines): trigger and run the new negative test on feature branch.
4. `AI_INFLUENCE_NPC_CROWN_STAGE9_BUILD_CONTRACT.md` (NEW), plus this audit.
No changes to Bellum production C#, `BellumCivile.csproj`, MCM defaults, SaveDefiner, event routing, Court Agenda, Bridge, Relay or either main branch. Script never downloads game dependencies or deploys its output into a user's game.

## Evidence — observed, not inferred
CI validated:
- `PASS STAGE9_BUILD_GATE missing_game_directory_never_builds`: blocked with exit **20**.
- `PASS STAGE9_BUILD_GATE incomplete_mod_stack_never_builds`: blocked with exit **21**, missing reference paths listed.
- `PASS STAGE9_BUILD_GATE fake_dll_names_cannot_pass_native_version_gate`: all dependency filenames exist but contain deliberately fake text, blocked with exit **22**.
- `STAGE9_BUILD_GATE_NEGATIVE_PASS`: only confirms **negative gate semantics**. It is **not** positive compile evidence.
- All existing Stage 5–8 regression and compilation-item checks green in the same final run.
- First Stage 9 CI `39579567259` was red only because an expected negative subprocess exit code `22` leaked through PowerShell into the job result; corrected with explicit `exit 0` at the end of the **test script only**. New gate semantics were unchanged; no unrelated production fix.
- Full diff after corrective test commit: exactly three new scoped files + narrow workflow edit; no introduced fallback/default change.

## How to obtain the one missing positive result (Windows, with Bannerlord 1.4.8 installed)
On a Windows checkout of THIS feature branch, with .NET SDK and net472 reference assemblies installed, run in repo root:
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\Verify-Bellum148Build.ps1 -GameFolder "D:\SteamLibrary\steamapps\common\Mount & Blade II Bannerlord"
```
**Replace the sample folder with the actual installed game location.** The command does not install or copy files into Bannerlord. Success requires the complete dependency stack, authentic-enough version metadata for installed 1.4.8 files, restore, full Release build, and a produced `bin/Release/net472/BellumCivile.dll`; it prints `BELLUM148_BUILD success head=... sha256=... output=...`. Copy back only the build **log**, commit SHA, and output hash first. Do NOT replace the installed Bellum DLL or test the actual saved campaign yet.

Failure is intentionally explicit, including `missing_game_folder`, `missing_references`, `unverified_game_version`, `wrong_game_version`, `restore_failed`, and `compile_failed`. Version gate uses file metadata, not a cryptographic game-binary provenance guarantee; real installed game files are still a prerequisite.

## STILL BLOCKED
- No Windows system with real installed Bannerlord 1.4.8 game assemblies was connected to the CI; **full production DLL compile remains unverified**.
- No native save/load, game tick, player or NPC court agenda gameplay proof.
- Bellum 1.4.5 migration also blocked separately by Royal Peace/Claim Feud semantic P0, Bellum Bridge 4-to-5 argument gate ABI, and other political/event routes.
- This step is **build verification tooling only**, not resolution of those incompatibilities. No merges, releases, or installation instructions were issued.
