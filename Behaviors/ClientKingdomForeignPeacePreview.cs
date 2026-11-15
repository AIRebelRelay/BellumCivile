using System;
using System.Collections.Generic;
using System.Linq;
using TaleWorlds.CampaignSystem;

namespace BellumCivile.Behaviors
{
    public sealed partial class ClientKingdomBehavior
    {
        // A pure lookup. Do NOT call the public client lookups: they may purge stale
        // records and advance the runtime revision during a supposedly read-only query.
        internal ForeignPeaceClientRead PeekForeignPeaceClientStatus(Kingdom source, Kingdom target)
        {
            if (_clients == null || _diplomaticSyncDepth != 0
                || source == null || target == null)
                return ForeignPeaceClientRead.Unknown;

            var seen = new HashSet<string>(StringComparer.Ordinal);
            foreach (ClientKingdomRecord record in _clients)
            {
                if (record == null || string.IsNullOrWhiteSpace(record.ClientKingdomId)
                    || string.IsNullOrWhiteSpace(record.SuzerainKingdomId)
                    || !seen.Add(record.ClientKingdomId))
                    return ForeignPeaceClientRead.Unknown;
            }

            ForeignPeaceClientRead first = PeekClientPeaceSide(source, target);
            ForeignPeaceClientRead second = PeekClientPeaceSide(target, source);
            if (first == ForeignPeaceClientRead.Blocked || second == ForeignPeaceClientRead.Blocked)
                return ForeignPeaceClientRead.Blocked;
            if (first == ForeignPeaceClientRead.Unknown || second == ForeignPeaceClientRead.Unknown)
                return ForeignPeaceClientRead.Unknown;
            return ForeignPeaceClientRead.Clear;
        }

        private ForeignPeaceClientRead PeekClientPeaceSide(Kingdom candidate, Kingdom opponent)
        {
            ClientKingdomRecord record = _clients.FirstOrDefault(
                item => item.ClientKingdomId == candidate.StringId);
            if (record == null)
                return ForeignPeaceClientRead.Clear;

            Kingdom suzerain = Kingdom.All.FirstOrDefault(
                realm => realm != null && realm.StringId == record.SuzerainKingdomId);
            if (suzerain == null || suzerain.IsEliminated)
                return ForeignPeaceClientRead.Unknown;

            // A subsidiary cannot independently settle its suzerain's foreign war.
            // An active liberation war against its own suzerain is not ordinary peace.
            if (suzerain == opponent || suzerain.IsAtWarWith(opponent))
                return ForeignPeaceClientRead.Blocked;
            return ForeignPeaceClientRead.Clear;
        }
    }
}
