#Requires -Version 7.2
# Force launch: pwsh -NoProfile -ExecutionPolicy Bypass -File .\Tests\ForeignDiplomacyJournal.Tests.ps1
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$temp=Join-Path ([IO.Path]::GetTempPath()) ('foreign-journal-'+[guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $temp | Out-Null
try {
 foreach($name in @('Fixtures','Scenarios')) {
  Copy-Item -LiteralPath (Join-Path $root "Tests/ForeignDiplomacyJournalHarness/$name.cs.txt") -Destination (Join-Path $temp "$name.cs")
 }
 $paths=@('ForeignDiplomacyAdmissionPolicy.cs','ForeignDiplomacyJournalRecords.cs','ForeignDiplomacyJournal.cs',
 'Behaviors/IntegrationForeignDiplomacy.cs','Behaviors/BellumIntegrationBehavior.cs') | ForEach-Object {Join-Path $root $_}
 $paths+=@(Get-ChildItem -LiteralPath $temp -Filter *.cs | ForEach-Object FullName)
 Add-Type -Path $paths -CompilerOptions '/langversion:7.3'
 [ForeignDiplomacyJournalScenarios]::Run()
} finally {Remove-Item -LiteralPath $temp -Recurse -Force}
