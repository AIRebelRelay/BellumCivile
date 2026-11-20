# S25A — executable full-cycle opportunity budget; candidate1.4.12.6

Base: cumulative S24/S23C candidate1.4.12.5 (local stage26 tree, archived Library
version3). Remote base AIRebelRelay/BellumCivile,
feature/cr-realm-preparation-receipts-2026-11-18,
903f6772a8bebab68b1296121d770b741ae1a232 / Draft PR54 rechecked unchanged.
All prior runtime functionality is preserved. No remote branch/CI/merge/release.

## Implemented boundary

One additive production source: ForeignCrisisBudgetEstimator.cs. Internal immutable
profile, planned-call and result values; stateless arithmetic/validation only.
There are ZERO production callers. No game/monotonic/UTC clock, deadline, campaign
save record, provider call, route setting, calibration collection, MCM switch,
Native operation, forced peace or receipt has been added or modified.

Existing-file changes: module/file/informational version1.4.12.6; build command
example folder name only; fixture runner includes the new budget suite. Core+Naval
builder behavior and logger/package test stay byte-identical. AssemblyVersion stays
1.0.0.0. No prior production method or save registration/field changes.

## Budget semantics

The adapter must supply the COMPLETE serial call plan (both rulers, every allowed
round), bounded attempts per call, Relay queue allowance, retry backoff, a matched
profile and explicit safety/floor/cap settings. Repeated plan entries are intentionally
counted, not deduplicated by route. Calculation does not reset clocks on retries.

For call i:
  call_seconds = attempts_i * (relay_queue_i + provider_seconds_i)
                 + (attempts_i - 1) * retry_backoff_i
  required_seconds = max(configured_floor, safety_factor * SUM(call_seconds))

An explicit mode selects provider_seconds:
- MeasuredEndToEnd: matched, conservatively observed full provider request latency,
  including provider queue, prefill/TTFT, output and configured reasoning.
- TokenEstimate: calibrated TTFT + full planned output tokens / conservative sustained
  TPS + explicit additional reasoning allowance if reasoning is enabled.
- ExplicitAllowance: an explicitly configured conservative full-provider duration.

Relay queue is separate from provider E2E duration to avoid counting one queue twice.
No E2E+token/reasoning sum: E2E duration already covers the configured provider work.
If reasoning tokens are hidden, use E2E evidence or an explicit conservative allowance;
visible output TPS alone is not automatically the whole thinking request budget.

A profile must exactly match the caller's route key and reasoning mode, and cover
its planned input/output token limits. The FUTURE trusted adapter must construct the
key from actual route/provider/model/reasoning configuration and verify calibration
quality, comparability and freshness. This estimator validates supplied metadata,
not statistical credibility or the identity of a live outbound request. No real
NanoGPT profile or fabricated TPS measurement is included in this package.

Unknown/missing/undersized profiles, invalid durations, nonpositive TPS, nonfinite
values, invalid settings and overflow are explicit failures. There is no silent
estimation-mode fallback. A cycle over the hard cap returns DoesNotFit with ZERO
usable BudgetSeconds, not a shortened budget. Caller must inspect Status==Ready.
The RequiredSeconds diagnostic explains an infeasible cap; it is not execution permission.

Resource guardrails: max64 serial plan entries and max8 attempts PER entry; excess
is rejected, never truncated. These are estimator input bounds, not an implemented
negotiation policy or added automatic retries. Margin/floor/cap/profile data must be
supplied explicitly. No default throughput or new crisis timer setting is inferred.

## Validation and exact limits

Contract/tests prepared before production edits. Initial RED: missing new estimator
source, not a claimed live-game bug. Actual standalone C# source compiles through
PowerShell Add-Type /langversion:7.3. All64 behavioral assertions PASS with SYNTHETIC
profiles. Tests cover distinct rulers/routes, six serial calls, attempts/queue/backoff,
slower TPS, longer outputs, thinking coverage, mode separation, calibrated bounds,
minimum/safety, exact vs over cap, invalid/nonfinite/overflow and oversized plans.

Five deliberate source mutations are rejected by assertions: replace serial sum,
ignore attempt multiplication, wrong TPS arithmetic, clamp-to-cap success, drop
calibration-bound check. Mutation runner is optional additional test-sensitivity
validation; the shared checkpoint includes the64 positive/negative budget assertions.

Cumulative checkpoint: all14 suites PASS, including prior journal/policy, neighboring
state/receipt tests, actual logger/two-DLL packaging fixture24 and Naval source checks.
All engine-bound fixture limitations from previous stages still apply. Fixture DLLs
are not the actual Naval/core game projects. Actual shipping Windows/net472 build,
provider benchmarking, native serialization/game save-load remain NOT_RUN.

S24's38 complete crisis behavior scenarios remain PLANNED / NOT_RUN. Passing this
budget unit suite does not implement or prove any dual-clock lifecycle, campaign
pause handling, persistence, crisis epoch, world revalidation or enforced execution.

## Replacement / next acceptance evidence

In-game replacements now: NONE. No new gameplay log lines. Expected test output:
CRISIS BUDGET PASS64; BUDGET MUTATIONS REJECTED5; CHECKPOINT_FIXTURES_PASS.
No commands are required from the user while travelling.

Future adapter/timer work must consume a complete real plan and calibrated profile,
persist its selected budget, preserve remaining opportunity across save/load,
combine it with the campaign floor, and require current Native legality/receipt.
These remain separate bounded implementation and game-validation gates. This source
candidate does not silently activate them or update Relay settings.
