namespace BellumCivile
{
    /// <summary>Immutable scalar copy of one saved and completed restoration.</summary>
    public sealed class RestoredRealmCompletionSnapshot
    {
        public string Id { get; }
        public double CompletedDay { get; }
        public string ParentRealmId { get; }
        public string SourceRealmId { get; }
        public string SuccessorRealmId { get; }
        public string FounderClanId { get; }
        public bool Replacement { get; }

        internal RestoredRealmCompletionSnapshot(RestoredRealmCreationRecord record)
        {
            Id = record.CompletionReceiptId;
            CompletedDay = record.CompletedDay;
            ParentRealmId = record.Parent.StringId;
            SourceRealmId = record.Source.StringId;
            SuccessorRealmId = record.SuccessorId;
            FounderClanId = record.Founder.StringId;
            Replacement = record.Replacement;
        }
    }
}
