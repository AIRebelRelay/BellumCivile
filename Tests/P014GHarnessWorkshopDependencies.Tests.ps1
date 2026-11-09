# P0-14G regression-first: evaluate actual MSBuild hint path properties, without building or touching the game.
# Covers Workshop-only, mixed Modules/Workshop, Modules priority, explicit overrides and decoy mod exclusion.
$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
$project = Join-Path $repo 'Tests/SuccessionEngineHarness/SuccessionEngineHarness.csproj'
$source = Get-Content -LiteralPath $project -Raw
$names = @('HarmonyDllPath', 'UIExtenderExDllPath', 'McmDllPath')
$components = @(
    @{ Name='HarmonyDllPath'; Module='Bannerlord.Harmony'; Dll='0Harmony.dll'; Id='2859188632' },
    @{ Name='UIExtenderExDllPath'; Module='Bannerlord.UIExtenderEx'; Dll='Bannerlord.UIExtenderEx.dll'; Id='2859222409' },
    @{ Name='McmDllPath'; Module='Bannerlord.MBOptionScreen'; Dll='MCMv5.dll'; Id='2859238197' }
)
function Check([bool]$condition, [string]$name) {
    if (-not $condition) { throw "P014G_FAIL $name" }
    Write-Host "P014G_PASS $name"
}
foreach ($c in $components) {
    Check ($source.Contains('$(GameFolder)/Modules/' + $c.Module) -and
        $source.Contains('workshop/content/261550/' + $c.Id) -and
        $source.Contains('$(' + $c.Name + ')') -and
        $source.Contains('Exists(')) ("contract_" + $c.Name)
}
Check (-not $source.Contains('3720376888')) 'decoy_mod_not_referenced'
if (-not (Get-Command dotnet -ErrorAction SilentlyContinue)) {
    throw 'P014G_FAIL dotnet SDK required to evaluate actual MSBuild properties'
}
$fixture = Join-Path ([IO.Path]::GetTempPath()) ('BellumP014G-' + [Guid]::NewGuid().ToString('N'))
$steam = Join-Path $fixture 'steamapps'
$game = Join-Path $steam 'common/Mount & Blade II Bannerlord'
$workshop = Join-Path $steam 'workshop/content/261550'
[IO.Directory]::CreateDirectory($game) | Out-Null
function Create([string]$p) {
    [IO.Directory]::CreateDirectory((Split-Path -Parent $p)) | Out-Null
    Set-Content -LiteralPath $p -Value 'test placeholder, never a DLL' -Encoding ASCII
}
function ModulePath($c) { Join-Path $game ("Modules/" + $c.Module + "/bin/Win64_Shipping_Client/" + $c.Dll) }
function WorkshopPath($c) { Join-Path $workshop ($c.Id + "/bin/Win64_Shipping_Client/" + $c.Dll) }
function Resolve-Property([string]$property, [string]$override='') {
    $args = @('msbuild', $project, '-nologo', "-getProperty:$property", "-p:GameFolder=$game")
    if ($override) { $args += "-p:$property=$override" }
    $output = @(& dotnet @args 2>&1)
    if ($LASTEXITCODE -ne 0) { throw "P014G_FAIL msbuild_property=$property result=$($output -join ' ')" }
    $path = ($output[-1] | Out-String).Trim()
    if (-not $path) { throw "P014G_FAIL empty_msbuild_property=$property" }
    [IO.Path]::GetFullPath($path)
}
function Expect($c, [string]$expected, [string]$label, [string]$override='') {
    $actual = Resolve-Property $c.Name $override
    Check ([string]::Equals([IO.Path]::GetFullPath($expected), $actual, [StringComparison]::OrdinalIgnoreCase)) $label
}
try {
    # Source ZIPs from Steam Workshop contain only their own IDs; unrelated mods may package duplicate DLL names.
    $decoy = Join-Path $workshop '3720376888/bin/Win64_Shipping_Client/MCMv5.dll'
    Create $decoy
    foreach ($c in $components) { Create (WorkshopPath $c) }
    foreach ($c in $components) { Expect $c (WorkshopPath $c) ("workshop_only_" + $c.Name) }
    $mcm = $components[2]
    Create (ModulePath $mcm)
    foreach ($c in $components) {
        $expect = if ($c.Name -eq 'McmDllPath') { ModulePath $c } else { WorkshopPath $c }
        Expect $c $expect ("mixed_modules_workshop_" + $c.Name)
    }
    foreach ($c in $components) { Create (ModulePath $c) }
    foreach ($c in $components) { Expect $c (ModulePath $c) ("standard_modules_first_" + $c.Name) }
    $override = Join-Path $fixture 'explicit/MCMv5.dll'
    Create $override
    Expect $mcm $override 'explicit_override_takes_priority' $override
    # The default must never point to the other mod's bundled DLL even if the canonical DLL is missing.
    Remove-Item -LiteralPath (ModulePath $mcm)
    Remove-Item -LiteralPath (WorkshopPath $mcm)
    Expect $mcm (ModulePath $mcm) 'missing_canonical_fails_closed_to_old_path'
    Check (Test-Path -LiteralPath $decoy -PathType Leaf) 'decoy_still_excluded'
    Write-Host 'P014G_MSBUILD_PROPERTY_PASS; compiled harness/runtime/save QA still pending.'
}
finally {
    if (Test-Path -LiteralPath $fixture) { Remove-Item -LiteralPath $fixture -Recurse -Force }
}
