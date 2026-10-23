using System.Collections.Generic;
using BellumCivile.Behaviors;
using TaleWorlds.CampaignSystem;

namespace BellumCivile
{
    public static partial class BellumIntegration
    {
        /// <summary>Stage an NPC faction request; no filing, payment, vote or appointment.</summary>
        public static NpcCouncilAppointmentIntentSubmission TryStageNpcCouncilAppointmentIntent(
            Kingdom realm, Clan sponsor, FactionObject faction, PrivyCouncilOffice office,
            Clan requestedCandidate, string externalIntentId)
        {
            BellumIntegrationBehavior.RequireCampaignThread();
            var court = CourtAgendaBehavior.Current;
            return court == null
                ? new NpcCouncilAppointmentIntentSubmission(false, "court_unavailable", null)
                : court.TryStageNpcCouncilAppointmentIntent(realm, sponsor, faction, office,
                    requestedCandidate, externalIntentId);
        }

        /// <summary>
        /// Read-only, actor- and faction-scoped executable Court nomination pairs.
        /// Does not stage, charge influence, nominate, or open a Court session.
        /// </summary>
        public static IReadOnlyList<NpcCouncilAppointmentOptionSnapshot> GetNpcCouncilAppointmentOptions(
            Kingdom realm, Clan sponsor, FactionObject faction)
        {
            BellumIntegrationBehavior.RequireCampaignThread();
            return CourtAgendaBehavior.Current?.GetNpcCouncilAppointmentOptions(realm, sponsor, faction)
                ?? new NpcCouncilAppointmentOptionSnapshot[0];
        }

        /// <summary>Exact persisted ticket status; only native Court state can prove an outcome.</summary>
        public static NpcCouncilAppointmentIntentSnapshot GetNpcCouncilAppointmentIntent(
            Kingdom realm, string externalIntentId)
        {
            BellumIntegrationBehavior.RequireCampaignThread();
            return CourtAgendaBehavior.Current?.GetNpcCouncilAppointmentIntent(realm, externalIntentId);
        }

        /// <summary>Read-only inventory for Bridge reconciliation after save/reload.</summary>
        public static IReadOnlyList<NpcCouncilAppointmentIntentSnapshot> GetNpcCouncilAppointmentIntents(Kingdom realm)
        {
            BellumIntegrationBehavior.RequireCampaignThread();
            return CourtAgendaBehavior.Current?.GetNpcCouncilAppointmentIntents(realm)
                ?? new NpcCouncilAppointmentIntentSnapshot[0];
        }
    }
}
