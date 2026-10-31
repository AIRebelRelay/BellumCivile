using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Text;
using BellumCivile.Patches;
using TaleWorlds.CampaignSystem;
using TaleWorlds.CampaignSystem.Election;

namespace BellumCivile.Behaviors
{
    public sealed partial class CourtAgendaBehavior
    {
        // Never infer historical Court recipients from today's realm or faction membership.
        // This ledger is an inert Native save record, not an event, ACK or NPC memory write.
        private const int MaxCourtPolicyVoteAudience = 1024;
        private const int MaxPolicyVoteAudienceHeroes = 256;
        private Dictionary<string, string> _courtPolicyVoteAudience = new Dictionary<string, string>();
        private int _courtPolicyVoteAudienceOverflow;

        private void SyncCourtPolicyVoteAudience(IDataStore store)
        {
            store.SyncData("BC_CourtPolicyVoteAudience_v1", ref _courtPolicyVoteAudience);
            store.SyncData("BC_CourtPolicyVoteAudienceOverflow_v1", ref _courtPolicyVoteAudienceOverflow);
            _courtPolicyVoteAudience = _courtPolicyVoteAudience
                ?? new Dictionary<string, string>();
        }

        // Called once from the *actual* KingdomPolicyDecision.ApplyChosenOutcome postfix,
        // after Conclude has authored the independent Stage31K vote provenance.
        // It uses the already captured pre-resolution ballot, not today's realm roster.
        internal void CapturePolicyVoteAudience(KingdomPolicyDecision decision, bool passed)
        {
            try
            {
                Kingdom realm = decision?.Kingdom;
                PolicyObject policy = decision?.Policy;
                Clan sponsor = decision?.ProposerClan;
                if (!ValidRealm(realm) || policy == null || sponsor == null)
                {
                    LogPolicyAudienceHeld("missing_vote_identity");
                    return;
                }

                bool abolish = PolicyDeliberationBehavior.ResolvePolicyAbolish(decision);
                CourtAgendaRecord agenda = _agendas.LastOrDefault(a => a.Realm == realm
                    && a.PolicyId == policy.StringId && a.Sponsor == sponsor && a.Abolish == abolish
                    && a.IsPolicy && a.ResultApplied);
                if (agenda == null || string.IsNullOrWhiteSpace(agenda.IntegrationId)
                    || agenda.State != (passed ? CourtAgendaState.Passed : CourtAgendaState.Defeated)
                    || !string.IsNullOrEmpty(agenda.CancellationReason))
                {
                    LogPolicyAudienceHeld("missing_concluded_agenda");
                    return;
                }

                string source;
                VoteProof proof;
                if (!_courtPolicyVotePublicProvenance.TryGetValue(agenda.IntegrationId, out source)
                    || !TryReadVoteProof(agenda.IntegrationId, source, out proof)
                    || !string.Equals(proof.RealmId, realm.StringId, StringComparison.Ordinal)
                    || !string.Equals(proof.PolicyId, policy.StringId, StringComparison.Ordinal)
                    || !string.Equals(proof.SponsorId, sponsor.StringId, StringComparison.Ordinal)
                    || !string.Equals(proof.Action, abolish ? "repeal" : "enact", StringComparison.Ordinal)
                    || !string.Equals(proof.Outcome, passed ? "passed" : "defeated", StringComparison.Ordinal))
                {
                    LogPolicyAudienceHeld("missing_or_mismatched_native_vote_proof");
                    return;
                }

                // Conclude writes the proof synchronously in this resolution call.
                // An older ResultApplied agenda with the same realm/policy/sponsor
                // must never inherit a new ballot just because its proof still exists.
                if (proof.VoteDay != CampaignTime.Now.ToDays)
                {
                    LogPolicyAudienceHeld("stale_or_foreign_vote_proof");
                    return;
                }

                if (_courtPolicyVoteAudience.ContainsKey(agenda.IntegrationId))
                    return; // Idempotent. Never rewrite historical membership.

                IReadOnlyList<Clan> participants;
                if (!KingdomVoteAlignmentTracker.TryGetRecordedParticipants(decision, out participants))
                {
                    LogPolicyAudienceHeld("missing_recorded_ballot");
                    return;
                }

                var heroIds = new HashSet<string>(StringComparer.Ordinal);
                foreach (Clan voter in participants)
                {
                    // Each captured voter must be a current *mechanical* participant
                    // at conclusion. Unknown/duplicate identities make the whole roster unsafe.
                    if (!Eligible(voter, realm) || voter.Leader.IsDead
                        || string.IsNullOrWhiteSpace(voter.Leader.StringId)
                        || !heroIds.Add(voter.Leader.StringId))
                    {
                        LogPolicyAudienceHeld("invalid_or_ambiguous_ballot_actor");
                        return;
                    }
                }

                if (heroIds.Count == 0)
                {
                    LogPolicyAudienceHeld("empty_ballot");
                    return;
                }
                if (heroIds.Count > MaxPolicyVoteAudienceHeroes)
                {
                    IncrementPolicyAudienceOverflow("recipient_limit");
                    return;
                }

                // v1: version | realm64 | policy64 | sponsor64 | vote-day | comma-delimited hero-id64.
                // Every exact hero ID is encoded separately; no names/roles/rumors in ACL data.
                string[] sorted = heroIds.OrderBy(id => id, StringComparer.Ordinal).ToArray();
                string payload = string.Join("|", new[]
                {
                    "v1",
                    EncodeAudienceField(realm.StringId),
                    EncodeAudienceField(policy.StringId),
                    EncodeAudienceField(sponsor.StringId),
                    proof.VoteDay.ToString("R", CultureInfo.InvariantCulture),
                    string.Join(",", sorted.Select(EncodeAudienceField))
                });

                if (payload.Length > 16384 || _courtPolicyVoteAudience.Count >= MaxCourtPolicyVoteAudience)
                {
                    IncrementPolicyAudienceOverflow("ledger_or_payload_limit");
                    return;
                }
                _courtPolicyVoteAudience.Add(agenda.IntegrationId, payload);
                BellumCivileLogger.Log("BC_COURT_POLICY_AUDIENCE status=recorded"
                    + "; id=" + agenda.IntegrationId + "; realm=" + realm.StringId
                    + "; count=" + sorted.Length.ToString(CultureInfo.InvariantCulture)
                    + "; result=" + proof.Outcome
                    + "; audience=realm_court; relay_emitted=false; npc_memory_mutated=false");
            }
            catch (Exception ex)
            {
                LogPolicyAudienceHeld("capture_exception_" + ex.GetType().Name);
            }
        }

        // Only join a captured historical audience to a Stage31L verified terminal
        // receipt. Without BOTH proofs, this API returns no authorized NPC IDs.
        internal CourtPolicyVoteAudienceJoinSnapshot GetPolicyVoteAudienceJoin(Kingdom realm)
        {
            if (realm == null || string.IsNullOrWhiteSpace(realm.StringId))
                return CourtPolicyVoteAudienceJoinSnapshot.Unavailable(realm?.StringId);

            CourtPolicyVoteProvenanceJoinSnapshot joined = GetPolicyVoteProvenanceJoin(realm);
            if (joined == null || !joined.SourceAvailable || _courtPolicyVoteAudience == null)
                return CourtPolicyVoteAudienceJoinSnapshot.Unavailable(realm.StringId);

            int invalid = 0;
            int conflicts = 0;
            int missingAudience = 0;
            var audiences = new Dictionary<string, PolicyVoteAudienceRecord>(StringComparer.Ordinal);
            foreach (var pair in _courtPolicyVoteAudience.OrderBy(p => p.Key, StringComparer.Ordinal))
            {
                PolicyVoteAudienceRecord candidate;
                if (!TryDecodePolicyVoteAudience(pair.Key, pair.Value, out candidate))
                {
                    invalid++;
                    continue;
                }
                audiences.Add(pair.Key, candidate);
            }

            var matched = new List<CourtPolicyVoteAudienceRecipientSnapshot>();
            foreach (CourtPolicyVoteJoinedReceiptSnapshot receipt in joined.Matched)
            {
                PolicyVoteAudienceRecord audience;
                if (!audiences.TryGetValue(receipt.Id, out audience))
                {
                    missingAudience++; // Legacy save: hold just this result, no retroactive guesses.
                    continue;
                }
                if (!string.Equals(receipt.RealmId, audience.RealmId, StringComparison.Ordinal)
                    || !string.Equals(receipt.PolicyId, audience.PolicyId, StringComparison.Ordinal)
                    || !string.Equals(receipt.SponsorId, audience.SponsorId, StringComparison.Ordinal)
                    || !string.Equals(receipt.Audience, "realm_court", StringComparison.Ordinal)
                    || receipt.VoteDay != audience.VoteDay)
                {
                    conflicts++;
                    continue;
                }
                matched.Add(new CourtPolicyVoteAudienceRecipientSnapshot(receipt.Id,
                    receipt.RealmId, receipt.PolicyId, receipt.SponsorId,
                    receipt.VoteDay, audience.HeroIds));
            }

            if (!joined.IsHealthy || invalid != 0 || conflicts != 0
                || _courtPolicyVoteAudienceOverflow != 0)
                matched.Clear();

            return new CourtPolicyVoteAudienceJoinSnapshot(realm.StringId,
                joined.SourceAvailable, joined.IsHealthy, matched.AsReadOnly(),
                _courtPolicyVoteAudience.Count, invalid, _courtPolicyVoteAudienceOverflow,
                conflicts, missingAudience);
        }

        private sealed class PolicyVoteAudienceRecord
        {
            internal string RealmId;
            internal string PolicyId;
            internal string SponsorId;
            internal double VoteDay;
            internal IReadOnlyList<string> HeroIds;
        }

        private static bool TryDecodePolicyVoteAudience(string id, string payload,
            out PolicyVoteAudienceRecord audience)
        {
            audience = null;
            Guid parsed;
            if (!Guid.TryParseExact(id, "N", out parsed)
                || string.IsNullOrWhiteSpace(payload) || payload.Length > 16384)
                return false;

            string[] fields = payload.Split('|');
            if (fields.Length != 6 || !string.Equals(fields[0], "v1", StringComparison.Ordinal))
                return false;

            var strictUtf8 = new UTF8Encoding(false, true);
            string realm, policy, sponsor;
            var ids = new List<string>();
            try
            {
                realm = DecodeAudienceField(fields[1], strictUtf8);
                policy = DecodeAudienceField(fields[2], strictUtf8);
                sponsor = DecodeAudienceField(fields[3], strictUtf8);
                string[] encodedIds = fields[5].Split(',');
                if (encodedIds.Length == 0 || encodedIds.Length > MaxPolicyVoteAudienceHeroes)
                    return false;
                string previous = null;
                foreach (string encoded in encodedIds)
                {
                    string heroId = DecodeAudienceField(encoded, strictUtf8);
                    if (string.IsNullOrWhiteSpace(heroId)
                        || previous != null && string.CompareOrdinal(previous, heroId) >= 0)
                        return false; // duplicate or non-canonical order
                    ids.Add(heroId);
                    previous = heroId;
                }
            }
            catch (FormatException) { return false; }
            catch (DecoderFallbackException) { return false; }

            double voteDay;
            if (string.IsNullOrWhiteSpace(realm) || string.IsNullOrWhiteSpace(policy)
                || string.IsNullOrWhiteSpace(sponsor)
                || !double.TryParse(fields[4], NumberStyles.Float,
                    CultureInfo.InvariantCulture, out voteDay)
                || double.IsNaN(voteDay) || double.IsInfinity(voteDay) || voteDay < 0)
                return false;

            audience = new PolicyVoteAudienceRecord
            {
                RealmId = realm, PolicyId = policy, SponsorId = sponsor,
                VoteDay = voteDay, HeroIds = ids.AsReadOnly()
            };
            return true;
        }

        private static string EncodeAudienceField(string value)
            => Convert.ToBase64String(Encoding.UTF8.GetBytes(value ?? string.Empty));

        private static string DecodeAudienceField(string encoded, UTF8Encoding strictUtf8)
        {
            if (encoded == null || encoded.Length > 8192)
                throw new FormatException("Audience identity field is too long");
            string decoded = strictUtf8.GetString(Convert.FromBase64String(encoded));
            if (decoded.Length > 2048)
                throw new FormatException("Audience identity exceeds bound");
            return decoded;
        }

        private void IncrementPolicyAudienceOverflow(string reason)
        {
            if (_courtPolicyVoteAudienceOverflow < int.MaxValue)
                _courtPolicyVoteAudienceOverflow++;
            BellumCivileLogger.Log("BC_COURT_POLICY_AUDIENCE status=overflow; reason=" + reason
                + "; total_overflow=" + _courtPolicyVoteAudienceOverflow.ToString(CultureInfo.InvariantCulture)
                + "; relay_emitted=false");
        }

        private static void LogPolicyAudienceHeld(string reason) =>
            BellumCivileLogger.Log("BC_COURT_POLICY_AUDIENCE status=held; reason=" + reason
                + "; relay_emitted=false; npc_memory_mutated=false");
    }
}
