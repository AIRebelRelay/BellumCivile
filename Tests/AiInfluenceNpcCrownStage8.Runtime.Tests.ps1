$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
function Check($ok,$name) { if (!$ok) { throw "FAIL STAGE8_NPC_CROWN_RUNTIME $name" }; Write-Host "PASS STAGE8_NPC_CROWN_RUNTIME $name" }
$sources = @(
    'NpcCrownTreasonIntentRecord.cs',
    'Behaviors/CourtNpcTreasonIntents.cs',
    'Behaviors/CourtNpcTreasonAssignment.cs',
    'Behaviors/CourtNpcTreasonLifecycle.cs',
    'BellumIntegrationNpcCrown.cs',
    'Tests/AiInfluenceNpcCrownStage6.Stubs.cs',
    'Tests/AiInfluenceNpcCrownStage7.Stubs.cs'
)
Add-Type -Path @($sources | ForEach-Object { Join-Path $root $_ }) -ErrorAction Stop
$KType = [TaleWorlds.CampaignSystem.Kingdom]
$CType = [TaleWorlds.CampaignSystem.Clan]
$Day = [TaleWorlds.CampaignSystem.CampaignTime]
$courtType = [BellumCivile.Behaviors.CourtAgendaBehavior]
$api = [BellumCivile.BellumIntegration]
$review = $courtType.GetMethod('MaintainNpcTreasonLifecycle',[Reflection.BindingFlags]'Instance, NonPublic')
$attach = $courtType.GetMethod('TryAttachStagedNpcTreason',[Reflection.BindingFlags]'Instance, NonPublic')
$sync = $courtType.GetMethod('SyncNpcTreasonIntents',[Reflection.BindingFlags]'Instance, NonPublic')
function NewCourt { $courtType::Current = $courtType::new() }
function ReviewAt([double]$day) {
    $Day::CurrentDay = $day
    [void]$review.Invoke($courtType::Current, @())
}
function Slot($k,$r) {
    $agenda = [BellumCivile.CourtAgendaRecord]::new()
    $agenda.Realm = $k; $agenda.Sponsor = $r
    $agenda.State = [BellumCivile.CourtAgendaState]::NotProposed
    $courtType::Current.AddAgendaForTest($agenda)
    return $agenda
}
$k = $KType::new(); $k.StringId = 'realm-8'; $KType::All.Add($k)
$r = $CType::new(); $r.StringId='ruler-8'; $r.Kingdom=$k
$r.Leader = [TaleWorlds.CampaignSystem.Hero]::new()
$t = $CType::new(); $t.StringId='target-8'; $t.Kingdom=$k
$t.Leader = [TaleWorlds.CampaignSystem.Hero]::new(); $t.Leader.Relation = -70
$other = $CType::new(); $other.StringId='other-8'; $other.Kingdom=$k
$other.Leader = [TaleWorlds.CampaignSystem.Hero]::new(); $other.Leader.Relation = -70
$k.RulingClan=$r; $k.Clans.Add($r); $k.Clans.Add($t); $k.Clans.Add($other)
$player=$CType::new(); $player.StringId='player'
$CType::PlayerClan=$player
$campaign=[TaleWorlds.CampaignSystem.Campaign]::new()
$campaign.Ideology=[BellumCivile.Behaviors.IdeologyBehavior]::new()
[TaleWorlds.CampaignSystem.Campaign]::Current=$campaign
$Day::CurrentDay = 17.25
NewCourt

foreach ($id in @('one','two','three','four')) {
    $res=$api::TryStageNpcTreasonIntent($k,$r,$t,$id)
    Check ($res.Accepted -and $res.Intent.Status -eq 'staged_not_scheduled') "stage_$id"
}
$full=$api::TryStageNpcTreasonIntent($k,$r,$other,'fifth')
Check (!$full.Accepted -and $full.Reason -eq 'realm_intent_capacity_reached') 'four_unassigned_cap'
$a=Slot $k $r
$attached=[bool]$attach.Invoke($courtType::Current,
    [object[]]@($a,[BellumCivile.CourtTermContext]::new($k)))
$extra=$api::TryStageNpcTreasonIntent($k,$r,$other,'fifth')
Check ($attached) 'first_staged_intent_attached_to_free_crown_slot'
Check ($api::GetNpcTreasonIntent($k,'one').Status -eq 'court_announced') 'native_crown_attachment_is_visible'
Check ($extra.Accepted -and $extra.Reason -eq 'staged_not_scheduled') 'attached_ticket_releases_pending_slot'
Check ($a.ObjectiveData.TargetId -eq 'target-8' -and
    $courtType::Current.NotificationCount -eq 1) 'native_agenda_assignment_exactly_once'

NewCourt
$Day::CurrentDay=22.5
$old=$api::TryStageNpcTreasonIntent($k,$r,$t,'ruler-replaced')
$newRuler=$CType::new(); $newRuler.StringId='new-ruler'; $newRuler.Kingdom=$k
$newRuler.Leader=[TaleWorlds.CampaignSystem.Hero]::new()
$k.RulingClan=$newRuler
ReviewAt 23.25
$closed=$api::GetNpcTreasonIntent($k,'ruler-replaced')
$replay=$api::TryStageNpcTreasonIntent($k,$r,$t,'ruler-replaced')
Check ($closed.Status -eq 'cancelled_ruler_changed' -and !$replay.Accepted -and
    $replay.Reason -eq $closed.Status -and
    $replay.Intent.SubmittedDay -eq $old.Intent.SubmittedDay) 'ruler_change_terminal_idempotent'
$k.RulingClan=$r

NewCourt
$Day::CurrentDay=25.25
[void]$api::TryStageNpcTreasonIntent($k,$r,$t,'target-moved')
$t.Kingdom=$null
ReviewAt 26.25
Check ($api::GetNpcTreasonIntent($k,'target-moved').Status -eq
    'cancelled_target_invalid') 'target_leaves_realm_terminal'
$t.Kingdom=$k

NewCourt
$Day::CurrentDay=27.25
[void]$api::TryStageNpcTreasonIntent($k,$r,$t,'disabled')
[BellumCivile.BellumCivileOptions]::EnableAutomaticTreasonIndictments=$false
ReviewAt 28.25
Check ($api::GetNpcTreasonIntent($k,'disabled').Status -eq
    'cancelled_automatic_disabled') 'toggle_change_cancels_unassigned'
[BellumCivile.BellumCivileOptions]::EnableAutomaticTreasonIndictments=$true

NewCourt
$Day::CurrentDay=30.25
[void]$api::TryStageNpcTreasonIntent($k,$r,$t,'realm-ended')
$k.IsEliminated=$true
ReviewAt 31.25
Check ($api::GetNpcTreasonIntent($k,'realm-ended').Status -eq
    'cancelled_realm_invalid') 'eliminated_realm_terminal'
$k.IsEliminated=$false

NewCourt
$Day::CurrentDay=35.25
[void]$api::TryStageNpcTreasonIntent($k,$r,$t,'aged-out')
ReviewAt 35.75
Check ($api::GetNpcTreasonIntent($k,'aged-out').Status -eq
    'staged_not_scheduled') 'same_day_not_prematurely_expired'
ReviewAt 40.25
Check ($api::GetNpcTreasonIntent($k,'aged-out').Status -eq
    'staged_not_scheduled') 'still_pending_under_age_limit'
ReviewAt 300.25
$expiry=$api::GetNpcTreasonIntent($k,'aged-out')
Check ($expiry.Status -eq 'expired_unassigned') 'staging_expires_after_bounded_game_days'
$save=[TaleWorlds.CampaignSystem.FakeNpcCrownStore]::new()
[void]$sync.Invoke($courtType::Current, @($save))
Check ($save.Saved['BC_CourtNpcTreasonClosures_v1']['aged-out'] -eq
    'expired_unassigned') 'closure_persisted_to_existing_dictionary_type'
NewCourt
$save.Writing=$false
[void]$sync.Invoke($courtType::Current, @($save))
$after=$api::GetNpcTreasonIntent($k,'aged-out')
$retry=$api::TryStageNpcTreasonIntent($k,$r,$t,'aged-out')
Check ($after.Status -eq 'expired_unassigned' -and !$retry.Accepted -and
    $retry.Intent.SubmittedDay -eq $expiry.SubmittedDay) 'closed_ticket_survives_reload_and_replay_refused'
$collision=$api::TryStageNpcTreasonIntent($k,$r,$other,'aged-out')
Check (!$collision.Accepted -and $collision.Reason -eq
    'external_intent_id_collision') 'terminal_tombstone_blocks_cross_target_id_reuse'
$validNew=$api::TryStageNpcTreasonIntent($k,$r,$other,'fresh-after-expiry')
Check ($validNew.Accepted -and $validNew.Intent.Status -eq
    'staged_not_scheduled') 'expired_tombstone_frees_realm_capacity'

NewCourt
$Day::CurrentDay=42.25
[void]$api::TryStageNpcTreasonIntent($k,$r,$t,'native-court')
$native=Slot $k $r
[void]$attach.Invoke($courtType::Current,
    [object[]]@($native,[BellumCivile.CourtTermContext]::new($k)))
$k.RulingClan=$newRuler
ReviewAt 500.25
$still=$api::GetNpcTreasonIntent($k,'native-court')
Check ($still.Status -eq 'court_announced' -and
    $still.CourtAgendaId -eq $native.IntegrationId) 'attached_native_vote_never_cancelled_by_ticket_lifecycle'
Check ($courtType::Current.NotificationCount -eq 1) 'maintenance_does_not_emit_native_action_or_reattach'
$k.RulingClan=$r
Write-Host 'STAGE8_NPC_CROWN_RUNTIME_PASS — isolated compiled Bellum lifecycle, NOT real Bannerlord save/build.'
