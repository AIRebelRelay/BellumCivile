$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
Push-Location $root
try {
    $raw = (& dotnet msbuild ./BellumCivile.csproj '-getItem:Compile' -nologo | Out-String)
    if ($LASTEXITCODE -ne 0) { throw "MSBuild item evaluation failed: $raw" }
    $data = $raw | ConvertFrom-Json
    $items = @($data.Items.Compile | ForEach-Object { $_.Identity -replace '\\','/' })
    foreach ($stub in @('Tests/AiInfluenceNpcCrownStage6.Stubs.cs',
                         'Tests/AiInfluenceNpcCrownStage7.Stubs.cs')) {
        if ($items -contains $stub) { throw "FAIL: test stub shipped in BellumCivile.dll: $stub" }
        Write-Host "PASS STAGE7_COMPILE_ITEMS excluded=$stub"
    }
    foreach ($required in @('Behaviors/CourtNpcTreasonAssignment.cs',
                             'Behaviors/CourtNpcTreasonIntents.cs',
                             'BellumIntegrationNpcCrown.cs',
                             'NpcCrownTreasonIntentRecord.cs')) {
        if ($items -notcontains $required) { throw "FAIL: production source excluded: $required" }
        Write-Host "PASS STAGE7_COMPILE_ITEMS present=$required"
    }
    Write-Host 'STAGE7_COMPILE_ITEMS_PASS — MSBuild item evaluation only, NOT full game DLL build.'
}
finally { Pop-Location }
