# Civil-war grace observer — test-only stage

ROOT CAUSE: TryBegin now calls the identical HasCivilWarGrace(realm) early-return
through local graceManager rather than manager. Legacy source assertion binds to
the obsolete local spelling. The current local is retrieved from the same Campaign
FactionManagerBehavior, before challenger/crown eligibility or record creation.
TOUCH: one expected local name in CivilWarGrace.Tests.ps1. DO NOT TOUCH: grace
length, exceptions, cooldowns, initiation or game code. MUST FIX: observe the actual
mandatory early guard. MUST NOT CHANGE: hereditary/elective guard checks or any
other assertion. Entire source suite PASS; exact one-literal diff audited. Native
save and grace timing remain pending, not inferred from this source result.
