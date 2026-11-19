using System;
using System.Linq;
using BellumCivile.Behaviors;
using TaleWorlds.CampaignSystem;

namespace BellumCivile
{
    public static partial class BellumIntegration
    {
        /// <summary>Campaign-thread-only exact-ID lookup; never calls materializing title/name getters.</summary>
        public static RecordedNameSnapshot GetExistingName(RecordedNameKind kind, string id)
        {
            BellumIntegrationBehavior.RequireCampaignThread();
            float day = (float)CampaignTime.Now.ToDays;
            if (!Enum.IsDefined(typeof(RecordedNameKind), kind) || string.IsNullOrWhiteSpace(id) || id.Length > 256
                || id.Any(char.IsControl) || float.IsNaN(day) || float.IsInfinity(day) || day < 0)
                return new RecordedNameSnapshot(id, kind, day, RecordedNameStatus.InvalidRequest);
            if (kind == RecordedNameKind.Title)
            {
                var titles = Campaign.Current.GetCampaignBehavior<FeudalTitleBehavior>();
                return titles == null ? new RecordedNameSnapshot(id, kind, day, RecordedNameStatus.BehaviorUnavailable)
                    : titles.ReadExistingTitleName(id, day);
            }
            var realms = Kingdom.All;
            if (realms == null) return new RecordedNameSnapshot(id, kind, day, RecordedNameStatus.RecordsUnavailable);
            var matches = realms.Where(k => k != null && string.Equals(k.StringId, id, StringComparison.Ordinal)).Take(2).ToList();
            if (matches.Count == 0) return new RecordedNameSnapshot(id, kind, day, RecordedNameStatus.NotRecorded);
            if (matches.Count != 1) return new RecordedNameSnapshot(id, kind, day, RecordedNameStatus.AmbiguousIdentity);
            if (matches[0].IsEliminated) return new RecordedNameSnapshot(id, kind, day, RecordedNameStatus.Inactive);
            try
            {
                string name;
                if (!DynamicKingdomTitleNameHelper.TryReadExistingNativeName(matches[0], out name))
                    return new RecordedNameSnapshot(id, kind, day, RecordedNameStatus.NotRecorded);
                return new RecordedNameSnapshot(id, kind, day,
                    string.IsNullOrWhiteSpace(name) ? RecordedNameStatus.EmptyName : RecordedNameStatus.Recorded, name);
            }
            catch { return new RecordedNameSnapshot(id, kind, day, RecordedNameStatus.RenderingFailed); }
        }
    }
}
