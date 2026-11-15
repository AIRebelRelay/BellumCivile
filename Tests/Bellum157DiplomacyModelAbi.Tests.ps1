# Stage 1: Bannerlord 1.5.7 DiplomacyModel ABI regression.
# Source-only checks; the real Windows net472 build and gameplay validation are separate gates.
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$sourcePath = Join-Path $root 'CivilWarDiplomacyModel.cs'
if (-not (Test-Path -LiteralPath $sourcePath -PathType Leaf)) {
    throw "BELLUM157_DIPLOMACY_ABI missing_source=$sourcePath"
}
$source = [System.IO.File]::ReadAllText($sourcePath)

function Assert-SourcePresent([string]$needle, [string]$label) {
    if (-not $source.Contains($needle)) {
        throw "BELLUM157_DIPLOMACY_ABI FAIL $label"
    }
    Write-Output "PASS BELLUM157_DIPLOMACY_ABI $label"
}

Assert-SourcePresent 'public override int GetEffectiveRelationChange(Hero hero1, Hero hero2, int relationChange) => _baseModel.GetEffectiveRelationChange(hero1, hero2, relationChange);' 'new_effective_relation_change_forwarded'
if ($source.Contains('GetRelationIncreaseFactor(')) {
    throw 'BELLUM157_DIPLOMACY_ABI FAIL removed_legacy_relation_factor'
}
Write-Output 'PASS BELLUM157_DIPLOMACY_ABI removed_legacy_relation_factor'
Assert-SourcePresent 'private readonly DiplomacyModel _baseModel;' 'wrapped_base_model_retained'
Assert-SourcePresent '_baseModel = baseModel ?? new DefaultDiplomacyModel();' 'fallback_base_model_retained'
Assert-SourcePresent 'public override float GetStrengthThresholdForNonMutualWarsToBeIgnoredToJoinKingdom(Kingdom kingdomToJoin) => _baseModel.GetStrengthThresholdForNonMutualWarsToBeIgnoredToJoinKingdom(kingdomToJoin);' 'neighbor_strength_threshold_retained'
Assert-SourcePresent 'public override int GetInfluenceAwardForSettlementCapturer(Settlement settlement) => _baseModel.GetInfluenceAwardForSettlementCapturer(settlement);' 'neighbor_influence_reward_retained'
Write-Output 'BELLUM157_DIPLOMACY_ABI SOURCE_PASS; compile_and_gameplay=NOT_RUN'
