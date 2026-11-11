# P0-05 source regression contract, RED-first before production code.
# Official author source: Vonbalt/BellumCivile @ da426b23c64f3a66ae2b389d2db8f23489736bf9.
# This is structural only. Executable tests, full final DLL build and live game/old-save QA are deferred.
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
function ReadSource($path) { Get-Content -Raw -LiteralPath (Join-Path $root $path) }
function Check($ok, $name) { if (!$ok) { throw "FAIL: $name" }; "PASS: $name" }
$guard = ReadSource 'Behaviors/FactionSuccessionSafety.cs'
$manager = ReadSource 'Behaviors/FactionManagerBehavior.cs'
$faction = ReadSource 'FactionObject.cs'
$grace = ReadSource 'Behaviors/CivilWarGrace.cs'
$save = ReadSource 'BellumCivileSaveDefiner.cs'

Check ($guard.Contains('private Dictionary<string, string> _pendingSuccessionOpportunities')
    -and $guard.Contains('private static bool IsWarmingCrownFaction(FactionObject faction)')
    -and $guard.Contains('!faction.HasTrackedRebelKingdom')
    -and $guard.Contains('!faction.IsChallengeStartupPending')
    -and $guard.Contains('!faction.IsRebellionCreationPending')
    -and $guard.Contains('!faction.HasStartedCivilWar')) 'Only not-yet-committed crown factions can be reconciled; active/partial/challenge armies are fenced.'
Check ($guard.Contains('CivilWarConflictBehavior.IsFactionTransferPending(faction)')
    -and $guard.Contains('faction.Leader == ruler')
    -and $guard.Contains('faction.Members.Contains(ruler)')
    -and $guard.Contains('faction.RemoveMember(ruler)')) 'A newly crowned ruler cannot retain a warm rebel coalition; pending transfers remain protected.'
Check ($manager.Contains('HourlyTickEvent.AddNonSerializedListener(this, ProcessSuccessionOpportunities)')
    -and $manager.Contains('dataStore.SyncData("BellumCivile_PendingSuccessionOpportunities", ref _pendingSuccessionOpportunities)')
    -and $manager.Contains('_pendingSuccessionOpportunities = _pendingSuccessionOpportunities ?? new Dictionary<string, string>()')) 'Deferred opportunities have an hourly owner and old-save-safe persistent dictionary.'
Check ($manager.Contains('ReconcileWarmingCrownFactions(realm);')
    -and $manager.Contains('ReconcileWarmingCrownFactions(kingdom, rulerChanged: oldRulingClan != newRulingClan)')) 'Daily maintenance and the ruler event reconcile only warm factions.'
Check ($manager.Contains('Clan newRulingClan = kingdom.RulingClan;')
    -and $manager.Contains('ReportRulingClanChangedEvent(kingdom, newRulingClan)')
    -and $manager.Contains('_pendingSuccessionOpportunities[kingdom.StringId] = newRulingClan.StringId')) 'Native RulingClanChanged gives displaced ruler; actual incoming sovereign is queried and queued.'
Check ($guard.Contains('!CivilWarConflictBehavior.IsRealmTransferPending(realm)')
    -and $guard.Contains('CrownAccessionBehavior.Instance?.IsPending(realm)')
    -and $guard.Contains('ElectiveSuccessionBehavior.Instance?.PendingDeposition(realm)')
    -and $guard.Contains('KingSelectionKingdomDecision')) 'No opportunity during Crown accession, transfer, deposition or unresolved election.'
Check ($guard.Contains('_pendingSuccessionOpportunities.Remove(pending.Key);')
    -and $guard.Contains('if (!SuccessionOpportunityReady(realm)) continue;')
    -and $guard.Contains('if (IsCurrentSuccessionOpportunity(faction, ruler, monarch)) faction.TriggerUltimatum();')) 'Deferred opportunity validates readiness and current faction state and consumes its receipt.'
Check ($faction.Contains('private bool TryGetRebellionCrown(out Clan crown, out string failureReason)')
    -and $faction.Contains('private bool RebellionCrownUnchanged(Clan expected, out string failureReason)')
    -and $faction.Contains('the faction leader is the parent kingdom''s reigning clan')) 'Rebellion cannot target its own ruling house or an invalid Crown.'
Check ($faction.Contains('if (!FactionManagerBehavior.SuccessionOpportunityReady(ParentKingdom)) return "the crown transition is still pending";')
    -and $faction.Contains('Leader.Kingdom != ParentKingdom || !FactionManagerBehavior.SuccessionOpportunityReady(ParentKingdom)')
    -and $faction.Contains('if (!resumeChallenge && !FactionManagerBehavior.SuccessionOpportunityReady(ParentKingdom))')) 'New ultimatums and rebel starts wait for transition; saved challenge resumes retain a dedicated exception.'
Check (([regex]::Matches($faction, 'RebellionCrownUnchanged\(crown, out failureReason\)')).Count -ge 6
    -and $faction.Contains('if (Members.Contains(crown)) RemoveMember(crown);')) 'Startup, adoption and partial retries repeatedly verify the same Crown and exclude reigning house.'
Check ($manager.Contains('OwnsCollapseHouseholdTransfer(faction, clan, oldKingdom, newKingdom)')
    -and $manager.Contains('OwnsRestoredHouseholdTransfer(faction, clan, oldKingdom, newKingdom)')
    -and $manager.Contains('ReportRulingClanChangedEvent(kingdom, newRulingClan)')) 'P1-01E/F ownership and custom ruler-transition logging remain intact.'
Check ($grace.Contains('BC_CivilWarGrace')
    -and $manager.Contains('MaintainCivilWarGrace')
    -and $manager.Contains('SyncCivilWarGrace(dataStore)')) 'P0-04 Grace author mechanics remain connected.'
Check ($save.Contains('ConstructContainerDefinition(typeof(Dictionary<string, string>))')) 'Saved succession opportunity uses the existing container: no SaveDefiner changes.'
'P0-05 source contract complete; end-to-end tests will run with the single final complete BellumCivile.dll.'
