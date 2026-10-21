$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
function Check($ok, $name) {
    if (!$ok) { throw "FAIL STAGE11_NPC_CROWN_INVENTORY $name" }
    Write-Host "PASS STAGE11_NPC_CROWN_INVENTORY $name"
}
$sourceFiles = @(
    'NpcCrownTreasonIntentRecord.cs',
    'Behaviors/CourtNpcTreasonIntents.cs',
    'Behaviors/CourtNpcTreasonAssignment.cs',
    'Behaviors/CourtNpcTreasonLifecycle.cs',
    'BellumIntegrationNpcCrown.cs',
    'Tests/AiInfluenceNpcCrownStage6.Stubs.cs',
    'Tests/AiInfluenceNpcCrownStage7.Stubs.cs'
)
Add-Type -Path @($sourceFiles | ForEach-Object { Join-Path $root $_ }) -ErrorAction Stop
$k = [TaleWorlds.CampaignSystem.Kingdom]::new()
$k.StringId = 'realm-11'
$r = [TaleWorlds.CampaignSystem.Clan]::new()
$r.StringId = 'ruler-11'; $r.Kingdom = $k
$r.Leader = [TaleWorlds.CampaignSystem.Hero]::new()
$t = [TaleWorlds.CampaignSystem.Clan]::new()
$t.StringId = 'target-11'; $t.Kingdom = $k
$t.Leader = [TaleWorlds.CampaignSystem.Hero]::new()
$t.Leader.Relation = -65
$k.RulingClan = $r; $k.Clans.Add($r); $k.Clans.Add($t)
$player = [TaleWorlds.CampaignSystem.Clan]::new()
$player.StringId = 'player-11'
[TaleWorlds.CampaignSystem.Clan]::PlayerClan = $player
$campaign = [TaleWorlds.CampaignSystem.Campaign]::new()
$campaign.Ideology = [BellumCivile.Behaviors.IdeologyBehavior]::new()
[TaleWorlds.CampaignSystem.Campaign]::Current = $campaign
$courtType = [BellumCivile.Behaviors.CourtAgendaBehavior]
$courtType::Current = $courtType::new()
$api = [BellumCivile.BellumIntegration]
$thread = [BellumCivile.Behaviors.BellumIntegrationBehavior]
$Day = [TaleWorlds.CampaignSystem.CampaignTime]
$Day::CurrentDay = 18.25
Check (($api::GetNpcTreasonIntents($null).Count -eq 0)) 'null_realm_returns_empty_inventory'
Check (($api::GetNpcTreasonIntents($k).Count -eq 0)) 'empty_court_returns_empty_inventory'
$z = $api::TryStageNpcTreasonIntent($k, $r, $t, 'z-closed')
$a = $api::TryStageNpcTreasonIntent($k, $r, $t, 'a-attached')
Check ($z.Accepted -and $a.Accepted) 'native_stage_ticket_acceptance_unchanged'
$list = $api::GetNpcTreasonIntents($k)
Check ($list.Count -eq 2 -and $list[0].ExternalIntentId -eq 'a-attached' -and
    $list[1].ExternalIntentId -eq 'z-closed' -and
    $list[0].Status -eq 'staged_not_scheduled') 'exact_realm_inventory_ordinal_order_and_staged_state'
$otherRealm = [TaleWorlds.CampaignSystem.Kingdom]::new()
$otherRealm.StringId = 'other-realm'
Check (($api::GetNpcTreasonIntents($otherRealm).Count -eq 0)) 'other_realm_sees_no_foreign_ticket'
$agenda = [BellumCivile.CourtAgendaRecord]::new()
$agenda.Realm=$k; $agenda.Sponsor=$r
$agenda.State=[BellumCivile.CourtAgendaState]::NotProposed
$courtType::Current.AddAgendaForTest($agenda)
$attach = $courtType.GetMethod('TryAttachStagedNpcTreason', [Reflection.BindingFlags]'Instance, NonPublic')
Check ([bool]$attach.Invoke($courtType::Current,
    [object[]]@($agenda, [BellumCivile.CourtTermContext]::new($k)))) 'native_crown_assignment_retained'
$attached = $api::GetNpcTreasonIntents($k)[0]
Check ($attached.Status -eq 'court_announced' -and
    $attached.CourtAgendaId -eq $agenda.IntegrationId) 'inventory_uses_real_native_agenda_status_and_id'
$agenda.State=[BellumCivile.CourtAgendaState]::Deliberating
Check ($api::GetNpcTreasonIntents($k)[0].Status -eq 'court_deliberating') 'read_only_status_follows_native_voting_progress'
$Day::CurrentDay=19.25
[BellumCivile.BellumCivileOptions]::EnableAutomaticTreasonIndictments = $false
$review = $courtType.GetMethod('MaintainNpcTreasonLifecycle', [Reflection.BindingFlags]'Instance, NonPublic')
[void]$review.Invoke($courtType::Current, @())
$closed = $api::GetNpcTreasonIntents($k)[1]
Check ($closed.Status -eq 'cancelled_automatic_disabled' -and
    $api::GetNpcTreasonIntents($k)[0].Status -eq 'court_deliberating') 'terminal_tombstone_visible_without_touching_attached_agenda'
[BellumCivile.BellumCivileOptions]::EnableAutomaticTreasonIndictments = $true
$mapField = $courtType.GetField('_npcTreasonIntents', [Reflection.BindingFlags]'Instance, NonPublic')
$map = $mapField.GetValue($courtType::Current)
$map.Add('bad-corrupt', 'definitely-not-a-real-ticket')
$countBefore=$map.Count
Check (($api::GetNpcTreasonIntents($k).Count -eq 2 -and $map.Count -eq $countBefore)) 'corrupt_ticket_skipped_without_state_mutation'
$save = [TaleWorlds.CampaignSystem.FakeNpcCrownStore]::new()
$sync = $courtType.GetMethod('SyncNpcTreasonIntents', [Reflection.BindingFlags]'Instance, NonPublic')
[void]$sync.Invoke($courtType::Current, @($save))
$courtType::Current = $courtType::new()
$courtType::Current.AddAgendaForTest($agenda) # Mimic separate restored native agenda save payload.
$save.Writing = $false
[void]$sync.Invoke($courtType::Current, @($save))
$after = $api::GetNpcTreasonIntents($k)
Check ($after.Count -eq 2 -and $after[0].CourtAgendaId -eq $agenda.IntegrationId -and
    $after[0].Status -eq 'court_deliberating' -and
    $after[1].Status -eq 'cancelled_automatic_disabled') 'mock_save_reload_inventory_survives_with_exact_id_and_terminal_state'
$agenda.ObjectiveData.Kind='grant_fief'
Check ($api::GetNpcTreasonIntents($k)[0].Status -eq 'court_superseded') 'native_court_supersession_cannot_be_reported_as_completed_treason'
$agenda.ObjectiveData.Kind='treason'
$agenda.State=[BellumCivile.CourtAgendaState]::Passed
Check ($api::GetNpcTreasonIntents($k)[0].Status -eq 'court_passed') 'court_passed_reported_only_as_agenda_status_not_expulsion_claim'
$courtType::Current = $courtType::new()
$save.Writing=$false
[void]$sync.Invoke($courtType::Current, @($save))
Check ($api::GetNpcTreasonIntents($k)[0].Status -eq 'court_missing') 'absent_restored_agenda_reports_missing_not_success'
$thread::OnCampaignThread = $false
$threw = $false
try { [void]$api::GetNpcTreasonIntents($k) } catch { $threw = $true }
$thread::OnCampaignThread = $true
Check ($threw) 'public_inventory_requires_campaign_thread'
$courtType::Current = $null
Check (($api::GetNpcTreasonIntents($k).Count -eq 0)) 'missing_court_returns_empty_collection'
Write-Host 'STAGE11_NPC_CROWN_INVENTORY_PASS — isolated compiled mock; not real Bannerlord gameplay.'
