# P0-06 RED-first regression: only challenge outcome recovery must stop
# when the source transfer/retirement reports incomplete. No game DLL needed.
# Upstream pin: Vonbalt/BellumCivile@da426b23c64f3a66ae2b389d2db8f23489736bf9
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$source = Get-Content -Raw -LiteralPath (Join-Path $root 'Behaviors/CivilWarSuccessionSettlement.cs')
$resolver = Get-Content -Raw -LiteralPath (Join-Path $root 'Behaviors/CivilWarResolutionBehavior.cs')
$collapse = Get-Content -Raw -LiteralPath (Join-Path $root 'Behaviors/CivilWarCollapseContinuation.cs')
$recovery = Get-Content -Raw -LiteralPath (Join-Path $root 'Behaviors/RestoredRealmRecovery.cs')
function Check([bool]$ok, [string]$name) {
    if (!$ok) { throw "P006_RED $name" }
    Write-Host "P006_PASS $name"
}
$start = $source.IndexOf('if (record.RestoredRealmRequested && record.Realm != realm)', [StringComparison]::Ordinal)
$end = $source.IndexOf('if (record.WarOutcome == SuccessionChallengeOutcome.Victory && !record.HasWarCrownReceipt)', $start + 1, [StringComparison]::Ordinal)
Check ($start -ge 0 -and $end -gt $start) 'unique restored realm transfer gate located before Crown completion'
$block = $source.Substring($start, $end - $start)
Check ($block.Contains('if (record.Realm.IsEliminated)') -and
    $block.Contains('if (!TransferLiveClansFromEliminatedKingdom(record.Realm, realm, victor)) return;') -and
    $block.Contains('else if (!DrainAndDestroyRebelKingdom(record.Realm, realm)) return;')) 'both failed outcomes return before Crown, tribunal, rewards or settled receipt'
Check ($source.Contains('if (record != null && TryResumeRivalChallengeOutcome(record)) return;') -and
    $source.Contains('if (record != null && TryResumeChallengeCollapse(record)) return;') -and
    $source.Contains('record == null || record.ResolutionReturned || !_settlingChallenges.Add(record)') -and
    $source.Contains('finally { _settlingChallenges.Remove(record); }')) 'existing rival/collapse journal ownership, completion and reentrancy gates preserved'
Check ($resolver.Contains('private static bool TransferLiveClansFromEliminatedKingdom(') -and
    $resolver.Contains('private bool DrainAndDestroyRebelKingdom(') -and
    $resolver.Contains('QueuePendingRebelCleanup(rebelKingdom, fallbackKingdom)')) 'shared helpers retain their existing boolean and deferred-cleanup semantics'
Check ($collapse.Contains('if (!DrainAndDestroyRebelKingdom(record.WinnerRealm, record.Successor)) return;') -and
    $recovery.Contains('if (!TransferLiveClansFromEliminatedKingdom(parent, realm, record.Founder))')) 'neighbor restoration owners continue checking failures'

# Compile the exact C# branch extracted from production, using isolated stubs.
# This tests the branch logic, not full CampaignSystem or actual save/game integration.
$fixture = @'
using System;
namespace P006 {
    public sealed class Realm { public bool IsEliminated; }
    public sealed class Challenge {
        public bool RestoredRealmRequested = true;
        public Realm Realm = new Realm();
        public bool TransferOk, DrainOk;
        public int Transfers, Drains, LaterSteps;
    }
    public static class Harness {
        private static Challenge current;
        private static bool TransferLiveClansFromEliminatedKingdom(Realm source, Realm target, string victor) {
            current.Transfers++;
            return current.TransferOk;
        }
        private static bool DrainAndDestroyRebelKingdom(Realm source, Realm target) {
            current.Drains++;
            return current.DrainOk;
        }
        public static void Resume(Challenge record, Realm realm) {
            current = record;
            string victor = "founder";
            __BLOCK__
            record.LaterSteps++;
        }
    }
}
'@
Add-Type -Language CSharp -TypeDefinition $fixture.Replace('__BLOCK__', $block) -ErrorAction Stop

$a = [P006.Challenge]::new()
$a.Realm.IsEliminated = $true
$a.TransferOk = $false
[P006.Harness]::Resume($a, [P006.Realm]::new())
Check ($a.Transfers -eq 1 -and $a.Drains -eq 0 -and $a.LaterSteps -eq 0) 'eliminated parent transfer failure defers later settlement'
$a.TransferOk = $true
[P006.Harness]::Resume($a, [P006.Realm]::new())
Check ($a.Transfers -eq 2 -and $a.LaterSteps -eq 1) 'eliminated parent successful retry resumes settlement'

$b = [P006.Challenge]::new()
$b.Realm.IsEliminated = $false
$b.DrainOk = $false
[P006.Harness]::Resume($b, [P006.Realm]::new())
Check ($b.Drains -eq 1 -and $b.Transfers -eq 0 -and $b.LaterSteps -eq 0) 'live old parent drain failure defers later settlement'
$b.DrainOk = $true
[P006.Harness]::Resume($b, [P006.Realm]::new())
Check ($b.Drains -eq 2 -and $b.LaterSteps -eq 1) 'live old parent successful retry resumes settlement'

$c = [P006.Challenge]::new()
$c.RestoredRealmRequested = $false
[P006.Harness]::Resume($c, [P006.Realm]::new())
Check ($c.LaterSteps -eq 1 -and $c.Transfers -eq 0 -and $c.Drains -eq 0) 'ordinary non-restoration outcome unchanged'
$d = [P006.Challenge]::new()
[P006.Harness]::Resume($d, $d.Realm)
Check ($d.LaterSteps -eq 1 -and $d.Transfers -eq 0 -and $d.Drains -eq 0) 'already-current realm outcome unchanged'
Write-Host 'P006_PASS isolated source-extracted branch contract; full Windows build / game / old-save QA NOT RUN'
