using System;
using System.Linq;
using TaleWorlds.CampaignSystem;

namespace BellumCivile.Behaviors
{
    public sealed partial class WarScoreBehavior
    {
        // This is saved as the existing WarScoreRecord.ContextId (SaveableField 17).
        // The Bridge must prove the exact authoritative AII event before calling the API;
        // a caller-supplied string alone is NOT evidence of political consent.
        private const string AiForeignLedgerContextPrefix = "aii_foreign_ledger:v1:";

        private static bool IsAiInfluenceForeignLedger(WarScoreRecord war)
        {
            return war != null
                && war.ConflictType == WarScoreConflictType.ForeignWar
                && !string.IsNullOrEmpty(war.ContextId)
                && war.ContextId.StartsWith(AiForeignLedgerContextPrefix, StringComparison.Ordinal)
                && war.ContextId.Length > AiForeignLedgerContextPrefix.Length;
        }

        private bool HasOpenAiInfluenceForeignLedgers()
        {
            return _wars != null && _wars.Any(war => war != null
                && war.IsActive && IsAiInfluenceForeignLedger(war));
        }

        private static bool CanScoreAiInfluenceForeignLedger(WarScoreRecord war, Kingdom attacker, Kingdom defender)
        {
            return IsAiInfluenceForeignLedger(war)
                && war.IsActive && !war.ResolutionPending && !war.ParleyPending
                && attacker != null && defender != null
                && attacker.StringId == war.AttackerKingdomId
                && defender.StringId == war.DefenderKingdomId
                && IsForeignWarPair(attacker, defender)
                && attacker.IsAtWarWith(defender);
        }

        // Exact, opt-in Bridge handshake. Never registered by OnWarDeclared or vanilla
        // decision callbacks, never starts a war, treaty, parley or peace.
        // Native proves the current hostile world state; the Bridge owns proving
        // that aiEventId came from the actual AII accepted DeclareWar statement.
        public bool TryRegisterAiInfluenceForeignWar(
            Kingdom attacker, Kingdom defender, string aiEventId, out string report)
        {
            report = "AII foreign ledger registration denied";
            if (WarPeaceRevampBehavior.IsRevampEnabled())
            {
                report = "Bellum foreign revamp is enabled; normal Native war tracking owns this war";
                return false;
            }
            if (string.IsNullOrWhiteSpace(aiEventId) || aiEventId != aiEventId.Trim()
                || aiEventId.Length > 128)
            {
                report = "missing or invalid authoritative AII event ID";
                return false;
            }
            if (!IsValidPermanentKingdom(attacker) || !IsValidPermanentKingdom(defender)
                || attacker == defender || !IsForeignWarPair(attacker, defender)
                || !attacker.IsAtWarWith(defender))
            {
                report = "foreign war is not an exact active hostility between permanent realms";
                return false;
            }

            EnsureCollectionsInitialized();
            string key = BuildWarKey(attacker, defender);
            string context = AiForeignLedgerContextPrefix + aiEventId;
            WarScoreRecord existing = GetActiveWar(attacker, defender);
            if (existing != null)
            {
                if (IsAiInfluenceForeignLedger(existing)
                    && existing.AttackerKingdomId == attacker.StringId
                    && existing.DefenderKingdomId == defender.StringId
                    && string.Equals(existing.ContextId, context, StringComparison.Ordinal))
                {
                    report = "same AII event already registered; idempotent no-op";
                    return true;
                }

                report = "an active foreign or internal war is already registered for this pair";
                return false;
            }
            if (_wars.Any(war => war != null && string.Equals(war.ContextId, context, StringComparison.Ordinal)))
            {
                report = "authoritative AII event ID was already consumed in a previous war";
                return false;
            }

            WarScoreRecord record = new WarScoreRecord(
                key, attacker.StringId, defender.StringId, CurrentDay,
                BuildFiefSnapshot(attacker, defender), WarScoreConflictType.ForeignWar, context);
            _wars.Add(record);
            AddEvent(record, WarScoreEventType.WarStarted, 0f, attacker, defender,
                debugText: "authoritative AII foreign hostility observed; accounting only");
            UpdateOccupationScore(record, WarScoreEventType.OccupationUpdated, attacker, defender,
                debugText: "initial AII foreign occupation snapshot");
            BellumCivileLogger.Log(
                $"AII foreign War Score ledger registered; war={key}; attacker={attacker.StringId}; defender={defender.StringId}; event_id={aiEventId}; accounting_only=true; bellum_autonomous_peace=false.");
            report = "AII foreign war ledger registered; no Bellum autonomous settlement";
            return true;
        }

        private void ReconcileAiInfluenceForeignLedgers()
        {
            if (!HasOpenAiInfluenceForeignLedgers())
                return;

            foreach (WarScoreRecord war in GetActiveWars()
                .Where(IsAiInfluenceForeignLedger).ToList())
            {
                Kingdom attacker = ResolveKingdom(war.AttackerKingdomId);
                Kingdom defender = ResolveKingdom(war.DefenderKingdomId);
                if (attacker == null || defender == null || attacker.IsEliminated
                    || defender.IsEliminated || !attacker.IsAtWarWith(defender)
                    || !IsForeignWarPair(attacker, defender))
                {
                    MarkWarEnded(war);
                    BellumCivileLogger.Log(
                        $"AII foreign War Score ledger closed after world-state change; war={war.WarKey}; accounting_only=true.");
                    continue;
                }

                // Older in-flight/saved terminal flags must not trigger the shared
                // resolver, which otherwise falls through to MakePeaceAction.Apply.
                if (war.TerminalResolutionQueued)
                {
                    war.ClearTerminalResolution();
                    TouchRuntimeRevision();
                }
            }
        }
    }
}
