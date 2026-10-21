<#
Build the shipping BellumCivile.dll ONLY against a real installed Bannerlord 1.4.8.
Preflight runs without modifications. No downloading, no copying into the game.
Exit: 20 missing GameFolder, 21 absent references, 22 game version mismatch/unverified,
      23 non-Windows build, 24 missing SDK, 25 restore/build failure,
      26 output absent/empty or tracked working tree dirty.
#>
param(
    [string]$GameFolder = $env:GameFolder,
    [switch]$PreflightOnly
)
$ErrorActionPreference = 'Stop'
$repo = Split-Path $PSScriptRoot -Parent
$projectPath = Join-Path $repo 'BellumCivile.csproj'
function Block([string]$reason, [int]$code, [string]$detail) {
    Write-Host "BELLUM148_BUILD blocked reason=$reason detail=$detail"
    exit $code
}
if ([string]::IsNullOrWhiteSpace($GameFolder) -or
    -not (Test-Path -LiteralPath $GameFolder -PathType Container)) {
    Block 'missing_game_folder' 20 'Specify an existing Bannerlord installation via -GameFolder.'
}
$game = (Resolve-Path -LiteralPath $GameFolder).ProviderPath
if (-not (Test-Path -LiteralPath $projectPath -PathType Leaf)) {
    Block 'missing_project' 25 $projectPath
}
# Read EXACT HintPaths declared by shipping BellumCivile.csproj, not a guessed DLL list.
[xml]$proj = Get-Content -Raw -LiteralPath $projectPath
$refs = @($proj.Project.ItemGroup.Reference | Where-Object { $_ -and $_.HintPath })
if ($refs.Count -lt 15) {
    Block 'reference_manifest_incomplete' 21 "Unexpectedly only $($refs.Count) project HintPaths."
}
$missing = @()
foreach ($ref in $refs) {
    $raw = [string]$ref.HintPath
    if (-not $raw.StartsWith('$(GameFolder)', [StringComparison]::OrdinalIgnoreCase)) {
        Block 'unrecognized_reference_path' 21 "$($ref.Include): $raw"
    }
    $expanded = $raw.Replace('$(GameFolder)', $game)
    $expanded = $expanded.Replace('\', [System.IO.Path]::DirectorySeparatorChar)
    if (-not (Test-Path -LiteralPath $expanded -PathType Leaf)) {
        $missing += "$($ref.Include): $expanded"
    }
}
if ($missing.Count -gt 0) {
    foreach ($item in $missing) { Write-Host "BELLUM148_BUILD missing_reference=$item" }
    Block 'missing_references' 21 "$($missing.Count) required shipping dependencies absent."
}
# Require positive version evidence from ORIGINAL installed game binaries.
# AssemblyVersion of some TaleWorlds libraries is stable 1.0.0.0, so prefer
# Windows file ProductVersion/FileVersion. Fail closed if metadata is absent.
$targets = @(
    (Join-Path $game 'bin/Win64_Shipping_Client/TaleWorlds.CampaignSystem.dll'),
    (Join-Path $game 'bin/Win64_Shipping_Client/TaleWorlds.Library.dll'),
    (Join-Path $game 'bin/Win64_Shipping_Client/Bannerlord.exe')
)
$versions = @()
foreach ($target in $targets) {
    if (-not (Test-Path -LiteralPath $target -PathType Leaf)) { continue }
    $v = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($target)
    foreach ($kind in @('ProductVersion', 'FileVersion')) {
        $value = [string]$v.$kind
        if (-not [string]::IsNullOrWhiteSpace($value)) {
            Write-Host "BELLUM148_BUILD version_evidence=$(Split-Path $target -Leaf) $kind=$value"
            $versions += $value
        }
    }
}
$gameVersionPattern = '(?<![0-9])(?:e|v)?1\.(?:4|5)\.[0-9]+'
$gameVersions = @($versions | ForEach-Object {
    [regex]::Matches($_, $gameVersionPattern) | ForEach-Object {
        $found = $_.Value
        $found -replace '^[ev]', ''
    }
} | Select-Object -Unique)
if ($gameVersions.Count -eq 0) {
    Block 'unverified_game_version' 22 'No installed Bannerlord 1.4.8 ProductVersion/FileVersion found.'
}
if ($gameVersions -contains '1.5.5' -or $gameVersions -contains '1.4.5' -or
    @($gameVersions | Where-Object { $_ -ne '1.4.8' }).Count -gt 0) {
    Block 'wrong_game_version' 22 ("Found game version markers: " + ($gameVersions -join ','))
}
if ($gameVersions -notcontains '1.4.8') {
    Block 'unverified_game_version' 22 'Expected installed 1.4.8 version marker.'
}
Write-Host "BELLUM148_PREFLIGHT pass game_version=1.4.8 reference_count=$($refs.Count)"
if ($PreflightOnly) {
    Write-Host 'BELLUM148_PREFLIGHT_ONLY complete; NO shipping DLL was compiled.'
    exit 0
}
if (-not $IsWindows -and $env:OS -ne 'Windows_NT') {
    Block 'windows_build_required' 23 'Use Windows with .NET Framework 4.7.2 targeting support.'
}
if (-not (Get-Command dotnet -ErrorAction SilentlyContinue)) {
    Block 'dotnet_sdk_missing' 24 'Install a .NET SDK capable of building net472 projects.'
}
# Never ship a build made from uncommitted modifications with a misleading HEAD.
if ((Get-Command git -ErrorAction SilentlyContinue) -and
    (Test-Path -LiteralPath (Join-Path $repo '.git'))) {
    Push-Location $repo
    try {
        $dirty = @(& git status --porcelain --untracked-files=no)
        if ($LASTEXITCODE -ne 0 -or $dirty.Count -gt 0) {
            Block 'tracked_sources_dirty' 26 'Commit/revert tracked edits first; building untracked generated outputs is fine.'
        }
        $revision = (& git rev-parse HEAD).Trim()
    } finally { Pop-Location }
} else {
    $revision = 'unverified_checkout'
}
Push-Location $repo
try {
    Write-Host "BELLUM148_BUILD begin head=$revision mode=Release target=net472"
    & dotnet restore ./BellumCivile.csproj "-p:GameFolder=$game"
    if ($LASTEXITCODE -ne 0) { Block 'restore_failed' 25 "dotnet restore exit=$LASTEXITCODE" }
    & dotnet build ./BellumCivile.csproj -c Release --no-restore "-p:GameFolder=$game"
    if ($LASTEXITCODE -ne 0) { Block 'compile_failed' 25 "dotnet build exit=$LASTEXITCODE" }
} finally { Pop-Location }
$output = Join-Path $repo 'bin/Release/net472/BellumCivile.dll'
if (-not (Test-Path -LiteralPath $output -PathType Leaf) -or
    (Get-Item -LiteralPath $output).Length -le 0) {
    Block 'missing_output_dll' 26 $output
}
$hash = (Get-FileHash -LiteralPath $output -Algorithm SHA256).Hash.ToLowerInvariant()
Write-Host "BELLUM148_BUILD success head=$revision game_version=1.4.8 sha256=$hash output=$output"
Write-Host 'BELLUM148_BUILD not_deployed game_save_runtime_untested=true'
