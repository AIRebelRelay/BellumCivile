# P101E source-parser recovery — parser fixed, semantic gate RED

ROOT CAUSE: a leading -and on line 21 prevents PowerShell parsing.
TOUCH: Tests/P101ECollapseClaimantCrown.Tests.ps1, whitespace around one -and only.
DO NOT TOUCH: production faction transfer, assertion meanings or old guard checks.
MUST FIX: execute the existing checks; MUST NOT CHANGE their conditions.

Regression result: parser accepted; whitespace-stripped old/new identical; four source
checks PASS, then the original negative guard assertion fails. The current
FactionManagerBehavior.OnClanChangedKingdom still contains an extra
IsRestoredCreationPending(faction.ParentKingdom) skip after both exact owned-transfer
guards. This is a newly exposed semantic gate, not a parser failure.

Classification: production/test-contract conflict requiring architectural review.
Do not delete the check to get green and do not remove the shared guard speculatively.
Trace IsRestoredCreationPending -> RestoredRealmCreationRecord.Protects, active
recovery journal lifetime, upstream version chain and all membership callers first.

Native executable part remains unexecuted because the source gate correctly stops.
No build/game/save PASS and no production repair claimed. Full diff audited.
