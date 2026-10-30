using System.Collections.Generic;

namespace BellumCivile
{
    // Internal Native evidence exposed to trusted integration readers only.
    // The opaque receipt contains technical and potentially private fields;
    // it is NOT authorized for public event narration.
    public sealed class CourtTerminalEvictionReceiptSnapshot
    {
        public string Id { get; }
        public string RealmId { get; }
        public string EncodedPayload { get; }

        internal CourtTerminalEvictionReceiptSnapshot(string id, string realmId, string encodedPayload)
        {
            Id = id;
            RealmId = realmId;
            EncodedPayload = encodedPayload;
        }
    }

    public sealed class CourtTerminalEvictionInventorySnapshot
    {
        public string RealmId { get; }
        public bool SourceAvailable { get; }
        public IReadOnlyList<CourtTerminalEvictionReceiptSnapshot> Pending { get; }
        public int TotalStored { get; }
        public int InvalidCount { get; }
        public int OverflowCount { get; }
        public bool IsHealthy => SourceAvailable && OverflowCount == 0 && InvalidCount == 0;

        internal CourtTerminalEvictionInventorySnapshot(string realmId, bool sourceAvailable,
            IReadOnlyList<CourtTerminalEvictionReceiptSnapshot> pending,
            int totalStored, int invalidCount, int overflowCount)
        {
            RealmId = realmId;
            SourceAvailable = sourceAvailable;
            Pending = pending;
            TotalStored = totalStored;
            InvalidCount = invalidCount;
            OverflowCount = overflowCount;
        }

        internal static CourtTerminalEvictionInventorySnapshot Unavailable(string realmId)
            => new CourtTerminalEvictionInventorySnapshot(realmId, false,
                new List<CourtTerminalEvictionReceiptSnapshot>().AsReadOnly(), 0, 0, 0);
    }
}
