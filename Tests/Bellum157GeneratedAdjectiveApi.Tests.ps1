# Bannerlord 1.5.7: removed FactionHelper.GetAdjectiveForFaction Harmony target.
# Source checks only. Native/localized generated-realm adjectives require live validation.
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$obsoletePatch = Join-Path $root 'Patches/BellumGeneratedKingdomAdjectivePatch.cs'
if (Test-Path -LiteralPath $obsoletePatch -PathType Leaf) {
    throw 'BELLUM157_ADJECTIVE_ABI FAIL removed_harmony_target_still_present'
}
Write-Output 'PASS BELLUM157_ADJECTIVE_ABI removed_harmony_target_absent'

$visibilityPath = Join-Path $root 'BellumKingdomVisibilityHelper.cs'
$modulePath = Join-Path $root 'SubModule.cs'
$namesPath = Join-Path $root 'Patches/DynamicKingdomTitleNamePatch.cs'
$helperPath = Join-Path $root 'DynamicKingdomTitleNameHelper.cs'
foreach ($path in @($visibilityPath, $modulePath, $namesPath, $helperPath)) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "BELLUM157_ADJECTIVE_ABI FAIL missing_neighbor_source=$path"
    }
}
$visibility = [System.IO.File]::ReadAllText($visibilityPath)
$module = [System.IO.File]::ReadAllText($modulePath)
$names = [System.IO.File]::ReadAllText($namesPath)
$helper = [System.IO.File]::ReadAllText($helperPath)

function Assert-Has([string]$body, [string]$fragment, [string]$case) {
    if (-not $body.Contains($fragment)) { throw "BELLUM157_ADJECTIVE_ABI FAIL $case" }
    Write-Output "PASS BELLUM157_ADJECTIVE_ABI $case"
}
function Assert-NotHas([string]$body, [string]$fragment, [string]$case) {
    if ($body.Contains($fragment)) { throw "BELLUM157_ADJECTIVE_ABI FAIL $case" }
    Write-Output "PASS BELLUM157_ADJECTIVE_ABI $case"
}

Assert-Has $visibility 'public static bool IsBellumGeneratedKingdom(Kingdom kingdom)' 'generated_realm_detection_retained'
Assert-Has $visibility 'public static bool ShouldUseCultureAdjective(Kingdom kingdom)' 'culture_adjective_guard_retained_for_future_consumer'
Assert-Has $visibility 'kingdomId.Contains("_rebels_")' 'rebel_realm_detection_retained'
Assert-Has $visibility 'kingdomId.StartsWith("bc_treaty_release_")' 'treaty_realm_detection_retained'
Assert-Has $visibility 'kingdomId.Contains("_indep_")' 'independent_realm_detection_retained'
Assert-Has $module '_harmony.CreateClassProcessor(type).Patch();' 'global_harmony_registration_unchanged'
Assert-Has $names 'nameof(Kingdom.FormalName), MethodType.Getter' 'formal_name_hook_retained'
Assert-Has $names 'DynamicKingdomTitleNameHelper.RecordNativeNameChange(__instance, name, informalName, formalName, __state);' 'native_realm_rename_retained'
Assert-Has $helper 'MergeXmlText(node, "title", value => names.FormalName = value);' 'xml_native_formal_recovery_retained'
Assert-NotHas $module 'BellumGeneratedKingdomAdjectivePatch' 'no_explicit_obsolete_registration'
Write-Output 'BELLUM157_ADJECTIVE_ABI SOURCE_PASS; compile_and_gameplay=NOT_RUN'
