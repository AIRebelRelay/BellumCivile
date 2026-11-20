namespace BellumCivile
{
    // A matching timestamp is NOT a unique Native war incarnation and NEVER grants
    // permission to execute a treaty/LLM decision. There is no affirmative authority state.
    public enum ForeignWarNativeWitnessStatus
    {
        IdentityUnavailable = 0,
        Unwitnessed = 1,
        AmbiguousDeclaration = 2,
        NativeStartUnavailable = 3,
        NativeStartChanged = 4,
        WeakTimestampMatchNotProof = 5
    }

    public sealed class ForeignWarNativeWitnessSnapshot
    {
        public const int ApiVersion = 1;
        public ForeignConflictIdentityStatus IdentityStatus { get; }
        public ForeignWarNativeWitnessStatus WitnessStatus { get; }
        public string ConflictInstanceId { get; }
        public double? RecordedNativeStartDay { get; }
        public double? CurrentNativeStartDay { get; }
        public bool AuthorizesAction => false;

        internal ForeignWarNativeWitnessSnapshot(
            ForeignConflictIdentityStatus identityStatus,
            ForeignWarNativeWitnessStatus witnessStatus,
            string instanceId = null, double? recordedDay = null, double? currentDay = null)
        {
            IdentityStatus = identityStatus;
            WitnessStatus = witnessStatus;
            ConflictInstanceId = instanceId;
            RecordedNativeStartDay = recordedDay;
            CurrentNativeStartDay = currentDay;
        }
    }
}
