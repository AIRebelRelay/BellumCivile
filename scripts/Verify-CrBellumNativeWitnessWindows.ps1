#Requires -Version 7.2
# Force launch from extracted BellumCivile source folder:
# pwsh -NoProfile -ExecutionPolicy Bypass -File .\scripts\Verify-CrBellumNativeWitnessWindows.ps1 -OutputRoot C:\CR_Builds\Bellum_141213_Treaty_01
[CmdletBinding()]
param([Parameter(Mandatory)][string]$OutputRoot,
 [string]$GameFolder='F:\Steam\steamapps\common\Mount & Blade II Bannerlord',
 [string]$WorkshopFolder='F:\Steam\steamapps\workshop\content\261550')
$ErrorActionPreference='Stop'
if([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT){throw 'Actual Windows/Game ABI required.'}
$root=Split-Path $PSScriptRoot -Parent
if(Test-Path -LiteralPath $OutputRoot){throw 'OutputRoot already exists; choose a fresh one.'}
$manifest=Get-Content -LiteralPath (Join-Path $root 'S26B_PACKAGE_FILES_SHA256.json') -Raw | ConvertFrom-Json -AsHashtable
foreach($relative in $manifest.Keys){
 $file=Join-Path $root $relative
 if(!(Test-Path -LiteralPath $file -PathType Leaf)){throw "Missing manifest file: $relative"}
 $actual=(Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash
 if($actual -cne ([string]$manifest[$relative]).ToUpperInvariant()){throw "Source inventory mismatch: $relative"}
}
[xml]$xml=Get-Content -LiteralPath (Join-Path $root '_Module/SubModule.xml') -Raw
if($xml.Module.Version.value -cne 'v1.4.12.19'){throw 'Unexpected source version.'}
# Preflight manually authored .NET file identity before running test suites or compiling.
# GenerateAssemblyInfo=false, so the project does not infer FileVersion from SubModule.xml.
$assemblyInfo=Get-Content -LiteralPath (Join-Path $root 'Properties/AssemblyInfo.cs') -Raw
$expectedFileVersion=([string]$xml.Module.Version.value).Substring(1)
if(-not $assemblyInfo.Contains('[assembly: AssemblyVersion("1.0.0.0")]')){throw 'Assembly binding identity changed.'}
if(-not $assemblyInfo.Contains('[assembly: AssemblyFileVersion("'+$expectedFileVersion+'")]')){throw ('AssemblyFileVersion mismatch: expected '+$expectedFileVersion)}
if(-not $assemblyInfo.Contains('[assembly: AssemblyInformationalVersion("1.4.12b-cr-royal-accord.19")]')){throw 'AssemblyInformationalVersion mismatch.'}
Write-Output ('BELLUM_VERSION_PREFLIGHT_PASS version='+$expectedFileVersion)
$groupNames=@('CrDiplomacyGateway.Tests','TreatyQaConsole.Tests','TreatyInstanceBinding.Tests','WarNativeWitness.Tests','WarIdentityDump.Tests','WarConflictIdentity.Tests',
 'ForeignConflictIdentity.Tests','WarConflictIdentity.Mutations','ForeignConflictIdentity.Mutations','CrRoyalAccord.Tests','CrownAccessionOccurrence.Tests')
New-Item -Path $OutputRoot -ItemType Directory | Out-Null
foreach($name in $groupNames){
 $script=Join-Path $root ("Tests/$name.ps1")
 if(!(Test-Path -LiteralPath $script -PathType Leaf)){throw "Missing required test $name"}
 $log=Join-Path $OutputRoot ("$name.log")
 & pwsh -NoProfile -ExecutionPolicy Bypass -File $script *>&1 | Tee-Object -FilePath $log
 if($LASTEXITCODE -ne 0){throw "FAIL $name; inspect $log; build NOT_RUN"}
 Write-Output "PASS $name"
}
$build=Join-Path $OutputRoot 'build'
& pwsh -NoProfile -ExecutionPolicy Bypass -File (Join-Path $root 'scripts/Build-CrBellumModuleWindows.ps1') `
 -OutputRoot $build -GameFolder $GameFolder -WorkshopFolder $WorkshopFolder
if($LASTEXITCODE -ne 0){throw 'Core+Naval builder failed; see build logs.'}
Write-Output ('BELLUM_CR_DIPLOMACY_GATE_PASS version=1.4.12.19; groups='+$groupNames.Count+
 '; module='+ (Join-Path $build 'Modules/BellumCivile') + '; game=NOT_RUN; deployed=false')
