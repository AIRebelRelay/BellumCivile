using System.Collections.Generic;
using System.Linq;

namespace BellumCivile
{
    public enum PoliticalPressureStateStatus { Recorded, UnavailableClan, BehaviorUnavailable, InvalidRecords, CapacityExceeded }
    public enum RecordedWarWillStatus { Recorded, NotRecorded, RecordsUnavailable }
    public enum PressureRecordsStatus { Recorded, RecordsUnavailable }

    /// <summary>Recorded applied war-will pressure, not faction opinion, an NPC grievance or a future target preference.</summary>
    public sealed class PoliticalPressureRecordSnapshot
    {
        public string RecordId { get; }
        public string TargetRealmId { get; }
        public string ConflictKey { get; }
        public float Amount { get; }
        public WarWillReasonType ReasonType { get; }
        public float CreatedDay { get; }
        public float ExpiresDay { get; }

        internal PoliticalPressureRecordSnapshot(WarWillPressureRecord record)
        {
            RecordId = record.RecordId;
            TargetRealmId = record.TargetKingdomId;
            ConflictKey = record.ConflictKey;
            Amount = record.Amount;
            ReasonType = record.ReasonType;
            CreatedDay = record.CreatedDay;
            ExpiresDay = record.ExpiresDay;
        }
    }

    /// <summary>
    /// Detached technical clan state. Separate section statuses distinguish unavailable/missing data from zero/empty.
    /// Pressure amounts are already applied deltas; their sum must not be added to RecordedWarWill again.
    /// Caller must enforce actor authorization/CR knowledge before future prompt use. No runtime registration.
    /// </summary>
    public sealed class PoliticalPressureStateSnapshot
    {
        public const int ApiVersion = 1;
        public const int MaximumPressures = 128;
        public string ClanId { get; }
        public double CapturedDay { get; }
        public PoliticalPressureStateStatus Status { get; }
        public RecordedWarWillStatus WarWillStatus { get; }
        public float? RecordedWarWill { get; }
        public PressureRecordsStatus PressureStatus { get; }
        public int ActivePressureCount { get; }
        public IReadOnlyList<PoliticalPressureRecordSnapshot> Pressures { get; }

        internal PoliticalPressureStateSnapshot(string clanId, double day, PoliticalPressureStateStatus status,
            RecordedWarWillStatus warWillStatus = RecordedWarWillStatus.RecordsUnavailable, float? warWill = null,
            PressureRecordsStatus pressureStatus = PressureRecordsStatus.RecordsUnavailable, int count = 0,
            IEnumerable<PoliticalPressureRecordSnapshot> pressures = null)
        {
            ClanId = clanId;
            CapturedDay = day;
            Status = status;
            WarWillStatus = warWillStatus;
            RecordedWarWill = warWill;
            PressureStatus = pressureStatus;
            ActivePressureCount = count;
            Pressures = (pressures ?? Enumerable.Empty<PoliticalPressureRecordSnapshot>()).ToList().AsReadOnly();
        }
    }
}
