# Stage32E1 — RED/current-contract source regression for save-native Court knowledge.
# No production edit and no new NPC JSON or Relay ledger. Windows/game save
# roundtrip MUST be tested separately before declaring persistence verified.
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
function Read([string]$name) { Get-Content -LiteralPath (Join-Path $root $name) -Raw }
function Check([bool]$condition, [string]$name) {
    if (-not $condition) { throw "STAGE32E1_FAIL $name" }
    Write-Host "STAGE32E1_PASS $name"
}
$court = Read 'Behaviors/CourtAgendaBehavior.cs'
$terminal = Read 'Behaviors/CourtTerminalEvictionReceipts.cs'
$proof = Read 'Behaviors/CourtPolicyVotePublicProvenance.cs'
$audience = Read 'Behaviors/CourtPolicyVoteAudience.cs'
$sourceJoin = Read 'Behaviors/CourtPolicyVoteProvenanceJoin.cs'
$integration = Read 'BellumIntegration.cs'
$schema = Read 'BellumCivileSaveDefiner.cs'

Check ($court.Contains('public override void SyncData(IDataStore dataStore)') -and
    $court.Contains('SyncCourtTerminalEvictionReceipts(dataStore);') -and
    $court.Contains('SyncCourtPolicyVotePublicProvenance(dataStore);') -and
    $court.Contains('SyncCourtPolicyVoteAudience(dataStore);')) 'all_three_histories_saved_through_court'
Check ($terminal.Contains('store.SyncData("BC_CourtTerminalEvictionReceipts_v1"') -and
    $terminal.Contains('store.SyncData("BC_CourtTerminalEvictionOverflow_v1"') -and
    $terminal.Contains('_courtTerminalReceipts = _courtTerminalReceipts ??')) 'terminal_receipts_roundtrip_keys_and_missing_legacy_default'
Check ($proof.Contains('store.SyncData("BC_CourtPolicyVotePublicProvenance_v1"') -and
    $proof.Contains('ref _courtPolicyVotePublicProvenance);') -and
    $proof.Contains('store.SyncData("BC_CourtPolicyVotePublicProvenanceOverflow_v1"')) 'vote_proof_saved_not_only_in_memory'
Check ($audience.Contains('store.SyncData("BC_CourtPolicyVoteAudience_v1"') -and
    $audience.Contains('store.SyncData("BC_CourtPolicyVoteAudienceOverflow_v1"') -and
    $audience.Contains('_courtPolicyVoteAudience = _courtPolicyVoteAudience')) 'exact_recipient_roster_saved_separately'
Check ($audience.Contains('_courtPolicyVoteAudience.Add(agenda.IntegrationId, payload);') -and
    $proof.Contains('_courtPolicyVotePublicProvenance.Add(agenda.IntegrationId, value);') -and
    $terminal.Contains('_courtTerminalReceipts.Add(agenda.IntegrationId,')) 'all_three_have_exact_integration_id_history'
Check ($sourceJoin.Contains('GetPolicyVoteProvenanceJoin(Kingdom realm)') -and
    $sourceJoin.Contains('_courtTerminalReceipts') -and
    $sourceJoin.Contains('_courtPolicyVotePublicProvenance') -and
    $audience.Contains('GetPolicyVoteProvenanceJoin(realm)')) 'fresh_post_load_native_join_not_stale_relay_memory'
Check ($audience.Contains('Legacy save: hold just this result, no retroactive guesses.') -and
    $audience.Contains('missingAudience++') -and
    $audience.Contains('joined.IsHealthy') -and
    $audience.Contains('_courtPolicyVoteAudienceOverflow != 0')) 'legacy_and_bad_ledger_denied_without_retroactive_recipient_guess'
Check ($audience.Contains('KingdomVoteAlignmentTracker.TryGetRecordedParticipants(') -and
    $audience.Contains('heroIds.Count > MaxPolicyVoteAudienceHeroes') -and
    $audience.Contains('string.CompareOrdinal(previous, heroId)')) 'ballot_recorded_hero_ids_not_inferred_clan_role'
Check ($audience.Contains('MaxCourtPolicyVoteAudience = 1024') -and
    $proof.Contains('MaxCourtPolicyVotePublicProvenance = 1024') -and
    $terminal.Contains('MaxCourtTerminalReceipts')) 'persistence_bounds_preserved'
Check ($integration.Contains('GetCourtPolicyVoteAudienceJoin(') -and
    $integration.Contains('GetCourtPolicyVoteProvenanceJoin(')) 'native_read_only_join_API_unchanged'
Check ($court.Contains('SyncCourtPolicyVoteAudience(dataStore);') -and
    $schema.Contains('ConstructContainerDefinition(typeof(Dictionary<string, string>))')) 'save_type_compatibility_for_string_dicts'
Write-Host 'STAGE32E1_SOURCE_CONTRACT_COMPLETE — NOT a save/load runtime PASS'
