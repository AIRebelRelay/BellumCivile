# Player signing source contract — test-only stage

ROOT CAUSE: two legacy source tests require a four-argument ApplyTreaty at player
signing. The current port passes playerReviewedWhitePeace explicitly to the
optional fifth argument, preserving the new reviewed-white-peace validation path.
ApplyTreatyCore remains four-argument. No runtime signature regression is implied.

TOUCH: only the expected player-sign call in Stage32H2O and Stage32H2P source tests.
DO NOT TOUCH: production code, OFF fences, influence/council ordering or treaty logic.
MUST FIX: validate the current exact call, not an obsolete textual spelling.
MUST NOT CHANGE: the existing OFF-before-mutation and ON-vote/draft/open paths.

Before: both fail at the old call expectation. After: both full source scripts PASS.
All other assertions are byte-identical; full diffs audited. H2O still checks the
OFF gate before SpendCouncilCommitments; H2P retains all five public mutation
freezes and ON-path checks. This is source evidence, not native game/save evidence.
