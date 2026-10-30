$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
function Read([string]$path) { Get-Content -LiteralPath (Join-Path $root $path) -Raw }
function Check([bool]$ok, [string]$name) {
    if (-not $ok) { throw "STAGE31L FAIL $name" }
    Write-Host "STAGE31L PASS $name"
}

$api = Read 'BellumIntegration.cs'
$join = Read 'Behaviors/CourtPolicyVoteProvenanceJoin.cs'
$dto = Read 'CourtPolicyVoteProvenanceJoinSnapshot.cs'
$original = Read 'Behaviors/CourtTerminalEvictionReceipts.cs'
$proof = Read 'Behaviors/CourtPolicyVotePublicProvenance.cs'
$court = Read 'Behaviors/CourtAgendaBehavior.cs'
$save = Read 'BellumCivileSaveDefiner.cs'
$test31k = Read 'Tests/Stage31KPolicyVotePublicProvenance.Tests.ps1'

Check ($api.Contains('GetCourtPolicyVoteProvenanceJoin(Kingdom realm)') -and
    $api.Contains('BellumIntegrationBehavior.RequireCampaignThread();') -and
    $api.Contains('CourtAgendaBehavior.Current?.GetPolicyVoteProvenanceJoin(realm)')) 'API_gate_readonly_campaign_thread'
Check ($join.Contains('internal CourtPolicyVoteProvenanceJoinSnapshot GetPolicyVoteProvenanceJoin(Kingdom realm)') -and
    $join.Contains('_courtTerminalReceipts') -and
    $join.Contains('_courtPolicyVotePublicProvenance')) 'join_only_native_two_saved_ledgers'
Check ($join.Contains('TryReadCourtTerminalPayload(pair.Key, pair.Value, out payloadRealm)') -and
    $join.Contains('TryReadVoteProof(') -and
    $join.Contains('TryMatchPolicyVote(')) 'reuse_native_terminal_validation_and_matching'
Check ($join.Contains('fields.Length != 13') -and
    $join.Contains('proofFields.Length != 10') -and
    $join.Contains('new UTF8Encoding(false, true)') -and
    $join.Contains('Convert.FromBase64String(')) 'strict_bounded_versioned_join_decoding'
Check ($join.Contains('Guid.TryParseExact(id, "N"') -and
    $join.Contains('double.TryParse(') -and
    $join.Contains('double.IsNaN(') -and
    $join.Contains('double.IsInfinity(')) 'exact_id_and_finite_observation_days'
Check ($join.Contains('"realm_court"') -and
    $join.Contains('"court_policy_conclude"') -and
    $join.Contains('"current_mandate"') -and
    $join.Contains('"obsolete_mandate"')) 'explicit_source_audience_and_obsolete_mandate'
Check ($join.Contains('"policy"') -and
    $join.Contains('"Passed"') -and
    $join.Contains('"Defeated"') -and
    $join.Contains('"Succeeded"') -and
    $join.Contains('"Failed"') -and
    $join.Contains('"Sponsor"') -and
    $join.Contains('"None"') -and
    $join.Contains('string.IsNullOrEmpty(receiptFields[11])')) 'no_technical_cancellation_or_unsupported_terminal_result'
Check ($join.Contains('string.Equals(receiptFields[1], proof.RealmId, StringComparison.Ordinal)') -and
    $join.Contains('string.Equals(receiptFields[3], proof.SponsorId, StringComparison.Ordinal)') -and
    $join.Contains('string.Equals(receiptFields[5], proof.PolicyId, StringComparison.Ordinal)') -and
    $join.Contains('string.Equals(receiptFields[6], proof.Action, StringComparison.Ordinal)') -and
    $join.Contains('receiptDay < proof.VoteDay')) 'cross_check_realm_sponsor_policy_action_and_chronology'
Check ($join.Contains('int conflicts = 0;') -and
    $join.Contains('int missingProof = 0;') -and
    $join.Contains('int proofInvalid = 0;') -and
    $join.Contains('int terminalInvalid = 0;') -and
    $join.Contains('_courtTerminalEvictionOverflow') -and
    $join.Contains('_courtPolicyVotePublicProvenanceOverflow')) 'global_diagnostics_invalid_overflow_and_conflicts'
Check ($dto.Contains('public sealed class CourtPolicyVoteProvenanceJoinSnapshot') -and
    $dto.Contains('public sealed class CourtPolicyVoteJoinedReceiptSnapshot') -and
    $dto.Contains('public IReadOnlyList<CourtPolicyVoteJoinedReceiptSnapshot> Matched { get; }') -and
    $dto.Contains('public bool IsHealthy => SourceAvailable') -and
    $dto.Contains('ConflictCount == 0')) 'immutable_bounded_delivery_not_claimed'
Check ($join.Contains('matched.AsReadOnly()') -and
    $join.Contains('OrderBy(pair => pair.Key, StringComparer.Ordinal)') -and
    $join.Contains('if (invalidOrOverflow) matched.Clear();')) 'stable_order_and_fail_closed_empty_match_on_bad_health'
Check (-not $join.Contains('GetObjective(') -and
    -not $join.Contains('.Finish(') -and
    -not $join.Contains('AcknowledgeCourt') -and
    -not $join.Contains('ConsumeAcknowledged(') -and
    -not $join.Contains('_courtTerminalReceipts.Remove(') -and
    -not $join.Contains('_courtPolicyVotePublicProvenance.Remove(') -and
    -not $join.Contains('RecordSourceBackedFact(')) 'no_mutation_ack_or_sidecar_publication'
Check ($proof.Contains('BC_CourtPolicyVotePublicProvenance_v1') -and
    $proof.Contains('RecordCourtPolicyVotePublicProvenance(') -and
    $original.Contains('BC_CourtTerminalEvictionReceipts_v1') -and
    $court.Contains('SyncCourtTerminalEvictionReceipts(dataStore);') -and
    $court.Contains('SyncCourtPolicyVotePublicProvenance(dataStore);') -and
    $save.Contains('ConstructContainerDefinition(typeof(Dictionary<string, string>))') -and
    $test31k.Contains('STAGE31K_SOURCE_CONTRACT_PASS')) 'prior_native_capture_and_save_contracts_intact'
Write-Host 'STAGE31L_SOURCE_CONTRACT_PASS -- no PowerShell execution/build/save-load/game/NPC E2E proof.'
