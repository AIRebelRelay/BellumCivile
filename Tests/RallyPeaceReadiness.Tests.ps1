# Exact production math with minimal type declarations; no campaign/UI simulation.
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$temp = Join-Path ([IO.Path]::GetTempPath()) ('bellum-rally-' + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $temp | Out-Null
try {
    $fixture = @'
using System;
namespace TaleWorlds.CampaignSystem { public sealed class Kingdom { } public sealed class Clan { } }
namespace TaleWorlds.SaveSystem { public sealed class SaveableFieldAttribute : Attribute { public SaveableFieldAttribute(int id) { } } }
namespace BellumCivile {
    public sealed class WarScoreRecord { }
    public static class RallyReadinessProbe {
        public static float Effective(float baseline, bool eligible) => CourtRallyRules.Effective(baseline, eligible);
        public static float Readiness(float days, float score, float will) => PeaceReadiness.Evaluate(days, score, will, 30).Total;
    }
}
'@
    $fixturePath = Join-Path $temp 'Fixture.cs'
    Set-Content -LiteralPath $fixturePath -Value $fixture
    Add-Type -Path @($fixturePath, (Join-Path $root 'BellumCivileConstants.cs'),
        (Join-Path $root 'PeaceReadiness.cs'), (Join-Path $root 'CourtRallyRecord.cs'))
    function Check([bool]$value, [string]$name) {
        if (!$value) { throw "FAIL: $name" }
        "PASS: $name"
    }
    $cases = @(
        @{ Name = 'early exhausted front'; Days = 0; Score = 0; Will = 0 },
        @{ Name = 'early resolved front'; Days = 1; Score = 70; Will = 20 },
        @{ Name = 'threshold crossing'; Days = 30; Score = 0; Will = 5 },
        @{ Name = 'ordinary campaign'; Days = 60; Score = 25; Will = 40 },
        @{ Name = 'prolonged exhausted front'; Days = 120; Score = 0; Will = 0 },
        @{ Name = 'near cap'; Days = 120; Score = 100; Will = 95 },
        @{ Name = 'already capped'; Days = 120; Score = 100; Will = 100 }
    )
    foreach ($case in $cases) {
        $base = [BellumCivile.RallyReadinessProbe]::Readiness($case.Days, $case.Score, $case.Will)
        $off = [BellumCivile.RallyReadinessProbe]::Effective($case.Will, $false)
        $effective = [BellumCivile.RallyReadinessProbe]::Effective($case.Will, $true)
        $rallied = [BellumCivile.RallyReadinessProbe]::Readiness($case.Days, $case.Score, $effective)
        Check ($off -eq $case.Will -and $effective -ge $case.Will -and $effective -le 100 -and
            $rallied -le $base -and [Math]::Abs(($base + ($rallied - $base)) - $rallied) -lt .0001) $case.Name
    }
    $base = [BellumCivile.RallyReadinessProbe]::Readiness(30, 0, 5)
    $rallied = [BellumCivile.RallyReadinessProbe]::Readiness(30, 0, 20)
    Check ([Math]::Abs(($rallied - $base) - (-15 * .5)) -gt .001) 'Threshold crossing differs from obsolete linear utility'
    '8 named math scenarios PASS. Scope/eligibility wiring is checked by CourtRally.Tests.ps1; native/game validation remains pending.'
} finally {
    Remove-Item -LiteralPath $temp -Recurse -Force
}
