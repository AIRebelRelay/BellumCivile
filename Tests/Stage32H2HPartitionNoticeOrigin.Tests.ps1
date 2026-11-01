$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
function Read-Source([string]$relative) {
    $path = Join-Path $root $relative
    if (-not (Test-Path -LiteralPath $path)) { throw "STAGE32H2H RED missing $relative" }
    return Get-Content -LiteralPath $path -Raw
}
function Check([bool]$condition, [string]$name) {
    if (-not $condition) { throw "STAGE32H2H_FAIL $name" }
    Write-Host "STAGE32H2H_PASS $name"
}

# This is a source/contract regression, not a substitute for Native compilation or game testing.
$origin = Read-Source 'PartitionNoticeOrigin.cs'
$api = Read-Source 'BellumIntegrationPartitions.cs'
$ordinary = Read-Source 'Behaviors/PartitionSuccessionBehavior.cs'
$crown = Read-Source 'Behaviors/CrownPartitionCompletion.cs'
$cross = Read-Source 'Behaviors/PartitionCrossClanInheritance.cs'
$mixed = Read-Source 'Behaviors/PartitionMixedEstateCompletion.cs'
$notifications = Read-Source 'BellumCivileNotifications.cs'
$completion = Read-Source 'Behaviors/IntegrationPartitions.cs'
$save = Read-Source 'BellumCivileSaveDefiner.cs'

Check ($origin.Contains('public sealed class PartitionNoticeOriginSnapshot') -and
    $origin.Contains('public string EpisodeId') -and
    $origin.Contains('public string DeceasedId') -and
    $origin.Contains('public string OriginHouseId') -and
    $origin.Contains('public string HeirId') -and
    $origin.Contains('public string RecipientHouseId') -and
    $origin.Contains('public string Executor') -and
    $origin.Contains('public string NoticeKey')) 'exact_immutable_notice_identity_fields'

Check ($origin.Contains('"partition|" + deceasedId + "|" + originHouseId') -and
    $completion.Contains('"partition|" + deceased.StringId + "|" + source.StringId')) 'same_episode_key_as_native_completion'

Check ($origin.Contains('[ThreadStatic]') -and
    $origin.Contains('ReferenceEquals(current.Campaign, Campaign.Current)') -and
    $api.Contains('BellumIntegrationBehavior.RequireCampaignThread();') -and
    $api.Contains('GetCurrentPartitionNoticeOrigin()')) 'read_only_campaign_thread_scoped_access'

Check ($origin.Contains('IDisposable') -and
    $origin.Contains('Dispose()') -and
    $origin.Contains('new Restore(previous)') -and
    $origin.Contains('_active = _previous;')) 'scope_restored_after_exception_or_nested_call'

Check ($ordinary.Contains('record.DeadLeaderId, "ordinary", "heir:" + heir.StringId') -and
    $ordinary.Contains('ShowSovereignPartitionMessage(') -and
    $ordinary.Contains('ShowPartitionMessage(')) 'ordinary_both_success_notices_tagged_by_deceased'

Check ($crown.Contains('pending.DeadLeaderId, "crown", "heir:" + share.Heir.StringId') -and
    $crown.Contains('batch.TryAnnounce("heir:" + share.Heir.StringId')) 'crown_notice_exact_existing_heir_marker'

Check ($cross.Contains('PartitionNoticeOriginScope.Begin(') -and
    $cross.Contains('record.Deceased?.StringId') -and
    $cross.Contains('ShowEstateInheritanceMessage(record, share, titles);')) 'cross_clan_share_with_its_native_estate'

# EstateInheritancePolicy.BuildProjection may produce separate sovereign and
# ordinary shares for the SAME heir / recipient. A name-pair key collides.
$projection = Read-Source 'EstateInheritancePolicy.cs'
Check (($projection.Split('record.Shares.Add(share);').Length -ge 3) -and
    $cross.Contains('record.Shares.IndexOf(share)') -and
    $cross.Contains('shareIndex < 0 ? null : "estate-share:"') -and
    $cross.Contains('shareIndex.ToString(System.Globalization.CultureInfo.InvariantCulture)') -and
    (-not $cross.Contains('"estate-share:" + heir?.StringId'))) 'cross_clan_multiple_shares_same_heir_distinct_saved_index'


Check ($mixed.Contains('pending.DeadLeaderId, "mixed", "mixed-share:" + i') -and
    $mixed.Contains('ShowEstateInheritanceMessage(estate, share, titles, "mixed", "mixed-share:" + i)') -and
    $mixed.Contains('batch.TryAnnounce("mixed-share:" + i')) 'mixed_share_exact_existing_index_marker'

Check ($ordinary.Contains('PartitionNoticeOriginScope.Begin(') -and
    $ordinary.Contains('BellumCivileNotifications.Show(')) 'origin_present_only_during_native_show'

Check (-not $origin.Contains('SaveableField') -and
    -not $origin.Contains('SyncData(') -and
    -not $origin.Contains('HarmonyLib') -and
    -not $origin.Contains('harmony.Patch(') -and
    -not $origin.Contains('RecordSourceBackedFact(') -and
    -not $origin.Contains('RecordNotificationFact(')) 'no_saved_fields_harmony_or_event_transport'

Check ($notifications.Contains('InformationManager.DisplayMessage(new InformationMessage(text, color));') -and
    $notifications.Contains('if (!ShouldShow(') -and
    $completion.Contains('branches.Select(r => r.House).Distinct().Count() < 2') -and
    $save.Contains('class BellumCivileSaveDefiner')) 'ui_completion_and_save_ownership_preserved'

Check (-not $origin.Contains('Failed') -and -not $origin.Contains('Completed =') -and
    -not $origin.Contains('DynamicEvents')) 'no_invented_terminal_outcome_or_global_event'

Write-Host 'STAGE32H2H_SOURCE_CONTRACT_PASS -- STATIC ONLY; compile, save/rollback, real notification and Bridge postfix E2E PENDING'
