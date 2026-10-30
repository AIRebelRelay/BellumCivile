$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
function Read([string]$path) { Get-Content -Raw -LiteralPath (Join-Path $root $path) }
function Check([bool]$ok, [string]$title) { if (-not $ok) { throw "STAGE31F FAIL $title" }; Write-Host "STAGE31F PASS $title" }
$store = Read 'Behaviors/CourtTerminalEvictionReceipts.cs'
$court = Read 'Behaviors/CourtAgendaBehavior.cs'
$claim = Read 'Behaviors/CourtClaimAgendas.cs'
$rally = Read 'Behaviors/CourtRallyAgendas.cs'
$api = Read 'BellumIntegration.cs'
$record = Read 'CourtAgendaRecord.cs'
$definer = Read 'BellumCivileSaveDefiner.cs'
$test31e = Read 'Tests/Stage31ECourtTerminalRetentionSourceAudit.Tests.ps1'

Check ($store.Contains('private const int MaxCourtTerminalReceipts = 1024;') -and
    $store.Contains('private Dictionary<string, string> _courtTerminalReceipts') -and
    $store.Contains('BC_CourtTerminalEvictionReceipts_v1') -and
    $store.Contains('BC_CourtTerminalEvictionOverflow_v1')) 'bounded_separate_save_keys'
Check ($store.Contains('store.SyncData("BC_CourtTerminalEvictionReceipts_v1", ref _courtTerminalReceipts);') -and
    $store.Contains('store.SyncData("BC_CourtTerminalEvictionOverflow_v1", ref _courtTerminalEvictionOverflow);')) 'receipt_save_reload'
Check ($court.Contains('SyncCourtTerminalEvictionReceipts(dataStore);') -and
    $court.Contains('SyncReactionHistory(dataStore);')) 'native_save_hook_after_existing_history'
Check ($store.Contains('if (agenda.ResultApplied != true || agenda.ObjectiveData?.IsTerminal != true) continue;')) 'final_native_result_only'
Check ($store.Contains('if (_courtTerminalReceipts.ContainsKey(agenda.IntegrationId)) continue;')) 'idempotent_on_same_agenda_id'
Check ($store.Contains('_courtTerminalReceipts.Add(agenda.IntegrationId, PackTerminalReceipt(agenda));')) 'immutable_primitive_payload_once'
Check ($store.Contains('status=record_error') -and
    $store.Contains('status=capture_error')) 'one_bad_record_does_not_stop_other_receipts_or_court_cleanup'
Check ($store.Contains('if (_courtTerminalReceipts.Count >= MaxCourtTerminalReceipts)') -and
    $store.Contains('_courtTerminalEvictionOverflow++;') -and
    $store.Contains('status=overflow') -and
    $store.Contains('status=recorded')) 'overflow_visible_not_silent'
Check ($store.Contains('Convert.ToBase64String(Encoding.UTF8.GetBytes(value ?? string.Empty))') -and
    $store.Contains('CampaignTime.Now.ToDays.ToString("R", CultureInfo.InvariantCulture)')) 'safe_primitive_pack_and_observed_day_not_terminal_claim'
Check (-not $store.Contains('.GetObjective(') -and
    -not $store.Contains('.Finish(') -and
    -not $store.Contains('TryClaimResult(') -and
    -not $store.Contains('.SettleCancellation(') -and
    -not $store.Contains('record.State =') -and
    -not $store.Contains('agenda.State =')) 'archive_does_not_mutate_native_agenda_or_objective'
$recent = [regex]::Match($court, 'CaptureEvictedCourtTerminals\(\s*_recentResults\.Where\(')
Check ($recent.Success -and $recent.Index -lt $court.IndexOf('_recentResults.RemoveAll(')) 'before_recent_history_expiry'
$invalid = [regex]::Match($court, 'CaptureEvictedCourtTerminals\(\s*_agendas\.Where\(a => !ValidRealm\(a\.Realm\)')
Check ($invalid.Success -and $invalid.Index -lt $court.IndexOf('_agendas.RemoveAll(a => !ValidRealm(a.Realm)')) 'before_invalid_realm_eviction'
$term = [regex]::Match($court, 'CaptureEvictedCourtTerminals\(\s*_agendas\.Where\(a => a\.Realm == realm')
Check ($term.Success -and $term.Index -lt $court.IndexOf('_agendas.RemoveAll(a => a.Realm == realm')) 'before_term_rollover_eviction'
Check ($claim.IndexOf('CaptureEvictedCourtTerminals(_claimGrace.Where(a => a.ResultApplied)') -ge 0 -and
    $claim.IndexOf('CaptureEvictedCourtTerminals(_claimGrace.Where(a => a.ResultApplied)') -lt
    $claim.IndexOf('_claimGrace.RemoveAll(a => a.ResultApplied);')) 'before_claim_grace_eviction'
Check ($rally.IndexOf('CaptureEvictedCourtTerminals(_rallies.Where(') -ge 0 -and
    $rally.IndexOf('CaptureEvictedCourtTerminals(_rallies.Where(') -lt
    $rally.IndexOf('_rallies.RemoveAll(a => a.ResultApplied')) 'before_rally_eviction'
Check ($court.Contains('FreezeNpcCouncilTerminalResults(realm);') -and
    $court.IndexOf('FreezeNpcCouncilTerminalResults(realm);') -lt $term.Index) 'council_intent_tombstones_remain_first'
Check ($api.Contains('GetCourtAgendas(Kingdom realm)') -and
    -not $api.Contains('GetCourtTerminalEvictionReceipts(')) 'no_premature_bridge_public_api_or_ack'
Check ($record.Contains('[SaveableField(51)] internal string IntegrationId') -and
    $definer.Contains('ConstructContainerDefinition(typeof(Dictionary<string, string>))') -and
    $test31e.Contains('STAGE31E_DURABLE_TERMINAL_RECEIPTS_NOT_IMPLEMENTED')) 'existing_save_class_and_31e_audit_untouched'
Write-Host 'STAGE31F_SOURCE_REGRESSION_PASS: source only, NOT .NET/save-load/game PASS.'
