#Requires -Version 7.2
# Force launch: pwsh -NoProfile -ExecutionPolicy Bypass -File .\Tests\ForeignCrisisWindow.Tests.ps1
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$temp=Join-Path ([IO.Path]::GetTempPath()) ('crisis-window-'+[guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $temp | Out-Null
try{
 Copy-Item -LiteralPath (Join-Path $root 'Tests/ForeignCrisisWindowHarness/Scenarios.cs.txt') -Destination (Join-Path $temp 'Scenarios.cs')
 Add-Type -Path @((Join-Path $root 'ForeignCrisisBudgetEstimator.cs'),(Join-Path $root 'ForeignCrisisWindowPolicy.cs'),(Join-Path $temp 'Scenarios.cs')) -CompilerOptions '/langversion:7.3'
 [ForeignCrisisWindowScenarios]::Run()
}finally{Remove-Item -LiteralPath $temp -Recurse -Force}
