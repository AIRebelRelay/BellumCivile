using System;
using System.Collections.Generic;
using TaleWorlds.CampaignSystem;

namespace BellumCivile.Behaviors
{
    public sealed partial class BellumIntegrationBehavior
    {
        private ForeignDiplomacyJournalState _foreignDiplomacyState = ForeignDiplomacyJournal.CreateState();
        // Never serialized. Reload invalidates all previously issued session tokens.
        private ForeignDiplomacyJournal _foreignDiplomacyJournal;

        private void PrepareForeignDiplomacySync(IDataStore store)
        {
            if (store.IsLoading)
            {
                // Invalidate before accessing the store: a failed load cannot retain a live old token.
                _foreignDiplomacyJournal = null;
                _foreignDiplomacyState = null;
            }
        }

        private void SyncForeignDiplomacy(IDataStore store)
        {
            bool found = store.SyncData("BC_Integration_ForeignDiplomacyJournal_v1", ref _foreignDiplomacyState);
            if (store.IsLoading && !found)
                _foreignDiplomacyState = ForeignDiplomacyJournal.CreateState();
            // Present-null, future and corrupt payloads remain saved evidence and become unavailable.
        }

        private ForeignDiplomacyJournal GetForeignDiplomacyJournal()
        {
            RequireCampaignThread();
            if (!ReferenceEquals(Current, this))
                throw new InvalidOperationException("Foreign diplomacy journal belongs to another campaign behavior.");
            return _foreignDiplomacyJournal ?? (_foreignDiplomacyJournal = new ForeignDiplomacyJournal(_foreignDiplomacyState));
        }

        internal ForeignDiplomacyJournalSession GetForeignDiplomacyJournalSession() => GetForeignDiplomacyJournal().Session;

        internal ForeignDiplomacyJournalResult BeginForeignDiplomacyIntent(ForeignDiplomacyJournalSession session,
            ForeignDiplomacyIntentRequest request, double day, out ForeignDiplomacyIntentSnapshot snapshot) =>
            GetForeignDiplomacyJournal().Begin(session, request, day, out snapshot);

        internal ForeignDiplomacyJournalResult GetForeignDiplomacyIntentForRevalidation(ForeignDiplomacyJournalSession session,
            string requestKey, string ownerId, out ForeignDiplomacyIntentSnapshot snapshot) =>
            GetForeignDiplomacyJournal().GetForRevalidation(session, requestKey, ownerId, out snapshot);

        internal ForeignDiplomacyJournalResult ListForeignDiplomacyIntentsForRevalidation(ForeignDiplomacyJournalSession session,
            string ownerId, out IReadOnlyList<ForeignDiplomacyIntentSnapshot> snapshots) =>
            GetForeignDiplomacyJournal().ListPendingForRevalidation(session, ownerId, out snapshots);

        internal ForeignDiplomacyJournalResult CancelForeignDiplomacyIntent(ForeignDiplomacyJournalSession session,
            ForeignDiplomacyIntentRequest request) => GetForeignDiplomacyJournal().Cancel(session, request);
    }
}
