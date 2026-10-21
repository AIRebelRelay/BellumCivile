$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
function Source($path) { Get-Content -Raw -LiteralPath (Join-Path $root $path) }
function Check($value, $message) {
    if (!$value) { throw "FAIL STAGE6_NPC_CROWN $message" }
    Write-Host "PASS STAGE6_NPC_CROWN $message"
}

# The codec is genuinely compiled and exercised. It has no TaleWorlds dependency.
$types = @(Add-Type -Path (Join-Path $root 'NpcCrownTreasonIntentRecord.cs') -PassThru)
$codec = @($types | Where-Object { $_.FullName -eq 'BellumCivile.NpcTreasonIntentCodec' })[0]
if ($null -eq $codec) { throw 'Codec type was not compiled' }
$flags = [Reflection.BindingFlags]'NonPublic, Static'
$pack = $codec.GetMethod('Pack', $flags)
$read = $codec.GetMethod('TryRead', $flags)
$valid = $codec.GetMethod('ValidId', $flags)
Check ($valid.Invoke($null, @('abc-123', 128)) -eq $true -and
    $valid.Invoke($null, @("bad`nid", 128)) -eq $false -and
    $valid.Invoke($null, @(('x' * 129), 128)) -eq $false) 'intent_id_validation_rejects_controls_and_unbounded'
$encoded = $pack.Invoke($null, @('realm_1', 'clan_ruler', 'clan_target', [double]12.75))
$args = [object[]]@('intent-1', $encoded, $null)
$decoded = $read.Invoke($null, $args)
Check ($decoded -eq $true -and $args[2].RealmId -eq 'realm_1' -and
    $args[2].RulerClanId -eq 'clan_ruler' -and
    $args[2].TargetClanId -eq 'clan_target' -and
    $args[2].SubmittedDay -eq 12.75 -and
    $args[2].Status -eq 'staged_not_scheduled') 'codec_round_trip_ticket_is_not_filed'
$argsBad = [object[]]@('intent-1', ($encoded -replace 'staged_not_scheduled', 'completed'), $null)
Check ($read.Invoke($null, $argsBad) -eq $false) 'unknown_status_fails_closed'
$argsBad = [object[]]@('intent-1', "bad`nvalue", $null)
Check ($read.Invoke($null, $argsBad) -eq $false) 'invalid_save_payload_fails_closed'

$api = Source 'BellumIntegrationNpcCrown.cs'
$service = Source 'Behaviors/CourtNpcTreasonIntents.cs'
$court = Source 'Behaviors/CourtAgendaBehavior.cs'
$definer = Source 'BellumCivileSaveDefiner.cs'
$baseline = Source 'Tests/AiInfluenceNpcCrownBaseline.Tests.ps1'

Check ($api.Contains('BellumIntegrationBehavior.RequireCampaignThread();') -and
    $api.Contains('TryStageNpcTreasonIntent(') -and
    $api.Contains('GetNpcTreasonIntent(')) 'api_campaign_thread_guard_and_snapshot'
Check ($court.Contains('SyncNpcTreasonIntents(dataStore);') -and
    $service.Contains('BC_CourtNpcTreasonIntents_v1') -and
    $definer.Contains('ConstructContainerDefinition(typeof(Dictionary<string, string>))')) 'save_uses_existing_dictionary_registry'
Check ($service.Contains('ideology.CanRulerIndictClan(realm, targetClan, false, out reason, readOnly: true)') -and
    $service.Contains('BellumCivileOptions.EnableAutomaticTreasonIndictments')) 'preflight_read_only_and_automatic_toggle'
Check ($service.Contains('already_staged') -and
    $service.Contains('external_intent_id_collision') -and
    $service.Contains('corrupt_ticket') -and
    $service.Contains('MaxNpcTreasonIntents = 256') -and
    $service.Contains('MaxNpcTreasonPerRealm = 4')) 'replay_idempotence_collision_and_queue_bound'
Check ($service.Contains('rulerClan == Clan.PlayerClan') -and
    $service.Contains('!Eligible(targetClan, realm)') -and
    $service.Contains('decree_only_relationship')) 'npc_scope_target_and_decree_guards'
Check (!$service.Contains('_agendas.Add(') -and !$service.Contains('QueueExpulsionVote(') -and
    !$service.Contains('TryStartTreasonVote(') -and !$service.Contains('AdvanceExecutive(') -and
    !$api.Contains('TryStartTreasonVote(') -and
    !$court.Contains('ConsumeNpcTreasonIntent(')) 'staging_cannot_execute_or_schedule_court_motion'
Check ($baseline.Contains('direct_player_crown_can_file_immediately') -and
    $baseline.Contains('native_crown_priority_and_existing_agenda_protected')) 'neighboring_player_and_crown_baseline_retained'
Write-Host 'STAGE6_NPC_CROWN_SOURCE_AND_CODEC_PASS — full Bannerlord build/save/runtime still unverified.'
