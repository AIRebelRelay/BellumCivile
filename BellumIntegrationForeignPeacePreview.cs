using System;
using System.Collections.Generic;
using System.Linq;
using BellumCivile.Behaviors;
using TaleWorlds.CampaignSystem;

namespace BellumCivile
{
    public static partial class BellumIntegration
    {
        /// <summary>
        /// Eligibility-only, detached snapshot for an NPC foreign-peace proposal.
        /// NO offer is queued, NO terms are drafted and NO treaty can be applied.
        /// Native still has no negotiated-treaty commit gateway in this stage.
        /// </summary>
        public static ForeignPeaceEligibilitySnapshot GetForeignPeaceEligibility(
            Hero speaker, Kingdom target)
        {
            BellumIntegrationBehavior.RequireCampaignThread();

            var reasons = new List<string>();
            Kingdom source = speaker?.Clan?.Kingdom;
            float gameDay = (float)CampaignTime.Now.ToDays;
            ForeignPeaceLegality legality = ForeignPeaceLegality.AllowedToPropose;
            ForeignPeaceReplyOwner replyOwner = ForeignPeaceReplyOwner.Unknown;
            ForeignPeaceWarRead war = new ForeignPeaceWarRead(
                ForeignPeaceWarTracking.Unknown, null, null, null);
            int? clientRevision = null;

            if (target?.RulingClan != null)
            {
                replyOwner = target.RulingClan == Clan.PlayerClan
                    || target.RulingClan.Leader == Hero.MainHero
                        ? ForeignPeaceReplyOwner.Player : ForeignPeaceReplyOwner.Npc;
            }
            else
            {
                reasons.Add("recipient_authority_unknown");
                legality = ForeignPeaceLegality.Unknown;
            }

            if (speaker == null || source == null || target == null
                || !Kingdom.All.Contains(source) || !Kingdom.All.Contains(target))
            {
                reasons.Add("campaign_realm_or_actor_missing");
                legality = ForeignPeaceLegality.Blocked;
            }
            else
            {
                if (speaker.IsDead || !Hero.AllAliveHeroes.Contains(speaker))
                {
                    reasons.Add("actor_not_alive_in_campaign");
                    legality = ForeignPeaceLegality.Blocked;
                }

                if (source.RulingClan?.Leader != speaker)
                {
                    reasons.Add("actor_not_reigning_ruler");
                    legality = ForeignPeaceLegality.Blocked;
                }

                if (speaker == Hero.MainHero || speaker.Clan == Clan.PlayerClan)
                {
                    reasons.Add("player_actor_requires_manual_authority");
                    legality = ForeignPeaceLegality.Blocked;
                }

                if (source == target)
                {
                    reasons.Add("same_kingdom");
                    legality = ForeignPeaceLegality.Blocked;
                }

                if (source.IsEliminated || target.IsEliminated
                    || source.RulingClan?.Leader == null || target.RulingClan?.Leader == null
                    || string.IsNullOrWhiteSpace(source.StringId)
                    || string.IsNullOrWhiteSpace(target.StringId))
                {
                    reasons.Add("invalid_or_eliminated_realm");
                    legality = ForeignPeaceLegality.Blocked;
                }

                if (BellumKingdomVisibilityHelper.IsTemporaryBellumKingdom(source)
                    || BellumKingdomVisibilityHelper.IsTemporaryBellumKingdom(target))
                {
                    reasons.Add("bellum_internal_or_temporary_realm");
                    legality = ForeignPeaceLegality.Blocked;
                }

                if (!source.IsAtWarWith(target))
                {
                    reasons.Add("realms_not_at_war");
                    legality = ForeignPeaceLegality.Blocked;
                }

                WarScoreBehavior warScores = Campaign.Current.GetCampaignBehavior<WarScoreBehavior>();
                if (warScores == null)
                {
                    reasons.Add("war_score_behavior_unavailable");
                    if (legality != ForeignPeaceLegality.Blocked)
                        legality = ForeignPeaceLegality.Unknown;
                }
                else
                {
                    war = warScores.PeekForeignPeaceWar(source.StringId, target.StringId);
                    if (war.Tracking == ForeignPeaceWarTracking.TrackedOtherConflict)
                    {
                        reasons.Add("internal_or_nonforeign_war_tracker");
                        legality = ForeignPeaceLegality.Blocked;
                    }
                    else if (war.Tracking == ForeignPeaceWarTracking.Unknown)
                    {
                        reasons.Add("war_tracking_unknown");
                        if (legality != ForeignPeaceLegality.Blocked)
                            legality = ForeignPeaceLegality.Unknown;
                    }
                    else if (war.Tracking == ForeignPeaceWarTracking.UntrackedForeignWar)
                        reasons.Add("foreign_war_untracked_revamp_off_possible");
                    else if (war.Tracking == ForeignPeaceWarTracking.AccountingOnlyForeignWar)
                        reasons.Add("foreign_war_accounting_only");
                }

                ClientKingdomBehavior client = Campaign.Current.GetCampaignBehavior<ClientKingdomBehavior>();
                if (client == null)
                {
                    reasons.Add("client_authority_unavailable");
                    if (legality != ForeignPeaceLegality.Blocked)
                        legality = ForeignPeaceLegality.Unknown;
                }
                else
                {
                    clientRevision = client.RuntimeRevision;
                    ForeignPeaceClientRead clientVerdict = client.PeekForeignPeaceClientStatus(source, target);
                    if (clientVerdict == ForeignPeaceClientRead.Blocked)
                    {
                        reasons.Add("client_or_suzerain_peace_restriction");
                        legality = ForeignPeaceLegality.Blocked;
                    }
                    else if (clientVerdict == ForeignPeaceClientRead.Unknown)
                    {
                        reasons.Add("client_authority_unknown");
                        if (legality != ForeignPeaceLegality.Blocked)
                            legality = ForeignPeaceLegality.Unknown;
                    }
                }

                ForeignPeaceOptionalVerdict storyVerdict =
                    ForeignPeaceOptionalModSafetyProbe.CheckStoryMode(source, target);
                if (storyVerdict == ForeignPeaceOptionalVerdict.Blocked)
                {
                    reasons.Add("story_mode_peace_protected");
                    legality = ForeignPeaceLegality.Blocked;
                }
                else if (storyVerdict == ForeignPeaceOptionalVerdict.Unknown)
                {
                    reasons.Add("story_mode_quest_protection_unverified");
                    if (legality != ForeignPeaceLegality.Blocked)
                        legality = ForeignPeaceLegality.Unknown;
                }

                ForeignPeaceOptionalVerdict diplomacyVerdict =
                    ForeignPeaceOptionalModSafetyProbe.CheckDiplomacyRebels(source, target);
                if (diplomacyVerdict == ForeignPeaceOptionalVerdict.Blocked)
                {
                    reasons.Add("diplomacy_rebel_kingdom");
                    legality = ForeignPeaceLegality.Blocked;
                }
                else if (diplomacyVerdict == ForeignPeaceOptionalVerdict.Unknown)
                {
                    reasons.Add("diplomacy_rebel_classification_unverified");
                    if (legality != ForeignPeaceLegality.Blocked)
                        legality = ForeignPeaceLegality.Unknown;
                }
            }

            if (replyOwner == ForeignPeaceReplyOwner.Unknown)
            {
                reasons.Add("recipient_cannot_be_assigned_to_llm");
                if (legality != ForeignPeaceLegality.Blocked)
                    legality = ForeignPeaceLegality.Unknown;
            }

            // No Native LLM treaty submission/receipt gateway has been implemented.
            // Never claim a peace offer is executable just because the war is tracked.
            reasons.Add("negotiated_treaty_gateway_not_implemented");
            return new ForeignPeaceEligibilitySnapshot(
                speaker?.StringId, source?.StringId, target?.StringId, gameDay,
                legality, ForeignPeaceExecutionReadiness.NotReady,
                replyOwner, war.Tracking, war.WarKey, war.Score, war.Revision,
                clientRevision, reasons);
        }
    }
}
