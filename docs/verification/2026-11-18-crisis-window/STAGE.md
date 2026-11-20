# S25B — pure dual-clock observation policy; candidate1.4.12.7

Base: cumulative local S25A1.4.12.6. Remote base rechecked:
AIRebelRelay/BellumCivile feature/cr-realm-preparation-receipts-2026-11-18,
903f6772a8bebab68b1296121d770b741ae1a232 (Draft PR54 unchanged).
No remote write, CI run, merge, release or deployment.

## Exact change boundary

New ForeignCrisisWindowPolicy.cs only: immutable in-memory state/decision values and
pure TryOpen/Observe functions. No producer, game event, Stopwatch/UTC API, provider,
serializer, Native execution or MCM setting. It reads existing S25A budget results;
the estimator's code/semantics remain byte-identical. Previous journal/admission,
WarScore/councils/terms, all save definitions/fields and logger/package test unchanged.
Existing changes are candidate module/file/informational version1.4.12.7, build
example identity only and one new suite entry in the fixture checkpoint. Existing
AssemblyVersion1.0.0.0 and both-DLL builder behavior remain unchanged.

## Rule implemented

TryOpen requires a Ready, positive finite opportunity budget and a valid supplied
opening game day/minimum grace. It freezes opening, grace/floor and budget; counters
start at zero/that opening day. Positive grace must produce a representable later
floor; overflow or floating-point precision collapse is refused.

Observe consumes the CURRENT campaign day and ABSOLUTE cumulative active-opportunity
seconds for the same window, not a delta. They must be finite/nonnegative and must
not decrease against the previous immutable observation. Repeated identical input
therefore does not double-count or restart the budget. Invalid input/state/status
returns Invalid with NO next state. Valid input returns a detached new immutable
observation retaining the original opening, grace and budget.

Precedence after input validation:
1. Paused -> Paused, never Ready; supplied in-flight provider time may still accrue.
2. Before campaign floor -> WaitCampaignFloor, even if provider budget elapsed or a
   valid final ruler response arrived early.
3. After floor, with no CURRENT valid terminal response and unspent opportunity ->
   WaitOpportunity. TechnicalFailure/StaleOrInvalidResponse are not final answers.
4. Otherwise -> ReadyForNativeAssessment ONLY.

ValidTerminalResponse may conclude opportunity early because the planned LLM work
has validly ended, but never shortens the campaign floor for automatic defeat
assessment. A previous valid response is deliberately NOT latched in state: after
ruler/draft/epoch invalidation, the adapter must supply stale/pending status again.
An expired opportunity after the game floor permits assessment even if the provider
failed, preventing unbounded technical retries. It still does not grant execution.

This is a timing predicate, not a once-only state transition. Repeated Ready outputs
must be bound to one operation by the future durable crisis/gateway owners. Native
world/legal/draft/player checks and receipt reconciliation are still required.

## Trust and persistence limits

Reply state comes from a future trusted validator, not LLM JSON. The policy cannot
itself verify who replied, current rulers, war epoch, consent or legality. The adapter
must supply a complete calibrated S25A budget and coherent active time; there is no
invented live TPS or selected provider profile here.

The policy does NOT collect elapsed time, detect offline UTC gaps, attach/recover
requests or register save data. Immutable state is NOT an engine save record. The
future clock/persistence adapter must retain opening/floor/budget/progress across
load, exclude offline time, reconcile unknown interrupted work and revalidate identity.
Tests here do not prove any of those engine lifecycle requirements.

Minimum game days are an explicit caller input; no global3-day setting or active
campaign timer is introduced. S24's3-day floor remains a proposed configuration.
No game-facing caller uses this new policy in this candidate.

## Regression evidence

Contract/tests existed before production edits. Initial RED was missing new source,
not a reproduced live-game symptom. Actual budget estimator + actual new policy
compile and run via PowerShell Add-Type /langversion:7.3:59 assertions PASS. Synthetic
budget inputs, deterministic supplied clocks, no actual sleeping/provider calls.
Coverage includes both exact thresholds, fast game/slow generation, pause with
in-flight work, valid vs technical/stale replies, immutable/idempotent updates,
clock rollback/reset, bad budget/status/state, overflow/precision collapse.

Five intentional mutations rejected by assertions: ignore game floor, ignore
opportunity budget, technical failure as final response, ignore pause, double-count
absolute cumulative seconds. Optional mutation runner is test-sensitivity evidence;
main checkpoint includes the59 policy assertions.

All15 cumulative fixture suites PASS, including prior budget64, journal/policy/state
and receipt fixtures and logger+two-DLL package24. Fixture managed DLLs and engine
doubles are not an actual core/Naval Windows build or TaleWorlds serializer.
Windows shipping build, live clocks/pause, real provider TPS, game/save-load and
Native diplomacy remain NOT_RUN. S24's full crisis scenarios remain open; isolated
policy assertions are not relabelled as complete end-to-end crisis passes.

## Replacement and expected evidence

In-game files to replace NOW: NONE. No new gameplay logs are emitted.
Fixture output: CRISIS WINDOW PASS59; WINDOW MUTATIONS REJECTED5;
CHECKPOINT_FIXTURES_PASS. Logs and exact diff/hash audit are adjacent.

Before runtime activation: actual clock capture + durable crisis identity/state,
unknown-request reconciliation, current-world validation and exactly-once Native
submission/receipt; accumulated real Windows/native save/game checks. NativePending,
partial treaty effects and player transitions must never be settled by this timing
predicate alone. No next gameplay stage is silently enabled by unit test success.
