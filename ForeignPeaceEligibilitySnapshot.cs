using System;
using System.Collections.Generic;

namespace BellumCivile
{
    // Detached, non-saveable data. A preview is NEVER a vote, treaty or settlement receipt.
    public enum ForeignPeaceLegality
    {
        Unknown = 0,
        AllowedToPropose = 1,
        Blocked = 2
    }

    public enum ForeignPeaceExecutionReadiness
    {
        Unknown = 0,
        NotReady = 1,
        Ready = 2
    }

    public enum ForeignPeaceReplyOwner
    {
        Unknown = 0,
        Npc = 1,
        Player = 2
    }

    public enum ForeignPeaceWarTracking
    {
        Unknown = 0,
        UntrackedForeignWar = 1,
        TrackedForeignWar = 2,
        TrackedOtherConflict = 3,
        AccountingOnlyForeignWar = 4
    }

    public sealed class ForeignPeaceEligibilitySnapshot
    {
        public string ActorHeroId { get; }
        public string SourceKingdomId { get; }
        public string TargetKingdomId { get; }
        public float GameDay { get; }
        public ForeignPeaceLegality Legality { get; }
        public ForeignPeaceExecutionReadiness ExecutionReadiness { get; }
        public ForeignPeaceReplyOwner ReplyOwner { get; }
        public ForeignPeaceWarTracking WarTracking { get; }
        public string WarKey { get; }
        public float? WarScore { get; }
        public int? WarScoreRuntimeRevision { get; }
        public int? ClientRuntimeRevision { get; }
        public IReadOnlyList<string> ReasonCodes { get; }

        // An eligibility preview cannot authorize diplomatic state changes.
        public bool MayExecuteImmediately => false;

        internal ForeignPeaceEligibilitySnapshot(
            string actorHeroId, string sourceKingdomId, string targetKingdomId,
            float gameDay, ForeignPeaceLegality legality,
            ForeignPeaceExecutionReadiness executionReadiness,
            ForeignPeaceReplyOwner replyOwner, ForeignPeaceWarTracking warTracking,
            string warKey, float? warScore, int? warScoreRuntimeRevision,
            int? clientRuntimeRevision, IEnumerable<string> reasonCodes)
        {
            ActorHeroId = actorHeroId;
            SourceKingdomId = sourceKingdomId;
            TargetKingdomId = targetKingdomId;
            GameDay = gameDay;
            Legality = legality;
            ExecutionReadiness = executionReadiness;
            ReplyOwner = replyOwner;
            WarTracking = warTracking;
            WarKey = warKey;
            WarScore = warScore;
            WarScoreRuntimeRevision = warScoreRuntimeRevision;
            ClientRuntimeRevision = clientRuntimeRevision;
            ReasonCodes = new List<string>(reasonCodes ?? new string[0]).AsReadOnly();
        }
    }

    internal sealed class ForeignPeaceWarRead
    {
        internal ForeignPeaceWarTracking Tracking { get; }
        internal string WarKey { get; }
        internal float? Score { get; }
        internal int? Revision { get; }

        internal ForeignPeaceWarRead(
            ForeignPeaceWarTracking tracking, string warKey, float? score, int? revision)
        {
            Tracking = tracking;
            WarKey = warKey;
            Score = score;
            Revision = revision;
        }
    }

    internal enum ForeignPeaceClientRead
    {
        Unknown = 0,
        Clear = 1,
        Blocked = 2
    }
}
