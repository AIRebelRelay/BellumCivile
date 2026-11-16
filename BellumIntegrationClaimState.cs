using BellumCivile.Behaviors;
using TaleWorlds.CampaignSystem;

namespace BellumCivile
{
    public static partial class BellumIntegration
    {
        /// <summary>Campaign-thread-only technical projection. Never publish directly as NPC knowledge.</summary>
        public static ClaimStateSnapshot GetExistingClaimState(Clan clan)
        {
            BellumIntegrationBehavior.RequireCampaignThread();
            // Match the float-day precision used by IsClaimCurrentlyActive.
            float day = (float)CampaignTime.Now.ToDays;
            var behavior = Campaign.Current.GetCampaignBehavior<FeudalTitleBehavior>();
            return behavior == null
                ? new ClaimStateSnapshot(clan?.StringId, day, ClaimStateStatus.BehaviorUnavailable)
                : behavior.GetExistingClaimStateSnapshot(clan, day);
        }
    }
}
