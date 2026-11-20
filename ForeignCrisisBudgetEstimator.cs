using System;
using System.Collections.Generic;
using System.Linq;

namespace BellumCivile
{
    internal enum ForeignCrisisEstimateMode { Unknown = 0, MeasuredEndToEnd, TokenEstimate, ExplicitAllowance }
    internal enum ForeignCrisisBudgetStatus
    {
        InvalidConfiguration = 0, Ready, InvalidPlan, MissingProfile, ProfileMismatch,
        ProfileOutOfRange, InvalidLatency, DoesNotFit, NumericOverflow
    }

    // Trusted adapter must key by route/provider/model/reasoning configuration, not LLM text.
    // Provider duration excludes the separate Relay queue, includes provider-side queue/TTFT/generation.
    internal sealed class ForeignCrisisLatencyProfile
    {
        internal readonly string RouteKey;
        internal readonly bool ReasoningEnabled;
        internal readonly int MaxInputTokens, MaxOutputTokens;
        internal readonly ForeignCrisisEstimateMode Mode;
        internal readonly double? ProviderSeconds, TtftSeconds, ConservativeTps, ExtraReasoningSeconds;
        internal ForeignCrisisLatencyProfile(string routeKey, bool reasoningEnabled, int maxInputTokens,
            int maxOutputTokens, ForeignCrisisEstimateMode mode, double? providerSeconds,
            double? ttftSeconds, double? conservativeTps, double? extraReasoningSeconds)
        {
            RouteKey = routeKey; ReasoningEnabled = reasoningEnabled;
            MaxInputTokens = maxInputTokens; MaxOutputTokens = maxOutputTokens; Mode = mode;
            ProviderSeconds = providerSeconds; TtftSeconds = ttftSeconds;
            ConservativeTps = conservativeTps; ExtraReasoningSeconds = extraReasoningSeconds;
        }
    }

    // One serial call position in the planned full cycle. Repeated positions are NOT deduplicated.
    internal sealed class ForeignCrisisPlannedCall
    {
        internal readonly string RouteKey;
        internal readonly int InputTokens, OutputTokens, MaxAttempts;
        internal readonly double RelayQueueSeconds, RetryBackoffSeconds;
        internal readonly bool ReasoningEnabled;
        internal readonly ForeignCrisisLatencyProfile Profile;
        internal ForeignCrisisPlannedCall(string routeKey, int inputTokens, int outputTokens,
            int maxAttempts, double relayQueueSeconds, double retryBackoffSeconds,
            bool reasoningEnabled, ForeignCrisisLatencyProfile profile)
        {
            RouteKey = routeKey; InputTokens = inputTokens; OutputTokens = outputTokens;
            MaxAttempts = maxAttempts; RelayQueueSeconds = relayQueueSeconds;
            RetryBackoffSeconds = retryBackoffSeconds; ReasoningEnabled = reasoningEnabled; Profile = profile;
        }
    }

    internal sealed class ForeignCrisisBudgetResult
    {
        internal readonly ForeignCrisisBudgetStatus Status;
        internal readonly double PlannedSeconds, RequiredSeconds, BudgetSeconds;
        internal readonly int RejectedCallIndex;
        internal ForeignCrisisBudgetResult(ForeignCrisisBudgetStatus status, double planned = 0,
            double required = 0, double budget = 0, int rejectedCallIndex = -1)
        { Status = status; PlannedSeconds = planned; RequiredSeconds = required; BudgetSeconds = budget; RejectedCallIndex = rejectedCallIndex; }
    }

    // Pure estimate only. No calibration collection, route dispatch, clock/deadline, save state or game effects.
    internal static class ForeignCrisisBudgetEstimator
    {
        internal const int MaxCalls = 64;
        internal const int MaxAttemptsPerCall = 8;
        private static bool Finite(double n) => !double.IsNaN(n) && !double.IsInfinity(n);
        private static bool Nonnegative(double n) => Finite(n) && n >= 0;
        private static bool Positive(double? n) => n.HasValue && Finite(n.Value) && n.Value > 0;
        private static bool ValidRoute(string s) => !string.IsNullOrWhiteSpace(s)
            && s.Length <= 256 && s == s.Trim() && !s.Any(char.IsControl);

        internal static ForeignCrisisBudgetResult Estimate(IReadOnlyList<ForeignCrisisPlannedCall> calls,
            double safetyFactor, double minimumSeconds, double hardCapSeconds)
        {
            if (!Finite(safetyFactor) || safetyFactor < 1 || !Positive(minimumSeconds)
                || !Positive(hardCapSeconds) || hardCapSeconds < minimumSeconds)
                return new ForeignCrisisBudgetResult(ForeignCrisisBudgetStatus.InvalidConfiguration);
            if (calls == null || calls.Count == 0 || calls.Count > MaxCalls)
                return new ForeignCrisisBudgetResult(ForeignCrisisBudgetStatus.InvalidPlan);
            double total = 0;
            for (int index = 0; index < calls.Count; index++)
            {
                var call = calls[index];
                if (call == null || !ValidRoute(call.RouteKey) || call.InputTokens < 0 || call.OutputTokens <= 0
                    || call.MaxAttempts < 1 || call.MaxAttempts > MaxAttemptsPerCall
                    || !Nonnegative(call.RelayQueueSeconds) || !Nonnegative(call.RetryBackoffSeconds))
                    return new ForeignCrisisBudgetResult(ForeignCrisisBudgetStatus.InvalidPlan, rejectedCallIndex: index);
                var p = call.Profile;
                if (p == null)
                    return new ForeignCrisisBudgetResult(ForeignCrisisBudgetStatus.MissingProfile, rejectedCallIndex: index);
                if (p.RouteKey != call.RouteKey || p.ReasoningEnabled != call.ReasoningEnabled)
                    return new ForeignCrisisBudgetResult(ForeignCrisisBudgetStatus.ProfileMismatch, rejectedCallIndex: index);
                if (p.MaxInputTokens <= 0 || p.MaxOutputTokens <= 0)
                    return new ForeignCrisisBudgetResult(ForeignCrisisBudgetStatus.InvalidLatency, rejectedCallIndex: index);
                if (call.InputTokens > p.MaxInputTokens || call.OutputTokens > p.MaxOutputTokens)
                    return new ForeignCrisisBudgetResult(ForeignCrisisBudgetStatus.ProfileOutOfRange, rejectedCallIndex: index);
                double provider;
                switch (p.Mode)
                {
                    case ForeignCrisisEstimateMode.MeasuredEndToEnd:
                    case ForeignCrisisEstimateMode.ExplicitAllowance:
                        if (!Positive(p.ProviderSeconds))
                            return new ForeignCrisisBudgetResult(ForeignCrisisBudgetStatus.InvalidLatency, rejectedCallIndex: index);
                        provider = p.ProviderSeconds.Value;
                        break;
                    case ForeignCrisisEstimateMode.TokenEstimate:
                        if (!p.TtftSeconds.HasValue || !Nonnegative(p.TtftSeconds.Value) || !Positive(p.ConservativeTps)
                            || (call.ReasoningEnabled && (!p.ExtraReasoningSeconds.HasValue || !Nonnegative(p.ExtraReasoningSeconds.Value))))
                            return new ForeignCrisisBudgetResult(ForeignCrisisBudgetStatus.InvalidLatency, rejectedCallIndex: index);
                        provider = p.TtftSeconds.Value + call.OutputTokens / p.ConservativeTps.Value
                            + (call.ReasoningEnabled ? p.ExtraReasoningSeconds.Value : 0);
                        break;
                    default:
                        return new ForeignCrisisBudgetResult(ForeignCrisisBudgetStatus.InvalidLatency, rejectedCallIndex: index);
                }
                double callTotal = (call.RelayQueueSeconds + provider) * call.MaxAttempts
                    + call.RetryBackoffSeconds * (call.MaxAttempts - 1);
                total += callTotal;
                if (!Finite(provider) || !Finite(callTotal) || !Finite(total))
                    return new ForeignCrisisBudgetResult(ForeignCrisisBudgetStatus.NumericOverflow, rejectedCallIndex: index);
            }
            double required = Math.Max(minimumSeconds, total * safetyFactor);
            if (!Finite(required)) return new ForeignCrisisBudgetResult(ForeignCrisisBudgetStatus.NumericOverflow);
            if (required > hardCapSeconds)
                return new ForeignCrisisBudgetResult(ForeignCrisisBudgetStatus.DoesNotFit, total, required);
            return new ForeignCrisisBudgetResult(ForeignCrisisBudgetStatus.Ready, total, required, required);
        }
    }
}
