$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
function Read([string]$path) { Get-Content -LiteralPath (Join-Path $root $path) -Raw }
function Check([bool]$ok, [string]$name) {
    if (-not $ok) { throw "STAGE32C FAIL $name" }
    Write-Host "STAGE32C PASS $name"
}

# Source/contract regressions; C# build, campaign save/load and real vote replay are separate release gates.
$vote = Read 'Patches/KingdomVoteAlignmentTracker.cs'
$resolution = Read 'Patches/PolicyVoteResolutionPatch.cs'
$capture = Read 'Behaviors/CourtPolicyVoteAudience.cs'
$dto = Read 'CourtPolicyVoteAudienceJoinSnapshot.cs'
$integration = Read 'BellumIntegration.cs'
$court = Read 'Behaviors/CourtAgendaBehavior.cs'
$proof = Read 'Behaviors/CourtPolicyVotePublicProvenance.cs'
$terminal = Read 'Behaviors/CourtTerminalEvictionReceipts.cs'
$join = Read 'Behaviors/CourtPolicyVoteProvenanceJoin.cs'
$save = Read 'BellumCivileSaveDefiner.cs'

Check ($vote.Contains('TryGetRecordedParticipants(KingdomDecision decision') -and
    $vote.Contains('VoteSnapshots.TryGetValue(decision') -and
    $vote.Contains('new List<Clan>(alignments.Keys)') -and
    -not $vote.Contains('new List<Clan>(chosenOutcome.SupporterList')) 'captured_ballot_includes_opposition_and_neutrals_without_fallback'
Check ($vote.Contains('if (decision == null || possibleOutcomes == null || chosenOutcome == null)') -and
    $vote.Contains('VoteSnapshots[decision] = alignments;') -and
    $vote.Contains('VoteSnapshots.Remove(decision);') -and
    $vote.Contains('GetAlignment(')) 'shared_vote_tracker_existing_semantics_preserved'
Check ($resolution.Contains('CourtAgendaBehavior.Current?.Conclude(') -and
    $resolution.Contains('CourtAgendaBehavior.Current?.CapturePolicyVoteAudience(__instance, motionSucceeded);') -and
    $resolution.IndexOf('CourtAgendaBehavior.Current?.CapturePolicyVoteAudience(') -gt
    $resolution.IndexOf('CourtAgendaBehavior.Current?.Conclude(')) 'capture_after_native_vote_conclusion_only'
Check ($capture.Contains('SyncData("BC_CourtPolicyVoteAudience_v1"') -and
    $capture.Contains('SyncData("BC_CourtPolicyVoteAudienceOverflow_v1"') -and
    $court.Contains('SyncCourtPolicyVoteAudience(dataStore);') -and
    $save.Contains('ConstructContainerDefinition(typeof(Dictionary<string, string>))')) 'save_restore_uses_existing_registered_dictionary'
Check ($capture.Contains('TryReadVoteProof(') -and
    $capture.Contains('_courtPolicyVotePublicProvenance.TryGetValue(') -and
    $capture.Contains('agenda.IntegrationId') -and
    $capture.Contains('proof.VoteDay')) 'source_proof_binding_exact_integration_id'
Check ($capture.Contains('TryGetRecordedParticipants(decision') -and
    $capture.Contains('Eligible(voter, realm)') -and
    $capture.Contains('voter.Leader') -and
    $capture.Contains('heroIds.Add(')) 'only_mechanically_recorded_valid_npc_heads'
Check ($capture.Contains('StringComparer.Ordinal') -and
    $capture.Contains('OrderBy(') -and
    $capture.Contains('new UTF8Encoding(false, true)') -and
    $capture.Contains('Convert.FromBase64String(')) 'stable_immutable_utf8_recipient_identity'
Check ($capture.Contains('Guid.TryParseExact(') -and
    $capture.Contains('fields.Length != 6') -and
    $capture.Contains('double.IsNaN(') -and
    $capture.Contains('double.IsInfinity(')) 'strict_version_id_and_time'
Check ($capture.Contains('GetPolicyVoteProvenanceJoin(realm)') -and
    $capture.Contains('joined.IsHealthy') -and
    $capture.Contains('receipt.VoteDay') -and
    $capture.Contains('receipt.SponsorId') -and
    $capture.Contains('receipt.PolicyId')) 'no_audience_without_exact_joined_native_result'
Check ($capture.Contains('missingAudience++') -and
    $capture.Contains('conflicts++') -and
    $capture.Contains('invalid++') -and
    $capture.Contains('_courtPolicyVoteAudienceOverflow')) 'old_saves_unknown_membership_conflict_corruption_fail_closed'
Check ($dto.Contains('IReadOnlyList<string> HeroIds') -and
    $dto.Contains('public bool IsHealthy') -and
    $dto.Contains('Audience = "realm_court";') -and
    $integration.Contains('GetCourtPolicyVoteAudienceJoin(Kingdom realm)') -and
    $integration.Contains('BellumIntegrationBehavior.RequireCampaignThread();')) 'private_readonly_explicit_actor_roster_campaign_thread_only'
Check ($proof.Contains('BC_CourtPolicyVotePublicProvenance_v1') -and
    $terminal.Contains('BC_CourtTerminalEvictionReceipts_v1') -and
    $join.Contains('GetPolicyVoteProvenanceJoin(Kingdom realm)')) 'stage31k_l_proof_receipt_contract_retained'
Check (-not $capture.Contains('AcknowledgeCourt') -and
    -not $capture.Contains('RecordSourceBackedFact(') -and
    -not $capture.Contains('DynamicEventsManager') -and
    -not $capture.Contains('Publish(') -and
    -not $capture.Contains('ApplyChosenOutcome(') -and
    -not $capture.Contains('GetObjective(')) 'no_publication_npc_mutation_or_vote_reexecution'
Check ($capture.Contains('proof.VoteDay != CampaignTime.Now.ToDays') -and
    $capture.Contains('stale_or_foreign_vote_proof') -and
    $capture.IndexOf('proof.VoteDay != CampaignTime.Now.ToDays') -lt
    $capture.IndexOf('TryGetRecordedParticipants(decision')) -and
    $capture.Contains('TryReadVoteProof(agenda.IntegrationId, source, out proof)')) 'never_bind_current_ballot_to_old_resultapplied_agenda_proof'
Write-Host 'STAGE32C_SOURCE_CONTRACT_PASS -- static only; run compiler and named-NPC in-game regression before release.'
