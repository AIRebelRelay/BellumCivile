using BellumCivile.Behaviors;
using TaleWorlds.CampaignSystem;

namespace BellumCivile
{
    public static partial class BellumIntegration
    {
        /// <summary>
        /// Copies existing council records on the campaign thread without creating a council.
        /// Recorded holder IDs are source state, not proof of live eligibility or action authority.
        /// No secret assignments, controversy or reaction reasons are returned.
        /// </summary>
        public static CouncilOfficeStateSnapshot GetExistingCouncilState(Kingdom realm)
        {
            BellumIntegrationBehavior.RequireCampaignThread();
            double day = CampaignTime.Now.ToDays;
            var council = Campaign.Current.GetCampaignBehavior<PrivyCouncilBehavior>();
            return council == null
                ? new CouncilOfficeStateSnapshot(realm?.StringId, day, CouncilOfficeStateStatus.BehaviorUnavailable)
                : council.GetExistingCouncilStateSnapshot(realm, day);
        }
    }
}
