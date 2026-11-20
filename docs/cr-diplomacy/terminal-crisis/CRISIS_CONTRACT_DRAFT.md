# Proposed foreign-war crisis contract v1 — NOT IMPLEMENTED

## Authority and scope

An ordinary negotiated treaty requires the current parties' exact-draft decisions
and Native ratification. An enforced defeat is a separate authority with explicit
reason `terminal_defeat`, not fabricated LLM consent or an ordinary paid ruler override.
A model can bargain over lawful options; it cannot cancel a still-valid physical
defeat by declining, inventing a victory, or failing to answer.

First proposed scope: opt-in owner, Revamp ON, ordinary foreign war, both current
rulers NPC, NO player political participation, no internal conflict, auxiliary client
war, different registered owner, active story/alliance peace restriction or unknown
legal state. Existing out-of-scope domain owners keep their current paths. This is
not a new global gate over player/internal/obligation peace actions.

## Proposed timing — TWO clocks, design defaults only

A fixed campaign-day deadline is insufficient: accelerated game time can outrun
queued/serial LLM calls. Do NOT evaluate defeat just because one game day elapsed.

- Proposed minimum grace:3 CAMPAIGN days, a floor rather than a sole timeout.
- Independently reserve a REAL-TIME opportunity budget for the entire allowed
  negotiation cycle, including both rulers and every serial round, queueing,
  prefill/time-to-first-token, generation, reasoning and bounded retry allowance.
- Assess enforced settlement only when BOTH the campaign floor has elapsed AND
  the negotiation has reached a valid terminal response or its bounded real-time
  opportunity budget has expired. A transport error alone is not a valid final
  ruler response and must not close this window prematurely.
- Completion before the campaign floor does not shorten that floor for automatic
  defeat assessment. A separately lawful voluntary treaty may still complete.

Budget computation is route/provider/model/reasoning-profile specific. Prefer
observed conservative end-to-end request latency (e.g. P95 at comparable context
and output budgets). If estimating from tokens, each serial call needs queue
allowance + conservative TTFT/prefill + full relevant token budget / conservative
sustained TPS + overhead. Account for reasoning latency through measured E2E time
when its token count is unavailable. Sum ALL planned calls, then apply a safety
margin and validated minimum/maximum limits. Do not use peak TPS, one ruler's
response time or a single global model profile for every route.

The hard real-time cap must be compatible with the configured call/round/token
budget. If that whole cycle cannot fit, reduce the planned cycle explicitly or
refuse activation; never silently cut a slow model's reply short to meet an
arbitrary cap. Missing calibration/profile requires an explicit conservative
configured budget or blocked readiness, not an invented fast-model assumption.
No TPS figures or real-time seconds are assigned without actual route evidence.

The opportunity window starts with persisted crisis/outbox publication and includes
queue starvation/provider outage; retries do not reset either clock. Monotonic
elapsed opportunity time is accounted only while this campaign/dispatcher session
is active. A game pause may let in-flight LLM work consume its real-time budget,
but does not advance the campaign floor or permit world execution while paused.
Closing the game is not an automatic expiry: persist consumed/remaining budget,
reconcile the SAME pending provider operation on reload, and do not charge offline
wall-clock time merely by subtracting saved UTC timestamps. Unknown interrupted
operation/timing state goes to reconciliation, not guessed consent or redispatch.

At the dual-clock boundary, Native revalidates CURRENT defeat and lawful terms;
LLM failure does not reset the deadline or grant Native permission to bypass law.
A positive no-effects transient Native refusal may be retried at most once per
campaign day, at most3 attempts, only while the same crisis remains lawful.
Unknown/possibly partial execution never consumes another execute attempt until
Native reconciliation proves the earlier attempt had no effects. Exhausted,
illegal or unknown execution becomes explicit Blocked/ReconciliationRequired;
no bare peace, false Applied or unlimited requeue.

All timing values/formulae here are PROPOSALS, not implemented options. The contract
does NOT promise every war ends in a fixed number of days: no timer substitutes
player authority, bypasses legal blocks or repairs a missing Native gateway.
Save/load preserves opening, both timing budgets, attempts and last attempt day;
royal succession does not restart grace. Inconsistent/rolled-back clock state is
quarantined instead of postponing or advancing execution under guessed time.

In the state/identity rules below, expiry/deadline means the combined two-clock
boundary, not the campaign-day floor by itself.

## States and allowed effects

| State | Meaning / permitted next step |
| --- | --- |
| Observed | Read score/world/legal facts; no claim that a defeat is already irrevocable |
| Negotiating | Persist crisis identity/deadline before dispatch; advisory/ruler responses only |
| SettlementDue | Deadline elapsed; recompute Native lawful forced settlement; no LLM permission needed for existence of defeat |
| NativePending | One bound submission accepted; query/reconcile operation, do not submit again |
| ReconciliationRequired | Possible partial effects, deferred hostage/structural owner or missing receipt; prohibit blind replay |
| Applied | Exact Native receipt AND required postconditions confirm this operation; announce enforced outcome honestly |
| RecoveredBelowThreshold | Fresh reconciled game state no longer supports terminal defeat; close episode without a settlement |
| ReconciledExternal | War ended/realm disappeared through another owner; close bookkeeping, do not attribute a treaty |
| Blocked | Explicit legal/capability/attempt-limit/identity failure; surface diagnostics, no hidden fallback |

All terminal and blocked states retain durable identity/tombstones. A new crisis
EPISODE after genuine recovery requires a new persisted episode number within the
same authoritative war incarnation; it must not reuse prior responses/receipts.
A changing draft/ruler invalidates its old response and any voluntary consent,
without resetting the crisis's original deadline. Before deadline it can be
re-presented if time remains; after deadline Native assesses forced terms anew.

## Required identity and verification

Campaign ID; authoritative Native war-incarnation ID; stable crisis/episode ID;
owner/scope; attacker/defender and score perspective; current ruler IDs; validation
revision; draft ID/revision/canonical fingerprint; opening/deadline and attempt state;
Native operation/receipt identity. The Native war epoch allocator is a prerequisite,
not a value the LLM invents. A bare pair key or StartedDay float is insufficient.

Fresh checks before admission, each accepted response and every irreversible action:
active same incarnation; reconciled current threshold/sign; both current participants;
player participation; story/alliance/client legality; source owner; council budget;
actual deliverability of terms; no existing/unknown in-flight operation. Re-reading
must happen on the campaign thread at a safe scheduler point, not inside unfinished
battle/ownership callbacks. Do not freeze/rewrite WarScore flags merely for LLM latency.
A historical threshold alone cannot override fresh recovery below the threshold.

LLM payload is untrusted. It cannot set forcedAcceptance, receipt status, epoch,
budget, deadline, attempt count or actual game facts. Counteroffers reference only
Native-enumerated legal options. Two rulers' statements are neither ratification
nor execution evidence. Any ordinary agreement completed before expiry still uses
its separate current-consent and Native council path; no execution path is implicit.

## Native settlement boundary

On SettlementDue, Native builds/revalidates forced terms under its existing policy
and preserves the outcome's economic/political mechanics. It may retain its explicit
forced willingness rule; budget/story/alliance/client/delivery constraints remain.
No automatic unapproved paid override or user vote may be forged. Do not convert
failed admission, blocked budget or absent model into free white peace.

The future gateway must distinguish rejected-before-effects, accepted/pending,
applied, and unknown/may-have-effects. At most one in-flight operation exists for
an exact crisis/draft. If peace occurs independently, disappearance of war alone is
not a receipt. Partial gold/land/tribute/hostage/structural effects require recovery
through their actual Native owners before any retry. A receipt records authority
as enforced defeat, not `both_llms_accepted`.

## Persistence, player transitions and information

This stage does not extend S23B ordinary intent records. A separately registered
crisis record/recovery contract will be required; retain every existing save ID.
There is no runtime switch until that, the epoch/gateway/crisis reconciliation and
actual accumulated Windows/game-save gates are proven.

If a player becomes politically involved during a pending crisis, hand control to
the existing player-facing owner and invalidate the NPC operation's authority;
do not auto-sign for the player or let a stale queued callback finish it.

Only after confirmed Native outcome may the news adapter publish public consequences.
Private draft/owner faults/council arguments remain recipient-scoped. News can say
"the realm was forced to concede"; it must not invent a willing agreement. No event
or prompt text itself applies terms or confers knowledge to every NPC.
