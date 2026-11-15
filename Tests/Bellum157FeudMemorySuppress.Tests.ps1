# 1.5.7 / Bellum 1.4.12b Stage 2B: legacy feud-memory harness expectation regression.
# Source-only. Runtime harness remains required.
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$test = [IO.File]::ReadAllText((Join-Path $root 'Tests/SuccessionEngineHarness/GameplayRelationMemoryTests.cs'))
$gameplay = [IO.File]::ReadAllText((Join-Path $root 'Behaviors/ClaimFeudBehavior.cs'))
$runner = [IO.File]::ReadAllText((Join-Path $root 'Tests/SuccessionEngineHarness/Program.cs'))
function Check([bool]$ok,[string]$case) {
    if (-not $ok) { throw "BELLUM157_FEUD_MEMORY FAIL $case" }
    "PASS BELLUM157_FEUD_MEMORY $case"
}
Check ($gameplay.Contains('if (ruler == null || judgment == ClaimFeudJudgment.Suppress)')) 'suppress_routes_to_royal_peace_without_per_feud_relations'
Check ($gameplay.Contains('if (judgment == ClaimFeudJudgment.Suppress || TryPauseFeudForRoyalPeace(record, out _))')) 'royal_peace_suppresses_legacy_ruling_path'
Check ($test.Contains('judgment == ClaimFeudJudgment.Suppress ? Array.Empty<string>()')) 'suppress_expects_no_personal_memory'
Check (!$test.Contains('judgment == ClaimFeudJudgment.Suppress ? new[] { RelationMemorySources.SuppressedMyClaim }')) 'stale_suppress_expectation_removed'
Check ($test.Contains('ClaimFeudJudgment.UpholdClaimant, ClaimFeudJudgment.UpholdHolder')) 'regular_rulings_still_covered'
Check ($test.Contains('RelationMemorySources.UpheldMyTitleRights, RelationMemorySources.RejectedMyTitleRights')) 'uphold_relation_causes_preserved'
Check ($test.Contains('RelationMemorySources.WithheldFeudJudgment, RelationMemorySources.WithheldFeudJudgment')) 'abstain_relation_causes_preserved'
Check ($test.Contains('RelationMemorySources.DefiedFeudJudgment')) 'defiance_relation_cause_preserved'
Check ($test.Contains('Changes.Select(c => c.Source).SequenceEqual(expected)')) 'zero_effect_and_neighbor_causes_asserted'
Check ($test.Contains('c.Scope == RelationMemoryScope.Personal && c.Days == DefaultDays(c.Amount)')) 'neighbor_duration_and_scope_asserted'
Check ($test.Contains('CheckTreatyEffects(check, first, second);')) 'treaty_regressions_still_called'
Check ($test.Contains('CheckCouncilEffects(check, ruler, holder);')) 'council_regressions_still_called'
Check ($runner.Contains('GameplayRelationMemoryTests.Run(Check);')) 'harness_entrypoint_preserved'
'BELLUM157_FEUD_MEMORY SOURCE_PASS; harness_runtime_gameplay=NOT_RUN'
