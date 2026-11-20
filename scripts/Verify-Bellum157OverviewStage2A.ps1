# Stage 2A: targeted repair validation; assumes Stage 1 + Stage 2 release scenarios previously passed.
# Usage: pwsh -NoProfile -ExecutionPolicy Bypass -File .\scripts\Verify-Bellum157OverviewStage2A.ps1 -GameFolder "F:\..."
param([Parameter(Mandatory = $true)][string]$GameFolder)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$game = (Resolve-Path -LiteralPath $GameFolder -ErrorAction Stop).ProviderPath
$logs = Join-Path $root 'Bellum157Stage2ALogs'
New-Item -ItemType Directory -Force -Path $logs | Out-Null
$harness = Join-Path $root 'Tests/SuccessionEngineHarness/bin/Release/net472/SuccessionEngineHarness.exe'
function Invoke-Check([string]$label,[string]$command,[string[]]$arguments) {
    Write-Output "BELLUM157_STAGE2A begin=$label"
    $out = @(& $command @arguments 2>&1)
    $exitCode = $LASTEXITCODE
    $log = Join-Path $logs "$label.log"
    $out | Set-Content -LiteralPath $log -Encoding UTF8
    if ($exitCode -ne 0) {
        Write-Output "BELLUM157_STAGE2A FAIL step=$label exit=$exitCode log=$log"
        $out | Select-Object -Last 30 | ForEach-Object { Write-Output $_ }
        throw "Stage 2A $label failed with exit $exitCode"
    }
    $summary = $out | Where-Object { $_ -match 'SOURCE_PASS|Build succeeded\.|checks passed\.' } | Select-Object -Last 1
    Write-Output "BELLUM157_STAGE2A PASS step=$label summary=$summary log=$log"
}
Push-Location $root
try {
    Invoke-Check 'overview_abi' 'pwsh' @('-NoProfile','-ExecutionPolicy','Bypass','-File','./Tests/Bellum157DiplomacyOverviewHarnessAbi.Tests.ps1')
    Invoke-Check 'harness_build' 'dotnet' @('build','./Tests/SuccessionEngineHarness/SuccessionEngineHarness.csproj','-c','Release',"-p:GameFolder=$game")
    if (-not (Test-Path -LiteralPath $harness -PathType Leaf)) { throw "Harness exe missing after build" }
    Invoke-Check 'client_liberation' $harness @($game,'--client-liberation')
    Invoke-Check 'relation_memories' $harness @($game,'--gameplay-relation-memories')
    Invoke-Check 'client_voluntary_release' $harness @($game,'--client-voluntary-release')
    Write-Output 'BELLUM157_STAGE2A ALL_PASS; previous_stage1_stage2_builds_already_verified=true; in_game_untested=true'
}
finally { Pop-Location }
