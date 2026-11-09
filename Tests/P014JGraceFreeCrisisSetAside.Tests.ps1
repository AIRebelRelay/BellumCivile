# P0-14J RED-first: free "Set the crisis aside" during civil-war grace stays separate from paid declines.
# Source contract; executable behavioral proof is CivilWarGraceTests.Run in the net472 harness.
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
function Source([string]$path) { Get-Content -Raw -LiteralPath (Join-Path $root $path) }
function Check([bool]$ok,[string]$name) {
    if (-not $ok) { throw "P014J_FAIL $name" }
    Write-Host "P014J_PASS $name"
}
$flow = Source 'Behaviors/CourtAgendaPlayerFlow.cs'
$picker = Source 'Behaviors/CourtPlayerMotionPicker.cs'
$fixture = Source 'Tests/SuccessionEngineHarness/CivilWarGraceTests.cs'
$start = $flow.IndexOf('private void ApplyPlayerAgendaChoice(CourtAgendaRecord agenda, int choice, bool crisis)')
$end = $flow.IndexOf('private bool UpdatePlayerAgenda(', $start)
Check ($start -ge 0 -and $end -gt $start) 'player_choice_method_isolated'
$method = $flow.Substring($start, $end - $start)
$free = $method.IndexOf('if (choice == 1 && grace != null)')
$paid = $method.IndexOf('NpcInfluenceBudgetService.TrySpend(Clan.PlayerClan, BlockCost(agenda, crisis)')
Check ($free -ge 0 -and $paid -gt $free) 'free_grace_branch_precedes_paid_influence'
$freeSegment = $method.Substring($free, $paid - $free)
Check ($freeSegment.Contains('agenda.CrisisInterventionPending = false;')
    -and $freeSegment.Contains('agenda.PlayerSelectionConfirmed = true;')
    -and $freeSegment.Contains('NotifyAgenda(agenda);')
    -and $freeSegment.Contains('return;')) 'free_grace_set_aside_commits_without_spend'
Check (-not $freeSegment.Contains('OrdinaryCrisisRestrained')
    -and -not $freeSegment.Contains('ApplyMemberMemory(')
    -and -not $freeSegment.Contains('TrySpend(')) 'free_grace_does_not_mark_restraint_or_punish'
Check ($method.Contains('if (choice == 0 && grace != null)')
    -and $method.Contains('BellumCivileNotifications.ShowPersonal(grace, BellumNotificationColors.Warning);')) 'approve_still_blocked'
Check ($method.Contains('if (choice == 2) { ShowTermMotionPicker(agenda, crisis); return; }')
    -and $method.Contains('NpcInfluenceBudgetService.TrySpend(Clan.PlayerClan, BlockCost(agenda, crisis)')
    -and $method.Contains('agenda.OrdinaryCrisisRestrained |= crisis;')
    -and $method.Contains('ApplyMemberMemory(agenda, C.CourtAgendaDeclineRelationPenalty')) 'existing_paid_declines_and_substitution_preserved'
Check ($picker.Contains('crisis && CourtChallengeGraceBlock(agenda) != null ? 0 : BlockCost(agenda, crisis)')
    -and $picker.Contains('Set the crisis aside')
    -and $picker.Contains('ReplacementCost(agenda, crisis) != price')) 'ui_cost_and_stale_callback_still_guarded'
Check ($fixture.Contains('Set aside under grace never calls influence budget')
    -and $fixture.Contains('Ordinary decline still spends influence and applies member memory without crisis restraint')
    -and $fixture.Contains('Unprotected crisis restraint still costs influence and applies member memory')
    -and $fixture.Contains('Forcing a disabled Approve callback cannot turn a prohibited crisis into a committed coalition')) 'executable_positive_and_neighbor_contracts'
Write-Host 'P014J_SOURCE_PASS; Windows net472 build, runtime fixture and game/save QA still required.'
