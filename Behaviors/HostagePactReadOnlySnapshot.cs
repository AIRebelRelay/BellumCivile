using System;
using System.Collections.Generic;
using System.Linq;
using TaleWorlds.CampaignSystem;

namespace BellumCivile.Behaviors
{
    // Transport-only observations. These types are NOT Saveable and have no
    // mutators, action callbacks or hostage holding-location disclosure.
    public sealed class HostageCustodyReadOnlyObservation
    {
        public string HeroId { get; private set; }
        public string SupplyingHouseId { get; private set; }
        public string ReceivingHouseId { get; private set; }
        public bool CustodyEstablished { get; private set; }
        public bool HeroIsAlive { get; private set; }
        public bool HeroIsPrisoner { get; private set; }
        public bool OriginalTreatyCustodyVerified { get; private set; }
        public bool ProtectedBySavedPact { get; private set; }
        public HostageCustodyOutcome SavedOutcome { get; private set; }
        public bool ActionCompleted { get; private set; }

        internal HostageCustodyReadOnlyObservation(TreatyHostageRecord slot, HostagePactRecord pact)
        {
            HeroId = SafeId(slot.Hero?.StringId);
            SupplyingHouseId = SafeId(slot.SupplyingHouse?.StringId);
            ReceivingHouseId = SafeId(slot.ReceivingHouse?.StringId);
            CustodyEstablished = slot.CustodyEstablished;
            HeroIsAlive = slot.Hero?.IsAlive == true;
            HeroIsPrisoner = slot.Hero?.IsPrisoner == true;
            // Do not mistake a later unrelated imprisonment for treaty custody.
            OriginalTreatyCustodyVerified = InOriginalCustody(slot);
            ProtectedBySavedPact = pact?.Protects(slot.Hero) == true;
            SavedOutcome = slot.Outcome;
            ActionCompleted = slot.ActionCompleted;
        }

        private static bool InOriginalCustody(TreatyHostageRecord slot)
        {
            return slot != null && slot.CustodyEstablished
                && slot.Hero?.IsAlive == true && slot.Hero.IsPrisoner
                && slot.Holding != null && slot.Hero.PartyBelongedToAsPrisoner == slot.Holding.Party
                && Math.Abs(slot.Hero.CaptivityStartTime.ToDays - slot.CaptivityStartDay) < 0.000001;
        }

        private static string SafeId(string value)
        {
            return string.IsNullOrWhiteSpace(value) ? "unknown" : value;
        }
    }

    public sealed class HostagePactReadOnlyObservation
    {
        public string PactId { get; private set; }
        public string TreatyProposalId { get; private set; }
        public string FirstRealmId { get; private set; }
        public string SecondRealmId { get; private set; }
        public string FirstHouseId { get; private set; }
        public string SecondHouseId { get; private set; }
        public HostagePactPhase SavedPhase { get; private set; }
        public HostagePactEndReason EndReason { get; private set; }
        public string Status { get; private set; }
        public bool RevampEnabled { get; private set; }
        public bool MechanicallyActive { get; private set; }
        public int AgreedDurationDays { get; private set; }
        public double SignedDay { get; private set; }
        public double EndDay { get; private set; }
        public HostageCustodyReadOnlyObservation FirstHostage { get; private set; }
        public HostageCustodyReadOnlyObservation SecondHostage { get; private set; }

        internal HostagePactReadOnlyObservation(HostagePactRecord pact, bool enabled, bool currentAgreement)
        {
            PactId = pact.Id;
            TreatyProposalId = SafeId(pact.TreatyProposalId);
            FirstRealmId = SafeId(pact.FirstRealm?.StringId);
            SecondRealmId = SafeId(pact.SecondRealm?.StringId);
            FirstHouseId = SafeId(pact.FirstHouse?.StringId);
            SecondHouseId = SafeId(pact.SecondHouse?.StringId);
            SavedPhase = pact.Phase;
            EndReason = pact.EndReason;
            RevampEnabled = enabled;
            MechanicallyActive = pact.Phase == HostagePactPhase.Active && enabled && currentAgreement;
            Status = StatusFor(pact.Phase, enabled, MechanicallyActive);
            AgreedDurationDays = pact.DurationDays;
            SignedDay = pact.SignedDay;
            EndDay = pact.EndDay;
            FirstHostage = pact.FirstHostage == null ? null
                : new HostageCustodyReadOnlyObservation(pact.FirstHostage, pact);
            SecondHostage = pact.SecondHostage == null ? null
                : new HostageCustodyReadOnlyObservation(pact.SecondHostage, pact);
        }

        private static string StatusFor(HostagePactPhase phase, bool enabled, bool currentAgreement)
        {
            if (phase == HostagePactPhase.Preparing) return "preparing_not_effective";
            if (phase == HostagePactPhase.Resolving) return "resolving";
            if (phase == HostagePactPhase.Ended) return "ended";
            if (phase != HostagePactPhase.Active) return "unknown";
            if (!enabled) return "active_revamp_off_pending_termination";
            return currentAgreement ? "active_confirmed" : "active_unverified";
        }

        private static string SafeId(string value)
        {
            return string.IsNullOrWhiteSpace(value) ? "unknown" : value;
        }
    }

    public sealed partial class HostagePactBehavior
    {
        // Additive, participant-realm-scoped READ ONLY Native API.
        // A Bridge caller must further narrow visibility to the actual speaker.
        // Call on the campaign thread; snapshots contain primitives, not live
        // mutable HostagePactRecord references or secret dungeon coordinates.
        public IReadOnlyList<HostagePactReadOnlyObservation> GetReadOnlyPactObservations(Kingdom realm)
        {
            if (realm == null) return Array.AsReadOnly(new HostagePactReadOnlyObservation[0]);
            bool enabled = BellumCivileOptions.EnableWarPeaceLogicRevamp;
            var currentlyListed = enabled
                ? new HashSet<HostagePactRecord>(GetActivePacts(realm))
                : new HashSet<HostagePactRecord>();
            return ProjectReadOnlyPacts(_pacts, realm, enabled, pact => currentlyListed.Contains(pact));
        }

        // Pure projection seam for tests; NEVER invokes a custody action or mutates a saved record.
        internal static IReadOnlyList<HostagePactReadOnlyObservation> ProjectReadOnlyPacts(
            IEnumerable<HostagePactRecord> pacts, Kingdom realm, bool revampEnabled,
            Func<HostagePactRecord, bool> isCurrentlyListed)
        {
            if (realm == null || pacts == null)
                return Array.AsReadOnly(new HostagePactReadOnlyObservation[0]);
            var result = pacts
                .Where(pact => pact != null && !string.IsNullOrWhiteSpace(pact.Id)
                    && pact.Phase != HostagePactPhase.Ended
                    && (pact.FirstRealm == realm || pact.SecondRealm == realm))
                .OrderBy(pact => pact.Id, StringComparer.Ordinal)
                .Select(pact => new HostagePactReadOnlyObservation(pact, revampEnabled,
                    revampEnabled && isCurrentlyListed != null && isCurrentlyListed(pact)))
                .ToArray();
            return Array.AsReadOnly(result);
        }
    }
}
