using System;
using TaleWorlds.CampaignSystem;

namespace BellumCivile
{
    /// <summary>
    /// Read-only origin of the CURRENT native partition notice invocation.
    /// A notice is not evidence of aggregate completion, UI display, durable
    /// delivery, or a globally unique save/rollback generation.
    /// </summary>
    public sealed class PartitionNoticeOriginSnapshot
    {
        public string EpisodeId { get; }
        public string DeceasedId { get; }
        public string OriginHouseId { get; }
        public string HeirId { get; }
        public string RecipientHouseId { get; }
        public string Executor { get; }
        public string NoticeKey { get; }

        internal PartitionNoticeOriginSnapshot(
            string deceasedId, string originHouseId, string heirId,
            string recipientHouseId, string executor, string noticeKey)
        {
            EpisodeId = "partition|" + deceasedId + "|" + originHouseId;
            DeceasedId = deceasedId;
            OriginHouseId = originHouseId;
            HeirId = heirId;
            RecipientHouseId = recipientHouseId;
            Executor = executor;
            NoticeKey = noticeKey;
        }
    }
}

namespace BellumCivile.Behaviors
{
    /// <summary>
    /// Scoped provenance for synchronous BellumCivileNotifications.Show only.
    /// No save data, event dispatch, Harmony patch or inheritance mutation.
    /// The Bridge may read it during its existing Show postfix, but it must
    /// NOT treat it as a terminal estate result or an ACK/dedup receipt.
    /// </summary>
    internal static class PartitionNoticeOriginScope
    {
        private sealed class ActiveClaim
        {
            internal Campaign Campaign;
            internal PartitionNoticeOriginSnapshot Snapshot;

            internal ActiveClaim(Campaign campaign, PartitionNoticeOriginSnapshot snapshot)
            {
                Campaign = campaign;
                Snapshot = snapshot;
            }
        }

        [ThreadStatic] private static ActiveClaim _active;

        internal static IDisposable Begin(
            string deceasedId, string originHouseId, string heirId,
            string recipientHouseId, string executor, string noticeKey)
        {
            ActiveClaim previous = _active;
            Campaign campaign = Campaign.Current;
            _active = campaign != null
                && !string.IsNullOrWhiteSpace(deceasedId)
                && !string.IsNullOrWhiteSpace(originHouseId)
                && !string.IsNullOrWhiteSpace(heirId)
                && !string.IsNullOrWhiteSpace(recipientHouseId)
                && !string.IsNullOrWhiteSpace(executor)
                && !string.IsNullOrWhiteSpace(noticeKey)
                ? new ActiveClaim(campaign, new PartitionNoticeOriginSnapshot(
                    deceasedId, originHouseId, heirId, recipientHouseId, executor, noticeKey))
                : null;
            return new Restore(previous);
        }

        internal static PartitionNoticeOriginSnapshot GetCurrent()
        {
            ActiveClaim current = _active;
            return current != null && ReferenceEquals(current.Campaign, Campaign.Current)
                ? current.Snapshot : null;
        }

        private sealed class Restore : IDisposable
        {
            private ActiveClaim _previous;
            private bool _disposed;

            internal Restore(ActiveClaim previous) { _previous = previous; }

            public void Dispose()
            {
                if (_disposed) return;
                _disposed = true;
                _active = _previous;
                _previous = null;
            }
        }
    }
}
