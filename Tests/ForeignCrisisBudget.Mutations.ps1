#Requires -Version 7.2
# Force launch: pwsh -NoProfile -ExecutionPolicy Bypass -File .\Tests\ForeignCrisisBudget.Mutations.ps1
$ErrorActionPreference='Stop'
$PSNativeCommandUseErrorActionPreference=$false
$root=Split-Path $PSScriptRoot -Parent
$source=Get-Content -Raw -LiteralPath (Join-Path $root 'ForeignCrisisBudgetEstimator.cs')
$pwsh=(Get-Process -Id $PID).Path
$cases=@(
 @('serial_calls_not_summed','total += callTotal;','total = callTotal;'),
 @('attempt_time_ignored','* call.MaxAttempts','* 1'),
 @('tps_formula_wrong','call.OutputTokens / p.ConservativeTps.Value','call.OutputTokens * p.ConservativeTps.Value'),
 @('cap_silently_truncates','new ForeignCrisisBudgetResult(ForeignCrisisBudgetStatus.DoesNotFit, total, required);','new ForeignCrisisBudgetResult(ForeignCrisisBudgetStatus.Ready, total, required, hardCapSeconds);'),
 @('calibration_range_not_checked','call.InputTokens > p.MaxInputTokens || call.OutputTokens > p.MaxOutputTokens','call.InputTokens < 0 || call.OutputTokens < 0')
)
foreach($case in $cases){
 $name,$before,$after=$case
 if([regex]::Matches($source,[regex]::Escape($before)).Count -ne 1){throw "Mutation boundary changed: $name"}
 $temp=Join-Path ([IO.Path]::GetTempPath()) ('budget-mutant-'+[guid]::NewGuid().ToString('N'))
 New-Item -ItemType Directory -Path (Join-Path $temp 'Tests') | Out-Null
 try{
  [IO.File]::WriteAllText((Join-Path $temp 'ForeignCrisisBudgetEstimator.cs'),$source.Replace($before,$after))
  Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'ForeignCrisisBudgetHarness') -Destination (Join-Path $temp 'Tests') -Recurse
  Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'ForeignCrisisBudget.Tests.ps1') -Destination (Join-Path $temp 'Tests')
  $output=(& $pwsh -NoProfile -ExecutionPolicy Bypass -File (Join-Path $temp 'Tests/ForeignCrisisBudget.Tests.ps1') 2>&1 | Out-String)
  $code=$LASTEXITCODE
  if($code -eq 0 -or $output -notmatch 'FAIL' -or $output -notmatch 'Exception calling' -or $output -match 'Add-Type:'){throw "Mutation not rejected by assertion: $name`n$output"}
  Write-Output ('BUDGET_MUTATION_REJECTED '+$name)
 }finally{Remove-Item -LiteralPath $temp -Recurse -Force}
}
Write-Output 'BUDGET MUTATIONS REJECTED 5'
