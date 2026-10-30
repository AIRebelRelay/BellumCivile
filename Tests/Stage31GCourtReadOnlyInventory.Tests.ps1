$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
function Read([string]$p) { Get-Content -LiteralPath (Join-Path $root $p) -Raw }
function Check([bool]$okay,[string]$label) {
    if (-not $okay) { throw "STAGE31G FAIL $label" }
    Write-Host "STAGE31G PASS $label"
}
$api = Read 'BellumIntegration.cs'
$reader = Read 'Behaviors/CourtTerminalEvictionReceipts.cs'
$dto = Read 'CourtTerminalEvictionInventorySnapshot.cs'
$save = Read 'Behaviors/CourtAgendaBehavior.cs'
$definer = Read 'BellumCivileSaveDefiner.cs'
$old = Read 'Tests/Stage31FCourtEvictionReceiptSourceContract.Tests.ps1'
Check ($dto.Contains('public sealed class CourtTerminalEvictionInventorySnapshot') -and
    $dto.Contains('public sealed class CourtTerminalEvictionReceiptSnapshot')) 'read_only_dtos_exist'
foreach ($name in @('RealmId','SourceAvailable','Pending','TotalStored','InvalidCount','OverflowCount')) {
    Check ($dto.Contains("public ") -and $dto.Contains("$name { get; }")) "inventory_field_$name"
}
Check ($dto.Contains('IReadOnlyList<CourtTerminalEvictionReceiptSnapshot>') -and
    $dto.Contains('public string EncodedPayload { get; }')) 'opaque_copy_not_native_record'
Check ($api.Contains('GetCourtTerminalEvictionInventory(Kingdom realm)') -and
    $api.Contains('BellumIntegrationBehavior.RequireCampaignThread();') -and
    $api.Contains('CourtAgendaBehavior.Current?.GetTerminalEvictionInventory(realm)')) 'campaign_thread_only_export'
Check ($reader.Contains('internal CourtTerminalEvictionInventorySnapshot GetTerminalEvictionInventory(Kingdom realm)') -and
    $reader.Contains('new CourtTerminalEvictionReceiptSnapshot(') -and
    $reader.Contains('new CourtTerminalEvictionInventorySnapshot(')) 'read_only_native_projection'
Check ($reader.Contains('private static bool TryReadCourtTerminalPayload(') -and
    $reader.Contains('fields.Length != 13') -and
    $reader.Contains('Convert.FromBase64String(fields[i])') -and
    $reader.Contains('Guid.TryParseExact(id, "N"')) 'fail_closed_exact_v1_identity_and_base64'
Check ($reader.Contains('Enum.TryParse(') -and
    $reader.Contains('Enum.IsDefined(') -and
    $reader.Contains('CourtObjectiveState.Selected') -and
    $reader.Contains('CourtObjectiveState.Active')) 'terminal_enum_validation'
Check ($reader.Contains('double.TryParse(fields[12]') -and
    $reader.Contains('double.IsNaN(day)') -and
    $reader.Contains('double.IsInfinity(day)')) 'finite_observed_day_validation'
Check ($reader.Contains('StringComparison.Ordinal') -and
    $reader.Contains('string.Equals(payloadRealm, realm.StringId')) 'exact_realm_isolation'
Check ($reader.Contains('_courtTerminalEvictionOverflow') -and
    $reader.Contains('invalid++') -and
    $reader.Contains('_courtTerminalReceipts.Count')) 'overflow_and_corruption_exposed'
Check ($reader.Contains('pending.AsReadOnly()') -and
    $reader.Contains('OrderBy(pair => pair.Key, StringComparer.Ordinal)')) 'stable_defensive_order'
Check ($dto.Contains('public bool IsHealthy => SourceAvailable && OverflowCount == 0 && InvalidCount == 0;')) 'health_never_false_positive'
Check (-not $api.Contains('AcknowledgeCourtTerminal') -and
    -not $reader.Contains('AcknowledgeCourtTerminal') -and
    -not $api.Contains('ConsumeCourtTerminal') -and
    -not $reader.Contains('_courtTerminalReceipts.Remove(') -and
    -not $reader.Contains('_courtTerminalReceipts.Clear(')) 'no_unsafe_ack_or_read_side_removal'
Check ($reader.Contains('store.SyncData("BC_CourtTerminalEvictionReceipts_v1", ref _courtTerminalReceipts);') -and
    $reader.Contains('store.SyncData("BC_CourtTerminalEvictionOverflow_v1", ref _courtTerminalEvictionOverflow);') -and
    $save.Contains('SyncCourtTerminalEvictionReceipts(dataStore);') -and
    $definer.Contains('ConstructContainerDefinition(typeof(Dictionary<string, string>))')) 'save_compatibility_unchanged'
Check ($old.Contains('STAGE31F_SOURCE_REGRESSION_PASS')) 'old_stage_contract_remains'
Write-Host 'STAGE31G_SOURCE_CONTRACT_PASS — not runtime/save-load/Bridge delivery PASS.'
