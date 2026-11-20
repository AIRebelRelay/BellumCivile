# Bellum 1.4.12b / Bannerlord 1.5.7 Stage 2D
# Native execution event moved to ExecutionCampaignBehavior. Contract first; runtime test remains mandatory.
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$patch = [IO.File]::ReadAllText((Join-Path $root 'Patches/DeathRelationMemoryPatch.cs'))
$memory = [IO.File]::ReadAllText((Join-Path $root 'Behaviors/DynamicRelationBehavior.cs'))
$test = [IO.File]::ReadAllText((Join-Path $root 'Tests/SuccessionEngineHarness/PersonalBereavementTests.cs'))
$runner = [IO.File]::ReadAllText((Join-Path $root 'Tests/SuccessionEngineHarness/Program.cs'))
$startup = [IO.File]::ReadAllText((Join-Path $root 'SubModule.cs'))
function Check([bool]$ok,[string]$case) {
  if (-not $ok) { throw "BELLUM157_EXECUTION_CONTEXT FAIL case=$case" }
  "PASS BELLUM157_EXECUTION_CONTEXT $case"
}
Check ($patch.Contains('[HarmonyPatch(typeof(ExecutionCampaignBehavior), "OnHeroKilled")]')) 'native_execution_behavior_target'
Check (!$patch.Contains('[HarmonyPatch(typeof(CharacterRelationCampaignBehavior), "OnHeroKilled")]')) 'old_death_relation_hook_absent'
Check ($patch.Contains('internal static class NativeExecutionRelationContextPatch')) 'existing_execution_context_patch'
Check ($patch.Contains('DynamicRelationBehavior.Instance?.BeginNativeExecutionRelations()')) 'execution_enters_native_relation_scope'
Check ($patch.Contains('private static void Postfix(IDisposable __state) => __state?.Dispose();')) 'execution_scope_disposed_on_success'
Check ($patch.Contains('private static Exception Finalizer(Exception __exception, IDisposable __state)')) 'execution_scope_disposed_on_exception'
Check ($patch.Contains('[HarmonyPatch(typeof(KillCharacterAction), "ApplyInternal")]')) 'nested_kill_action_context_preserved'
Check ($patch.Contains('DynamicRelationBehavior.Instance?.PreserveDeathContext()')) 'nested_death_snapshot_preserved'
Check ($patch.Contains('[HarmonyPatch(typeof(CampaignEventDispatcher), "OnHeroKilled")]')) 'death_completion_dispatch_preserved'
Check ($patch.Contains('DynamicRelationBehavior.Instance?.CompleteDeathMemories(victim, killer, detail)')) 'death_memories_completed_after_subscribers'
Check ($memory.Contains('internal IDisposable BeginNativeExecutionRelations()')) 'scope_provider_retained'
Check ($memory.Contains('if (!_handlingNativeExecutionRelations || RelationMemoryService.CurrentDescriptor != null) return false;')) 'explicit_other_sources_untouched'
Check ($test.Contains('Death lifecycle hook attaches to native assembly: ')) 'three_native_hooks_tested_by_harmony'
Check ($test.Contains('Native close-family penalty is replaced until death dispatch completes')) 'native_double_penalty_prevention_test'
Check ($test.Contains('Family and house reactions each count once')) 'no_duplicate_death_grief'
Check ($test.Contains('Nested natural death does not inherit outer suppression')) 'non_execution_death_preserved'
Check ($test.Contains('Non-native reactions during death dispatch are not suppressed')) 'unrelated_relation_changes_preserved'
Check ($test.Contains('Death action finalizer restores prior context and propagates exceptions')) 'failed_death_restores_context'
Check ($test.Contains('Personal/house exclusion survives behavior save/load')) 'save_load_grief_preserved'
Check ($runner.Contains('PersonalBereavementTests.Run(Check);')) 'behavior_harness_retained'
Check ($startup.Contains('_harmony.CreateClassProcessor(type).Patch();')) 'startup_patch_registration_retained'
'BELLUM157_EXECUTION_CONTEXT SOURCE_PASS; native_harmony_runtime_and_gameplay=NOT_RUN'
