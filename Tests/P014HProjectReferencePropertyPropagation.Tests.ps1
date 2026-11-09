# P0-14H: RED-first contract for resolved harness paths crossing into the Native ProjectReference.
# Source-level and MSBuild evaluation only; no game writes, builds or DLL deployment.
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$project = Join-Path $root 'Tests/SuccessionEngineHarness/SuccessionEngineHarness.csproj'
function Check([bool]$passed, [string]$label) {
    if (-not $passed) { throw "P014H_FAIL $label" }
    Write-Host "P014H_PASS $label"
}
[xml]$xml = Get-Content -LiteralPath $project -Raw
$refs = @($xml.Project.ItemGroup.ProjectReference | Where-Object { $_ -and $_.Include })
Check ($refs.Count -eq 1 -and [string]$refs[0].Include -eq '../../BellumCivile.csproj') 'single_native_project_reference_preserved'
$nativeRef = @($xml.Project.ItemGroup.ProjectReference | Where-Object { $_ -and $_.Update -eq '../../BellumCivile.csproj' })
Check ($nativeRef.Count -eq 1) 'single_specific_native_reference_update'
$additional = [string]$nativeRef[0].AdditionalProperties
Check ($additional -eq 'HarmonyDllPath=$(HarmonyDllPath);UIExtenderExDllPath=$(UIExtenderExDllPath)') 'only_two_native_dependencies_forwarded'
Check ([string]::IsNullOrEmpty([string]$nativeRef[0].Properties)) 'existing_build_configuration_not_overridden'
Check ((Get-Content -LiteralPath $project -Raw).Contains('<ProjectReference Include="../../BellumCivile.csproj" />')) 'previous_P014A_source_contract_preserved'
if (-not (Get-Command dotnet -ErrorAction SilentlyContinue)) { throw 'P014H_FAIL dotnet_sdk_required' }
# Assert the actual evaluated ProjectReference metadata, not only XML text.
function Probe([string]$harmony, [string]$ui) {
    $game = Join-Path ([IO.Path]::GetTempPath()) 'BellumP014H/uninstalled-game'
    $result = @(& dotnet msbuild $project -nologo "-p:GameFolder=$game" "-p:HarmonyDllPath=$harmony" "-p:UIExtenderExDllPath=$ui" '-getItem:ProjectReference' 2>&1)
    if ($LASTEXITCODE -ne 0) { throw "P014H_FAIL msbuild_eval: $($result -join ' ')" }
    try {
        $parsed = ($result -join [Environment]::NewLine) | ConvertFrom-Json
        $items = @($parsed.Items.ProjectReference)
        Check ($items.Count -eq 1) 'one_evaluated_project_reference'
        return [string]$items[0].AdditionalProperties
    } catch {
        throw "P014H_FAIL msbuild_json: $($_.Exception.Message)"
    }
}
$harmony1 = Join-Path ([IO.Path]::GetTempPath()) 'P014H/original/0Harmony.dll'
$ui1 = Join-Path ([IO.Path]::GetTempPath()) 'P014H/original/Bannerlord.UIExtenderEx.dll'
$observed = Probe $harmony1 $ui1
Check ($observed -eq "HarmonyDllPath=$harmony1;UIExtenderExDllPath=$ui1") 'explicit_property_values_forwarded_to_native'
$harmony2 = Join-Path ([IO.Path]::GetTempPath()) 'P014H/other/0Harmony.dll'
$ui2 = Join-Path ([IO.Path]::GetTempPath()) 'P014H/other/Bannerlord.UIExtenderEx.dll'
$observed2 = Probe $harmony2 $ui2
Check ($observed2 -eq "HarmonyDllPath=$harmony2;UIExtenderExDllPath=$ui2") 'new_overrides_not_stuck_on_previous_paths'
Write-Host 'P014H_PROJECT_REFERENCE_PASS; real no-override net472 graph build and executable regressions still required.'
