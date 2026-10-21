using System.Collections.Generic;
using BellumCivile.Behaviors;
using TaleWorlds.CampaignSystem;

namespace BellumCivile
{
    public static partial class BellumIntegration
    {
        /// <summary>
        /// Stage an exact NPC Crown treason request without executing, announcing, or scheduling it.
        /// Requires active campaign thread. This is preparatory API, NOT a completed political action.
        /// </summary>
        public static NpcCrownTreasonIntentSubmission TryStageNpcTreasonIntent(
            Kingdom realm, Clan rulerClan, Clan targetClan, string externalIntentId)
        {
            BellumIntegrationBehavior.RequireCampaignThread();
            var court = CourtAgendaBehavior.Current;
            return court == null
                ? new NpcCrownTreasonIntentSubmission(false, "court_unavailable", null)
                : court.TryStageNpcTreasonIntent(realm, rulerClan, targetClan, externalIntentId);
        }

        /// <summary>
        /// Return a stable, realm-scoped inventory of already persisted NPC Crown tickets.
        /// Read-only: this does not stage, reissue or advance any Court motion.
        /// Caller must be on the active Bannerlord campaign thread.
        /// </summary>
        public static IReadOnlyList<NpcCrownTreasonIntentSnapshot> GetNpcTreasonIntents(Kingdom realm)
        {
            BellumIntegrationBehavior.RequireCampaignThread();
            return CourtAgendaBehavior.Current?.GetNpcTreasonIntents(realm)
                ?? new List<NpcCrownTreasonIntentSnapshot>();
        }

        /// <summary>Read a durable staging ticket. null means absent or mismatched realm.</summary>
        public static NpcCrownTreasonIntentSnapshot GetNpcTreasonIntent(
            Kingdom realm, string externalIntentId)
        {
            BellumIntegrationBehavior.RequireCampaignThread();
            return CourtAgendaBehavior.Current?.GetNpcTreasonIntent(realm, externalIntentId);
        }
    }
}
