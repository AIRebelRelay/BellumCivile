using BellumCivile.Behaviors;
using TaleWorlds.CampaignSystem;

namespace BellumCivile
{
    public static partial class BellumIntegration
    {
        /// <summary>
        /// Campaign-thread-only, detached, passive evidence. Even WeakTimestampMatchNotProof
        /// is NOT Native war-incarnation identity, action legality or political consent.
        /// Future executors must fail closed on ALL witness statuses until independent
        /// durable Native epoch and current intent/actor/terms checks are implemented.
        /// </summary>
        public static ForeignWarNativeWitnessSnapshot ObserveForeignWarNativeWitness(
            string instanceId, string primaryRealmId, string opposingRealmId)
        {
            BellumIntegrationBehavior.RequireCampaignThread();
            double day = CampaignTime.Now.ToDays;
            var behavior = Campaign.Current.GetCampaignBehavior<WarScoreBehavior>();
            return behavior == null
                ? new ForeignWarNativeWitnessSnapshot(ForeignConflictIdentityStatus.BehaviorUnavailable,
                    ForeignWarNativeWitnessStatus.IdentityUnavailable)
                : behavior.ObserveForeignWarNativeWitness(instanceId, primaryRealmId, opposingRealmId, day);
        }
    }
}
