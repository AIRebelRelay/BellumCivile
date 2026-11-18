using System;
using System.Collections.Generic;
using System.Linq;
using TaleWorlds.CampaignSystem;

namespace BellumCivile
{
    /// <summary>A saved realm-preparation fact, not proof of peace, settlement or awareness.</summary>
    public sealed class RealmPreparationReceipt
    {
        public string ReceiptId { get; }
        public double CompletedDay { get; }
        public string ParentRealmId { get; }
        public string SourceRealmId { get; }
        public string SuccessorRealmId { get; }
        public string FounderHouseId { get; }
        public string RulingHouseId { get; }
        public string RulerHeroId { get; }
        public bool WasReplacement { get; }
        public string ChallengeId { get; }

        internal RealmPreparationReceipt(RestoredRealmCreationRecord r)
        {
            ReceiptId = r.PreparationReceiptId;
            CompletedDay = r.PreparationDay;
            ParentRealmId = r.PreparationParentId;
            SourceRealmId = r.PreparationSourceId;
            SuccessorRealmId = r.PreparationSuccessorId;
            FounderHouseId = r.PreparationFounderHouseId;
            RulingHouseId = r.PreparationRulingHouseId;
            RulerHeroId = r.PreparationRulerHeroId ?? string.Empty;
            WasReplacement = r.PreparationWasReplacement;
            ChallengeId = r.PreparationChallengeId ?? string.Empty;
        }
    }

    public enum RealmPreparationStateStatus { Recorded, NotRecorded, BehaviorUnavailable, InvalidRecords }

    public sealed class RealmPreparationStateSnapshot
    {
        public const int ApiVersion = 1;
        public double CapturedDay { get; }
        public RealmPreparationStateStatus Status { get; }
        public IReadOnlyList<RealmPreparationReceipt> Receipts { get; }
        public int UndatedReadyCount { get; }
        public int PendingCount { get; }
        public int OmittedCount { get; }

        internal RealmPreparationStateSnapshot(double day, RealmPreparationStateStatus status,
            IEnumerable<RealmPreparationReceipt> receipts = null, int undated = 0, int pending = 0, int omitted = 0)
        {
            CapturedDay = day;
            Status = status;
            Receipts = (receipts ?? Enumerable.Empty<RealmPreparationReceipt>()).ToList().AsReadOnly();
            UndatedReadyCount = undated;
            PendingCount = pending;
            OmittedCount = omitted;
        }
    }

    internal static class RealmPreparationReceiptCapture
    {
        internal static bool ValidId(string id) => !string.IsNullOrWhiteSpace(id) && id.Length <= 1024;
        internal static bool ValidDay(double day) => !double.IsNaN(day) && !double.IsInfinity(day) && day >= 0;

        // Called only at the new false->true Ready transition, never while reading old saves.
        internal static bool TryStamp(RestoredRealmCreationRecord r)
        {
            if (r == null || !r.Ready || !string.IsNullOrEmpty(r.PreparationReceiptId) || HasPartialStamp(r)) return false;
            try
            {
                double day = CampaignTime.Now.ToDays;
                string parent = r.Parent?.StringId, source = r.Source?.StringId;
                string successor = r.Successor?.StringId, founder = r.Founder?.StringId;
                var ruling = r.Successor?.RulingClan;
                string house = ruling?.StringId;
                var hero = r.Successor?.Leader;
                string ruler = hero?.IsAlive == true && ruling?.Leader == hero ? hero.StringId : string.Empty;
                string challenge = r.Challenge?.Id ?? string.Empty;
                if (!ValidDay(day) || !ValidId(parent) || !ValidId(source) || !ValidId(successor)
                    || successor != r.SuccessorId || !ValidId(founder) || !ValidId(house)
                    || (ruler.Length != 0 && !ValidId(ruler)) || (challenge.Length != 0 && !ValidId(challenge))) return false;
                string id = Guid.NewGuid().ToString("N");
                // All reads/validation/allocation precede primitive field writes. ID is the final marker.
                r.PreparationDay = day;
                r.PreparationParentId = parent;
                r.PreparationSourceId = source;
                r.PreparationSuccessorId = successor;
                r.PreparationFounderHouseId = founder;
                r.PreparationRulingHouseId = house;
                r.PreparationRulerHeroId = ruler;
                r.PreparationWasReplacement = r.Replacement;
                r.PreparationChallengeId = challenge;
                r.PreparationReceiptId = id;
                return true;
            }
            catch { return false; }
        }

        internal static bool IsValid(RestoredRealmCreationRecord r, double day)
        {
            Guid id;
            return r.Ready && Guid.TryParseExact(r.PreparationReceiptId, "N", out id) && id != Guid.Empty
                && r.PreparationReceiptId == id.ToString("N")
                && ValidDay(r.PreparationDay) && r.PreparationDay <= day
                && ValidId(r.PreparationParentId) && ValidId(r.PreparationSourceId)
                && ValidId(r.PreparationSuccessorId) && ValidId(r.PreparationFounderHouseId)
                && ValidId(r.PreparationRulingHouseId)
                && (string.IsNullOrEmpty(r.PreparationRulerHeroId) || ValidId(r.PreparationRulerHeroId))
                && (string.IsNullOrEmpty(r.PreparationChallengeId) || ValidId(r.PreparationChallengeId));
        }

        internal static bool HasPartialStamp(RestoredRealmCreationRecord r) => r.PreparationDay != 0
            || r.PreparationParentId != null || r.PreparationSourceId != null || r.PreparationSuccessorId != null
            || r.PreparationFounderHouseId != null || r.PreparationRulingHouseId != null
            || r.PreparationRulerHeroId != null || r.PreparationWasReplacement || r.PreparationChallengeId != null;
    }
}
