$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
function Check($ok, $name) {
    if (-not $ok) { throw "FAIL STAGE6_NPC_CROWN_RUNTIME $name" }
    Write-Host "PASS STAGE6_NPC_CROWN_RUNTIME $name"
}
$sourceFiles = @(
    'NpcCrownTreasonIntentRecord.cs',
    'Behaviors/CourtNpcTreasonIntents.cs',
    'Behaviors/CourtNpcTreasonAssignment.cs',
    'BellumIntegrationNpcCrown.cs',
    'Tests/AiInfluenceNpcCrownStage6.Stubs.cs',
    'Tests/AiInfluenceNpcCrownStage7.Stubs.cs'
)
$paths = @($sourceFiles | ForEach-Object { Join-Path $root $_ })
Add-Type -Path $paths -ErrorAction Stop

$kingdom = [TaleWorlds.CampaignSystem.Kingdom]::new()
$kingdom.StringId = 'realm_1'
$ruler = [TaleWorlds.CampaignSystem.Clan]::new()
$ruler.StringId = 'ruler_1'; $ruler.Kingdom = $kingdom
$ruler.Leader = [TaleWorlds.CampaignSystem.Hero]::new()
$target = [TaleWorlds.CampaignSystem.Clan]::new()
$target.StringId = 'target_1'; $target.Kingdom = $kingdom
$target.Leader = [TaleWorlds.CampaignSystem.Hero]::new()
$target.Leader.Relation = -75
$kingdom.RulingClan = $ruler
$player = [TaleWorlds.CampaignSystem.Clan]::new()
$player.StringId = 'player'
[TaleWorlds.CampaignSystem.Clan]::PlayerClan = $player
$ideology = [BellumCivile.Behaviors.IdeologyBehavior]::new()
$campaign = [TaleWorlds.CampaignSystem.Campaign]::new()
$campaign.Ideology = $ideology
[TaleWorlds.CampaignSystem.Campaign]::Current = $campaign
$CourtType = [BellumCivile.Behaviors.CourtAgendaBehavior]
$CourtType::Current = $CourtType::new()
$api = [BellumCivile.BellumIntegration]

$t1 = $api::TryStageNpcTreasonIntent($kingdom, $ruler, $target, 'ai-1')
Check ($t1.Accepted -and $t1.Reason -eq 'staged_not_scheduled' -and
    $t1.Intent.Status -eq 'staged_not_scheduled' -and $ideology.WasReadOnly -and
    $t1.Intent.TargetClanId -eq 'target_1') 'valid_npc_stage_no_execution_and_readonly_gate'

$t2 = $api::TryStageNpcTreasonIntent($kingdom, $ruler, $target, 'ai-1')
Check ($t2.Accepted -and $t2.Reason -eq 'already_staged' -and
    $t2.Intent.SubmittedDay -eq $t1.Intent.SubmittedDay) 'same_exact_intent_replay_idempotent'

$other = [TaleWorlds.CampaignSystem.Clan]::new()
$other.StringId = 'target_2'; $other.Kingdom = $kingdom
$other.Leader = [TaleWorlds.CampaignSystem.Hero]::new()
$other.Leader.Relation = -75
$collision = $api::TryStageNpcTreasonIntent($kingdom, $ruler, $other, 'ai-1')
Check (!$collision.Accepted -and $collision.Reason -eq 'external_intent_id_collision') 'different_target_same_id_rejected'

$save = [TaleWorlds.CampaignSystem.FakeNpcCrownStore]::new()
$sync = $CourtType.GetMethod('SyncNpcTreasonIntents',
    [Reflection.BindingFlags]'Instance, NonPublic')
[void]$sync.Invoke($CourtType::Current, @($save))
Check ($save.Saved.ContainsKey('BC_CourtNpcTreasonIntents_v1') -and
    $save.Saved.ContainsKey('BC_CourtNpcTreasonAgendaIds_v1') -and
    $save.Serialized.Count -eq 1) 'ticket_serialized_under_new_registered_dictionary_key'
$CourtType::Current = $CourtType::new()
$save.Writing = $false
[void]$sync.Invoke($CourtType::Current, @($save))
$restored = $api::GetNpcTreasonIntent($kingdom, 'ai-1')
Check ($restored -ne $null -and $restored.TargetClanId -eq 'target_1' -and
    $restored.SubmittedDay -eq $t1.Intent.SubmittedDay) 'ticket_persists_exactly_across_reload'
$replay = $api::TryStageNpcTreasonIntent($kingdom, $ruler, $target, 'ai-1')
Check ($replay.Accepted -and $replay.Reason -eq 'already_staged') 'post_reload_replay_is_idempotent'

[BellumCivile.BellumCivileOptions]::EnableAutomaticTreasonIndictments = $false
$disabled = $api::TryStageNpcTreasonIntent($kingdom, $ruler, $other, 'ai-disabled')
Check (!$disabled.Accepted -and $disabled.Reason -eq 'automatic_treason_disabled') 'bellum_toggle_blocks_new_intent'
[BellumCivile.BellumCivileOptions]::EnableAutomaticTreasonIndictments = $true

$kingdom.RulingClan = $player
$player.Kingdom = $kingdom
$player.Leader = [TaleWorlds.CampaignSystem.Hero]::new()
$p = $api::TryStageNpcTreasonIntent($kingdom, $player, $target, 'ai-player')
Check (!$p.Accepted -and $p.Reason -eq 'npc_ruler_required') 'player_ruler_rejected'
$kingdom.RulingClan = $ruler

$target.Leader.Relation = -100
$d = $api::TryStageNpcTreasonIntent($kingdom, $ruler, $target, 'ai-decree')
Check (!$d.Accepted -and $d.Reason -eq 'decree_only_relationship') 'decree_scope_not_silently_escalated'
$target.Leader.Relation = -75

$ideology.Eligible = $false
$rejected = $api::TryStageNpcTreasonIntent($kingdom, $ruler, $other, 'ai-rejected')
Check (!$rejected.Accepted -and $rejected.Reason -eq 'bellum_preflight_rejected' -and
    $ideology.WasReadOnly) 'ideology_preflight_refusal_no_mutation'
$ideology.Eligible = $true

[BellumCivile.Behaviors.BellumIntegrationBehavior]::OnCampaignThread = $false
$threadRejected = $false
try { [void]$api::TryStageNpcTreasonIntent($kingdom, $ruler, $target, 'ai-thread') }
catch { $threadRejected = $true }
[BellumCivile.Behaviors.BellumIntegrationBehavior]::OnCampaignThread = $true
Check ($threadRejected) 'off_campaign_thread_rejected'

$filled = 1
foreach ($id in @('ai-2','ai-3','ai-4')) {
    $next = $api::TryStageNpcTreasonIntent($kingdom, $ruler, $other, $id)
    if ($next.Accepted) { $filled++ }
}
$overflow = $api::TryStageNpcTreasonIntent($kingdom, $ruler, $other, 'ai-overflow')
Check ($filled -eq 4 -and !$overflow.Accepted -and
    $overflow.Reason -eq 'realm_intent_capacity_reached') 'realm_capacity_bounded_four_tickets'
Check ([BellumCivile.BellumCivileLogger]::Lines.Count -eq 4 -and
    [BellumCivile.BellumCivileLogger]::Lines[0].Contains('state_changes=false')) 'no_native_court_action_in_runtime_stub'

Write-Host 'STAGE6_NPC_CROWN_RUNTIME_PASS — mock campaign compiled; full Bannerlord build and real save still unverified.'
