#Requires -Version 7.2
# Force launch: pwsh -NoProfile -ExecutionPolicy Bypass -File .\Tests\ForeignDiplomacyJournal.Schema.Tests.ps1
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$source=Get-Content -Raw -LiteralPath (Join-Path $root 'BellumCivileSaveDefiner.cs')
$baseline=Get-Content -Raw -LiteralPath (Join-Path $root 'Tests/ForeignDiplomacyJournalHarness/SaveSchemaBaseline.json') | ConvertFrom-Json
$definitions=@([regex]::Matches($source,'Add(?:Class|Enum)Definition\(typeof\(.+?\),\s*\d+\);') | ForEach-Object Value)
$containers=@([regex]::Matches($source,'ConstructContainerDefinition\(typeof\(.+?\)\);') | ForEach-Object Value)
$new=@('AddClassDefinition(typeof(ForeignDiplomacyJournalState), 150);','AddClassDefinition(typeof(ForeignDiplomacyIntentRecord), 151);')
$newContainer='ConstructContainerDefinition(typeof(List<ForeignDiplomacyIntentRecord>));'
function Check([bool]$ok,[string]$name){if(!$ok){throw "SCHEMA_FAIL $name"};Write-Output ('SCHEMA_PASS '+$name)}
Check ((($definitions | Where-Object {$_ -cnotin $new}) -join "`n") -ceq ($baseline.definitions -join "`n")) 'all_existing_type_definitions_and_order_preserved'
Check ((($containers | Where-Object {$_ -cne $newContainer}) -join "`n") -ceq ($baseline.containers -join "`n")) 'all_existing_container_definitions_and_order_preserved'
foreach($entry in $new){Check (@($definitions | Where-Object {$_ -ceq $entry}).Count -eq 1) $entry}
Check (@($containers | Where-Object {$_ -ceq $newContainer}).Count -eq 1) 'new_list_registered_once'
$ids=@($definitions | ForEach-Object {[int]([regex]::Match($_,',\s*(\d+)\);').Groups[1].Value)})
Check (@($ids | Sort-Object -Unique).Count -eq $ids.Count) 'global_class_enum_ids_unique'
Check ($definitions.Count -eq $baseline.definitions.Count+2 -and $containers.Count -eq $baseline.containers.Count+1) 'only_two_types_one_container_added'
Check ($source.Contains('public const int SaveBaseId = 8456123;')) 'save_base_id_unchanged'
Write-Output 'SCHEMA TOTAL PASS 8; Native registry startup NOT_RUN'
