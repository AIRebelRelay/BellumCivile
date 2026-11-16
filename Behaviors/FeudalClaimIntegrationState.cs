using System;
using System.Linq;
using TaleWorlds.CampaignSystem;

namespace BellumCivile.Behaviors
{
    public partial class FeudalTitleBehavior
    {
        // Read authoritative saved rows, not mutable/rebuilt claim indexes. No Ensure*, repair or normalization.
        internal ClaimStateSnapshot GetExistingClaimStateSnapshot(Clan clan, float day)
        {
            string id = clan?.StringId;
            if (clan == null || clan.IsEliminated || string.IsNullOrWhiteSpace(id) || !Clan.All.Contains(clan))
                return new ClaimStateSnapshot(id, day, ClaimStateStatus.UnavailableClan);
            if (float.IsNaN(day) || float.IsInfinity(day) || day < 0)
                return new ClaimStateSnapshot(id, day, ClaimStateStatus.InvalidRecords);
            if (_claims == null)
                return new ClaimStateSnapshot(id, day, ClaimStateStatus.UninitializedRecords);
            if (_claims.Any(c => c == null))
                return new ClaimStateSnapshot(id, day, ClaimStateStatus.InvalidRecords);
            var scoped = _claims.Where(c => c.IsActive && c.ClaimantClanId == id).ToList();
            if (scoped.Any(c => string.IsNullOrWhiteSpace(c.ClaimId) || string.IsNullOrWhiteSpace(c.TargetTitleId)
                || !Enum.IsDefined(typeof(FeudalClaimStrength), c.Strength)
                || float.IsNaN(c.CreatedDay) || float.IsInfinity(c.CreatedDay) || c.CreatedDay < 0 || c.CreatedDay > day
                || float.IsNaN(c.ExpiresDay) || float.IsInfinity(c.ExpiresDay))
                || scoped.GroupBy(c => c.ClaimId, StringComparer.Ordinal).Any(g => g.Count() > 1))
                return new ClaimStateSnapshot(id, day, ClaimStateStatus.InvalidRecords);
            var active = scoped.Where(IsClaimCurrentlyActive).OrderBy(c => c.ClaimId, StringComparer.Ordinal).ToList();
            if (active.Count > ClaimStateSnapshot.MaximumClaims)
                return new ClaimStateSnapshot(id, day, ClaimStateStatus.CapacityExceeded, active.Count);
            var copies = active.Select(c =>
            {
                ClaimTargetState target = ClaimTargetState.RecordsUnavailable;
                if (_titlesById != null)
                {
                    FeudalTitleRecord title;
                    if (!_titlesById.TryGetValue(c.TargetTitleId, out title) || title == null)
                        target = ClaimTargetState.Missing;
                    else if (title.TitleId != c.TargetTitleId)
                        return null;
                    else
                        target = title.IsDeliberatelyDissolved ? ClaimTargetState.Dissolved
                            : title.IsActive ? ClaimTargetState.Active : ClaimTargetState.Inactive;
                }
                return new ClaimRecordSnapshot(c, target);
            }).ToList();
            if (copies.Any(c => c == null))
                return new ClaimStateSnapshot(id, day, ClaimStateStatus.InvalidRecords);
            return new ClaimStateSnapshot(id, day, ClaimStateStatus.Recorded, active.Count, copies);
        }
    }
}
