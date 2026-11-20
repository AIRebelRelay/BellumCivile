using System;

namespace BellumCivile
{
    internal enum ForeignCrisisReplyState
    {
        Pending = 0, ValidTerminalResponse, TechnicalFailure, StaleOrInvalidResponse
    }

    internal enum ForeignCrisisWindowStatus
    {
        Invalid = 0, Paused, WaitCampaignFloor, WaitOpportunity, ReadyForNativeAssessment
    }

    // Immutable in-memory observation only. No Saveable fields or engine lifecycle registration.
    internal sealed class ForeignCrisisWindowState
    {
        internal readonly double OpeningDay, MinimumCampaignDays, BudgetSeconds;
        internal readonly double LastObservedDay, SpentActiveSeconds;
        internal double CampaignFloorDay => OpeningDay + MinimumCampaignDays;
        internal ForeignCrisisWindowState(double openingDay, double minimumCampaignDays,
            double budgetSeconds, double lastObservedDay, double spentActiveSeconds)
        {
            OpeningDay = openingDay; MinimumCampaignDays = minimumCampaignDays; BudgetSeconds = budgetSeconds;
            LastObservedDay = lastObservedDay; SpentActiveSeconds = spentActiveSeconds;
        }
    }

    internal sealed class ForeignCrisisWindowDecision
    {
        internal readonly ForeignCrisisWindowStatus Status;
        internal readonly ForeignCrisisWindowState Next;
        internal ForeignCrisisWindowDecision(ForeignCrisisWindowStatus status, ForeignCrisisWindowState next = null)
        { Status = status; Next = next; }
    }

    // Pure observation policy: supplied time is trusted adapter data, NEVER model payload.
    // Does not measure TPS/time, persist progress, validate a ruler/war/draft, or execute a treaty.
    internal static class ForeignCrisisWindowPolicy
    {
        private static bool Finite(double n) => !double.IsNaN(n) && !double.IsInfinity(n);
        private static bool Nonnegative(double n) => Finite(n) && n >= 0;
        private static bool Positive(double n) => Finite(n) && n > 0;
        private static bool ValidState(ForeignCrisisWindowState s) => s != null
            && Nonnegative(s.OpeningDay) && Positive(s.MinimumCampaignDays) && Positive(s.BudgetSeconds)
            && Finite(s.CampaignFloorDay) && s.CampaignFloorDay > s.OpeningDay
            && Nonnegative(s.LastObservedDay) && s.LastObservedDay >= s.OpeningDay
            && Nonnegative(s.SpentActiveSeconds);

        internal static bool TryOpen(double openingDay, double minimumCampaignDays,
            ForeignCrisisBudgetResult budget, out ForeignCrisisWindowState state)
        {
            state = null;
            if (budget == null || budget.Status != ForeignCrisisBudgetStatus.Ready)
                return false;
            var candidate = new ForeignCrisisWindowState(openingDay, minimumCampaignDays,
                budget.BudgetSeconds, openingDay, 0);
            if (!ValidState(candidate)) return false;
            state = candidate;
            return true;
        }

        // totalActiveSeconds is an ABSOLUTE cumulative amount for this window, not a delta.
        // Future adapter must exclude offline UTC gaps and reconcile unknown interrupted work.
        // Current valid response is re-supplied per observation; success is intentionally not latched.
        internal static ForeignCrisisWindowDecision Observe(ForeignCrisisWindowState state,
            double currentCampaignDay, double totalActiveSeconds, bool campaignPaused,
            ForeignCrisisReplyState reply)
        {
            if (!ValidState(state) || !Nonnegative(currentCampaignDay) || !Nonnegative(totalActiveSeconds)
                || currentCampaignDay < state.LastObservedDay || totalActiveSeconds < state.SpentActiveSeconds
                || (reply != ForeignCrisisReplyState.Pending && reply != ForeignCrisisReplyState.ValidTerminalResponse
                    && reply != ForeignCrisisReplyState.TechnicalFailure && reply != ForeignCrisisReplyState.StaleOrInvalidResponse))
                return new ForeignCrisisWindowDecision(ForeignCrisisWindowStatus.Invalid);

            var next = new ForeignCrisisWindowState(state.OpeningDay, state.MinimumCampaignDays,
                state.BudgetSeconds, currentCampaignDay, totalActiveSeconds);
            if (campaignPaused) return new ForeignCrisisWindowDecision(ForeignCrisisWindowStatus.Paused, next);
            if (currentCampaignDay < state.CampaignFloorDay)
                return new ForeignCrisisWindowDecision(ForeignCrisisWindowStatus.WaitCampaignFloor, next);
            if (reply != ForeignCrisisReplyState.ValidTerminalResponse && totalActiveSeconds < state.BudgetSeconds)
                return new ForeignCrisisWindowDecision(ForeignCrisisWindowStatus.WaitOpportunity, next);
            // Only timing eligibility for fresh Native assessment. This is NOT consent or execution permission.
            return new ForeignCrisisWindowDecision(ForeignCrisisWindowStatus.ReadyForNativeAssessment, next);
        }
    }
}
