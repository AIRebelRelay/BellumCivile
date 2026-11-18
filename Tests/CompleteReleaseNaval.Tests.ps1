# Source-level regression for the CR Bellum release packager.
# Run: pwsh -NoProfile -ExecutionPolicy Bypass -File .\Tests\CompleteReleaseNaval.Tests.ps1
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$script = [IO.File]::ReadAllText((Join-Path $root 'scripts\Build-CrBellumModuleWindows.ps1'))
$project = [IO.File]::ReadAllText((Join-Path $root 'BellumCivile.NavalDLCPatch\BellumCivile.NavalDLCPatch.csproj'))
function Check([bool]$ok, [string]$case) {
    if (-not $ok) { throw "BELLUM_NAVAL_RELEASE_FAIL $case" }
    Write-Host "BELLUM_NAVAL_RELEASE_PASS $case"
}
Check ($script.Contains('BellumCivile.csproj') -and $script.Contains('BellumCivile.NavalDLCPatch.csproj')) 'both_projects_required'
Check ($script.Contains('BuildProjectReferences=false') -and $script.Contains('SkipNavalMainOutputCopy=true')) 'isolated_naval_compilation_preserves_existing_core'
Check ($project.Contains("Condition=`"'$(SkipNavalMainOutputCopy)' != 'true'`"")) 'legacy_naval_copy_preserved_unless_release_isolated'
Check ($script.Contains('NavalDLC.ViewModelCollection.dll')) 'naval_dependency_preflight'
Check ($script.Contains('BellumCivile.NavalDLCPatch.dll') -and $script.Contains('wrong_naval_assembly_identity')) 'companion_identity_guard'
Check ($script.Contains('naval_packaged_hash_mismatch')) 'companion_copy_hash_guard'
Check ($script.Contains('zip_missing=') -and $script.Contains('BellumCivile/bin/Win64_Shipping_Client/BellumCivile.NavalDLCPatch.dll')) 'zip_naval_presence_guard'
Check ($script.Contains('BellumCivile/bin/Win64_Shipping_Client/BellumCivile.dll')) 'zip_core_presence_guard'
Check (-not $script.Contains('Core Bellum only; optional Naval companion not built')) 'no_core_only_success'
Write-Host 'BELLUM_NAVAL_RELEASE_SOURCE_PASS; Windows build and game validation still required.'
