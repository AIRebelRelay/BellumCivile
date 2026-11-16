# Captive incumbent source observer — test-only stage

ROOT CAUSE: candidate selection now compares candidate.StringId with the persisted
office HolderClanId, rather than incumbent object identity. The prisoner restriction
is still the same logical exception for the incumbent only.
TOUCH: one expected expression in CouncilCaptivityScheduling.Tests.ps1, additionally
require incumbentId to originate from that office's HolderClanId. DO NOT TOUCH:
appointments, captivity handling, caches, payments or game code. MUST FIX: observe
the persisted-ID implementation. MUST NOT CHANGE: other source assertions. Whole
suite PASS; full diff audited. This is not the native --council-captivity result.
