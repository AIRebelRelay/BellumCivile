# P0-15: Observe native KingdomDestroyed registration/delivery; NO event routing changes.
# RED-first contract. This is not a fix for double AI Influence requests.
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
function Read([string]$file) { Get-Content -Raw -LiteralPath (Join-Path $root $file) }
function Check([bool]$ok, [string]$name) {
    if (-not $ok) { throw "P015_FAIL $name" }
    Write-Host "P015_PASS $name"
}
$source = Read 'Behaviors/ClientKingdomBehavior.cs'
$startup = Read 'SubModule.cs'
$regStart = $source.IndexOf('public override void RegisterEvents()')
$regEnd = $source.IndexOf('public override void SyncData(', $regStart)
$cbStart = $source.IndexOf('private void OnKingdomDestroyed(Kingdom destroyedKingdom)')
$cbEnd = $source.IndexOf('private void OnWarDeclared(', $cbStart)
Check ($regStart -ge 0 -and $regEnd -gt $regStart -and $cbStart -ge 0 -and $cbEnd -gt $cbStart) 'exact_native_listener_and_callback_methods_exist'
$registration = $source.Substring($regStart, $regEnd - $regStart)
$callback = $source.Substring($cbStart, $cbEnd - $cbStart)
$listener = 'CampaignEvents.KingdomDestroyedEvent.AddNonSerializedListener(this, OnKingdomDestroyed);'
Check ($startup.Contains('campaignStarter.AddBehavior(new ClientKingdomBehavior());')) 'native_campaign_behavior_still_registered'
Check (([regex]::Matches($registration, [regex]::Escape($listener))).Count -eq 1) 'exactly_one_existing_native_listener_unchanged'
Check ($source.Contains('private int _kdTraceRegistrationCount;') -and $source.Contains('private int _kdTraceCallbackCount;')) 'diagnostic_counters_per_behavior_instance_only'
Check ($registration.Contains('KD_TRACE_REGISTER') -and $registration.Contains('Interlocked.Increment(ref _kdTraceRegistrationCount)') -and
    $registration.Contains('RuntimeHelpers.GetHashCode(this)')) 'registration_logs_instance_and_sequence'
Check ($registration.IndexOf($listener) -lt $registration.IndexOf('KD_TRACE_REGISTER')) 'registration_log_after_existing_subscription'
Check ($callback.Contains('KD_TRACE_CALLBACK') -and $callback.Contains('Interlocked.Increment(ref _kdTraceCallbackCount)') -and
    $callback.Contains('RuntimeHelpers.GetHashCode(this)') -and $callback.Contains('destroyedKingdom?.StringId')) 'callback_logs_instance_sequence_and_realm'
Check ($callback.IndexOf('KD_TRACE_CALLBACK') -lt $callback.IndexOf('if (destroyedKingdom == null)')) 'callback_trace_includes_null_event_before_original_guard'
Check ($registration.Contains('DateTime.UtcNow:O') -and $callback.Contains('DateTime.UtcNow:O') -and
    $registration.Contains('Campaign.Current?.UniqueGameId') -and $callback.Contains('Campaign.Current?.UniqueGameId')) 'millisecond_utc_and_campaign_correlation'
Check ($registration.Contains('CampaignEvents.WarDeclared.AddNonSerializedListener(this, OnWarDeclared);') -and
    $registration.Contains('CampaignEvents.MakePeace.AddNonSerializedListener(this, OnMakePeace);') -and
    $registration.Contains('CampaignEvents.DailyTickEvent.AddNonSerializedListener(this, OnDailyTick);')) 'neighbor_war_peace_daily_listeners_preserved'
Check ($callback.Contains('EnsureCollectionsInitialized();') -and
    $callback.Contains('_clients.Remove(record);') -and
    $callback.Contains('EndProtectedAgreements(client, suzerain, "clientage participant kingdom destroyed");') -and
    $callback.Contains('ShowIndependenceAfterSuzerainCollapse(')) 'original_clientage_destruction_cleanup_preserved'
Check ($registration -notmatch 'HarmonyMethod|\.Patch\(|RemoveListener|RemoveNonSerializedListener' -and
    $callback -notmatch 'HarmonyMethod|\.Patch\(|RemoveListener|RemoveNonSerializedListener') 'no_harmony_or_event_suppression'
Write-Host 'P015_SOURCE_PASS; this proves a diagnostic contract, NOT gameplay behavior or duplicate root cause.'
