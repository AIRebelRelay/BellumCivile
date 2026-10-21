using System;
using System.Collections.Generic;
using System.Linq;
using TaleWorlds.CampaignSystem;

namespace BellumCivile.Behaviors
{
    public sealed partial class CourtAgendaBehavior
    {
        // Durable correlation only: native Bellum retains all Court Agenda authority.
        private Dictionary<string, string> _npcTreasonAgendaIds = new Dictionary<string, string>();

        private NpcCrownTreasonIntentSnapshot DescribeNpcTreasonIntent(NpcCrownTreasonIntentSnapshot ticket)
        {
            string closed;
            if (ticket != null && _npcTreasonClosures != null
                && _npcTreasonClosures.TryGetValue(ticket.ExternalIntentId, out closed))
                return new NpcCrownTreasonIntentSnapshot(ticket.ExternalIntentId, ticket.RealmId,
                    ticket.RulerClanId, ticket.TargetClanId, ticket.SubmittedDay,
                    IsNpcTreasonTerminalReason(closed) ? closed : "corrupt_terminal_state");
            string agendaId;
            if (ticket == null || _npcTreasonAgendaIds == null
                || !_npcTreasonAgendaIds.TryGetValue(ticket.ExternalIntentId, out agendaId))
                return ticket;

            CourtAgendaRecord agenda = IntegrationRecords().FirstOrDefault(a => a.IntegrationId == agendaId);
            string status;
            if (agenda == null) status = "court_missing";
            else if (agenda.Realm?.StringId != ticket.RealmId
                || agenda.Sponsor?.StringId != ticket.RulerClanId
                || agenda.ObjectiveData?.Kind != CourtExecutiveRules.Treason
                || agenda.ObjectiveData.TargetId != ticket.TargetClanId)
                status = "court_superseded";
            else status = "court_" + agenda.State.ToString().ToLowerInvariant();

            return new NpcCrownTreasonIntentSnapshot(ticket.ExternalIntentId, ticket.RealmId,
                ticket.RulerClanId, ticket.TargetClanId, ticket.SubmittedDay, status, agendaId);
        }

        // OpenTerm calls this only for a fresh NPC Crown slot AFTER native Decree,
        // Royal Peace and Council vacancy reservations, BEFORE automatic selection.
        private bool TryAttachStagedNpcTreason(CourtAgendaRecord agenda, CourtTermContext context)
        {
            if (agenda == null || context == null || agenda.Faction != null
                || agenda.State != CourtAgendaState.NotProposed || agenda.ResultApplied
                || !ValidRealm(agenda.Realm) || agenda.Sponsor != agenda.Realm.RulingClan
                || agenda.Sponsor == Clan.PlayerClan || !Eligible(agenda.Sponsor, agenda.Realm)
                || !BellumCivileOptions.EnableAutomaticTreasonIndictments
                || _npcTreasonIntents == null || _npcTreasonIntents.Count == 0)
                return false;

            Kingdom realm = agenda.Realm;
            var source = (CourtExecutiveObjectiveSource)_objectiveSelector.FindSource(CourtExecutiveRules.Treason);
            if (source == null) return false;
            var owner = new CourtObjectiveOwner(null, agenda.Sponsor);
            var pending = new List<NpcCrownTreasonIntentSnapshot>();
            foreach (var pair in _npcTreasonIntents)
            {
                NpcCrownTreasonIntentSnapshot ticket;
                if (NpcTreasonIntentCodec.TryRead(pair.Key, pair.Value, out ticket)
                    && ticket.RealmId == realm.StringId
                    && (_npcTreasonClosures == null || !_npcTreasonClosures.ContainsKey(pair.Key))
                    && (_npcTreasonAgendaIds == null || !_npcTreasonAgendaIds.ContainsKey(pair.Key)))
                    pending.Add(ticket);
            }

            foreach (var ticket in pending.OrderBy(t => t.SubmittedDay)
                .ThenBy(t => t.ExternalIntentId, StringComparer.Ordinal))
            {
                if (ticket.RulerClanId != agenda.Sponsor.StringId) continue;
                Clan target = realm.Clans.FirstOrDefault(c => c?.StringId == ticket.TargetClanId);
                if (target == null || target == agenda.Sponsor || !Eligible(target, realm)
                    || target.Leader.GetRelation(agenda.Sponsor.Leader) <= -100)
                    continue;

                var candidate = new CourtObjectiveCandidate(ticket.TargetClanId, "indict");
                var evaluation = source.EvaluateCandidate(context, owner, candidate);
                if (evaluation == null || !evaluation.Selectable || !evaluation.Viable)
                    continue;

                source.ApplySelection(agenda, new CourtObjectiveChoice(source.Kind, candidate, evaluation));
                agenda.State = CourtAgendaState.Announced;
                if (_npcTreasonAgendaIds == null)
                    _npcTreasonAgendaIds = new Dictionary<string, string>();
                _npcTreasonAgendaIds.Add(ticket.ExternalIntentId, agenda.IntegrationId);
                NotifyAgenda(agenda);
                BellumCivileLogger.Log("AIInfluence NPC Crown intent attached; realm="
                    + realm.StringId + "; ruler=" + agenda.Sponsor.StringId
                    + "; target=" + ticket.TargetClanId + "; id=" + ticket.ExternalIntentId
                    + "; agenda=" + agenda.IntegrationId
                    + "; status=court_announced; vote_filed=false.");
                return true;
            }
            return false;
        }
    }
}
