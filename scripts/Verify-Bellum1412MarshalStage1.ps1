# Bellum 1.4.12b Stage 1 validation. Run from extracted GitHub ZIP:
# pwsh -NoProfile -ExecutionPolicy Bypass -File .\scripts\Verify-Bellum1412MarshalStage1.ps1 -GameFolder "F:\..."
param([Parameter(Mandatory = $true)][string]$GameFolder)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$game = (Resolve-Path -LiteralPath $GameFolder -ErrorAction Stop).ProviderPath
$outDir = Join-Path $root 'Bellum1412Stage1Logs'
New-Item -ItemType Directory -Path $outDir -Force | Out-Null
$harness = Join-Path $root 'Tests/SuccessionEngineHarness/bin/Release/net472/SuccessionEngineHarness.exe'
function Invoke-Checked([string]$label, [string]$executable, [string[]]$parameters) {
    Write-Output "BELLUM1412_STAGE1 begin=$label"
    $lines = @(& $executable @parameters 2>&1)
    $status = $LASTEXITCODE
    $logFile = Join-Path $outDir "$label.log"
    $lines | Set-Content -LiteralPath $logFile -Encoding UTF8
    if ($status -ne 0) {
        Write-Output "BELLUM1412_STAGE1 FAIL step=$label exit=$status log=$logFile"
        $lines | Select-Object -Last 25 | ForEach-Object { Write-Output $_ }
        throw "Stage 1 $label failed with exit $status"
    }
    $summary = ($lines | Where-Object { $_ -match 'SOURCE_PASS|Build succeeded\.|BELLUM157_BUILD success|checks passed\.' } | Select-Object -Last 1)
    Write-Output "BELLUM1412_STAGE1 PASS step=$label summary=$summary log=$logFile"
}
Push-Location $root
try {
    Invoke-Checked 'source_contract' 'pwsh' @('-NoProfile','-ExecutionPolicy','Bypass','-File','./Tests/Bellum1412MarshalBattleCap.Tests.ps1')
    Invoke-Checked 'native_build' 'pwsh' @('-NoProfile','-ExecutionPolicy','Bypass','-File','./scripts/Verify-Bellum157Build.ps1','-GameFolder', $game)
    Invoke-Checked 'harness_build' 'dotnet' @('build','./Tests/SuccessionEngineHarness/SuccessionEngineHarness.csproj','-c','Release',"-p:GameFolder=$game")
    if (-not (Test-Path -LiteralPath $harness -PathType Leaf)) { throw "Harness exe missing after successful build: $harness" }
    Invoke-Checked 'marshal_battle_cap' $harness @($game,'--marshal-battle-cap')
    Invoke-Checked 'council_captivity' $harness @($game,'--council-captivity')
    Invoke-Checked 'hostage_pacts' $harness @($game,'--hostage-pacts')
    Write-Output 'BELLUM1412_STAGE1 ALL_PASS; game_save_runtime_untested=true'
}
finally { Pop-Location }
