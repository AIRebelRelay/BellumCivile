# Compile the exact early membership guards and ownership predicates against minimal types.
# This isolates the entry fence, NOT the remainder of OnClanChangedKingdom or a live campaign.
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
function ReadSource($p) { Get-Content -LiteralPath (Join-Path $root $p) -Raw }
function Expression($text, $name) {
    $m = [regex]::Match($text, '(?s)internal bool ' + $name + '\([^;{}]*\)\s*=>\s*(?<body>.*?);')
    if (!$m.Success) { throw "Cannot extract production expression: $name" }
    $m.Groups['body'].Value
}
$manager = ReadSource 'Behaviors/FactionManagerBehavior.cs'
$start = $manager.IndexOf('private void OnClanChangedKingdom(')
$begin = $manager.IndexOf('if (!faction.Members.Contains(clan)) continue;', $start)
$end = $manager.IndexOf('if (faction.IsIdeology)', $begin)
if ($start -lt 0 -or $begin -lt $start -or $end -lt $begin) { throw 'Membership entry boundaries missing' }
$guards = $manager.Substring($begin, $end - $begin)
$recovery = ReadSource 'Behaviors/RestoredRealmRecovery.cs'
$collapse = ReadSource 'Behaviors/CivilWarCollapseContinuation.cs'
$record = ReadSource 'RestoredRealmCreationRecord.cs'
$code = @'
using System.Collections.Generic;
using System.Linq;
namespace BellumRestorationScopeTests {
    public sealed class Kingdom { public string StringId; }
    public sealed class Clan { }
    public sealed class FactionObject {
        public bool IsIdeology; public Kingdom ParentKingdom;
        public List<Clan> Members = new List<Clan>();
    }
    public sealed class RestoredRealmCreationRecord {
        public bool Ready, MovesComplete; public Kingdom Parent, Source, Successor;
        public string SuccessorId; public FactionObject Owner;
        public List<Clan> Houses = new List<Clan>();
        internal bool Protects(Kingdom realm) => __PROTECTS__;
    }
    public sealed class CivilWarCollapseRecord {
        public bool Completed; public int Stage; public FactionObject Winner;
        public Kingdom WinnerRealm, Successor; public List<Clan> WinnerClans = new List<Clan>();
    }
    public sealed class CivilWarResolutionBehavior {
        internal List<RestoredRealmCreationRecord> _restoredCreations = new List<RestoredRealmCreationRecord>();
        internal HashSet<RestoredRealmCreationRecord> _preparingRestoredCreations = new HashSet<RestoredRealmCreationRecord>();
        internal HashSet<CivilWarCollapseRecord> _resumingCollapses = new HashSet<CivilWarCollapseRecord>();
        internal bool IsRestoredCreationPending(Kingdom realm) => __PENDING__;
        internal bool OwnsRestoredHouseholdTransfer(FactionObject faction, Clan clan, Kingdom source, Kingdom destination) => __RESTORED__;
        internal bool OwnsCollapseHouseholdTransfer(FactionObject faction, Clan clan, Kingdom source, Kingdom destination) => __COLLAPSE__;
    }
    public sealed class Campaign {
        public static Campaign Current; internal CivilWarResolutionBehavior Behavior;
        public T GetCampaignBehavior<T>() where T : class => Behavior as T;
    }
    public static class Probe {
        private static bool EntryBypasses(FactionObject item, Clan clan, Kingdom oldKingdom, Kingdom newKingdom) {
            bool reachedOrdinaryHandling = false;
            foreach (FactionObject faction in new[] { item }) {
                __GUARDS__
                reachedOrdinaryHandling = true;
            }
            return !reachedOrdinaryHandling;
        }
        public static bool Run(string scenario) {
            var parent = new Kingdom { StringId = "parent" };
            var source = new Kingdom { StringId = "source" };
            var successor = new Kingdom { StringId = "successor" };
            var foreign = new Kingdom { StringId = "foreign" };
            var clan = new Clan(); var faction = new FactionObject { ParentKingdom = parent };
            faction.Members.Add(clan);
            var b = new CivilWarResolutionBehavior(); Campaign.Current = new Campaign { Behavior = b };
            var r = new RestoredRealmCreationRecord { Parent = parent, Source = source,
                Successor = successor, SuccessorId = successor.StringId, Owner = faction };
            r.Houses.Add(clan); b._restoredCreations.Add(r);
            var oldKingdom = source; var newKingdom = successor;
            if (scenario != "inactive_journal") b._preparingRestoredCreations.Add(r);
            switch (scenario) {
                case "foreign_destination": newKingdom = foreign; break;
                case "wrong_source": oldKingdom = foreign; break;
                case "other_faction": r.Owner = new FactionObject { ParentKingdom = parent }; break;
                case "uncaptured_clan": r.Houses.Clear(); break;
                case "ready_record": r.Ready = true; break;
                case "ideology": faction.IsIdeology = true; break;
                case "no_campaign": Campaign.Current = null; break;
                case "no_pending": b._restoredCreations.Clear(); b._preparingRestoredCreations.Clear(); break;
                case "owned_collapse":
                case "later_collapse_stage":
                    b._restoredCreations.Clear(); b._preparingRestoredCreations.Clear();
                    var c = new CivilWarCollapseRecord { Winner = faction, WinnerRealm = source,
                        Successor = successor, Stage = scenario == "owned_collapse" ? 2 : 3 };
                    c.WinnerClans.Add(clan); b._resumingCollapses.Add(c); break;
            }
            return EntryBypasses(faction, clan, oldKingdom, newKingdom);
        }
    }
}
'@
$code = $code.Replace('__PROTECTS__', (Expression $record 'Protects')).
    Replace('__PENDING__', (Expression $recovery 'IsRestoredCreationPending')).
    Replace('__RESTORED__', (Expression $recovery 'OwnsRestoredHouseholdTransfer')).
    Replace('__COLLAPSE__', (Expression $collapse 'OwnsCollapseHouseholdTransfer')).
    Replace('__GUARDS__', $guards)
Add-Type -TypeDefinition $code -Language CSharp
$failed = 0
$cases = @('owned_restore', 'owned_collapse', 'inactive_journal', 'foreign_destination',
    'wrong_source', 'other_faction', 'uncaptured_clan', 'ready_record', 'ideology',
    'no_campaign', 'no_pending', 'later_collapse_stage')
foreach ($case in $cases) {
    $expected = $case -in @('owned_restore', 'owned_collapse')
    $actual = [BellumRestorationScopeTests.Probe]::Run($case)
    if ($actual -eq $expected) { Write-Host "RESTORATION_SCOPE_PASS $case" }
    else { $failed++; Write-Host "RESTORATION_SCOPE_FAIL $case expected=$expected actual=$actual" }
}
if ($failed) { throw "RESTORATION_SCOPE_RED $failed/$($cases.Count) cases failed" }
Write-Host "RESTORATION_SCOPE_PASS_ALL $($cases.Count) cases; isolated entry fence only"
