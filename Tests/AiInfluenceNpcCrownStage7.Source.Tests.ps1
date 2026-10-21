$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
function Read($path) { Get-Content -Raw (Join-Path $root $path) }
function Check($value,$label) { if (!$value) { throw "FAIL STAGE7_NPC_CROWN_SOURCE $label" }; Write-Host "PASS STAGE7_NPC_CROWN_SOURCE $label" }
$court = Read 'Behaviors/CourtAgendaBehavior.cs'
$assign = Read 'Behaviors/CourtNpcTreasonAssignment.cs'
$registry = Read 'Behaviors/CourtNpcTreasonIntents.cs'
$snapshot = Read 'NpcCrownTreasonIntentRecord.cs'
$executive = Read 'Behaviors/CourtExecutiveAgendas.cs'
$openStart = $court.IndexOf('private void OpenTerm(')
$openEnd = $court.IndexOf('private void Advance(', $openStart)
$open = $court.Substring($openStart,$openEnd-$openStart)
$priority = $open.IndexOf('AssignPriorityRoyalPeace(agenda)')
$council = $open.IndexOf('MaintainCouncilVacancyPriority(realm)')
$integration = $open.IndexOf('TryAttachStagedNpcTreason(agenda, context)')
$selector = $open.IndexOf('_objectiveSelector.SelectBatch')
Check ($priority -ge 0 -and $council -gt $priority -and
    $integration -gt $council -and $selector -gt $integration) 'native_priority_order_before_external_intent'
Check ($open.Contains('GetAgenda(realm, null) != agenda') -and
    $open.Contains('if (sponsor == Clan.PlayerClan)') -and
    $assign.Contains('agenda.State != CourtAgendaState.NotProposed')) 'only_fresh_free_nonplayer_crown_slot'
Check ($assign.Contains('source.EvaluateCandidate(context, owner, candidate)') -and
    $assign.Contains('!evaluation.Selectable || !evaluation.Viable') -and
    $assign.Contains('source.ApplySelection(agenda,')) 'native_legality_and_selection_not_bypassed'
Check ($assign.Contains('IntegrationRecords()') -and
    $assign.Contains('CourtAgendaState.Announced') -and
    $assign.Contains('court_superseded') -and $assign.Contains('court_missing')) 'native_current_status_not_cached_success'
Check ($registry.Contains('BC_CourtNpcTreasonIntents_v1') -and
    $registry.Contains('BC_CourtNpcTreasonAgendaIds_v1') -and
    $snapshot.Contains('string courtAgendaId = null')) 'stage6_ticket_codec_backward_compatible_save'
Check (!$assign.Contains('QueueExpulsionVote(') -and
    !$assign.Contains('TryStartTreasonVote(') -and
    !$assign.Contains('TryPay(') -and
    !$assign.Contains('AddDecisionAsModAction(') -and
    !$assign.Contains('Harmony') -and
    $executive.Contains('FileAgendaTreasonVote(agenda.Realm')) 'native_filing_payment_vote_ownership_preserved'
Write-Host 'STAGE7_NPC_CROWN_SOURCE_PASS; game DLL compile and save still unverified.'
