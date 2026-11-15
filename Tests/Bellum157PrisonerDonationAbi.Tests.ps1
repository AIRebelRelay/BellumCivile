# Stage 2C: Bannerlord 1.5.7 native relation action ABI contract.
# Static check only; native-IL composition is exercised by RelationIdentityCacheTests.
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$donation = [IO.File]::ReadAllText((Join-Path $root 'Patches/PrisonerDonationRelationMemoryPatch.cs'))
$identity = [IO.File]::ReadAllText((Join-Path $root 'Patches/PersonalRelationIdentityPatch.cs'))
$harness = [IO.File]::ReadAllText((Join-Path $root 'Tests/SuccessionEngineHarness/RelationIdentityCacheTests.cs'))
$relation = [IO.File]::ReadAllText((Join-Path $root 'Behaviors/DynamicRelationBehavior.cs'))
$diplomacy = [IO.File]::ReadAllText((Join-Path $root 'CivilWarDiplomacyModel.cs'))
function Check([bool]$ok,[string]$case) {
    if (-not $ok) { throw "BELLUM157_DONATION_ABI FAIL $case" }
    "PASS BELLUM157_DONATION_ABI $case"
}
Check ($donation.Contains('using TaleWorlds.CampaignSystem.ComponentInterfaces;')) 'beta_diplomacy_model_import'
Check ($donation.Contains('var effectiveChange = AccessTools.Method(typeof(DiplomacyModel), nameof(DiplomacyModel.GetEffectiveRelationChange));')) 'beta_effective_relation_hook'
Check ($donation.Contains('if (instruction.Calls(effectiveChange))')) 'beta_call_found_once_by_transpiler'
Check (!$donation.Contains('MBRandom.RoundRandomized')) 'stale_round_randomized_hook_absent'
Check ($donation.Contains('if (matches != 1)')) 'fail_closed_on_unexpected_il'
Check ($donation.Contains('yield return new CodeInstruction(OpCodes.Ldarg_0);')) 'original_first_hero_forwarded'
Check ($donation.Contains('yield return new CodeInstruction(OpCodes.Ldarg_1);')) 'original_second_hero_forwarded'
Check ($donation.Contains('yield return new CodeInstruction(OpCodes.Call, limiter);')) 'limiter_invoked_once'
Check ($donation.Contains('gain <= 0 || RelationMemoryService.CurrentDescriptor?.SourceId != RelationMemorySources.DeliveredNoblePrisoners')) 'only_positive_donation_reduced'
Check ($donation.Contains('DynamicRelationBehavior.Instance == null || !BellumCivileOptions.EnableDynamicRelationDrift')) 'disabled_mode_untouched'
Check ($donation.Contains('Campaign.Current.Models.DiplomacyModel.GetHeroesForEffectiveRelation(firstHero, secondHero,')) 'house_relations_resolve_effective_pair'
Check ($donation.Contains('DynamicRelationBehavior.Instance.LimitPrisonerDonationGain(effectiveFirst, effectiveSecond, gain)')) 'existing_20_point_donation_cap_retained'
Check ($donation.Contains('RelationMemoryService.Begin(RelationMemorySources.DeliveredNoblePrisoners,')) 'donation_event_context_retained'
Check ($donation.Contains('private static Exception Finalizer(Exception __exception, IDisposable __state)')) 'donation_memory_context_exception_cleanup'
Check ($identity.Contains('var original = AccessTools.Method(typeof(DiplomacyModel), nameof(DiplomacyModel.GetHeroesForEffectiveRelation));')) 'personal_identity_il_interop_retained'
Check ($identity.Contains('model.GetHeroesForEffectiveRelation(first, second, out effectiveFirst, out effectiveSecond);')) 'house_identity_routing_retained'
Check ($harness.Contains('harmony.Patch(native, transpiler: new HarmonyMethod(PatchType, "Transpiler"));')) 'identity_transpiler_runtime_compose_test'
Check ($harness.Contains('harmony.Patch(native, transpiler: new HarmonyMethod(donationPatch, "Transpiler"));')) 'donation_transpiler_runtime_compose_test'
Check ($harness.Contains('new[] { "GetEffectiveRelationChange", "SetPersonalRelation", "OnHeroRelationChanged" }')) 'beta_native_side_effect_regression'
Check ($harness.Contains('Personal identity patch composes with existing prisoner-donation cap')) 'both_transpilers_together'
Check ($relation.Contains('return Math.Min(proposedGain, Math.Max(0, BellumCivileConstants.PrisonerDonationRelationCap - existing));')) 'donation_cap_effect_not_changed'
Check ($diplomacy.Contains('public override int GetEffectiveRelationChange(Hero hero1, Hero hero2, int relationChange)')) 'diplomacy_wrapper_still_delegates_native_beta_method'
'BELLUM157_DONATION_ABI SOURCE_PASS; runtime_assembly_and_gameplay=NOT_RUN'
