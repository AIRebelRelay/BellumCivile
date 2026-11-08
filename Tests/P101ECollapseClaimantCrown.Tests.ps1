$ErrorActionPreference = 'Stop'
# P1-01E RED-first: source contract + executable isolated ownership predicate.
# It does not replace Bannerlord campaign/save tests for claimant and Crown.
$root = Split-Path -Parent $PSScriptRoot
$collapse = Get-Content -Raw -LiteralPath (Join-Path $root 'Behaviors/CivilWarCollapseContinuation.cs')
$factions = Get-Content -Raw -LiteralPath (Join-Path $root 'Behaviors/FactionManagerBehavior.cs')
$claim = Get-Content -Raw -LiteralPath (Join-Path $root 'SuccessionChallengeRecord.cs')
function Check([bool]$ok, [string]$description) {
    if (-not $ok) { throw "P101E_RED $description" }
    Write-Host "P101E_PASS $description"
}
$ownerPattern = 'internal bool OwnsCollapseHouseholdTransfer\(FactionObject faction, Clan clan, Kingdom source, Kingdom destination\) =>\s*(?<expr>_resumingCollapses\.Any\(c => !c\.Completed && c\.Stage == 2 && c\.Winner == faction\s*&& c\.WinnerRealm == source && c\.Successor == destination && c\.WinnerClans\.Contains\(clan\)\));'
$owner = [regex]::Match($collapse, $ownerPattern)
Check $owner.Success 'running Stage 2 protects only saved winner, source, successor and captured member'
$entry = $factions.IndexOf('private void OnClanChangedKingdom(', [StringComparison]::Ordinal)
$exit = $factions.IndexOf('private void RepairReferencedKingdomRulerState(', $entry + 1, [StringComparison]::Ordinal)
Check ($entry -ge 0 -and $exit -gt $entry) 'exact shared kingdom-change handler found'
$handler = $factions.Substring($entry, $exit - $entry)
$gate = 'OwnsCollapseHouseholdTransfer(faction, clan, oldKingdom, newKingdom) == true'
Check ($handler.Contains($gate) -and $handler.Contains('!faction.IsIdeology')
    -and $handler.IndexOf($gate, [StringComparison]::Ordinal) -lt
         $handler.IndexOf('faction.RemoveMember(clan);', [StringComparison]::Ordinal)) 'faction membership is preserved before removal on owned Stage 2 transfers'
Check ($handler.Contains('TrackPlayerCourtTransfer(clan, oldKingdom, newKingdom);') -and
    $handler.Contains('QueueSettlementRefresh(clan);') -and
    $handler.Contains('RepairReferencedKingdomRulerState(oldKingdom);')) 'player court, settlement, and ruler side effects stay enabled'
Check (-not $handler.Contains('IsRestoredCreationPending(faction.ParentKingdom)')) 'do not add unrelated broad restored-creation exception in this stage'
$begin = $collapse.IndexOf('private bool CanContinueCollapseClaim(', [StringComparison]::Ordinal)
$end = $collapse.IndexOf('private bool TryResumeChallengeCollapse(', $begin + 1, [StringComparison]::Ordinal)
Check ($begin -ge 0 -and $end -gt $begin) 'claim legality and Crown receipt helpers present'
$legal = $collapse.Substring($begin, $end - $begin)
foreach ($required in @(
    'SuccessionChallengeBehavior.Instance?.GetWarRecord(record.Winner) != claim',
    'claim.OutcomeVictor != record.WinnerHouse',
    'claim.WarOutcome != SuccessionChallengeOutcome.Victory',
    'if (claim.HasWarCrownReceipt) return true;',
    'if (record.Stage >= 3 && CollapseCrownDelivered(record))',
    'claim.WarCrownTransferred = true;',
    'claim.Challenger?.IsAlive == true',
    'record.WinnerHouse.Leader == claim.Challenger',
    'crown?.IsActive == true',
    'crown.AssociatedKingdomId == realm.StringId',
    'crown.DeJureHolderClanId == record.WinnerHouse.StringId',
    'crown.DeFactoHolderClanId == record.WinnerHouse.StringId',
    'titles.TrySetKingdomTitleRuler(record.Successor, record.WinnerHouse, true,',
    '"restored hereditary challenge victory"',
    'record.Challenge.WarCrownTransferred = true;',
    'return challenges.LegalizeChallengeVictory(record.Winner, record.Successor);'
)) { Check ($legal.Contains($required)) ("required claim/Crown invariant: " + $required) }
$stage3 = $collapse.IndexOf('if (record.Stage == 3)', [StringComparison]::Ordinal)
$stage4 = $collapse.IndexOf('if (record.Stage == 4)', $stage3 + 1, [StringComparison]::Ordinal)
Check ($stage3 -ge 0 -and $stage4 -gt $stage3) 'stage 3 and 4 boundaries preserved'
$segment = $collapse.Substring($stage3, $stage4 - $stage3)
Check ($segment.Contains('if (!PrepareCollapseChallengeVictory(record)) return;') -and
    $segment.Contains('TryQueueChallengeTribunal(record.Winner, record.Successor);') -and
    $segment.Contains('if (!record.Challenge.TribunalQueued) return;')) 'no settlement or tribunal before legal Crown transfer'
Check ($collapse.Contains('if (!CanContinueCollapseClaim(record))') -and
    $collapse.Contains('if (record.Stage < 3 &&')) 'claimant check at entry, with original general founder guard'
Check ($claim.Contains('internal bool HasWarCrownReceipt => WarCrownTransferred || RestoredRealmReady')) 'historic receipt semantics unchanged'

# Compile exactly the ownership expression from production against minimal types.
$fixture = @'
using System.Collections.Generic;
using System.Linq;
namespace P101E {
    public sealed class FactionObject {}
    public sealed class Clan {}
    public sealed class Kingdom {}
    public sealed class Collapse {
        public bool Completed;
        public int Stage;
        public FactionObject Winner;
        public Kingdom WinnerRealm;
        public Kingdom Successor;
        public List<Clan> WinnerClans = new List<Clan>();
    }
    public sealed class Owner {
        internal readonly HashSet<Collapse> _resumingCollapses = new HashSet<Collapse>();
        public void Begin(Collapse record) { _resumingCollapses.Add(record); }
        public void End(Collapse record) { _resumingCollapses.Remove(record); }
        public bool OwnsCollapseHouseholdTransfer(FactionObject faction, Clan clan, Kingdom source, Kingdom destination) => __EXPRESSION__;
    }
}
'@
Add-Type -Language CSharp -TypeDefinition $fixture.Replace('__EXPRESSION__', $owner.Groups['expr'].Value) -ErrorAction Stop
$handlerOwner = [P101E.Owner]::new()
$f = [P101E.FactionObject]::new(); $cl = [P101E.Clan]::new(); $outsider = [P101E.Clan]::new()
$source = [P101E.Kingdom]::new(); $target = [P101E.Kingdom]::new(); $another = [P101E.Kingdom]::new()
$record = [P101E.Collapse]::new()
$record.Stage = 2; $record.Winner = $f; $record.WinnerRealm = $source; $record.Successor = $target; $record.WinnerClans.Add($cl)
Check (-not $handlerOwner.OwnsCollapseHouseholdTransfer($f, $cl, $source, $target)) 'ordinary transfer without active resume is unprotected'
$handlerOwner.Begin($record)
Check ($handlerOwner.OwnsCollapseHouseholdTransfer($f, $cl, $source, $target)) 'captured winning member is protected during actual Stage 2'
Check (-not $handlerOwner.OwnsCollapseHouseholdTransfer($f, $outsider, $source, $target)) 'nonmember is not protected'
Check (-not $handlerOwner.OwnsCollapseHouseholdTransfer($f, $cl, $another, $target)) 'unrelated source is not protected'
Check (-not $handlerOwner.OwnsCollapseHouseholdTransfer($f, $cl, $source, $another)) 'external defection is not protected'
Check (-not $handlerOwner.OwnsCollapseHouseholdTransfer([P101E.FactionObject]::new(), $cl, $source, $target)) 'unrelated faction is not protected'
$record.Stage = 3
Check (-not $handlerOwner.OwnsCollapseHouseholdTransfer($f, $cl, $source, $target)) 'finished Stage 2 cannot hold coalition membership'
$record.Stage = 2; $record.Completed = $true
Check (-not $handlerOwner.OwnsCollapseHouseholdTransfer($f, $cl, $source, $target)) 'completed collapse cannot hold coalition membership'
$record.Completed = $false; $handlerOwner.End($record)
Check (-not $handlerOwner.OwnsCollapseHouseholdTransfer($f, $cl, $source, $target)) 'inactive continuation does not shadow a later defection'
Write-Host 'P101E_PASS isolated ownership test; real Crown legal transfer, save/reload and game QA NOT RUN'
