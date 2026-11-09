# P0-14L: build-only resolution for the bundled Naval DLL's UIExtenderEx reference.
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$proj = Get-Content -Raw -LiteralPath (Join-Path $root 'BellumCivile.NavalDLCPatch\BellumCivile.NavalDLCPatch.csproj')
function Check([bool]$ok, [string]$description) {
    if (-not $ok) { throw "P014L_FAIL $description" }
    Write-Host "P014L_PASS $description"
}
$module = '$(GameFolder)\Modules\Bannerlord.UIExtenderEx\bin\Win64_Shipping_Client\Bannerlord.UIExtenderEx.dll'
$workshop = '$(GameFolder)\..\..\workshop\content\261550\2859222409\bin\Win64_Shipping_Client\Bannerlord.UIExtenderEx.dll'
$modIdx = $proj.IndexOf($module)
$shopIdx = $proj.IndexOf($workshop)
$hintIdx = $proj.IndexOf('<HintPath>$(UIExtenderExDllPath)</HintPath>')
Check ($proj.Contains('<ProjectReference Include="..\BellumCivile.csproj" />')) 'native_core_project_reference_unchanged'
Check ($proj.Contains('<Reference Include="Bannerlord.UIExtenderEx">')) 'same_explicit_UIExtenderEx_reference'
Check ($modIdx -ge 0 -and $shopIdx -gt $modIdx -and $hintIdx -gt $shopIdx) 'modules_before_workshop_and_reference_uses_resolved_path'
Check (([regex]::Matches($proj, '<UIExtenderExDllPath Condition=')).Count -eq 3) 'three_conditional_resolution_choices'
Check (([regex]::Matches($proj, 'Condition="[^"\r\n]*UIExtenderExDllPath')).Count -eq 3) 'caller_override_has_precedence'
Check ($proj.Contains('Exists(') -and $proj.Contains('workshop\content\261550\2859222409')) 'workshop_reference_is_selected_only_if_present'
Check ($proj.Contains('<Target Name="CopyNavalPatchToMainOutput" AfterTargets="Build">')) 'existing_navaldlc_copy_target_preserved'
Check ($proj.Contains('<TargetFramework>net472</TargetFramework>') -and $proj.Contains('<AssemblyName>BellumCivile.NavalDLCPatch</AssemblyName>')) 'assembly_identity_unchanged'
Write-Host 'P014L_SOURCE_PASS; Windows net472 compile and installed-reference check still required.'
