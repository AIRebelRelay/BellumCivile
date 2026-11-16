using System.Collections.Generic;
using System.Linq;

namespace BellumCivile
{
    public enum ClaimStateStatus
    {
        Recorded, UnavailableClan, BehaviorUnavailable, UninitializedRecords, InvalidRecords, CapacityExceeded
    }
    public enum ClaimTargetState { RecordsUnavailable, Missing, Inactive, Dissolved, Active }

    /// <summary>Recorded claim, not title ownership, action authority, public news or NPC knowledge.</summary>
    public sealed class ClaimRecordSnapshot
    {
        public string ClaimId { get; }
        public string TargetTitleId { get; }
        public FeudalClaimStrength Strength { get; }
        public float CreatedDay { get; }
        public float ExpiresDay { get; }
        public ClaimTargetState TargetState { get; }

        internal ClaimRecordSnapshot(FeudalClaimRecord record, ClaimTargetState target)
        {
            ClaimId = record.ClaimId;
            TargetTitleId = record.TargetTitleId;
            Strength = record.Strength;
            CreatedDay = record.CreatedDay;
            ExpiresDay = record.ExpiresDay;
            TargetState = target;
        }
    }

    /// <summary>
    /// Detached active claims of the requested clan, using Bellum's existing expiry and legitimacy filter.
    /// Technical API only: actor authorization and CR awareness must be enforced before any future prompt use.
    /// Source/reasons, carrier identities and fabrication provenance are intentionally absent.
    /// Recorded + empty means no matching active saved claims, not no possible title rights.
    /// </summary>
    public sealed class ClaimStateSnapshot
    {
        public const int ApiVersion = 1;
        public const int MaximumClaims = 128;
        public string ClanId { get; }
        public double CapturedDay { get; }
        public ClaimStateStatus Status { get; }
        public int ActiveRecordCount { get; }
        public IReadOnlyList<ClaimRecordSnapshot> Claims { get; }

        internal ClaimStateSnapshot(string clanId, double day, ClaimStateStatus status, int count = 0,
            IEnumerable<ClaimRecordSnapshot> claims = null)
        {
            ClanId = clanId;
            CapturedDay = day;
            Status = status;
            ActiveRecordCount = count;
            Claims = (claims ?? Enumerable.Empty<ClaimRecordSnapshot>()).ToList().AsReadOnly();
        }
    }
}
