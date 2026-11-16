Standing election source contract

Root cause: the old source observer expected a direct duration assignment; current production takes the next court evaluation and retains valid promises through ElectiveSuccessionRules.RetainPromise.
Touch: Tests/StandingElections.Tests.ps1 only. Production elections, calendar, and persistence remain unchanged.
Regression contract: calendar-derived expiry, copied promise expiry/source, and the frozen-or-not-expired plus valid-nominee retention predicate must remain present. Existing suite checks retained.
Validation: complete StandingElections suite PASS. This is a source contract, not game lifecycle validation.
