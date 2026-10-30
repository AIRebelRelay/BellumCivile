$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
function Read([string]$p) { Get-Content -Raw -LiteralPath (Join-Path $root $p) }
function Check([bool]$okay, [string]$title) {
    if (-not $okay) { throw "STAGE31K FAIL $title" }
    Write-Host "STAGE31K PASS $title"
}
$proof = Read 'Behaviors/CourtPolicyVotePublicProvenance.cs'
$court = Read 'Behaviors/CourtAgendaBehavior.cs'
$patch = Read 'Patches/PolicyVoteResolutionPatch.cs'
$notices = Read 'BellumCivileNotifications.cs'
$dto = Read 'CourtTerminalEvictionInventorySnapshot.cs'
$ledger = Read 'Behaviors/CourtTerminalEvictionReceipts.cs'
$definer = Read 'BellumCivileSaveDefiner.cs'
$old31j = Read 'Tests/Stage31JCourtPublicProvenanceSourceAudit.Tests.ps1'

Check ($patch.Contains('[HarmonyPatch(typeof(KingdomPolicyDecision), "ApplyChosenOutcome")]') -and
    $patch.Contains('Resolved.Add(__instance, new object());') -and
    $patch.Contains('CourtAgendaBehavior.Current?.Conclude(kingdom, policy, __instance.ProposerClan, abolish, motionSucceeded, __state);')) 'actual_source_vote_conclude_caller_unchanged'
Check ($court.Contains('SyncCourtTerminalEvictionReceipts(dataStore);') -and
    $court.Contains('SyncCourtPolicyVotePublicProvenance(dataStore);') -and
    $court.Contains('RestoreIntegrationIds();')) 'isolated_save_hook_compatible_with_receipts'
Check ($court.Contains('RecordCourtPolicyVotePublicProvenance(agenda, policy, abolish, passed, obsoleteMandate);')) 'single_native_policy_conclusion_proof_hook'
Check ($court.IndexOf('BellumCivileNotifications.Show(message, obsoleteMandate') -lt
    $court.IndexOf('RecordCourtPolicyVotePublicProvenance(agenda, policy, abolish, passed, obsoleteMandate);')) 'policy_ui_remains_unmodified_and_proof_after_result'
Check ($proof.Contains('BC_CourtPolicyVotePublicProvenance_v1') -and
    $proof.Contains('BC_CourtPolicyVotePublicProvenanceOverflow_v1') -and
    $proof.Contains('private Dictionary<string, string> _courtPolicyVotePublicProvenance')) 'separate_primitive_save_and_overflow'
Check ($proof.Contains('private const int MaxCourtPolicyVotePublicProvenance = 1024;') -and
    $proof.Contains('if (_courtPolicyVotePublicProvenance.Count >= MaxCourtPolicyVotePublicProvenance)') -and
    $proof.Contains('status=overflow')) 'bounded_and_overflow_visible'
Check ($proof.Contains('if (_courtPolicyVotePublicProvenance.ContainsKey(agenda.IntegrationId)) return;') -and
    $proof.Contains('_courtPolicyVotePublicProvenance.Add(agenda.IntegrationId, value);')) 'stable_integration_id_dedup'
Check ($proof.Contains('if (!ValidRealm(agenda.Realm)') -and
    $proof.Contains('!agenda.IsPolicy') -and
    $proof.Contains('!string.IsNullOrEmpty(agenda.CancellationReason)') -and
    $proof.Contains('!Guid.TryParseExact(agenda.IntegrationId, "N"')) 'exclude_invalid_realm_nonpolicy_cancellation_bad_id'
Check ($proof.Contains('agenda.ResultApplied != true') -and
    $proof.Contains('agenda.State != (passed ? CourtAgendaState.Passed : CourtAgendaState.Defeated)') -and
    $proof.Contains('objective.State != (passed ? CourtObjectiveState.Succeeded : CourtObjectiveState.Failed)') -and
    $proof.Contains('objective.Credit != (passed ? CourtObjectiveCredit.Sponsor : CourtObjectiveCredit.None)')) 'terminal_outcome_and_credit_verified'
Check ($proof.Contains('string.Equals(objective.Kind, "policy", StringComparison.Ordinal)') -and
    $proof.Contains('string.Equals(objective.TargetId, policy.StringId, StringComparison.Ordinal)') -and
    $proof.Contains('string.Equals(objective.ActionId, abolish ? "repeal" : "enact", StringComparison.Ordinal)')) 'exact_policy_and_action'
Check ($proof.Contains('"v1"') -and
    $proof.Contains('"realm_court"') -and
    $proof.Contains('"court_policy_conclude"') -and
    $proof.Contains('obsoleteMandate ? "obsolete_mandate" : "current_mandate"') -and
    $proof.Contains('CampaignTime.Now.ToDays.ToString("R", CultureInfo.InvariantCulture)')) 'source_authored_scoped_proof_not_public_global'
Check ($proof.Contains('Convert.ToBase64String(Encoding.UTF8.GetBytes(value ?? string.Empty))') -and
    $proof.Contains('BC_COURT_PUBLIC_PROVENANCE status=recorded') -and
    $proof.Contains('relay_emitted=false')) 'safe_encoded_source_provenance_no_delivery_claim'
Check (-not $proof.Contains('RecordSourceBackedFact(') -and
    -not $proof.Contains('TryPersistVerifiedPublicCourtFact(') -and
    -not $proof.Contains('ConsumeAcknowledged(') -and
    -not $proof.Contains('_courtPolicyVotePublicProvenance.Remove(') -and
    -not $proof.Contains('GetObjective(') -and
    -not $proof.Contains('.Finish(')) 'no_bridge_ack_objective_mutation_or_false_delivery'
Check ($notices.Contains('BellumNotificationScope scope = BellumCivileOptions.BellumCivileNotifications;') -and
    $notices.Contains('if (isPersonal)') -and
    $dto.Contains('public bool IsHealthy => SourceAvailable && OverflowCount == 0 && InvalidCount == 0;') -and
    $ledger.Contains('BC_CourtTerminalEvictionReceipts_v1') -and
    $definer.Contains('ConstructContainerDefinition(typeof(Dictionary<string, string>))')) 'legacy_ui_archive_and_save_contracts_retained'
Check ($old31j.Contains('STAGE31J_PUBLIC_PROVENANCE_SOURCE_AUDIT_PASS')) 'previous_31j_regression_preserved'
Write-Host 'STAGE31K_SOURCE_CONTRACT_PASS — source only; no PowerShell runtime, build, save/load or game proof.'
