# Deferred parley OFF tick — independent surgical candidate

Base: AIRebelRelay/BellumCivile audit/bellum-cr2812-coverage-2026-11-16,
389fb3f74c84c62d65678295e064d9cf6afbf213. Base/main rechecked before editing.

ROOT CAUSE: reconciliation d7c0891 dropped the previously implemented edcd4e9
early OFF fence in ForeignTreatyBehavior.OnTick. A pending deferred player parley
then scans proposal/war collections on every OFF tick. Cancelled/missing state can
also clear deferred IDs while OFF; the lower TryOpenPlayerParley fence runs too late.
This is not evidence that an OFF treaty was applied: that callee's guard remains.

Call chain: RegisterEvents -> CampaignEvents.TickEvent -> private OnTick ->
EnsureCollectionsInitialized -> proposal/war lookup -> TryOpenPlayerParley.
Deferred ID writers are existing player-parley handoff/inquiry paths. The sole
OnTick registration is unchanged. Historical implementation was read at edcd4e9.

TOUCH: only the initial OnTick condition, plus Tests/DeferredParleyTickGate.Tests.ps1.
DO NOT TOUCH: the five public OFF fences, sign/reject/vote/edit/open paths, treaty
ratification, committed deliveries, daily/hourly callbacks, persistence, war score,
UI hooks, Bridge/Relay/CR, restoration membership and the pending drift candidate.
MUST FIX: OFF does not scan or clear deferred IDs; OFF->ON can resume the same queue.
MUST NOT CHANGE: ON valid opening, retries, invalid-state cleanup, empty ID and UI fences.

## Regression evidence

The new test compiles the exact current production OnTick body with instrumented
boundary doubles (not a rewritten tick). The callee double also rejects OFF, matching
the real callee; no claim of actual OFF UI opening is manufactured.

14 named scenarios. Before: five OFF scenarios FAIL. In particular 200 OFF ticks
produce 200 proposal/war scans, and cancelled/missing-war cases clear deferred IDs.
After: all 14 scenarios PASS: valid/cancelled/missing-war/repeated OFF, OFF->ON,
empty ID, inquiry, visible UI, valid/missing/cancelled proposal, missing/inactive war,
and failed-open retry. These are named scenarios, not a Monte Carlo assertion count.
Existing Stage32H2Q source contract now passes all six checks without modification.

Full production diff audit: one Boolean operand restored; entire file is otherwise
byte-equivalent to the base. Complete tick body compiles in the isolated test.
No changed shared helper, field, saved ID, defaults or new native diagnostic logs.
Windows net472 build, native harness, gameplay/save and real UI/FPS are NOT RUN.
Current restoration/drift native gates remain pending. No merge/release.

In-game acceptance: OFF with a queued parley preserves the deferred request and
shows no new parley; after ON, valid queue resumes once, invalid queue cleans up,
transient UI refusal retries. Existing success line is 'Player parley opened after
deferred inquiry handoff; ...'. Log silence alone is not proof of no scanning.
