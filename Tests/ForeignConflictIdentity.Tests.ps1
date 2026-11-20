#Requires -Version 7.2
# Force launch: pwsh -NoProfile -ExecutionPolicy Bypass -File .\Tests\ForeignConflictIdentity.Tests.ps1
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$temp=Join-Path ([IO.Path]::GetTempPath()) ('conflict-reader-'+[guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $temp | Out-Null
try{
 foreach($name in @('Fixtures','Scenarios')){Copy-Item -LiteralPath (Join-Path $root "Tests/ForeignConflictIdentityHarness/$name.cs.txt") -Destination (Join-Path $temp "$name.cs")}
 $integration=Get-Content -Raw -LiteralPath (Join-Path $root 'Behaviors/BellumIntegrationBehavior.cs')
 $a=$integration.IndexOf('internal static BellumIntegrationBehavior Current');$b=$integration.IndexOf('public override void RegisterEvents()', $a)
 if($a -lt 0 -or $b -le $a){throw 'Actual campaign guard boundary changed'}
 Set-Content -LiteralPath (Join-Path $temp 'Guard.cs') -Value ('using System;using System.Threading;using TaleWorlds.CampaignSystem;namespace BellumCivile.Behaviors{public sealed partial class BellumIntegrationBehavior{'+$integration.Substring($a,$b-$a)+'}}')
 $constants=Get-Content -Raw -LiteralPath (Join-Path $root 'BellumCivileConstants.cs')
 $parts=@('TreatyOfferingCreditMultiplier','WarScoreFeudObjectiveCap','WarScoreFeudObjectiveDailyGain') | ForEach-Object {$m=[regex]::Match($constants,('public const float '+$_+' = [^;]+;'));if(!$m.Success){throw "Missing constant $_"};$m.Value}
 $pair=Get-Content -Raw -LiteralPath (Join-Path $root 'CivilWarConflictRecord.cs');$prefix=[regex]::Match($pair,'internal const string RivalryPrefix = "[^"]*";');if(!$prefix.Success){throw 'Missing rivalry prefix'}
 Set-Content -LiteralPath (Join-Path $temp 'Constants.cs') -Value ('namespace BellumCivile{internal static class BellumCivileConstants{'+($parts -join "`n")+'}internal sealed class CivilWarPairRecord{'+$prefix.Value+'}}')
 $paths=@('ForeignConflictIdentitySnapshot.cs','BellumIntegrationConflictIdentity.cs','Behaviors/WarScoreConflictIdentityReader.cs','WarScoreRecord.cs','WarScorePeaceReconsideration.cs','WarScoreFeudObjective.cs','WarScoreConflictType.cs','WarScoreFiefSnapshotRecord.cs','WarScoreEventRecord.cs','WarScoreEventType.cs','TreatyTermRecord.cs','TreatyTermType.cs') | ForEach-Object {Join-Path $root $_}
 $paths+=@(Get-ChildItem -LiteralPath $temp -Filter *.cs | ForEach-Object FullName)
 Add-Type -Path $paths -CompilerOptions '/langversion:7.3'
 [ForeignConflictIdentityScenarios]::Run()
}finally{Remove-Item -LiteralPath $temp -Recurse -Force}
