using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Text;
using TaleWorlds.CampaignSystem;

namespace BellumCivile.Behaviors
{
    public sealed partial class CourtAgendaBehavior
    {
        // Independent of active agendas and UI reaction history. This is a Native-only
        // pre-eviction ledger, not a public event feed or an AII delivery receipt.
        private const int MaxCourtTerminalReceipts = 1024;
        private Dictionary<string, string> _courtTerminalReceipts = new Dictionary<string, string>();
        private int _courtTerminalEvictionOverflow;

        private void SyncCourtTerminalEvictionReceipts(IDataStore store)
        {
            store.SyncData("BC_CourtTerminalEvictionReceipts_v1", ref _courtTerminalReceipts);
            store.SyncData("BC_CourtTerminalEvictionOverflow_v1", ref _courtTerminalEvictionOverflow);
            _courtTerminalReceipts = _courtTerminalReceipts ?? new Dictionary<string, string>();
        }

        // Must run while the record is still in its native owner collection.
        // No read-side refresh, result mutation, reward claiming, or scheduling.
        private void CaptureEvictedCourtTerminals(IEnumerable<CourtAgendaRecord> records, string source)
        {
            try
            {
                foreach (CourtAgendaRecord agenda in records.ToList())
                {
                    try
                    {
                    if (agenda == null) continue;
                    if (agenda.ResultApplied != true || agenda.ObjectiveData?.IsTerminal != true) continue;
                    if (string.IsNullOrWhiteSpace(agenda.IntegrationId)
                        || string.IsNullOrWhiteSpace(agenda.Realm?.StringId))
                    {
                        BellumCivileLogger.Log("BC_COURT_TERMINAL_EVICTION status=invalid_identity"
                            + "; source=" + source + "; public_event=false");
                        continue;
                    }
                    if (_courtTerminalReceipts.ContainsKey(agenda.IntegrationId)) continue;
                    if (_courtTerminalReceipts.Count >= MaxCourtTerminalReceipts)
                    {
                        if (_courtTerminalEvictionOverflow < int.MaxValue) _courtTerminalEvictionOverflow++;
                        BellumCivileLogger.Log("BC_COURT_TERMINAL_EVICTION status=overflow"
                            + "; source=" + source
                            + "; id=" + agenda.IntegrationId
                            + "; pending=" + _courtTerminalReceipts.Count.ToString(CultureInfo.InvariantCulture)
                            + "; total_overflow=" + _courtTerminalEvictionOverflow.ToString(CultureInfo.InvariantCulture)
                            + "; delivery_claim=false");
                        continue;
                    }
                    _courtTerminalReceipts.Add(agenda.IntegrationId, PackTerminalReceipt(agenda));
                    BellumCivileLogger.Log("BC_COURT_TERMINAL_EVICTION status=recorded"
                        + "; source=" + source + "; id=" + agenda.IntegrationId
                        + "; realm=" + agenda.Realm.StringId
                        + "; objective_state=" + agenda.ObjectiveData.State
                        + "; pending=" + _courtTerminalReceipts.Count.ToString(CultureInfo.InvariantCulture)
                        + "; public_event=false; delivery_claim=false");
                    }
                    catch (Exception ex)
                    {
                        BellumCivileLogger.Log("BC_COURT_TERMINAL_EVICTION status=record_error"
                            + "; source=" + source + "; delivery_claim=false; " + ex);
                    }
                }
            }
            catch (Exception ex)
            {
                // Reporting failure must not change Native Court term/pruning semantics.
                BellumCivileLogger.Log("BC_COURT_TERMINAL_EVICTION status=capture_error"
                    + "; source=" + source + "; delivery_claim=false; " + ex);
            }
        }

        // Read-only campaign-thread inventory. The archive is never consumed here:
        // a future Bridge stage must prove its spool is durably written before ACK.
        internal CourtTerminalEvictionInventorySnapshot GetTerminalEvictionInventory(Kingdom realm)
        {
            if (realm == null || string.IsNullOrWhiteSpace(realm.StringId))
                return CourtTerminalEvictionInventorySnapshot.Unavailable(realm?.StringId);

            var pending = new List<CourtTerminalEvictionReceiptSnapshot>();
            int invalid = 0;
            foreach (var pair in _courtTerminalReceipts.OrderBy(pair => pair.Key, StringComparer.Ordinal))
            {
                string payloadRealm;
                if (!TryReadCourtTerminalPayload(pair.Key, pair.Value, out payloadRealm))
                {
                    invalid++;
                    continue;
                }
                if (!string.Equals(payloadRealm, realm.StringId, StringComparison.Ordinal)) continue;
                pending.Add(new CourtTerminalEvictionReceiptSnapshot(
                    pair.Key, payloadRealm, pair.Value));
            }

            return new CourtTerminalEvictionInventorySnapshot(
                realm.StringId, true, pending.AsReadOnly(), _courtTerminalReceipts.Count,
                invalid, _courtTerminalEvictionOverflow);
        }

        private static bool TryReadCourtTerminalPayload(string id, string payload, out string realmId)
        {
            realmId = null;
            Guid parsed;
            if (!Guid.TryParseExact(id, "N", out parsed)
                || string.IsNullOrEmpty(payload) || payload.Length > 16384) return false;

            string[] fields = payload.Split('|');
            if (fields.Length != 13 || !string.Equals(fields[0], "v1", StringComparison.Ordinal))
                return false;

            var decoded = new string[12];
            try
            {
                var utf8 = new UTF8Encoding(false, true);
                for (int i = 1; i <= 11; i++)
                {
                    if (fields[i].Length > 8192) return false;
                    decoded[i] = utf8.GetString(Convert.FromBase64String(fields[i]));
                    if (decoded[i].Length > 2048) return false;
                }
            }
            catch (FormatException) { return false; }
            catch (DecoderFallbackException) { return false; }

            CourtAgendaState agendaState;
            CourtObjectiveState objectiveState;
            CourtObjectiveCredit credit;
            if (!Enum.TryParse(decoded[7], false, out agendaState)
                || !Enum.IsDefined(typeof(CourtAgendaState), agendaState)
                || !Enum.TryParse(decoded[8], false, out objectiveState)
                || !Enum.IsDefined(typeof(CourtObjectiveState), objectiveState)
                || objectiveState == CourtObjectiveState.Selected
                || objectiveState == CourtObjectiveState.Active
                || !Enum.TryParse(decoded[9], false, out credit)
                || !Enum.IsDefined(typeof(CourtObjectiveCredit), credit)) return false;

            double day;
            if (!double.TryParse(fields[12], NumberStyles.Float, CultureInfo.InvariantCulture, out day)
                || double.IsNaN(day) || double.IsInfinity(day) || day < 0) return false;
            if (string.IsNullOrWhiteSpace(decoded[1])) return false;

            realmId = decoded[1];
            return true;
        }

        private static string PackTerminalReceipt(CourtAgendaRecord agenda)
        {
            CourtObjectiveRecord objective = agenda.ObjectiveData;
            // Escape all untrusted ID/reason strings; pipe is the structural separator.
            // This is an *observation* day, not the unrecorded actual terminal day.
            return string.Join("|", new[]
            {
                "v1",
                EncodeReceiptField(agenda.Realm?.StringId),
                EncodeReceiptField(agenda.Faction?.Type.ToString()),
                EncodeReceiptField(agenda.Sponsor?.StringId),
                EncodeReceiptField(objective.Kind),
                EncodeReceiptField(objective.TargetId ?? agenda.PolicyId),
                EncodeReceiptField(objective.ActionId),
                EncodeReceiptField(agenda.State.ToString()),
                EncodeReceiptField(objective.State.ToString()),
                EncodeReceiptField(objective.Credit.ToString()),
                EncodeReceiptField(objective.ResultReason),
                EncodeReceiptField(agenda.CancellationReason),
                CampaignTime.Now.ToDays.ToString("R", CultureInfo.InvariantCulture)
            });
        }

        private static string EncodeReceiptField(string value)
            => Convert.ToBase64String(Encoding.UTF8.GetBytes(value ?? string.Empty));
    }
}
