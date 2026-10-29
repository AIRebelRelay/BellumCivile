using System;
using BellumCivile;
using BellumCivile.Behaviors;
using HarmonyLib;

// Stage29F1: source-backed foreign accounting ONLY. No war/peace action invoked.
internal static class AiInfluenceForeignLedgerTests
{
    internal static void Run(Action<bool, string> check)
    {
        var behavior = new WarScoreBehavior();
        var owned = new WarScoreRecord("a|b", "a", "b", 1, null,
            WarScoreConflictType.ForeignWar, "aii_foreign_ledger:v1:exact-ai-event-1");
        var ordinary = new WarScoreRecord("a|b", "a", "b", 1, null,
            WarScoreConflictType.ForeignWar, "");
        var civil = new WarScoreRecord("a|b", "a", "b", 1, null,
            WarScoreConflictType.CivilWar, "aii_foreign_ledger:v1:exact-ai-event-1");

        var isOwned = AccessTools.Method(typeof(WarScoreBehavior), "IsAiInfluenceForeignLedger");
        check(isOwned != null, "An exact source-backed foreign ledger detector is implemented");
        if (isOwned == null) return;
        bool Owned(WarScoreRecord war) => (bool)isOwned.Invoke(null, new object[] { war });
        check(Owned(owned), "AII foreign provenance is recognized from saved WarScoreRecord.ContextId");
        check(!Owned(ordinary), "Unowned ordinary foreign war is never AII-authorized");
        check(!Owned(civil), "Civil war cannot borrow AII foreign provenance even with same context");
        check(!Owned(null), "Missing war record is never authorized");

        var autonomous = AccessTools.Method(typeof(WarScoreBehavior), "ShouldPreventAutonomousForeignResolution");
        check(autonomous != null, "Native has an exact ForeignWar-only automatic-peace gate");
        if (autonomous != null)
        {
            bool Block(WarScoreRecord war, bool revampEnabled) =>
                (bool)autonomous.Invoke(null, new object[] { war, revampEnabled });
            check(Block(owned, false) && Block(owned, true),
                "AII-owned record never grants Native automatic peace, even after MCM toggle");
            check(Block(ordinary, false) && !Block(ordinary, true),
                "Restored ordinary Bellum foreign war cannot force peace when Revamp OFF");
            check(!Block(civil, false) && !Block(civil, true),
                "Civil-war terminal resolution is never captured by ForeignWar-only gate");
        }

        var register = AccessTools.Method(typeof(WarScoreBehavior), "TryRegisterAiInfluenceForeignWar");
        check(register != null, "Opt-in Native API exists but is not invoked by generic war declaration");
        if (register != null)
        {
            var args = new object[] { null, null, "exact-ai-event-1", null };
            check(!(bool)register.Invoke(behavior, args), "Null/absent real-world war cannot create an AII ledger");
        }

        owned.ForceScore(100);
        var queue = AccessTools.Method(typeof(WarScoreBehavior), "QueueTerminalWarScoreResolution");
        check(queue != null, "Existing native terminal method preserved");
        if (queue == null) return;
        check(!(bool)queue.Invoke(behavior, new object[] { owned, "no Bellum autonomous peace" }),
            "AII foreign ledger does not queue forced peace even at WarScore 100");
        check(!owned.TerminalResolutionQueued, "Terminal state stays unlatched after threshold");

        owned.QueueTerminalResolution("legacy saved pending");
        check(owned.TerminalResolutionQueued, "Legacy hostile terminal state was constructed");
        var resolve = AccessTools.Method(typeof(WarScoreBehavior), "ResolveQueuedTerminalWarScore");
        check(resolve != null, "Native queued resolver exists");
        if (resolve != null)
        {
            check(!(bool)resolve.Invoke(behavior, new object[] { owned }),
                "Restored AII ledger terminal state never invokes native forced peace");
            check(!owned.TerminalResolutionQueued,
                "Restored unauthorized pending terminal state is cleared without ending the war");
            check(owned.IsActive, "Owned ledger remains open until real diplomatic world-state peace");
        }

        civil.ForceScore(100);
        check((bool)queue.Invoke(behavior, new object[] { civil, "civil outcome" }),
            "Existing civil-war terminal queue remains enabled");
        check(civil.TerminalResolutionQueued, "Civil-war terminal flag remains unchanged");

        // ContextId is already a Native SaveableField(17), no SaveDefiner addition.
        var contextField = AccessTools.Field(typeof(WarScoreRecord), "_contextId");
        check(contextField != null && contextField.IsDefined(typeof(TaleWorlds.SaveSystem.SaveableFieldAttribute), false),
            "AII source provenance persists via existing native SaveableField(17)");
    }
}
