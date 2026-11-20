# Bellum 1.4.12b / Bannerlord 1.5.7 - Stage 3A beta native settlement/quest hooks.
# Run from extracted source ZIP; collect both baseline and targeted results.
param([Parameter(Mandatory = $true)][string]$GameFolder)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$game = (Resolve-Path -LiteralPath $GameFolder -ErrorAction Stop).ProviderPath
$logs = Join-Path $root 'Bellum157Stage3ALogs'
New-Item -ItemType Directory -Path $logs -Force | Out-Null
$failures = [Collections.Generic.List[string]]::new()
$harness = Join-Path $root 'Tests/SuccessionEngineHarness/bin/Release/net472/SuccessionEngineHarness.exe'
function Step([string]$label,[string]$program,[string[]]$arguments) {
    Write-Host "BELLUM157_STAGE3A begin=$label"
    $output = @(& $program @arguments 2>&1)
    $exitCode = $LASTEXITCODE
    $log = Join-Path $logs "$label.log"
    $output | Set-Content -LiteralPath $log -Encoding UTF8
    $summary = $output | Where-Object { $_ -match 'SOURCE_PASS|ALL_PASS|checks passed\.' } | Select-Object -Last 1
    if ($exitCode -ne 0) {
        $failures.Add($label)
        Write-Host "BELLUM157_STAGE3A FAIL step=$label exit=$exitCode log=$log"
        $output | Select-Object -Last 18 | ForEach-Object { Write-Host $_ }
        return
    }
    Write-Host "BELLUM157_STAGE3A PASS step=$label summary=$summary log=$log"
}
Push-Location $root
try {
    Step 'settlement_abi_contract' 'pwsh' @('-NoProfile','-ExecutionPolicy','Bypass','-File','./Tests/Bellum157SettlementCauseAbi.Tests.ps1')
    # Stage 2D builds the native game module and harness and runs six adjacent suites.
    Step 'complete_stage2d_baseline' 'pwsh' @('-NoProfile','-ExecutionPolicy','Bypass','-File','./scripts/Verify-Bellum157NativeExecutionStage2D.ps1','-GameFolder',$game)
    if (Test-Path -LiteralPath $harness -PathType Leaf) {
        Step 'native_settlement_and_quest_hooks' $harness @($game,'--settlement-cause-labels')
    } else { $failures.Add('native_harness_missing'); Write-Host 'BELLUM157_STAGE3A FAIL harness EXE missing after baseline compilation' }
    if ($failures.Count -gt 0) {
        Write-Host "BELLUM157_STAGE3A FAILURES=$($failures.Count) names=$($failures -join ',')"
        throw 'Stage 3A regression gate failed'
    }
    Write-Host 'BELLUM157_STAGE3A ALL_PASS; compiled_and_native_harmony_harness_verified=true; live_game_save_untested=true'
}
finally { Pop-Location }
