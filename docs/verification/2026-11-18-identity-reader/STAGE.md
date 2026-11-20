# S26B stage evidence

Repository: AIRebelRelay/BellumCivile. Checked remote draft PR54 branch
feature/cr-realm-preparation-receipts-2026-11-18 at
903f6772a8bebab68b1296121d770b741ae1a232; unchanged remote baseline.
Local cumulative base: 1.4.12.8 S26A source ZIP; candidate 1.4.12.9 S26B.
No remote writes, release, merge or CI trigger.

Call chain: new BellumIntegration facade -> unchanged RequireCampaignThread ->
current WarScoreBehavior -> new passive reader -> detached immutable projection.
New reader has one production caller, the new facade. Existing APIs/callers unchanged.
GUID identifies record lifetime, not guaranteed engine war incarnation.

Full diff audited: three new production C# files; four existing files changed only
for version/example/test runner. No save schema, old guard or gameplay edits.
49 actual-reader/actual-facade/actual-guard fixture assertions PASS.
17 checkpoint suites exit 0. Five mutation probes rejected by assertions.
Logs: CHECKPOINT.log and MUTATIONS.log. Diff: FULL_CODE_DIFF.patch.
Compiler evidence covers isolated C#7.3 slices with Native world doubles.
Full Windows/net472 build, actual engine ABI, save-load and live game NOT_RUN.
No new logging or gameplay execution connected. Expected live API statuses and
PowerShell force-launch/build instructions are in README_S26B_UK.md.
