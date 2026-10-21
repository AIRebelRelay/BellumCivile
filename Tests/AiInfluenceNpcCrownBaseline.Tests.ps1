# Stage 5 — source-backed baseline regression contract.
# Read only. These checks preserve Bellum 1.4.5 game semantics before a new NPC Crown integration API.
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
function Source($relativePath) {
    $path = Join-Path $root $relativePath
    if (-not (Test-Path -LiteralPath $path)) { throw "Required upstream source missing: $relativePath" }
    Get-Content -Raw -LiteralPath $path
}
function Require($condition, $scenario) {
    if (-not $condition) { throw "FAIL AI_INFLUENCE_NPC_CROWN_BASELINE $scenario" }
    Write-Host "PASS AI_INFLUENCE_NPC_CROWN_BASELINE $scenario"
}
function Section($content, $begin, $end, $label) {
    $start = $content.IndexOf($begin, [StringComparison]::Ordinal)
    $stop = $content.IndexOf($end, [Math]::Max($start, 0), [StringComparison]::Ordinal)
    if ($start -lt 0 -or $stop -le $start) { throw "Source section not found: $label" }
    $content.Substring($start, $stop - $start)
}
function InOrder($content, [string[]]$markers) {
    $position = -1
    foreach ($marker in $markers) {
        $next = $content.IndexOf($marker, $position + 1, [StringComparison]::Ordinal)
        if ($next -lt 0) { return $false }
        $position = $next
    }
    return $true
}

$ideology = Source 'Behaviors/IdeologyBehavior.cs'
$court = Source 'Behaviors/CourtAgendaBehavior.cs'
$executive = Source 'Behaviors/CourtExecutiveAgendas.cs'
$player = Source 'Behaviors/CourtPlayerCrownActions.cs'
$expulsion = Source 'Behaviors/ExpulsionDeliberationBehavior.cs'
$objective = Source 'CourtExecutiveObjectiveSource.cs'
$integration = Source 'BellumIntegration.cs'
$snapshots = Source 'IntegrationSnapshots.cs'
$record = Source 'CourtAgendaRecord.cs'
$readOnlyLock = Section $ideology 'private bool IsRejectedExpulsionLocked(' 'public void RecordExpulsionVoteOutcome' 'rejected expulsion lock'
$indictGate = Section $ideology 'public bool CanRulerIndictClan(' 'private void OnSessionLaunched(' 'indictment gate'
$startVote = Section $ideology 'public bool TryStartTreasonVote(' 'internal bool FileAgendaTreasonVote(' 'start vote'
$nominate = Section $executive 'public bool TryNominateTreason(' 'private KingdomDecision ExecutiveDecision(' 'NPC nomination'
$openTerm = Section $court 'private void OpenTerm(' 'private void Advance(' 'open term'
$advance = Section $executive 'private void AdvanceExecutive(' 'private static bool MatchesExecutive(' 'advance executive'
$playerCrown = Section $player 'private bool FilePlayerCrownBusiness(' 'internal bool TryPlayerCouncilBusiness(' 'player crown filing'
$playerTreason = $player.Substring($player.IndexOf('internal bool TryPlayerTreasonBusiness('))

Require ($indictGate.Contains('bool readOnly = false') -and
    $indictGate.Contains('IsRejectedExpulsionLocked(kingdom, targetClan, relation, readOnly)') -and
    $readOnlyLock.Contains('if (!readOnly) _rejectedExpulsionRelations.Remove(key)')) 'read_only_indictment_does_not_clear_rejection_lock'

Require ($startVote.Contains('TryPlayerTreasonBusiness') -and
    $startVote.Contains('TryNominateTreason') -and
    -not $startVote.Contains('QueueExpulsionVote')) 'player_and_npc_nomination_dispatch_is_bellum_owned'

Require ($nominate.Contains('proposer != realm.RulingClan || proposer != Clan.PlayerClan') -and
    $nominate.Contains('CanRulerIndictClan(realm, target, false, out explanation, true)')) 'npc_nomination_currently_not_publicly_authorized'

Require ($playerCrown.Contains('NewPlayerCrownBusiness(realm)') -and
    (InOrder $playerCrown @('_agendas.Add(agenda)', 'Advance(agenda, Campaign.Current.GetCampaignBehavior<IdeologyBehavior>())')) -and
    $playerTreason.Contains('return FilePlayerCrownBusiness(realm, motion)')) 'direct_player_crown_can_file_immediately'

Require ($openTerm.Contains('existing?.IsFiled == true || existing?.IsUnopened == true') -and
    $openTerm.Contains('realm.RulingClan == Clan.PlayerClan') -and
    (InOrder $openTerm @('AssignPriorityDecree(agenda)', 'AssignPriorityRoyalPeace(agenda)', 'MaintainCouncilVacancyPriority(realm)', '_objectiveSelector.SelectBatch'))) 'native_crown_priority_and_existing_agenda_protected'

Require ((InOrder $advance @('TryPay(agenda, decision.GetProposalInfluenceCost())', 'ideology.FileAgendaTreasonVote(')) -and
    $advance.Contains('if (!agenda.SessionDate.IsPast) return;') -and
    $advance.Contains('if (kind == CourtExecutiveRules.Treason)')) 'native_treason_filing_waits_and_charges_once'

Require ($expulsion.Contains('if (_pendingExpelDate.ContainsKey(key))') -and
    $expulsion.Contains('Expulsion deliberation duplicate ignored') -and
    $expulsion.Contains('public bool HasPendingExpulsionForTarget(')) 'native_pending_expulsion_target_duplicate_guard'

Require ($executive.Contains('if (!BellumCivileOptions.EnableAutomaticTreasonIndictments) return;') -and
    $objective.Contains('!context.ManualSelection && !BellumCivileOptions.EnableAutomaticTreasonIndictments')) 'automatic_treason_toggle_respected'

Require ($integration.Contains('public static IReadOnlyList<CourtAgendaSnapshot> GetCourtAgendas(Kingdom realm)') -and
    $integration.Contains('BellumIntegrationBehavior.RequireCampaignThread()') -and
    $snapshots.Contains('public string Id { get; }') -and
    $snapshots.Contains('public string TargetId { get; }') -and
    $snapshots.Contains('public CourtAgendaState State { get; }')) 'supported_read_only_court_snapshot_campaign_thread'

Require ($court.Contains('dataStore.SyncData("BC_CourtAgendas", ref _agendas)') -and
    $court.Contains('RestoreIntegrationIds()') -and
    $record.Contains('[SaveableField(51)] internal string IntegrationId')) 'court_agenda_serialization_and_identity_stable'

Require ($executive.Contains('Court objective concluded; realm=') -and
    $executive.Contains('if (agenda.ResultApplied) return;')) 'terminal_court_result_exactly_once_guard'

Write-Host 'BASELINE SOURCE REGRESSIONS PASS; NPC Crown API NOT IMPLEMENTED; BANNERLORD GAME NOT TESTED.'
