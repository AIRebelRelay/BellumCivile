using BellumCivile.Behaviors;
using TaleWorlds.CampaignSystem;

namespace BellumCivile
{
    public static partial class BellumIntegration
    {
        /// <summary>Campaign-thread-only technical snapshot. Caller must separately enforce actor scope and CR knowledge.</summary>
        public static WarStateSnapshot GetExistingWarState(Kingdom realm)
        {
            BellumIntegrationBehavior.RequireCampaignThread();
            double day = CampaignTime.Now.ToDays;
            var behavior = Campaign.Current.GetCampaignBehavior<WarScoreBehavior>();
            return behavior == null
                ? new WarStateSnapshot(realm?.StringId, day, WarStateStatus.BehaviorUnavailable)
                : behavior.GetExistingWarStateSnapshot(realm, day);
        }
    }
}
