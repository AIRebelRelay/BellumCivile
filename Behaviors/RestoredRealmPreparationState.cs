using System;
using System.Collections.Generic;
using System.Linq;

namespace BellumCivile.Behaviors
{
    public partial class CivilWarResolutionBehavior
    {
        internal RealmPreparationStateSnapshot GetRecentRealmPreparationSnapshot(double day)
        {
            if (!RealmPreparationReceiptCapture.ValidDay(day) || _restoredCreations == null)
                return new RealmPreparationStateSnapshot(day, RealmPreparationStateStatus.InvalidRecords);
            int pending = 0, undated = 0;
            var receipts = new List<RealmPreparationReceipt>();
            var ids = new HashSet<string>(StringComparer.Ordinal);
            foreach (var r in _restoredCreations)
            {
                if (r == null) return new RealmPreparationStateSnapshot(day, RealmPreparationStateStatus.InvalidRecords);
                if (string.IsNullOrEmpty(r.PreparationReceiptId))
                {
                    if (RealmPreparationReceiptCapture.HasPartialStamp(r))
                        return new RealmPreparationStateSnapshot(day, RealmPreparationStateStatus.InvalidRecords);
                    if (r.Ready) undated++; else pending++;
                    continue;
                }
                if (!RealmPreparationReceiptCapture.IsValid(r, day) || !ids.Add(r.PreparationReceiptId))
                    return new RealmPreparationStateSnapshot(day, RealmPreparationStateStatus.InvalidRecords);
                receipts.Add(new RealmPreparationReceipt(r));
            }
            return new RealmPreparationStateSnapshot(day, receipts.Count == 0
                ? RealmPreparationStateStatus.NotRecorded : RealmPreparationStateStatus.Recorded,
                receipts.OrderByDescending(r => r.CompletedDay).ThenBy(r => r.ReceiptId, StringComparer.Ordinal).Take(100),
                undated, pending, Math.Max(0, receipts.Count - 100));
        }
    }
}
