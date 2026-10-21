// Isolated compilation fixture. These classes are NOT shipped with BellumCivile.dll.
using System;
using System.Collections.Generic;
namespace TaleWorlds.CampaignSystem
{
    public sealed class Hero
    {
        public int Relation;
        public int GetRelation(Hero other) { return Relation; }
    }
    public sealed class Kingdom
    {
        public static readonly List<Kingdom> All = new List<Kingdom>();
        public string StringId;
        public bool IsEliminated;
        public Clan RulingClan;
        public List<Clan> Clans = new List<Clan>();
    }
    public sealed class Clan
    {
        public static Clan PlayerClan;
        public string StringId;
        public Kingdom Kingdom;
        public Hero Leader;
        public bool IsEliminated;
        public bool IsUnderMercenaryService;
        public bool IsMinorFaction;
    }
    public struct CampaignTime
    {
        public double ToDays;
        public static double CurrentDay = 17.25;
        public const int DaysInYear = 84;
        public static CampaignTime Now { get { return new CampaignTime { ToDays = CurrentDay }; } }
    }
    public interface IDataStore
    {
        void SyncData(string key, ref Dictionary<string, string> data);
    }
    public sealed class FakeNpcCrownStore : IDataStore
    {
        public bool Writing = true;
        public Dictionary<string, string> Serialized;
        public string Key;
        public Dictionary<string, Dictionary<string, string>> Saved =
            new Dictionary<string, Dictionary<string, string>>();
        public void SyncData(string key, ref Dictionary<string, string> data)
        {
            Key = key;
            if (Writing)
            {
                Saved[key] = data == null ? null : new Dictionary<string, string>(data);
                if (key == "BC_CourtNpcTreasonIntents_v1") Serialized = Saved[key];
            }
            else
            {
                Dictionary<string, string> source;
                data = Saved.TryGetValue(key, out source) && source != null
                    ? new Dictionary<string, string>(source) : null;
            }
        }
    }
    public sealed class Campaign
    {
        public static Campaign Current;
        public BellumCivile.Behaviors.IdeologyBehavior Ideology;
        public T GetCampaignBehavior<T>() where T : class
        {
            return Ideology as T;
        }
    }
}
namespace TaleWorlds.Localization
{
    public sealed class TextObject
    {
        public TextObject(string text) { }
    }
}
namespace BellumCivile
{
    public static class BellumCivileOptions
    {
        public static bool EnableAutomaticTreasonIndictments = true;
        public static float CourtTermDays = 84f;
    }
    public static class BellumCivileLogger
    {
        public static readonly List<string> Lines = new List<string>();
        public static void Log(string line) { Lines.Add(line); }
    }
}
namespace BellumCivile.Behaviors
{
    public sealed partial class CourtAgendaBehavior
    {
        public static CourtAgendaBehavior Current { get; set; }
        internal static bool ValidRealm(TaleWorlds.CampaignSystem.Kingdom realm)
        {
            return realm != null && !realm.IsEliminated && realm.RulingClan?.Leader != null;
        }
        internal static bool Eligible(TaleWorlds.CampaignSystem.Clan clan,
            TaleWorlds.CampaignSystem.Kingdom realm)
        {
            return clan != null && !clan.IsEliminated && clan.Leader != null
                && !clan.IsUnderMercenaryService && clan.Kingdom == realm;
        }
    }
    public sealed partial class BellumIntegrationBehavior
    {
        public static bool OnCampaignThread = true;
        internal static void RequireCampaignThread()
        {
            if (!OnCampaignThread)
                throw new InvalidOperationException("not campaign thread");
        }
    }
    public sealed class IdeologyBehavior
    {
        public bool Eligible = true;
        public bool WasReadOnly;
        public bool CanRulerIndictClan(TaleWorlds.CampaignSystem.Kingdom realm,
            TaleWorlds.CampaignSystem.Clan target, bool highTreason,
            out TaleWorlds.Localization.TextObject explanation, bool readOnly = false)
        {
            WasReadOnly = readOnly;
            explanation = new TaleWorlds.Localization.TextObject("test");
            return Eligible;
        }
    }
}
