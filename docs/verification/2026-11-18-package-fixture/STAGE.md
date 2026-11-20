# S23C — test fixture follows existing core + Naval packager

Base: cumulative local S23B candidate1.4.12.5, originally based on custom Bellum
AIRebelRelay/BellumCivile feature/cr-realm-preparation-receipts-2026-11-18,
903f6772a8bebab68b1296121d770b741ae1a232, Draft PR54 rechecked unchanged.

ROOT CAUSE: the test dot-sources the actual production packaging tail, skipping
build/preflight where $navalDll and $expectedVersion are established. The old test
provided only its core DLL, output/source path and fake file-version object.
The existing production Naval compilation and packaging fix was not lost.

Change: compile an independent managed Naval fixture with a separate identity and
bytes; read expected module version from the source manifest; provide dependencies
to the unchanged actual packaging tail. Check both output DLLs, hashes, unique ZIP
entries and ZIP stream hashes, versioned ZIP name, report identity/paths/hashes,
NOT_RUN/no-deployment report semantics, original asset/manifest/logger behavior.
The dynamic expected version removes the need to update literals on each candidate.

Only Tests/ModuleLocalLogs.Tests.ps1 has test behavior changes. Cumulative runner
changes are stale failure text/comments only; README status is refreshed.
Production builder/logger/mod/Naval/save/diplomacy source and module/assembly version
are byte-identical to S23B. Version remains1.4.12.5: this is a tests-only correction
inside the same candidate batch, not a new runtime feature or game release.
No remote repository mutation, CI, merge, release or deployment.

Evidence:
- RED: original test reproduces null $navalDll after 10 logger checks.
- GREEN: actual unchanged package tail succeeds; all 24 named checks pass.
- CHECKPOINT: all13 suites run in fresh PowerShell processes and return0. Includes
  journal104, schema8, journal mutations5, policy65, policy mutations5, previous
  neighboring state/receipt suites, Naval source-contract and corrected logger/package.
- Negative package cases in TEMPORARY COPIES of the builder only: omit Naval copy
  while bypassing its immediate hash fence -> existing ZIP completeness guard fails;
  substitute core bytes for Naval while bypassing that hash fence -> new test hash
  assertion fails. Original builder bytes remain unchanged.

Fixture managed DLLs are compiled with Roslyn, not from the actual core/Naval projects.
This tests logger and file/ZIP packaging and does NOT prove shipping net472 ABI,
Workshop dependency resolution or actual Windows compilation. Those and Native
game/save-load remain NOT_RUN. No new game logging or installation is required.
Historical S23A/S23B failure notes remain as historical evidence; the fixture failure
is now closed. See RED.log, GREEN.log, CHECKPOINT.log and NEGATIVE_CASES.json.
