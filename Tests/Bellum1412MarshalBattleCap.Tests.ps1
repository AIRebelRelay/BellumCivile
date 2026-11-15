# Bellum 1.4.12b Stage 1: source contract for Marshal per-battle casualty controversy.
# Does not replace native 1.5.7 build, behavioral harness or live campaign verification.
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$files = @{
  Controversy = 'Behaviors/ControversyBehavior.cs'
  Council = 'Behaviors/PrivyCouncilBehavior.cs'
  Context = 'Patches/MarshalBattleCasualtyContext.cs'
  Harness = 'Tests/SuccessionEngineHarness/MarshalBattleControversyTests.cs'
  Runner = 'Tests/SuccessionEngineHarness/Program.cs'
  Options = 'BellumCivileOptions.cs'
}
$source = @{}
foreach ($entry in $files.GetEnumerator()) {
  $name = Join-Path $root $entry.Value
  if (-not (Test-Path -LiteralPath $name -PathType Leaf)) { throw "BELLUM1412_MARSHAL FAIL missing_source=$name" }
  $source[$entry.Key] = [IO.File]::ReadAllText($name)
}
function Assert-Has([string]$body, [string]$fragment, [string]$caseName) {
  if (-not $body.Contains($fragment)) { throw "BELLUM1412_MARSHAL FAIL $caseName" }
  "PASS BELLUM1412_MARSHAL $caseName"
}
$c = $source.Controversy
$p = $source.Council
$x = $source.Context
$h = $source.Harness
Assert-Has $c 'internal const float BattleCasualtyControversyCap = 15f;' 'cap_15_per_battle'
Assert-Has $c 'dataStore.SyncData("BellumCivile_BattleCasualtyControversy", ref _battleCasualtyIncreases);' 'budget_persisted'
Assert-Has $c 'if (_battleCasualtyIncreases == null) _battleCasualtyIncreases = new Dictionary<string, float>();' 'legacy_saves_safe'
Assert-Has $c 'MapEvent battle = MarshalBattleCasualtyContext.Current ?? prisoner.PartyBelongedTo?.MapEvent ?? captor?.MapEvent;' 'captured_lord_battle_context'
Assert-Has $c 'AddBattleCasualtyControversy(prisoner.Clan.Kingdom, 3, battle);' 'captured_lord_existing_weight_3'
Assert-Has $c 'AddBattleCasualtyControversy(victim.Clan.Kingdom, 5,' 'battle_death_existing_weight_5'
Assert-Has $c 'else if (victim.Clan.Kingdom != null) AddControversy(victim.Clan.Kingdom, 5);' 'execution_still_uncapped'
Assert-Has $c 'if (battle == null) { AddControversy(kingdom, amount); return; }' 'unknown_battle_legacy_path'
Assert-Has $c 'string key = BattleKeyPrefix(battle) + kingdom.StringId;' 'per_battle_per_realm_key'
Assert-Has $c 'float remaining = Math.Max(0f, BattleCasualtyControversyCap - used);' 'budget_remaining'
Assert-Has $c 'council.AddControversyWithLimit(kingdom, PrivyCouncilOffice.Marshal, amount, GetCouncilReason(PrivyCouncilOffice.Marshal), remaining)' 'scaled_limit_in_council'
Assert-Has $c 'if (captor?.MapFaction is Kingdom captorKingdom) AddControversy(captorKingdom, -3);' 'captor_reward_retained'
Assert-Has $c 'if (killer?.Clan?.Kingdom != null) AddControversy(killer.Clan.Kingdom, -5);' 'killer_reward_retained'
Assert-Has $c 'PruneBattleCasualtyIncreases();' 'completed_battle_pruning'
Assert-Has $c 'if (PlayerEncounter.Battle != null) live.Add(BattleKeyPrefix(PlayerEncounter.Battle));' 'pending_player_encounter_retained'
Assert-Has $p 'AddControversyWithLimit(kingdom, office, amount, reason, float.MaxValue);' 'unlimited_existing_callers'
Assert-Has $p 'internal float AddControversyWithLimit(Kingdom kingdom, PrivyCouncilOffice office, float amount, string reason, float maximumIncrease)' 'new_bounded_overload'
Assert-Has $p 'float scaledAmount = amount;' 'competence_scaling_retained'
Assert-Has $p 'if (scaledAmount > 0f) scaledAmount = Math.Min(scaledAmount, Math.Max(0f, maximumIncrease));' 'cap_applies_after_scaling_only_to_positive'
Assert-Has $p 'return record.Controversy - before;' 'actual_applied_amount_receipt'
Assert-Has $x '[ThreadStatic] private static MapEvent _current;' 'no_cross_thread_battle_context'
Assert-Has $x 'internal static void Restore(MapEvent previous) => _current = previous;' 'nested_context_restored'
Assert-Has $x '[HarmonyPatch(typeof(TakePrisonerAction), "ApplyInternal")]' 'native_capture_hook'
Assert-Has $x '[HarmonyPatch(typeof(KillCharacterAction), "ApplyInternal")]' 'native_death_hook'
Assert-Has $x '[HarmonyPatch(typeof(MapEventSide), "HandleMapEventEndForPartyInternal")]' 'deferred_death_hook'
Assert-Has $x 'private static Exception Finalizer(Exception __exception, MapEvent __state)' 'exception_safe_cleanup'
Assert-Has $h 'Three captures and one battle death retain their ordinary fourteen-point cost' 'baseline_14_test'
Assert-Has $h 'Captures and deaths share one fifteen-point allowance' 'shared_budget_test'
Assert-Has $h 'A replacement marshal starts clean without resetting the realm' 'marshal_replacement_test'
Assert-Has $h 'Interleaved battles retain separate allowances' 'separate_battles_test'
Assert-Has $h 'Final increases stay capped after competence scaling:' 'competence_test'
Assert-Has $h 'Save/load retains the allowance across a new native battle instance' 'save_reload_test'
Assert-Has $h 'Exceptions propagate while restoring the native action context' 'exception_cleanup_test'
Assert-Has $h 'Raids, caravans, siege losses and ongoing pressures do not consume the allowance' 'neighbor_events_test'
Assert-Has $h 'Legacy controversy routing also respects the shared battle cap' 'legacy_council_fallback_test'
Assert-Has $source.Runner 'MarshalBattleControversyTests.Run(Check);' 'harness_entrypoint'
Assert-Has $source.Runner '--marshal-battle-cap' 'harness_flag'
Assert-Has $source.Options 'public static bool EnableWarPeaceLogicRevamp' 'unrelated_settings_retained'
'BELLUM1412_MARSHAL SOURCE_PASS; harness_build_runtime_gameplay=NOT_RUN'
