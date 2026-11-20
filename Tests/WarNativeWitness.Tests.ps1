#Requires -Version 7.2
# Force launch: pwsh -NoProfile -ExecutionPolicy Bypass -File .\Tests\WarNativeWitness.Tests.ps1
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$temp=Join-Path ([IO.Path]::GetTempPath()) ('war-native-witness-'+[guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $temp | Out-Null
try {
 $eventSource=Get-Content -Raw -LiteralPath (Join-Path $root 'Behaviors/WarScoreBehavior.cs')
 $eventStart=$eventSource.IndexOf('private void OnWarDeclared(')
 $eventEnd=$eventSource.IndexOf('internal bool EnsureProtectionInterventionTracked(', $eventStart)
 if($eventStart -lt 0 -or $eventEnd -le $eventStart){throw 'Actual declaration handler moved'}
 $event=$eventSource.Substring($eventStart,$eventEnd-$eventStart)
 if($event -notmatch 'WarScoreRecord previouslyTracked = GetActiveWar\(' -or
    $event -notmatch 'FlagAmbiguousNativeForeignDeclaration\(' -or
    $event -notmatch 'CaptureNewNativeForeignWarStart\(' -or
    $event -notmatch 'previouslyTracked != null' -or
    $event -match 'MarkWarEnded\(|MakePeaceAction\.Apply|DeclareWarAction\.Apply'){
  throw 'Native provenance callback boundary regression'
 }
 $entry=Get-Content -Raw -LiteralPath (Join-Path $root 'CheatCommands.cs')
 $start=$entry.IndexOf('[CommandLineFunctionality.CommandLineArgumentFunction("dump_war_native_witness", "civilwars")]')
 $end=$entry.IndexOf('[CommandLineFunctionality.CommandLineArgumentFunction("war_score", "civilwars")]', $start)
 if($start -lt 0 -or $end -le $start){throw 'Native witness console entrypoint missing'}
 $command=$entry.Substring($start,$end-$start)
 if($command -notmatch 'RequireCampaignThread\(' -or
   $command -notmatch 'BuildForeignWarNativeWitnessDump\(' -or
   $command -match '(RegisterConflict|ReconcileExistingWars|EnsureCollectionsInitialized|InitializeMissingConflictInstanceId|SyncData)\s*\('){
  throw 'Native witness console not passive/guarded'
 }
 foreach($file in @('Fixtures','Scenarios')){
  $sourcePath= if($file -eq 'Fixtures') {'Tests/ForeignConflictIdentityHarness/Fixtures.cs.txt'} else {'Tests/WarNativeWitnessHarness/Scenarios.cs.txt'}
  Copy-Item -LiteralPath (Join-Path $root $sourcePath) -Destination (Join-Path $temp "$file.cs")
 }
 $fixturePath=Join-Path $temp 'Fixtures.cs'
 $fixture=Get-Content -Raw -LiteralPath $fixturePath
 if(!$fixture.Contains('public bool IsAtWarWith(Kingdom other){return Hostile;}')){throw 'Fixture kingdom seam changed'}
 $fixture=$fixture.Replace('public bool IsAtWarWith(Kingdom other){return Hostile;}',
 'public double NativeWarDay=20;public bool IsAtWarWith(Kingdom other){return Hostile;}public StanceLink GetStanceWith(Kingdom other){return new StanceLink{WarStartDate=new CampaignTime{ToDays=NativeWarDay}};}')
 $fixture=$fixture.Replace('namespace TaleWorlds.CampaignSystem{','namespace TaleWorlds.CampaignSystem{ public sealed class StanceLink {public CampaignTime WarStartDate;}')
 Set-Content -LiteralPath $fixturePath -Value $fixture
 # This harness reuses ForeignConflictIdentityHarness/Fixtures.cs.txt, whose Campaign
 # manager references BellumIntegrationBehavior. Include the real, bounded campaign
 # thread guard so the isolated Add-Type assembly resolves that shared fixture type.
 $integration=Get-Content -Raw -LiteralPath (Join-Path $root 'Behaviors/BellumIntegrationBehavior.cs')
 $guardStart=$integration.IndexOf('internal static BellumIntegrationBehavior Current')
 $guardEnd=$integration.IndexOf('public override void RegisterEvents()', $guardStart)
 if($guardStart -lt 0 -or $guardEnd -le $guardStart){throw 'Actual campaign guard boundary changed'}
 Set-Content -LiteralPath (Join-Path $temp 'Guard.cs') -Value ('using System;using System.Threading;using TaleWorlds.CampaignSystem;namespace BellumCivile.Behaviors{public sealed partial class BellumIntegrationBehavior{'+$integration.Substring($guardStart,$guardEnd-$guardStart)+'}}')
 $constants=Get-Content -Raw -LiteralPath (Join-Path $root 'BellumCivileConstants.cs')
 $parts=@('TreatyOfferingCreditMultiplier','WarScoreFeudObjectiveCap','WarScoreFeudObjectiveDailyGain') | ForEach-Object {
  $match=[regex]::Match($constants,('public const float '+$_+' = [^;]+;'))
  if(!$match.Success){throw "Missing constant $_"};$match.Value
 }
 $pair=Get-Content -Raw -LiteralPath (Join-Path $root 'CivilWarConflictRecord.cs')
 $prefix=[regex]::Match($pair,'internal const string RivalryPrefix = "[^"]*";')
 if(!$prefix.Success){throw 'Missing rivalry prefix'}
 Set-Content -LiteralPath (Join-Path $temp 'Constants.cs') -Value ('namespace BellumCivile{internal static class BellumCivileConstants{'+($parts -join "`n")+'}internal sealed class CivilWarPairRecord{'+$prefix.Value+'}}')
 $paths=@('ForeignConflictIdentitySnapshot.cs','ForeignWarNativeWitnessSnapshot.cs',
 'Behaviors/WarScoreConflictIdentityReader.cs','Behaviors/WarScoreIdentityDump.cs',
 'Behaviors/WarScoreForeignNativeWitness.cs','WarScoreRecord.cs',
 'WarScorePeaceReconsideration.cs','WarScoreFeudObjective.cs',
 'WarScoreConflictType.cs','WarScoreFiefSnapshotRecord.cs','WarScoreEventRecord.cs',
 'WarScoreEventType.cs','TreatyTermRecord.cs','TreatyTermType.cs') | ForEach-Object {Join-Path $root $_}
 $paths+=@(Get-ChildItem -LiteralPath $temp -Filter *.cs | ForEach-Object FullName)
 Add-Type -Path $paths -CompilerOptions '/langversion:7.3'
 [WarNativeWitnessScenarios]::Run()
}finally {
 Remove-Item -LiteralPath $temp -Recurse -Force
}
