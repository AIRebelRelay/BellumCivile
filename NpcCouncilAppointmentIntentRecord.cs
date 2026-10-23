using System;
using System.Globalization;
using System.Collections.Generic;

namespace BellumCivile
{
    /// <summary>Persisted request, not an appointment or ballot receipt.</summary>
    public sealed class NpcCouncilAppointmentIntentSnapshot
    {
        public string ExternalIntentId { get; }
        public string RealmId { get; }
        public string SponsorClanId { get; }
        public int FactionTypeValue { get; }
        public int OfficeValue { get; }
        public string RequestedCandidateClanId { get; }
        public string SelectedCandidateClanId { get; }
        public double SubmittedDay { get; }
        public string Status { get; }
        public string CourtAgendaId { get; }

        internal NpcCouncilAppointmentIntentSnapshot(string id, string realm, string sponsor,
            int faction, int office, string requested, double day, string status,
            string agendaId = null, string selected = null)
        {
            ExternalIntentId = id; RealmId = realm; SponsorClanId = sponsor;
            FactionTypeValue = faction; OfficeValue = office;
            RequestedCandidateClanId = requested ?? string.Empty;
            SelectedCandidateClanId = selected;
            SubmittedDay = day; Status = status; CourtAgendaId = agendaId;
        }
    }

    /// <summary>Current read-only NPC faction eligibility, not a scheduled vote.</summary>
    public sealed class NpcCouncilAppointmentOptionSnapshot
    {
        public string Office { get; }
        public IReadOnlyList<string> CandidateClanIds { get; }

        internal NpcCouncilAppointmentOptionSnapshot(string office, IReadOnlyList<string> candidates)
        {
            Office = office;
            CandidateClanIds = candidates ?? new string[0];
        }
    }

    public sealed class NpcCouncilAppointmentIntentSubmission
    {
        public bool Accepted { get; }
        public string Reason { get; }
        public NpcCouncilAppointmentIntentSnapshot Intent { get; }

        internal NpcCouncilAppointmentIntentSubmission(bool accepted, string reason,
            NpcCouncilAppointmentIntentSnapshot intent)
        { Accepted = accepted; Reason = reason; Intent = intent; }
    }

    // Strict versioned string map; no new TaleWorlds SaveDefiner type IDs.
    internal static class NpcCouncilAppointmentIntentCodec
    {
        internal const string Staged = "staged_not_scheduled";
        internal static bool ValidId(string id, int max)
        {
            if (string.IsNullOrWhiteSpace(id) || id.Length > max) return false;
            foreach (char c in id) if (char.IsControl(c)) return false;
            return true;
        }

        internal static string Pack(string realm, string sponsor, int faction, int office,
            string candidate, double day)
        {
            if (!ValidId(realm, 256) || !ValidId(sponsor, 256)
                || (!string.IsNullOrEmpty(candidate) && !ValidId(candidate, 256))
                || double.IsNaN(day) || double.IsInfinity(day))
                throw new ArgumentException("Invalid NPC council ticket.");
            return string.Join("\n", "1", realm, sponsor,
                faction.ToString(CultureInfo.InvariantCulture),
                office.ToString(CultureInfo.InvariantCulture), candidate ?? "",
                day.ToString("R", CultureInfo.InvariantCulture), Staged);
        }

        internal static bool TryRead(string id, string packed, out NpcCouncilAppointmentIntentSnapshot ticket)
        {
            ticket = null;
            if (!ValidId(id, 128) || string.IsNullOrEmpty(packed)) return false;
            string[] p = packed.Split('\n');
            if (p.Length != 8 || p[0] != "1" || p[7] != Staged
                || !ValidId(p[1], 256) || !ValidId(p[2], 256)
                || (p[5].Length > 0 && !ValidId(p[5], 256))) return false;
            int faction, office;
            double day;
            if (!int.TryParse(p[3], NumberStyles.Integer, CultureInfo.InvariantCulture, out faction)
                || !int.TryParse(p[4], NumberStyles.Integer, CultureInfo.InvariantCulture, out office)
                || !double.TryParse(p[6], NumberStyles.Float, CultureInfo.InvariantCulture, out day)
                || double.IsNaN(day) || double.IsInfinity(day)) return false;
            ticket = new NpcCouncilAppointmentIntentSnapshot(id, p[1], p[2], faction, office,
                p[5], day, Staged);
            return true;
        }
    }
}
