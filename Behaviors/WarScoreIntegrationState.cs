using System;
using System.Linq;
using TaleWorlds.CampaignSystem;

namespace BellumCivile.Behaviors
{
    public sealed partial class WarScoreBehavior
    {
        // No Ensure*, reconciliation, scoring, ending wars or mutable record escapes.
        internal WarStateSnapshot GetExistingWarStateSnapshot(Kingdom realm, double day)
        {
            string id = realm?.StringId;
            if (realm == null || realm.IsEliminated || string.IsNullOrWhiteSpace(id)
                || !Kingdom.All.Contains(realm))
                return new WarStateSnapshot(id, day, WarStateStatus.UnavailableRealm);
            if (double.IsNaN(day) || double.IsInfinity(day) || day < 0)
                return new WarStateSnapshot(id, day, WarStateStatus.InvalidRecords);
            if (_wars == null)
                return new WarStateSnapshot(id, day, WarStateStatus.UninitializedRecords);
            // Null rows cannot be scoped, so reject rather than silently asserting completeness.
            if (_wars.Any(w => w == null))
                return new WarStateSnapshot(id, day, WarStateStatus.InvalidRecords);
            var rows = _wars.Where(w => w.IsActive
                && (w.AttackerKingdomId == id || w.DefenderKingdomId == id)).ToList();
            int count = rows.Count;
            if (rows.Any(w => string.IsNullOrWhiteSpace(w.WarKey)
                || string.IsNullOrWhiteSpace(w.AttackerKingdomId) || string.IsNullOrWhiteSpace(w.DefenderKingdomId)
                || w.AttackerKingdomId == w.DefenderKingdomId
                || !Enum.IsDefined(typeof(WarScoreConflictType), w.ConflictType)
                || float.IsNaN(w.Score) || float.IsInfinity(w.Score)
                || float.IsNaN(w.StartedDay) || float.IsInfinity(w.StartedDay)
                || w.StartedDay < 0 || w.StartedDay > day)
                || rows.GroupBy(w => w.WarKey, StringComparer.Ordinal).Any(g => g.Count() > 1))
                return new WarStateSnapshot(id, day, WarStateStatus.InvalidRecords, count);
            if (count > WarStateSnapshot.MaximumWars)
                return new WarStateSnapshot(id, day, WarStateStatus.CapacityExceeded, count);
            var copies = rows.OrderBy(w => w.WarKey, StringComparer.Ordinal).Select(w =>
            {
                Kingdom opponent = GetOpposingKingdom(w, realm);
                bool? hostility = opponent == null ? (bool?)null : realm.IsAtWarWith(opponent);
                return new WarRecordSnapshot(w, id, day, hostility);
            }).ToList();
            return new WarStateSnapshot(id, day, WarStateStatus.Recorded, count, copies);
        }
    }
}
