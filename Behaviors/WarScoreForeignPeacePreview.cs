using System;

namespace BellumCivile.Behaviors
{
    public sealed partial class WarScoreBehavior
    {
        // No GetActiveWar(): its shared implementation performs lazy initialization.
        // Read the live ledger without registering or reconciling foreign hostilities.
        internal ForeignPeaceWarRead PeekForeignPeaceWar(string sourceId, string targetId)
        {
            if (_wars == null || string.IsNullOrWhiteSpace(sourceId)
                || string.IsNullOrWhiteSpace(targetId))
                return new ForeignPeaceWarRead(ForeignPeaceWarTracking.Unknown, null, null, _runtimeRevision);

            string pairKey = WarScoreRecord.PairKey(sourceId, targetId);
            WarScoreRecord found = null;

            foreach (WarScoreRecord candidate in _wars)
            {
                if (candidate == null || !candidate.IsActive || candidate.WarKey != pairKey)
                    continue;

                // A duplicate live pair is corrupted/ambiguous; do not choose one silently.
                if (found != null)
                    return new ForeignPeaceWarRead(ForeignPeaceWarTracking.Unknown, null, null, _runtimeRevision);

                found = candidate;
            }

            if (found == null)
                return new ForeignPeaceWarRead(
                    ForeignPeaceWarTracking.UntrackedForeignWar, null, null, _runtimeRevision);

            if (found.ConflictType != WarScoreConflictType.ForeignWar)
                return new ForeignPeaceWarRead(
                    ForeignPeaceWarTracking.TrackedOtherConflict, found.WarKey, found.Score, _runtimeRevision);

            // The existing AI Influence entry is accounting-only; it is not authorization.
            bool accountingOnly = (found.ContextId ?? string.Empty)
                .StartsWith("aii_foreign_ledger:v1:", StringComparison.Ordinal);
            return new ForeignPeaceWarRead(
                accountingOnly
                    ? ForeignPeaceWarTracking.AccountingOnlyForeignWar
                    : ForeignPeaceWarTracking.TrackedForeignWar,
                found.WarKey, found.Score, _runtimeRevision);
        }
    }
}
