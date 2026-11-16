# Execute the exact production OnTick body with instrumented boundary doubles.
# This tests queue control flow, NOT the real game UI or treaty execution.
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$source = Get-Content (Join-Path $root 'Behaviors/ForeignTreatyBehavior.cs') -Raw
$start = $source.IndexOf('private void OnTick(float dt)')
$end = $source.IndexOf('private void OnDailyTick()', $start)
if ($start -lt 0 -or $end -le $start) { throw 'Cannot locate exact deferred tick body' }
$body = $source.Substring($start, $end - $start)
$fixture = @'
using System;
using System.Collections.Generic;
using System.Linq;
namespace DeferredParleyTickGate {
    public sealed class Kingdom { }
    public enum TreatyProposalState { ParleyPending, Cancelled }
    public enum TreatyTermType { WhitePeace }
    public sealed class Term { public TreatyTermType Type; }
    public sealed class TreatyProposalRecord {
        public string ProposalId = "proposal", WarKey = "war", DrafterKingdomId = "realm";
        public bool IsForced = true;
        public TreatyProposalState State = TreatyProposalState.ParleyPending;
        public List<Term> Terms = new List<Term>();
    }
    public sealed class WarScoreRecord { public string WarKey = "war"; public bool IsActive = true; }
    public sealed class WarScoreBehavior {
        public int Queries; public List<WarScoreRecord> Wars = new List<WarScoreRecord>();
        public IEnumerable<WarScoreRecord> GetActiveWars() { Queries++; return Wars; }
    }
    public sealed class Campaign {
        public static Campaign Current;
        public WarScoreBehavior Score;
        public T GetCampaignBehavior<T>() where T : class => Score as T;
    }
    public static class WarPeaceRevampBehavior {
        public static bool Enabled;
        public static bool IsRevampEnabled() => Enabled;
    }
    public static class InformationManager {
        public static bool Inquiry; public static bool IsAnyInquiryActive() => Inquiry;
    }
    public sealed class PeaceParleyInterface {
        public static PeaceParleyInterface Instance = new PeaceParleyInterface(); public bool IsShown;
    }
    public static class BellumCivileLogger { public static int Logs; public static void Log(string s) { Logs++; } }
    public sealed class ForeignTreatyBehavior {
        private string _pendingPlayerParleyOpenProposalId = "proposal";
        private string _forcedPlayerParleyInquiryProposalId = "proposal";
        private List<TreatyProposalRecord> _proposals = new List<TreatyProposalRecord>();
        private int scans, attempts, opened; private bool succeeds = true;
        private void EnsureCollectionsInitialized() { scans++; }
        private Kingdom ResolveKingdom(string id) => new Kingdom();
        private bool TryOpenPlayerParley(WarScoreRecord war, bool forced, bool whitePeace, string reason,
            Kingdom drafter, Action closed, out string report) {
            attempts++; report = "boundary double";
            // The real callee also rejects OFF; don't pretend the original tick opened an OFF parley.
            if (!WarPeaceRevampBehavior.IsRevampEnabled() || !succeeds) return false;
            opened++; return true;
        }
        __BODY__
        public static string Run(string name) {
            var f = new ForeignTreatyBehavior(); var proposal = new TreatyProposalRecord();
            var score = new WarScoreBehavior(); var war = new WarScoreRecord();
            f._proposals.Add(proposal); score.Wars.Add(war);
            Campaign.Current = new Campaign { Score = score }; BellumCivileLogger.Logs = 0;
            InformationManager.Inquiry = false; PeaceParleyInterface.Instance.IsShown = false;
            WarPeaceRevampBehavior.Enabled = !name.StartsWith("off_");
            switch (name) {
                case "empty_id": f._pendingPlayerParleyOpenProposalId = ""; break;
                case "off_cancelled": case "on_cancelled": proposal.State = TreatyProposalState.Cancelled; break;
                case "off_missing_war": case "on_missing_war": score.Wars.Clear(); break;
                case "on_missing_proposal": f._proposals.Clear(); break;
                case "on_inactive_war": war.IsActive = false; break;
                case "on_retry": f.succeeds = false; break;
                case "inquiry": InformationManager.Inquiry = true; break;
                case "shown": PeaceParleyInterface.Instance.IsShown = true; break;
            }
            int ticks = name == "off_repeated" ? 200 : 1;
            for (int i = 0; i < ticks; i++) f.OnTick(0);
            bool unchanged = f._pendingPlayerParleyOpenProposalId == "proposal"
                && f._forcedPlayerParleyInquiryProposalId == "proposal";
            bool clear = f._pendingPlayerParleyOpenProposalId == null && f._forcedPlayerParleyInquiryProposalId == null;
            bool pass;
            if (name == "off_to_on") {
                bool frozen = unchanged && f.scans == 0 && score.Queries == 0 && f.attempts == 0;
                WarPeaceRevampBehavior.Enabled = true; f.OnTick(0);
                pass = frozen && f.scans == 1 && score.Queries == 1 && f.opened == 1
                    && f._pendingPlayerParleyOpenProposalId == null && BellumCivileLogger.Logs == 1;
            } else if (name.StartsWith("off_") || name == "inquiry" || name == "shown")
                pass = unchanged && f.scans == 0 && score.Queries == 0 && f.attempts == 0 && BellumCivileLogger.Logs == 0;
            else if (name == "empty_id")
                pass = f.scans == 0 && score.Queries == 0 && f.attempts == 0;
            else if (name == "on_valid")
                pass = clear && f.scans == 1 && score.Queries == 1 && f.opened == 1 && BellumCivileLogger.Logs == 1;
            else if (name == "on_retry")
                pass = unchanged && f.scans == 1 && score.Queries == 1 && f.attempts == 1 && f.opened == 0;
            else if (name == "on_missing_proposal" || name == "on_cancelled")
                pass = clear && f.scans == 1 && score.Queries == 0 && f.attempts == 0;
            else pass = clear && f.scans == 1 && score.Queries == 1 && f.attempts == 0;
            return pass ? null : $"scans={f.scans}; queries={score.Queries}; attempts={f.attempts}; pending={f._pendingPlayerParleyOpenProposalId ?? "null"}; forced={f._forcedPlayerParleyInquiryProposalId ?? "null"}";
        }
    }
}
'@
Add-Type -TypeDefinition $fixture.Replace('__BODY__', $body) -Language CSharp
$cases = @('off_valid','off_cancelled','off_missing_war','off_repeated','off_to_on',
    'empty_id','inquiry','shown','on_valid','on_missing_proposal','on_cancelled','on_missing_war','on_inactive_war','on_retry')
$failed = 0
foreach ($case in $cases) {
    $detail = [DeferredParleyTickGate.ForeignTreatyBehavior]::Run($case)
    if ($null -eq $detail) { Write-Host "DEFERRED_TICK_PASS $case" }
    else { $failed++; Write-Host "DEFERRED_TICK_FAIL $case $detail" }
}
if ($failed) { throw "DEFERRED_TICK_RED $failed/$($cases.Count) scenarios failed" }
Write-Host "DEFERRED_TICK_ALL_PASS $($cases.Count) named scenarios; isolated tick body only"
