using System.Collections.Generic;
using TaleWorlds.CampaignSystem;
using TaleWorlds.SaveSystem;

namespace BellumCivile
{
    public sealed class RestoredRealmCreationRecord
    {
        [SaveableField(1)] public Kingdom Parent;
        [SaveableField(2)] public Kingdom Source;
        [SaveableField(3)] public Clan Founder;
        [SaveableField(4)] public Kingdom Successor;
        [SaveableField(5)] public string SuccessorId;
        [SaveableField(6)] public bool Initialized;
        [SaveableField(7)] public bool MovesComplete;
        [SaveableField(8)] public bool Ready;
        [SaveableField(9)] public bool Replacement;
        [SaveableField(10)] public FactionObject Owner;
        [SaveableField(11)] public SuccessionChallengeRecord Challenge;
        [SaveableField(12)] public List<Clan> Houses = new List<Clan>();
        [SaveableField(13)] public bool CreatedNotified;
        [SaveableField(14)] public string Failure;
        [SaveableField(15)] public bool ParentWasEliminated;
        [SaveableField(16)] public List<Clan> ParentHouses = new List<Clan>();
        [SaveableField(17)] public List<Kingdom> ExternalEnemies = new List<Kingdom>();

        // Historical preparation evidence only; not political settlement or NPC knowledge.
        [SaveableField(18)] public string PreparationReceiptId;
        [SaveableField(19)] public double PreparationDay;
        [SaveableField(20)] public string PreparationParentId;
        [SaveableField(21)] public string PreparationSourceId;
        [SaveableField(22)] public string PreparationSuccessorId;
        [SaveableField(23)] public string PreparationFounderHouseId;
        [SaveableField(24)] public string PreparationRulingHouseId;
        [SaveableField(25)] public string PreparationRulerHeroId;
        [SaveableField(26)] public bool PreparationWasReplacement;
        [SaveableField(27)] public string PreparationChallengeId;

        internal bool Protects(Kingdom realm) => !Ready && realm != null
            && (realm == Parent || !MovesComplete && (realm == Source || realm == Successor || realm.StringId == SuccessorId));
    }
}
