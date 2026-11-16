# Dynastic marriage source contract — test-only stage

ROOT CAUSE: upstream extracted shared dynasty/household search into
EvaluateMarriageOpportunity(clan, household). The legacy test looks for a direct
ShouldEvaluateToday guard and direct _lastHouseEvaluationYear assignment that no
longer exist in that shape. StrategicMarriageBehavior is byte-identical to author
8a08e0c038a60030813c56eae39a5fbee0b75cb6; no production restoration is warranted.

Call chain: OnDailyTickClan first processes active prospects, then court dynastic
pursuit, then ordinary EvaluateMarriageOpportunity(clan,false). That helper uses
the dynasty annual gate when household=false, selects the correct yearly dictionary
and records the year before MBRandom.RandomFloat. Household search remains separate.

TOUCH: exactly two assertions in CourtDynasticObjective.Tests.ps1. DO NOT TOUCH:
marriage scoring, eligibility, AI choices, prospect persistence, family rules or game
code. MUST FIX: observe the current delegated order and receipt-before-roll.
MUST NOT CHANGE: the remaining checks, family/foreign acceptance and XML fixtures.
Both required call indices must exist, and dictionary selection plus the annual
conditional are asserted explicitly. Whole source/XML suite PASS; full diff audited.
This does not claim actual marriages, UI or save/load pass.
