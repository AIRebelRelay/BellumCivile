# Stage 3B - strict native grant-fief confirmation callback ABI contract.
# Source checks only. See compiled native hook tests for 1.5.7 runtime verification.
$ErrorActionPreference='Stop'
$root=Split-Path -Parent $PSScriptRoot
$source=[IO.File]::ReadAllText((Join-Path $root 'Patches/GrantFiefDeliberationPatch.cs'))
$runtime=[IO.File]::ReadAllText((Join-Path $root 'Tests/SuccessionEngineHarness/GrantFiefClosureTests.cs'))
$program=[IO.File]::ReadAllText((Join-Path $root 'Tests/SuccessionEngineHarness/Program.cs'))
$queue=[IO.File]::ReadAllText((Join-Path $root 'Behaviors/FiefDeliberationBehavior.cs'))
function Check([bool]$ok,[string]$name){if(!$ok){throw "BELLUM157_GRANT_FIEF FAIL $name"}; "PASS BELLUM157_GRANT_FIEF $name"}
Check ($source.Contains('typeof(KingdomManagementVM).GetNestedTypes(BindingFlags.NonPublic)')) 'search_native_nested_closures'
Check ($source.Contains('.SelectMany(AccessTools.GetDeclaredMethods)')) 'search_nested_declared_methods'
Check ($source.Contains('.Single(m => m.Name == "<OnGrantFief>b__0" && m.GetParameters().Length == 0);')) 'unique_arity_checked_callback'
Check (!$source.Contains('DisplayClass21_0')) 'no_hardcoded_native_compiler_class_index'
Check ($source.Contains('SettlementField = AccessTools.Field(callback.DeclaringType, "settlement");')) 'reflect_settlement_field_from_callback'
Check ($source.Contains('ViewModelField = AccessTools.Field(callback.DeclaringType, "<>4__this");')) 'reflect_native_viewmodel_field'
Check ($source.Contains('SettlementField?.FieldType != typeof(Settlement) || ViewModelField?.FieldType != typeof(KingdomManagementVM)')) 'fail_closed_on_native_capture_layout_change'
Check ($source.Contains('throw new InvalidOperationException("Unsupported grant-fief confirmation closure.")')) 'unsupported_closure_is_explicit_error'
Check ($source.Contains('if (__instance == null || SettlementField == null || ViewModelField == null)')) 'null_instance_defers_to_native'
Check ($source.Contains('if (deliberation == null)')) 'no_campaign_behavior_defers_to_native'
Check ($source.Contains('if (vmKingdom == null || vmKingdom != playerKingdom)')) 'other_kingdom_keeps_native_action'
Check ($source.Contains('if (deliberation.HasPendingFiefVoteForSettlement(playerKingdom, settlement))')) 'existing_pending_vote_handled_once'
Check ($source.Contains('if (!deliberation.QueueRelinquishedSettlementVote(settlement))')) 'queue_failure_allows_native_fallback'
Check ($source.Contains('BlockVanillaFiefVotePatch.AllowNextImmediatePlayerClaimantVote();')) 'native_fallback_sponsorship_preserved'
Check ($source.Contains('RefreshSettlementMethod?.Invoke(kingdomManagementVm, null);')) 'refresh_after_custom_processing'
Check ($queue.Contains('public bool QueueRelinquishedSettlementVote(Settlement settlement)')) 'shared_queue_api_untouched'
Check ($runtime.Contains('GetPatchInfo(callback)')) 'runtime_confirms_patch_on_resolved_native_callback'
Check ($runtime.Contains('GrantFiefDeliberationPatch.Prefix(null)')) 'runtime_null_instance_fallback_test'
Check ($program.Contains('GrantFiefClosureTests.Run(Check);')) 'focused_harness_route_installed'
Check ($program.Contains('FiefRedistributionTests.Run(Check);')) 'existing_fief_redist_test_preserved'
'BELLUM157_GRANT_FIEF SOURCE_PASS; native_harmony_runtime_and_live_campaign=NOT_RUN'
