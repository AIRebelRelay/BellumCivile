# Queued court term ordering — test-only stage

ROOT CAUSE: three objective source tests compare maintenance to an old direct
OpenTerm(realm, manager, ideology) call in Tick. The current implementation delegates
opening to PrepareQueuedCourtTerms -> OpenTerm(..., term), with bounded batches.
The old token is absent (-1), making the textual ordering assertion fail.

TOUCH: the single ordering assertion in CourtCampaignObjective, CourtPeaceObjective
and CourtSubjugationObjective source tests. DO NOT TOUCH: production scheduler,
objective maintenance, batching, term clocks, player priority, saved queue or defaults.
MUST FIX: prove maintenance precedes actual queued preparation and it delegates to
term opening. MUST NOT CHANGE: all remaining objective and XML/localization checks.

Regression: each maintenance and queue token must exist, maintenance index is earlier,
and CourtTermPreparation must call OpenTerm with the captured term. Missing tokens
cannot pass via IndexOf=-1. All three complete scripts now PASS (35, 33, 57 assertions).
Existing CourtTermPreparation suite also PASS (19 assertions). These are four source
suites, not 144 independent gameplay scenarios. Full diffs checked: exactly one
assertion replaced per file; no production changes. Native timing/save QA pending.
