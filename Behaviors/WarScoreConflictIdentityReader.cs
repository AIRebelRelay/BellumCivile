using System;
using System.Linq;
using TaleWorlds.CampaignSystem;

namespace BellumCivile.Behaviors
{
    public sealed partial class WarScoreBehavior
    {
        private static bool ValidConflictRealmId(string id) => !string.IsNullOrWhiteSpace(id)
            && id.Length <= 128 && id == id.Trim() && !id.Any(char.IsControl);

        // Passive only: no Ensure*, reconciliation, mutation, allocation or mutable-record return.
        internal ForeignConflictIdentitySnapshot GetExistingForeignConflictByInstance(
            string instanceId, string primaryId, string opposingId, double day)
        {
            Guid parsed;
            if (!Guid.TryParseExact(instanceId, "N", out parsed) || parsed == Guid.Empty
                || parsed.ToString("N") != instanceId || !ValidConflictRealmId(primaryId)
                || !ValidConflictRealmId(opposingId) || primaryId == opposingId
                || double.IsNaN(day) || double.IsInfinity(day) || day < 0)
                return new ForeignConflictIdentitySnapshot(ForeignConflictIdentityStatus.InvalidRequest, day);
            if (_wars == null)
                return new ForeignConflictIdentitySnapshot(ForeignConflictIdentityStatus.UninitializedRecords, day);
            // Unknown identities, including corrupt historical rows, cannot establish global uniqueness.
            if (_wars.Any(w => w == null || w.ConflictInstanceId == null))
                return new ForeignConflictIdentitySnapshot(ForeignConflictIdentityStatus.InvalidRecords, day);
            var matches = _wars.Where(w => w.ConflictInstanceId == instanceId).Take(2).ToList();
            if (matches.Count > 1)
                return new ForeignConflictIdentitySnapshot(ForeignConflictIdentityStatus.Ambiguous, day);
            if (matches.Count == 0)
                return new ForeignConflictIdentitySnapshot(ForeignConflictIdentityStatus.NotFound, day);
            var record = matches[0];
            if (!Enum.IsDefined(typeof(WarScoreConflictType), record.ConflictType)
                || !ValidConflictRealmId(record.AttackerKingdomId) || !ValidConflictRealmId(record.DefenderKingdomId)
                || record.AttackerKingdomId == record.DefenderKingdomId
                || record.WarKey != WarScoreRecord.PairKey(record.AttackerKingdomId, record.DefenderKingdomId)
                || float.IsNaN(record.Score) || float.IsInfinity(record.Score) || Math.Abs(record.Score) > 100f
                || float.IsNaN(record.StartedDay) || float.IsInfinity(record.StartedDay)
                // Stored StartedDay is float (save field 4), while capture time is double.
                // The same instant can round upward in float; only reject a start that
                // is future at the precision actually retained in the saved record.
                || record.StartedDay < 0 || record.StartedDay > (float)day)
                return new ForeignConflictIdentitySnapshot(ForeignConflictIdentityStatus.InvalidRecords, day);
            if (record.ConflictType != WarScoreConflictType.ForeignWar)
                return new ForeignConflictIdentitySnapshot(ForeignConflictIdentityStatus.WrongConflictType, day);
            if (record.AttackerKingdomId != primaryId || record.DefenderKingdomId != opposingId)
                return new ForeignConflictIdentitySnapshot(ForeignConflictIdentityStatus.ParticipantMismatch, day);
            if (!record.IsActive)
                return new ForeignConflictIdentitySnapshot(ForeignConflictIdentityStatus.Ended, day);

            var primary = Kingdom.All.Where(k => k != null && k.StringId == primaryId).Take(2).ToList();
            var opposing = Kingdom.All.Where(k => k != null && k.StringId == opposingId).Take(2).ToList();
            if (primary.Count != 1 || opposing.Count != 1 || primary[0].IsEliminated || opposing[0].IsEliminated)
                return new ForeignConflictIdentitySnapshot(ForeignConflictIdentityStatus.RealmUnavailable, day);
            if (!primary[0].IsAtWarWith(opposing[0]) || !opposing[0].IsAtWarWith(primary[0]))
                return new ForeignConflictIdentitySnapshot(ForeignConflictIdentityStatus.NotAtWar, day);
            return new ForeignConflictIdentitySnapshot(ForeignConflictIdentityStatus.RecordedActive, day, record);
        }
    }
}
