<#
Stage32H2H: one-command regression + strict shipping build GATE (Windows).
DOES NOT copy DLL into Modules, touch save files, run game, merge or publish.
Requires PowerShell 7+, git and installed Bannerlord EXACT 1.4.8.
The existing scripts/Verify-Bellum148Build.ps1 is the only build owner.
#>
param(
    [string]$GameFolder = $env:GameFolder
)
$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
$requiredBranch = 'feature/stage32h2h-native-partition-notice-origin-2026-11-01'
$requiredSourceAncestor = '90b0c2c1401a740c6c984f929b965e136f892c58'
$qaFolder = Join-Path ([System.IO.Path]::GetTempPath()) 'AIInfluence-Bellum-H2H-QA'
[System.IO.Directory]::CreateDirectory($qaFolder) | Out-Null
$stamp = [DateTime]::UtcNow.ToString('yyyyMMdd-HHmmss', [Globalization.CultureInfo]::InvariantCulture)
$qaLog = Join-Path $qaFolder ("Stage32H2H-" + $stamp + ".txt")
$transcriptStarted = $false
$failed = $false
try {
    Start-Transcript -LiteralPath $qaLog -ErrorAction Stop | Out-Null
    $transcriptStarted = $true
    Write-Host "STAGE32H2H_GATE begin transcript=$qaLog"
    if ($PSVersionTable.PSVersion.Major -lt 7) {
        throw "PowerShell 7+ (pwsh) required for Add-Type C# harness; Windows PowerShell 5.1 is not sufficient."
    }
    foreach ($name in @('git', 'dotnet', 'pwsh')) {
        if (-not (Get-Command $name -ErrorAction SilentlyContinue)) {
            throw "Required command missing: $name"
        }
    }
    if (-not (Test-Path -LiteralPath (Join-Path $repo '.git'))) {
        throw "Git checkout required; source ZIP cannot prove pinned branch and HEAD."
    }
    Push-Location $repo
    try {
        $branch = (& git branch --show-current).Trim()
        if ($LASTEXITCODE -ne 0 -or $branch -cne $requiredBranch) {
            throw "Wrong Native branch: $branch (expected $requiredBranch)"
        }
        $head = (& git rev-parse HEAD).Trim()
        if ($LASTEXITCODE -ne 0) { throw "Git HEAD unavailable" }
        & git merge-base --is-ancestor $requiredSourceAncestor HEAD
        if ($LASTEXITCODE -ne 0) {
            throw "Wrong source ancestry: H2H protected commit $requiredSourceAncestor not in HEAD=$head"
        }
        $dirty = @(& git status --porcelain --untracked-files=no)
        if ($LASTEXITCODE -ne 0 -or $dirty.Count -gt 0) {
            throw "Tracked changes detected; commit/revert them before H2H verification."
        }
    } finally { Pop-Location }
    Write-Host "STAGE32H2H_GATE pinned_repo=Native branch=$branch head=$head"

    # Reuse the repo's exact 1.4.8 ABI/HintPath validator.
    $buildVerifier = Join-Path $repo 'scripts/Verify-Bellum148Build.ps1'
    if (-not (Test-Path -LiteralPath $buildVerifier)) { throw "Native 1.4.8 build verifier missing." }
    & pwsh -NoProfile -File $buildVerifier -GameFolder $GameFolder -PreflightOnly
    if ($LASTEXITCODE -ne 0) { throw "Bannerlord 1.4.8 preflight failed (exit=$LASTEXITCODE)." }
    Write-Host "STAGE32H2H_GATE version_and_references=PASS"

    # Red-first H2H regressions, actual real-code Add-Type behavior test,
    # and existing adjacent inheritance/Crown/succession controls.
    $tests = @(
        'Tests/Stage32H2HPartitionNoticeOrigin.Tests.ps1',
        'Tests/Stage32H2HPartitionNoticeScopeHarness.ps1',
        'Tests/CrossClanEstate.Tests.ps1',
        'Tests/EstateInheritanceDisplay.Tests.ps1',
        'Tests/CrownAccessionNotices.Tests.ps1',
        'Tests/InheritanceAllocationCustody.Tests.ps1',
        'Tests/SuccessionDispatch.Tests.ps1',
        'Tests/InheritedPossession.Tests.ps1'
    )
    foreach ($relative in $tests) {
        $testPath = Join-Path $repo $relative
        if (-not (Test-Path -LiteralPath $testPath)) { throw "Test file missing: $relative" }
        Write-Host "STAGE32H2H_GATE test_begin=$relative"
        & pwsh -NoProfile -File $testPath
        if ($LASTEXITCODE -ne 0) { throw "Regression test failed: $relative (exit=$LASTEXITCODE)." }
        Write-Host "STAGE32H2H_GATE test_pass=$relative"
    }

    Write-Host "STAGE32H2H_GATE build_begin game_version=1.4.8"
    & pwsh -NoProfile -File $buildVerifier -GameFolder $GameFolder
    if ($LASTEXITCODE -ne 0) { throw "Native shipping build failed (exit=$LASTEXITCODE)." }
    Write-Host "STAGE32H2H_VERIFY_PASS head=$head source_tests=$($tests.Count) game_build=1.4.8"
    Write-Host "STAGE32H2H_GATE runtime_untested=true save_rollback_untested=true bridge_postfix_untested=true release_go=false"
}
catch {
    $failed = $true
    Write-Host ("STAGE32H2H_VERIFY_FAIL reason=" + $_.Exception.Message)
}
finally {
    if ($transcriptStarted) { Stop-Transcript | Out-Null }
    Write-Host "STAGE32H2H_GATE transcript=$qaLog"
}
if ($failed) { exit 1 }
exit 0
