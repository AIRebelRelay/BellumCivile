using System;
using System.Linq;
using System.Reflection;
using TaleWorlds.CampaignSystem;

namespace BellumCivile
{
    internal enum ForeignPeaceOptionalVerdict
    {
        Unknown = 0,
        Clear = 1,
        Blocked = 2
    }

    /// <summary>
    /// Read-only probes for optional modules. Never call Native's cached reflection
    /// helpers here: their negative results may mean "not inspected".
    /// Unknown means "do not promise the LLM that foreign peace is lawful".
    /// </summary>
    internal static class ForeignPeaceOptionalModSafetyProbe
    {
        internal static ForeignPeaceOptionalVerdict CheckStoryMode(
            Kingdom source, Kingdom target)
        {
            if (source == null || target == null)
                return ForeignPeaceOptionalVerdict.Unknown;

            try
            {
                Assembly[] loaded = AppDomain.CurrentDomain.GetAssemblies();
                bool storyPresent = loaded.Any(a =>
                    string.Equals(a.GetName().Name, "StoryMode", StringComparison.OrdinalIgnoreCase)
                    || a.GetType("StoryMode.StoryModeManager", throwOnError: false) != null);
                if (!storyPresent)
                    return ForeignPeaceOptionalVerdict.Clear;

                Hero mainHero = Hero.MainHero;
                if (mainHero == null)
                    return ForeignPeaceOptionalVerdict.Unknown;

                Kingdom playerKingdom = Hero.MainHero?.MapFaction as Kingdom;

                // Mirror only the proven SCOPE of StorylineWarProtectionHelper,
                // NOT its bool-only reflection/fallback logic:
                // a quest protection can apply only if exactly one belligerent
                // is the main hero's map faction.
                if (playerKingdom == null
                    || (source == playerKingdom) == (target == playerKingdom))
                    return ForeignPeaceOptionalVerdict.Clear;

                // An actual player-side Story Mode quest would need a separately
                // validated tri-state query. Never treat reflection failure as clear.
                return ForeignPeaceOptionalVerdict.Unknown;
            }
            catch (Exception)
            {
                return ForeignPeaceOptionalVerdict.Unknown;
            }
        }

        internal static ForeignPeaceOptionalVerdict CheckDiplomacyRebels(
            Kingdom source, Kingdom target)
        {
            if (source == null || target == null)
                return ForeignPeaceOptionalVerdict.Unknown;

            try
            {
                Assembly[] loaded = AppDomain.CurrentDomain.GetAssemblies();
                Type extension = loaded
                    .Select(a => a.GetType("Diplomacy.Extensions.KingdomExtensions", throwOnError: false))
                    .FirstOrDefault(t => t != null);

                bool diplomacyPresent = loaded.Any(a =>
                {
                    string name = a.GetName().Name ?? string.Empty;
                    return name.Equals("Bannerlord.Diplomacy", StringComparison.OrdinalIgnoreCase)
                        || name.StartsWith("Bannerlord.Diplomacy.", StringComparison.OrdinalIgnoreCase)
                        || name.Equals("Bannerlord.ModuleLoader.Bannerlord.Diplomacy", StringComparison.OrdinalIgnoreCase)
                        || name.Equals("Diplomacy", StringComparison.OrdinalIgnoreCase)
                        || a.GetType("Diplomacy.Settings", throwOnError: false) != null;
                }) || extension != null;

                if (!diplomacyPresent)
                    return ForeignPeaceOptionalVerdict.Clear;

                // Recognize this known source-backed extension only from official
                // Diplomacy assembly names. Different builds/extensions fail closed.
                string owner = extension?.Assembly.GetName().Name ?? string.Empty;
                bool trustedAssembly = owner.Equals("Bannerlord.Diplomacy", StringComparison.OrdinalIgnoreCase)
                    || owner.StartsWith("Bannerlord.Diplomacy.", StringComparison.OrdinalIgnoreCase)
                    || owner.Equals("Bannerlord.ModuleLoader.Bannerlord.Diplomacy", StringComparison.OrdinalIgnoreCase);
                if (!trustedAssembly)
                    return ForeignPeaceOptionalVerdict.Unknown;

                MethodInfo probe = extension.GetMethod(
                    "IsRebelKingdom",
                    BindingFlags.Public | BindingFlags.Static,
                    binder: null,
                    types: new[] { typeof(Kingdom) },
                    modifiers: null);
                if (probe == null || probe.ReturnType != typeof(bool))
                    return ForeignPeaceOptionalVerdict.Unknown;

                // In Diplomacy v1.5.5 and its 2026-11-14 source HEAD this
                // extension reads RebelFactionManager's active/dead registries.
                // Do not use ModIntegrationHelper.IsDiplomacyRebelKingdom:
                // it writes lazy static reflection caches and can hide errors.
                object sourceResult = probe.Invoke(null, new object[] { source });
                object targetResult = probe.Invoke(null, new object[] { target });
                if (!(sourceResult is bool sourceIsRebel)
                    || !(targetResult is bool targetIsRebel))
                    return ForeignPeaceOptionalVerdict.Unknown;

                return sourceIsRebel || targetIsRebel
                    ? ForeignPeaceOptionalVerdict.Blocked
                    : ForeignPeaceOptionalVerdict.Clear;
            }
            catch (Exception)
            {
                // Missing DLL/manager, changed external API or runtime failure
                // must not be misreported as "not a rebel".
                return ForeignPeaceOptionalVerdict.Unknown;
            }
        }
    }
}
