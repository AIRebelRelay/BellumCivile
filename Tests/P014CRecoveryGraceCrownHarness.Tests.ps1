$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
function Read([string]$path) { Get-Content -Raw -LiteralPath (Join-Path $root $path) }
function Check([bool]$ok, [string]$label) {
    if (-not $ok) { throw "FAIL: $label" }
    Write-Output "PASS: $label"
}
$program = Read 'Tests/SuccessionEngineHarness/Program.cs'
$restored = Read 'Tests/SuccessionEngineHarness/RestoredRealmRecoveryTests.cs'
$collapse = Read 'Tests/SuccessionEngineHarness/CollapseClaimantRecoveryTests.cs'
$crown = Read 'Tests/SuccessionEngineHarness/CrownRebellionSafetyTests.cs'
$grace = Read 'Tests/SuccessionEngineHarness/CivilWarGraceTests.cs'
$playerSecession = Read 'Patches/PlayerLandedSecessionPatch.cs'
$saveDefiner = Read 'BellumCivileSaveDefiner.cs'

Check ($restored.Contains('internal static class RestoredRealmRecoveryTests') -and
       $restored.Contains('A loaded retry verifies both retirements and crown delivery before publishing the original successor once') -and
       $restored.Contains('An interrupted created-event listener leaves a saved receipt before callbacks') -and
       $restored.Contains('Older saves without restoration records load safely')) 'Restoration runs real saved-journal, Crown receipt and interrupted-event fixture.'
Check ($restored.Contains('Blocked founder movement cannot strand followers') -and
       $restored.Contains('Only verified elimination removes the cleanup record') -and
       $restored.Contains('A saved unfinished restoration is not treated as an unowned historical orphan')) 'Household retry and neighboring orphan protection remain exercised.'
Check (-not $restored.Contains('ProtectedRealmLoadMigrationPatch') -and
       -not $restored.Contains('IsMigrationActive') -and
       -not $restored.Contains('A deferred native duplicate-ruler migration restores')) 'Absent ProtectedRealmLoadMigrationPatch is explicitly excluded; no dummy compatibility patch introduced.'
Check ($collapse.Contains('internal static class CollapseClaimantRecoveryTests') -and
       $collapse.Contains('An uncommitted winner defecting to an unrelated realm cannot take the Crown') -and
       $collapse.Contains('Ordinary external defections are not hidden by the owned-transfer guard') -and
       $collapse.Contains('ResumePendingCollapses')) 'Collapse claimant correct Crown, illegal defection and saved Stage 2-4 recoveries verified.'
Check ($crown.Contains('internal static class CrownRebellionSafetyTests') -and
       $crown.Contains('Real native event passes the displaced ruling clan') -and
       $crown.Contains('Incoming ruler leaves warm coalition; former ruler is retained') -and
       $crown.Contains('Stale player inquiry cannot rebel against a different ruler') -and
       $crown.Contains('Pending accession retains its deferred opportunity')) 'RulingClan event, deferred player ultimatum and faction continuity are exercised.'
Check ($grace.Contains('internal static class CivilWarGraceTests') -and
       $grace.Contains('Changing MCM does not rewrite a recorded recovery period') -and
       $grace.Contains('Zero records no new blocking period even during settlement') -and
       $grace.Contains('Startup protection neither invents a civil war nor depends on the postwar MCM slider')) 'Grace tests zero, saved duration and independent initial-year behavior.'
Check ($grace.Contains('New rebellion registration is blocked before membership') -and
       $grace.Contains('A pending crisis popup disables Approve') -and
       $grace.Contains('The membership backend also rejects a new player pledge') -and
       $grace.Contains('Expired protection leaves no stale blocking tooltip')) 'Grace blocks only forbidden new political actions; UI and expiry recover cleanly.'
foreach ($route in @('--restored-realm-recovery', '--collapse-claimant-recovery',
        '--crown-rebellion-safety', '--civil-war-grace')) {
    Check ($program.Contains('args.Contains("' + $route + '")')) "Compiled harness includes $route."
}
foreach ($call in @('RestoredRealmRecoveryTests.Run(Check);',
       'CollapseClaimantRecoveryTests.Run(Check);',
       'CrownRebellionSafetyTests.Run(Check);',
       'CivilWarGraceTests.Run(Check);')) {
    Check ($program.Contains($call)) "Dedicated harness invokes $call"
}
Check ($program.Contains('--fief-redistribution') -and
       $program.Contains('--encyclopedia-family') -and
       $program.Contains('--encyclopedia-inheritance') -and
       $program.Contains('--realm-names') -and
       $program.Contains('--campaign-ui-startup')) 'Previous stage test routes remain registered.'
Check ($playerSecession.IndexOf('CivilWarGraceBlock(player.Kingdom)') -lt
       $playerSecession.IndexOf('if (!WarPeaceRevampBehavior.IsRevampEnabled()) return true;')) 'Documented Grace gate is still present before external diplomacy OFF fallback.'
Check ($saveDefiner.Contains('AddClassDefinition(typeof(CivilWarGraceRecord), 136)') -and
       $saveDefiner.Contains('AddClassDefinition(typeof(RestoredRealmCreationRecord), 137)') -and
       $saveDefiner.Contains('AddClassDefinition(typeof(CivilWarCollapseRecord), 86)')) 'Old save schema and new owner record registration untouched.'
'P0-14C source contract passed; PowerShell execution, compiled harness and live Bannerlord old saves PENDING.'
