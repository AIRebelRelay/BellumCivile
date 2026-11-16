# P005 source-parser recovery — completed test-only stage

ROOT CAUSE: multiline Boolean clauses start new PowerShell lines with `-and` after
a complete method expression. The original script fails parsing at line 14, so no
assertion executes. Reproduced on baseline bf1e019 and drift candidate c4d2fd0.

TOUCH: Tests/P005CrownRebellionSafetySource.Tests.ps1 only. Move whitespace around
existing `-and` tokens so the operator ends the preceding line.
DO NOT TOUCH: all production code, assertion strings, Boolean operands, test meanings,
other scripts, save data, Bridge/Relay/CR.
MUST FIX: parser acceptance and execution of all 13 existing checks.
MUST NOT CHANGE: any original assertion or expected production behavior.

Regression contract: original source is parser RED; candidate must parse and pass all
13 checks; removing whitespace must produce identical old/new text.
Actual result: 13/13 PASS in PowerShell 7.5.4. Whitespace-stripped old/new identical.
Full diff reviewed; one source test edited, no shipping files changed. This does not
claim native crown/rebellion harness, game or save/load PASS.

Reproduce from source root:
```powershell
pwsh -NoProfile -File .\Tests\P005CrownRebellionSafetySource.Tests.ps1
```
