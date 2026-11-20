#Requires -Version 7.2
# Force launch: pwsh -NoProfile -ExecutionPolicy Bypass -File .\scripts\Test-ForeignDiplomacyCheckpoint.ps1
# Does not build/deploy. Every suite failure is reported; packaging uses fixture DLLs.
$ErrorActionPreference='Stop'
$PSNativeCommandUseErrorActionPreference=$false
$root=Split-Path $PSScriptRoot -Parent
$pwsh=(Get-Process -Id $PID).Path
$results=@()
foreach($name in @('ForeignConflictIdentity.Tests','WarConflictIdentity.Tests','ForeignCrisisWindow.Tests','ForeignCrisisBudget.Tests','ForeignDiplomacyJournal.Tests','ForeignDiplomacyJournal.Schema.Tests','ForeignDiplomacyJournal.Mutations',
 'ForeignDiplomacyAdmission.Tests','ForeignDiplomacyAdmission.Mutations','ExistingPoliticalPressure.Tests','ExistingWarState.Tests',
 'ExistingClaimState.Tests','ExistingCouncilState.Tests','ExistingRecordedName.Tests','RealmPreparationReceipt.Tests',
 'CompleteReleaseNaval.Tests','ModuleLocalLogs.Tests')){
 & $pwsh -NoProfile -ExecutionPolicy Bypass -File (Join-Path $root "Tests/$name.ps1")
 $results+=[pscustomobject]@{Test=$name;ExitCode=$LASTEXITCODE}
}
$results | ConvertTo-Json
if(@($results | Where-Object {$_.ExitCode -ne 0}).Count -ne 0){throw 'CHECKPOINT_NOT_GREEN: inspect failing suites.'}
Write-Output 'CHECKPOINT_FIXTURES_PASS; actual Windows build and game/save-load NOT_RUN'
