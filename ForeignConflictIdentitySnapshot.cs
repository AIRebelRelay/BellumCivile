namespace BellumCivile
{
    public enum ForeignConflictIdentityStatus
    {
        InvalidRequest = 0, BehaviorUnavailable, UninitializedRecords, InvalidRecords,
        NotFound, Ambiguous, WrongConflictType, ParticipantMismatch, Ended,
        RealmUnavailable, NotAtWar, RecordedActive
    }

    /// <summary>Detached observed record data. Not legality, ruler consent, knowledge or an outcome receipt.</summary>
    public sealed class ForeignConflictIdentityRecord
    {
        public string InstanceId { get; }
        public string WarKey { get; }
        public string PrimaryRealmId { get; }
        public string OpposingRealmId { get; }
        public float PrimaryScore { get; }
        public float StartedDay { get; }
        internal ForeignConflictIdentityRecord(WarScoreRecord record)
        {
            InstanceId = record.ConflictInstanceId; WarKey = record.WarKey;
            PrimaryRealmId = record.AttackerKingdomId; OpposingRealmId = record.DefenderKingdomId;
            PrimaryScore = record.Score; StartedDay = record.StartedDay;
        }
    }

    public sealed class ForeignConflictIdentitySnapshot
    {
        public const int ApiVersion = 1;
        public ForeignConflictIdentityStatus Status { get; }
        public double? CapturedDay { get; }
        public ForeignConflictIdentityRecord Record { get; }
        internal ForeignConflictIdentitySnapshot(ForeignConflictIdentityStatus status, double day, WarScoreRecord record = null)
        {
            Status = status == ForeignConflictIdentityStatus.RecordedActive && record == null
                ? ForeignConflictIdentityStatus.InvalidRecords : status;
            CapturedDay = !double.IsNaN(day) && !double.IsInfinity(day) && day >= 0 ? (double?)day : null;
            Record = Status == ForeignConflictIdentityStatus.RecordedActive
                ? new ForeignConflictIdentityRecord(record) : null;
        }
    }
}
