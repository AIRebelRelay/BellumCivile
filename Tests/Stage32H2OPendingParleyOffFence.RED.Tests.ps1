# Stage32H2O — RED-FIRST source contract for old player pending parley + Revamp OFF.
# Intentional RED on the 2026-11-01 Native source: future production gate NOT yet implemented.
# Execute with pwsh 7+ in one integrated alpha QA. Source check != game validation.
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$src = Get-Content -LiteralPath (Join-Path $root 'Behaviors/ForeignTreatyBehavior.cs') -Raw
$vm = Get-Content -LiteralPath (Join-Path $root 'UI/Parley/PeaceParleyVM.cs') -Raw
$war = Get-Content -LiteralPath (Join-Path $root 'Behaviors/WarScoreBehavior.cs') -Raw
$f1 = Get-Content -LiteralPath (Join-Path $root 'Behaviors/WarScoreAiInfluenceForeignLedger.cs') -Raw
function Check([bool]$ok, [string]$label) {
    if (-not $ok) { throw "STAGE32H2O_RED $label" }
    Write-Host "STAGE32H2O_SOURCE_CHECK $label"
}
function SliceBetween([string]$text, [string]$start, [string]$end) {
    $a = $text.IndexOf($start, [StringComparison]::Ordinal)
    if ($a -lt 0) { throw "STAGE32H2O_RED missing $start" }
    $b = $text.IndexOf($end, $a + $start.Length, [StringComparison]::Ordinal)
    if ($b -lt 0) { throw "STAGE32H2O_RED missing $end" }
    return $text.Substring($a, $b - $a)
}
$sign = SliceBetween $src 'public bool TrySignPlayerParley(' 'private TreatyProposalRecord FindPendingPlayerProposal('
$queue = SliceBetween $src 'private bool TryQueueParley(' 'private bool CanSubmitAutomaticDraft('
$daily = SliceBetween $src 'private void OnDailyTick(' 'private void ResolvePendingParley('
$apply = SliceBetween $src 'private bool ApplyTreaty(' 'private bool ApplyTreatyCore('
Check ($vm.Contains('public void ExecuteSignTreaty()') -and
    $vm.Contains('treaties.TrySignPlayerParley(_proposal?.ProposalId, out report)')) 'UI Sign directly calls Native public TrySignPlayerParley'
Check ($queue.Contains('if (!WarPeaceRevampBehavior.IsRevampEnabled()') -and
    $daily.Contains('if (!WarPeaceRevampBehavior.IsRevampEnabled())')) 'new Native queued parley and automatic daily settlement are gated OFF'
Check ($f1.Contains('ShouldPreventAutonomousForeignResolution') -and
    $war.Contains('if (IsAiInfluenceForeignLedger(war))')) 'AII ledger remains accounting-only in ordinary scoring and terminal path'
Check ($sign.Contains('SpendCouncilCommitments(proposal, winnerCouncil, loserCouncil)') -and
    $sign.Contains('ApplyTreaty(war, proposal, winner, loser)') -and
    $apply.Contains('ApplyTreatyCore(war, proposal, winner, loser)')) 'previous valid sign and treaty path still exists for ON'
# The next check is EXPECTED RED until a separately approved safe runtime policy
# prevents stale player GUI signing from spending influence / making peace after OFF.
$signOffGate = $sign.IndexOf('if (!WarPeaceRevampBehavior.IsRevampEnabled())', [StringComparison]::Ordinal)
$firstMutable = $sign.IndexOf('SpendCouncilCommitments(proposal, winnerCouncil, loserCouncil)', [StringComparison]::Ordinal)
Check ($signOffGate -ge 0 -and $signOffGate -lt $firstMutable) 'Revamp OFF must deny pending player signing BEFORE council influence and treaty execution'
Write-Host 'STAGE32H2O_SOURCE_CONTRACT_PASS -- actual C#/game/save and OFF→ON reactivation tests PENDING'
