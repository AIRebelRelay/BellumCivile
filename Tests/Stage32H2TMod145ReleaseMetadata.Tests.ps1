# Stage32H2T — RED-first exact Native Bellum MOD 1.4.6 release-candidate metadata.
# This contract does NOT compile or release the DLL, or change GAME version.
$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
$manifestPath = Join-Path $repo '_Module/SubModule.xml'
$navalPath = Join-Path $repo 'BellumCivile.NavalDLCPatch/_Module/SubModule.xml'
$readmePath = Join-Path $repo 'README.md'
$assemblyPath = Join-Path $repo 'Properties/AssemblyInfo.cs'
$verifierPath = Join-Path $repo 'scripts/Verify-Bellum148Build.ps1'
function Check([bool]$yes, [string]$label) {
    if (-not $yes) { throw "STAGE32H2T_RED $label" }
    Write-Host "STAGE32H2T_CHECK $label"
}
foreach ($p in @($manifestPath, $navalPath, $readmePath, $assemblyPath, $verifierPath)) {
    Check (Test-Path -LiteralPath $p -PathType Leaf) "required_file_$(Split-Path $p -Leaf)"
}
[xml]$manifest = Get-Content -LiteralPath $manifestPath -Raw
[xml]$naval = Get-Content -LiteralPath $navalPath -Raw
$readme = Get-Content -LiteralPath $readmePath -Raw
$assembly = Get-Content -LiteralPath $assemblyPath -Raw
$verifier = Get-Content -LiteralPath $verifierPath -Raw
Check ($manifest.Module.Name.value -eq 'Bellum Civile' -and
    $manifest.Module.Id.value -eq 'BellumCivile' -and
    $manifest.Module.Version.value -eq 'v1.4.6') 'main_Bellum_mod_id_and_version_146'
Check ($manifest.Module.SubModules.SubModule.DLLName.value -eq 'BellumCivile.dll' -and
    $manifest.Module.SubModules.SubModule.SubModuleClassType.value -eq 'BellumCivile.SubModule') 'main_DLL_and_entrypoint_unchanged'
Check ($manifest.Module.DependedModules.DependedModule.Count -ge 7 -and
    (@($manifest.Module.DependedModules.DependedModule | ForEach-Object { $_.Id }) -contains 'Native') -and
    (@($manifest.Module.DependedModules.DependedModule | ForEach-Object { $_.Id }) -contains 'Bannerlord.Harmony')) 'original_dependency_graph_still_present'
Check ($readme.Contains('| Release version | Bellum Civile 1.4.6 |') -and
    $readme.Contains('| Target game version | Bannerlord 1.4.8 |')) 'readme_mod_146_and_game_148'
Check ($naval.Module.Id.value -eq 'BellumCivile.NavalDLCPatch' -and
    $naval.Module.Version.value -eq 'v1.0.33') 'separate_Naval_DLC_patch_version_unchanged'
Check ($assembly.Contains('[assembly: AssemblyVersion("1.0.0.0")]') -and
    $assembly.Contains('[assembly: AssemblyFileVersion("1.4.6.0")]')) 'assembly_identity_unchanged'
Check ($verifier.Contains('BELLUM148_PREFLIGHT pass game_version=1.4.8') -and
    $verifier.Contains('$gameVersions -notcontains ' + "'1.4.8'")) 'strict_GAME_148_verifier_unchanged'
Write-Host 'STAGE32H2T_SOURCE_CONTRACT_PASS; build/DLL/game/save/release PENDING'
