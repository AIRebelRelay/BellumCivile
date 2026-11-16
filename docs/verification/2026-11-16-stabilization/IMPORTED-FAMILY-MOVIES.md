# Imported family movie scopes — test-only stage

ROOT CAUSE: P012B still requires Clan Household to be absent, a checkpoint before
that upstream feature was ported. Current finalizer explicitly dispatches Hero
Family and Clan Household by distinct movie IDs. The divider additionally handles
MembersDivider only when Clan Household is enabled and its marked subtree exists.

TOUCH: the two obsolete exclusion assertions in P012BFamilyUiCompatibility.
The boundary was reassessed after the second exclusion surfaced. Require both
exact movie dispatches, original FamilyDivider compatibility gate, enabled
MembersDivider gate and BellumClanHousehold parent-subtree marker. DO NOT TOUCH:
any production XML/VM/Harmony source, family shape or external mod adaptation.
MUST FIX: validate present imported features, not their prior absence.
MUST NOT CHANGE: unsupported dividers stay native; all other P012B checks remain.
Entire suite PASS, including optional Family Tree owner/IL isolation checks.
Full diff audited; native UIExtender/rendering tests are still pending.
