using System;
using System.Collections.Generic;
using System.Linq;
using TaleWorlds.CampaignSystem;

namespace BellumCivile.Behaviors
{
    public sealed partial class CourtAgendaBehavior
    {
        // Terminal tombstones preserve external IDs across saves; never recycle them.
        // Native attached court motions are excluded from this lifecycle entirely.
        private Dictionary<string, string> _npcTreasonClosures = new Dictionary<string, string>();
        private double _lastNpcTreasonReviewDay = double.NaN;

        private static bool IsNpcTreasonTerminalReason(string status)
        {
            switch (status)
            {
                case "cancelled_realm_invalid":
                case "cancelled_ruler_changed":
                case "cancelled_target_invalid":
                case "cancelled_automatic_disabled":
                case "expired_unassigned":
                    return true;
                default: return false;
            }
        }

        private int PendingNpcTreasonIntentCount(string realmId)
        {
            if (_npcTreasonIntents == null) return 0;
            return _npcTreasonIntents.Count(entry =>
            {
                NpcCrownTreasonIntentSnapshot ticket;
                return (_npcTreasonClosures == null || !_npcTreasonClosures.ContainsKey(entry.Key))
                    && (_npcTreasonAgendaIds == null || !_npcTreasonAgendaIds.ContainsKey(entry.Key))
                    && NpcTreasonIntentCodec.TryRead(entry.Key, entry.Value, out ticket)
                    && ticket.RealmId == realmId;
            });
        }

        // Called by Bellum's EXISTING campaign Tick; runs once per game day,
        // never opens, closes or overwrites a native Court agenda.
        private void MaintainNpcTreasonLifecycle()
        {
            if (_npcTreasonIntents == null || _npcTreasonIntents.Count == 0) return;
            double now = CampaignTime.Now.ToDays;
            if (double.IsNaN(now) || double.IsInfinity(now)) return;
            double today = Math.Floor(now);
            if (_lastNpcTreasonReviewDay == today) return;
            _lastNpcTreasonReviewDay = today;

            double maximumAge = Math.Max(3d * CampaignTime.DaysInYear,
                2d * BellumCivileOptions.CourtTermDays);
            foreach (var entry in _npcTreasonIntents)
            {
                if ((_npcTreasonClosures != null && _npcTreasonClosures.ContainsKey(entry.Key))
                    || (_npcTreasonAgendaIds != null && _npcTreasonAgendaIds.ContainsKey(entry.Key)))
                    continue;

                NpcCrownTreasonIntentSnapshot ticket;
                // Unknown/corrupt saved records must not be acted upon or reissued.
                if (!NpcTreasonIntentCodec.TryRead(entry.Key, entry.Value, out ticket))
                    continue;

                string status = null;
                Kingdom realm = Kingdom.All.FirstOrDefault(k => k != null
                    && string.Equals(k.StringId, ticket.RealmId, StringComparison.Ordinal));
                if (!ValidRealm(realm))
                    status = "cancelled_realm_invalid";
                else if (realm.RulingClan == Clan.PlayerClan
                    || realm.RulingClan?.StringId != ticket.RulerClanId
                    || !Eligible(realm.RulingClan, realm))
                    status = "cancelled_ruler_changed";
                else
                {
                    Clan target = realm.Clans.FirstOrDefault(c => c != null
                        && string.Equals(c.StringId, ticket.TargetClanId, StringComparison.Ordinal));
                    if (target == realm.RulingClan || !Eligible(target, realm)
                        || target.Leader.GetRelation(realm.RulingClan.Leader) <= -100)
                        status = "cancelled_target_invalid";
                    else if (!BellumCivileOptions.EnableAutomaticTreasonIndictments)
                        status = "cancelled_automatic_disabled";
                    else if (now - ticket.SubmittedDay > maximumAge)
                        status = "expired_unassigned";
                }

                if (status == null) continue;
                if (_npcTreasonClosures == null)
                    _npcTreasonClosures = new Dictionary<string, string>();
                _npcTreasonClosures[entry.Key] = status;
                BellumCivileLogger.Log("AIInfluence NPC Crown intent closed; id="
                    + entry.Key + "; realm=" + ticket.RealmId + "; target="
                    + ticket.TargetClanId + "; status=" + status
                    + "; court_actions=false.");
            }
        }
    }
}
