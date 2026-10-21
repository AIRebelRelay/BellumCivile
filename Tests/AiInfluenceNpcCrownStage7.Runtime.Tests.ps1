$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
function Check($ok, $name) {
    if (!$ok) { throw "FAIL STAGE7_NPC_CROWN_RUNTIME $name" }
    Write-Host "PASS STAGE7_NPC_CROWN_RUNTIME $name"
}
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

$k = [TaleWorlds.CampaignSystem.Kingdom]::new()
$k.StringId = 'realm'
$r = [TaleWorlds.CampaignSystem.Clan]::new()
$r.StringId = 'ruler'; $r.Kingdom = $k
$r.Leader = [TaleWorlds.CampaignSystem.Hero]::new()
$t = [TaleWorlds.CampaignSystem.Clan]::new()
$t.StringId = 'target'; $t.Kingdom = $k
$t.Leader = [TaleWorlds.CampaignSystem.Hero]::new()
$t.Leader.Relation = -70
$k.RulingClan = $r
$k.Clans.Add($r); $k.Clans.Add($t)
$player = [TaleWorlds.CampaignSystem.Clan]::new()
$player.StringId = 'player'
[TaleWorlds.CampaignSystem.Clan]::PlayerClan = $player
$ideology = [BellumCivile.Behaviors.IdeologyBehavior]::new()
$campaign = [TaleWorlds.CampaignSystem.Campaign]::new()
$campaign.Ideology = $ideology
[TaleWorlds.CampaignSystem.Campaign]::Current = $campaign
$courtType = [BellumCivile.Behaviors.CourtAgendaBehavior]
$courtType::Current = $courtType::new()
$api = [BellumCivile.BellumIntegration]
$method = $courtType.GetMethod('TryAttachStagedNpcTreason',
    [Reflection.BindingFlags]'Instance, NonPublic')
$sync = $courtType.GetMethod('SyncNpcTreasonIntents',
    [Reflection.BindingFlags]'Instance, NonPublic')
function Slot() {
    $a = [BellumCivile.CourtAgendaRecord]::new()
    $a.Realm = $k; $a.Sponsor = $r
    $a.State = [BellumCivile.CourtAgendaState]::NotProposed
    $courtType::Current.AddAgendaForTest($a)
    return $a
}
function Attach($agenda) {
    return [bool]$method.Invoke($courtType::Current,
        [object[]]@($agenda,[BellumCivile.CourtTermContext]::new($k)))
}
$submitted = $api::TryStageNpcTreasonIntent($k,$r,$t,'intent-1')
Check ($submitted.Accepted -and $submitted.Intent.Status -eq 'staged_not_scheduled') 'stage_is_not_court'
$a = Slot
Check ((Attach $a) -and $a.ObjectiveData.Kind -eq 'treason' -and
    $a.ObjectiveData.TargetId -eq 'target' -and
    $a.State -eq [BellumCivile.CourtAgendaState]::Announced -and
    $courtType::Current.NotificationCount -eq 1) 'one_exact_npc_crown_agenda_no_immediate_vote'
$ticket = $api::GetNpcTreasonIntent($k,'intent-1')
Check ($ticket.Status -eq 'court_announced' -and
    $ticket.CourtAgendaId -eq $a.IntegrationId) 'status_and_id_follow_native_agenda'
Check (!(Attach (Slot)) -and $courtType::Current.NotificationCount -eq 1) 'same_ticket_cannot_attach_twice'
$a.State = [BellumCivile.CourtAgendaState]::Deliberating
Check ($api::GetNpcTreasonIntent($k,'intent-1').Status -eq 'court_deliberating') 'read_current_bellum_filing_state'
$a.ObjectiveData.Kind = 'grant_fief'
Check ($api::GetNpcTreasonIntent($k,'intent-1').Status -eq 'court_superseded') 'native_overwrite_not_misreported_as_treason'
$a.ObjectiveData.Kind = 'treason'
Check ($api::GetNpcTreasonIntent($k,'intent-1').Status -eq 'court_deliberating') 'readback_does_not_mutate_or_recreate_motions'
$save = [TaleWorlds.CampaignSystem.FakeNpcCrownStore]::new()
[void]$sync.Invoke($courtType::Current, @($save))
Check ($save.Saved['BC_CourtNpcTreasonAgendaIds_v1']['intent-1'] -eq $a.IntegrationId) 'linked_agenda_identity_persisted'
$courtType::Current = $courtType::new()
$courtType::Current.AddAgendaForTest($a)
$save.Writing = $false
[void]$sync.Invoke($courtType::Current, @($save))
Check ($api::GetNpcTreasonIntent($k,'intent-1').CourtAgendaId -eq $a.IntegrationId -and
    $api::GetNpcTreasonIntent($k,'intent-1').Status -eq 'court_deliberating') 'reload_preserves_link_without_second_vote'
$replay = $api::TryStageNpcTreasonIntent($k,$r,$t,'intent-1')
Check ($replay.Accepted -and $replay.Reason -eq 'already_staged' -and
    $replay.Intent.Status -eq 'court_deliberating') 'replay_reflects_real_native_state'
$courtType::Current = $courtType::new()
$save.Writing = $false
[void]$sync.Invoke($courtType::Current, @($save))
Check ($api::GetNpcTreasonIntent($k,'intent-1').Status -eq 'court_missing') 'missing_native_agenda_fails_closed_no_false_completion'

$courtType::Current = $courtType::new()
[void]$api::TryStageNpcTreasonIntent($k,$r,$t,'intent-2')
[BellumCivile.CourtExecutiveObjectiveSource]::IsViable = $false
Check (!(Attach (Slot))) 'unviable_forecast_does_not_force_assignment'
[BellumCivile.CourtExecutiveObjectiveSource]::IsViable = $true
[BellumCivile.BellumCivileOptions]::EnableAutomaticTreasonIndictments = $false
Check (!(Attach (Slot))) 'disabled_automatic_treason_respected_after_staging'
[BellumCivile.BellumCivileOptions]::EnableAutomaticTreasonIndictments = $true
$busy = Slot
$busy.State = [BellumCivile.CourtAgendaState]::Announced
Check (!(Attach $busy)) 'already_announced_crown_docket_not_overwritten'
$busy.State = [BellumCivile.CourtAgendaState]::NotProposed
$busy.Faction = [object]::new()
Check (!(Attach $busy)) 'faction_agenda_not_claimed_by_crown'
$busy.Faction = $null
Check ((Attach $busy) -and $courtType::Current.NotificationCount -eq 1) 'pending_ticket_can_attach_to_later_free_slot'
Write-Host 'STAGE7_NPC_CROWN_RUNTIME_PASS — stub-compiled Bellum API; NOT real Bannerlord build/save.'
