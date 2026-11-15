# Bellum native 1.4.12 / Bannerlord 1.5.7 - Stage 3E: ward adulthood and regency safety.
# Replays approved build/regressions then the targeted new source and native checks.
param([Parameter(Mandatory=$true)][string]$GameFolder)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$game = (Resolve-Path -LiteralPath $GameFolder -ErrorAction Stop).ProviderPath
$logs = Join-Path $root 'Bellum157Stage3ELogs'
New-Item -ItemType Directory -Path $logs -Force | Out-Null
$harness = Join-Path $root 'Tests/SuccessionEngineHarness/bin/Release/net472/SuccessionEngineHarness.exe'
Push-Location $root
try {
    Write-Host 'BELLUM157_STAGE3E begin=stage3d_full_regressions'
    & pwsh -NoProfile -ExecutionPolicy Bypass -File './scripts/Verify-Bellum157InitialChildStage3D.ps1' -GameFolder $game 2>&1 |
        Tee-Object -FilePath (Join-Path $logs 'stage3d_full_regressions.log')
    if ($LASTEXITCODE -ne 0) { throw 'Stage 3D baseline failed; stopping Stage 3E.' }

    Write-Host 'BELLUM157_STAGE3E begin=regency_adulthood_source_contract'
    & pwsh -NoProfile -ExecutionPolicy Bypass -File './Tests/RegencyAdulthood.Tests.ps1' 2>&1 |
        Tee-Object -FilePath (Join-Path $logs 'regency_adulthood_source_contract.log')
    if ($LASTEXITCODE -ne 0) { throw 'Regency adulthood source contract failed.' }
    if (-not (Test-Path -LiteralPath $harness -PathType Leaf)) { throw 'Native regression harness was not built.' }

    foreach ($probe in @('regency-adulthood-157', 'regency-settings', 'crown-rebellion-safety', 'internal-instability')) {
        Write-Host "BELLUM157_STAGE3E begin=$probe"
        & $harness $game "--$probe" 2>&1 |
            Tee-Object -FilePath (Join-Path $logs "$probe.log")
        if ($LASTEXITCODE -ne 0) { throw "Stage 3E regression failed: $probe" }
        Write-Host "BELLUM157_STAGE3E PASS step=$probe"
    }
    Write-Host 'BELLUM157_STAGE3E ALL_PASS; stage3c=PASS; stage3d=PASS; regency_adulthood=PASS; live_campaign_save_NOT_RUN=true'
}
finally { Pop-Location }
