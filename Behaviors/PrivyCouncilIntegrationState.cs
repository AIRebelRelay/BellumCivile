using System;
using System.Linq;
using TaleWorlds.CampaignSystem;

namespace BellumCivile.Behaviors
{
    public sealed partial class PrivyCouncilBehavior
    {
        // No Ensure*, holder resolution, index rebuild, validation/repair or mutable record escapes.
        internal CouncilOfficeStateSnapshot GetExistingCouncilStateSnapshot(Kingdom realm, double day)
        {
            string id = realm?.StringId;
            if (!IsEligiblePermanentRealm(realm))
                return new CouncilOfficeStateSnapshot(id, day, CouncilOfficeStateStatus.UnavailableRealm);
            if (double.IsNaN(day) || double.IsInfinity(day) || day < 0)
                return new CouncilOfficeStateSnapshot(id, day, CouncilOfficeStateStatus.InvalidRecords);
            var rows = _officeRecords?.Where(r => r != null && r.KingdomId == id).ToList();
            if (rows == null || rows.Count == 0)
                return new CouncilOfficeStateSnapshot(id, day, CouncilOfficeStateStatus.NotRecorded);
            if (rows.Any(r => !Enum.IsDefined(typeof(PrivyCouncilOffice), r.Office)
                || r.RecordId != PrivyCouncilOfficeRecord.BuildRecordId(id, r.Office))
                || rows.GroupBy(r => r.Office).Any(g => g.Count() != 1))
                return new CouncilOfficeStateSnapshot(id, day, CouncilOfficeStateStatus.InvalidRecords);
            if (rows.Any(r => !r.IsInitialized))
                return new CouncilOfficeStateSnapshot(id, day, CouncilOfficeStateStatus.UninitializedRecords);
            return new CouncilOfficeStateSnapshot(id, day, CouncilOfficeStateStatus.Recorded,
                rows.OrderBy(r => r.Office).Select(r => new CouncilOfficeRecordSnapshot(r)));
        }
    }
}
