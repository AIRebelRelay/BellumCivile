#Requires -Version 7.2
# Force launch: pwsh -NoProfile -ExecutionPolicy Bypass -File .\Tests\WarConflictIdentity.Tests.ps1
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$temp=Join-Path ([IO.Path]::GetTempPath()) ('war-identity-'+[guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $temp | Out-Null
try{
 foreach($name in @('Fixtures','Scenarios')){Copy-Item -LiteralPath (Join-Path $root "Tests/WarConflictIdentityHarness/$name.cs.txt") -Destination (Join-Path $temp "$name.cs")}
 $behavior=Get-Content -Raw -LiteralPath (Join-Path $root 'Behaviors/WarScoreBehavior.cs')
 $a=$behavior.IndexOf('public override void SyncData(IDataStore dataStore)');$b=$behavior.IndexOf('public IReadOnlyList<WarScoreRecord> GetActiveWars()', $a)
 if($a -lt 0 -or $b -le $a){throw 'Actual SyncData boundary changed'}
 $ensure=[regex]::Match($behavior,'private void EnsureCollectionsInitialized\(\)\s*\{\s*_wars = _wars \?\? new List<WarScoreRecord>\(\);\s*\}')
 if(!$ensure.Success){throw 'Actual list guard boundary changed'}
 Set-Content -LiteralPath (Join-Path $temp 'ActualSync.cs') -Value ('using System.Collections.Generic;using TaleWorlds.CampaignSystem;namespace BellumCivile.Behaviors{public sealed partial class WarScoreBehavior{'+$behavior.Substring($a,$b-$a)+$ensure.Value+'}}')
 $constants=Get-Content -Raw -LiteralPath (Join-Path $root 'BellumCivileConstants.cs')
 $parts=@('TreatyOfferingCreditMultiplier','WarScoreFeudObjectiveCap','WarScoreFeudObjectiveDailyGain') | ForEach-Object {
  $match=[regex]::Match($constants,('public const float '+$_+' = [^;]+;'));if(!$match.Success){throw "Missing actual constant $_"};$match.Value
 }
 $pair=Get-Content -Raw -LiteralPath (Join-Path $root 'CivilWarConflictRecord.cs');$prefix=[regex]::Match($pair,'internal const string RivalryPrefix = "[^"]*";')
 if(!$prefix.Success){throw 'Missing actual rivalry prefix'}
 Set-Content -LiteralPath (Join-Path $temp 'ActualConstants.cs') -Value ('namespace BellumCivile{internal static class BellumCivileConstants{'+($parts -join "`n")+'}internal sealed class CivilWarPairRecord{'+$prefix.Value+'}}')
 $paths=@('WarScoreRecord.cs','WarScorePeaceReconsideration.cs','WarScoreFeudObjective.cs','WarScoreConflictType.cs','WarScoreFiefSnapshotRecord.cs','WarScoreEventRecord.cs','WarScoreEventType.cs','TreatyTermRecord.cs','TreatyTermType.cs') | ForEach-Object {Join-Path $root $_}
 $paths+=@(Get-ChildItem -LiteralPath $temp -Filter *.cs | ForEach-Object FullName)
 Add-Type -Path $paths -CompilerOptions '/langversion:7.3'
 [WarConflictIdentityScenarios]::Run()
 $baseline=Get-Content -Raw -LiteralPath (Join-Path $root 'Tests/WarConflictIdentityHarness/SaveFieldsBaseline.json') | ConvertFrom-Json
 $actual=@(foreach($file in @('WarScoreRecord.cs','WarScorePeaceReconsideration.cs','WarScoreFeudObjective.cs')){
  Get-Content -LiteralPath (Join-Path $root $file) | Where-Object {$_ -match '\[SaveableField\(' -and $_ -notmatch '\[SaveableField\((38|39|40|41)\)\]'} | ForEach-Object {$_.Trim()}
 })
 if(($baseline -join "`n") -cne ($actual -join "`n")){throw 'Existing saved field identity/type/name changed'}
 Write-Output 'WAR IDENTITY SCHEMA PASS original37 exact declarations preserved'

}finally{Remove-Item -LiteralPath $temp -Recurse -Force}
