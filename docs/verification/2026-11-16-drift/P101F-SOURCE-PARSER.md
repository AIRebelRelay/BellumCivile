# P101F source-parser recovery — parser fixed, semantic gate RED

ROOT CAUSE: line 24 uses C# `<` rather than PowerShell `-lt` between two IndexOf
integers. PowerShell treats it as invalid redirection, so the script never runs.
TOUCH: Tests/P101FRestoredHouseholdOwnership.Tests.ps1, exactly one operator token.
DO NOT TOUCH: operands, assertion strings, production clan transfers or saved records.
MUST FIX: numeric earlier-than comparison parses. MUST NOT CHANGE comparison intent.

Results: parser accepted; six existing checks PASS; original negative broad-suppression
assertion then correctly fails against FactionManagerBehavior.OnClanChangedKingdom.
This is the same shared-guard conflict exposed by P101E, not a reason to weaken tests.
All quoted literals unchanged and full one-token diff audited. Add-Type ownership
regressions remain blocked behind the failing source guard. Game/save/build unverified.
