$ErrorActionPreference = 'Stop'
# P0-03 RED-first source and isolated actual queue-guard regression.
# NOT a Bannerlord DLL, Harmony, old-save or in-game test.
$root = Split-Path -Parent $PSScriptRoot
$src = Get-Content -LiteralPath (Join-Path $root 'Behaviors/WarScoreBehavior.cs') -Raw
$ledger = Get-Content -LiteralPath (Join-Path $root 'Behaviors/WarScoreAiInfluenceForeignLedger.cs') -Raw
$native = Get-Content -LiteralPath (Join-Path $root 'AlliancePeaceRestriction.cs') -Raw
$treaty = Get-Content -LiteralPath (Join-Path $root 'Behaviors/ForeignTreatyBehavior.cs') -Raw
function Check([bool]$ok, [string]$name) {
    if (-not $ok) { throw "P003_RED $name" }
    Write-Host "P003_PASS $name"
}
function Part([string]$from,[string]$to) {
    $a=$src.IndexOf($from,[StringComparison]::Ordinal)
    $b=if($a -lt 0){-1}else{$src.IndexOf($to,$a+$from.Length,[StringComparison]::Ordinal)}
    Check ($a -ge 0 -and $b -gt $a) "method bounds $from"
    return $src.Substring($a,$b-$a)
}
function Before([string]$body,[string]$first,[string]$second,[string]$name) {
    $a=$body.IndexOf($first,[StringComparison]::Ordinal)
    $b=$body.IndexOf($second,[StringComparison]::Ordinal)
    Check ($a -ge 0 -and $b -gt $a) $name
}
$select=Part 'public bool TryGetForeignParleyProposal(' 'public WarScoreRecord RegisterCivilWar('
$queue=Part 'private bool QueueTerminalWarScoreResolution(' 'private bool ResolveQueuedTerminalWarScore('
$resolve=Part 'private bool ResolveQueuedTerminalWarScore(' 'private bool TryCloseOrphanedForeignWarTracker('
$daily=Part 'private void OnDailyTick()' 'private void OnWarDeclared('
$active=Part 'private void ProcessActiveWars()' 'private void ProcessQueuedTerminalResolutions()'
$terminal=Part 'private bool ResolveTerminalConflict(' 'private static float SignedDeltaFor('
$orphan=Part 'private bool TryCloseOrphanedForeignWarTracker(' 'private static float GetLastRecordedWarActivityDay('
$queueGate='if (war.ConflictType == WarScoreConflictType.ForeignWar && AlliancePeaceRestriction.IsPeaceBlocked(ResolveKingdom(war.AttackerKingdomId), ResolveKingdom(war.DefenderKingdomId))) return false;'
$selectGate='.Where(war => !AlliancePeaceRestriction.IsPeaceBlocked('
$ledgerGate='.Where(war => !IsAiInfluenceForeignLedger(war))'
$terminalGate='if (AlliancePeaceRestriction.IsPeaceBlocked(attacker, defender))'

Check ($native.Contains('IsAtWarByCallToWarAgreement(first, second, out caller)') -and $native.Contains('IsAtWarByCallToWarAgreement(second, first, out caller)')) 'official native obligation both directions'
Check ($ledger.Contains('private static bool IsAiInfluenceForeignLedger(') -and
    $ledger.Contains('private static bool ShouldPreventAutonomousForeignResolution(') -and
    $ledger.Contains('!revampEnabled || IsAiInfluenceForeignLedger(war)')) 'AII ledger owns foreign peace even after MCM ON'
Check ($ledger.Contains('public bool TryRegisterAiInfluenceForeignWar(') -and $ledger.Contains('aii_foreign_ledger:v1:')) 'Bridge-facing existing ledger signature and save context retained'
Check ($treaty.Contains('if (AlliancePeaceRestriction.TryGetPeaceBlock(attacker, defender, out TextObject allianceReason))') -and $treaty.Contains('private bool TryCancelAllianceRestrictedProposal(')) 'existing P0-02B/C Native treaty gates preserved'

Before $select '.Where(war => war.ConflictType == WarScoreConflictType.ForeignWar' $ledgerGate 'candidate ledger filter before any NPC treaty'
Before $select '.Where(war => !IsStorylineProtectedForeignWar(war))' $selectGate 'native alliance candidate filter after storyline'
Before $select $selectGate '.Where(war => war.CanReconsiderPeace(CurrentDay))' 'alliance candidates filtered before white-peace economics'
Check ($select.Contains('ResolveKingdom(war.AttackerKingdomId), ResolveKingdom(war.DefenderKingdomId)')) 'candidate blocker resolves exact war pair'
Check ($select.Contains('IsMutualWhitePeaceEligible(war, out _, out _)') -and $select.Contains('OrderByDescending(war => Math.Abs(war.GetSelfRelativeScore(')) 'existing eligible peace preferences preserved'

Before $queue 'if (ShouldPreventAutonomousForeignResolution(war, WarPeaceRevampBehavior.IsRevampEnabled()))' $queueGate 'AII/Revamp OFF check precedes native call-to-arms'
Before $queue 'if (war.ConflictType == WarScoreConflictType.ForeignWar && IsStorylineProtectedForeignWar(war))' $queueGate 'storyline exclusion remains prior to alliance'
Before $queue $queueGate 'war.QueueTerminalResolution(reason)' 'alliance veto happens before terminal latch'
Before $queue $queueGate 'war.ForceScore(war.Score >= 0f' 'alliance veto happens before score force'
Check ($queue.Contains('if (war.TerminalResolutionQueued)') -and $queue.Contains('if (war.ConflictType == WarScoreConflictType.ForeignWar && IsAuxiliaryClientWar(war))')) 'existing idempotency/client fences preserved'

Before $resolve 'if (ShouldPreventAutonomousForeignResolution(war, WarPeaceRevampBehavior.IsRevampEnabled()))' 'if (CivilWarConflictBehavior.IsScoreTransferPending(war))' 'AII legacy queue cleanup precedes internal-war checks'
Before $resolve 'TryCloseOrphanedForeignWarTracker(war, attacker, defender' $terminalGate 'orphaned real-world war closed before alliance veto'
Before $resolve 'if (IsAuxiliaryClientWar(war))' $terminalGate 'client war restriction priority preserved'
Before $resolve $terminalGate 'ForeignTreatyBehavior treaties =' 'stale native terminal queue blocked before treaty'
Before $resolve $terminalGate 'war.BeginResolution()' 'stale native terminal queue cannot fall through to peace'
$a=$resolve.IndexOf($terminalGate,[StringComparison]::Ordinal)
$b=$resolve.IndexOf('ForeignTreatyBehavior treaties =',$a,[StringComparison]::Ordinal)
Check ($a -ge 0 -and $b -gt $a) 'isolated terminal alliance branch'
$branch=$resolve.Substring($a,$b-$a)
Check ($branch.Contains('war.ClearTerminalResolution();') -and $branch.Contains('TouchRuntimeRevision();') -and $branch.Contains('return false;')) 'stale queued flag cleared without ending war'
Check ($resolve.Contains('if (CivilWarConflictBehavior.IsScoreTransferPending(war))') -and $resolve.Contains('TryQueueAiParley(war, forced: true')) 'existing internal and legal native queues retained'
Check ($daily.IndexOf('ReconcileAiInfluenceForeignLedgers();') -lt $daily.IndexOf('ProcessQueuedTerminalResolutions();')) 'AII ledgers reconciled before terminal resolver'
Check ($active.Contains('if (IsAiInfluenceForeignLedger(war))') -and $active.Contains('continue; // never run Bellum automatic full occupation, landless or terminal resolution')) 'AII ledger scores but never auto-resolves'
Check ($terminal.Contains('if (ShouldPreventAutonomousForeignResolution(war, WarPeaceRevampBehavior.IsRevampEnabled())) return false;') -and $terminal.Contains('MakePeaceAction.Apply(primary, opposing)')) 'existing final foreign owner gate retained'
Check ($orphan.Contains('war.MarkEnded(endedDay);') -and $orphan.Contains('!attacker.IsAtWarWith(defender)')) 'orphaned ended-war reconciliation still works'
Check ($src.Contains('public WarScoreRecord RegisterClaimFeudWar(') -and $src.Contains('private bool TryResolveInternalExhaustedVictory(') -and $src.Contains('private bool ResolveInternalWhitePeace(')) 'internal civil/claim-feud methods untouched'

# Compile the actual new queue predicate under a fake native obligation for
# positive/negative foreign-vs-internal, blocked-vs-normal and unrelated pairs.
Check ($queue.Contains($queueGate)) 'production exact standalone queue predicate found'
$fixture=@'
using System;
namespace P003Fixture {
    public enum WarScoreConflictType { ForeignWar, CivilWar, ClaimFeud }
    public sealed class WarScoreRecord {
        public WarScoreConflictType ConflictType;
        public string AttackerKingdomId;
        public string DefenderKingdomId;
    }
    public sealed class Kingdom {
        public readonly string Id;
        public Kingdom(string id) { Id=id; }
    }
    public static class AlliancePeaceRestriction {
        public static bool IsBlocked;
        public static bool IsPeaceBlocked(Kingdom first, Kingdom second) {
            return IsBlocked && first != null && second != null &&
                ((first.Id=="a" && second.Id=="b") || (first.Id=="b" && second.Id=="a"));
        }
    }
    public static class Test {
        private static Kingdom ResolveKingdom(string id) {
            return id=="a" || id=="b" ? new Kingdom(id) : null;
        }
        public static bool Allowed(WarScoreRecord war) {
'@
$fixture += [Environment]::NewLine + $queueGate +
    [Environment]::NewLine + 'return true;' + [Environment]::NewLine + '}' +
    [Environment]::NewLine + '}' + [Environment]::NewLine + '}'
Add-Type -TypeDefinition $fixture -ErrorAction Stop
$pair=[P003Fixture.WarScoreRecord]::new()
$pair.AttackerKingdomId='a'
$pair.DefenderKingdomId='b'
foreach($type in @([P003Fixture.WarScoreConflictType]::ForeignWar,
                   [P003Fixture.WarScoreConflictType]::CivilWar,
                   [P003Fixture.WarScoreConflictType]::ClaimFeud)) {
    $pair.ConflictType=$type
    [P003Fixture.AlliancePeaceRestriction]::IsBlocked=$true
    Check ([P003Fixture.Test]::Allowed($pair) -eq ($type -ne [P003Fixture.WarScoreConflictType]::ForeignWar)) "active native obligation: $type"
    [P003Fixture.AlliancePeaceRestriction]::IsBlocked=$false
    Check ([P003Fixture.Test]::Allowed($pair)) "no native obligation: $type"
}
[P003Fixture.AlliancePeaceRestriction]::IsBlocked=$true
$pair.ConflictType=[P003Fixture.WarScoreConflictType]::ForeignWar
$pair.DefenderKingdomId='unrelated'
Check ([P003Fixture.Test]::Allowed($pair)) 'unrelated opponent never blocked'
Write-Host 'P003_SOURCE_AND_EXTRACTED_GUARD_PASS; full Bannerlord .NET/Harmony/save/game QA deferred.'
