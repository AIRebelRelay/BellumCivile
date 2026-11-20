#Requires -Version 7.2
# Force launch: pwsh -NoProfile -ExecutionPolicy Bypass -File .\Tests\ForeignCrisisWindow.Mutations.ps1
$ErrorActionPreference='Stop'
$PSNativeCommandUseErrorActionPreference=$false
$root=Split-Path $PSScriptRoot -Parent
$source=Get-Content -Raw -LiteralPath (Join-Path $root 'ForeignCrisisWindowPolicy.cs')
$pwsh=(Get-Process -Id $PID).Path
$cases=@(
 @('campaign_floor_ignored','currentCampaignDay < state.CampaignFloorDay','currentCampaignDay < state.OpeningDay'),
 @('opportunity_wait_ignored','&& totalActiveSeconds < state.BudgetSeconds','&& totalActiveSeconds < 0'),
 @('technical_failure_as_final','if (reply != ForeignCrisisReplyState.ValidTerminalResponse && totalActiveSeconds < state.BudgetSeconds)','if (reply != ForeignCrisisReplyState.ValidTerminalResponse && reply != ForeignCrisisReplyState.TechnicalFailure && totalActiveSeconds < state.BudgetSeconds)'),
 @('pause_ignored','if (campaignPaused)','if (campaignPaused && totalActiveSeconds < 0)'),
 @('absolute_counter_double_counted','state.BudgetSeconds, currentCampaignDay, totalActiveSeconds);','state.BudgetSeconds, currentCampaignDay, totalActiveSeconds + state.SpentActiveSeconds);')
)
foreach($case in $cases){
 $name,$before,$after=$case
 if([regex]::Matches($source,[regex]::Escape($before)).Count -ne 1){throw "Mutation boundary changed: $name"}
 $temp=Join-Path ([IO.Path]::GetTempPath()) ('window-mutant-'+[guid]::NewGuid().ToString('N'))
 New-Item -ItemType Directory -Path (Join-Path $temp 'Tests') | Out-Null
 try{
  [IO.File]::WriteAllText((Join-Path $temp 'ForeignCrisisWindowPolicy.cs'),$source.Replace($before,$after))
  Copy-Item -LiteralPath (Join-Path $root 'ForeignCrisisBudgetEstimator.cs') -Destination $temp
  Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'ForeignCrisisWindowHarness') -Destination (Join-Path $temp 'Tests') -Recurse
  Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'ForeignCrisisWindow.Tests.ps1') -Destination (Join-Path $temp 'Tests')
  $output=(& $pwsh -NoProfile -ExecutionPolicy Bypass -File (Join-Path $temp 'Tests/ForeignCrisisWindow.Tests.ps1') 2>&1 | Out-String)
  $code=$LASTEXITCODE
  if($code -eq 0 -or $output -notmatch 'FAIL' -or $output -notmatch 'Exception calling' -or $output -match 'Add-Type:'){throw "Mutation not rejected by assertion: $name`n$output"}
  Write-Output ('WINDOW_MUTATION_REJECTED '+$name)
 }finally{Remove-Item -LiteralPath $temp -Recurse -Force}
}
Write-Output 'WINDOW MUTATIONS REJECTED 5'
