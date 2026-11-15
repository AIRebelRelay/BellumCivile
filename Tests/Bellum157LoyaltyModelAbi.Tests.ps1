# Bannerlord 1.5.7 loyalty model ABI regression contract.
# Offline source checks. Compilation against game DLLs and in-game behavior are separate gates.
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$sourcePath = Join-Path $root 'BellumFeudalSettlementLoyaltyModel.cs'
$hostPath = Join-Path $root 'SubModule.cs'
if (-not (Test-Path -LiteralPath $sourcePath -PathType Leaf) -or
    -not (Test-Path -LiteralPath $hostPath -PathType Leaf)) {
    throw 'BELLUM157_LOYALTY_ABI FAIL missing_required_source'
}
$source = [System.IO.File]::ReadAllText($sourcePath)
$hostSource = [System.IO.File]::ReadAllText($hostPath)

function Assert-Present([string]$text, [string]$fragment, [string]$name) {
    if (-not $text.Contains($fragment)) {
        throw "BELLUM157_LOYALTY_ABI FAIL $name"
    }
    Write-Output "PASS BELLUM157_LOYALTY_ABI $name"
}

if ($source.Contains('GovernorSameCultureLoyaltyEffect') -or
    $source.Contains('GovernorDifferentCultureLoyaltyEffect')) {
    throw 'BELLUM157_LOYALTY_ABI FAIL removed_governor_culture_overrides'
}
Write-Output 'PASS BELLUM157_LOYALTY_ABI removed_governor_culture_overrides'

Assert-Present $source 'public class BellumFeudalSettlementLoyaltyModel : SettlementLoyaltyModel' 'wrapper_class_retained'
Assert-Present $source '_baseModel = baseModel ?? new DefaultSettlementLoyaltyModel();' 'base_model_fallback_retained'
Assert-Present $source 'public override float SettlementOwnerDifferentCultureLoyaltyEffect => _baseModel.SettlementOwnerDifferentCultureLoyaltyEffect;' 'remaining_culture_rule_delegated'
Assert-Present $source 'ExplainedNumber result = _baseModel.CalculateLoyaltyChange(town, includeDescriptions);' 'base_loyalty_change_delegated'
Assert-Present $source 'if (FeudalTitlePenaltyHelper.IsContestedLegalTitle(town, out FeudalTitleRecord _))' 'contested_title_guard_retained'
Assert-Present $source 'result.Add(C.FeudalTitleContestedLoyaltyPenalty, FeudalTitlePenaltyHelper.ContestedLegalTitleText);' 'contested_title_penalty_retained'
Assert-Present $source 'return result;' 'loyalty_result_preserved'
Assert-Present $source '_baseModel.CalculateGoldGainDueToHighLoyalty(town, ref explainedNumber);' 'neighbor_high_loyalty_gold_delegated'
Assert-Present $source '_baseModel.CalculateGoldCutDueToLowLoyalty(town, ref explainedNumber);' 'neighbor_low_loyalty_gold_delegated'
Assert-Present $hostSource 'campaignStarter.AddModel(new BellumFeudalSettlementLoyaltyModel(baseSettlementLoyaltyModel));' 'campaign_registration_retained'
Write-Output 'BELLUM157_LOYALTY_ABI SOURCE_PASS; compile_and_gameplay=NOT_RUN'
