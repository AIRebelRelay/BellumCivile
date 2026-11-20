# Bannerlord 1.5.7 council patrol party size ABI regression contract.
# Offline source checks only; real build and live patrol/naval validation remain separate.
$ErrorActionPreference = 'Stop'
$sourcePath = Join-Path (Split-Path -Parent $PSScriptRoot) 'CouncilAssignmentRuntimePatches.cs'
if (-not (Test-Path -LiteralPath $sourcePath -PathType Leaf)) {
    throw "BELLUM157_PARTY_SIZE FAIL missing_source=$sourcePath"
}
$source = [System.IO.File]::ReadAllText($sourcePath)

function Assert-Has([string]$needle, [string]$name) {
    if (-not $source.Contains($needle)) { throw "BELLUM157_PARTY_SIZE FAIL $name" }
    Write-Output "PASS BELLUM157_PARTY_SIZE $name"
}

Assert-Has '"GetPartyMemberSizeLimit",' 'target_name_retained'
Assert-Has 'new[] { typeof(PartyBase), typeof(bool), typeof(bool) },' 'target_signature_three_parameters'
if ($source.Contains('new[] { typeof(PartyBase), typeof(bool) },')) {
    throw 'BELLUM157_PARTY_SIZE FAIL obsolete_target_signature_absent'
}
Write-Output 'PASS BELLUM157_PARTY_SIZE obsolete_target_signature_absent'

$expectedCall = 'model.GetPartyMemberSizeLimit(party.Party, includeDescriptions: false, isCurrentlyAtSea: party.IsCurrentlyAtSea)'
$callCount = ([regex]::Matches($source, [regex]::Escape($expectedCall))).Count
if ($callCount -ne 2) {
    throw "BELLUM157_PARTY_SIZE FAIL sea_state_forwarded_for_base_and_target count=$callCount"
}
Write-Output 'PASS BELLUM157_PARTY_SIZE sea_state_forwarded_for_base_and_target count=2'

if ([regex]::Matches($source, 'model\.GetPartyMemberSizeLimit\(').Count -ne 2) {
    throw 'BELLUM157_PARTY_SIZE FAIL no_other_party_limit_call_patterns'
}
Write-Output 'PASS BELLUM157_PARTY_SIZE no_other_party_limit_call_patterns'

Assert-Has 'if (party?.IsPatrolParty != true || party.Party == null || party.HomeSettlement == null)' 'nonpatrol_guard_retained'
Assert-Has '_suppressPatrolSizeAssignment = true;' 'base_limit_suppression_begin'
Assert-Has '_suppressPatrolSizeAssignment = false;' 'base_limit_suppression_end'
Assert-Has 'return baseLimit > 0 && targetLimit > baseLimit;' 'positive_slots_only'
Assert-Has '__result.AddFactor(' 'patrol_size_add_factor_retained'
Assert-Has 'nameof(ApplyPatrolSizeAssignment));' 'patrol_postfix_wiring_retained'
Assert-Has 'nameof(ApplyPatrolRosterAssignment));' 'patrol_roster_wiring_retained'
Assert-Has 'nameof(ApplyArmyFoodAssignment));' 'army_food_neighbor_retained'
Assert-Has 'nameof(ApplyVillageProductionAssignment));' 'village_production_neighbor_retained'
Assert-Has '.GetPartyTemplateForPatrolParty(party.HomeSettlement, party.PatrolPartyComponent.IsNaval);' 'naval_roster_selection_retained'
Assert-Has 'PatchedMethods.Add(target);' 'patch_idempotency_retained'
Write-Output 'BELLUM157_PARTY_SIZE SOURCE_PASS; compile_and_gameplay=NOT_RUN'
