#Requires -Version 7.2
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$temp = Join-Path ([IO.Path]::GetTempPath()) ('council-state-' + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $temp | Out-Null
try {
    $source = Get-Content -Raw (Join-Path $root 'Behaviors/PrivyCouncilBehavior.cs')
    $start = $source.IndexOf('private static bool IsEligiblePermanentRealm(Kingdom kingdom)')
    $end = $source.IndexOf('private Clan ResolveClan(string clanId)', $start)
    if ($start -lt 0 -or $end -le $start) { throw 'Missing actual permanent-realm predicate boundary' }
    $guard = 'using TaleWorlds.CampaignSystem; namespace BellumCivile.Behaviors { public sealed partial class PrivyCouncilBehavior { ' + $source.Substring($start, $end - $start) + ' } }'
    Set-Content -LiteralPath (Join-Path $temp 'Guard.cs') -Value $guard
    foreach ($name in @('Fixtures', 'Scenarios')) {
        Copy-Item -LiteralPath (Join-Path $root "Tests/ExistingCouncilStateHarness/$name.cs.txt") -Destination (Join-Path $temp "$name.cs")
    }
    $paths = @('CouncilOfficeStateSnapshot.cs', 'BellumIntegrationCouncilState.cs',
        'Behaviors/PrivyCouncilIntegrationState.cs', 'PrivyCouncilOfficeRecord.cs',
        'PrivyCouncilOffice.cs', 'BellumKingdomVisibilityHelper.cs') | ForEach-Object { Join-Path $root $_ }
    $paths += @(Get-ChildItem $temp -Filter *.cs | ForEach-Object FullName)
    Add-Type -Path $paths -CompilerOptions '/langversion:7.3'
    [ExistingCouncilStateScenarios]::Run()
} finally { Remove-Item -LiteralPath $temp -Recurse -Force }
