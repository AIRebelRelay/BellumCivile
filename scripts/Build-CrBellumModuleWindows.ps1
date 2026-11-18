#Requires -Version 7.2
# Both BellumCivile.dll and BellumCivile.NavalDLCPatch.dll are mandatory in CR releases.
# Force launch from extracted ZIP root (new output folder required):
# pwsh -NoProfile -ExecutionPolicy Bypass -File .\scripts\Build-CrBellumModuleWindows.ps1 -OutputRoot C:\CR_Builds\Bellum_14123_01 -GameFolder "F:\Steam\steamapps\common\Mount & Blade II Bannerlord" -WorkshopFolder "F:\Steam\steamapps\workshop\content\261550"
[CmdletBinding()]
param(
 [Parameter(Mandatory)][string]$OutputRoot,
 [Parameter(Mandatory)][string]$GameFolder,
 [Parameter(Mandatory)][string]$WorkshopFolder,
 [string]$DotnetPath='dotnet'
)
$ErrorActionPreference='Stop'
$PSNativeCommandUseErrorActionPreference=$false
if([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT){throw 'Windows and actual installed game references required.'}
$source=Split-Path $PSScriptRoot -Parent
$navalProjectPath=Join-Path $source 'BellumCivile.NavalDLCPatch/BellumCivile.NavalDLCPatch.csproj'
if(!(Test-Path -LiteralPath $navalProjectPath -PathType Leaf)){throw 'Missing mandatory Naval companion project.'}
$out=[IO.Path]::GetFullPath($OutputRoot)
$game=[IO.Path]::GetFullPath($GameFolder)
$workshop=[IO.Path]::GetFullPath($WorkshopFolder)
if(Test-Path -LiteralPath $out){throw 'Output already exists. Choose a new OutputRoot.'}
foreach($protected in @($source,$game,$workshop)){
 $prefix=$protected.TrimEnd('\','/')+[IO.Path]::DirectorySeparatorChar
 if($out.Equals($protected,[StringComparison]::OrdinalIgnoreCase) -or $out.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)){throw 'Output must be outside source/game/Workshop.'}
}
$ancestor=Split-Path $out -Parent
while($ancestor){if(Test-Path -LiteralPath $ancestor){if((Get-Item -LiteralPath $ancestor -Force).Attributes -band [IO.FileAttributes]::ReparsePoint){throw 'Output ancestor is a link/junction.'}};$parent=Split-Path $ancestor -Parent;if($parent -eq $ancestor){break};$ancestor=$parent}
$overrides=@{
 'HarmonyDllPath'=(Join-Path $workshop '2859188632/bin/Win64_Shipping_Client/0Harmony.dll')
 'UIExtenderExDllPath'=(Join-Path $workshop '2859222409/bin/Win64_Shipping_Client/Bannerlord.UIExtenderEx.dll')
 'McmDllPath'=(Join-Path $workshop '2859238197/bin/Win64_Shipping_Client/MCMv5.dll')
}
$butterlib=Join-Path $workshop '2859232415/bin/Win64_Shipping_Client/Bannerlord.ButterLib.dll'
if(!(Test-Path -LiteralPath $butterlib -PathType Leaf)){throw ('Missing Workshop ButterLib: '+$butterlib)}
$navalViewModel=Join-Path $game 'Modules/NavalDLC/bin/Win64_Shipping_Client/NavalDLC.ViewModelCollection.dll'
if(!(Test-Path -LiteralPath $navalViewModel -PathType Leaf)){throw ('Missing War Sails reference: '+$navalViewModel)}
[xml]$project=Get-Content -Raw -LiteralPath (Join-Path $source 'BellumCivile.csproj')
[xml]$navalProject=Get-Content -Raw -LiteralPath $navalProjectPath
$references=@($project.Project.ItemGroup.Reference | Where-Object {$_.HintPath})+
            @($navalProject.Project.ItemGroup.Reference | Where-Object {$_.HintPath})
foreach($reference in $references){
 $path=[string]$reference.HintPath
 foreach($key in $overrides.Keys){$path=$path.Replace('$('+$key+')',$overrides[$key])}
 $path=$path.Replace('$(GameFolder)',$game)
 if($path.Contains('$(') -or !(Test-Path -LiteralPath $path -PathType Leaf)){throw ('Missing/unresolved reference: '+$path)}
 [Reflection.AssemblyName]::GetAssemblyName($path) | Out-Null
}
foreach($relative in @('_Module/SubModule.xml','GUI','ModuleData','LICENSE.txt')){if(!(Test-Path -LiteralPath (Join-Path $source $relative))){throw ('Missing package input: '+$relative)}}
[xml]$template=Get-Content -Raw -LiteralPath (Join-Path $source '_Module/SubModule.xml')
if($template.Module.Id.value -cne 'BellumCivile' -or
   $template.Module.Version.value -notmatch '^v[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$'){
 throw 'Expected a versioned BellumCivile module template.'
}
$expectedVersion=([string]$template.Module.Version.value).Substring(1)
$dotnet=Get-Command $DotnetPath -CommandType Application -ErrorAction Stop | Select-Object -First 1
New-Item -ItemType Directory -Path $out | Out-Null
$artifacts=(Join-Path $out 'artifacts').Replace('\','/')+'/'
$intermediate=(Join-Path $out 'intermediate').Replace('\','/')+'/'
$arguments=@('build',(Join-Path $source 'BellumCivile.csproj'),'-c','Release','--no-incremental',('-p:GameFolder='+$game),('-p:OutputPath='+$artifacts),('-p:BaseIntermediateOutputPath='+$intermediate),('-p:MSBuildProjectExtensionsPath='+$intermediate),'-p:AppendTargetFrameworkToOutputPath=false','-p:AppendRuntimeIdentifierToOutputPath=false','-p:ImportDirectoryBuildTargets=false')
foreach($key in $overrides.Keys){$arguments+=('-p:'+$key+'='+$overrides[$key])}
Push-Location $source
try{& $dotnet.Source @arguments 2>&1 | Tee-Object -FilePath (Join-Path $out 'build.log');$buildExit=$LASTEXITCODE}finally{Pop-Location}
if($buildExit -ne 0){throw ('Build failed; see '+(Join-Path $out 'build.log'))}
# Build bundled companion with previously compiled core from artifacts.
# Naval intermediates remain out-of-tree; normal standalone post-build copy is unchanged.
$navalIntermediate=(Join-Path $out 'naval-intermediate').Replace('\','/')+'/'
$navalArguments=@('build',$navalProjectPath,'-c','Release','--no-incremental',
 ('-p:GameFolder='+$game),('-p:OutputPath='+$artifacts),
 ('-p:BaseIntermediateOutputPath='+$navalIntermediate),
 ('-p:MSBuildProjectExtensionsPath='+$navalIntermediate),
 '-p:AppendTargetFrameworkToOutputPath=false',
 '-p:AppendRuntimeIdentifierToOutputPath=false',
 '-p:ImportDirectoryBuildTargets=false',
 '-p:BuildProjectReferences=false',
 '-p:SkipNavalMainOutputCopy=true')
foreach($key in $overrides.Keys){$navalArguments+=('-p:'+$key+'='+$overrides[$key])}
Push-Location $source
try{& $dotnet.Source @navalArguments 2>&1 | Tee-Object -FilePath (Join-Path $out 'naval-build.log');$navalExit=$LASTEXITCODE}finally{Pop-Location}
if($navalExit -ne 0){throw ('Naval build failed; see '+(Join-Path $out 'naval-build.log'))}
$dll=Join-Path $artifacts 'BellumCivile.dll'
if([Reflection.AssemblyName]::GetAssemblyName($dll).Name -cne 'BellumCivile'){throw 'Unexpected DLL identity.'}
$version=[Diagnostics.FileVersionInfo]::GetVersionInfo($dll)
if($version.FileVersion -ne $expectedVersion){throw ('Unexpected DLL file version: '+$version.FileVersion+' expected='+$expectedVersion)}
$navalDll=Join-Path $artifacts 'BellumCivile.NavalDLCPatch.dll'
if(!(Test-Path -LiteralPath $navalDll -PathType Leaf)){throw ('Missing Naval DLL after build: '+$navalDll)}
if((Get-Item -LiteralPath $navalDll).Length -le 0){throw 'Empty Naval DLL after build.'}
if([Reflection.AssemblyName]::GetAssemblyName($navalDll).Name -cne 'BellumCivile.NavalDLCPatch'){
 throw 'wrong_naval_assembly_identity'
}
$module=Join-Path $out 'Modules/BellumCivile'
$bin=Join-Path $module 'bin/Win64_Shipping_Client'
New-Item -ItemType Directory -Path $bin,(Join-Path $module 'logs') | Out-Null
Copy-Item -LiteralPath (Join-Path $source '_Module/SubModule.xml') -Destination (Join-Path $module 'SubModule.xml')
Copy-Item -LiteralPath (Join-Path $source 'GUI'),(Join-Path $source 'ModuleData') -Destination $module -Recurse
Copy-Item -LiteralPath (Join-Path $source 'LICENSE.txt') -Destination $module
$packagedDll=Join-Path $bin 'BellumCivile.dll';Copy-Item -LiteralPath $dll -Destination $packagedDll
if((Get-FileHash -LiteralPath $dll).Hash -ne (Get-FileHash -LiteralPath $packagedDll).Hash){throw 'Packaged DLL hash mismatch.'}
$packagedNavalDll=Join-Path $bin 'BellumCivile.NavalDLCPatch.dll'
Copy-Item -LiteralPath $navalDll -Destination $packagedNavalDll
if((Get-FileHash -LiteralPath $navalDll).Hash -ne (Get-FileHash -LiteralPath $packagedNavalDll).Hash){
 throw 'naval_packaged_hash_mismatch'
}
$zipPath=Join-Path $out ('BellumCivile_'+$expectedVersion+'_complete.zip')
Compress-Archive -LiteralPath $module -DestinationPath $zipPath -CompressionLevel Optimal
$zip=[IO.Compression.ZipFile]::OpenRead($zipPath)
try{
 $entries=@($zip.Entries | ForEach-Object {$_.FullName.Replace('\','/')})
 foreach($required in @(
  'BellumCivile/SubModule.xml',
  'BellumCivile/bin/Win64_Shipping_Client/BellumCivile.dll',
  'BellumCivile/bin/Win64_Shipping_Client/BellumCivile.NavalDLCPatch.dll'
  )){
  if($entries -cnotcontains $required){throw ('zip_missing='+$required)}
  $item=$zip.GetEntry($required)
  if($null -eq $item -or $item.Length -le 0){throw ('zip_empty='+$required)}
 }
 if(@($entries | Where-Object {$_ -like 'BellumCivile/GUI/*'}).Count -eq 0){throw 'zip_missing=GUI'}
 if(@($entries | Where-Object {$_ -like 'BellumCivile/ModuleData/*'}).Count -eq 0){throw 'zip_missing=ModuleData'}
}finally{$zip.Dispose()}
[ordered]@{
 Version=$version.FileVersion
 ModuleFolder=$module
 CoreDllSha256=(Get-FileHash -LiteralPath $packagedDll).Hash
 NavalDllSha256=(Get-FileHash -LiteralPath $packagedNavalDll).Hash
 ZipPath=$zipPath
 Gameplay='NOT_RUN'
 Scope='Core Bellum plus bundled Naval companion'
 Deployed=$false
} | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $out 'build-report.json')
Write-Output ('BELLUM_MODULE_BUILD_PACKAGE_PASS version='+$expectedVersion+'; core=present; naval=present; zip='+$zipPath+'; module='+$module+'; gameplay=NOT_RUN; deployed=false')
