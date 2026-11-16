Crown maintenance source contract

Root cause: elective maintenance moved from OpenTerm to the tick before queued term preparation; the old source observer searched only OpenTerm.
Touch: Tests/P011CourtCrownStability.Tests.ps1 only. Court scheduling, Crown resolution and callbacks unchanged.
Regression contract: elective maintenance precedes queued preparation; queued helper validates the ruler before opening; OpenTerm validates again; existing post-callback admission checks remain.
Validation: complete P011 suite PASS. Source ordering does not replace native/game Crown-transition validation.
