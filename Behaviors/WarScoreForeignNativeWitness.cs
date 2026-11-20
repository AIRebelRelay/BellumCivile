using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using TaleWorlds.CampaignSystem;

namespace BellumCivile.Behaviors
{
    public sealed partial class WarScoreBehavior
    {
        // A changed timestamp disproves the observed start. Equality is only weak evidence:
        // Native StanceLink.WarStartDate is NOT proven to be a globally unique war epoch.
        private static double ReadForeignNativeWarStart(Kingdom first, Kingdom second)
        {
            if (first == null || second == null) return double.NaN;
            try
            {
                if (!first.IsAtWarWith(second) || !second.IsAtWarWith(first)) return double.NaN;
                StanceLink stance = first.GetStanceWith(second);
                double start = stance == null ? double.NaN : stance.WarStartDate.ToDays;
                return double.IsNaN(start) || double.IsInfinity(start) || start < 0 ? double.NaN : start;
            }
            catch (Exception)
            {
                // Do not let optional diagnostics interrupt Native war callbacks.
                return double.NaN;
            }
        }

        // This observer deliberately delegates all global ID/corruption/realm checks to
        // the existing detached reader; it never initializes, alters or fixes records.
        internal ForeignWarNativeWitnessSnapshot ObserveForeignWarNativeWitness(
            string instanceId, string primaryId, string opposingId, double day)
        {
            ForeignConflictIdentitySnapshot identity = GetExistingForeignConflictByInstance(
                instanceId, primaryId, opposingId, day);
            if (identity.Status != ForeignConflictIdentityStatus.RecordedActive)
                return new ForeignWarNativeWitnessSnapshot(
                    identity.Status, ForeignWarNativeWitnessStatus.IdentityUnavailable);

            WarScoreRecord record = _wars.First(war => war.ConflictInstanceId == instanceId);
            if (record.NativeForeignDeclarationAmbiguous)
                return new ForeignWarNativeWitnessSnapshot(
                    identity.Status, ForeignWarNativeWitnessStatus.AmbiguousDeclaration, instanceId,
                    record.NativeForeignWarStartObserved ? (double?)record.NativeForeignWarStartDay : null);
            if (!record.NativeForeignWarStartObserved)
                return new ForeignWarNativeWitnessSnapshot(
                    identity.Status, ForeignWarNativeWitnessStatus.Unwitnessed, instanceId);

            Kingdom first = Kingdom.All.First(k => k.StringId == primaryId);
            Kingdom second = Kingdom.All.First(k => k.StringId == opposingId);
            double nativeStart = ReadForeignNativeWarStart(first, second);
            if (double.IsNaN(nativeStart))
                return new ForeignWarNativeWitnessSnapshot(
                    identity.Status, ForeignWarNativeWitnessStatus.NativeStartUnavailable, instanceId,
                    record.NativeForeignWarStartDay);
            return new ForeignWarNativeWitnessSnapshot(
                identity.Status,
                record.NativeForeignWarStartDay == nativeStart
                    ? ForeignWarNativeWitnessStatus.WeakTimestampMatchNotProof
                    : ForeignWarNativeWitnessStatus.NativeStartChanged,
                instanceId, record.NativeForeignWarStartDay, nativeStart);
        }

        // Isolated, deterministic read-only observation. Does not alter the existing
        // S27 fingerprint semantics or require the player to start/stop wars.
        internal IReadOnlyList<string> BuildForeignWarNativeWitnessDump()
        {
            if (_wars == null)
                return new[] { "BELLUM_NATIVE_WAR_WITNESS_BEGIN status=UNINITIALIZED",
                    "BELLUM_NATIVE_WAR_WITNESS_END status=UNINITIALIZED" };
            var rows = new List<string>();
            double day = CampaignTime.Now.ToDays;
            foreach (WarScoreRecord record in _wars)
            {
                if (record == null || record.ConflictType != WarScoreConflictType.ForeignWar)
                    continue;
                string id = record.ConflictInstanceId;
                ForeignWarNativeWitnessSnapshot assessment = ObserveForeignWarNativeWitness(
                    id, record.AttackerKingdomId, record.DefenderKingdomId, day);
                rows.Add("BELLUM_NATIVE_WAR_WITNESS_ROW id=" + (id ?? "<unknown>")
                    + " primary=" + EscapeWarIdDump(record.AttackerKingdomId)
                    + " opposing=" + EscapeWarIdDump(record.DefenderKingdomId)
                    + " record_state=" + (record.IsActive ? "ACTIVE" : "ENDED")
                    + " identity=" + assessment.IdentityStatus
                    + " witness=" + assessment.WitnessStatus
                    + " saved_start=" + FormatNativeWitnessDay(assessment.RecordedNativeStartDay)
                    + " current_start=" + FormatNativeWitnessDay(assessment.CurrentNativeStartDay)
                    + " authority=false");
            }
            rows.Sort(StringComparer.Ordinal);
            var result = new List<string>(rows.Count + 2) {
                "BELLUM_NATIVE_WAR_WITNESS_BEGIN records=" + rows.Count + " authority=false"
            };
            result.AddRange(rows);
            result.Add("BELLUM_NATIVE_WAR_WITNESS_END records=" + rows.Count + " authority=false");
            return result;
        }

        private static string FormatNativeWitnessDay(double? day) => day.HasValue
            ? day.Value.ToString("R", CultureInfo.InvariantCulture) : "unknown";
    }
}
