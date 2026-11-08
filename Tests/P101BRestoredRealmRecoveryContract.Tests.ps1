$ErrorActionPreference = 'Stop'
# P1-01B RED-first source/schema gate ONLY. Real runtime, save/load and Bridge
# behavior regressions are listed in issue #96 and MUST be executed separately.
$root = Split-Path -Parent $PSScriptRoot
function Read([string]$file) {
    $path = Join-Path $root $file
    if (-not (Test-Path -LiteralPath $path)) { throw "P101B_RED missing $file" }
    return Get-Content -LiteralPath $path -Raw
}
function Require([bool]$ok, [string]$name) {
    if (-not $ok) { throw "P101B_RED $name" }
    Write-Host "P101B_PASS $name"
}
$record = Read 'RestoredRealmCreationRecord.cs'
$save = Read 'BellumCivileSaveDefiner.cs'
$resolver = Read 'Behaviors/CivilWarResolutionBehavior.cs'
$recovery = Read 'Behaviors/RestoredRealmRecovery.cs'
$crown = Read 'Behaviors/CivilWarCrownTransfer.cs'
$destruction = Read 'Patches/CivilWarParentDestructionPatch.cs'
$orphan = Read 'Behaviors/RestoredRealmOrphanRecovery.cs'

Require ($save.Contains('AddClassDefinition(typeof(RestoredRealmCreationRecord), 137);')) 'saved class ID 137'
Require ($save.Contains('ConstructContainerDefinition(typeof(List<RestoredRealmCreationRecord>));')) 'saved record list container'
$allIds = @()
foreach ($m in [regex]::Matches($save, 'Add(?:Class|Enum)Definition\(typeof\(.+?\),\s*(\d+)\)')) { $allIds += [int]$m.Groups[1].Value }
Require ($allIds.Count -eq (@($allIds | Select-Object -Unique)).Count) 'no duplicate class/enum save IDs'
$fields = @([regex]::Matches($record, '\[SaveableField\((\d+)\)\]') | ForEach-Object { [int]$_.Groups[1].Value } | Sort-Object)
Require ($fields.Count -eq 17 -and (($fields -join ',') -eq ((1..17) -join ','))) 'record field IDs 1..17 unchanged'
Require ($record.Contains('internal bool Protects(Kingdom realm)') -and $record.Contains('!Ready')) 'only unfinished restoration is protected'
Require ($resolver.Contains('SyncData("BC_RestoredRealmCreations", ref _restoredCreations);')) 'stable save key'
Require ($resolver.Contains('_restoredCreations = _restoredCreations ?? new List<RestoredRealmCreationRecord>();')) 'missing old-save collection defaults safely'
Require ($resolver.Contains('ResumePendingRestoredCreations();')) 'saved restoration retried'
Require ($recovery.Contains('PrepareRestoredRealm(') -and $recovery.Contains('_restoredCreations.Add(record);')) 'new restoration recorded before transfer'
Require ($recovery.Contains('record.MovesComplete = true;') -and $recovery.Contains('record.Ready = true;')) 'distinct membership and completed receipts'
$receipt = $recovery.IndexOf('record.CreatedNotified = true;', [StringComparison]::Ordinal)
$dispatch = $recovery.IndexOf('CampaignEventDispatcher.Instance.OnKingdomCreated(realm);', [StringComparison]::Ordinal)
Require ($receipt -ge 0 -and $dispatch -gt $receipt -and
    $recovery.Contains('if (!record.CreatedNotified)')) 'created event receipt persisted before dispatch'
Require ($recovery.Contains('IsRestoredRetirementAuthorized(Kingdom realm)') -and
    $destruction.Contains('.IsRestoredRetirementAuthorized(destroyedKingdom) == true')) 'parent destruction authorized only by restoration coordinator'
Require ($crown.Contains('IsRestoredCreationPending(realm)') -and
    $crown.Contains('IsOtherRealmTransferPending(Kingdom realm)')) 'restoration blocks general kingdom transfer, with distinct internal guard'
Require ($resolver.Contains('private static bool TransferClansToKingdom(') -and
    $resolver.Contains('private static bool TransferLiveClansFromEliminatedKingdom(')) 'clan transfers report completion for retries'
Require ($orphan.Contains('IsOrphanedRestoredRealm(') -and
    $orphan.Contains('IsKingdomIdReferencedByBellumCivileState(realm.StringId)')) 'orphan sweep excludes still-referenced realms'
Write-Host 'P101B_PASS structural RED-first contract; behavior/save/game test status is NOT RUN'
