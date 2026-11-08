$ErrorActionPreference = 'Stop'
# P1-01A regression-first contract. Source guard extracted into a tiny executable
# C# fixture; this does NOT compile Bellum against Bannerlord or test live saves.
$root = Split-Path -Parent $PSScriptRoot
$path = Join-Path $root 'Behaviors/CivilWarResolutionBehavior.cs'
$source = Get-Content -LiteralPath $path -Raw
function Check([bool]$condition, [string]$label) {
    if (-not $condition) { throw "P101A_RED $label" }
    Write-Host "P101A_PASS $label"
}
$start = $source.IndexOf('public bool IsKingdomIdReferencedByBellumCivileState(', [StringComparison]::Ordinal)
$end = $source.IndexOf('public bool IsClanIdReferencedByBellumCivileState(', $start + 1, [StringComparison]::Ordinal)
Check ($start -ge 0 -and $end -gt $start) 'exact existing public method found'
$method = $source.Substring($start, $end - $start)
$pattern = 'if\s*\(_collapses\.Any\(c\s*=>\s*!c\.Completed\s*&&\s*\(c\.Parent\?\.StringId\s*==\s*kingdomId\s*\|\|\s*c\.WinnerRealm\?\.StringId\s*==\s*kingdomId\s*\|\|\s*c\.SuccessorId\s*==\s*kingdomId\)\)\)\s*return\s+true\s*;'
$guard = [regex]::Match($method, $pattern)
Check $guard.Success 'active collapse Parent / WinnerRealm / SuccessorId protected'
Check ($method.IndexOf('if (string.IsNullOrEmpty(kingdomId)) return false;', [StringComparison]::Ordinal) -ge 0) 'empty-id guard unchanged'
Check ($method.IndexOf('if (IsKingdomIdReferencedByResolutionState(kingdomId)) return true;', [StringComparison]::Ordinal) -gt 0) 'other saved resolution references retained'
Check ($method.Contains('factionManager.GetFactionByRebelKingdom(kingdom) != null') -and
       $method.Contains('factionManager.GetFactionsInKingdom(kingdom).Any(f => !f.IsIdeology)')) 'existing faction fallbacks retained'
$fixture = @'
using System;
using System.Collections.Generic;
using System.Linq;
namespace P101A {
    public sealed class Realm {
        public string StringId;
        public Realm(string id) { StringId = id; }
    }
    public sealed class Collapse {
        public bool Completed;
        public int Stage;
        public Realm Parent;
        public Realm WinnerRealm;
        public string SuccessorId;
    }
    public static class Cases {
        public static bool References(string kingdomId, Collapse[] _collapses) {
            if (string.IsNullOrEmpty(kingdomId)) return false;
            __GUARD__
            return false;
        }
    }
}
'@
Add-Type -Language CSharp -TypeDefinition $fixture.Replace('__GUARD__', $guard.Value) -ErrorAction Stop
function Case([string]$parent, [string]$winner, [string]$successor, [bool]$completed, [int]$stage) {
    $record = [P101A.Collapse]::new()
    if ($parent) { $record.Parent = [P101A.Realm]::new($parent) }
    if ($winner) { $record.WinnerRealm = [P101A.Realm]::new($winner) }
    $record.SuccessorId = $successor
    $record.Completed = $completed
    $record.Stage = $stage
    return $record
}
$pending = [P101A.Collapse[]]@((Case 'parent' 'rebel' 'successor' $false 2))
Check ([P101A.Cases]::References('parent', $pending)) 'active parent protected'
Check ([P101A.Cases]::References('rebel', $pending)) 'active rebel realm protected'
Check ([P101A.Cases]::References('successor', $pending)) 'active successor ID protected before completion'
Check (-not [P101A.Cases]::References('unrelated', $pending)) 'unrelated kingdom remains unreferenced'
Check (-not [P101A.Cases]::References('', $pending)) 'empty kingdom remains unreferenced'
$late = [P101A.Collapse[]]@((Case $null $null 'successor' $false 4))
Check ([P101A.Cases]::References('successor', $late)) 'late uncompleted collapse remains protected'
$completed = [P101A.Collapse[]]@((Case 'parent' 'rebel' 'successor' $true 4))
Check (-not [P101A.Cases]::References('parent', $completed)) 'completed parent no longer protected'
Check (-not [P101A.Cases]::References('successor', $completed)) 'completed successor no longer protected'
Check (-not [P101A.Cases]::References('other', [P101A.Collapse[]]@())) 'empty collapse collection does not protect unrelated kingdom'
Write-Host 'P101A_PASS isolated collapse-state contract finished; full game/CI/save QA remains deferred'
