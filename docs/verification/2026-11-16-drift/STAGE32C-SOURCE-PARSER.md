# Stage32C source-parser recovery — completed test-only stage

ROOT CAUSE: an extra `)` after IndexOf at line 79 closes the Check expression
before its final -and operand, leaving line 80 with an unmatched closing parenthesis.
Original baseline and candidate reproduce ParserError before any assertion executes.

TOUCH: Tests/Stage32CCourtPolicyVoteRecipientRoster.Tests.ps1, one character removed.
DO NOT TOUCH: production policy-vote receipts, privacy rules, assertion operands or strings.
MUST FIX: parser acceptance and execution of every existing source check.
MUST NOT CHANGE: exact proof identity, actor roster and stale/foreign proof rejection.

Regression contract/results: parser RED before; parser accepted after; 15 source
checks PASS. All quoted strings remain byte-equivalent. Full diff is one closing
parenthesis removal. No native execution, save or live audience correctness claimed.
