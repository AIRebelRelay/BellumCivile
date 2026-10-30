using System;
using System.Collections.Generic;
using System.Globalization;
using System.Text;
using TaleWorlds.CampaignSystem;

namespace BellumCivile.Behaviors
{
    public sealed partial class CourtAgendaBehavior
    {
        // Authored ONLY by CourtAgendaBehavior.Conclude after the verified Native
        // kingdom policy decision has resolved. This is realm-court disclosure
        // provenance, not law enactment or a world-public publication.
        private const int MaxCourtPolicyVotePublicProvenance = 1024;
        private Dictionary<string, string> _courtPolicyVotePublicProvenance =
            new Dictionary<string, string>();
        private int _courtPolicyVotePublicProvenanceOverflow;

        private void SyncCourtPolicyVotePublicProvenance(IDataStore store)
        {
            store.SyncData("BC_CourtPolicyVotePublicProvenance_v1",
                ref _courtPolicyVotePublicProvenance);
            store.SyncData("BC_CourtPolicyVotePublicProvenanceOverflow_v1",
                ref _courtPolicyVotePublicProvenanceOverflow);
            _courtPolicyVotePublicProvenance = _courtPolicyVotePublicProvenance
                ?? new Dictionary<string, string>();
        }

        private void RecordCourtPolicyVotePublicProvenance(
            CourtAgendaRecord agenda, PolicyObject policy, bool abolish, bool passed,
            bool obsoleteMandate)
        {
            try
            {
                Guid parsed;
                if (agenda == null || policy == null || agenda.Sponsor == null
                    || !ValidRealm(agenda.Realm)
                    || string.IsNullOrWhiteSpace(agenda.Realm.StringId)
                    || string.IsNullOrWhiteSpace(agenda.Sponsor.StringId)
                    || !agenda.IsPolicy
                    || !string.IsNullOrEmpty(agenda.CancellationReason)
                    || !Guid.TryParseExact(agenda.IntegrationId, "N", out parsed))
                {
                    BellumCivileLogger.Log(
                        "BC_COURT_PUBLIC_PROVENANCE status=held; reason=invalid_policy_vote_identity"
                        + "; relay_emitted=false");
                    return;
                }

                CourtObjectiveRecord objective = agenda.ObjectiveData;
                if (objective == null || agenda.ResultApplied != true
                    || agenda.State != (passed ? CourtAgendaState.Passed : CourtAgendaState.Defeated)
                    || objective.State != (passed ? CourtObjectiveState.Succeeded : CourtObjectiveState.Failed)
                    || objective.Credit != (passed ? CourtObjectiveCredit.Sponsor : CourtObjectiveCredit.None)
                    || !string.Equals(objective.Kind, "policy", StringComparison.Ordinal)
                    || !string.Equals(objective.TargetId, policy.StringId, StringComparison.Ordinal)
                    || !string.Equals(objective.ActionId, abolish ? "repeal" : "enact", StringComparison.Ordinal))
                {
                    BellumCivileLogger.Log(
                        "BC_COURT_PUBLIC_PROVENANCE status=held; reason=unverified_policy_vote"
                        + "; relay_emitted=false");
                    return;
                }

                if (_courtPolicyVotePublicProvenance.ContainsKey(agenda.IntegrationId)) return;
                if (_courtPolicyVotePublicProvenance.Count >= MaxCourtPolicyVotePublicProvenance)
                {
                    if (_courtPolicyVotePublicProvenanceOverflow < int.MaxValue)
                        _courtPolicyVotePublicProvenanceOverflow++;
                    BellumCivileLogger.Log(
                        "BC_COURT_PUBLIC_PROVENANCE status=overflow"
                        + "; pending=" + _courtPolicyVotePublicProvenance.Count.ToString(CultureInfo.InvariantCulture)
                        + "; total_overflow=" + _courtPolicyVotePublicProvenanceOverflow.ToString(CultureInfo.InvariantCulture)
                        + "; relay_emitted=false");
                    return;
                }

                string value = string.Join("|", new[]
                {
                    "v1",
                    EncodeCourtPolicyProofField(agenda.Realm.StringId),
                    EncodeCourtPolicyProofField(policy.StringId),
                    EncodeCourtPolicyProofField(agenda.Sponsor.StringId),
                    abolish ? "repeal" : "enact",
                    passed ? "passed" : "defeated",
                    "realm_court",
                    "court_policy_conclude",
                    obsoleteMandate ? "obsolete_mandate" : "current_mandate",
                    CampaignTime.Now.ToDays.ToString("R", CultureInfo.InvariantCulture)
                });
                _courtPolicyVotePublicProvenance.Add(agenda.IntegrationId, value);
                BellumCivileLogger.Log(
                    "BC_COURT_PUBLIC_PROVENANCE status=recorded"
                    + "; id=" + agenda.IntegrationId
                    + "; realm=" + agenda.Realm.StringId
                    + "; audience=realm_court; source=court_policy_conclude"
                    + "; result=" + (passed ? "passed" : "defeated")
                    + "; obsolete_mandate=" + obsoleteMandate.ToString().ToLowerInvariant()
                    + "; pending=" + _courtPolicyVotePublicProvenance.Count.ToString(CultureInfo.InvariantCulture)
                    + "; law_effect_owner=w7; relay_emitted=false");
            }
            catch (Exception ex)
            {
                // The provenance recorder never changes Native vote success,
                // influence, faction mood or notification delivery.
                BellumCivileLogger.Log(
                    "BC_COURT_PUBLIC_PROVENANCE status=capture_error"
                    + "; relay_emitted=false; " + ex);
            }
        }

        private static string EncodeCourtPolicyProofField(string value)
            => Convert.ToBase64String(Encoding.UTF8.GetBytes(value ?? string.Empty));
    }
}
