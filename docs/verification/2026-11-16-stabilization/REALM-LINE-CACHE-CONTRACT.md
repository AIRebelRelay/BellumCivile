# Realm succession line observer — test-only stage

ROOT CAUSE: the VM now prefers HereditaryLoyaltyBehavior.GetLine and retains the
full HereditaryRealmSuccession.GetLine fallback. The legacy assertion requires a
direct return. The cache itself fills cache.Line through the identical complete
realm-line provider, with population/revision/law input checks.
TOUCH: one assertion in HereditaryRealmLine.Tests.ps1. Require the explicit cached
VM route, complete fallback and cache fill provider. DO NOT TOUCH: eligibility,
cache invalidation, regency, inheritance or UI/game code. MUST FIX: observe the
current complete-line call chain. MUST NOT CHANGE: all other legal-family tests.
Whole source suite PASS; full diff audited. Native succession/save QA pending.
