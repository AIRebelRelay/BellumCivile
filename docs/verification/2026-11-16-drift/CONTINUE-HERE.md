# AI Bannerlord — continue here, 2026-11-16

User authorization: continue independent analysis/testing without waiting for replies.
User sleeps; do not interpret a missing response as an approval requirement.
No merge/release or unrelated production changes. ZIP + PowerShell workflow.

## Current source branches / stages

- Integration branch still bf1e019111674fba8f31e2315d38ab5d3b954985.
- Main still 59b2aee8268cf1633e052e6b44e1cdba0e3c15fb.
- Drift candidate c4d2fd01c759051e0774710d96685da170d8f526, Draft PR #43.
  Native Harmony/full Windows run pending. No certainty that JIT candidate is fixed.
- Parser recovery head 9e05ff8ae608856c5518a4f7de4ad23041afd9e5, Draft PR #44.
  Four separate syntax-only commits. P005 13 checks; Stage32C 16 checks.
- Restoration membership candidate 5390b58d09987572a522bccbcc6664c26e7b104b,
  Draft PR #45. Exactly two production lines removed, plus source-derived regression
  and its stage report. 5/12 RED before, 12/12 PASS after. P101E/F pass again.

## Tests and unresolved gates

All 227 PowerShell test scripts parse. Read-only source sweep 129 PASS / 29 FAIL;
original 31 failures all reproduced on base, two recovered parsers now PASS.
No assertions removed to fake green. New scope test and original P101E/F compile
actual predicate/guard extracts, not the native game assembly.
Additional isolated source/predicate sweep: 21/23 PASS after installing .NET 9.0.11.
Remaining GamePath failure needs Windows ProgramFilesX86; P014H still expects two
forwarded dependency properties although MCM is now intentionally the third.
CourtRedesignHarness compiled and executed: 200486 production-math/XML checks PASS;
this is not the native campaign lifecycle. P014E Workshop and P014F old game-version
manifest fixture tests PASS. Legacy Stage9 synthetic build-gate test remains FAIL.
The third standalone NativeInitialChildGeneration net472 harness also requires real
game DLLs; its old direct Modules Harmony path needs a separate build-reference audit
before proposing a Windows command for it.
SDK 10.0.100 and pwsh 7.5.4 are now provisioned; initial lack-of-SDK notes describe
the earlier drift stage, not the current environment. Real Workshop MSBuild reference
resolution test P014G now PASS, including explicit override and decoy rejection.
Complete matching game DLL set is still unavailable; Windows full harness/build,
Bannerlord startup, save/load and actual callback behavior remain open.

CR SDK full tests: 2331 PASS, 0 FAIL. CR host/Logic suite: 7414 PASS, 43 FAIL,
148 skipped; see CR-2812-CONTRACT.md and cr-host-failures.json. No external LLM
request or game action was executed. No upstream CR code patched.

## API source of truth

Actual host is LogRaam/calradia-remembers main
ab539bb66fac59fc6b68d2c027cdaa9e6fd58b9d, v2.8.12, CrApi.Version=2.
LLM-Roleplay-Service is its separate SDK, not the whole mod. Use new Persona and
optional CrLlm APIs, public Feed/knowledge/authority doors; do not recreate them.
CrLlmRequest lacks per-route model/endpoint overrides: preserve project NanoGPT via
AI Rebel Relay route requirements; do not quietly route everything to CR's prose model.

API-COVERAGE-MATRIX.csv covers 19 domain groups with explicit gaps/visibility and
consumer status. Roslyn syntactic indexes cover the entire production source tree:
2052 public method declarations, 463 notification callsites, 401 persistence callsites.
These are exhaustive for the selected syntax, NOT exhaustive semantic/API coverage.
No source visibility or current-state correctness can be inferred from a filename.

## Next independent work

1. See remaining-source-gates.json for first-failure triage of all 29 gates.
   A real missing early Revamp-OFF fence is demonstrated in ForeignTreatyBehavior.OnTick;
   its downstream TryOpenPlayerParley fence remains, so do not claim actual peace
   execution while OFF. Separate call-chain/history/regression stage required.
   Classify remaining source failures against current code/version contracts;
   distinguish stale version/layout checks from actual lost behavior. Do not weaken
   checks or bundle unrelated production fixes. New production stages must wait for
   the current candidate's required native validation or be explicitly independent.
2. Continue semantic API joins, using the 19-domain map and syntax indexes as an
   index, not as proof. Highest gaps: all court reactions/notifications, terminal
   succession/civil/feud receipts, treaty/clientage/tribute and all-clan title/economy.
3. Define source-stable, campaign-scoped event receipts, detached snapshots, visibility,
   bounded retention/backfill and delivery acknowledgements. Callback Dispatched is
   not durable consumer acceptance. Native recent result retention is 100.
4. CR Feed quota 20 new source events/day requires prioritization/coalescing and a
   truthful delivery backlog. Current state belongs in scoped live variables where
   appropriate. Bellum full API availability is not a whole-world prompt dump.

See RESTORATION-MEMBERSHIP-STAGE.md for exact root/call chain/regressions and
CR-2812-CONTRACT.md for verified host and old Bellum Bridge transport contracts.
Bellum Bridge and Relay Bridge remain separate; AI Influence is inspiration only.
