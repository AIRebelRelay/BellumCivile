#Requires -Version 7.2
# Force launch: pwsh -NoProfile -ExecutionPolicy Bypass -File .\Tests\WarIdentityDump.Tests.ps1
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$temp=Join-Path ([IO.Path]::GetTempPath()) ('war-dump-'+[guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $temp | Out-Null
try {
 $source=Get-Content -Raw -LiteralPath (Join-Path $root 'CheatCommands.cs')
 $a=$source.IndexOf('[CommandLineFunctionality.CommandLineArgumentFunction("dump_war_ids", "civilwars")]')
 $b=$source.IndexOf('[CommandLineFunctionality.CommandLineArgumentFunction("war_score", "civilwars")]', $a)
 if($a -lt 0 -or $b -le $a){throw 'Actual console entrypoint missing or moved'}
 $method=$source.Substring($a,$b-$a)
 if($method.IndexOf('BellumIntegrationBehavior.RequireCampaignThread()') -lt 0 -or
    $method.IndexOf('RequireCampaignThread()') -gt $method.IndexOf('BuildWarIdentityDump()') -or
    $method.IndexOf('BellumCivileLogger.Log(line)') -lt 0 -or
    $method.IndexOf('BellumCivileLogger.Flush()') -lt 0 -or
    $method -match '(RegisterConflict|ReconcileExistingWars|EnsureCollectionsInitialized|InitializeMissingConflictInstanceId|SyncData)\s*\('){
  throw 'Console guard/log/passivity contract failed'
 }
 $dump=Get-Content -Raw -LiteralPath (Join-Path $root 'Behaviors/WarScoreIdentityDump.cs')
 if($dump -match '(RegisterConflict|ReconcileExistingWars|EnsureCollectionsInitialized|InitializeMissingConflictInstanceId|SyncData|MarkWarEnded|OnMakePeace)\s*\('){throw 'Dump must not mutate or initialize campaign records'}
 Copy-Item -LiteralPath (Join-Path $root 'Tests/ForeignConflictIdentityHarness/Fixtures.cs.txt') -Destination (Join-Path $temp 'Fixtures.cs')
 Copy-Item -LiteralPath (Join-Path $root 'Tests/WarIdentityDumpHarness/Scenarios.cs.txt') -Destination (Join-Path $temp 'Scenarios.cs')
 # The shared identity-reader fixture's campaign manager is typed to BellumIntegrationBehavior.
 # Compile its existing campaign guard in the isolated test assembly, as in ForeignConflictIdentity.Tests.ps1.
 $integration=Get-Content -Raw -LiteralPath (Join-Path $root 'Behaviors/BellumIntegrationBehavior.cs')
 $guardStart=$integration.IndexOf('internal static BellumIntegrationBehavior Current')
 $guardEnd=$integration.IndexOf('public override void RegisterEvents()', $guardStart)
 if($guardStart -lt 0 -or $guardEnd -le $guardStart){throw 'Actual campaign guard boundary changed'}
 Set-Content -LiteralPath (Join-Path $temp 'Guard.cs') -Value ('using System;using System.Threading;using TaleWorlds.CampaignSystem;namespace BellumCivile.Behaviors{public sealed partial class BellumIntegrationBehavior{'+$integration.Substring($guardStart,$guardEnd-$guardStart)+'}}')
 $constants=Get-Content -Raw -LiteralPath (Join-Path $root 'BellumCivileConstants.cs')
 $parts=@('TreatyOfferingCreditMultiplier','WarScoreFeudObjectiveCap','WarScoreFeudObjectiveDailyGain') | ForEach-Object {
  $m=[regex]::Match($constants,('public const float '+$_+' = [^;]+;'));if(!$m.Success){throw "Missing constant $_"};$m.Value
 }
 $pair=Get-Content -Raw -LiteralPath (Join-Path $root 'CivilWarConflictRecord.cs')
 $prefix=[regex]::Match($pair,'internal const string RivalryPrefix = "[^"]*";')
 if(!$prefix.Success){throw 'Missing rivalry prefix'}
 Set-Content -LiteralPath (Join-Path $temp 'Constants.cs') -Value ('namespace BellumCivile{internal static class BellumCivileConstants{'+($parts -join "`n")+'}internal sealed class CivilWarPairRecord{'+$prefix.Value+'}}')
 $paths=@('ForeignConflictIdentitySnapshot.cs','Behaviors/WarScoreConflictIdentityReader.cs',
 'Behaviors/WarScoreIdentityDump.cs','WarScoreRecord.cs','WarScorePeaceReconsideration.cs','WarScoreFeudObjective.cs',
 'WarScoreConflictType.cs','WarScoreFiefSnapshotRecord.cs','WarScoreEventRecord.cs','WarScoreEventType.cs',
 'TreatyTermRecord.cs','TreatyTermType.cs') | ForEach-Object {Join-Path $root $_}
 $paths+=@(Get-ChildItem -LiteralPath $temp -Filter *.cs | ForEach-Object FullName)
 Add-Type -Path $paths -CompilerOptions '/langversion:7.3'
 [WarIdentityDumpScenarios]::Run()
 Write-Output 'WAR_ID_DUMP_CONSOLE_CONTRACT_PASS; actual guarded command and logger checked; game NOT_RUN'
} finally {
 Remove-Item -LiteralPath $temp -Recurse -Force
}
