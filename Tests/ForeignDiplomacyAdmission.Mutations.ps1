#Requires -Version 7.2
# Force launch: pwsh -NoProfile -ExecutionPolicy Bypass -File .\Tests\ForeignDiplomacyAdmission.Mutations.ps1
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $false
$root = Split-Path $PSScriptRoot -Parent
$source = Get-Content -Raw -LiteralPath (Join-Path $root 'ForeignDiplomacyAdmissionPolicy.cs')
$pwsh = (Get-Process -Id $PID).Path
$cases = @(
    @('owner_fault_falls_through', 'if (!ownerReady) return ForeignDiplomacyAdmission.Hold;', 'if (!ownerReady) return ForeignDiplomacyAdmission.Legacy;'),
    @('terminal_becomes_ordinary_intent', 'return ForeignDiplomacyAdmission.RequestCrisisResolution;', 'return ForeignDiplomacyAdmission.RequestLlmIntent;'),
    @('ratification_accepts_without_consent', 'return exactDraftConsent', 'return true'),
    @('pending_activation_allowed', 'if (readiness.LegacyPendingCount != 0)', 'if (readiness.LegacyPendingCount == int.MinValue)'),
    @('default_unknown_permitted', "default:`n                    return ForeignDiplomacyAdmission.Hold;", "default:`n                    return ForeignDiplomacyAdmission.Legacy;")
)
# Normalize only the temporary mutation input; preserve original production bytes.
$source = $source.Replace("`r`n", "`n")
foreach ($case in $cases) {
    $name, $before, $after = $case
    if ([regex]::Matches($source, [regex]::Escape($before)).Count -ne 1) { throw "Mutation boundary changed: $name" }
    $temp = Join-Path ([IO.Path]::GetTempPath()) ('foreign-mutant-' + [Guid]::NewGuid().ToString('N'))
    $tests = Join-Path $temp 'Tests'
    New-Item -ItemType Directory -Path $tests | Out-Null
    try {
        [IO.File]::WriteAllText((Join-Path $temp 'ForeignDiplomacyAdmissionPolicy.cs'), $source.Replace($before, $after))
        Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'ForeignDiplomacyAdmissionHarness') -Destination $tests -Recurse
        $runner = Join-Path $tests 'ForeignDiplomacyAdmission.Tests.ps1'
        Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'ForeignDiplomacyAdmission.Tests.ps1') -Destination $runner
        $output = (& $pwsh -NoProfile -ExecutionPolicy Bypass -File $runner 2>&1 | Out-String)
        $code = $LASTEXITCODE
        if ($code -eq 0 -or $output -notmatch 'FAIL' -or $output -notmatch 'Exception calling' -or $output -match 'Add-Type:') {
            throw "Mutation not rejected by behavioral assertion: $name`n$output"
        }
        Write-Output ('MUTATION_REJECTED ' + $name)
    } finally { Remove-Item -LiteralPath $temp -Recurse -Force }
}
Write-Output 'TOTAL MUTATIONS REJECTED 5'
