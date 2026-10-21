$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
function Read($path) { Get-Content -Raw -LiteralPath (Join-Path $root $path) }
function Check($value,$label) { if (!$value) { throw "FAIL STAGE8_NPC_CROWN_SOURCE $label" }; Write-Host "PASS STAGE8_NPC_CROWN_SOURCE $label" }
$service=Read 'Behaviors/CourtNpcTreasonLifecycle.cs'
$intents=Read 'Behaviors/CourtNpcTreasonIntents.cs'
$assignment=Read 'Behaviors/CourtNpcTreasonAssignment.cs'
$court=Read 'Behaviors/CourtAgendaBehavior.cs'
$codec=Read 'NpcCrownTreasonIntentRecord.cs'
$save=Read 'BellumCivileSaveDefiner.cs'
$baseline=Read 'Tests/AiInfluenceNpcCrownBaseline.Tests.ps1'
Check ($service.Contains('_lastNpcTreasonReviewDay == today') -and
    $service.Contains('Math.Floor(now)') -and
    $court.Contains('MaintainNpcTreasonLifecycle();')) 'one_daily_pass_on_existing_bellum_tick'
Check ($service.Contains('_npcTreasonAgendaIds.ContainsKey(entry.Key)') -and
    $service.Contains('_npcTreasonClosures.ContainsKey(entry.Key)')) 'attached_and_terminal_tickets_not_mutated'
Check ($service.Contains('3d * CampaignTime.DaysInYear') -and
    $service.Contains('2d * BellumCivileOptions.CourtTermDays') -and
    $service.Contains('expired_unassigned')) 'bounded_expiry_respects_court_term'
Check ($service.Contains('cancelled_realm_invalid') -and
    $service.Contains('cancelled_ruler_changed') -and
    $service.Contains('cancelled_target_invalid') -and
    $service.Contains('cancelled_automatic_disabled')) 'all_hard_invalidation_cases'
Check ($intents.Contains('BC_CourtNpcTreasonClosures_v1') -and
    $intents.Contains('PendingNpcTreasonIntentCount(realm.StringId)') -and
    $intents.Contains('_npcTreasonIntents.Count >= MaxNpcTreasonIntents') -and
    $assignment.Contains('IsNpcTreasonTerminalReason(closed)')) 'saved_tombstone_and_global_id_limit'
Check ($assignment.Contains('!_npcTreasonClosures.ContainsKey(pair.Key)') -and
    $intents.Contains('new NpcCrownTreasonIntentSubmission(false,') -and
    $intents.Contains('external_intent_id_collision')) 'closed_id_no_replay_or_reassignment'
Check ($codec.Contains('internal const string Version = "1"') -and
    !$service.Contains('_agendas.Add(') -and
    !$service.Contains('TryPay(') -and
    !$service.Contains('QueueExpulsionVote(') -and
    !$service.Contains('FileAgendaTreasonVote(') -and
    $baseline.Contains('direct_player_crown_can_file_immediately')) 'codec_and_native_player_court_unmodified'
Check ($save.Contains('ConstructContainerDefinition(typeof(Dictionary<string, string>))') -and
    !$service.Contains('SaveableField') -and
    !$service.Contains('AddClassDefinition')) 'no_new_save_type_registration'
Write-Host 'STAGE8_NPC_CROWN_SOURCE_PASS — source contracts only; no game binary validated.'
