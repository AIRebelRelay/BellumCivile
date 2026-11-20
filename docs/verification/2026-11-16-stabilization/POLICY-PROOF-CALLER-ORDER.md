POLICY-PROOF-CALLER-ORDER

ROOT CAUSE AND TRACE
Conclude uses a captured CourtAgendaBehavior local so that proof IDs can be snapshotted before conclusion and the actual audience captured afterwards. The source observer now requires that order and observes the strengthened null/identity guard without requiring it to start with ValidRealm. All other provenance, scope, bound, persistence, and no-effect assertions retained. Complete suite PASS.

BOUNDARY
TOUCH: Tests/Stage31KPolicyVotePublicProvenance.Tests.ps1 and this evidence note only.
DO NOT TOUCH: production code, defaults, shared helpers, persistence, Bridge/Relay, authority or notification behavior.
MUST FIX: obsolete source observation.
MUST NOT CHANGE: existing neighboring checks except the documented moved/current contract.

VALIDATION LIMIT
Source contract only. Native compilation, save/load and campaign behavior remain unverified. No release or merge authorized by these results.
