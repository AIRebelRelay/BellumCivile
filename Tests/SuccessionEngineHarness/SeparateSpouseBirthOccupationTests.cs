using System;
using System.Reflection;
using System.Runtime.Serialization;
using BellumCivile.Patches;
using HarmonyLib;
using TaleWorlds.CampaignSystem;
using TaleWorlds.Core;

// Targeted behavioral tests for the native birth occupation resolver.
// The household Supports() predicate is replaced only in the harness to isolate the birth rule.
internal static class SeparateSpouseBirthOccupationTests
{
    private static Hero _player;
    private static Clan _supportedHousehold;
    private static Occupation _nativeOccupation;
    private static int _supportsCalls;

    private static bool Player(ref Hero __result) { __result = _player; return false; }
    private static bool NativeOccupation(ref Occupation __result) { __result = _nativeOccupation; return false; }
    private static bool Supported(Clan clan, ref bool __result)
    {
        _supportsCalls++;
        __result = clan != null && clan == _supportedHousehold;
        return false;
    }

    private static T Blank<T>() => (T)FormatterServices.GetUninitializedObject(typeof(T));

    internal static void Run(Action<bool, string> check)
    {
        var harmony = new Harmony("bellum.tests.birth_occupation_157");
        var membership = typeof(SeparateSpouseBirthClanPatch).Assembly.GetType("BellumCivile.HouseholdMembership", true);
        MethodInfo supports = AccessTools.Method(membership, "Supports");
        check(supports != null && supports.ReturnType == typeof(bool),
            "Complete upstream household membership helper is present with its native predicate");
        var originalPlayer = _player;
        var originalHouse = _supportedHousehold;
        try
        {
            harmony.Patch(AccessTools.PropertyGetter(typeof(Hero), "MainHero"),
                prefix: new HarmonyMethod(typeof(SeparateSpouseBirthOccupationTests), nameof(Player)));
            harmony.Patch(AccessTools.PropertyGetter(typeof(Hero), "Occupation"),
                prefix: new HarmonyMethod(typeof(SeparateSpouseBirthOccupationTests), nameof(NativeOccupation)));
            harmony.Patch(supports, prefix: new HarmonyMethod(typeof(SeparateSpouseBirthOccupationTests), nameof(Supported)));

            Clan maternal = Blank<Clan>(); maternal.StringId = "mother_house";
            Clan paternal = Blank<Clan>(); paternal.StringId = "father_house";
            Hero mother = Blank<Hero>(); mother.StringId = "mother";
            Hero father = Blank<Hero>(); father.StringId = "father";
            Hero third = Blank<Hero>(); third.StringId = "unrelated_player";
            AccessTools.Field(typeof(Hero), "_clan").SetValue(mother, maternal);
            AccessTools.Field(typeof(Hero), "_clan").SetValue(father, paternal);
            _supportedHousehold = maternal;
            _nativeOccupation = Occupation.Wanderer;
            _player = null;

            Occupation Birth(Hero nativeParent) =>
                SeparateSpouseBirthClanPatch.ResolveBirthOccupation(nativeParent, mother, father);

            check(Birth(father) == Occupation.Lord,
                "NPC father and different-clan mother select maternal noble household for newborn occupation");
            _player = father;
            check(Birth(father) == Occupation.Lord,
                "Player father does not override separate mother's noble household");
            _player = mother;
            check(Birth(mother) == Occupation.Lord,
                "Player mother uses the same household eligibility and noble-born outcome");
            _player = third;
            check(Birth(father) == Occupation.Lord,
                "Unrelated player is not treated as a parent");
            _supportedHousehold = paternal;
            check(Birth(father) == Occupation.Wanderer,
                "Unsupported maternal household retains the native wanderer occupation");
            _supportedHousehold = null;
            check(Birth(father) == Occupation.Wanderer,
                "No eligible household never manufactures a noble occupation");

            _supportsCalls = 0;
            _nativeOccupation = Occupation.Lord;
            check(Birth(father) == Occupation.Lord && _supportsCalls == 0,
                "Already noble newborn keeps native occupation without querying household eligibility");

            _nativeOccupation = Occupation.Wanderer;
            _player = null;
            _supportedHousehold = paternal;
            check(SeparateSpouseBirthClanPatch.ResolveBirthOccupation(father, null, father) == Occupation.Lord,
                "Missing maternal data preserves the valid native paternal clan fallback");
            _supportedHousehold = maternal;
            check(SeparateSpouseBirthClanPatch.ResolveBirthOccupation(father, null, father) == Occupation.Wanderer,
                "Missing maternal data does not invent a maternal household");
        }
        finally
        {
            harmony.UnpatchAll(harmony.Id);
            _player = originalPlayer;
            _supportedHousehold = originalHouse;
            _supportsCalls = 0;
            _nativeOccupation = default(Occupation);
        }
    }
}
