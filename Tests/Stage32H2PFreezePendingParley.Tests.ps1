# Stage32H2P — RED-first Native contract for frozen, saved player parley under Revamp OFF.
# Source contract only; executable .NET/game/save/GUI evidence belongs to alpha QA.
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$src = Get-Content -LiteralPath (Join-Path $root 'Behaviors/ForeignTreatyBehavior.cs') -Raw
$ui = Get-Content -LiteralPath (Join-Path $root 'UI/Parley/PeaceParleyVM.cs') -Raw
function Part([string]$from, [string]$to) {
    $a = $src.IndexOf($from, [StringComparison]::Ordinal)
    if ($a -lt 0) { throw "STAGE32H2P_RED missing $from" }
    $b = $src.IndexOf($to, $a + $from.Length, [StringComparison]::Ordinal)
    if ($b -lt 0) { throw "STAGE32H2P_RED missing $to" }
    return $src.Substring($a, $b - $a)
}
function Check([bool]$ok, [string]$why) {
    if (-not $ok) { throw "STAGE32H2P_RED $why" }
    Write-Host "STAGE32H2P_SOURCE_CHECK $why"
}
function CheckFreeze([string]$method, [string]$snippet, [string]$firstMutation) {
    $gate = $snippet.IndexOf('if (!WarPeaceRevampBehavior.IsRevampEnabled())', [StringComparison]::Ordinal)
    $report = $snippet.IndexOf('report = "Bellum foreign treaty is frozen while War & Peace Revamp is disabled";', [StringComparison]::Ordinal)
    $noMutation = $snippet.IndexOf('return false;', $report + 1, [StringComparison]::Ordinal)
    $mutate = $snippet.IndexOf($firstMutation, [StringComparison]::Ordinal)
    Check ($gate -ge 0 -and $report -gt $gate -and $noMutation -gt $report -and
        $mutate -gt $noMutation -and
        ($snippet.Substring($gate, $noMutation-$gate)).Contains('if (!WarPeaceRevampBehavior.IsRevampEnabled())')) "$method Revamp OFF blocks before state access/mutation"
}
$vote = Part 'public bool TrySetPlayerVote(' 'public bool TryRejectPlayerParley('
$reject = Part 'public bool TryRejectPlayerParley(' 'public bool TrySignPlayerParley('
$sign = Part 'public bool TrySignPlayerParley(' 'private TreatyProposalRecord FindPendingPlayerProposal('
$open = Part 'public bool TryOpenPlayerParley(WarScoreRecord war, bool forced, bool preferWhitePeace, string reason, Kingdom drafter, Action onClosed, out string report)' 'private void EnsureProposalHasDraft('
$draft = Part 'public bool TryReplacePlayerDraft(' 'private bool TryQueueParley('
CheckFreeze 'Vote' $vote '_proposals.FirstOrDefault('
CheckFreeze 'Reject' $reject 'FindPendingPlayerProposal(proposalId)'
CheckFreeze 'Sign' $sign 'FindPendingPlayerProposal(proposalId)'
CheckFreeze 'Open' $open 'GetPendingProposalForPlayer(war)'
CheckFreeze 'Edit draft' $draft '_proposals.FirstOrDefault('
Check ($sign.Contains('SpendCouncilCommitments(proposal, winnerCouncil, loserCouncil)') -and
       $sign.Contains('ApplyTreaty(war, proposal, winner, loser)')) 'original ON signing, councils and treaty execution retained'
Check ($reject.Contains('SpendRulerOverride(playerSide, rejectionOverrideCost)') -and
       $reject.Contains('RejectParley(war, proposal, "player ruler refused the treaty", playerKingdom)')) 'original ON rejection and override retained'
Check ($vote.Contains('proposal.SetPlayerVote(stance, influenceCommitment)') -and
       $draft.Contains('proposal.ReplaceTerms(draft)')) 'original ON vote and draft actions retained'
Check ($open.Contains('PeaceParleyInterface.Instance.Show(proposal, onClosed)') -and
       $ui.Contains('public void ExecuteClose()') -and
       $ui.Contains('_closeAction?.Invoke();')) 'original ON open and UI close retained'
Check ($src.Contains('if (!WarPeaceRevampBehavior.IsRevampEnabled() || war == null || !war.IsActive') -and
       $src.Contains('private void OnDailyTick(')) 'old new-queue and daily OFF controls unchanged'
Write-Host 'STAGE32H2P_SOURCE_PASS -- pwsh/Windows build, gameplay & save QA PENDING'
