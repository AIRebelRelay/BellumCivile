namespace BellumCivile
{
    public enum RecordedNameKind { Title, Realm }
    public enum RecordedNameStatus
    {
        Recorded, InvalidRequest, NotRecorded, RecordsUnavailable, BehaviorUnavailable,
        Inactive, Dissolved, InvalidRecord, EmptyName, AmbiguousIdentity, RenderingFailed
    }
    /// <summary>
    /// Detached source label only, not actor awareness, title ownership or permission.
    /// Realm labels are recorded Native names, not generated dynamic display titles.
    /// </summary>
    public sealed class RecordedNameSnapshot
    {
        public const int ApiVersion = 1;
        public string EntityId { get; }
        public RecordedNameKind Kind { get; }
        public double CapturedDay { get; }
        public RecordedNameStatus Status { get; }
        public string Name { get; }
        internal RecordedNameSnapshot(string id, RecordedNameKind kind, double day, RecordedNameStatus status, string name = null)
        { EntityId = id; Kind = kind; CapturedDay = day; Status = status; Name = status == RecordedNameStatus.Recorded ? name : null; }
    }
}
