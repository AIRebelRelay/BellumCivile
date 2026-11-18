using BellumCivile.Behaviors;
using TaleWorlds.CampaignSystem;

namespace BellumCivile
{
    public static partial class BellumIntegration
    {
        /// <summary>Existing saved preparation receipts only. Does not create, repair or inform anyone.</summary>
        public static RealmPreparationStateSnapshot GetRecentRealmPreparations()
        {
            BellumIntegrationBehavior.RequireCampaignThread();
            double day = CampaignTime.Now.ToDays;
            var behavior = Campaign.Current.GetCampaignBehavior<CivilWarResolutionBehavior>();
            return behavior == null
                ? new RealmPreparationStateSnapshot(day, RealmPreparationStateStatus.BehaviorUnavailable)
                : behavior.GetRecentRealmPreparationSnapshot(day);
        }
    }
}
