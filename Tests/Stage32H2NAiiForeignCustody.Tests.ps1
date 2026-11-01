# Stage32H2N RED-first Native source contract.
# The same prisoner that AII foreign scoring credited under Revamp OFF
# must be debited on release/death and reconciled on save-load/daily tick,
# with all OTHER wars still skipped. This does not execute the game.
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$src = Get-Content -LiteralPath (Join-Path $root 'Behaviors/WarScoreCustody.cs') -Raw
$war = Get-Content -LiteralPath (Join-Path $root 'Behaviors/WarScoreBehavior.cs') -Raw
$f1 = Get-Content -LiteralPath (Join-Path $root 'Behaviors/WarScoreAiInfluenceForeignLedger.cs') -Raw
function Check([bool]$pass, [string]$label) {
    if (-not $pass) { throw "STAGE32H2N_RED $label" }
    Write-Host "STAGE32H2N_SOURCE_CHECK $label"
}
function Contains([string]$str, [string]$needle) {
    $str.IndexOf($needle, [StringComparison]::Ordinal) -ge 0
}
$releaseStart = $src.IndexOf('private void RemoveCustodyScore(', [StringComparison]::Ordinal)
$reconcileStart = $src.IndexOf('private void ReconcileReversibleScores(', [StringComparison]::Ordinal)
Check ($releaseStart -ge 0 -and $reconcileStart -gt $releaseStart) 'source custody methods found'
$release = $src.Substring($releaseStart, $reconcileStart - $releaseStart)
$reconcile = $src.Substring($reconcileStart)
Check (Contains $release 'bool revampEnabled = WarPeaceRevampBehavior.IsRevampEnabled();') 'release revamp snapshot'
Check (Contains $release 'if (prisoner == null || (!revampEnabled && !HasOpenAiInfluenceForeignLedgers())) return;') 'release runs with OFF only when AII ledger exists'
Check (Contains $release 'if (!revampEnabled && !IsAiInfluenceForeignLedger(war)) continue;') 'release must not mutate civil claim or unrelated wars when OFF'
Check ((Contains $release 'war.RemovePrisoner(prisoner.StringId, C.WarScorePrisonerCap);') -and
       (Contains $release 'WarScoreEventType.PrisonerCustodyChanged') -and
       (Contains $release 'QueueTerminalWarScoreResolution(war, "prisoner custody changed")')) 'existing release debt and no-autonomous-terminal fence retained'
Check (Contains $reconcile 'bool revampEnabled = WarPeaceRevampBehavior.IsRevampEnabled();') 'daily reversible revamp snapshot'
Check (Contains $reconcile 'if (!revampEnabled && !HasOpenAiInfluenceForeignLedgers()) return;') 'daily OFF scan only when AII ledger exists'
Check (Contains $reconcile 'if (!revampEnabled && !IsAiInfluenceForeignLedger(war)) continue;') 'daily OFF affects AII ledger only'
Check ((Contains $reconcile 'HostageCustodyGuard.IsProtected(h)') -and
       (Contains $reconcile 'RetainedTreatyPrisonerBehavior.GetCaptorKingdom(h)') -and
       (Contains $reconcile 'war.ReconcilePrisoners(current, C.WarScorePrisonerCap)')) 'hostage safety + original custody snapshot retained'
Check (Contains $reconcile 'if (revampEnabled)') 'claim feud reconciliation still runs ONLY with Revamp ON'
Check ((Contains $war 'CampaignEvents.HeroPrisonerReleased.AddNonSerializedListener(this, OnScorePrisonerReleased)') -and
       (Contains $war 'CampaignEvents.HeroKilledEvent.AddNonSerializedListener(this, (hero, killer, detail, show) => RemoveCustodyScore(hero))') -and
       (Contains $war 'ReconcileReversibleScores();')) 'all custody callers preserved'
Check ((Contains $war 'if (!WarPeaceRevampBehavior.IsRevampEnabled() && !HasOpenAiInfluenceForeignLedgers())') -and
       (Contains $war 'war.RecordPrisoner(prisoner.StringId, delta, C.WarScorePrisonerCap)') -and
       (Contains $f1 'private static bool ShouldPreventAutonomousForeignResolution(')) 'captured prisoner accounting and no Bellum forced foreign peace unchanged'
Write-Host 'STAGE32H2N_SOURCE_CONTRACT_PASS -- Windows Native build and actual campaign tests PENDING'
