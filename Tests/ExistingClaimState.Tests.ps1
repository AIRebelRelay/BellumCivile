#Requires -Version 7.2
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$temp = Join-Path ([IO.Path]::GetTempPath()) ('claim-state-' + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $temp | Out-Null
try {
    $source = Get-Content -Raw (Join-Path $root 'Behaviors/FeudalTitleBehavior.cs')
    $start = $source.IndexOf('private static bool IsClaimCurrentlyActive(FeudalClaimRecord claim)')
    $end = $source.IndexOf('private int NormalizeActiveClaimDuplicates()', $start)
    $day = [regex]::Match($source, 'private static float CurrentDay => [^;]+;')
    if ($start -lt 0 -or $end -le $start -or -not $day.Success) { throw 'Actual claim predicate boundary changed' }
    Set-Content -LiteralPath (Join-Path $temp 'ActivePredicate.cs') -Value ('using TaleWorlds.CampaignSystem; namespace BellumCivile.Behaviors { public partial class FeudalTitleBehavior { ' + $source.Substring($start, $end - $start) + $day.Value + ' } }')
    $legitimacy = Get-Content -Raw (Join-Path $root 'Behaviors/IntegrationLegitimacy.cs')
    $barred = [regex]::Match($legitimacy, 'internal static bool IsBarredId\(string id\) => [^;]+;')
    $integration = Get-Content -Raw (Join-Path $root 'Behaviors/BellumIntegrationBehavior.cs')
    $thread = [regex]::Match($integration, 'internal bool IsCampaignThread => [^;]+;')
    $guardStart = $integration.IndexOf('internal static void RequireCampaignThread()')
    $guardEnd = $integration.IndexOf('public override void RegisterEvents()', $guardStart)
    if (-not $barred.Success -or -not $thread.Success -or $guardStart -lt 0 -or $guardEnd -le $guardStart) { throw 'Actual legitimacy/thread guard boundary changed' }
    Set-Content -LiteralPath (Join-Path $temp 'IntegrationGuards.cs') -Value ('using System; using System.Threading; namespace BellumCivile.Behaviors { public sealed partial class BellumIntegrationBehavior { ' + $barred.Value + $thread.Value + $integration.Substring($guardStart, $guardEnd - $guardStart) + ' } }')
    foreach ($name in @('Fixtures', 'Scenarios')) {
        Copy-Item -LiteralPath (Join-Path $root "Tests/ExistingClaimStateHarness/$name.cs.txt") -Destination (Join-Path $temp "$name.cs")
    }
    $paths = @('ClaimStateSnapshot.cs', 'BellumIntegrationClaimState.cs', 'Behaviors/FeudalClaimIntegrationState.cs',
        'FeudalClaimRecord.cs', 'FeudalClaimStrength.cs', 'FeudalTitleRecord.cs', 'FeudalTitleType.cs',
        'Behaviors/FeudalLegitimacyClaims.cs') | ForEach-Object { Join-Path $root $_ }
    $paths += @(Get-ChildItem $temp -Filter *.cs | ForEach-Object FullName)
    Add-Type -Path $paths -CompilerOptions '/langversion:7.3'
    [ExistingClaimStateScenarios]::Run()
} finally { Remove-Item -LiteralPath $temp -Recurse -Force }
