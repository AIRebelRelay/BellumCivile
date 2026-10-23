using System;
using System.Collections.Generic;
using System.Linq;
using TaleWorlds.CampaignSystem;
using TaleWorlds.CampaignSystem.Election;

namespace BellumCivile.Behaviors
{
    // Native Court retains all authority to file, charge influence and resolve ballots.
    public sealed partial class CourtAgendaBehavior
    {
        private const int MaxNpcCouncilIntents = 256;
        private const int MaxNpcCouncilPerRealm = 4;
        private Dictionary<string, string> _npcCouncilIntents = new Dictionary<string, string>();
        private Dictionary<string, string> _npcCouncilAgendaIds = new Dictionary<string, string>();
        private Dictionary<string, string> _npcCouncilClosures = new Dictionary<string, string>();
        private double _lastNpcCouncilReviewDay = double.NaN;

        private void SyncNpcCouncilIntents(IDataStore store)
        {
            store.SyncData("BC_CourtNpcCouncilIntents_v1", ref _npcCouncilIntents);
            store.SyncData("BC_CourtNpcCouncilAgendaIds_v1", ref _npcCouncilAgendaIds);
            store.SyncData("BC_CourtNpcCouncilClosures_v1", ref _npcCouncilClosures);
            _npcCouncilIntents = _npcCouncilIntents ?? new Dictionary<string, string>();
            _npcCouncilAgendaIds = _npcCouncilAgendaIds ?? new Dictionary<string, string>();
            _npcCouncilClosures = _npcCouncilClosures ?? new Dictionary<string, string>();
        }

        internal NpcCouncilAppointmentIntentSnapshot GetNpcCouncilAppointmentIntent(Kingdom realm, string id)
        {
            if (realm == null || !NpcCouncilAppointmentIntentCodec.ValidId(id, 128)
                || !_npcCouncilIntents.TryGetValue(id, out string packed)
                || !NpcCouncilAppointmentIntentCodec.TryRead(id, packed, out var saved)
                || saved.RealmId != realm.StringId) return null;
            _npcCouncilAgendaIds.TryGetValue(id, out string agendaId);
            if (_npcCouncilClosures.TryGetValue(id, out string closed))
                return CouncilTicket(saved, closed, agendaId, null);
            if (string.IsNullOrEmpty(agendaId)) return saved;
            var agenda = IntegrationRecords().FirstOrDefault(a => a.IntegrationId == agendaId);
            if (agenda == null) return CouncilTicket(saved, "court_missing", agendaId, null);
            if (agenda.Realm != realm || agenda.Sponsor?.StringId != saved.SponsorClanId
                || agenda.Faction == null || (int)agenda.Faction.Type != saved.FactionTypeValue
                || !IsCouncil(agenda) || !CouncilOffice(agenda, out var office)
                || (int)office != saved.OfficeValue)
                return CouncilTicket(saved, "court_superseded", agendaId, null);
            return CouncilTicket(saved, "court_" + agenda.State.ToString().ToLowerInvariant(),
                agendaId, agenda.PreferredCouncilCandidate?.StringId);
        }

        internal IReadOnlyList<NpcCouncilAppointmentIntentSnapshot> GetNpcCouncilAppointmentIntents(Kingdom realm)
        {
            var result = new List<NpcCouncilAppointmentIntentSnapshot>();
            if (realm == null) return result;
            foreach (var id in _npcCouncilIntents.Keys.OrderBy(i => i, StringComparer.Ordinal))
            {
                var ticket = GetNpcCouncilAppointmentIntent(realm, id);
                if (ticket != null) result.Add(ticket);
            }
            return result.AsReadOnly();
        }

        private static NpcCouncilAppointmentIntentSnapshot CouncilTicket(NpcCouncilAppointmentIntentSnapshot saved,
            string status, string agendaId, string selected)
            => new NpcCouncilAppointmentIntentSnapshot(saved.ExternalIntentId, saved.RealmId,
                saved.SponsorClanId, saved.FactionTypeValue, saved.OfficeValue,
                saved.RequestedCandidateClanId, saved.SubmittedDay, status, agendaId, selected);

        private static NpcCouncilAppointmentIntentSubmission RejectNpcCouncil(string reason)
            => new NpcCouncilAppointmentIntentSubmission(false, reason, null);

        internal NpcCouncilAppointmentIntentSubmission TryStageNpcCouncilAppointmentIntent(
            Kingdom realm, Clan sponsor, FactionObject faction, PrivyCouncilOffice office,
            Clan requestedCandidate, string id)
        {
            if (!NpcCouncilAppointmentIntentCodec.ValidId(id, 128)) return RejectNpcCouncil("invalid_intent_id");
            if (_npcCouncilIntents.TryGetValue(id, out string packed))
            {
                if (!NpcCouncilAppointmentIntentCodec.TryRead(id, packed, out var previous))
                    return RejectNpcCouncil("corrupt_ticket");
                if (realm == null || sponsor == null || faction == null
                    || previous.RealmId != realm.StringId || previous.SponsorClanId != sponsor.StringId
                    || previous.FactionTypeValue != (int)faction.Type || previous.OfficeValue != (int)office
                    || previous.RequestedCandidateClanId != (requestedCandidate?.StringId ?? ""))
                    return RejectNpcCouncil("intent_id_collision");
                var current = GetNpcCouncilAppointmentIntent(realm, id);
                return _npcCouncilClosures.ContainsKey(id)
                    ? new NpcCouncilAppointmentIntentSubmission(false, current.Status, current)
                    : new NpcCouncilAppointmentIntentSubmission(true, "already_staged", current);
            }
            if (!ValidRealm(realm) || sponsor == null || sponsor == Clan.PlayerClan || !Eligible(sponsor, realm)
                || faction == null || !faction.IsIdeology || faction.ParentKingdom != realm
                || faction.Leader != sponsor || MemberCount(faction) < 2)
                return RejectNpcCouncil("npc_faction_leader_required");
            if (!Enum.IsDefined(typeof(PrivyCouncilOffice), office)) return RejectNpcCouncil("invalid_office");
            var council = Campaign.Current?.GetCampaignBehavior<PrivyCouncilBehavior>();
            if (council == null || !council.IsOfficeUnlocked(realm, office)
                || IsCouncilOfficeSettled(realm, office) || HasCouncilReservation(realm)
                || CouncilAppointmentDeliberationBehavior.Current?.HasPendingAppointment(realm) == true
                || realm.UnresolvedDecisions.OfType<PrivyCouncilAppointmentDecision>().Any())
                return RejectNpcCouncil("council_reserved_or_unavailable");
            if (_npcCouncilIntents.Count >= MaxNpcCouncilIntents)
                return RejectNpcCouncil("intent_capacity_reached");
            if (_npcCouncilIntents.Count(entry =>
            {
                if (_npcCouncilClosures.ContainsKey(entry.Key)
                    || _npcCouncilAgendaIds.ContainsKey(entry.Key)
                    || !NpcCouncilAppointmentIntentCodec.TryRead(entry.Key, entry.Value, out var t))
                    return false;
                return t.RealmId == realm.StringId;
            }) >= MaxNpcCouncilPerRealm) return RejectNpcCouncil("realm_capacity_reached");
            foreach (var entry in _npcCouncilIntents)
            {
                if (_npcCouncilClosures.ContainsKey(entry.Key)
                    || !NpcCouncilAppointmentIntentCodec.TryRead(entry.Key, entry.Value, out var existing)
                    || existing.RealmId != realm.StringId || existing.FactionTypeValue != (int)faction.Type)
                    continue;
                var prior = GetNpcCouncilAppointmentIntent(realm, entry.Key);
                if (prior.Status == NpcCouncilAppointmentIntentCodec.Staged
                    || prior.Status == "court_announced" || prior.Status == "court_deliberating"
                    || prior.Status == "court_voting")
                    return RejectNpcCouncil("faction_intent_in_flight");
            }
            var context = new CourtTermContext(realm, _ => false);
            var owner = new CourtObjectiveOwner(faction, sponsor);
            var source = new CourtCouncilObjectiveSource();
            var match = source.FindCandidates(context, owner).FirstOrDefault(c =>
                c.TargetId == office.ToString()
                && (requestedCandidate == null || c.BeneficiaryId == requestedCandidate.StringId));
            if (match == null || !source.EvaluateCandidate(context, owner, match).Selectable)
                return RejectNpcCouncil("candidate_or_office_not_viable");
            if (!NpcCouncilAppointmentIntentCodec.ValidId(realm.StringId, 256)
                || !NpcCouncilAppointmentIntentCodec.ValidId(sponsor.StringId, 256)
                || (requestedCandidate != null && !NpcCouncilAppointmentIntentCodec.ValidId(requestedCandidate.StringId, 256)))
                return RejectNpcCouncil("invalid_entity_id");
            _npcCouncilIntents.Add(id, NpcCouncilAppointmentIntentCodec.Pack(realm.StringId,
                sponsor.StringId, (int)faction.Type, (int)office,
                requestedCandidate?.StringId, CampaignTime.Now.ToDays));
            BellumCivileLogger.Log("AIInfluence NPC council intent staged; realm=" + realm.StringId
                + "; sponsor=" + sponsor.StringId + "; office=" + office
                + "; id=" + id + "; status=staged_not_scheduled; vote_filed=false.");
            return new NpcCouncilAppointmentIntentSubmission(true, NpcCouncilAppointmentIntentCodec.Staged,
                GetNpcCouncilAppointmentIntent(realm, id));
        }

        // Only occupy the faction's native slot if no other selector winner owns a council motion.
        private bool TryAttachStagedNpcCouncil(CourtAgendaRecord agenda, CourtTermContext context,
            IReadOnlyList<CourtObjectiveChoice> nativeChoices, int ownerIndex)
        {
            if (agenda?.State != CourtAgendaState.NotProposed || agenda.Faction == null
                || !ValidRealm(agenda.Realm) || agenda.Sponsor == Clan.PlayerClan
                || agenda.Faction.Leader != agenda.Sponsor || !Eligible(agenda.Sponsor, agenda.Realm)
                || MemberCount(agenda.Faction) < 2 || HasCouncilReservation(agenda.Realm, agenda)
                || nativeChoices.Where((c, i) => i != ownerIndex).Any(c => c?.Kind == CourtCouncilObjectiveSource.CouncilKind)
                || _npcCouncilIntents.Count == 0) return false;
            var source = new CourtCouncilObjectiveSource();
            var owner = new CourtObjectiveOwner(agenda.Faction, agenda.Sponsor);
            foreach (var entry in _npcCouncilIntents.OrderBy(p => p.Key, StringComparer.Ordinal))
            {
                if (_npcCouncilClosures.ContainsKey(entry.Key) || _npcCouncilAgendaIds.ContainsKey(entry.Key)
                    || !NpcCouncilAppointmentIntentCodec.TryRead(entry.Key, entry.Value, out var ticket)
                    || ticket.RealmId != agenda.Realm.StringId
                    || ticket.SponsorClanId != agenda.Sponsor.StringId
                    || ticket.FactionTypeValue != (int)agenda.Faction.Type
                    || !Enum.IsDefined(typeof(PrivyCouncilOffice), ticket.OfficeValue))
                    continue;
                var office = (PrivyCouncilOffice)ticket.OfficeValue;
                var candidate = source.FindCandidates(context, owner).FirstOrDefault(c =>
                    c.TargetId == office.ToString()
                    && (string.IsNullOrEmpty(ticket.RequestedCandidateClanId)
                        || c.BeneficiaryId == ticket.RequestedCandidateClanId));
                if (candidate == null) continue;
                var evaluation = source.EvaluateCandidate(context, owner, candidate);
                if (!evaluation.Selectable) continue;
                source.ApplySelection(agenda, new CourtObjectiveChoice(source.Kind, candidate, evaluation));
                agenda.State = CourtAgendaState.Announced;
                _npcCouncilAgendaIds.Add(ticket.ExternalIntentId, agenda.IntegrationId);
                NotifyAgenda(agenda);
                BellumCivileLogger.Log("AIInfluence NPC council intent attached; realm="
                    + agenda.Realm.StringId + "; sponsor=" + agenda.Sponsor.StringId
                    + "; office=" + office + "; nominee=" + candidate.BeneficiaryId
                    + "; id=" + ticket.ExternalIntentId + "; agenda=" + agenda.IntegrationId
                    + "; status=court_announced; vote_filed=false.");
                return true;
            }
            return false;
        }

        // Freeze native terminal state before OpenTerm cleans old agenda records.
        private void FreezeNpcCouncilTerminalResults(Kingdom realm)
        {
            foreach (var entry in _npcCouncilAgendaIds)
            {
                if (_npcCouncilClosures.ContainsKey(entry.Key)
                    || !_npcCouncilIntents.TryGetValue(entry.Key, out var packed)
                    || !NpcCouncilAppointmentIntentCodec.TryRead(entry.Key, packed, out var ticket)
                    || ticket.RealmId != realm.StringId) continue;
                var agenda = IntegrationRecords().FirstOrDefault(a => a.IntegrationId == entry.Value);
                if (agenda == null || agenda.Realm != realm || agenda.IsUnopened
                    || agenda.IsFiled || agenda.IsOngoingObjective) continue;
                _npcCouncilClosures[entry.Key] = "court_" + agenda.State.ToString().ToLowerInvariant();
            }
        }

        // Daily maintenance never opens an agenda and never creates a ballot.
        private void MaintainNpcCouncilIntentLifecycle()
        {
            if (_npcCouncilIntents.Count == 0) return;
            double now = CampaignTime.Now.ToDays;
            if (double.IsNaN(now) || double.IsInfinity(now)) return;
            double today = Math.Floor(now);
            if (_lastNpcCouncilReviewDay == today) return;
            _lastNpcCouncilReviewDay = today;
            double maxAge = Math.Max(3d * CampaignTime.DaysInYear,
                2d * BellumCivileOptions.CourtTermDays);
            foreach (var entry in _npcCouncilIntents)
            {
                if (_npcCouncilClosures.ContainsKey(entry.Key) || _npcCouncilAgendaIds.ContainsKey(entry.Key)
                    || !NpcCouncilAppointmentIntentCodec.TryRead(entry.Key, entry.Value, out var ticket))
                    continue;
                var realm = Kingdom.All.FirstOrDefault(k => k?.StringId == ticket.RealmId);
                string state = null;
                if (!ValidRealm(realm)) state = "cancelled_realm_invalid";
                else
                {
                    var manager = Campaign.Current?.GetCampaignBehavior<FactionManagerBehavior>();
                    var faction = manager?.GetFactionsInKingdom(realm).FirstOrDefault(f =>
                        f.IsIdeology && (int)f.Type == ticket.FactionTypeValue);
                    if (faction == null || faction.Leader?.StringId != ticket.SponsorClanId
                        || !Eligible(faction.Leader, realm) || MemberCount(faction) < 2)
                        state = "cancelled_sponsor_changed";
                    else if (now - ticket.SubmittedDay > maxAge)
                        state = "expired_unassigned";
                }
                if (state == null) continue;
                _npcCouncilClosures[entry.Key] = state;
                BellumCivileLogger.Log("AIInfluence NPC council intent closed; id="
                    + entry.Key + "; realm=" + ticket.RealmId + "; status=" + state
                    + "; appointment_executed=false.");
            }
        }
    }
}
