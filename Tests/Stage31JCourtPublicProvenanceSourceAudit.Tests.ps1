$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
function Read([string]$path) { Get-Content -LiteralPath (Join-Path $root $path) -Raw }
function Check([bool]$yes, [string]$label) {
    if (-not $yes) { throw "STAGE31J_SOURCE_AUDIT FAIL $label" }
    Write-Host "STAGE31J_SOURCE_AUDIT PASS $label"
}

$notices = Read 'BellumCivileNotifications.cs'
$scope = Read 'BellumNotificationScope.cs'
$court = Read 'Behaviors/CourtAgendaBehavior.cs'
$policy = Read 'CourtPolicyObjectiveBridge.cs'
$council = Read 'Behaviors/CourtCouncilAgendas.cs'
$activity = Read 'Behaviors/CourtActivityAgendas.cs'
$report = Read 'CourtSessionEventReports.cs'
$objective = Read 'CourtObjectiveRecord.cs'
$record = Read 'CourtAgendaRecord.cs'
$archive = Read 'Behaviors/CourtTerminalEvictionReceipts.cs'
$api = Read 'BellumIntegration.cs'
$dto = Read 'CourtTerminalEvictionInventorySnapshot.cs'

# Player UI scope is NOT proof of world-public narrative.
Check ($notices.Contains('if (isPersonal)') -and
    $notices.Contains('BellumNotificationScope scope = BellumCivileOptions.BellumCivileNotifications;') -and
    $notices.Contains('if (scope == BellumNotificationScope.Disabled)') -and
    $notices.Contains('if (scope == BellumNotificationScope.Global)') -and
    $notices.Contains('Clan playerClan = Clan.PlayerClan;') -and
    $notices.Contains('InformationManager.DisplayMessage')) 'native_notification_scope_is_player_ui_only'
Check ($scope.Contains('Disabled = 0') -and $scope.Contains('KingdomOnly = 1') -and
    $scope.Contains('Global = 2')) 'UI_options_are_not_event_audience_fields'
Check ($court.Contains('public void Conclude(Kingdom realm, PolicyObject policy, Clan proposer, bool abolish, bool passed') -and
    $court.Contains('agenda.ResultApplied = true;') -and
    $court.Contains('agenda.State = passed ? CourtAgendaState.Passed : CourtAgendaState.Defeated;') -and
    $court.Contains('agenda.GetObjective();') -and
    $court.Contains('BellumCivileNotifications.Show(message, obsoleteMandate')) 'policy_conclusion_has_exact_vote_but_UI_is_separate'
Check ($policy.Contains('case CourtAgendaState.Passed:') -and
    $policy.Contains('objective.Credit = CourtObjectiveCredit.Sponsor;') -and
    $policy.Contains('case CourtAgendaState.FulfilledElsewhere:') -and
    $policy.Contains('objective.Credit = CourtObjectiveCredit.FulfilledElsewhere;')) 'policy_outcome_credit_distinguishes_sponsor'
Check ($council.Contains('council_appointment_unverified') -and
    $council.Contains('decision.AppliedCandidate == agenda.PreferredCouncilCandidate') -and
    $council.Contains('verified_council_appointment')) 'council_preferred_is_not_actual_winner'
Check ($activity.Contains('activity_partial_execution') -and
    $activity.Contains('CourtSessionEvents.Report(plan, agenda.Faction, agenda.Realm);') -and
    $activity.Contains('bool changed = plan.Targets.Any(')) 'activity_finality_is_partial_target_scoped'
Check ($report.Contains('internal static class CourtSessionEventReports') -and
    $report.Contains('internal static TextObject Narrative(string id)') -and
    -not $report.Contains('public enum CourtEventAudience')) 'session_event_narratives_are_not_public_provenance'
Check ($record.Contains('[SaveableField(51)] internal string IntegrationId') -and
    $objective.Contains('public enum CourtObjectiveCredit { None, Sponsor, FulfilledElsewhere }')) 'stable_source_id_and_credit_retained'
Check ($archive.Contains('private const int MaxCourtTerminalReceipts = 1024;') -and
    $archive.Contains('if (agenda.ResultApplied != true || agenda.ObjectiveData?.IsTerminal != true) continue;') -and
    $archive.Contains('"v1",') -and
    $archive.Contains('EncodeReceiptField(agenda.CancellationReason)')) 'archive_captures_results_but_no_audience'
Check ($api.Contains('GetCourtTerminalEvictionInventory(Kingdom realm)') -and
    $dto.Contains('public string EncodedPayload { get; }') -and
    $dto.Contains('public bool IsHealthy => SourceAvailable && OverflowCount == 0 && InvalidCount == 0;')) 'read_api_is_diagnostic_not_world_event'
Check (-not $dto.Contains('Audience { get; }') -and
    -not $dto.Contains('PublicAuthorized { get; }') -and
    -not $archive.Contains('public_authorized=true') -and
    -not $api.Contains('PublishCourtTerminal')) 'public_provenance_is_not_yet_implemented'
Check ($court.Contains('primaryKingdom: realm') -and
    (Read 'Behaviors/CourtAgendaPlayerFlow.cs').Contains('isPersonal: true')) 'neighboring_personal_toasts_remain_separate'
Write-Host 'STAGE31J_PUBLIC_PROVENANCE_SOURCE_AUDIT_PASS: source observations only; production unchanged.'
Write-Host 'STAGE31J_PUBLIC_PROVENANCE_NOT_IMPLEMENTED: cannot authorize Bridge/Relay publication from terminal state.'
