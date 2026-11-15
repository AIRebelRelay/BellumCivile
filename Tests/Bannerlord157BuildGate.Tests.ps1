<#
Regression-first, fail-closed game build gate tests for Bannerlord 1.5.7.
No real DLL compilation and no writes outside a disposable temp fixture.
Run: pwsh -NoProfile -File .\Tests\Bannerlord157BuildGate.Tests.ps1
Optional: -InstalledGameFolder <real Bannerlord 1.5.7 install> for positive preflight.
#>
param([string]$InstalledGameFolder = '')
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$script = Join-Path $root 'scripts/Verify-Bellum157Build.ps1'
$legacy = Join-Path $root 'scripts/Verify-Bellum148Build.ps1'
$engine = Get-Command pwsh -ErrorAction SilentlyContinue
if (-not $engine) { $engine = Get-Command powershell -ErrorAction SilentlyContinue }
if (-not $engine) { throw 'BELLUM157_TEST blocked reason=powershell_unavailable' }
function Check([bool]$ok, [string]$label) {
    if (-not $ok) { throw "FAIL BELLUM157_BUILD_GATE $label" }
    Write-Host "PASS BELLUM157_BUILD_GATE $label"
}
function RunPreflight([string]$game) {
    $lines = @(& $engine.Source -NoProfile -File $script -GameFolder $game -PreflightOnly 2>&1)
    $code = $LASTEXITCODE
    return @{ Code=$code; Output=($lines | Out-String) }
}
function Blocked([string]$game, [int]$expectedExit, [string]$reason, [string]$label) {
    $result = RunPreflight $game
    Check ($result.Code -eq $expectedExit -and
        $result.Output.Contains("BELLUM157_BUILD blocked reason=$reason") -and
        -not $result.Output.Contains('BELLUM157_BUILD success') -and
        -not $result.Output.Contains('BELLUM157_PREFLIGHT pass')) $label
}
Check (Test-Path -LiteralPath $script -PathType Leaf) 'new_157_script_present'
Check (Test-Path -LiteralPath $legacy -PathType Leaf) 'legacy_148_script_present'
$legacyText = Get-Content -Raw -LiteralPath $legacy
Check ($legacyText.Contains('BELLUM148_BUILD') -and $legacyText.Contains('1.4.8')) 'legacy_148_unchanged_contract'
$source = Get-Content -Raw -LiteralPath $script
Check ($source.Contains('BELLUM157_BUILD') -and $source.Contains('1.5.7') -and
    $source.Contains('GetVersionInfo') -and $source.Contains('GetAssemblyName') -and
    $source.Contains('PreflightOnly') -and $source.Contains('dotnet restore') -and
    $source.Contains('dotnet build')) 'real_157_version_and_build_contract'
$temp = Join-Path ([IO.Path]::GetTempPath()) ('bellum157 gate ' + [Guid]::NewGuid().ToString('N'))
try {
    Blocked (Join-Path $temp 'not-installed') 20 'missing_game_folder' 'absent_game_never_builds'
    [void](New-Item -Path $temp -ItemType Directory -Force)
    Blocked $temp 21 'missing_references' 'incomplete_dependency_stack_never_builds'

    # All paths come from the shipping csproj; synthetic files are intentionally NOT valid DLLs.
    [xml]$project = Get-Content -Raw -LiteralPath (Join-Path $root 'BellumCivile.csproj')
    $refs = @($project.Project.ItemGroup.Reference | Where-Object { $_ -and $_.HintPath })
    Check ($refs.Count -ge 15) 'shipping_csproj_reference_inventory_present'
    foreach ($ref in $refs) {
        $name = [string]$ref.Include
        if ($name -eq '0Harmony') {
            $path = Join-Path $temp 'Modules/Bannerlord.Harmony/bin/Win64_Shipping_Client/0Harmony.dll'
        } elseif ($name -eq 'Bannerlord.UIExtenderEx') {
            $path = Join-Path $temp 'Modules/Bannerlord.UIExtenderEx/bin/Win64_Shipping_Client/Bannerlord.UIExtenderEx.dll'
        } else {
            $path = ([string]$ref.HintPath).Replace('$(GameFolder)', $temp)
        }
        $path = $path.Replace('\', [IO.Path]::DirectorySeparatorChar)
        [void](New-Item -ItemType Directory -Path (Split-Path $path -Parent) -Force)
        [IO.File]::WriteAllText($path, 'synthetic fixture, not a managed .NET assembly')
    }
    Blocked $temp 22 'missing_game_version_manifest' 'binary_names_alone_not_enough'

    foreach ($moduleName in @('Native', 'SandBoxCore', 'Sandbox', 'StoryMode')) {
        $path = Join-Path $temp "Modules/$moduleName/SubModule.xml"
        [void](New-Item -ItemType Directory -Path (Split-Path $path -Parent) -Force)
        [IO.File]::WriteAllText($path, '<Module><Version value="v1.4.8"/></Module>')
    }
    Blocked $temp 22 'wrong_game_version' 'rejects_148_despite_reference_names'

    foreach ($moduleName in @('Native', 'SandBoxCore', 'Sandbox', 'StoryMode')) {
        $path = Join-Path $temp "Modules/$moduleName/SubModule.xml"
        [IO.File]::WriteAllText($path, '<Module><Version value="v1.5.7"/></Module>')
    }
    Blocked $temp 22 'invalid_managed_reference' 'rejects_fake_dlls_despite_157_manifests'

    if (-not [string]::IsNullOrWhiteSpace($InstalledGameFolder)) {
        $positive = RunPreflight $InstalledGameFolder
        Check ($positive.Code -eq 0 -and
            $positive.Output.Contains('BELLUM157_PREFLIGHT pass game_version=1.5.7') -and
            $positive.Output.Contains('BELLUM157_PREFLIGHT_ONLY complete') -and
            -not $positive.Output.Contains('BELLUM157_BUILD success')) 'authentic_157_positive_preflight'
    } else {
        Write-Host 'BELLUM157_BUILD_GATE positive_real_game=NOT_RUN reason=no_InstalledGameFolder'
    }
}
finally {
    if (Test-Path -LiteralPath $temp) {
        Remove-Item -LiteralPath $temp -Recurse -Force
    }
}
Write-Host 'BELLUM157_BUILD_GATE NEGATIVE_PASS actual_compile=NOT_RUN'
exit 0
