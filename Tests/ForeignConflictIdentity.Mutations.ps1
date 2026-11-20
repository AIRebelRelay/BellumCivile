#Requires -Version 7.2
# Force launch: pwsh -NoProfile -ExecutionPolicy Bypass -File .\Tests\ForeignConflictIdentity.Mutations.ps1
$ErrorActionPreference='Stop'
$PSNativeCommandUseErrorActionPreference=$false
$root=Split-Path $PSScriptRoot -Parent
$pwsh=(Get-Process -Id $PID).Path
$cases=@(
 @('first_match_hides_duplicate','Behaviors/WarScoreConflictIdentityReader.cs','.Take(2).ToList();','.Take(1).ToList();'),
 @('ordered_participant_binding_removed','Behaviors/WarScoreConflictIdentityReader.cs','record.AttackerKingdomId != primaryId || record.DefenderKingdomId != opposingId','record.AttackerKingdomId == "__never__"'),
 @('ended_record_allowed','Behaviors/WarScoreConflictIdentityReader.cs','if (!record.IsActive)','if (!record.IsActive && day < 0)'),
 @('reverse_hostility_ignored','Behaviors/WarScoreConflictIdentityReader.cs',' || !opposing[0].IsAtWarWith(primary[0])',''),
 @('campaign_guard_bypassed','BellumIntegrationConflictIdentity.cs','BellumIntegrationBehavior.RequireCampaignThread();','// mutation: public thread guard bypassed')
)
foreach($case in $cases){
 $name,$relative,$before,$after=$case
 $source=Get-Content -Raw -LiteralPath (Join-Path $root $relative)
 $position=$source.IndexOf($before,[StringComparison]::Ordinal);if($position -lt 0){throw "Missing mutation boundary $name"}
 $mutant=$source.Substring(0,$position)+$after+$source.Substring($position+$before.Length)
 $temp=Join-Path ([IO.Path]::GetTempPath()) ('identity-reader-mutant-'+[guid]::NewGuid().ToString('N'))
 New-Item -ItemType Directory -Path (Join-Path $temp 'Tests'),(Join-Path $temp 'Behaviors') | Out-Null
 try{
  foreach($path in @('ForeignConflictIdentitySnapshot.cs','BellumIntegrationConflictIdentity.cs','Behaviors/WarScoreConflictIdentityReader.cs','Behaviors/BellumIntegrationBehavior.cs','WarScoreRecord.cs','WarScorePeaceReconsideration.cs','WarScoreFeudObjective.cs','WarScoreConflictType.cs','WarScoreFiefSnapshotRecord.cs','WarScoreEventRecord.cs','WarScoreEventType.cs','TreatyTermRecord.cs','TreatyTermType.cs','BellumCivileConstants.cs','CivilWarConflictRecord.cs','Tests/ForeignConflictIdentity.Tests.ps1')){Copy-Item -LiteralPath (Join-Path $root $path) -Destination (Join-Path $temp $path)}
  Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'ForeignConflictIdentityHarness') -Destination (Join-Path $temp 'Tests') -Recurse
  [IO.File]::WriteAllText((Join-Path $temp $relative),$mutant)
  $output=(& $pwsh -NoProfile -ExecutionPolicy Bypass -File (Join-Path $temp 'Tests/ForeignConflictIdentity.Tests.ps1') 2>&1 | Out-String)
  $code=$LASTEXITCODE
  if($code -eq 0 -or $output -notmatch 'FAIL' -or $output -notmatch 'Exception calling' -or $output -match 'Add-Type:'){throw "Mutation not rejected by assertion: $name`n$output"}
  Write-Output ('IDENTITY_READER_MUTATION_REJECTED '+$name)
 }finally{Remove-Item -LiteralPath $temp -Recurse -Force}
}
Write-Output 'IDENTITY READER MUTATIONS REJECTED 5'
