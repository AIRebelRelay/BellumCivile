#Requires -Version 7.2
# Force launch: pwsh -NoProfile -ExecutionPolicy Bypass -File .\Tests\WarConflictIdentity.Mutations.ps1
$ErrorActionPreference='Stop'
$PSNativeCommandUseErrorActionPreference=$false
$root=Split-Path $PSScriptRoot -Parent
$pwsh=(Get-Process -Id $PID).Path
$cases=@(
 @('sync_reassigns_valid_id','WarScoreRecord.cs','if (_conflictInstanceId != null) return false;','if (_conflictInstanceId == "__never__") return false;'),
 @('all_instances_share_id','WarScoreRecord.cs','System.Guid.NewGuid().ToString("N")','"11111111111111111111111111111111"'),
 @('getter_mutates_legacy','WarScoreRecord.cs','System.Guid id;','InitializeMissingConflictInstanceId(); System.Guid id;'),
 @('missing_sync_migration','Behaviors/WarScoreBehavior.cs','war?.InitializeMissingConflictInstanceId();','// mutation: no legacy identity migration'),
 @('end_reassigns_identity','WarScoreRecord.cs','_endedDay = day;','_conflictInstanceId = null; InitializeMissingConflictInstanceId(); _endedDay = day;')
)
foreach($case in $cases){
 $name,$relative,$before,$after=$case
 $source=Get-Content -Raw -LiteralPath (Join-Path $root $relative)
 if([regex]::Matches($source,[regex]::Escape($before)).Count -ne 1){throw "Mutation boundary changed: $name"}
 $temp=Join-Path ([IO.Path]::GetTempPath()) ('war-id-mutant-'+[guid]::NewGuid().ToString('N'))
 New-Item -ItemType Directory -Path (Join-Path $temp 'Tests'),(Join-Path $temp 'Behaviors') | Out-Null
 try{
  foreach($path in @('WarScoreRecord.cs','WarScorePeaceReconsideration.cs','WarScoreFeudObjective.cs','WarScoreConflictType.cs','WarScoreFiefSnapshotRecord.cs','WarScoreEventRecord.cs','WarScoreEventType.cs','TreatyTermRecord.cs','TreatyTermType.cs','BellumCivileConstants.cs','CivilWarConflictRecord.cs','Behaviors/WarScoreBehavior.cs','Tests/WarConflictIdentity.Tests.ps1')){Copy-Item -LiteralPath (Join-Path $root $path) -Destination (Join-Path $temp $path)}
  Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'WarConflictIdentityHarness') -Destination (Join-Path $temp 'Tests') -Recurse
  [IO.File]::WriteAllText((Join-Path $temp $relative),$source.Replace($before,$after))
  $output=(& $pwsh -NoProfile -ExecutionPolicy Bypass -File (Join-Path $temp 'Tests/WarConflictIdentity.Tests.ps1') 2>&1 | Out-String)
  $code=$LASTEXITCODE
  if($code -eq 0 -or $output -notmatch 'FAIL' -or $output -notmatch 'Exception calling' -or $output -match 'Add-Type:'){throw "Mutation not rejected by assertion: $name`n$output"}
  Write-Output ('WAR_ID_MUTATION_REJECTED '+$name)
 }finally{Remove-Item -LiteralPath $temp -Recurse -Force}
}
Write-Output 'WAR IDENTITY MUTATIONS REJECTED 5'
