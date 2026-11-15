# Bellum 1.4.12b / Bannerlord 1.5.7 Stage 2C.
# Audit all neighboring test groups in one run; collect independent failures rather than fail fast.
param([Parameter(Mandatory = $true)][string]$GameFolder)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$game = (Resolve-Path -LiteralPath $GameFolder -ErrorAction Stop).ProviderPath
$logs = Join-Path $root 'Bellum157Stage2CLogs'
New-Item -ItemType Directory -Path $logs -Force | Out-Null
$failures = [Collections.Generic.List[string]]::new()
$harness = Join-Path $root 'Tests/SuccessionEngineHarness/bin/Release/net472/SuccessionEngineHarness.exe'
function Step([string]$label,[string]$command,[string[]]$arguments) {
    Write-Output "BELLUM157_STAGE2C begin=$label"
    $output = @(& $command @arguments 2>&1)
    $exitCode = $LASTEXITCODE
    $log = Join-Path $logs "$label.log"
    $output | Set-Content -LiteralPath $log -Encoding UTF8
    $summary = $output | Where-Object { $_ -match 'SOURCE_PASS|BELLUM157_BUILD success|checks passed\.|Build succeeded\.' } | Select-Object -Last 1
    if ($exitCode -ne 0) {
        $failures.Add($label)
        Write-Output "BELLUM157_STAGE2C FAIL step=$label exit=$exitCode log=$log"
        $output | Select-Object -Last 12 | ForEach-Object { Write-Output $_ }
        return $false
    }
    Write-Output "BELLUM157_STAGE2C PASS step=$label summary=$summary log=$log"
    return $true
}
Push-Location $root
try {
    $contract = Step 'donation_abi_contract' 'pwsh' @('-NoProfile','-ExecutionPolicy','Bypass','-File','./Tests/Bellum157PrisonerDonationAbi.Tests.ps1')
    $native = Step 'native_build' 'pwsh' @('-NoProfile','-ExecutionPolicy','Bypass','-File','./scripts/Verify-Bellum157Build.ps1','-GameFolder',$game)
    $build = Step 'harness_build' 'dotnet' @('build','./Tests/SuccessionEngineHarness/SuccessionEngineHarness.csproj','-c','Release',"-p:GameFolder=$game")
    if (!$build -or !(Test-Path -LiteralPath $harness -PathType Leaf)) {
        $failures.Add('harness_runtime_skipped')
        Write-Output 'BELLUM157_STAGE2C SKIP native harness tests because build/EXE is unavailable'
    }
    else {
        $groups = @(
            @('relation_memories','--gameplay-relation-memories'),
            @('expulsion_relations','--expulsion-relations'),
            @('client_release','--client-voluntary-release'),
            @('client_liberation','--client-liberation'),
            @('council_captivity','--council-captivity'),
            @('hostage_pacts','--hostage-pacts')
        )
        foreach ($group in $groups) {
            $result = Step $group[0] $harness @($game,$group[1])
        }
    }
    if ($failures.Count -gt 0) {
        Write-Output "BELLUM157_STAGE2C FAILURES=$($failures.Count) names=$($failures -join ',')"
        throw 'Stage 2C regression gate failed; inspect logs for all independent failures'
    }
    Write-Output 'BELLUM157_STAGE2C ALL_PASS; native_build_and_behavioural_harness_verified=true; live_game_save_not_verified=true'
}
finally { Pop-Location }
