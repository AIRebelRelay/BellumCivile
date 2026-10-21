using System;
using System.Globalization;

namespace BellumCivile
{
    /// <summary>Read-only integration ticket; staging does not imply Court Agenda assignment.</summary>
    public sealed class NpcCrownTreasonIntentSnapshot
    {
        public string ExternalIntentId { get; }
        public string RealmId { get; }
        public string RulerClanId { get; }
        public string TargetClanId { get; }
        public double SubmittedDay { get; }
        public string Status { get; }
        public string CourtAgendaId { get; }

        internal NpcCrownTreasonIntentSnapshot(string intentId, string realmId,
            string rulerClanId, string targetClanId, double submittedDay, string status,
            string courtAgendaId = null)
        {
            ExternalIntentId = intentId;
            RealmId = realmId;
            RulerClanId = rulerClanId;
            TargetClanId = targetClanId;
            SubmittedDay = submittedDay;
            Status = status;
            CourtAgendaId = courtAgendaId;
        }
    }

    public sealed class NpcCrownTreasonIntentSubmission
    {
        public bool Accepted { get; }
        public string Reason { get; }
        public NpcCrownTreasonIntentSnapshot Intent { get; }

        internal NpcCrownTreasonIntentSubmission(bool accepted, string reason,
            NpcCrownTreasonIntentSnapshot intent)
        {
            Accepted = accepted;
            Reason = reason;
            Intent = intent;
        }
    }

    // Primitive-only save payload: no new SaveDefiner type IDs or mutable campaign records.
    // The encoding is intentionally strict and versioned; unexpected data fails closed.
    internal static class NpcTreasonIntentCodec
    {
        internal const string Staged = "staged_not_scheduled";
        internal const string Version = "1";

        internal static bool ValidId(string id, int maxLength)
        {
            if (string.IsNullOrWhiteSpace(id) || id.Length > maxLength) return false;
            foreach (char ch in id)
                if (char.IsControl(ch)) return false;
            return true;
        }

        internal static string Pack(string realmId, string rulerId, string targetId, double day)
        {
            if (!ValidId(realmId, 256) || !ValidId(rulerId, 256) || !ValidId(targetId, 256)
                || double.IsNaN(day) || double.IsInfinity(day))
                throw new ArgumentException("Invalid NPC Crown intent payload.");
            return string.Join("\n", Version, realmId, rulerId, targetId,
                day.ToString("R", CultureInfo.InvariantCulture), Staged);
        }

        internal static bool TryRead(string intentId, string packed,
            out NpcCrownTreasonIntentSnapshot snapshot)
        {
            snapshot = null;
            if (!ValidId(intentId, 128) || string.IsNullOrEmpty(packed)) return false;
            string[] parts = packed.Split('\n');
            if (parts.Length != 6 || parts[0] != Version || parts[5] != Staged
                || !ValidId(parts[1], 256) || !ValidId(parts[2], 256)
                || !ValidId(parts[3], 256))
                return false;
            double day;
            if (!double.TryParse(parts[4], NumberStyles.Float, CultureInfo.InvariantCulture, out day)
                || double.IsNaN(day) || double.IsInfinity(day))
                return false;
            snapshot = new NpcCrownTreasonIntentSnapshot(
                intentId, parts[1], parts[2], parts[3], day, parts[5]);
            return true;
        }
    }
}
