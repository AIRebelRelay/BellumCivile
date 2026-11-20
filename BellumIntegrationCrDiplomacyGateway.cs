using System;
using System.Linq;
using BellumCivile.Behaviors;
using TaleWorlds.CampaignSystem;

namespace BellumCivile
{
    // CR integration boundary: detached truth, exactly one Bellum treaty writer.
    // This facade does not interpret LLM text: the Bridge validates BOTH responses.
    // A provenance-bound Royal Accord grants sovereign authority; Bellum still enforces world safety.
    public sealed class CrForeignPeaceSnapshot
    {
        public string Status { get; }
        public string ConflictInstanceId { get; }
        public string AttackerId { get; }
        public string DefenderId { get; }
        public float WarScore { get; }
        public bool CanSuggest { get; }
        internal CrForeignPeaceSnapshot(string status, WarScoreRecord war = null, bool canSuggest = false)
        {
            Status = status;
            ConflictInstanceId = war?.ConflictInstanceId;
            AttackerId = war?.AttackerKingdomId;
            DefenderId = war?.DefenderKingdomId;
            WarScore = war?.Score ?? 0f;
            CanSuggest = status == "Ready" && canSuggest;
        }
    }

    public sealed class CrForeignTreatyReceipt
    {
        public string Status { get; }
        public string ProposalId { get; }
        public string ConflictInstanceId { get; }
        public string AttackerId { get; }
        public string DefenderId { get; }
        internal CrForeignTreatyReceipt(string status, string proposalId = null,
            string instanceId = null, string attackerId = null, string defenderId = null)
        {
            Status = status; ProposalId = proposalId; ConflictInstanceId = instanceId;
            AttackerId = attackerId; DefenderId = defenderId;
        }
    }

    public static partial class BellumIntegration
    {
        public const int CrDiplomacyGatewayApiVersion = 2;

        /// <summary>Passive eligibility; game thread. Never an approval or an offer.</summary>
        public static CrForeignPeaceSnapshot ReadCrForeignPeaceWar(Kingdom first, Kingdom second)
        {
            BellumIntegrationBehavior.RequireCampaignThread();
            WarScoreRecord war;
            string problem = ResolveCrForeignWar(first, second, out war);
            if (problem != null) return new CrForeignPeaceSnapshot(problem);
            // Automated Bellum reconsideration cadence is not a veto on a NEW LLM
            // decision. Exact war, ruler, player and Native-witness gates still apply.
            return new CrForeignPeaceSnapshot("Ready", war, canSuggest: true);
        }

        /// <summary>
        /// After BOTH validated NPC rulers assent to an exact war, queue a provenance-bound,
        /// non-forced Royal Accord. It bypasses ONLY automatic willingness/council vetoes.
        /// Treaty execution, story/alliance protection, exact identity and save safety remain
        /// solely Bellum's responsibility. Game thread; never a player realm.
        /// </summary>
        public static CrForeignTreatyReceipt TryQueueCrForeignWhitePeace(
            string conflictInstanceId, string firstRealmId, string secondRealmId,
            string firstRulerId, string secondRulerId)
        {
            BellumIntegrationBehavior.RequireCampaignThread();
            if (!CanonicalCrId(conflictInstanceId)) return new CrForeignTreatyReceipt("InvalidInstance");
            Kingdom first = Kingdom.All?.FirstOrDefault(k => k?.StringId == firstRealmId);
            Kingdom second = Kingdom.All?.FirstOrDefault(k => k?.StringId == secondRealmId);
            WarScoreRecord war;
            string problem = ResolveCrForeignWar(first, second, out war);
            if (problem != null) return new CrForeignTreatyReceipt(problem);
            if (!string.Equals(war.ConflictInstanceId, conflictInstanceId, StringComparison.Ordinal))
                return new CrForeignTreatyReceipt("StaleInstance");
            if (first?.RulingClan?.Leader == null || second?.RulingClan?.Leader == null
                || first.RulingClan.Leader.StringId != firstRulerId
                || second.RulingClan.Leader.StringId != secondRulerId)
                return new CrForeignTreatyReceipt("RulerChanged");
            ForeignTreatyBehavior treaties = Campaign.Current.GetCampaignBehavior<ForeignTreatyBehavior>();
            if (treaties == null) return new CrForeignTreatyReceipt("TreatyBehaviorUnavailable");
            // Existing pending proposals may belong to another origin. Never hijack or relabel them.
            if (treaties.GetProposals().Any(p => p != null && p.WarKey == war.WarKey
                && p.State == TreatyProposalState.ParleyPending))
                return new CrForeignTreatyReceipt("AlreadyPending");
            // Normal/non-forced. Exact two-ruler consent is politically authoritative,
            // NOT a terminal or automatically approved AI war-will draft.
            // All mechanical legality and the normal Bellum executor stay active.
            bool queued = treaties.TryQueueCrRoyalAccordParley(war, first,
                firstRulerId, secondRulerId, out string report);
            if (!queued)
            {
                BellumCivileLogger.Log($"BELLUM_CR_DIPLOMACY status=rejected; instance={conflictInstanceId}; reason={report}");
                return new CrForeignTreatyReceipt("BellumRejected");
            }
            var matches = treaties.GetProposals().Where(p => p != null
                && p.WarKey == war.WarKey && p.BoundConflictInstanceId == conflictInstanceId
                && p.State == TreatyProposalState.ParleyPending && !p.IsForced
                && p.IsCrRoyalAccord && p.IsExplicitWhitePeace).ToList();
            if (matches.Count != 1)
            {
                // Unknown after a possible side effect: caller MUST reconcile, never retry blindly.
                BellumCivileLogger.Log($"BELLUM_CR_DIPLOMACY status=unknown_after_queue; instance={conflictInstanceId}; matching={matches.Count}");
                return new CrForeignTreatyReceipt("UnknownAfterQueue");
            }
            var proposal = matches[0];
            BellumCivileLogger.Log($"BELLUM_CR_DIPLOMACY status=queued; instance={conflictInstanceId}; proposal={proposal.ProposalId}; royal_accord=true; forced=false; terms=white_peace");
            return new CrForeignTreatyReceipt("Queued", proposal.ProposalId, conflictInstanceId,
                war.AttackerKingdomId, war.DefenderKingdomId);
        }

        /// <summary>Detached terminal receipt. Works after war ends; never pair-falls-back.</summary>
        public static CrForeignTreatyReceipt ReadCrForeignTreatyReceipt(string proposalId, string conflictInstanceId)
        {
            BellumIntegrationBehavior.RequireCampaignThread();
            if (!CanonicalCrId(conflictInstanceId) || !CanonicalCrId(proposalId))
                return new CrForeignTreatyReceipt("InvalidRequest");
            ForeignTreatyBehavior behavior = Campaign.Current.GetCampaignBehavior<ForeignTreatyBehavior>();
            if (behavior == null) return new CrForeignTreatyReceipt("TreatyBehaviorUnavailable");
            var matches = behavior.GetProposals().Where(row => row != null && row.ProposalId == proposalId).ToList();
            if (matches.Count != 1) return new CrForeignTreatyReceipt(matches.Count == 0 ? "NotFound" : "Ambiguous");
            var p = matches[0];
            if (p.BoundConflictInstanceId != conflictInstanceId)
                return new CrForeignTreatyReceipt("StaleInstance");
            return new CrForeignTreatyReceipt(p.State.ToString(), p.ProposalId,
                p.BoundConflictInstanceId, p.WinnerKingdomId, p.LoserKingdomId);
        }

        private static bool CanonicalCrId(string id)
        {
            Guid parsed;
            return id != null && id.Length == 32 && Guid.TryParseExact(id, "N", out parsed)
                && parsed != Guid.Empty && string.Equals(parsed.ToString("N"), id, StringComparison.Ordinal);
        }

        private static string ResolveCrForeignWar(Kingdom first, Kingdom second, out WarScoreRecord war)
        {
            war = null;
            if (Campaign.Current == null || !WarPeaceRevampBehavior.IsRevampEnabled()) return "RevampUnavailable";
            if (first == null || second == null || first == second || first.IsEliminated || second.IsEliminated
                || !Kingdom.All.Contains(first) || !Kingdom.All.Contains(second)) return "InvalidRealm";
            if (WarPeaceRevampBehavior.IsPlayerPoliticalParticipant(first, second)
                || Clan.PlayerClan?.Kingdom == first || Clan.PlayerClan?.Kingdom == second)
                return "PlayerRealmExcluded";
            if (first.RulingClan?.Leader == null || second.RulingClan?.Leader == null
                || first.RulingClan.Leader.IsDead || second.RulingClan.Leader.IsDead)
                return "RulerUnavailable";
            if (!first.IsAtWarWith(second) || !second.IsAtWarWith(first)) return "NotAtWar";
            WarScoreBehavior scores = Campaign.Current.GetCampaignBehavior<WarScoreBehavior>();
            if (scores == null) return "WarScoreUnavailable";
            string key = WarScoreRecord.PairKey(first.StringId, second.StringId);
            var candidates = scores.GetActiveWars().Where(w => w != null && w.WarKey == key).ToList();
            if (candidates.Count != 1) return "AmbiguousWar";
            var candidate = candidates[0];
            if (candidate.ConflictType != WarScoreConflictType.ForeignWar || !CanonicalCrId(candidate.ConflictInstanceId)
                || candidate.NativeForeignDeclarationAmbiguous) return "InvalidWarIdentity";
            if (candidate.ParleyPending || candidate.ResolutionPending || candidate.TerminalResolutionQueued)
                return "WarResolutionPending";
            var identity = scores.GetExistingForeignConflictByInstance(candidate.ConflictInstanceId,
                candidate.AttackerKingdomId, candidate.DefenderKingdomId, CampaignTime.Now.ToDays);
            if (identity?.Status != ForeignConflictIdentityStatus.RecordedActive
                || identity.Record?.InstanceId != candidate.ConflictInstanceId) return "StaleWarIdentity";
            // A matching Native timestamp is only corroboration, never sovereign authority.
            var witness = scores.ObserveForeignWarNativeWitness(candidate.ConflictInstanceId,
                candidate.AttackerKingdomId, candidate.DefenderKingdomId, CampaignTime.Now.ToDays);
            if (witness.IdentityStatus != ForeignConflictIdentityStatus.RecordedActive
                || witness.WitnessStatus != ForeignWarNativeWitnessStatus.WeakTimestampMatchNotProof)
                return "UnwitnessedOrAmbiguous";
            war = candidate;
            return null;
        }
    }
}
