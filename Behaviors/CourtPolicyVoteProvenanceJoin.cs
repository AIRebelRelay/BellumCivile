using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Text;
using TaleWorlds.CampaignSystem;

namespace BellumCivile.Behaviors
{
    public sealed partial class CourtAgendaBehavior
    {
        // Stage31L joins *existing saved maps* by stable IntegrationId. This is
        // deliberately not attached to GetObjective, Court ticks or UI notices.
        // Missing provenance means held, never retroactively authorized.
        internal CourtPolicyVoteProvenanceJoinSnapshot GetPolicyVoteProvenanceJoin(Kingdom realm)
        {
            if (realm == null || string.IsNullOrWhiteSpace(realm.StringId)
                || _courtTerminalReceipts == null || _courtPolicyVotePublicProvenance == null)
                return CourtPolicyVoteProvenanceJoinSnapshot.Unavailable(realm?.StringId);

            int proofInvalid = 0;
            int terminalInvalid = 0;
            int conflicts = 0;
            int missingProof = 0;
            var proofs = new Dictionary<string, VoteProof>(StringComparer.Ordinal);
            foreach (var pair in _courtPolicyVotePublicProvenance.OrderBy(pair => pair.Key, StringComparer.Ordinal))
            {
                VoteProof proof;
                if (!TryReadVoteProof(pair.Key, pair.Value, out proof))
                {
                    proofInvalid++;
                    continue;
                }
                proofs.Add(pair.Key, proof);
            }

            var matched = new List<CourtPolicyVoteJoinedReceiptSnapshot>();
            var matchedIds = new HashSet<string>(StringComparer.Ordinal);
            foreach (var pair in _courtTerminalReceipts.OrderBy(pair => pair.Key, StringComparer.Ordinal))
            {
                string payloadRealm;
                if (!TryReadCourtTerminalPayload(pair.Key, pair.Value, out payloadRealm))
                {
                    terminalInvalid++;
                    continue;
                }
                if (!string.Equals(payloadRealm, realm.StringId, StringComparison.Ordinal)) continue;

                string[] receiptFields;
                double receiptDay;
                if (!TryDecodeCourtVoteReceipt(pair.Value, out receiptFields, out receiptDay))
                {
                    terminalInvalid++;
                    continue;
                }

                VoteProof proof;
                if (!proofs.TryGetValue(pair.Key, out proof))
                {
                    if (string.Equals(receiptFields[4], "policy", StringComparison.Ordinal)
                        && (string.Equals(receiptFields[7], "Passed", StringComparison.Ordinal)
                            || string.Equals(receiptFields[7], "Defeated", StringComparison.Ordinal)))
                        missingProof++;
                    continue;
                }
                if (!TryMatchPolicyVote(receiptFields, receiptDay, proof))
                {
                    conflicts++;
                    continue;
                }

                matchedIds.Add(pair.Key);
                matched.Add(new CourtPolicyVoteJoinedReceiptSnapshot(
                    pair.Key, proof.RealmId, proof.PolicyId, proof.SponsorId,
                    proof.Action, proof.Outcome, proof.ObsoleteMandate,
                    proof.VoteDay, receiptDay));
            }

            int awaitingEviction = proofs.Values.Count(proof =>
                string.Equals(proof.RealmId, realm.StringId, StringComparison.Ordinal)
                && !matchedIds.Contains(proof.Id));

            // Conservative global health: one corrupt record or overflow in
            // either map must never produce an apparently publishable match.
            bool invalidOrOverflow = proofInvalid != 0 || terminalInvalid != 0 || conflicts != 0
                || _courtTerminalEvictionOverflow != 0
                || _courtPolicyVotePublicProvenanceOverflow != 0;
            if (invalidOrOverflow) matched.Clear();
            return new CourtPolicyVoteProvenanceJoinSnapshot(
                realm.StringId, true, matched.AsReadOnly(),
                _courtTerminalReceipts.Count, _courtPolicyVotePublicProvenance.Count,
                terminalInvalid, proofInvalid, _courtTerminalEvictionOverflow,
                _courtPolicyVotePublicProvenanceOverflow, conflicts, missingProof, awaitingEviction);
        }

        private sealed class VoteProof
        {
            internal string Id;
            internal string RealmId;
            internal string PolicyId;
            internal string SponsorId;
            internal string Action;
            internal string Outcome;
            internal bool ObsoleteMandate;
            internal double VoteDay;
        }

        private static bool TryReadVoteProof(string id, string payload, out VoteProof proof)
        {
            proof = null;
            Guid parsed;
            if (!Guid.TryParseExact(id, "N", out parsed)
                || string.IsNullOrWhiteSpace(payload) || payload.Length > 8192) return false;

            string[] proofFields = payload.Split('|');
            if (proofFields.Length != 10 || !string.Equals(proofFields[0], "v1", StringComparison.Ordinal))
                return false;

            var utf8 = new UTF8Encoding(false, true);
            var decoded = new string[4];
            try
            {
                for (int i = 1; i <= 3; i++)
                {
                    if (proofFields[i].Length > 8192) return false;
                    decoded[i] = utf8.GetString(Convert.FromBase64String(proofFields[i]));
                    if (decoded[i].Length > 2048) return false;
                }
            }
            catch (FormatException) { return false; }
            catch (DecoderFallbackException) { return false; }

            double voteDay;
            if (!double.TryParse(proofFields[9], NumberStyles.Float, CultureInfo.InvariantCulture, out voteDay)
                || double.IsNaN(voteDay) || double.IsInfinity(voteDay) || voteDay < 0
                || string.IsNullOrWhiteSpace(decoded[1])
                || string.IsNullOrWhiteSpace(decoded[2])
                || string.IsNullOrWhiteSpace(decoded[3])
                || !(string.Equals(proofFields[4], "enact", StringComparison.Ordinal)
                    || string.Equals(proofFields[4], "repeal", StringComparison.Ordinal))
                || !(string.Equals(proofFields[5], "passed", StringComparison.Ordinal)
                    || string.Equals(proofFields[5], "defeated", StringComparison.Ordinal))
                || !string.Equals(proofFields[6], "realm_court", StringComparison.Ordinal)
                || !string.Equals(proofFields[7], "court_policy_conclude", StringComparison.Ordinal)
                || !(string.Equals(proofFields[8], "current_mandate", StringComparison.Ordinal)
                    || string.Equals(proofFields[8], "obsolete_mandate", StringComparison.Ordinal)))
                return false;

            proof = new VoteProof
            {
                Id = id,
                RealmId = decoded[1],
                PolicyId = decoded[2],
                SponsorId = decoded[3],
                Action = proofFields[4],
                Outcome = proofFields[5],
                ObsoleteMandate = string.Equals(proofFields[8], "obsolete_mandate", StringComparison.Ordinal),
                VoteDay = voteDay
            };
            return true;
        }

        private static bool TryDecodeCourtVoteReceipt(string payload, out string[] receiptFields, out double receiptDay)
        {
            receiptFields = null;
            receiptDay = 0;
            if (string.IsNullOrWhiteSpace(payload) || payload.Length > 16384) return false;
            string[] fields = payload.Split('|');
            if (fields.Length != 13 || !string.Equals(fields[0], "v1", StringComparison.Ordinal))
                return false;

            var decoded = new string[12];
            decoded[0] = "v1";
            var utf8 = new UTF8Encoding(false, true);
            try
            {
                for (int i = 1; i <= 11; i++)
                {
                    if (fields[i].Length > 8192) return false;
                    decoded[i] = utf8.GetString(Convert.FromBase64String(fields[i]));
                    if (decoded[i].Length > 2048) return false;
                }
            }
            catch (FormatException) { return false; }
            catch (DecoderFallbackException) { return false; }

            double day;
            if (!double.TryParse(fields[12], NumberStyles.Float, CultureInfo.InvariantCulture, out day)
                || double.IsNaN(day) || double.IsInfinity(day) || day < 0) return false;
            receiptFields = decoded;
            receiptDay = day;
            return true;
        }

        private static bool TryMatchPolicyVote(string[] receiptFields, double receiptDay, VoteProof proof)
        {
            if (proof == null || receiptFields == null || receiptFields.Length != 12
                || receiptDay < proof.VoteDay
                || !string.Equals(receiptFields[1], proof.RealmId, StringComparison.Ordinal)
                || !string.Equals(receiptFields[3], proof.SponsorId, StringComparison.Ordinal)
                || !string.Equals(receiptFields[4], "policy", StringComparison.Ordinal)
                || !string.Equals(receiptFields[5], proof.PolicyId, StringComparison.Ordinal)
                || !string.Equals(receiptFields[6], proof.Action, StringComparison.Ordinal)
                || !string.IsNullOrEmpty(receiptFields[11]))
                return false;

            if (string.Equals(proof.Outcome, "passed", StringComparison.Ordinal))
                return string.Equals(receiptFields[7], "Passed", StringComparison.Ordinal)
                    && string.Equals(receiptFields[8], "Succeeded", StringComparison.Ordinal)
                    && string.Equals(receiptFields[9], "Sponsor", StringComparison.Ordinal)
                    && string.Equals(receiptFields[10], "Passed", StringComparison.Ordinal);

            return string.Equals(proof.Outcome, "defeated", StringComparison.Ordinal)
                && string.Equals(receiptFields[7], "Defeated", StringComparison.Ordinal)
                && string.Equals(receiptFields[8], "Failed", StringComparison.Ordinal)
                && string.Equals(receiptFields[9], "None", StringComparison.Ordinal)
                && string.Equals(receiptFields[10], "Defeated", StringComparison.Ordinal);
        }
    }
}
