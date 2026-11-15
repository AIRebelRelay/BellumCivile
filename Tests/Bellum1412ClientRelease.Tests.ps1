# Bellum 1.4.12b Stage 2 - client voluntary release and neighboring diplomacy regression contract.
# Static checks only. Native compilation, behavioral harness, and campaign save/load are separate gates.
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$paths = @{
  Release='Behaviors/ClientVoluntaryRelease.cs'
  Agreements='ClientReleaseAgreements.cs'
  Client='Behaviors/ClientKingdomBehavior.cs'
  Relations='Behaviors/DynamicRelationBehavior.cs'
  Memory='RelationMemoryService.cs'
  Strings='ModuleData/Languages/EN/strings.xml'
  Harness='Tests/SuccessionEngineHarness/ClientVoluntaryReleaseTests.cs'
  Runner='Tests/SuccessionEngineHarness/Program.cs'
}
$c = @{}
foreach ($name in $paths.Keys) {
  $path = Join-Path $root $paths[$name]
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "BELLUM1412_CLIENT_RELEASE FAIL missing_file=$path" }
  $c[$name] = [IO.File]::ReadAllText($path)
}
function Has([string]$source,[string]$fragment,[string]$name) {
  if (-not $source.Contains($fragment)) { throw "BELLUM1412_CLIENT_RELEASE FAIL $name" }
  "PASS BELLUM1412_CLIENT_RELEASE $name"
}
Has $c.Release 'internal const int VoluntaryReleaseGratitude = 40;' 'gratitude_40'
Has $c.Release 'internal const float VoluntaryReleaseMemoryYears = 15;' 'memory_15_years'
Has $c.Release 'if (!CanVoluntarilyRelease(offer, out reason)) return false;' 'recheck_at_confirmation'
Has $c.Release '!IsValidPermanentRealm(offer.Suzerain)' 'require_real_suzerain'
Has $c.Release '!IsValidPermanentRealm(offer.Client)' 'require_real_client'
Has $c.Release 'offer.Player != Hero.MainHero' 'player_only'
Has $c.Release 'offer.Suzerain.RulingClan != offer.Player.Clan' 'player_is_sovereign'
Has $c.Release 'offer.Client.RulingClan != offer.Recipient.Clan' 'recipient_is_ruler'
Has $c.Release 'offer.Client.IsAtWarWith(offer.Suzerain)' 'no_war_during_release'
Has $c.Release 'ClientReleaseAgreements.TryPrepare(offer.Suzerain, offer.Client, out var agreements)' 'prepare_before_commit'
Has $c.Release 'if (!_clients.Remove(offer.Record)) { agreements.Restore(); return; }' 'rollback_on_record_failure'
Has $c.Release 'RunDiplomaticSync(() =>' 'synchronized_diplomatic_changes'
Has $c.Release 'if (!committed) return false;' 'fail_closed'
Has $c.Release 'HasVoluntaryReleaseGratitude(offer.Player, offer.Recipient)' 'non_stacking_gratitude'
Has $c.Release 'AddVoluntaryReleaseDialogues(CampaignGameStarter starter)' 'player_dialogue_only'
Has $c.Release 'if (_releaseSucceeded) return;' 'confirmation_idempotent'
Has $c.Agreements 'AllianceCampaignBehavior' 'native_alliance_model'
Has $c.Agreements 'TradeAgreementsCampaignBehavior' 'native_trade_model'
Has $c.Agreements 'if (allianceIndex >= 0) return false;' 'reject_duplicate_alliances'
Has $c.Agreements 'if (tradeIndex >= 0) return false;' 'reject_duplicate_trade_pacts'
Has $c.Agreements 'oldEnd.ToDays > allianceEnd.ToDays ? oldEnd : allianceEnd' 'alliance_never_shortens'
Has $c.Agreements 'Kingdom1GoldGainedTotal = oldTrade.Kingdom1GoldGainedTotal' 'trade_history_retained'
Has $c.Agreements 'Kingdom2GoldGainedTotal = oldTrade.Kingdom2GoldGainedTotal' 'trade_history_other_party_retained'
Has $c.Agreements 'internal void Restore()' 'rollback_available'
Has $c.Client 'if (starter != null) AddVoluntaryReleaseDialogues(starter);' 'dialogue_registered_session_launch'
Has $c.Client 'ReconcileClientKingdoms();' 'existing_client_reconciliation'
Has $c.Client 'ReconcileDiplomacyNonAggressionPacts();' 'existing_diplomatic_reconciliation'
Has $c.Relations 'internal bool HasVoluntaryReleaseGratitude(Hero firstHero, Hero secondHero)' 'memory_guard_exists'
Has $c.Relations 'm.SourceId == RelationMemorySources.GrantedRealmIndependence && !m.IsExpired(CurrentDay)' 'memory_guard_is_live_only'
Has $c.Relations 'internal int LimitClientGrantGain(Hero firstHero, Hero secondHero)' 'existing_client_gratitude_unmodified'
Has $c.Memory 'public const string GrantedRealmIndependence = "granted_realm_independence";' 'additive_memory_source'
Has $c.Memory 'case GrantedRealmIndependence:' 'localized_memory_case'
Has $c.Harness 'Conversion preserves both unpaid trade balances and lifetime income counters' 'trade_regression'
Has $c.Harness 'Existing call-to-war obligations survive without restarting or duplicating pacts' 'call_to_war_regression'
Has $c.Harness 'Releasing one client leaves all other clients and their pact dates untouched' 'other_clients_regression'
Has $c.Harness 'Bellum and native save-data roundtrips retain independence and converted pact dates' 'save_reload_regression'
Has $c.Harness 'Duplicate confirmation neither repeats rewards nor replaces success with a failure message' 'idempotent_confirmation_regression'
Has $c.Runner '--client-voluntary-release' 'targeted_harness_flag'
Has $c.Runner 'ClientVoluntaryReleaseTests.Run(Check);' 'harness_executed'
[xml]$strings = $c.Strings
foreach ($id in @('BC_ClientRelease_Open','BC_ClientRelease_Question','BC_ClientRelease_Proposal','BC_ClientRelease_Response',
  'BC_ClientRelease_Confirm','BC_ClientRelease_Cancel','BC_ClientRelease_Thanks','BC_ClientRelease_Changed',
  'BC_ClientRelease_AgreementsUnavailable','BC_ClientRelease_Failure','BC_ClientRelease_Hint',
  'BC_RelationMemory_GrantedRealmIndependence')) {
  $count = @($strings.base.strings.string | Where-Object id -eq $id).Count
  if ($count -ne 1) { throw "BELLUM1412_CLIENT_RELEASE FAIL localization_$id count=$count" }
  "PASS BELLUM1412_CLIENT_RELEASE localization_$id"
}
'BELLUM1412_CLIENT_RELEASE SOURCE_PASS; harness_and_gameplay=NOT_RUN'
