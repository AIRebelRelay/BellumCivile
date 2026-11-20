using System.Collections.Generic;
using System.Linq;

namespace BellumCivile
{
    public enum WarStateStatus
    {
        Recorded, UnavailableRealm, BehaviorUnavailable, UninitializedRecords, InvalidRecords, CapacityExceeded
    }

    /// <summary>Mechanical source state, not NPC knowledge, a public event or permission to negotiate.</summary>
    public sealed class WarRecordSnapshot
    {
        public string WarKey { get; }
        public string PrimaryRealmId { get; }
        public string OpposingRealmId { get; }
        public WarScoreConflictType ConflictType { get; }
        public float PrimaryScore { get; }
        public float ViewingRealmScore { get; }
        public double DurationDays { get; }
        public bool? NativeHostility { get; }

        internal WarRecordSnapshot(WarScoreRecord record, string viewingRealmId, double day, bool? hostility)
        {
            WarKey = record.WarKey;
            PrimaryRealmId = record.AttackerKingdomId;
            OpposingRealmId = record.DefenderKingdomId;
            ConflictType = record.ConflictType;
            PrimaryScore = record.Score;
            ViewingRealmScore = viewingRealmId == PrimaryRealmId ? record.Score : -record.Score;
            DurationDays = day - record.StartedDay;
            NativeHostility = hostility;
        }
    }

    /// <summary>
    /// Active saved records involving the requested realm. Recorded + empty means no matching saved rows,
    /// not proof of peace. ForeignWar is the raw score kind; auxiliary/rivalry ownership is not classified here.
    /// No claim, pressure, negotiation payload, reason, event history or mutable Native object is exposed.
    /// </summary>
    public sealed class WarStateSnapshot
    {
        public const int ApiVersion = 1;
        public const int MaximumWars = 64;
        public string RealmId { get; }
        public double CapturedDay { get; }
        public WarStateStatus Status { get; }
        public int MatchingRecordCount { get; }
        public IReadOnlyList<WarRecordSnapshot> Wars { get; }

        internal WarStateSnapshot(string realmId, double day, WarStateStatus status, int count = 0,
            IEnumerable<WarRecordSnapshot> wars = null)
        {
            RealmId = realmId;
            CapturedDay = day;
            Status = status;
            MatchingRecordCount = count;
            Wars = (wars ?? Enumerable.Empty<WarRecordSnapshot>()).ToList().AsReadOnly();
        }
    }
}
