using BellumCivile.Behaviors;
using TaleWorlds.CampaignSystem;

namespace BellumCivile
{
    public static partial class BellumIntegration
    {
        /// <summary>
        /// Campaign-thread-only observed identity lookup. Caller must separately enforce actor/knowledge
        /// scope, current engine war incarnation and all Native legality before using this data.
        /// No missing record/identity is initialized or repaired.
        /// </summary>
        public static ForeignConflictIdentitySnapshot GetExistingForeignConflictByInstance(
            string instanceId, string primaryRealmId, string opposingRealmId)
        {
            BellumIntegrationBehavior.RequireCampaignThread();
            double day = CampaignTime.Now.ToDays;
            var behavior = Campaign.Current.GetCampaignBehavior<WarScoreBehavior>();
            return behavior == null
                ? new ForeignConflictIdentitySnapshot(ForeignConflictIdentityStatus.BehaviorUnavailable, day)
                : behavior.GetExistingForeignConflictByInstance(instanceId, primaryRealmId, opposingRealmId, day);
        }
    }
}
