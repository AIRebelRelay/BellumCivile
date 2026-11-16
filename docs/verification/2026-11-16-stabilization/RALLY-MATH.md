Rally peace-readiness regression

TOUCH: new Tests/RallyPeaceReadiness.Tests.ps1 only; production remains unchanged. This compiles the complete actual BellumCivileConstants.cs, PeaceReadiness.cs and CourtRallyRecord.cs with minimal record/attribute declarations, then probes actual methods. Type doubles do not simulate campaign behavior.

Regression contract: seven named input cases cover early/late campaigns, exhausted/ordinary will, crossing the readiness threshold, near-cap and already-capped enthusiasm. Each requires ineligible baseline preservation, nondecreasing capped effective will, nonincreasing willingness for peace, and base-plus-delta equivalence. An eighth named case proves the threshold crossing differs from the obsolete linear delta, preventing a misleading linear-model source contract.

Result: 8 named math scenarios PASS in PowerShell 7.5.4/.NET 9. Scope routing is separately checked in CourtRally.Tests.ps1. Native TreatyRatification/game behavior remains pending.
