#Requires -Version 7.2
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$temp = Join-Path ([IO.Path]::GetTempPath()) ('war-state-' + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $temp | Out-Null
try {
    $source = Get-Content -Raw (Join-Path $root 'Behaviors/WarScoreBehavior.cs')
    $opponentStart = $source.IndexOf('public Kingdom GetOpposingKingdom(WarScoreRecord war, Kingdom viewingKingdom)')
    $opponentEnd = $source.IndexOf('public IReadOnlyList<WarScoreRecord> GetTrackedWars()', $opponentStart)
    $resolveStart = $source.IndexOf('private static Kingdom ResolveKingdom(string kingdomId)')
    $resolveEnd = $source.IndexOf('private static Settlement ResolveSettlement(string settlementId)', $resolveStart)
    if ($opponentStart -lt 0 -or $opponentEnd -le $opponentStart -or $resolveStart -lt 0 -or $resolveEnd -le $resolveStart) { throw 'Actual helper extraction boundary changed' }
    $helpers = 'using System.Linq; using TaleWorlds.CampaignSystem; namespace BellumCivile.Behaviors { public sealed partial class WarScoreBehavior { ' + $source.Substring($opponentStart, $opponentEnd - $opponentStart) + $source.Substring($resolveStart, $resolveEnd - $resolveStart) + ' } }'
    Set-Content -LiteralPath (Join-Path $temp 'Helpers.cs') -Value $helpers
    foreach ($name in @('Fixtures', 'Scenarios')) {
        Copy-Item -LiteralPath (Join-Path $root "Tests/ExistingWarStateHarness/$name.cs.txt") -Destination (Join-Path $temp "$name.cs")
    }
    $pairSource = Get-Content -Raw (Join-Path $root 'CivilWarConflictRecord.cs')
    $constant = [regex]::Match($pairSource, 'internal const string RivalryPrefix = "[^"]*";')
    if (-not $constant.Success) { throw 'Missing actual rivalry prefix constant' }
    Set-Content -LiteralPath (Join-Path $temp 'PairConstant.cs') -Value ('namespace BellumCivile { internal sealed class CivilWarPairRecord { ' + $constant.Value + ' } }')
    $constantsSource = Get-Content -Raw (Join-Path $root 'BellumCivileConstants.cs')
    $credit = [regex]::Match($constantsSource, 'public const float TreatyOfferingCreditMultiplier = [^;]+;')
    if (-not $credit.Success) { throw 'Missing actual treaty credit constant' }
    Set-Content -LiteralPath (Join-Path $temp 'CreditConstant.cs') -Value ('namespace BellumCivile { internal static class BellumCivileConstants { ' + $credit.Value + ' } }')
    $paths = @('WarStateSnapshot.cs', 'BellumIntegrationWarState.cs', 'Behaviors/WarScoreIntegrationState.cs',
        'WarScoreRecord.cs', 'WarScorePeaceReconsideration.cs', 'TreatyTermRecord.cs', 'TreatyTermType.cs', 'WarScoreConflictType.cs', 'WarScoreEventRecord.cs', 'WarScoreEventType.cs', 'WarScoreFiefSnapshotRecord.cs') | ForEach-Object { Join-Path $root $_ }
    $paths += @(Get-ChildItem $temp -Filter *.cs | ForEach-Object FullName)
    Add-Type -Path $paths -CompilerOptions '/langversion:7.3'
    [ExistingWarStateScenarios]::Run()
} finally { Remove-Item -LiteralPath $temp -Recurse -Force }
