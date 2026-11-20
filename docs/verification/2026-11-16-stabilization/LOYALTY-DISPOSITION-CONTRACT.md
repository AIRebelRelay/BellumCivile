# Loyalty presentation observer — test-only stage

ROOT CAUSE: disposition text/localization moved to SuccessionDisposition.Value.
The old test demands BC_Loyalty_Disloyal directly inside the succession VM, although
the VM calls that helper. The helper is byte-identical to author 8a08e0c.
TOUCH: HereditaryLoyalty.Tests.ps1, read the helper, require VM delegation plus its
disloyal state and validate the combined VM/helper localization IDs. DO NOT TOUCH:
loyalty math, caching, legal sovereign resolution, UI source or helper. MUST FIX:
observe the actual text owner. MUST NOT CHANGE: readonly/cache tests and state labels.
Entire source suite PASS, including the additional shared-state localization IDs.
Full diff audited; no production code changed or assertion discarded. Actual regency,
Gauntlet rendering and save/load remain pending.
