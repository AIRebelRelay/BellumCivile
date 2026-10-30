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
