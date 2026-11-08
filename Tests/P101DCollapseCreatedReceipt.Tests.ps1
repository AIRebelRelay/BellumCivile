$ErrorActionPreference = 'Stop'
# P1-01D RED-first; source-extracted Stage 4 receipt + isolated C# fixture.
# This cannot prove Bannerlord save compatibility or Bellum Bridge snapshot timing.
$root = Split-Path -Parent $PSScriptRoot
$source = Get-Content -Raw -LiteralPath (Join-Path $root 'Behaviors/CivilWarCollapseContinuation.cs')
$record = Get-Content -Raw -LiteralPath (Join-Path $root 'CivilWarCollapseRecord.cs')
$save = Get-Content -Raw -LiteralPath (Join-Path $root 'BellumCivileSaveDefiner.cs')
function Check([bool]$ok, [string]$label) {
    if (-not $ok) { throw "P101D_RED $label" }
    Write-Host "P101D_PASS $label"
}
$start = $source.IndexOf('if (record.Stage == 4)', [StringComparison]::Ordinal)
$end = $source.IndexOf('if (!record.RewardsApplied)', $start + 1, [StringComparison]::Ordinal)
Check ($start -ge 0 -and $end -gt $start) 'exact Stage 4 entry and reward boundary'
$entry = $source.Substring($start, $end - $start)
$pattern = 'if\s*\(!record\.CreatedNotified\)\s*\{\s*record\.CreatedNotified\s*=\s*true;\s*CampaignEventDispatcher\.Instance\.OnKingdomCreated\(record\.Successor\);\s*\}'
$m = [regex]::Match($entry, $pattern)
Check $m.Success 'single event callback has a durable receipt BEFORE dispatch'
Check (([regex]::Matches($source, 'CampaignEventDispatcher\.Instance\.OnKingdomCreated\(')).Count -eq 1) 'exactly one Stage 4 publication call site'
$precondition = 'if (!NobleClanEligibilityHelper.IsValidRulingClan(record.Successor?.RulingClan, record.Successor)'
$postcondition = 'if (record.Successor.IsEliminated'
Check ($entry.Contains($precondition) -and $entry.IndexOf($precondition, [StringComparison]::Ordinal) -lt
    $entry.IndexOf($m.Value, [StringComparison]::Ordinal)) 'valid ruling clan and non-eliminated successor checked before notification'
Check ($entry.Contains($postcondition) -and $entry.IndexOf($postcondition, [StringComparison]::Ordinal) -gt
    $entry.IndexOf($m.Value, [StringComparison]::Ordinal)) 'successor revalidated after notification callback'
Check ($record.Contains('[SaveableField(21)] public bool CreatedNotified;')) 'new append-only save field 21 registered on existing record'
$ids = @([regex]::Matches($record, '\[SaveableField\((\d+)\)\]') | ForEach-Object { [int]$_.Groups[1].Value } | Sort-Object)
Check ($ids.Count -eq 21 -and (($ids -join ',') -eq ((1..21) -join ','))) 'original fields 1..20 unchanged, no duplicate IDs'
Check ($save.Contains('AddClassDefinition(typeof(CivilWarCollapseRecord), 86);') -and
    $save.Contains('ConstructContainerDefinition(typeof(List<CivilWarCollapseRecord>));')) 'existing class ID 86 and list container reused'

# Compile precisely the production receipt snippet (not a duplicate handwritten condition).
$fixture = @'
using System;
namespace P101D {
    public sealed class Kingdom {
        public bool ValidRulingClan = true;
        public bool IsEliminated;
    }
    public sealed class CivilWarCollapseRecord {
        public Kingdom Successor = new Kingdom();
        public bool Completed;
        public int Stage = 4;
        public bool CreatedNotified;
    }
    public sealed class CampaignEventDispatcher {
        public static readonly CampaignEventDispatcher Instance = new CampaignEventDispatcher();
        public int Calls;
        public bool Throw;
        public void OnKingdomCreated(Kingdom target) {
            Calls++;
            if (Throw) throw new InvalidOperationException("injected listener interruption");
        }
    }
    public static class Cases {
        public static void Step(CivilWarCollapseRecord record) {
            if (record.Completed || record.Stage != 4) return;
            if (record.Successor == null || record.Successor.IsEliminated || !record.Successor.ValidRulingClan) return;
            __RECEIPT__
        }
    }
}
'@
Add-Type -Language CSharp -TypeDefinition $fixture.Replace('__RECEIPT__', $m.Value) -ErrorAction Stop
$bus = [P101D.CampaignEventDispatcher]::Instance
$pending = [P101D.CivilWarCollapseRecord]::new()
Check (-not $pending.CreatedNotified) 'old-save-style missing field defaults false'
[P101D.Cases]::Step($pending)
Check ($pending.CreatedNotified -and $bus.Calls -eq 1) 'eligible Stage 4 publishes once'
[P101D.Cases]::Step($pending)
Check ($bus.Calls -eq 1) 'reentered Stage 4 does not republish'
$bus.Throw = $true
$interrupted = [P101D.CivilWarCollapseRecord]::new()
$threw = $false
try { [P101D.Cases]::Step($interrupted) } catch { $threw = $true }
Check ($threw -and $interrupted.CreatedNotified -and $bus.Calls -eq 2) 'listener exception occurs AFTER in-memory receipt'
$bus.Throw = $false
[P101D.Cases]::Step($interrupted)
Check ($bus.Calls -eq 2) 'retry after interrupted listener does not duplicate delivery'
$invalid = [P101D.CivilWarCollapseRecord]::new()
$invalid.Successor.ValidRulingClan = $false
[P101D.Cases]::Step($invalid)
Check (-not $invalid.CreatedNotified -and $bus.Calls -eq 2) 'uncrowned successor cannot publish'
$eliminated = [P101D.CivilWarCollapseRecord]::new()
$eliminated.Successor.IsEliminated = $true
[P101D.Cases]::Step($eliminated)
Check (-not $eliminated.CreatedNotified -and $bus.Calls -eq 2) 'eliminated successor cannot publish'
$premature = [P101D.CivilWarCollapseRecord]::new()
$premature.Stage = 3
[P101D.Cases]::Step($premature)
Check (-not $premature.CreatedNotified -and $bus.Calls -eq 2) 'Stage 3 cannot publish'
$done = [P101D.CivilWarCollapseRecord]::new()
$done.Completed = $true
[P101D.Cases]::Step($done)
Check (-not $done.CreatedNotified -and $bus.Calls -eq 2) 'completed collapse does not reenter Stage 4'
Write-Host 'P101D_PASS isolated receipt contract; actual PowerShell execution, save reload and live Bridge QA must be recorded separately'
