using System.Collections.Generic;

namespace BellumCivile
{
    // Read-only Native evidence: a result and its source-authored realm-court
    // disclosure provenance agree. NOT world-public, Relay accepted or ACKed.
    public sealed class CourtPolicyVoteJoinedReceiptSnapshot
    {
        public string Id { get; }
        public string RealmId { get; }
        public string PolicyId { get; }
        public string SponsorId { get; }
        public string Action { get; }
        public string VoteOutcome { get; }
        public bool ObsoleteMandate { get; }
        public string Audience { get; }
        public double VoteDay { get; }
        public double ReceiptObservedDay { get; }

        internal CourtPolicyVoteJoinedReceiptSnapshot(string id, string realmId,
            string policyId, string sponsorId, string action, string voteOutcome,
            bool obsoleteMandate, double voteDay, double receiptObservedDay)
        {
            Id = id;
            RealmId = realmId;
            PolicyId = policyId;
            SponsorId = sponsorId;
            Action = action;
            VoteOutcome = voteOutcome;
            ObsoleteMandate = obsoleteMandate;
            Audience = "realm_court";
            VoteDay = voteDay;
            ReceiptObservedDay = receiptObservedDay;
        }
    }

    public sealed class CourtPolicyVoteProvenanceJoinSnapshot
    {
        public string RealmId { get; }
        public bool SourceAvailable { get; }
        public IReadOnlyList<CourtPolicyVoteJoinedReceiptSnapshot> Matched { get; }
        public int TerminalStored { get; }
        public int ProofStored { get; }
        public int TerminalInvalidCount { get; }
        public int ProofInvalidCount { get; }
        public int TerminalOverflowCount { get; }
        public int ProofOverflowCount { get; }
        public int ConflictCount { get; }
        public int MissingProofCount { get; }
        public int AwaitingEvictionCount { get; }
        public bool IsHealthy => SourceAvailable && TerminalInvalidCount == 0
            && ProofInvalidCount == 0 && TerminalOverflowCount == 0
            && ProofOverflowCount == 0 && ConflictCount == 0;

        internal CourtPolicyVoteProvenanceJoinSnapshot(string realmId, bool sourceAvailable,
            IReadOnlyList<CourtPolicyVoteJoinedReceiptSnapshot> matched,
            int terminalStored, int proofStored, int terminalInvalid,
            int proofInvalid, int terminalOverflow, int proofOverflow,
            int conflict, int missingProof, int awaitingEviction)
        {
            RealmId = realmId;
            SourceAvailable = sourceAvailable;
            Matched = matched;
            TerminalStored = terminalStored;
            ProofStored = proofStored;
            TerminalInvalidCount = terminalInvalid;
            ProofInvalidCount = proofInvalid;
            TerminalOverflowCount = terminalOverflow;
            ProofOverflowCount = proofOverflow;
            ConflictCount = conflict;
            MissingProofCount = missingProof;
            AwaitingEvictionCount = awaitingEviction;
        }

        internal static CourtPolicyVoteProvenanceJoinSnapshot Unavailable(string realmId)
            => new CourtPolicyVoteProvenanceJoinSnapshot(realmId, false,
                new List<CourtPolicyVoteJoinedReceiptSnapshot>().AsReadOnly(),
                0, 0, 0, 0, 0, 0, 0, 0, 0);
    }
}
