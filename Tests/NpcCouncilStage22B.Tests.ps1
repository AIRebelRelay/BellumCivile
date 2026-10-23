$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
function Read($p) { Get-Content -Raw -LiteralPath (Join-Path $root $p) }
function Check($ok, $name) { if (!$ok) { throw "FAIL STAGE22B $name" }; "PASS STAGE22B $name" }

$types = @(Add-Type -Path (Join-Path $root 'NpcCouncilAppointmentIntentRecord.cs') -PassThru)
$codec = @($types | Where-Object FullName -eq 'BellumCivile.NpcCouncilAppointmentIntentCodec')[0]
$flags = [Reflection.BindingFlags]'NonPublic, Static'
$packed = $codec.GetMethod('Pack', $flags).Invoke($null, @('realm_1','clan_1', [int]2, [int]3, 'nominee_1', [double]12.75))
$read = $codec.GetMethod('TryRead', $flags)
$args = [object[]]@('intent-1', $packed, $null)
Check ($read.Invoke($null,$args) -eq $true -and $args[2].RealmId -eq 'realm_1' -and
    $args[2].SponsorClanId -eq 'clan_1' -and $args[2].OfficeValue -eq 3 -and
    $args[2].RequestedCandidateClanId -eq 'nominee_1' -and $args[2].SubmittedDay -eq 12.75 -and
    $args[2].Status -eq 'staged_not_scheduled') 'codec_valid_ticket_is_not_appointment'
$bad = [object[]]@('intent-1', $packed.Replace('staged_not_scheduled','court_passed'), $null)
Check ($read.Invoke($null,$bad) -eq $false) 'terminal_status_cannot_be_forged'
$bad = [object[]]@("bad`nid", $packed, $null)
Check ($read.Invoke($null,$bad) -eq $false) 'newline_in_external_id_rejected'

$api = Read 'BellumIntegrationNpcCouncil.cs'
$native = Read 'Behaviors/CourtNpcCouncilAppointments.cs'
$court = Read 'Behaviors/CourtAgendaBehavior.cs'
$council = Read 'Behaviors/CourtCouncilAgendas.cs'
$queue = Read 'Behaviors/CouncilAppointmentDeliberationBehavior.cs'
Check ($api.Contains('BellumIntegrationBehavior.RequireCampaignThread();') -and
    $api.Contains('GetNpcCouncilAppointmentIntent(')) 'thread_guard_and_persisted_readback'
Check ($court.Contains('SyncNpcCouncilIntents(dataStore);') -and
    $native.Contains('BC_CourtNpcCouncilIntents_v1') -and
    $native.Contains('BC_CourtNpcCouncilAgendaIds_v1') -and
    $native.Contains('BC_CourtNpcCouncilClosures_v1')) 'save_maps_and_idempotence'
Check ($native.Contains('faction.Leader != sponsor') -and
    $native.Contains('sponsor == Clan.PlayerClan') -and
    $native.Contains('MemberCount(faction) < 2')) 'strict_npc_leader_scope'
Check ($native.Contains('source.FindCandidates(context, owner)') -and
    $native.Contains('source.EvaluateCandidate(context, owner, candidate)') -and
    $native.Contains('!evaluation.Selectable')) 'native_candidate_rules'
Check ($native.Contains('new CourtObjectiveCandidate(office.ToString(),') -and
    $native.Contains('source.EvaluateCandidate(context, owner, explicitNomination).Selectable') -and
    !$native.Contains('requestedCandidate == null || c.BeneficiaryId')) 'explicit_candidate_uses_native_viability_not_auto_favorite'
Check ($native.Contains('nativeChoices.Where((c, i) => i != ownerIndex)') -and
    $native.Contains('HasCouncilReservation(agenda.Realm, agenda)')) 'batch_council_exclusivity'
Check ($native.Contains('agenda.State = CourtAgendaState.Announced;') -and
    !$native.Contains('TryQueueAgendaAppointment(') -and
    !$native.Contains('TryPay(') -and !$native.Contains('SetOfficeHolder(')) 'no_instant_vote_payment_or_appointment'
Check ($court.Contains('FreezeNpcCouncilTerminalResults(realm);') -and
    $native.Contains('agenda.IsUnopened') -and
    $native.Contains('court_" + agenda.State.ToString()')) 'terminal_state_frozen_before_prune'
Check ($native.Contains('const string passPrefix = "court_passed|"') -and
    $native.Contains('closed.Substring(passPrefix.Length)') -and
    $native.Contains('outcome += "|" + agenda.PreferredCouncilCandidate.StringId')) 'passed_result_keeps_exact_nominee_after_save_and_prune'
$optionsApi = Read 'BellumIntegrationNpcCouncil.cs'
Check ($optionsApi.Contains('GetNpcCouncilAppointmentOptions(') -and
    $optionsApi.Contains('BellumIntegrationBehavior.RequireCampaignThread();')) 'native_capability_readback_campaign_thread'
Check ($native.Contains('NpcCouncilAdmissionReason(realm, sponsor, faction, office)') -and
    $native.Contains('private string NpcCouncilAdmissionReason(')) 'same_fences_for_capability_and_submission'
Check ($native.Contains('canOmitCandidate = SelectNpcCouncilCandidate(') -and
    $native.Contains('office, null) != null;')) 'unnamed_motion_allowed_only_for_native_viable_default'
$optionRecord = Read 'NpcCouncilAppointmentIntentRecord.cs'
Check ($optionRecord.Contains('public bool CanOmitCandidate { get; }')) 'native_option_snapshot_records_generic_nomination_eligibility'
Check ($native.Contains('SelectNpcCouncilCandidate(context, owner, source,') -and
    $native.Contains('CourtCouncilObjectiveSource.OfficeAvailable(context.Council, office)')) 'capability_uses_native_office_candidate_evaluation'
Check (!$native.Contains('TryStageNpcCouncilAppointmentIntent(realm, sponsor, faction, office,') -and
    !$optionsApi.Contains('GetNpcCouncilAppointmentOptions(realm, sponsor, faction, externalIntentId)')) 'enumeration_never_stages'
Check ($native.Contains('intent_id_collision') -and
    $native.Contains('faction_intent_in_flight') -and
    $native.Contains('cancelled_sponsor_changed')) 'duplicate_and_crown_change_checks'
Check ($council.Contains('agenda.VoteDate, agenda.CouncilMotionId, out _') -and
    $queue.Contains('CourtAgendaBehavior.Current?.ValidateCouncilProceeding(')) 'original_native_ballot_path_preserved'
'STAGE22B_CODEC_SOURCE_CONTRACT_PASS (game build/live tests still required)'
