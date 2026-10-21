$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$script = Join-Path $root 'scripts/Verify-Bellum148Build.ps1'
function Check($ok, $label) {
    if (-not $ok) { throw "FAIL STAGE9_BUILD_GATE $label" }
    Write-Host "PASS STAGE9_BUILD_GATE $label"
}
function Blocked($gamePath, [int]$expectedExit, [string]$reason, [string]$label) {
    # Execute in a child process to inspect the intentional fail-closed exit code.
    $lines = @(& pwsh -NoProfile -File $script -GameFolder $gamePath -PreflightOnly 2>&1)
    $code = $LASTEXITCODE
    $combined = ($lines | Out-String)
    Check ($code -eq $expectedExit -and
        $combined.Contains("BELLUM148_BUILD blocked reason=$reason") -and
        -not $combined.Contains('BELLUM148_BUILD success')) $label
}
Check (Test-Path -LiteralPath $script) 'script_present'
$temp = Join-Path ([IO.Path]::GetTempPath()) ('bellum148 gate ' + [Guid]::NewGuid().ToString('N'))
$missing = Join-Path $temp 'not-installed'
try {
    Blocked $missing 20 'missing_game_folder' 'missing_game_directory_never_builds'
    [void](New-Item -Path $temp -ItemType Directory -Force)
    Blocked $temp 21 'missing_references' 'incomplete_mod_stack_never_builds'

    # Create files with EXACT csproj dependency names, deliberately NOT real DLLs.
    # Mere existence must not be interpreted as a verified Bannerlord 1.4.8 install.
    [xml]$project = Get-Content -Raw -LiteralPath (Join-Path $root 'BellumCivile.csproj')
    $refs = @($project.Project.ItemGroup.Reference | Where-Object { $_ -and $_.HintPath })
    Check ($refs.Count -ge 15) 'shipping_project_reference_inventory_present'
    foreach ($ref in $refs) {
        $path = ([string]$ref.HintPath).Replace('$(GameFolder)', $temp)
        $path = $path.Replace('\', [IO.Path]::DirectorySeparatorChar)
        $directory = Split-Path -Parent $path
        [void](New-Item -Path $directory -ItemType Directory -Force)
        [IO.File]::WriteAllText($path, 'synthetic test fixture - NOT a Bannerlord game binary')
    }
    Blocked $temp 22 'unverified_game_version' 'fake_dll_names_cannot_pass_native_version_gate'
}
finally {
    if (Test-Path -LiteralPath $temp) {
        Remove-Item -LiteralPath $temp -Recurse -Force
    }
}
Write-Host 'STAGE9_BUILD_GATE_NEGATIVE_PASS — no authentic game assemblies available; real net472 compilation is UNVERIFIED.'
# All expected negative child exit codes were asserted. Do not leak the last code 22
# to GitHub Actions as if this successful negative-suite run had failed.
exit 0
