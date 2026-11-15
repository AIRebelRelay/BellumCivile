# Bellum 1.4.12b / Bannerlord 1.5.7 - Stage 2D.
# One entrypoint for the new native death hook and all Stage 2C neighboring regression groups.
param([Parameter(Mandatory = $true)][string]$GameFolder)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$game = (Resolve-Path -LiteralPath $GameFolder -ErrorAction Stop).ProviderPath
$logs = Join-Path $root 'Bellum157Stage2DLogs'
New-Item -ItemType Directory -Path $logs -Force | Out-Null
Push-Location $root
try {
    Write-Host 'BELLUM157_STAGE2D begin=execution_hook_contract'
    $result = @(& pwsh -NoProfile -ExecutionPolicy Bypass -File './Tests/Bellum157NativeExecutionContext.Tests.ps1' 2>&1)
    $code = $LASTEXITCODE
    $log = Join-Path $logs 'execution_hook_contract.log'
    $result | Set-Content -LiteralPath $log -Encoding UTF8
    if ($code -ne 0) {
        Write-Host "BELLUM157_STAGE2D FAIL step=execution_hook_contract exit=$code log=$log"
        $result | Select-Object -Last 15 | ForEach-Object { Write-Host $_ }
        throw 'Stage 2D execution hook source contract failed'
    }
    Write-Host "BELLUM157_STAGE2D PASS step=execution_hook_contract checks=21 log=$log"
    Write-Host 'BELLUM157_STAGE2D begin=complete_neighbor_suite'
    $result = @(& pwsh -NoProfile -ExecutionPolicy Bypass -File './scripts/Verify-Bellum157RelationAbiStage2C.ps1' -GameFolder $game 2>&1)
    $code = $LASTEXITCODE
    $log = Join-Path $logs 'complete_neighbor_suite.log'
    $result | Set-Content -LiteralPath $log -Encoding UTF8
    $result | ForEach-Object { Write-Host $_ }
    if ($code -ne 0) {
        Write-Host "BELLUM157_STAGE2D FAIL step=complete_neighbor_suite exit=$code log=$log"
        throw 'Stage 2D neighboring regression suite failed; review all reported failures'
    }
    Write-Host 'BELLUM157_STAGE2D ALL_PASS; native_build_and_harness_verified=true; live_game_save_untested=true'
}
finally { Pop-Location }
