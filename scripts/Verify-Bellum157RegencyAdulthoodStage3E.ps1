# Bellum native 1.4.12 / Bannerlord 1.5.7 - Stage 3E: regency adulthood regressions.
# Execute independent checks and aggregate failures instead of exposing one failure per ZIP.
param([Parameter(Mandatory=$true)][string]$GameFolder)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$game = (Resolve-Path -LiteralPath $GameFolder -ErrorAction Stop).ProviderPath
$logs = Join-Path $root 'Bellum157Stage3ELogs'
New-Item -ItemType Directory -Path $logs -Force | Out-Null
$harness = Join-Path $root 'Tests/SuccessionEngineHarness/bin/Release/net472/SuccessionEngineHarness.exe'
$failures = [Collections.Generic.List[string]]::new()

function Check-Probe([string]$name, [string]$executable, [string[]]$arguments) {
    Write-Host "BELLUM157_STAGE3E begin=$name"
    & $executable @arguments 2>&1 | Tee-Object -FilePath (Join-Path $logs "$name.log")
    $code = $LASTEXITCODE
    if ($code -ne 0) {
        $failures.Add($name)
        Write-Host "BELLUM157_STAGE3E FAIL step=$name exit=$code"
    } else {
        Write-Host "BELLUM157_STAGE3E PASS step=$name"
    }
}
function Stop-On-Failures([string]$stage) {
    if ($failures.Count -gt 0) {
        Write-Host "BELLUM157_STAGE3E FAILURES=$($failures.Count) names=$($failures -join ',')"
        throw "Stage 3E $stage failed; inspect all independent logs."
    }
}
Push-Location $root
try {
    # Source contracts first: reject stale fixture expectations before any costly build.
    Check-Probe 'regency_adulthood_source_contract' 'pwsh' @('-NoProfile','-ExecutionPolicy','Bypass','-File','./Tests/RegencyAdulthood.Tests.ps1')
    Check-Probe 'internal_instability_source_contract' 'pwsh' @('-NoProfile','-ExecutionPolicy','Bypass','-File','./Tests/InternalInstability.Tests.ps1')
    Stop-On-Failures 'source contracts'

    Write-Host 'BELLUM157_STAGE3E begin=stage3d_full_regressions'
    & pwsh -NoProfile -ExecutionPolicy Bypass -File './scripts/Verify-Bellum157InitialChildStage3D.ps1' -GameFolder $game 2>&1 |
        Tee-Object -FilePath (Join-Path $logs 'stage3d_full_regressions.log')
    if ($LASTEXITCODE -ne 0) { throw 'Stage 3D baseline failed; no valid native harness.' }
    if (-not (Test-Path -LiteralPath $harness -PathType Leaf)) { throw 'Native regression harness was not built.' }

    # Each native probe runs in a fresh process; no failing case hides the following ones.
    foreach ($probe in @('regency-adulthood-157', 'regency-settings', 'crown-rebellion-safety', 'internal-instability')) {
        Check-Probe $probe $harness @($game, "--$probe")
    }
    Stop-On-Failures 'native regressions'
    Write-Host 'BELLUM157_STAGE3E ALL_PASS; stage3c=PASS; stage3d=PASS; regency_adulthood=PASS; related_regressions=PASS; live_campaign_save_NOT_RUN=true'
}
finally { Pop-Location }
