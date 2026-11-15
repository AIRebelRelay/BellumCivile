# Bellum 1.4.12b / Bannerlord 1.5.7 - Stage 3B. Source ZIP, no git required.
# One command: native build, native UI Harmony hook ABI and neighboring fief regressions.
param([Parameter(Mandatory = $true)][string]$GameFolder)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$game = (Resolve-Path -LiteralPath $GameFolder -ErrorAction Stop).ProviderPath
$logs = Join-Path $root 'Bellum157Stage3BLogs'
New-Item -ItemType Directory -Path $logs -Force | Out-Null
$harness = Join-Path $root 'Tests/SuccessionEngineHarness/bin/Release/net472/SuccessionEngineHarness.exe'
$failures = [Collections.Generic.List[string]]::new()
function Step([string]$name,[string]$command,[string[]]$arguments) {
    Write-Host "BELLUM157_STAGE3B begin=$name"
    $lines = @(& $command @arguments 2>&1)
    $status = $LASTEXITCODE
    $log = Join-Path $logs "$name.log"
    $lines | Set-Content -LiteralPath $log -Encoding UTF8
    if ($status -ne 0) {
        $failures.Add($name)
        Write-Host "BELLUM157_STAGE3B FAIL step=$name exit=$status log=$log"
        $lines | Select-Object -Last 22 | ForEach-Object { Write-Host $_ }
        return $false
    }
    $summary = $lines | Where-Object { $_ -match 'SOURCE_PASS|BELLUM157_BUILD success|Build succeeded\.|checks passed\.' } | Select-Object -Last 1
    Write-Host "BELLUM157_STAGE3B PASS step=$name summary=$summary log=$log"
    return $true
}
Push-Location $root
try {
    $contract = Step 'grant_fief_source' 'pwsh' @('-NoProfile','-ExecutionPolicy','Bypass','-File','./Tests/Bellum157GrantFiefClosure.Tests.ps1')
    $native = Step 'native_build' 'pwsh' @('-NoProfile','-ExecutionPolicy','Bypass','-File','./scripts/Verify-Bellum157Build.ps1','-GameFolder',$game)
    $build = Step 'harness_build' 'dotnet' @('build','./Tests/SuccessionEngineHarness/SuccessionEngineHarness.csproj','-c','Release',"-p:GameFolder=$game")
    if ($build -and (Test-Path -LiteralPath $harness -PathType Leaf)) {
        $cases = @(
            @('native_grant_fief_callback','--grant-fief-closure'),
            @('fief_redistribution','--fief-redistribution'),
            @('fief_allocation','--fief-allocation')
        )
        foreach ($case in $cases) { $result = Step $case[0] $harness @($game,$case[1]) }
    }
    else {
        $failures.Add('harness_unavailable')
        Write-Host 'BELLUM157_STAGE3B SKIP runtime tests: harness compilation/executable unavailable'
    }
    if ($failures.Count -gt 0) {
        Write-Host "BELLUM157_STAGE3B FAILURES=$($failures.Count) names=$($failures -join ',')"
        throw 'Stage 3B regression gate failed'
    }
    Write-Host 'BELLUM157_STAGE3B ALL_PASS; runtime_harmony_callback_verified=true; live_game_save_untested=true'
}
finally { Pop-Location }
