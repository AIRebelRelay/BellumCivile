# P0-14F regression-first: actual preflight game-version code runs on isolated fake module manifests.
# No game DLL, install, restore or build is touched by this fixture.
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$source = Get-Content -LiteralPath (Join-Path $root 'scripts/Verify-Bellum148Build.ps1') -Raw
$start = $source.IndexOf('# Require positive version evidence', [StringComparison]::Ordinal)
$end = $source.IndexOf('Write-Host "BELLUM148_PREFLIGHT pass', [StringComparison]::Ordinal)
if ($start -lt 0 -or $end -le $start) { throw 'P014F_FAIL version_source_boundary' }
$probeCode = $source.Substring($start, $end - $start)
$probe = [ScriptBlock]::Create($probeCode)
if (-not $probeCode.Contains('Modules/$moduleName/SubModule.xml') -or
    -not $probeCode.Contains('missing_game_version_manifest') -or
    -not $probeCode.Contains('invalid_game_version_manifest') -or
    -not $probeCode.Contains('wrong_game_version')) { throw 'P014F_FAIL version_contract_not_present' }
function Block([string]$reason, [int]$code, [string]$detail) {
    throw "VERSION_REJECT reason=$reason code=$code detail=$detail"
}
function Invoke-Probe([string]$gamePath) {
    $game = $gamePath
    . $probe
    return @($gameVersions)
}
function Expect-Rejected([string]$reason) {
    try {
        $null = Invoke-Probe $fixture
        throw "Unexpected pass: $reason"
    }
    catch {
        if (-not $_.Exception.Message.Contains("VERSION_REJECT reason=$reason code=22")) {
            throw "P014F_FAIL expected=$reason actual=$($_.Exception.Message)"
        }
        Write-Host "P014F_PASS rejected_$reason"
    }
}
$fixture = Join-Path ([IO.Path]::GetTempPath()) ('Bellum-P014F-' + [Guid]::NewGuid().ToString('N'))
$modules = @('Native', 'SandBoxCore', 'Sandbox', 'StoryMode')
function Set-ModuleVersion([string]$name, [string]$version) {
    $dir = Join-Path $fixture "Modules/$name"
    [IO.Directory]::CreateDirectory($dir) | Out-Null
    Set-Content -LiteralPath (Join-Path $dir 'SubModule.xml') -Value ('<Module><Version value="' + $version + '" /></Module>') -Encoding UTF8
}
try {
    foreach ($m in $modules) { Set-ModuleVersion $m 'v1.4.8' }
    $seen = @(Invoke-Probe $fixture)
    if ($seen.Count -ne 1 -or $seen[0] -cne '1.4.8') {
        throw "P014F_FAIL all_four_148 seen=$($seen -join ',')"
    }
    Write-Host 'P014F_PASS all_four_148_generic_or_missing_pe_metadata'
    Set-ModuleVersion 'Sandbox' 'v1.4.9'
    Expect-Rejected 'wrong_game_version'
    Set-ModuleVersion 'Sandbox' 'v1.4.8'
    Remove-Item -LiteralPath (Join-Path $fixture 'Modules/StoryMode/SubModule.xml')
    Expect-Rejected 'missing_game_version_manifest'
    Set-ModuleVersion 'StoryMode' 'v1.4.8'
    Set-Content -LiteralPath (Join-Path $fixture 'Modules/StoryMode/SubModule.xml') -Value '<Module><Version' -Encoding UTF8
    Expect-Rejected 'invalid_game_version_manifest'
    Set-ModuleVersion 'StoryMode' 'unknown'
    Expect-Rejected 'unverified_game_version'
    Set-ModuleVersion 'StoryMode' 'v1.4.8'
    Write-Host 'P014F_SOURCE_AND_FIXTURE_PASS: Windows shipping build/game/save QA still pending.'
}
finally {
    if (Test-Path -LiteralPath $fixture) {
        Remove-Item -LiteralPath $fixture -Recurse -Force
    }
}
