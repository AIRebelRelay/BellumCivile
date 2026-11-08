$ErrorActionPreference = 'Stop'
# P1-01C RED-first: test EXACT Stage-2 short-circuit from source, not a
# hand-transcribed replacement. This is not a Bannerlord/Unity game test.
$root = Split-Path -Parent $PSScriptRoot
$path = Join-Path $root 'Behaviors/CivilWarCollapseContinuation.cs'
$source = Get-Content -LiteralPath $path -Raw
$resolution = Get-Content -LiteralPath (Join-Path $root 'Behaviors/CivilWarResolutionBehavior.cs') -Raw
function Check([bool]$ok, [string]$message) {
    if (-not $ok) { throw "P101C_RED $message" }
    Write-Host "P101C_PASS $message"
}
Check ($resolution.Contains('private static bool TransferClansToKingdom(')) 'P1-01B returned-bool transfer API present'
$start = $source.IndexOf('if (record.Stage == 2)', [StringComparison]::Ordinal)
$end = $source.IndexOf('if (record.Stage == 3)', $start + 1, [StringComparison]::Ordinal)
Check ($start -ge 0 -and $end -gt $start) 'exact Stage 2 in CivilWarCollapseContinuation'
$stage2 = $source.Substring($start, $end - $start)
$pattern = 'if\s*\(!TransferClansToKingdom\(record\.WinnerRealm,\s*record\.Successor,\s*record\.WinnerHouse\)\s*\|\|\s*!TransferClansToKingdom\(record\.Parent,\s*record\.Successor\)\)\s*return;'
$guard = [regex]::Match($stage2, $pattern)
Check $guard.Success 'failed winner movement returns before parent movement, failed parent movement returns before Crown'
Check ($stage2.IndexOf($guard.Value, [StringComparison]::Ordinal) -lt
    $stage2.IndexOf('EnsureValidRulingClan(record.Successor, record.WinnerHouse, forcePreferred: true);', [StringComparison]::Ordinal)) 'Crown/ruler write happens only after both transfers'
Check ($stage2.Contains('record.WinnerRealm.Clans.Any(c => !c.IsEliminated)') -and
    $stage2.Contains('record.Parent.Clans.Any(c => !c.IsEliminated)')) 'existing residual clan guards unchanged'
Check ($stage2.Contains('record.Stage = 3;')) 'Stage 3 advance preserved'

$fixture = @'
using System;
namespace P101C {
    public sealed class Collapse {
        public string WinnerRealm = "winner";
        public string Parent = "parent";
        public string Successor = "successor";
        public string WinnerHouse = "winner_house";
        public int Stage = 2;
        public bool WinnerResult;
        public bool ParentResult;
        public int WinnerCalls, ParentCalls, CrownCalls;
    }
    public static class Cases {
        private static Collapse active;
        private static bool TransferClansToKingdom(string source, string target, string preferredRuler = null) {
            if (target != active.Successor) throw new Exception("wrong destination");
            if (source == active.WinnerRealm) {
                if (preferredRuler != active.WinnerHouse) throw new Exception("wrong winning founder");
                active.WinnerCalls++;
                return active.WinnerResult;
            }
            if (source == active.Parent) {
                if (preferredRuler != null) throw new Exception("unexpected founder sent to old parent");
                active.ParentCalls++;
                return active.ParentResult;
            }
            throw new Exception("unrecognized source");
        }
        public static void Step(Collapse record) {
            active = record;
            if (record.Stage != 2) return;
            __GUARD__
            record.CrownCalls++;
            record.Stage = 3;
        }
    }
}
'@
Add-Type -Language CSharp -TypeDefinition $fixture.Replace('__GUARD__', $guard.Value) -ErrorAction Stop
$a = [P101C.Collapse]::new()
$a.WinnerResult = $false; $a.ParentResult = $true
[P101C.Cases]::Step($a)
Check ($a.Stage -eq 2 -and $a.WinnerCalls -eq 1 -and $a.ParentCalls -eq 0 -and $a.CrownCalls -eq 0) 'winner failure cannot start parent transfer or advance Stage'
$a.WinnerResult = $true; $a.ParentResult = $false
[P101C.Cases]::Step($a)
Check ($a.Stage -eq 2 -and $a.WinnerCalls -eq 2 -and $a.ParentCalls -eq 1 -and $a.CrownCalls -eq 0) 'parent failure defers Crown and Stage'
$a.ParentResult = $true
[P101C.Cases]::Step($a)
Check ($a.Stage -eq 3 -and $a.WinnerCalls -eq 3 -and $a.ParentCalls -eq 2 -and $a.CrownCalls -eq 1) 'successful retry advances once'
[P101C.Cases]::Step($a)
Check ($a.Stage -eq 3 -and $a.WinnerCalls -eq 3 -and $a.ParentCalls -eq 2 -and $a.CrownCalls -eq 1) 'completed Stage 2 not replayed'
$b = [P101C.Collapse]::new()
$b.WinnerResult = $true; $b.ParentResult = $true
[P101C.Cases]::Step($b)
Check ($b.Stage -eq 3 -and $b.ParentCalls -eq 1 -and $b.CrownCalls -eq 1) 'normal successful first pass retained'
Write-Host 'P101C_PASS isolated Stage-2 call/short-circuit contract; full save, native build and game QA NOT RUN'
