#Requires -Version 7.2
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$temp = Join-Path ([IO.Path]::GetTempPath()) ('realm-preparation-' + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $temp | Out-Null
try {
    $recovery = Get-Content -Raw (Join-Path $root 'Behaviors/RestoredRealmRecovery.cs')
    $start = $recovery.IndexOf('record.Ready = true;')
    $publicationStart = $recovery.IndexOf('if (!record.CreatedNotified)')
    $end = $recovery.IndexOf('return realm;', $start)
    if ($publicationStart -lt 0 -or $start -le $publicationStart -or $end -le $start) { throw 'Missing production completion boundary' }
    $earlyStart = $recovery.IndexOf('if (record.Ready) return record.Successor')
    $earlyEnd = $recovery.IndexOf(';', $earlyStart)
    if ($earlyStart -lt 0 -or $earlyEnd -le $earlyStart) { throw 'Missing production Ready early return' }
    $method = 'using BellumCivile; using TaleWorlds.CampaignSystem; namespace BellumCivile.Behaviors { public partial class CivilWarResolutionBehavior { public Kingdom Complete(RestoredRealmCreationRecord record) { var realm = record.Successor; var challenge = record.Challenge; ' + $recovery.Substring($earlyStart, $earlyEnd-$earlyStart+1) + $recovery.Substring($publicationStart, $end-$publicationStart) + 'return realm; } } }'
    Set-Content -LiteralPath (Join-Path $temp 'Completion.cs') -Value $method
    $integration = Get-Content -Raw (Join-Path $root 'Behaviors/BellumIntegrationBehavior.cs')
    $guardStart = $integration.IndexOf('internal static BellumIntegrationBehavior Current')
    $guardEnd = $integration.IndexOf('public override void RegisterEvents()', $guardStart)
    if ($guardStart -lt 0 -or $guardEnd -le $guardStart) { throw 'Missing actual campaign-thread guard boundary' }
    $guard = 'using System; using System.Threading; using TaleWorlds.CampaignSystem; namespace BellumCivile.Behaviors { public sealed partial class BellumIntegrationBehavior { ' + $integration.Substring($guardStart,$guardEnd-$guardStart) + ' } }'
    Set-Content -LiteralPath (Join-Path $temp 'Guard.cs') -Value $guard
    foreach ($name in @('Fixtures','Scenarios')) {
        Copy-Item -LiteralPath (Join-Path $root "Tests/RealmPreparationHarness/$name.cs.txt") -Destination (Join-Path $temp "$name.cs")
    }
    $paths = @('RestoredRealmCreationRecord.cs','RealmPreparationReceipt.cs','Behaviors/RestoredRealmPreparationState.cs','BellumIntegrationRealmPreparations.cs') | ForEach-Object { Join-Path $root $_ }
    $paths += @(Get-ChildItem $temp -Filter *.cs | ForEach-Object FullName)
    Add-Type -Path $paths -CompilerOptions '/langversion:7.3'
    [RealmPreparationScenarios]::Run()
    # Full recovery remains a separate native harness. These are source boundary checks only.
    if ($recovery.IndexOf('RealmPreparationReceiptCapture.TryStamp(record);') -lt $recovery.IndexOf('record.Ready = true;')) { throw 'Stamp must follow Ready' }
    if ($recovery.IndexOf('CampaignEventDispatcher.Instance.OnKingdomCreated(realm);') -ge $start) { throw 'Callback order changed' }
    Write-Output 'SOURCE_BOUNDARY_PASS callback before terminal slice; native_recovery=NOT_RUN'
} finally { Remove-Item -LiteralPath $temp -Recurse -Force }
