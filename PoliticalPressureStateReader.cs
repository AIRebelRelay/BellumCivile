using System;
using System.Collections.Generic;
using System.Linq;
using TaleWorlds.CampaignSystem;

namespace BellumCivile
{
    internal static class PoliticalPressureStateReader
    {
        // Only the behavior forwards its existing storage. Never initialize or expose that storage.
        internal static PoliticalPressureStateSnapshot Read(Clan clan, float day,
            Dictionary<string, float> warWill, List<WarWillPressureRecord> pressures)
        {
            string id = clan?.StringId;
            if (clan == null || clan.IsEliminated || string.IsNullOrWhiteSpace(id) || !Clan.All.Contains(clan))
                return new PoliticalPressureStateSnapshot(id, day, PoliticalPressureStateStatus.UnavailableClan);
            if (float.IsNaN(day) || float.IsInfinity(day) || day < 0)
                return new PoliticalPressureStateSnapshot(id, day, PoliticalPressureStateStatus.InvalidRecords);
            float stored = 0;
            bool found = warWill != null && warWill.TryGetValue(id, out stored);
            if (found && (float.IsNaN(stored) || float.IsInfinity(stored)))
                return new PoliticalPressureStateSnapshot(id, day, PoliticalPressureStateStatus.InvalidRecords);
            var willStatus = warWill == null ? RecordedWarWillStatus.RecordsUnavailable
                : found ? RecordedWarWillStatus.Recorded : RecordedWarWillStatus.NotRecorded;
            float? value = found ? (float?)stored : null;
            if (pressures == null)
                return new PoliticalPressureStateSnapshot(id, day, PoliticalPressureStateStatus.Recorded, willStatus, value);
            if (pressures.Any(p => p == null))
                return new PoliticalPressureStateSnapshot(id, day, PoliticalPressureStateStatus.InvalidRecords);
            var scoped = pressures.Where(p => p.IsActive && p.ClanId == id).ToList();
            if (scoped.Any(p => string.IsNullOrWhiteSpace(p.RecordId)
                || float.IsNaN(p.Amount) || float.IsInfinity(p.Amount)
                || float.IsNaN(p.CreatedDay) || float.IsInfinity(p.CreatedDay) || p.CreatedDay < 0 || p.CreatedDay > day
                || float.IsNaN(p.ExpiresDay) || float.IsInfinity(p.ExpiresDay)
                || !Enum.IsDefined(typeof(WarWillReasonType), p.ReasonType))
                || scoped.GroupBy(p => p.RecordId, StringComparer.Ordinal).Any(g => g.Count() > 1))
                return new PoliticalPressureStateSnapshot(id, day, PoliticalPressureStateStatus.InvalidRecords);
            var active = scoped.Where(p => !p.IsExpired(day)).OrderBy(p => p.RecordId, StringComparer.Ordinal).ToList();
            if (active.Count > PoliticalPressureStateSnapshot.MaximumPressures)
                return new PoliticalPressureStateSnapshot(id, day, PoliticalPressureStateStatus.CapacityExceeded, count: active.Count);
            return new PoliticalPressureStateSnapshot(id, day, PoliticalPressureStateStatus.Recorded, willStatus, value,
                PressureRecordsStatus.Recorded, active.Count, active.Select(p => new PoliticalPressureRecordSnapshot(p)));
        }
    }
}
