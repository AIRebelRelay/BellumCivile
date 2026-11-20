using System;
using System.Collections.Generic;
using System.Linq;

namespace BellumCivile
{
    internal enum ForeignDiplomacyJournalResult
    {
        Unavailable = 0, Added, Existing, Conflict, StaleSession, InvalidRequest,
        Capacity, Found, Cancelled, AlreadyCancelled, NotFound
    }

    internal sealed class ForeignDiplomacyJournalSession
    {
        internal readonly string CampaignId;
        internal readonly string SessionId;
        internal ForeignDiplomacyJournalSession(string campaignId, string sessionId)
        { CampaignId = campaignId; SessionId = sessionId; }
    }

    internal sealed class ForeignDiplomacyIntentRequest
    {
        internal readonly string RequestKey, OwnerId, OriginId, FirstKingdomId, SecondKingdomId;
        internal readonly string FirstRulerId, SecondRulerId, ConflictEpoch, DraftFingerprint;
        internal readonly ForeignDiplomacySource Source;
        internal ForeignDiplomacyIntentRequest(string requestKey, string ownerId, string originId,
            string firstKingdomId, string secondKingdomId, string firstRulerId, string secondRulerId,
            string conflictEpoch, string draftFingerprint, ForeignDiplomacySource source)
        {
            RequestKey = requestKey; OwnerId = ownerId; OriginId = originId;
            FirstKingdomId = firstKingdomId; SecondKingdomId = secondKingdomId;
            FirstRulerId = firstRulerId; SecondRulerId = secondRulerId;
            ConflictEpoch = conflictEpoch; DraftFingerprint = draftFingerprint; Source = source;
        }
    }

    internal sealed class ForeignDiplomacyIntentSnapshot
    {
        internal readonly string CampaignId, OperationId;
        internal readonly ForeignDiplomacyIntentRequest Request;
        internal readonly double CreatedDay;
        internal readonly bool Cancelled;
        // Reading historical evidence never revalidates the world or reinstates consent.
        internal bool RequiresWorldRevalidation => true;
        internal ForeignDiplomacyIntentSnapshot(string campaignId, ForeignDiplomacyIntentRecord record)
        {
            CampaignId = campaignId; OperationId = record.OperationId;
            Request = ForeignDiplomacyJournal.RequestFrom(record);
            CreatedDay = record.CreatedDay; Cancelled = record.Cancelled;
        }
    }

    // Internal metadata journal only. Does not claim a kingdom pair or call any game action.
    internal sealed class ForeignDiplomacyJournal
    {
        internal const int Capacity = 128;
        private readonly ForeignDiplomacyJournalState _state;
        private readonly string _sessionId = Guid.NewGuid().ToString("N");
        private readonly bool _available;

        internal ForeignDiplomacyJournal(ForeignDiplomacyJournalState state)
        { _state = state; _available = ValidState(state); }
        internal ForeignDiplomacyJournalSession Session =>
            new ForeignDiplomacyJournalSession(_state?.CampaignId, _sessionId);

        internal static ForeignDiplomacyJournalState CreateState() => new ForeignDiplomacyJournalState
        {
            SchemaVersion = 1, CampaignId = Guid.NewGuid().ToString("N"),
            Entries = new List<ForeignDiplomacyIntentRecord>()
        };

        private bool MatchesSession(ForeignDiplomacyJournalSession session) => session != null
            && session.SessionId == _sessionId && session.CampaignId == _state?.CampaignId;
        private static bool ValidDay(double value) => !double.IsNaN(value) && !double.IsInfinity(value) && value >= 0;
        private static bool ValidText(string value, int limit) => !string.IsNullOrWhiteSpace(value)
            && value.Length <= limit && value == value.Trim() && !value.Any(char.IsControl);
        private static bool ValidGuid(string value)
        { Guid id; return Guid.TryParseExact(value, "N", out id) && id != Guid.Empty && id.ToString("N") == value; }
        private static bool ValidRequest(ForeignDiplomacyIntentRequest r) => r != null
            && ValidText(r.RequestKey, 128) && ValidText(r.OwnerId, 96) && ValidText(r.OriginId, 256)
            && ValidText(r.FirstKingdomId, 128) && ValidText(r.SecondKingdomId, 128)
            && r.FirstKingdomId != r.SecondKingdomId
            && ValidText(r.FirstRulerId, 128) && ValidText(r.SecondRulerId, 128)
            && r.FirstRulerId != r.SecondRulerId
            && ValidText(r.ConflictEpoch, 256) && ValidText(r.DraftFingerprint, 256)
            && (r.Source == ForeignDiplomacySource.AutomaticForeignWar
                || r.Source == ForeignDiplomacySource.AutomaticForeignPeace
                || r.Source == ForeignDiplomacySource.AutomaticForeignParley);

        internal static ForeignDiplomacyIntentRequest RequestFrom(ForeignDiplomacyIntentRecord r) =>
            new ForeignDiplomacyIntentRequest(r.RequestKey, r.OwnerId, r.OriginId, r.FirstKingdomId,
                r.SecondKingdomId, r.FirstRulerId, r.SecondRulerId, r.ConflictEpoch,
                r.DraftFingerprint, (ForeignDiplomacySource)r.Source);

        private static bool ValidState(ForeignDiplomacyJournalState state)
        {
            if (state == null || state.SchemaVersion != 1 || !ValidGuid(state.CampaignId)
                || state.Entries == null || state.Entries.Count > Capacity) return false;
            var keys = new HashSet<string>(StringComparer.Ordinal);
            var origins = new HashSet<string>(StringComparer.Ordinal);
            var ids = new HashSet<string>(StringComparer.Ordinal);
            foreach (var r in state.Entries)
            {
                if (r == null || !ValidGuid(r.OperationId) || !ValidRequest(RequestFrom(r))
                    || !ValidDay(r.CreatedDay) || !keys.Add(r.RequestKey)
                    || !origins.Add(r.OriginId) || !ids.Add(r.OperationId)) return false;
            }
            return true;
        }

        private static bool SameRequest(ForeignDiplomacyIntentRecord r, ForeignDiplomacyIntentRequest q) =>
            r.RequestKey == q.RequestKey && r.OwnerId == q.OwnerId && r.OriginId == q.OriginId
            && r.FirstKingdomId == q.FirstKingdomId && r.SecondKingdomId == q.SecondKingdomId
            && r.FirstRulerId == q.FirstRulerId && r.SecondRulerId == q.SecondRulerId
            && r.ConflictEpoch == q.ConflictEpoch && r.DraftFingerprint == q.DraftFingerprint
            && r.Source == (int)q.Source;

        internal ForeignDiplomacyJournalResult Begin(ForeignDiplomacyJournalSession session,
            ForeignDiplomacyIntentRequest request, double day, out ForeignDiplomacyIntentSnapshot snapshot)
        {
            snapshot = null;
            if (!MatchesSession(session)) return ForeignDiplomacyJournalResult.StaleSession;
            if (!_available) return ForeignDiplomacyJournalResult.Unavailable;
            if (!ValidRequest(request) || !ValidDay(day)) return ForeignDiplomacyJournalResult.InvalidRequest;
            var prior = _state.Entries.FirstOrDefault(r => r.RequestKey == request.RequestKey || r.OriginId == request.OriginId);
            if (prior != null)
            {
                if (!SameRequest(prior, request)) return ForeignDiplomacyJournalResult.Conflict;
                snapshot = new ForeignDiplomacyIntentSnapshot(_state.CampaignId, prior);
                return ForeignDiplomacyJournalResult.Existing;
            }
            if (_state.Entries.Count >= Capacity) return ForeignDiplomacyJournalResult.Capacity;
            var record = new ForeignDiplomacyIntentRecord
            {
                OperationId = Guid.NewGuid().ToString("N"), RequestKey = request.RequestKey,
                OwnerId = request.OwnerId, OriginId = request.OriginId,
                FirstKingdomId = request.FirstKingdomId, SecondKingdomId = request.SecondKingdomId,
                FirstRulerId = request.FirstRulerId, SecondRulerId = request.SecondRulerId,
                ConflictEpoch = request.ConflictEpoch, DraftFingerprint = request.DraftFingerprint,
                Source = (int)request.Source, CreatedDay = day, Cancelled = false
            };
            _state.Entries.Add(record);
            snapshot = new ForeignDiplomacyIntentSnapshot(_state.CampaignId, record);
            return ForeignDiplomacyJournalResult.Added;
        }

        internal ForeignDiplomacyJournalResult GetForRevalidation(ForeignDiplomacyJournalSession session,
            string requestKey, string ownerId, out ForeignDiplomacyIntentSnapshot snapshot)
        {
            snapshot = null;
            if (!MatchesSession(session)) return ForeignDiplomacyJournalResult.StaleSession;
            if (!_available) return ForeignDiplomacyJournalResult.Unavailable;
            if (!ValidText(requestKey, 128) || !ValidText(ownerId, 96)) return ForeignDiplomacyJournalResult.InvalidRequest;
            var record = _state.Entries.FirstOrDefault(r => r.RequestKey == requestKey);
            if (record == null) return ForeignDiplomacyJournalResult.NotFound;
            if (record.OwnerId != ownerId) return ForeignDiplomacyJournalResult.Conflict;
            snapshot = new ForeignDiplomacyIntentSnapshot(_state.CampaignId, record);
            return ForeignDiplomacyJournalResult.Found;
        }

        internal ForeignDiplomacyJournalResult ListPendingForRevalidation(ForeignDiplomacyJournalSession session,
            string ownerId, out IReadOnlyList<ForeignDiplomacyIntentSnapshot> snapshots)
        {
            snapshots = null;
            if (!MatchesSession(session)) return ForeignDiplomacyJournalResult.StaleSession;
            if (!_available) return ForeignDiplomacyJournalResult.Unavailable;
            if (!ValidText(ownerId, 96)) return ForeignDiplomacyJournalResult.InvalidRequest;
            snapshots = _state.Entries.Where(r => !r.Cancelled && r.OwnerId == ownerId)
                .Select(r => new ForeignDiplomacyIntentSnapshot(_state.CampaignId, r)).ToList().AsReadOnly();
            return ForeignDiplomacyJournalResult.Found;
        }

        internal ForeignDiplomacyJournalResult Cancel(ForeignDiplomacyJournalSession session,
            ForeignDiplomacyIntentRequest request)
        {
            if (!MatchesSession(session)) return ForeignDiplomacyJournalResult.StaleSession;
            if (!_available) return ForeignDiplomacyJournalResult.Unavailable;
            if (!ValidRequest(request)) return ForeignDiplomacyJournalResult.InvalidRequest;
            var record = _state.Entries.FirstOrDefault(r => r.RequestKey == request.RequestKey);
            if (record == null) return ForeignDiplomacyJournalResult.NotFound;
            if (!SameRequest(record, request)) return ForeignDiplomacyJournalResult.Conflict;
            if (record.Cancelled) return ForeignDiplomacyJournalResult.AlreadyCancelled;
            record.Cancelled = true;
            return ForeignDiplomacyJournalResult.Cancelled;
        }
    }
}
