# P0-14D metadata-only QA candidate. Source identity assertions, no game/SDK execution.
# This does not assert functional parity with official upstream Bellum 1.4.11.
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
function Read([string]$p) { Get-Content -Raw -LiteralPath (Join-Path $root $p) }
function Check([bool]$ok,[string]$name) { if (-not $ok) { throw "P014D_FAIL $name" }; Write-Host "P014D_PASS $name" }
[xml]$xml = Read '_Module/SubModule.xml'
$asm = Read 'Properties/AssemblyInfo.cs'
$readme = Read 'README.md'
[xml]$naval = Read 'BellumCivile.NavalDLCPatch/_Module/SubModule.xml'
Check ($xml.Module.Id.value -eq 'BellumCivile' -and $xml.Module.Name.value -eq 'Bellum Civile') 'native_module_id_name_preserved'
Check ($xml.Module.Version.value -eq 'v1.4.11.1') 'bannerlord_numeric_version_for_relay_1411r'
Check ($asm.Contains('[assembly: AssemblyVersion("1.0.0.0")]')) 'native_assembly_binding_identity_preserved'
Check ($asm.Contains('[assembly: AssemblyFileVersion("1.4.11.1")]') -and
       $asm.Contains('[assembly: AssemblyInformationalVersion("1.4.11r-qa")]')) 'file_and_informational_relay_identity'
Check ($readme.Contains('Bellum Civile 1.4.11r') -and
       $readme.Contains('upstream parity not certified')) 'readme_marks_candidate_not_parity'
Check ($naval.Module.Id.value -eq 'BellumCivile.NavalDLCPatch' -and
       $naval.Module.Version.value -eq 'v1.0.33') 'naval_dlc_independent_module_untouched'
Check ((Read 'BellumCivile.csproj').Contains('<TargetFramework>net472</TargetFramework>')) 'framework_unchanged'
Check ((Read 'scripts/Verify-Bellum148Build.ps1').Contains("BELLUM148_PREFLIGHT pass game_version=1.4.8")) 'game_version_gate_unchanged'
Write-Host 'P014D_SOURCE_PASS; game ApplicationVersion parser, assembly build, upstream parity and save QA NOT RUN.'
