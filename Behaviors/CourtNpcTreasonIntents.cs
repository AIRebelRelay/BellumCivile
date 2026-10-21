using System;
using System.Collections.Generic;
using System.Linq;
using TaleWorlds.CampaignSystem;
using TaleWorlds.Localization;

namespace BellumCivile.Behaviors
{
    public sealed partial class CourtAgendaBehavior
    {
        // Stage 6 only: serialized intents are inert until a separate audited Court Agenda
        // consumer is implemented. Never claim that a staged ticket has filed a vote.
        private Dictionary<string, string> _npcTreasonIntents = new Dictionary<string, string>();
        private const int MaxNpcTreasonIntents = 256;
        private const int MaxNpcTreasonPerRealm = 4;

        private void SyncNpcTreasonIntents(IDataStore dataStore)
        {
            dataStore.SyncData("BC_CourtNpcTreasonIntents_v1", ref _npcTreasonIntents);
            dataStore.SyncData("BC_CourtNpcTreasonAgendaIds_v1", ref _npcTreasonAgendaIds);
            _npcTreasonIntents = _npcTreasonIntents ?? new Dictionary<string, string>();
            _npcTreasonAgendaIds = _npcTreasonAgendaIds ?? new Dictionary<string, string>();
        }

        internal NpcCrownTreasonIntentSnapshot GetNpcTreasonIntent(
            Kingdom realm, string externalIntentId)
        {
            if (realm == null || !NpcTreasonIntentCodec.ValidId(externalIntentId, 128))
                return null;
            string packed;
            NpcCrownTreasonIntentSnapshot snapshot;
            return _npcTreasonIntents != null
                && _npcTreasonIntents.TryGetValue(externalIntentId, out packed)
                && NpcTreasonIntentCodec.TryRead(externalIntentId, packed, out snapshot)
                && string.Equals(snapshot.RealmId, realm.StringId, StringComparison.Ordinal)
                ? DescribeNpcTreasonIntent(snapshot) : null;
        }

        internal NpcCrownTreasonIntentSubmission TryStageNpcTreasonIntent(
            Kingdom realm, Clan rulerClan, Clan targetClan, string externalIntentId)
        {
            if (!NpcTreasonIntentCodec.ValidId(externalIntentId, 128))
                return Rejected("invalid_external_intent_id");
            if (_npcTreasonIntents == null)
                _npcTreasonIntents = new Dictionary<string, string>();

            // Check identity before preflight: replaying a persisted ticket after the ruler
            // changes must NEVER generate another attempt or rewrite the historical ticket.
            string existing;
            if (_npcTreasonIntents.TryGetValue(externalIntentId, out existing))
            {
                NpcCrownTreasonIntentSnapshot previous;
                if (!NpcTreasonIntentCodec.TryRead(externalIntentId, existing, out previous))
                    return Rejected("corrupt_ticket");
                if (realm == null || rulerClan == null || targetClan == null
                    || previous.RealmId != realm.StringId
                    || previous.RulerClanId != rulerClan.StringId
                    || previous.TargetClanId != targetClan.StringId)
                    return Rejected("external_intent_id_collision");
                return new NpcCrownTreasonIntentSubmission(true, "already_staged",
                    GetNpcTreasonIntent(realm, externalIntentId));
            }

            if (!ValidRealm(realm) || rulerClan == null || rulerClan != realm.RulingClan
                || rulerClan == Clan.PlayerClan || !Eligible(rulerClan, realm))
                return Rejected("npc_ruler_required");
            if (targetClan == null || targetClan == rulerClan || !Eligible(targetClan, realm))
                return Rejected("invalid_target_clan");
            if (!BellumCivileOptions.EnableAutomaticTreasonIndictments)
                return Rejected("automatic_treason_disabled");
            if (!NpcTreasonIntentCodec.ValidId(realm.StringId, 256)
                || !NpcTreasonIntentCodec.ValidId(rulerClan.StringId, 256)
                || !NpcTreasonIntentCodec.ValidId(targetClan.StringId, 256))
                return Rejected("invalid_entity_id");
            if (targetClan.Leader.GetRelation(rulerClan.Leader) <= -100)
                return Rejected("decree_only_relationship");

            IdeologyBehavior ideology = Campaign.Current?.GetCampaignBehavior<IdeologyBehavior>();
            if (ideology == null) return Rejected("ideology_unavailable");
            TextObject reason;
            // This must never clear Bellum's stored rejected-expulsion lock.
            if (!ideology.CanRulerIndictClan(realm, targetClan, false, out reason, readOnly: true))
                return Rejected("bellum_preflight_rejected");

            if (_npcTreasonIntents.Count >= MaxNpcTreasonIntents)
                return Rejected("intent_capacity_reached");
            int existingForRealm = _npcTreasonIntents.Count(entry =>
            {
                NpcCrownTreasonIntentSnapshot ticket;
                return NpcTreasonIntentCodec.TryRead(entry.Key, entry.Value, out ticket)
                    && ticket.RealmId == realm.StringId;
            });
            if (existingForRealm >= MaxNpcTreasonPerRealm)
                return Rejected("realm_intent_capacity_reached");

            string payload = NpcTreasonIntentCodec.Pack(
                realm.StringId, rulerClan.StringId, targetClan.StringId, CampaignTime.Now.ToDays);
            _npcTreasonIntents.Add(externalIntentId, payload);
            var staged = GetNpcTreasonIntent(realm, externalIntentId);
            BellumCivileLogger.Log("AIInfluence NPC Crown intent staged; realm="
                + realm.StringId + "; ruler=" + rulerClan.StringId
                + "; target=" + targetClan.StringId + "; id=" + externalIntentId
                + "; status=" + NpcTreasonIntentCodec.Staged + "; state_changes=false.");
            return new NpcCrownTreasonIntentSubmission(true, "staged_not_scheduled", staged);
        }

        private static NpcCrownTreasonIntentSubmission Rejected(string reason)
        {
            return new NpcCrownTreasonIntentSubmission(false, reason, null);
        }
    }
}
