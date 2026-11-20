# Bellum 1.4.12b / Bannerlord 1.5.7 - Complete SeparateSpouse stage 3C.
# Single ZIP-source PowerShell entrypoint: compile once, then run independent regression groups.
param([Parameter(Mandatory=$true)][string]$GameFolder)
$ErrorActionPreference='Stop'
$root=Split-Path -Parent $PSScriptRoot
$game=(Resolve-Path -LiteralPath $GameFolder -ErrorAction Stop).ProviderPath
$logs=Join-Path $root 'Bellum157Stage3CLogs'
New-Item -ItemType Directory -Path $logs -Force | Out-Null
$harness=Join-Path $root 'Tests/SuccessionEngineHarness/bin/Release/net472/SuccessionEngineHarness.exe'
$failures=[Collections.Generic.List[string]]::new()
function Step([string]$name,[string]$command,[string[]]$arguments) {
    Write-Host "BELLUM157_STAGE3C begin=$name"
    $output=@(& $command @arguments 2>&1)
    $exitCode=$LASTEXITCODE
    $log=Join-Path $logs "$name.log"
    $output | Set-Content -LiteralPath $log -Encoding UTF8
    if($exitCode -ne 0) {
        $failures.Add($name)
        Write-Host "BELLUM157_STAGE3C FAIL step=$name exit=$exitCode log=$log"
        $output | Select-Object -Last 20 | ForEach-Object { Write-Host $_ }
        return $false
    }
    $summary=$output | Where-Object { $_ -match 'SOURCE_PASS|Source contracts only|BUILD success|Build succeeded\.|checks passed\.' } | Select-Object -Last 1
    Write-Host "BELLUM157_STAGE3C PASS step=$name summary=$summary log=$log"
    return $true
}
Push-Location $root
try {
    $source=Step 'spouse_source_contract' 'pwsh' @('-NoProfile','-ExecutionPolicy','Bypass','-File','./Tests/Bellum157SeparateSpouseStage3C.Tests.ps1')
    $neighbor=Step 'existing_spouse_source_contract' 'pwsh' @('-NoProfile','-ExecutionPolicy','Bypass','-File','./Tests/SpouseHousehold.Tests.ps1')
    if(-not $source -or -not $neighbor) {
        throw 'Stage 3C source contracts failed; no production build attempted'
    }
    $native=Step 'native_build' 'pwsh' @('-NoProfile','-ExecutionPolicy','Bypass','-File','./scripts/Verify-Bellum157Build.ps1','-GameFolder',$game)
    $compiled=Step 'harness_build' 'dotnet' @('build','./Tests/SuccessionEngineHarness/SuccessionEngineHarness.csproj','-c','Release',"-p:GameFolder=$game")
    if($compiled -and (Test-Path -LiteralPath $harness -PathType Leaf)) {
        $cases=@(
            @('separate_spouse_157','--separate-spouse-157'),
            @('marriage_households','--marriage-households'),
            @('marriage_heiress','--marriage-heiress-simulation'),
            @('cadet_households','--cadet-household-preparation'),
            @('grant_fief','--grant-fief-closure'),
            @('fief_redistribution','--fief-redistribution'),
            @('fief_allocation','--fief-allocation'),
            @('settlement_causes','--settlement-cause-labels'),
            @('relation_memories','--gameplay-relation-memories'),
            @('expulsion_relations','--expulsion-relations'),
            @('client_release','--client-voluntary-release'),
            @('client_liberation','--client-liberation'),
            @('council_captivity','--council-captivity'),
            @('hostage_pacts','--hostage-pacts')
        )
        foreach($case in $cases) { $passed=Step $case[0] $harness @($game,$case[1]) }
    } else {
        $failures.Add('harness_unavailable')
        Write-Host 'BELLUM157_STAGE3C SKIP behavioral suites: native harness unavailable'
    }
    if($failures.Count -gt 0) {
        Write-Host "BELLUM157_STAGE3C FAILURES=$($failures.Count) names=$($failures -join ',')"
        throw 'Stage 3C regression gate failed; inspect independent logs'
    }
    Write-Host 'BELLUM157_STAGE3C ALL_PASS; native_build_and_regression_harness_verified=true; live_campaign_save_NOT_RUN=true'
}
finally { Pop-Location }
