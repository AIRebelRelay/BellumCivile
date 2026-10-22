$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
function Check($ok, $name) {
    if (-not $ok) { throw "FAIL STAGE16_NPC_CROWN_NOTICE $name" }
    Write-Host "PASS STAGE16_NPC_CROWN_NOTICE $name"
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
$k.StringId='realm-16'
$r = [TaleWorlds.CampaignSystem.Clan]::new()
$r.StringId='ruler-16'; $r.Kingdom=$k; $r.Leader=[TaleWorlds.CampaignSystem.Hero]::new()
$t = [TaleWorlds.CampaignSystem.Clan]::new()
$t.StringId='target-16'; $t.Kingdom=$k; $t.Leader=[TaleWorlds.CampaignSystem.Hero]::new()
$t.Leader.Relation = -70
$k.RulingClan = $r; $k.Clans.Add($r); $k.Clans.Add($t)
$player = [TaleWorlds.CampaignSystem.Clan]::new()
$player.StringId = 'player-16'
[TaleWorlds.CampaignSystem.Clan]::PlayerClan=$player
$campaign = [TaleWorlds.CampaignSystem.Campaign]::new()
$campaign.Ideology=[BellumCivile.Behaviors.IdeologyBehavior]::new()
[TaleWorlds.CampaignSystem.Campaign]::Current=$campaign
$courtType = [BellumCivile.Behaviors.CourtAgendaBehavior]
$courtType::Current=$courtType::new()
$api = [BellumCivile.BellumIntegration]
$attach = $courtType.GetMethod('TryAttachStagedNpcTreason', [Reflection.BindingFlags]'NonPublic, Instance')
function NewSlot {
    $agenda = [BellumCivile.CourtAgendaRecord]::new()
    $agenda.Realm = $k; $agenda.Sponsor = $r
    $agenda.State = [BellumCivile.CourtAgendaState]::NotProposed
    $courtType::Current.AddAgendaForTest($agenda)
    return $agenda
}
function Assign($agenda) {
    return [bool]$attach.Invoke($courtType::Current,
        [object[]]@($agenda,[BellumCivile.CourtTermContext]::new($k)))
}
Check ($null -eq $api::GetActiveNpcCrownAnnouncement($k)) 'no_context_before_staging'
$staged = $api::TryStageNpcTreasonIntent($k,$r,$t,'exact-token-1')
Check ($staged.Accepted -and $null -eq $api::GetActiveNpcCrownAnnouncement($k)) 'private_stage_not_a_public_notice'
$a = NewSlot
Check (Assign $a) 'native_ticket_attached'
$noticed = $courtType::Current.LastNoticeToken
Check ($null -ne $noticed -and $noticed.ExternalIntentId -eq 'exact-token-1' -and
    $noticed.RealmId -eq 'realm-16' -and $noticed.RulerClanId -eq 'ruler-16' -and
    $noticed.TargetClanId -eq 'target-16' -and
    $noticed.CourtAgendaId -eq $a.IntegrationId -and
    $noticed.Status -eq 'court_announced') 'dedicated_native_notice_witness_has_exact_docket_and_parties'
Check ($null -eq $courtType::Current.WrongRealmNoticeToken) 'same_string_id_does_not_spoof_actual_realm_reference'
Check ($null -eq $api::GetActiveNpcCrownAnnouncement($k)) 'context_cleared_after_normal_notice'
Check ($api::GetNpcTreasonIntent($k,'exact-token-1').CourtAgendaId -eq $a.IntegrationId) 'native_saved_ticket_preserved'
Check (-not (Assign (NewSlot)) -and $courtType::Current.NotificationCount -eq 1) 'replay_never_emits_duplicate_notice'
[void]$api::TryStageNpcTreasonIntent($k,$r,$t,'exact-token-2')
$courtType::Current.ThrowDuringNpcCrownNotice=$true
$second = NewSlot
$threw=$false
try { [void](Assign $second) } catch { $threw=$true }
Check ($threw -and $null -eq $api::GetActiveNpcCrownAnnouncement($k)) 'exception_still_clears_ephemeral_context'
Check ($courtType::Current.NotificationCount -eq 2) 'exception_does_not_fabricate_an_extra_notice'
Check ($api::GetNpcTreasonIntent($k,'exact-token-2').CourtAgendaId -eq $second.IntegrationId) 'native_linkage_does_not_claim_rollback_after_ui_exception'
[cultureinfo]::CurrentCulture = [cultureinfo]::InvariantCulture
[BellumCivile.Behaviors.BellumIntegrationBehavior]::OnCampaignThread=$false
$threadBlocked=$false
try { [void]$api::GetActiveNpcCrownAnnouncement($k) } catch { $threadBlocked=$true }
[BellumCivile.Behaviors.BellumIntegrationBehavior]::OnCampaignThread=$true
Check ($threadBlocked) 'public_getter_preserves_campaign_thread_guard'
$courtType::Current=$null
Check ($null -eq $api::GetActiveNpcCrownAnnouncement($k)) 'missing_court_returns_no_ephemeral_context'
Write-Host 'STAGE16_NPC_CROWN_NOTICE_CONTEXT_PASS; compiled isolated mock only, no live game or sidecar publication.'
