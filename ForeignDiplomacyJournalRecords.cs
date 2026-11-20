using System.Collections.Generic;
using TaleWorlds.SaveSystem;

namespace BellumCivile
{
    // Separate additive schema. No Native treaty, consent, execution receipt or live actor reference.
    public sealed class ForeignDiplomacyJournalState
    {
        [SaveableField(1)] public int SchemaVersion;
        [SaveableField(2)] public string CampaignId;
        [SaveableField(3)] public List<ForeignDiplomacyIntentRecord> Entries;
    }

    public sealed class ForeignDiplomacyIntentRecord
    {
        [SaveableField(1)] public string OperationId;
        [SaveableField(2)] public string RequestKey;
        [SaveableField(3)] public string OwnerId;
        [SaveableField(4)] public string OriginId;
        [SaveableField(5)] public string FirstKingdomId;
        [SaveableField(6)] public string SecondKingdomId;
        [SaveableField(7)] public string FirstRulerId;
        [SaveableField(8)] public string SecondRulerId;
        [SaveableField(9)] public string ConflictEpoch;
        [SaveableField(10)] public string DraftFingerprint;
        [SaveableField(11)] public int Source;
        [SaveableField(12)] public double CreatedDay;
        [SaveableField(13)] public bool Cancelled;
    }
}
