#Requires -Version 7.2
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$temp = Join-Path ([IO.Path]::GetTempPath()) ('pressure-state-' + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $temp | Out-Null
try {
    $source = Get-Content -Raw (Join-Path $root 'Behaviors/WarPeaceRevampBehavior.cs')
    $start = $source.IndexOf('internal PoliticalPressureStateSnapshot GetExistingPoliticalPressureStateSnapshot(Clan clan, float day)')
    $end = $source.IndexOf('internal static bool HasInternalConflict(Kingdom realm)', $start)
    if ($start -lt 0 -or $end -le $start) { throw 'Actual forwarding/getter extraction boundary changed' }
    $fixture = Get-Content -Raw (Join-Path $root 'Tests/ExistingPoliticalPressureHarness/Fixtures.cs.txt')
    if ([regex]::Matches($fixture, '// INSERT_ACTUAL_METHODS').Count -ne 1) { throw 'Fixture insertion boundary changed' }
    Set-Content -LiteralPath (Join-Path $temp 'Fixtures.cs') -Value $fixture.Replace('// INSERT_ACTUAL_METHODS', $source.Substring($start, $end-$start))
    Copy-Item -LiteralPath (Join-Path $root 'Tests/ExistingPoliticalPressureHarness/Scenarios.cs.txt') -Destination (Join-Path $temp 'Scenarios.cs')
    $integration = Get-Content -Raw (Join-Path $root 'Behaviors/BellumIntegrationBehavior.cs')
    $thread = [regex]::Match($integration, 'internal bool IsCampaignThread => [^;]+;')
    $guardStart = $integration.IndexOf('internal static void RequireCampaignThread()')
    $guardEnd = $integration.IndexOf('public override void RegisterEvents()', $guardStart)
    if (-not $thread.Success -or $guardStart -lt 0 -or $guardEnd -le $guardStart) { throw 'Actual integration guard boundary changed' }
    Set-Content -LiteralPath (Join-Path $temp 'IntegrationGuard.cs') -Value ('using System; using System.Threading; namespace BellumCivile.Behaviors { public sealed partial class BellumIntegrationBehavior { ' + $thread.Value + $integration.Substring($guardStart,$guardEnd-$guardStart) + ' } }')
    $paths = @('PoliticalPressureStateSnapshot.cs','PoliticalPressureStateReader.cs','BellumIntegrationPoliticalPressure.cs',
        'WarWillPressureRecord.cs','WarWillReasonType.cs') | ForEach-Object { Join-Path $root $_ }
    $paths += @(Get-ChildItem $temp -Filter *.cs | ForEach-Object FullName)
    Add-Type -Path $paths -CompilerOptions '/langversion:7.3'
    [ExistingPoliticalPressureScenarios]::Run()
} finally { Remove-Item -LiteralPath $temp -Recurse -Force }
