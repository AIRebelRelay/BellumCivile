using System.Collections.Generic;
using BellumCivile.Behaviors;
using TaleWorlds.CampaignSystem;

namespace BellumCivile
{
    public static partial class BellumIntegration
    {
        /// <summary>
        /// Saved exact completions, campaign thread only. No state initialization, inference
        /// from world notifications, or backfilling of older already-ready records.
        /// </summary>
        public static IReadOnlyList<RestoredRealmCompletionSnapshot> GetRecentRestoredRealmCompletions()
        {
            BellumIntegrationBehavior.RequireCampaignThread();
            return Campaign.Current?.GetCampaignBehavior<CivilWarResolutionBehavior>()
                ?.GetRecentRestoredRealmCompletions() ?? new RestoredRealmCompletionSnapshot[0];
        }
    }
}
