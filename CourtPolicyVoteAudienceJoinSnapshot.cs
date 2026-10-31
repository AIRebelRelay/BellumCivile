using System.Collections.Generic;

namespace BellumCivile
{
    // Historical audience of one *verified* Native Court policy vote, not world-public.
    // Hero.StringId is captured at vote resolution, never derived from the later realm roster.
    public sealed class CourtPolicyVoteAudienceRecipientSnapshot
    {
        public string Id { get; }
        public string RealmId { get; }
        public string PolicyId { get; }
        public string SponsorId { get; }
        public string Audience { get; }
        public double VoteDay { get; }
        public IReadOnlyList<string> HeroIds { get; }

        internal CourtPolicyVoteAudienceRecipientSnapshot(string id, string realmId,
            string policyId, string sponsorId, double voteDay, IReadOnlyList<string> heroIds)
        {
            Id = id;
            RealmId = realmId;
            PolicyId = policyId;
            SponsorId = sponsorId;
            VoteDay = voteDay;
            Audience = "realm_court";
            HeroIds = new List<string>(heroIds).AsReadOnly();
        }
    }

    // A missing audience on a legacy result holds only that result. Corrupt/overflowed
    // audience evidence or unhealthy Stage31L provenance holds the entire projection.
    public sealed class CourtPolicyVoteAudienceJoinSnapshot
    {
        public string RealmId { get; }
        public bool SourceAvailable { get; }
        public bool SourceJoinHealthy { get; }
        public IReadOnlyList<CourtPolicyVoteAudienceRecipientSnapshot> Matched { get; }
        public int AudienceStored { get; }
        public int AudienceInvalidCount { get; }
        public int AudienceOverflowCount { get; }
        public int ConflictCount { get; }
        public int MissingAudienceCount { get; }
        public bool IsHealthy => SourceAvailable && SourceJoinHealthy
            && AudienceInvalidCount == 0 && AudienceOverflowCount == 0
            && ConflictCount == 0;

        internal CourtPolicyVoteAudienceJoinSnapshot(string realmId, bool sourceAvailable,
            bool sourceJoinHealthy, IReadOnlyList<CourtPolicyVoteAudienceRecipientSnapshot> matched,
            int audienceStored, int invalidCount, int overflowCount,
            int conflictCount, int missingAudienceCount)
        {
            RealmId = realmId;
            SourceAvailable = sourceAvailable;
            SourceJoinHealthy = sourceJoinHealthy;
            Matched = matched;
            AudienceStored = audienceStored;
            AudienceInvalidCount = invalidCount;
            AudienceOverflowCount = overflowCount;
            ConflictCount = conflictCount;
            MissingAudienceCount = missingAudienceCount;
        }

        internal static CourtPolicyVoteAudienceJoinSnapshot Unavailable(string realmId)
            => new CourtPolicyVoteAudienceJoinSnapshot(realmId, false, false,
                new List<CourtPolicyVoteAudienceRecipientSnapshot>().AsReadOnly(),
                0, 0, 0, 0, 0);
    }
}
