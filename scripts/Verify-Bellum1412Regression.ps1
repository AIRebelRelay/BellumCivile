param(
    [string]$GameFolder = 'F:\Steam\steamapps\common\Mount & Blade II Bannerlord',
    [string]$WorkshopFolder = 'F:\Steam\steamapps\workshop\content\261550',
    [string]$LogFolder = (Join-Path $env:TEMP ('Bellum-regression-' + (Get-Date -Format 'yyyyMMdd-HHmmss'))),
    [switch]$AllRoutes,
    [int]$TimeoutSeconds = 600
)
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$project = Join-Path $root 'Tests\SuccessionEngineHarness\SuccessionEngineHarness.csproj'
$harmony = Join-Path $WorkshopFolder '2859188632\bin\Win64_Shipping_Client\0Harmony.dll'
$ui = Join-Path $WorkshopFolder '2859222409\bin\Win64_Shipping_Client\Bannerlord.UIExtenderEx.dll'
$mcm = Join-Path $WorkshopFolder '2859238197\bin\Win64_Shipping_Client\MCMv5.dll'
$cecil = Join-Path $WorkshopFolder '2859188632\bin\Win64_Shipping_Client\Mono.Cecil.dll'
foreach ($path in @($project, $harmony, $ui, $mcm, $cecil,
        (Join-Path $GameFolder 'bin\Win64_Shipping_Client\TaleWorlds.CampaignSystem.dll'))) {
    if (!(Test-Path -LiteralPath $path -PathType Leaf)) { throw "Missing dependency: $path" }
}
New-Item -ItemType Directory -Path $LogFolder -Force | Out-Null
& dotnet build $project -c Release "-p:GameFolder=$GameFolder" `
    "-p:HarmonyDllPath=$harmony" "-p:UIExtenderExDllPath=$ui" `
    "-p:McmDllPath=$mcm" "-p:MonoCecilDllPath=$cecil" *> (Join-Path $LogFolder 'build.log')
if ($LASTEXITCODE -ne 0) {
    Get-Content (Join-Path $LogFolder 'build.log') -Tail 25
    throw "BUILD FAILED; logs: $LogFolder"
}
Write-Host 'BUILD PASSED' -ForegroundColor Green
$exe = Join-Path $root 'Tests\SuccessionEngineHarness\bin\Release\net472\SuccessionEngineHarness.exe'
if (!(Test-Path -LiteralPath $exe)) { throw "Harness not produced: $exe" }
$routes = @('--de-jure-drift', '--lordships', '--crown-rebellion-safety',
    '--regency-adulthood-157', '--court-term-preparation', '--ai-foreign-ledger',
    '--peacetime-pact-rules', '--encyclopedia-inheritance', '--campaign-ui-startup')
if ($AllRoutes) {
    $source = Get-Content (Join-Path $root 'Tests\SuccessionEngineHarness\Program.cs') -Raw
    $routes = @([regex]::Matches($source, 'args\.Contains\("(--[a-z0-9-]+)"\)') |
        ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique)
}
# The empty route is the unchanged default full harness, always run in a fresh process.
$routes += ''
$results = foreach ($route in $routes) {
    $name = if ($route) { $route.Substring(2) } else { 'full-regression' }
    $stdout = Join-Path $LogFolder "$name.log"
    $stderr = Join-Path $LogFolder "$name.stderr.log"
    $arguments = @('"' + $GameFolder + '"')
    if ($route) { $arguments += $route }
    $process = $null
    try {
        $process = Start-Process -FilePath $exe -ArgumentList $arguments -PassThru `
            -RedirectStandardOutput $stdout -RedirectStandardError $stderr
        if (!$process.WaitForExit($TimeoutSeconds * 1000)) {
            $process.Kill()
            $process.WaitForExit()
            $status = 'TIMEOUT'
            $code = $null
        } else {
            $process.WaitForExit()
            $code = $process.ExitCode
            $status = if ($code -eq 0) { 'PASS' } else { 'FAIL' }
        }
        [pscustomobject]@{ Route = $name; Status = $status; ExitCode = $code; Detail = '' }
    } catch {
        [pscustomobject]@{ Route = $name; Status = 'ERROR'; ExitCode = $null; Detail = $_.Exception.Message }
    } finally {
        if ($null -ne $process) { $process.Dispose() }
    }
}
$results | Export-Csv (Join-Path $LogFolder 'summary.csv') -NoTypeInformation -Encoding UTF8
$results | Format-Table -AutoSize
Write-Host "Logs: $LogFolder"
if (@($results | Where-Object Status -ne 'PASS').Count -gt 0) {
    throw 'REGRESSION FAILED; see summary.csv and per-route logs.'
}
Write-Host 'ALL REQUESTED REGRESSIONS PASSED' -ForegroundColor Green
