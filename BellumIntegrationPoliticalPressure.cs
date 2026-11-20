using BellumCivile.Behaviors;
using TaleWorlds.CampaignSystem;

namespace BellumCivile
{
    public static partial class BellumIntegration
    {
        /// <summary>Campaign-thread technical snapshot, not authorization or public/NPC awareness.</summary>
        public static PoliticalPressureStateSnapshot GetExistingPoliticalPressureState(Clan clan)
        {
            BellumIntegrationBehavior.RequireCampaignThread();
            float day = (float)CampaignTime.Now.ToDays;
            var behavior = Campaign.Current.GetCampaignBehavior<WarPeaceRevampBehavior>();
            return behavior == null
                ? new PoliticalPressureStateSnapshot(clan?.StringId, day, PoliticalPressureStateStatus.BehaviorUnavailable)
                : behavior.GetExistingPoliticalPressureStateSnapshot(clan, day);
        }
    }
}
