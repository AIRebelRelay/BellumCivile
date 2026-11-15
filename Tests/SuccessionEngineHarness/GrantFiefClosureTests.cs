using System;
using System.Linq;
using System.Reflection;
using BellumCivile.Patches;
using HarmonyLib;
using TaleWorlds.CampaignSystem.Settlements;
using TaleWorlds.CampaignSystem.ViewModelCollection.KingdomManagement;

// Tests the exact native callback ABI and Harmony attachment; no campaign is needed.
internal static class GrantFiefClosureTests
{
    internal static void Run(Action<bool, string> check)
    {
        Type patchType = typeof(GrantFiefDeliberationPatch);
        MethodInfo targetMethod = AccessTools.Method(patchType, "TargetMethod");
        check(targetMethod != null, "Grant-fief patch exposes a native target resolver");
        MethodBase callback = (MethodBase)targetMethod.Invoke(null, null);
        check(callback != null && callback.DeclaringType != null
            && typeof(KingdomManagementVM).GetNestedTypes(BindingFlags.NonPublic).Contains(callback.DeclaringType),
            "Grant-fief target is a native KingdomManagementVM nested callback");
        var matches = typeof(KingdomManagementVM).GetNestedTypes(BindingFlags.NonPublic)
            .SelectMany(AccessTools.GetDeclaredMethods)
            .Where(m => m.Name == "<OnGrantFief>b__0" && m.GetParameters().Length == 0).ToList();
        check(matches.Count == 1 && matches[0] == callback,
            "Native grant-fief confirmation callback matches uniquely without compiler closure number");

        var settlement = (FieldInfo)AccessTools.Field(patchType, "SettlementField").GetValue(null);
        var viewModel = (FieldInfo)AccessTools.Field(patchType, "ViewModelField").GetValue(null);
        check(settlement != null && settlement.DeclaringType == callback.DeclaringType
            && settlement.FieldType == typeof(Settlement), "Captured settlement field is the native settlement");
        check(viewModel != null && viewModel.DeclaringType == callback.DeclaringType
            && viewModel.FieldType == typeof(KingdomManagementVM), "Captured view-model field is the native kingdom management VM");

        var onGranted = (MethodInfo)AccessTools.Field(patchType, "RefreshSettlementMethod").GetValue(null);
        var kingdom = (MethodInfo)AccessTools.Field(patchType, "GetKingdomMethod").GetValue(null);
        check(onGranted != null && kingdom != null, "Existing refresh and kingdom guard native methods remain available");
        check(GrantFiefDeliberationPatch.Prefix(null), "Absent native callback instance defers to vanilla");

        var harmony = new Harmony("bellum.tests.grant_fief_closure_157");
        try
        {
            var patched = harmony.CreateClassProcessor(patchType).Patch();
            check(patched.Count == 1 && patched[0] != null,
                "Grant-fief Harmony class attaches to exactly the resolved native confirmation callback");
            var installed = Harmony.GetPatchInfo(callback);
            check(installed != null && installed.Prefixes.Any(p => p.owner == harmony.Id),
                "Grant-fief Harmony prefix is registered on the native callback");
            check(GrantFiefDeliberationPatch.Prefix(null),
                "Null-instance vanilla fallback remains valid while the patch is active");
        }
        finally { harmony.UnpatchAll(harmony.Id); }
        check(Harmony.GetPatchInfo(callback)?.Prefixes.Any(p => p.owner == harmony.Id) != true,
            "Grant-fief Harmony test cleans its patch without affecting other registrations");
    }
}
