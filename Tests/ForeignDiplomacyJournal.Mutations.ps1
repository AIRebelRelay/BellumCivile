#Requires -Version 7.2
# Force launch: pwsh -NoProfile -ExecutionPolicy Bypass -File .\Tests\ForeignDiplomacyJournal.Mutations.ps1
$ErrorActionPreference='Stop'
$PSNativeCommandUseErrorActionPreference=$false
$root=Split-Path $PSScriptRoot -Parent
$pwsh=(Get-Process -Id $PID).Path
$cases=@(
 @('stale_begin_allowed','ForeignDiplomacyJournal.cs','if (!MatchesSession(session)) return ForeignDiplomacyJournalResult.StaleSession;','if (session == null) return ForeignDiplomacyJournalResult.StaleSession;'),
 @('ruler_binding_removed','ForeignDiplomacyJournal.cs','r.FirstRulerId == q.FirstRulerId && r.SecondRulerId == q.SecondRulerId','true'),
 @('retry_replaces_operation_id','ForeignDiplomacyJournal.cs','snapshot = new ForeignDiplomacyIntentSnapshot(_state.CampaignId, prior);','prior.OperationId = Guid.NewGuid().ToString("N"); snapshot = new ForeignDiplomacyIntentSnapshot(_state.CampaignId, prior);'),
 @('cancelled_intent_resurrected','ForeignDiplomacyJournal.cs','snapshot = new ForeignDiplomacyIntentSnapshot(_state.CampaignId, prior);','prior.Cancelled = false; snapshot = new ForeignDiplomacyIntentSnapshot(_state.CampaignId, prior);'),
 @('load_keeps_old_session','Behaviors/IntegrationForeignDiplomacy.cs','_foreignDiplomacyJournal = null;','// mutation: old journal retained')
)
foreach($case in $cases){
 $name,$relative,$before,$after=$case
 $source=(Get-Content -Raw -LiteralPath (Join-Path $root $relative)).Replace("`r`n","`n")
 $start=$source.IndexOf($before,[StringComparison]::Ordinal)
 if($start -lt 0){throw "Mutation boundary changed: $name"}
 $mutant=$source.Substring(0,$start)+$after+$source.Substring($start+$before.Length)
 $temp=Join-Path ([IO.Path]::GetTempPath()) ('journal-mutant-'+[guid]::NewGuid().ToString('N'))
 New-Item -ItemType Directory -Path (Join-Path $temp 'Behaviors'),(Join-Path $temp 'Tests') | Out-Null
 try{
  foreach($path in @('ForeignDiplomacyAdmissionPolicy.cs','ForeignDiplomacyJournalRecords.cs','ForeignDiplomacyJournal.cs','Behaviors/IntegrationForeignDiplomacy.cs','Behaviors/BellumIntegrationBehavior.cs','Tests/ForeignDiplomacyJournal.Tests.ps1')){
   Copy-Item -LiteralPath (Join-Path $root $path) -Destination (Join-Path $temp $path)
  }
  Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'ForeignDiplomacyJournalHarness') -Destination (Join-Path $temp 'Tests') -Recurse
  [IO.File]::WriteAllText((Join-Path $temp $relative),$mutant)
  $output=(& $pwsh -NoProfile -ExecutionPolicy Bypass -File (Join-Path $temp 'Tests/ForeignDiplomacyJournal.Tests.ps1') 2>&1 | Out-String)
  $code=$LASTEXITCODE
  if($code -eq 0 -or $output -notmatch 'FAIL' -or $output -notmatch 'Exception calling' -or $output -match 'Add-Type:'){throw "Mutation not rejected by assertion: $name`n$output"}
  Write-Output ('JOURNAL_MUTATION_REJECTED '+$name)
 }finally{Remove-Item -LiteralPath $temp -Recurse -Force}
}
Write-Output 'JOURNAL MUTATIONS REJECTED 5'
