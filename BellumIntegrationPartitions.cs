using System;
using System.Collections.Generic;
using BellumCivile.Behaviors;

namespace BellumCivile
{
    public static partial class BellumIntegration
    {
        /// <summary>Subscribe each campaign session. Callbacks occur after the estate has completed.</summary>
        public static event Action<PartitionCompletionSnapshot> PartitionCompleted
        {
            add { BellumIntegrationBehavior.RequireCampaignThread(); BellumIntegrationBehavior.Current.PartitionCompleted += value; }
            remove { BellumIntegrationBehavior.RequireCampaignThread(); BellumIntegrationBehavior.Current.PartitionCompleted -= value; }
        }

        public static IReadOnlyList<PartitionCompletionSnapshot> GetRecentPartitions()
        {
            BellumIntegrationBehavior.RequireCampaignThread();
            return BellumIntegrationBehavior.Current.GetRecentPartitions();
        }

        /// <summary>
        /// Exact origin during one synchronous native partition notice only.
        /// Null outside that invocation; neither completion nor display receipt.
        /// </summary>
        public static PartitionNoticeOriginSnapshot GetCurrentPartitionNoticeOrigin()
        {
            BellumIntegrationBehavior.RequireCampaignThread();
            return PartitionNoticeOriginScope.GetCurrent();
        }
    }
}
