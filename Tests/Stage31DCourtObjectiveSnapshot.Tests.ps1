$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
function Read([string]$relative) { Get-Content -LiteralPath (Join-Path $root $relative) -Raw }
function Check([bool]$ok, [string]$name) {
    if (-not $ok) { throw "STAGE31D FAIL $name" }
    Write-Host "STAGE31D PASS $name"
}
$snapshot = Read 'IntegrationSnapshots.cs'
$record = Read 'CourtAgendaRecord.cs'
$objective = Read 'CourtObjectiveRecord.cs'
$bridge = Read 'CourtPolicyObjectiveBridge.cs'
$api = Read 'Behaviors/CourtIntegrationSnapshots.cs'
$behavior = Read 'Behaviors/CourtAgendaBehavior.cs'
$executive = Read 'Behaviors/CourtExecutiveAgendas.cs'
$council = Read 'Behaviors/CourtCouncilAgendas.cs'
$activity = Read 'Behaviors/CourtActivityAgendas.cs'
$history = Read 'Behaviors/CourtReactionHistory.cs'

$start = $snapshot.IndexOf('public sealed class CourtAgendaSnapshot')
$ctorStart = $snapshot.IndexOf('internal CourtAgendaSnapshot(CourtAgendaRecord record)', $start)
Check ($start -ge 0 -and $ctorStart -gt $start) 'existing_court_snapshot_target_only'
$court = $snapshot.Substring($start)
$ctor = $snapshot.Substring($ctorStart)

# Exact original identity and time semantics survive; no editor/writer path.
foreach ($existing in @(
    'public string Id { get; }', 'public Kingdom Realm { get; }',
    'public FactionType? Faction { get; }', 'public Clan Sponsor { get; }',
    'public string Kind { get; }', 'public string TargetId { get; }',
    'public string ActionId { get; }', 'public bool Abolish { get; }',
    'public CourtAgendaState State { get; }', 'public double SessionDay { get; }',
    'public double ResultVisibleUntilDay { get; }',
    'public bool ResultApplied { get; }'
)) { Check ($court.Contains($existing)) "original_field:$existing" }

foreach ($added in @(
    'public CourtObjectiveState? ObjectiveState { get; }',
    'public CourtObjectiveCredit? ObjectiveCredit { get; }',
    'public string ObjectiveResultReason { get; }',
    'public bool ObjectiveTerminal { get; }',
    'public string CancellationReason { get; }'
)) { Check ($court.Contains($added)) "new_outcome_field:$added" }

Check ($ctor.Contains('var objective = record.ObjectiveData;') -and
    $ctor.Contains('ObjectiveState = objective == null ? (CourtObjectiveState?)null : objective.State;') -and
    $ctor.Contains('ObjectiveCredit = objective == null ? (CourtObjectiveCredit?)null : objective.Credit;') -and
    $ctor.Contains('ObjectiveResultReason = objective?.ResultReason;') -and
    $ctor.Contains('ObjectiveTerminal = objective?.IsTerminal == true;') -and
    $ctor.Contains('CancellationReason = record.CancellationReason;')) 'null_safe_direct_read_only_objective_projection'
Check (-not $ctor.Contains('record.GetObjective(') -and
    -not $ctor.Contains('.Finish(') -and
    -not $ctor.Contains('Guid.NewGuid(') -and
    -not $ctor.Contains('TryClaimResult(') -and
    -not $ctor.Contains('record.State =') -and
    -not $ctor.Contains('record.ResultApplied =')) 'snapshot_constructor_no_native_mutation'
Check ($snapshot.Contains('public sealed class HostageStatusSnapshot') -and
    $snapshot.Contains('Protected = custody && pact.Protects(slot.Hero);')) 'hostage_snapshot_unchanged'
Check ($record.Contains('[SaveableField(51)] internal string IntegrationId') -and
    $record.Contains('public int SettleCancellation(string reason)')) 'persisted_native_agenda_identity_and_cancel_untouched'
Check ($objective.Contains('public enum CourtObjectiveState { Selected, Active, Succeeded, Failed, Expired, Cancelled }') -and
    $objective.Contains('public enum CourtObjectiveCredit { None, Sponsor, FulfilledElsewhere }') -and
    $objective.Contains('public bool IsTerminal =>') -and
    $objective.Contains('public string ResultReason;')) 'native_objective_semantics_preserved'
Check ($api.Contains('_agendas.Concat(_recentResults).Concat(_rallies).Concat(_claimGrace)') -and
    $api.Contains('GetIntegrationSnapshots(Kingdom realm)') -and
    $api.Contains('RestoreIntegrationIds()')) 'integration_api_unchanged'
Check ($behavior.Contains('_agendas.RemoveAll(a => a.Realm == realm && !a.IsFiled && !a.IsUnopened && !a.IsOngoingObjective)') -and
    $history.Contains('ResultVisibleUntil.IsFuture')) 'limited_retention_not_hidden'
Check ($bridge.Contains('objective.Credit = CourtObjectiveCredit.FulfilledElsewhere;') -and
    $executive.Contains('FinishExecutive(CourtAgendaRecord agenda, CourtAgendaState state, string reason)') -and
    $council.Contains('verified_council_appointment') -and
    $activity.Contains('activity_partial_execution')) 'adjacent_policy_executive_council_activity_provenance'
Write-Host 'STAGE31D_SOURCE_CONTRACT_PASS (source only; build/runtime/game evidence required before release)'
