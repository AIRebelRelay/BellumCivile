$ErrorActionPreference = 'Stop'
# P1-01F RED-first: contracts for *only* the journal-owned live clan-transfer callback.
# A static test plus an extracted C# predicate is not a live Bannerlord regression test.
$root = Split-Path -Parent $PSScriptRoot
$recovery = Get-Content -LiteralPath (Join-Path $root 'Behaviors/RestoredRealmRecovery.cs') -Raw
$factionCode = Get-Content -LiteralPath (Join-Path $root 'Behaviors/FactionManagerBehavior.cs') -Raw
function Check([bool]$passed, [string]$message) {
    if (-not $passed) { throw "P101F_RED $message" }
    Write-Host "P101F_PASS $message"
}
$pattern = 'internal bool OwnsRestoredHouseholdTransfer\(FactionObject faction, Clan clan, Kingdom source, Kingdom destination\)\s*=>\s*(?<expr>_preparingRestoredCreations\.Any\(r => !r\.Ready && r\.Owner == faction\s*&& r\.Source == source && r\.Successor == destination\s*&& r\.Houses\.Contains\(clan\)\));'
$match = [regex]::Match($recovery, $pattern)
Check $match.Success 'ownership matches active journal, exact source/destination/faction and captured house'
Check ($recovery.Contains('if (!_preparingRestoredCreations.Add(record)) return null;') -and
    $recovery.Contains('finally { _preparingRestoredCreations.Remove(record); }')) 'existing preparation lifetime encompasses synchronous household moves'
Check ($recovery.Contains('Houses = source.Clans.Where(') -and
    $recovery.Contains('Owner = owner ?? challenge?.WarFaction')) 'ownership and participating houses captured before transfer'
$from = $factionCode.IndexOf('private void OnClanChangedKingdom(', [StringComparison]::Ordinal)
$to = $factionCode.IndexOf('private void RepairReferencedKingdomRulerState(', $from + 1, [StringComparison]::Ordinal)
Check ($from -ge 0 -and $to -gt $from) 'single faction kingdom-change listener located'
$handler = $factionCode.Substring($from, $to - $from)
$owned = 'OwnsRestoredHouseholdTransfer(faction, clan, oldKingdom, newKingdom) == true'
Check ($handler.Contains($owned) -and $handler.Contains('!faction.IsIdeology') -and
    $handler.IndexOf($owned, [StringComparison]::Ordinal) <
    $handler.IndexOf('faction.RemoveMember(clan);', [StringComparison]::Ordinal)) 'only actively owned restoration bypasses faction removal'
Check ($handler.Contains('OwnsCollapseHouseholdTransfer(faction, clan, oldKingdom, newKingdom) == true')) 'prior P1-01E collapse ownership guard kept'
Check (-not $handler.Contains('IsRestoredCreationPending(faction.ParentKingdom)')) 'broad upstream parent-level suppression intentionally absent'
foreach ($line in @('TrackPlayerCourtTransfer(clan, oldKingdom, newKingdom);',
    'bool preserveQueuedLoyalistResolution =', 'ShouldKeepIdeologyMembership(faction, oldKingdom, newKingdom)',
    'QueueSettlementRefresh(clan);', 'RepairReferencedKingdomRulerState(oldKingdom);',
    'RepairReferencedKingdomRulerState(newKingdom);')) {
    Check ($handler.Contains($line)) ("neighboring membership callback preserved: " + $line)
}

# Compile the exact production predicate, not a hand-copied rewrite.
$fixture = @'
using System.Collections.Generic;
using System.Linq;
namespace P101F {
    public sealed class Kingdom {}
    public sealed class Clan {}
    public sealed class FactionObject {}
    public sealed class RestoredRealmCreationRecord {
        public bool Ready;
        public Kingdom Source;
        public Kingdom Successor;
        public FactionObject Owner;
        public List<Clan> Houses = new List<Clan>();
    }
    public sealed class Coordinator {
        private readonly HashSet<RestoredRealmCreationRecord> _preparingRestoredCreations = new HashSet<RestoredRealmCreationRecord>();
        public void Begin(RestoredRealmCreationRecord record) { _preparingRestoredCreations.Add(record); }
        public void End(RestoredRealmCreationRecord record) { _preparingRestoredCreations.Remove(record); }
        public bool OwnsRestoredHouseholdTransfer(FactionObject faction, Clan clan, Kingdom source, Kingdom destination) => __GUARD__;
    }
}
'@
Add-Type -Language CSharp -TypeDefinition $fixture.Replace('__GUARD__', $match.Groups['expr'].Value) -ErrorAction Stop

$coord = [P101F.Coordinator]::new()
$owner = [P101F.FactionObject]::new()
$other = [P101F.FactionObject]::new()
$source = [P101F.Kingdom]::new()
$parent = [P101F.Kingdom]::new()
$successor = [P101F.Kingdom]::new()
$foreign = [P101F.Kingdom]::new()
$founder = [P101F.Clan]::new()
$backer = [P101F.Clan]::new()
$outsider = [P101F.Clan]::new()
$record = [P101F.RestoredRealmCreationRecord]::new()
$record.Owner = $owner; $record.Source = $source; $record.Successor = $successor
$record.Houses.Add($founder); $record.Houses.Add($backer)

Check (-not $coord.OwnsRestoredHouseholdTransfer($owner, $founder, $source, $successor)) 'pending but inactive journal does not freeze any clan'
$coord.Begin($record)
Check ($coord.OwnsRestoredHouseholdTransfer($owner, $founder, $source, $successor)) 'founder is preserved during exact owned migration'
Check ($coord.OwnsRestoredHouseholdTransfer($owner, $backer, $source, $successor)) 'captured original backer is preserved'
Check (-not $coord.OwnsRestoredHouseholdTransfer($owner, $outsider, $source, $successor)) 'other clan is free to leave even while restoration is active'
Check (-not $coord.OwnsRestoredHouseholdTransfer($other, $founder, $source, $successor)) 'another faction receives no exemption'
Check (-not $coord.OwnsRestoredHouseholdTransfer($owner, $founder, $parent, $successor)) 'parent kingdom ordinary transfer receives no exemption'
Check (-not $coord.OwnsRestoredHouseholdTransfer($owner, $founder, $source, $foreign)) 'foreign defection receives no exemption'
Check (-not $coord.OwnsRestoredHouseholdTransfer($owner, $founder, $successor, $foreign)) 'defection after arrival in successor remains ordinary'
$record.Ready = $true
Check (-not $coord.OwnsRestoredHouseholdTransfer($owner, $founder, $source, $successor)) 'ready journal cannot shadow a later clan move'
$record.Ready = $false
$coord.End($record)
Check (-not $coord.OwnsRestoredHouseholdTransfer($owner, $founder, $source, $successor)) 'exception/finally/end removes ownership protection'
$emergency = [P101F.RestoredRealmCreationRecord]::new()
$emergency.Source = $parent; $emergency.Successor = $successor
$emergency.Houses.Add($founder)
$coord.Begin($emergency)
Check (-not $coord.OwnsRestoredHouseholdTransfer($owner, $founder, $parent, $successor)) 'emergency restoration without faction owner does not freeze factions'
$coord.End($emergency)
Write-Host 'P101F_PASS isolated active-transfer predicate; real Campaign.OnClanChangedKingdom, old-save and Bridge tests NOT RUN'
