$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
function Read([string]$name) { Get-Content -LiteralPath (Join-Path $root $name) -Raw }
function Require([bool]$condition, [string]$label) {
    if (-not $condition) { throw "STAGE31E_SOURCE_AUDIT FAIL $label" }
    Write-Host "STAGE31E_SOURCE_AUDIT PASS $label"
}
$api = Read 'BellumIntegration.cs'
$snapshot = Read 'IntegrationSnapshots.cs'
$integration = Read 'Behaviors/CourtIntegrationSnapshots.cs'
$behavior = Read 'Behaviors/CourtAgendaBehavior.cs'
$reaction = Read 'Behaviors/CourtReactionHistory.cs'
$council = Read 'Behaviors/CourtNpcCouncilAppointments.cs'
$claim = Read 'Behaviors/CourtClaimAgendas.cs'
$rally = Read 'Behaviors/CourtRallyAgendas.cs'
$objective = Read 'CourtObjectiveRecord.cs'
$record = Read 'CourtAgendaRecord.cs'
$save = Read 'BellumCivileSaveDefiner.cs'

# These are CURRENT SOURCE observations, not assertions that lossless transport exists.
Require ($api.Contains('RequireCampaignThread();') -and
    $api.Contains('GetCourtAgendas(Kingdom realm)')) 'public_api_requires_campaign_thread'
Require ($integration.Contains('_agendas.Concat(_recentResults).Concat(_rallies).Concat(_claimGrace)') -and
    $integration.Contains('GetIntegrationSnapshots(Kingdom realm)')) 'current_snapshot_four_list_union'
Require ($record.Contains('[SaveableField(51)] internal string IntegrationId') -and
    $snapshot.Contains('Id = record.IntegrationId;')) 'native_stable_agenda_id_preserved'
Require ($snapshot.Contains('ObjectiveResultReason = objective?.ResultReason;') -and
    $snapshot.Contains('ObjectiveCredit = objective == null ? (CourtObjectiveCredit?)null : objective.Credit;') -and
    $snapshot.Contains('ObjectiveTerminal = objective?.IsTerminal == true;')) 'stage31d_readonly_outcome_fields_preserved'

Require ($behavior.Contains('_agendas.RemoveAll(a => a.Realm == realm && !a.IsFiled && !a.IsUnopened && !a.IsOngoingObjective)')) 'openterm_prunes_closed_agendas'
Require ($behavior.Contains('_agendas.RemoveAll(a => !ValidRealm(a.Realm) && !a.IsFiled && !a.IsUnopened)')) 'daily_invalid_realm_prunes'
Require ($reaction.Contains('private void RecordResultHistory(CourtAgendaRecord agenda, float shock)') -and
    $reaction.Contains('if (agenda.Faction == null || shock == 0 || _recentResults.Contains(agenda)) return;') -and
    $behavior.Contains('!a.ResultVisibleUntil.IsFuture || !ReactionApproval(a).HasValue')) 'reaction_history_not_full_terminal_journal'
Require ($claim.Contains('_agendas.Remove(agenda);') -and
    $claim.Contains('_claimGrace.RemoveAll(a => a.ResultApplied);')) 'claim_grace_has_separate_eviction'
Require ($rally.Contains('_rallies.RemoveAll(a => a.ResultApplied && CampaignTime.Now.ToDays>a.ObjectiveData.DeadlineDay+1)')) 'rally_has_separate_eviction'

# Current precedent is an NPC council intent tombstone; DO NOT broaden its shared semantics.
Require ($behavior.Contains('FreezeNpcCouncilTerminalResults(realm);') -and
    $behavior.IndexOf('FreezeNpcCouncilTerminalResults(realm);') -lt
    $behavior.IndexOf('_agendas.RemoveAll(a => a.Realm == realm')) 'council_freeze_before_term_prune'
Require ($council.Contains('private Dictionary<string, string> _npcCouncilClosures') -and
    $council.Contains('BC_CourtNpcCouncilClosures_v1') -and
    $council.Contains('_npcCouncilClosures[entry.Key] = outcome;')) 'saved_council_terminal_precedent_is_narrow'
Require ($save.Contains('ConstructContainerDefinition(typeof(Dictionary<string, string>))')) 'existing_primitive_save_container'
Require ($objective.Contains('CourtObjectiveState { Selected, Active, Succeeded, Failed, Expired, Cancelled }') -and
    $objective.Contains('CourtObjectiveCredit { None, Sponsor, FulfilledElsewhere }')) 'outcome_and_actor_credit_are_distinct'

Write-Host 'STAGE31E_RETENTION_SOURCE_AUDIT_PASS: observed existing behavior only.'
Write-Host 'STAGE31E_DURABLE_TERMINAL_RECEIPTS_NOT_IMPLEMENTED: no lossless Bridge/Relay/NPC claim.'
