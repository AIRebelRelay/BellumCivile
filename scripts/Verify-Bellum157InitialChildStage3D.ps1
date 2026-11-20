# Bellum 1.4.12 / Bannerlord 1.5.7 - Stage 3D: starting-child adulthood-age compatibility.
# One Windows command replays Stage 3C build/regressions, then runs the new native-IL harness.
param([Parameter(Mandatory=$true)][string]$GameFolder)
$ErrorActionPreference='Stop'
$root=Split-Path -Parent $PSScriptRoot
$game=(Resolve-Path -LiteralPath $GameFolder -ErrorAction Stop).ProviderPath
$logs=Join-Path $root 'Bellum157Stage3DLogs'
New-Item -ItemType Directory -Path $logs -Force | Out-Null
$harness=Join-Path $root 'Tests/SuccessionEngineHarness/bin/Release/net472/SuccessionEngineHarness.exe'
Push-Location $root
try {
    Write-Host 'BELLUM157_STAGE3D begin=stage3c_full_regressions'
    & pwsh -NoProfile -ExecutionPolicy Bypass -File './scripts/Verify-Bellum157SeparateSpouseStage3C.ps1' -GameFolder $game 2>&1 |
        Tee-Object -FilePath (Join-Path $logs 'stage3c_full_regressions.log')
    if($LASTEXITCODE -ne 0) { throw 'Stage 3C baseline failed; Stage 3D must not pass.' }
    if(-not (Test-Path -LiteralPath $harness -PathType Leaf)) { throw 'Native regression harness not built.' }
    Write-Host 'BELLUM157_STAGE3D begin=initial_child_age_native'
    & $harness $game '--initial-child-age-157' 2>&1 |
        Tee-Object -FilePath (Join-Path $logs 'initial_child_age_native.log')
    if($LASTEXITCODE -ne 0) { throw 'Stage 3D native initial-child regression failed.' }
    Write-Host 'BELLUM157_STAGE3D ALL_PASS; stage3c=PASS; starting_children=PASS; live_campaign_save_NOT_RUN=true'
}
finally { Pop-Location }
