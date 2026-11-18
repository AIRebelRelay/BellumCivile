#Requires -Version 7.2
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$temp=Join-Path ([IO.Path]::GetTempPath()) ('bellum-logs-'+[guid]::NewGuid().ToString('N'))
$count=0
function Check([bool]$ok,[string]$name){if(!$ok){throw $name};$script:count++;Write-Output ('PASS '+$name)}
try {
 $bin=Join-Path $temp 'Module With Spaces/bin/Win64_Shipping_Client'
 $logs=Join-Path $temp 'Module With Spaces/logs'
 New-Item -ItemType Directory -Path $bin,$logs | Out-Null
 $source=Get-Content -Raw -LiteralPath (Join-Path $root 'BellumCivileLogger.cs')
 $stub='namespace TaleWorlds.Library {public static class Debug {public static int Calls; public static void Print(string s){Calls++;}}}'
 Add-Type -TypeDefinition 'internal class BellumLogCompilerWarmup {}'
 $trees=[Microsoft.CodeAnalysis.SyntaxTree[]]@([Microsoft.CodeAnalysis.CSharp.CSharpSyntaxTree]::ParseText($source),[Microsoft.CodeAnalysis.CSharp.CSharpSyntaxTree]::ParseText($stub))
 $references=[Microsoft.CodeAnalysis.MetadataReference[]]@(([AppContext]::GetData('TRUSTED_PLATFORM_ASSEMBLIES') -split [IO.Path]::PathSeparator) | ForEach-Object {[Microsoft.CodeAnalysis.MetadataReference]::CreateFromFile($_)})
 $options=[Microsoft.CodeAnalysis.CSharp.CSharpCompilationOptions]::new([Microsoft.CodeAnalysis.OutputKind]::DynamicallyLinkedLibrary)
 $compilation=[Microsoft.CodeAnalysis.CSharp.CSharpCompilation]::Create('BellumLogFixture',$trees,$references,$options)
 $dll=Join-Path $bin 'BellumLogFixture.dll';$stream=[IO.File]::Create($dll)
 try{$emitted=$compilation.Emit($stream,$null,$null,$null,$null,$null,[Threading.CancellationToken]::None)}finally{$stream.Dispose()}
 if(!$emitted.Success){throw ($emitted.Diagnostics -join ' ')}
 $assembly=[Reflection.Assembly]::LoadFrom($dll);$logger=$assembly.GetType('BellumCivile.BellumCivileLogger')
 $flags=[Reflection.BindingFlags]'NonPublic,Static'
 $resolve=$logger.GetMethod('ResolveLogDirectory',$flags)
 Check ($resolve.Invoke($null,[object[]]@([string]$dll)) -eq $logs) 'resolve actual module location with spaces'
 $rejected=$false;try{$resolve.Invoke($null,[object[]]@([string](Join-Path $temp 'wrong.dll'))) | Out-Null}catch{$rejected=$true}
 Check $rejected 'invalid installation layout rejected'
 $today=[DateTime]::Now.ToString('yyyyMMdd');$old=[DateTime]::Today.AddDays(-6).ToString('yyyyMMdd')
 $oldFile=Join-Path $logs ("BellumCivile$old.log");[IO.File]::WriteAllText($oldFile,'old')
 $other=Join-Path $logs 'other.log';[IO.File]::WriteAllText($other,'keep')
 $current=Join-Path $logs ("BellumCivile$today.log");$rotated=Join-Path $logs ("BellumCivile${today}_1.log")
 [IO.File]::WriteAllBytes($current,[byte[]]::new(5*1024*1024))
 $log=$logger.GetMethod('Log');$flush=$logger.GetMethod('Flush');$year=$logger.GetMethod('LogYearlyReport')
 $log.Invoke($null,@('fixture first')) | Out-Null;$flush.Invoke($null,@()) | Out-Null
 Check ((Get-Content -Raw $rotated) -match '\[\d{4}-\d{2}-\d{2} .*\] fixture first') 'normal log format and five-megabyte rotation'
 Check (!(Test-Path $oldFile) -and (Test-Path $other)) 'old dated logs pruned while unrelated file retained'
 $before=(Get-Item $rotated).Length;$log.Invoke($null,@('  ')) | Out-Null;$flush.Invoke($null,@()) | Out-Null
 Check ((Get-Item $rotated).Length -eq $before) 'blank normal message ignored'
 $year.Invoke($null,@('politics','yearly fixture')) | Out-Null
 $report=Join-Path $logs 'bellumcivile_yearlyreports.txt'
 Check ((Get-Content -Raw $report) -match '\[politics\].*\r?\nyearly fixture') 'yearly report in same module logs folder'
 $year.Invoke($null,@('','default category')) | Out-Null
 Check ((Get-Content -Raw $report) -match '\[general\]') 'empty yearly category retains general fallback'
 $before=(Get-Item $report).Length;$year.Invoke($null,@('x',' ')) | Out-Null
 Check ((Get-Item $report).Length -eq $before) 'blank yearly report ignored'
 $logger.GetMethod('CloseLogWriter',$flags).Invoke($null,@()) | Out-Null
 Remove-Item $logs -Recurse -Force;[IO.File]::WriteAllText($logs,'blocked directory')
 $log.Invoke($null,@('cannot write')) | Out-Null;$year.Invoke($null,@('x','cannot write')) | Out-Null;$flush.Invoke($null,@()) | Out-Null
 Check ($assembly.GetType('TaleWorlds.Library.Debug').GetField('Calls').GetValue($null) -eq 1) 'write failure contained with existing debugger fallback'
 Check ($source -notmatch 'GetFolderPath|MyDocuments|LocalApplicationData|ModLogs') 'no external log directory fallback'
 $runner=Get-Content -Raw -LiteralPath (Join-Path $root 'scripts/Build-CrBellumModuleWindows.ps1')
 $packageStart=$runner.IndexOf('$module=Join-Path')
 if($packageStart -lt 0){throw 'Package boundary not found'}
 $source=$root;$out=Join-Path $temp 'build-result';New-Item -ItemType Directory -Path $out | Out-Null
 $version=[pscustomobject]@{FileVersion='1.4.12.3'}
 . ([scriptblock]::Create($runner.Substring($packageStart)))
 Check ((Test-Path "$module/SubModule.xml") -and (Test-Path "$module/bin/Win64_Shipping_Client/BellumCivile.dll") -and (Test-Path "$module/logs" -PathType Container)) 'actual packaging block creates full module layout using fixture DLL'
 $expected=@(Get-ChildItem (Join-Path $root 'GUI'),(Join-Path $root 'ModuleData') -Recurse -File)
 $equal=$true
 foreach($item in $expected){$relative=[IO.Path]::GetRelativePath($root,$item.FullName);$target=Join-Path $module $relative;if(!(Test-Path -LiteralPath $target) -or (Get-FileHash $item.FullName).Hash -ne (Get-FileHash $target).Hash){$equal=$false}}
 Check ($equal -and (Test-Path "$module/LICENSE.txt")) 'all GUI XML localization and license copied unchanged'
 [xml]$manifest=Get-Content -Raw "$module/SubModule.xml"
 Check ($manifest.Module.Version.value -ceq 'v1.4.12.3') 'packaged XML uses new hotfix version'
 Write-Output ('BELLUM_MODULE_LOG_PASS '+$count+' named checks; full game build NOT_RUN')
} finally {
 if($logger){$logger.GetMethod('CloseLogWriter',[Reflection.BindingFlags]'NonPublic,Static').Invoke($null,@()) | Out-Null}
 Remove-Item -LiteralPath $temp -Recurse -Force
}
