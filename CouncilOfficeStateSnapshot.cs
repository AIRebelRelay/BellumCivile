using System;
using System.Collections.Generic;
using System.Linq;

namespace BellumCivile
{
    public enum CouncilOfficeStateStatus
    {
        Recorded, NotRecorded, UnavailableRealm, BehaviorUnavailable, UninitializedRecords, InvalidRecords
    }

    /// <summary>A detached saved office row. Not a permission, appointment event, vacancy eligibility or assignment.</summary>
    public sealed class CouncilOfficeRecordSnapshot
    {
        public string RecordId { get; }
        public string RealmId { get; }
        public PrivyCouncilOffice Office { get; }
        public string RecordedHolderClanId { get; }

        internal CouncilOfficeRecordSnapshot(PrivyCouncilOfficeRecord record)
        {
            RecordId = record.RecordId;
            RealmId = record.KingdomId;
            Office = record.Office;
            RecordedHolderClanId = record.HolderClanId ?? string.Empty;
        }
    }

    /// <summary>Existing saved records only. Empty/absent data does not assert that the realm has no council.</summary>
    public sealed class CouncilOfficeStateSnapshot
    {
        public const int ApiVersion = 1;
        public string RealmId { get; }
        public double CapturedDay { get; }
        public CouncilOfficeStateStatus Status { get; }
        public IReadOnlyList<CouncilOfficeRecordSnapshot> Offices { get; }
        public bool HasAllOfficeRecords { get; }

        internal CouncilOfficeStateSnapshot(string realmId, double day, CouncilOfficeStateStatus status,
            IEnumerable<CouncilOfficeRecordSnapshot> offices = null)
        {
            RealmId = realmId;
            CapturedDay = day;
            Status = status;
            Offices = (offices ?? Enumerable.Empty<CouncilOfficeRecordSnapshot>()).ToList().AsReadOnly();
            HasAllOfficeRecords = status == CouncilOfficeStateStatus.Recorded
                && Offices.Count == Enum.GetValues(typeof(PrivyCouncilOffice)).Length;
        }
    }
}
