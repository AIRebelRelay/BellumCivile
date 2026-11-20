# Stage 3A: Bannerlord 1.5.7 settlement-rescue/daughter quest native event target contract.
# Source checks precede production changes; native Harmony composition still required.
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$patch = [IO.File]::ReadAllText((Join-Path $root 'Patches/SettlementRescueRelationMemoryPatch.cs'))
$test = [IO.File]::ReadAllText((Join-Path $root 'Tests/SuccessionEngineHarness/SettlementCauseLabelTests.cs'))
$program = [IO.File]::ReadAllText((Join-Path $root 'Tests/SuccessionEngineHarness/Program.cs'))
function Check([bool]$condition,[string]$case) {
    if (!$condition) { throw "BELLUM157_SETTLEMENT_ABI FAIL $case" }
    "PASS BELLUM157_SETTLEMENT_ABI $case"
}
Check ($patch.Contains('[HarmonyPatch(typeof(CharacterRelationCampaignBehavior), "OnMapEventEnded")]')) 'native_map_event_target'
Check (!$patch.Contains('[HarmonyPatch(typeof(CharacterRelationCampaignBehavior), "MapEventEnded")]')) 'legacy_map_event_target_absent'
Check ($patch.Contains('[HarmonyPatch(typeof(SandBox.Issues.NotableWantsDaughterFoundIssueBehavior.NotableWantsDaughterFoundIssueQuest), "OnMissionEnded")]')) 'native_daughter_quest_target'
Check (!$patch.Contains('ApplyDeliveryFailedDueToDuelLostConsequences')) 'legacy_daughter_quest_target_absent'
Check ($patch.Contains('[HarmonyPatch(typeof(SiegeAftermathCampaignBehavior), "OnSiegeAftermathApplied")]')) 'unaffected_siege_hook_preserved'
Check ($patch.Contains('new[] { null, null, RelationMemorySources.ProtectedSettlement, RelationMemorySources.ProtectedVillagers,')) 'battle_perk_reward_order_preserved'
Check ($patch.Contains('RelationMemorySources.ProtectedVillagers, RelationMemorySources.ProtectedCaravan }, new string[6]')) 'six_native_reward_slots_preserved'
Check ($patch.Contains('new string[1], new[] { RelationMemorySources.InterferedInAffairs }')) 'daughter_negative_label_preserved'
Check ($patch.Contains('if (index != positives.Length) throw new InvalidOperationException')) 'unexpected_native_call_count_fails_closed'
Check ($patch.Contains('if (positives.Length != negatives.Length) throw new ArgumentException')) 'relation_label_pair_count_guard'
Check ($patch.Contains('using (RelationMemoryService.BeginNativeLabels(positive, negative))')) 'labels_scoped_to_audited_native_call'
Check ($test.Contains('typeof(CharacterRelationCampaignBehavior), "OnMapEventEnded"')) 'harness_tracks_native_map_event'
Check ($test.Contains('Native event patch attaches: ')) 'all_three_harmony_targets_covered'
Check ($test.Contains('Battle perks remain native while exactly four rescue reward calls are labeled')) 'battle_perks_remain_vanilla'
Check ($test.Contains('Cause wrapper forwards native arguments unchanged, once')) 'relation_arguments_preserved'
Check ($test.Contains('Existing explicit memory source retains priority')) 'explicit_memories_override_labels'
Check ($test.Contains('Cause scope restores after native exception')) 'exception_restores_context'
Check ($test.Contains('Changed native call count fails rather than silently mislabeling rewards')) 'reject_native_IL_drift'
Check ($program.Contains('else if (args.Contains("--settlement-cause-labels"))')) 'focused_harness_route'
Check ($program.Contains('SettlementCauseLabelTests.Run(Check);')) 'existing_default_harness_test_retained'
'BELLUM157_SETTLEMENT_ABI SOURCE_PASS; native_1.5.7_harmony_runtime=NOT_RUN'
