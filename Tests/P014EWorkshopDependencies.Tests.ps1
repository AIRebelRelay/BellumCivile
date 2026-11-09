# P0-14E: RED-first regression contract for installed game/Steam Workshop references.
# Source-only contract; Windows preflight and real net472 build still required.
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
function Read([string]$name) { Get-Content -Raw -LiteralPath (Join-Path $root $name) }
function Check([bool]$ok,[string]$reason) { if (-not $ok) { throw "P014E_FAIL $reason" }; Write-Host "P014E_PASS $reason" }
$proj = Read 'BellumCivile.csproj'
$verify = Read 'scripts/Verify-Bellum148Build.ps1'
$harness = Read 'Tests/SuccessionEngineHarness/SuccessionEngineHarness.csproj'
Check ($proj.Contains('<HintPath>$(HarmonyDllPath)</HintPath>') -and
       $proj.Contains('<HintPath>$(UIExtenderExDllPath)</HintPath>')) 'shipping_two_explicit_msbuild_reference_properties'
Check ($proj.Contains('<HarmonyDllPath Condition=') -and
       $proj.Contains('<UIExtenderExDllPath Condition=') -and
       $proj.Contains('$(GameFolder)\Modules\Bannerlord.Harmony') -and
       $proj.Contains('$(GameFolder)\Modules\Bannerlord.UIExtenderEx')) 'shipping_standard_modules_fallback_preserved'
Check ($harness.Contains('$(HarmonyDllPath)') -and
       $harness.Contains('$(UIExtenderExDllPath)') -and
       $harness.Contains('$(GameFolder)/Modules/Bannerlord.Harmony') -and
       $harness.Contains('$(GameFolder)/Modules/Bannerlord.UIExtenderEx')) 'harness_standard_and_explicit_reference_paths'
Check ($verify.Contains('BellumHarmonyDllPath') -and
       $verify.Contains('BellumUIExtenderExDllPath') -and
       $verify.Contains('HarmonyDllPath') -and
       $verify.Contains('UIExtenderExDllPath')) 'explicit_param_and_env_override'
Check ($verify.Contains('2859188632') -and
       $verify.Contains('2859222409') -and
       $verify.Contains('workshop\content\261550') -and
       -not $verify.Contains('3720376888')) 'only_canonical_workshop_modules'
Check ($verify.Contains("source=modules") -and
       $verify.Contains("source=workshop") -and
       $verify.Contains("source=override") -and
       $verify.Contains('Test-Path -LiteralPath $modulePath') -and
       $verify.Contains('Test-Path -LiteralPath $workshopPath')) 'modules_precedes_workshop_and_override_supported'
Check ($verify.Contains("unrecognized_reference_path") -and
       $verify.Contains("missing_references") -and
       $verify.Contains("wrong_game_version") -and
       $verify.Contains("1.4.8")) 'strict_unknown_reference_missing_dll_and_game_version_fail_closed'
Check ($verify.Contains('@msbuildProps') -and
       $verify.Contains('dotnet restore') -and
       $verify.Contains('dotnet build')) 'restore_build_same_exact_resolved_dependencies'
Check (-not $verify.Contains('Copy-Item') -and
       -not $verify.Contains('New-Item') -and
       -not $verify.Contains('Set-Content')) 'read_only_preflight_no_game_mutation'
Write-Host 'P014E_SOURCE_PASS: execute real Windows preflight, net472 and harness after source test.'
