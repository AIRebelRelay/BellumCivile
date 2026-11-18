#Requires -Version 7.2
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
[xml]$project=Get-Content -Raw -LiteralPath (Join-Path $source 'BellumCivile.csproj')
foreach($reference in @($project.Project.ItemGroup.Reference | Where-Object {$_.HintPath})){
 $path=[string]$reference.HintPath
 foreach($key in $overrides.Keys){$path=$path.Replace('$('+$key+')',$overrides[$key])}
 $path=$path.Replace('$(GameFolder)',$game)
 if($path.Contains('$(') -or !(Test-Path -LiteralPath $path -PathType Leaf)){throw ('Missing/unresolved reference: '+$path)}
 [Reflection.AssemblyName]::GetAssemblyName($path) | Out-Null
}
foreach($relative in @('_Module/SubModule.xml','GUI','ModuleData','LICENSE.txt')){if(!(Test-Path -LiteralPath (Join-Path $source $relative))){throw ('Missing package input: '+$relative)}}
[xml]$template=Get-Content -Raw -LiteralPath (Join-Path $source '_Module/SubModule.xml')
if($template.Module.Version.value -cne 'v1.4.12.3' -or $template.Module.Id.value -cne 'BellumCivile'){throw 'Expected BellumCivile v1.4.12.3 module template.'}
$dotnet=Get-Command $DotnetPath -CommandType Application -ErrorAction Stop | Select-Object -First 1
New-Item -ItemType Directory -Path $out | Out-Null
$artifacts=(Join-Path $out 'artifacts').Replace('\','/')+'/'
$intermediate=(Join-Path $out 'intermediate').Replace('\','/')+'/'
$arguments=@('build',(Join-Path $source 'BellumCivile.csproj'),'-c','Release','--no-incremental',('-p:GameFolder='+$game),('-p:OutputPath='+$artifacts),('-p:BaseIntermediateOutputPath='+$intermediate),('-p:MSBuildProjectExtensionsPath='+$intermediate),'-p:AppendTargetFrameworkToOutputPath=false','-p:AppendRuntimeIdentifierToOutputPath=false','-p:ImportDirectoryBuildTargets=false')
foreach($key in $overrides.Keys){$arguments+=('-p:'+$key+'='+$overrides[$key])}
Push-Location $source
try{& $dotnet.Source @arguments 2>&1 | Tee-Object -FilePath (Join-Path $out 'build.log');$buildExit=$LASTEXITCODE}finally{Pop-Location}
if($buildExit -ne 0){throw ('Build failed; see '+(Join-Path $out 'build.log'))}
$dll=Join-Path $artifacts 'BellumCivile.dll'
if([Reflection.AssemblyName]::GetAssemblyName($dll).Name -cne 'BellumCivile'){throw 'Unexpected DLL identity.'}
$version=[Diagnostics.FileVersionInfo]::GetVersionInfo($dll)
if($version.FileVersion -ne '1.4.12.3'){throw ('Unexpected DLL file version: '+$version.FileVersion)}
$module=Join-Path $out 'Modules/BellumCivile'
$bin=Join-Path $module 'bin/Win64_Shipping_Client'
New-Item -ItemType Directory -Path $bin,(Join-Path $module 'logs') | Out-Null
Copy-Item -LiteralPath (Join-Path $source '_Module/SubModule.xml') -Destination (Join-Path $module 'SubModule.xml')
Copy-Item -LiteralPath (Join-Path $source 'GUI'),(Join-Path $source 'ModuleData') -Destination $module -Recurse
Copy-Item -LiteralPath (Join-Path $source 'LICENSE.txt') -Destination $module
$packagedDll=Join-Path $bin 'BellumCivile.dll';Copy-Item -LiteralPath $dll -Destination $packagedDll
if((Get-FileHash -LiteralPath $dll).Hash -ne (Get-FileHash -LiteralPath $packagedDll).Hash){throw 'Packaged DLL hash mismatch.'}
[ordered]@{Version=$version.FileVersion;ModuleFolder=$module;DllSha256=(Get-FileHash -LiteralPath $packagedDll).Hash;Gameplay='NOT_RUN';Scope='Core Bellum only; optional Naval companion not built';Deployed=$false} | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $out 'build-report.json')
Write-Output ('BELLUM_MODULE_BUILD_PACKAGE_PASS version=1.4.12.3; module='+$module+'; gameplay=NOT_RUN; deployed=false')
