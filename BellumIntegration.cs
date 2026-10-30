using System.Collections.Generic;
using BellumCivile.Behaviors;
using TaleWorlds.CampaignSystem;

namespace BellumCivile
{
    /// <summary>Supported integration calls. Call only on the active campaign thread.</summary>
    public static partial class BellumIntegration
    {
        public const int ApiVersion = 1;

        public static bool ManagesRelationPair(Hero first, Hero second)
        {
            BellumIntegrationBehavior.RequireCampaignThread();
            return Campaign.Current.GetCampaignBehavior<DynamicRelationBehavior>()?.ManagesPair(first, second) == true;
        }

        public static HostageStatusSnapshot GetHostageStatus(Hero hero)
        {
            BellumIntegrationBehavior.RequireCampaignThread();
            return Campaign.Current.GetCampaignBehavior<HostagePactBehavior>()?.GetStatusSnapshot(hero);
        }

        public static IReadOnlyList<CourtAgendaSnapshot> GetCourtAgendas(Kingdom realm)
        {
            BellumIntegrationBehavior.RequireCampaignThread();
            return CourtAgendaBehavior.Current?.GetIntegrationSnapshots(realm) ?? new CourtAgendaSnapshot[0];
        }

        /// <summary>
        /// Internal diagnostic evidence of already-evicted Court results.
        /// Contains private technical provenance; NOT a public event feed.
        /// No receipt is acknowledged or removed by this read-only method.
        /// </summary>
        public static CourtTerminalEvictionInventorySnapshot GetCourtTerminalEvictionInventory(Kingdom realm)
        {
            BellumIntegrationBehavior.RequireCampaignThread();
            return CourtAgendaBehavior.Current?.GetTerminalEvictionInventory(realm)
                ?? CourtTerminalEvictionInventorySnapshot.Unavailable(realm?.StringId);
        }
    }
}
