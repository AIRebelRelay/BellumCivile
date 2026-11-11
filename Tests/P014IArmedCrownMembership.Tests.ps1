# P0-14I surgical source contract: crowned house must not join its own armed faction.
# RED first. The executable CrownRebellionSafetyTests fixture verifies the native FactionObject.AddMember behavior.
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
function Read([string]$file) { Get-Content -Raw -LiteralPath (Join-Path $root $file) }
function Check([bool]$ok,[string]$name) {
    if (-not $ok) { throw "P014I_FAIL $name" }
    Write-Host "P014I_PASS $name"
}
$faction = Read 'FactionObject.cs'
$manager = Read 'Behaviors/FactionSuccessionSafety.cs'
$fixture = Read 'Tests/SuccessionEngineHarness/CrownRebellionSafetyTests.cs'
$ideology = Read 'Behaviors/IdeologyBehavior.cs'
$ui = Read 'UI/FactionsWindowVM.cs'
$barter = Read 'JoinFactionBarterable.cs'
$transfer = Read 'Behaviors/FactionManagerBehavior.cs'
$start = $faction.IndexOf('public void AddMember(Clan clan)')
$end = $faction.IndexOf('public void RemoveMember(Clan clan)', $start)
Check ($start -ge 0 -and $end -gt $start) 'membership_method_located'
$method = $faction.Substring($start, $end - $start)
Check ($method.Contains('if (!IsIdeology && clan == ParentKingdom?.RulingClan) return;')) 'no_new_armed_membership_for_own_crown'
Check ($method.IndexOf('if (!IsIdeology && clan == ParentKingdom?.RulingClan) return;') -lt $method.IndexOf('if (_declaredLoyalist == clan)')) 'guard_precedes_membership_and_loyalist_mutation'
Check ($method.Contains('(IsIdeology && !CourtMembershipEligibility.CanBelong(clan, ParentKingdom))') -and
    $method.Contains('IsCivilWarGraceBlocked(this)') -and
    $method.Contains('CivilWarGraceJoinBlock(this)')) 'ideology_and_grace_guards_preserved'
Check ($method.Contains('if (!Members.Contains(clan))') -and $method.Contains('Members.Add(clan);') -and
    $method.Contains('InvalidatePowerProjection();') -and $method.Contains('InvalidateFactionLookupCache();') -and
    $method.Contains('if (HasTrackedRebelKingdom || IsCivilWarActive())')) 'normal_member_add_and_active_war_accounting_preserved'
Check ($manager.Contains('faction.RemoveMember(ruler);') -and
    $manager.Contains('CivilWarConflictBehavior.IsFactionTransferPending(faction)')) 'accession_cleanup_and_pending_transfer_preserved'
Check ($fixture.Contains('Ruling clan cannot be added to another armed faction') -and
    $fixture.Contains('Ordinary vassal can still join an armed faction') -and
    $fixture.Contains('Ordinary vassal can still join a court faction')) 'runtime_positive_and_neighboring_checks_present'
Check ($ideology.Contains('faction.AddMember(expelled);') -and
    $ui.Contains('selectedBackendFaction.AddMember(Clan.PlayerClan);') -and
    $barter.Contains('_faction.AddMember(_targetHero.Clan);') -and
    $transfer.Contains('activeRebellion.AddMember(clan);')) 'known_ideology_ui_barter_and_rebel_transfer_callers_preserved'
Write-Host 'P014I_SOURCE_PASS; compiled executable and old-save/game validation still pending.'
