namespace BellumCivile
{
    // Explicit provenance supplied by a future, audited runtime adapter.
    // Unknown must not become an executable foreign action by default.
    internal enum ForeignDiplomacySource
    {
        Unknown = 0,
        AutomaticForeignWar,
        AutomaticForeignPeace,
        AutomaticForeignParley,
        PendingForeignRatification,
        TerminalForeignWar,
        PlayerAction,
        InternalConflict,
        ClientObligation,
        ExistingTreatyObligation,
        VoluntaryPact,
        HostageChoice
    }

    internal enum ForeignDiplomacyAdmission
    {
        Hold = 0,
        Legacy,
        RequestLlmIntent,
        ContinueNativeValidation,
        RequestCrisisResolution
    }

    internal enum ForeignDiplomacyActivation
    {
        MissingReadiness = 0,
        RevampDisabled,
        MissingCampaignScope,
        MissingDurableOwner,
        MissingDurableQueue,
        MissingSaveRecovery,
        MissingNativeGateway,
        MissingDraftConsentVerifier,
        MissingBoundedCrisisHandler,
        PendingOrUnknownLegacyWork,
        Ready
    }

    // Capability facts, not configuration switches. No engine calls or mutable registry.
    // Runtime construction and verification are deliberately outside this stage.
    internal sealed class ForeignDiplomacyReadiness
    {
        internal readonly bool RevampEnabled;
        internal readonly bool CampaignScopeBound;
        internal readonly bool DurableOwnerReady;
        internal readonly bool DurableQueueReady;
        internal readonly bool SaveRecoveryReady;
        internal readonly bool NativeGatewayReady;
        internal readonly bool DraftConsentVerifierReady;
        internal readonly bool BoundedCrisisHandlerReady;
        internal readonly int LegacyPendingCount;

        internal ForeignDiplomacyReadiness(bool revampEnabled = false, bool campaignScopeBound = false,
            bool durableOwnerReady = false, bool durableQueueReady = false, bool saveRecoveryReady = false,
            bool nativeGatewayReady = false, bool draftConsentVerifierReady = false,
            bool boundedCrisisHandlerReady = false, int legacyPendingCount = -1)
        {
            RevampEnabled = revampEnabled;
            CampaignScopeBound = campaignScopeBound;
            DurableOwnerReady = durableOwnerReady;
            DurableQueueReady = durableQueueReady;
            SaveRecoveryReady = saveRecoveryReady;
            NativeGatewayReady = nativeGatewayReady;
            DraftConsentVerifierReady = draftConsentVerifierReady;
            BoundedCrisisHandlerReady = boundedCrisisHandlerReady;
            LegacyPendingCount = legacyPendingCount;
        }
    }

    /// <summary>
    /// Pure admission rules only. No current game caller activates or consumes this policy.
    /// Legacy means retain the existing owner's rules, never unconditional execution.
    /// Hold is an admission result, not a durable pending record or crisis timeout policy.
    /// </summary>
    internal static class ForeignDiplomacyAdmissionPolicy
    {
        internal static ForeignDiplomacyActivation CheckActivation(ForeignDiplomacyReadiness readiness)
        {
            if (readiness == null) return ForeignDiplomacyActivation.MissingReadiness;
            if (!readiness.RevampEnabled) return ForeignDiplomacyActivation.RevampDisabled;
            if (!readiness.CampaignScopeBound) return ForeignDiplomacyActivation.MissingCampaignScope;
            if (!readiness.DurableOwnerReady) return ForeignDiplomacyActivation.MissingDurableOwner;
            if (!readiness.DurableQueueReady) return ForeignDiplomacyActivation.MissingDurableQueue;
            if (!readiness.SaveRecoveryReady) return ForeignDiplomacyActivation.MissingSaveRecovery;
            if (!readiness.NativeGatewayReady) return ForeignDiplomacyActivation.MissingNativeGateway;
            if (!readiness.DraftConsentVerifierReady) return ForeignDiplomacyActivation.MissingDraftConsentVerifier;
            if (!readiness.BoundedCrisisHandlerReady) return ForeignDiplomacyActivation.MissingBoundedCrisisHandler;
            if (readiness.LegacyPendingCount != 0) return ForeignDiplomacyActivation.PendingOrUnknownLegacyWork;
            return ForeignDiplomacyActivation.Ready;
        }

        // Inputs must come from an audited adapter, not the LLM or user-provided JSON.
        // ownerReady includes the active capability checks above and campaign/ruler/scope revalidation.
        // exactDraftConsent includes both current rulers, war incarnation and draft revision.
        internal static ForeignDiplomacyAdmission Evaluate(bool controlledMode, bool inOwnedScope,
            bool ownerReady, ForeignDiplomacySource source, bool exactDraftConsent)
        {
            if (!controlledMode || !inOwnedScope) return ForeignDiplomacyAdmission.Legacy;
            switch (source)
            {
                case ForeignDiplomacySource.PlayerAction:
                case ForeignDiplomacySource.InternalConflict:
                case ForeignDiplomacySource.ClientObligation:
                case ForeignDiplomacySource.ExistingTreatyObligation:
                case ForeignDiplomacySource.VoluntaryPact:
                case ForeignDiplomacySource.HostageChoice:
                    return ForeignDiplomacyAdmission.Legacy;
            }
            if (!ownerReady) return ForeignDiplomacyAdmission.Hold;
            switch (source)
            {
                case ForeignDiplomacySource.AutomaticForeignWar:
                case ForeignDiplomacySource.AutomaticForeignPeace:
                case ForeignDiplomacySource.AutomaticForeignParley:
                    return ForeignDiplomacyAdmission.RequestLlmIntent;
                case ForeignDiplomacySource.PendingForeignRatification:
                    return exactDraftConsent
                        ? ForeignDiplomacyAdmission.ContinueNativeValidation
                        : ForeignDiplomacyAdmission.Hold;
                case ForeignDiplomacySource.TerminalForeignWar:
                    return ForeignDiplomacyAdmission.RequestCrisisResolution;
                default:
                    return ForeignDiplomacyAdmission.Hold;
            }
        }
    }
}
