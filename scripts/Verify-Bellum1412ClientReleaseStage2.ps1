# Bellum 1.4.12b Stage 2: one-command port, ABI and adjacent-system regression gate.
# Usage (from extracted source ZIP): pwsh -NoProfile -ExecutionPolicy Bypass -File .\scripts\Verify-Bellum1412ClientReleaseStage2.ps1 -GameFolder "F:\..."
param([Parameter(Mandatory = $true)][string]$GameFolder)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$game = (Resolve-Path -LiteralPath $GameFolder -ErrorAction Stop).ProviderPath
$logs = Join-Path $root 'Bellum1412Stage2Logs'
New-Item -ItemType Directory -Path $logs -Force | Out-Null
$harness = Join-Path $root 'Tests/SuccessionEngineHarness/bin/Release/net472/SuccessionEngineHarness.exe'
function Run-Stage([string]$label, [string]$program, [string[]]$arguments) {
    Write-Output "BELLUM1412_STAGE2 begin=$label"
    $lines = @(& $program @arguments 2>&1)
    $status = $LASTEXITCODE
    $log = Join-Path $logs "$label.log"
    $lines | Set-Content -LiteralPath $log -Encoding UTF8
    if ($status -ne 0) {
        Write-Output "BELLUM1412_STAGE2 FAIL step=$label exit=$status log=$log"
        $lines | Select-Object -Last 35 | ForEach-Object { Write-Output $_ }
        throw "Bellum 1.4.12b Stage 2 $label failed, exit=$status"
    }
    $summary = ($lines | Where-Object { $_ -match 'SOURCE_PASS|ALL_PASS|checks passed\.|Build succeeded\.' } | Select-Object -Last 1)
    Write-Output "BELLUM1412_STAGE2 PASS step=$label summary=$summary log=$log"
}
Push-Location $root
try {
    Run-Stage 'client_release_contract' 'pwsh' @('-NoProfile','-ExecutionPolicy','Bypass','-File','./Tests/Bellum1412ClientRelease.Tests.ps1')
    # The prior complete stage remains the positive/negative regression baseline.
    Run-Stage 'stage1_baseline' 'pwsh' @('-NoProfile','-ExecutionPolicy','Bypass','-File','./scripts/Verify-Bellum1412MarshalStage1.ps1','-GameFolder',$game)
    if (-not (Test-Path -LiteralPath $harness -PathType Leaf)) { throw "Missing harness after compilation: $harness" }
    Run-Stage 'client_voluntary_release' $harness @($game,'--client-voluntary-release')
    Run-Stage 'starting_clientage' $harness @($game,'--starting-clientage')
    Run-Stage 'client_liberation' $harness @($game,'--client-liberation')
    Run-Stage 'relation_memories' $harness @($game,'--gameplay-relation-memories')
    Write-Output 'BELLUM1412_STAGE2 ALL_PASS; game_save_runtime_untested=true'
}
finally { Pop-Location }
