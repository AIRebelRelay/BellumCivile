using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Security.Cryptography;
using System.Text;

namespace BellumCivile.Behaviors
{
    public sealed partial class WarScoreBehavior
    {
        // S27: observational only. No Ensure*, migrations, reconciliation, registration, or saved-state writes.
        // The fingerprint covers all tracked rows (including ended/internal/invalid), not the capture time.
        internal IReadOnlyList<string> BuildWarIdentityDump()
        {
            if (_wars == null)
                return new[] {
                    "BELLUM_WAR_ID_DUMP_BEGIN status=UNINITIALIZED records=unknown fingerprint=UNINITIALIZED",
                    "BELLUM_WAR_ID_DUMP_END status=UNINITIALIZED fingerprint=UNINITIALIZED"
                };

            var counts = new Dictionary<string, int>(StringComparer.Ordinal);
            foreach (WarScoreRecord war in _wars)
            {
                string id = war?.ConflictInstanceId;
                if (id == null) continue;
                counts[id] = counts.TryGetValue(id, out int current) ? current + 1 : 1;
            }

            var rows = new List<string>(_wars.Count);
            int active = 0, ended = 0, missing = 0, invalid = 0, duplicates = 0;
            foreach (WarScoreRecord war in _wars)
            {
                if (war == null)
                {
                    invalid++;
                    rows.Add("BELLUM_WAR_ID_DUMP_ROW id=<null-row> flags=NULL_ROW");
                    continue;
                }
                if (war.IsActive) active++; else ended++;
                string rawId = war.StoredConflictInstanceId;
                string id = war.ConflictInstanceId;
                var flags = new List<string>();
                if (rawId == null) { missing++; flags.Add("MISSING_ID"); }
                else if (id == null) { invalid++; flags.Add("INVALID_ID"); }
                if (id != null && counts[id] > 1) { duplicates++; flags.Add("DUPLICATE_ID"); }
                if (!Enum.IsDefined(typeof(WarScoreConflictType), war.ConflictType)
                    || !ValidConflictRealmId(war.AttackerKingdomId)
                    || !ValidConflictRealmId(war.DefenderKingdomId)
                    || war.AttackerKingdomId == war.DefenderKingdomId
                    || war.WarKey != WarScoreRecord.PairKey(war.AttackerKingdomId, war.DefenderKingdomId)
                    || float.IsNaN(war.StartedDay) || float.IsInfinity(war.StartedDay) || war.StartedDay < 0
                    || float.IsNaN(war.Score) || float.IsInfinity(war.Score) || Math.Abs(war.Score) > 100f)
                {
                    invalid++;
                    flags.Add("INVALID_RECORD");
                }
                rows.Add("BELLUM_WAR_ID_DUMP_ROW id=" + (id ?? "<unknown>")
                    + " raw_id=" + EscapeWarIdDump(rawId)
                    + " kind=" + (Enum.IsDefined(typeof(WarScoreConflictType), war.ConflictType)
                        ? war.ConflictType.ToString() : "UNKNOWN(" + ((int)war.ConflictType).ToString(CultureInfo.InvariantCulture) + ")")
                    + " primary=" + EscapeWarIdDump(war.AttackerKingdomId)
                    + " opposing=" + EscapeWarIdDump(war.DefenderKingdomId)
                    + " key=" + EscapeWarIdDump(war.WarKey)
                    + " state=" + (war.IsActive ? "ACTIVE" : "ENDED")
                    + " started_day=" + war.StartedDay.ToString("R", CultureInfo.InvariantCulture)
                    + " ended_day=" + war.EndedDay.ToString("R", CultureInfo.InvariantCulture)
                    + " flags=" + (flags.Count == 0 ? "OK" : string.Join(",", flags)));
            }
            rows.Sort(StringComparer.Ordinal);
            string digest;
            using (SHA256 sha = SHA256.Create())
                digest = BitConverter.ToString(sha.ComputeHash(Encoding.UTF8.GetBytes(string.Join("\n", rows))))
                    .Replace("-", "").ToLowerInvariant();

            var result = new List<string>(rows.Count + 2) {
                "BELLUM_WAR_ID_DUMP_BEGIN status=OK records=" + _wars.Count.ToString(CultureInfo.InvariantCulture)
                + " active=" + active + " ended=" + ended + " missing_ids=" + missing
                + " invalid_flags=" + invalid + " duplicate_rows=" + duplicates
                + " fingerprint=" + digest
            };
            result.AddRange(rows);
            result.Add("BELLUM_WAR_ID_DUMP_END fingerprint=" + digest);
            return result;
        }

        private static string EscapeWarIdDump(string value)
        {
            if (value == null) return "<null>";
            var result = new StringBuilder();
            for (int i = 0; i < Math.Min(value.Length, 160); i++)
            {
                char ch = value[i];
                if ((ch >= 'a' && ch <= 'z') || (ch >= 'A' && ch <= 'Z')
                    || (ch >= '0' && ch <= '9') || ch == '_' || ch == '-' || ch == '.')
                    result.Append(ch);
                else result.Append("\\u").Append(((int)ch).ToString("x4", CultureInfo.InvariantCulture));
            }
            if (value.Length > 160)
            {
                using (SHA256 sha = SHA256.Create())
                    result.Append("...length=").Append(value.Length)
                        .Append(";sha256=")
                        .Append(BitConverter.ToString(sha.ComputeHash(Encoding.UTF8.GetBytes(value))).Replace("-", "").ToLowerInvariant());
            }
            return result.ToString();
        }
    }
}
