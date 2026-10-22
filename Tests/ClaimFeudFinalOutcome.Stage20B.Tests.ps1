$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$record = Get-Content (Join-Path $root 'ClaimFeudWarRecord.cs') -Raw
$outcomes = Get-Content (Join-Path $root 'ClaimFeudWarOutcome.cs') -Raw
$behavior = Get-Content (Join-Path $root 'Behaviors/ClaimFeudWarBehavior.cs') -Raw

$ids = [regex]::Matches($record, '\[SaveableField\((\d+)\)\]') | ForEach-Object { [int]$_.Groups[1].Value }
if ($ids.Count -ne ($ids | Sort-Object -Unique).Count) { throw 'Duplicate ClaimFeudWarRecord save field ID.' }
foreach ($id in 1..26) { if ($id -notin $ids) { throw "Missing ClaimFeudWarRecord save field $id." } }
if ($record -notmatch 'public bool HasFinalOutcome' -or $record -notmatch 'internal bool RecordFinalOutcome\(') {
    throw 'Missing explicit immutable result stamp.'
}
if ($behavior -notmatch 'public IReadOnlyList<ClaimFeudFinalOutcomeSnapshot> GetFinalizedWarOutcomes\(') {
    throw 'Missing dedicated read-only projection (do not expose mutable war list).'
}
$start = $behavior.IndexOf('        private void ResolveWar(')
$end = $behavior.IndexOf('        private void RecordYearlyOutcome(', $start)
if ($start -lt 0 -or $end -le $start) { throw 'ResolveWar boundary missing.' }
$resolve = $behavior.Substring($start, $end - $start)
$downgrade = $resolve.IndexOf('outcome = ClaimFeudWarOutcome.WhitePeace;')
$stamp = $resolve.IndexOf('war.RecordFinalOutcome(')
$cleanup = $resolve.IndexOf('DestroyTemporaryKingdom(holderKingdom, parent);')
$publish = $resolve.IndexOf('ConflictOutcomeBehavior.Current?.Publish(')
if ($downgrade -lt 0 -or $stamp -le $downgrade -or $stamp -le $cleanup -or $publish -le $stamp) {
    throw 'Result stamp must occur after award fallback and cleanup, before UI publication.'
}
if ($resolve -notmatch 'if \(war == null \|\| !war.IsActive\)') { throw 'Original double-resolution guard changed.' }
if ($resolve -notmatch 'war.SetActive\(false\)') { throw 'Original inactive-before-cleanup invariant changed.' }
if ($resolve -notmatch 'bool titleAwardApplied = false;') { throw 'Award evidence must be explicit.' }
if (([regex]::Matches($resolve, 'titleAwardApplied = true;')).Count -ne 2) {
    throw 'Claimant and holder award paths must each record actual application.'
}
if ($resolve -notmatch 'title\?\.DeJureHolderClanId' -or $resolve -notmatch 'title\?\.DeFactoHolderClanId') {
    throw 'Final legal and factual title holders missing.'
}

$stubs = @'
using System;
using System.Linq;
using TaleWorlds.SaveSystem;
namespace TaleWorlds.SaveSystem {
    [AttributeUsage(AttributeTargets.Field)]
    public sealed class SaveableFieldAttribute : Attribute {
        public SaveableFieldAttribute(int id) {}
    }
}
namespace BellumCivile {
    public static class ClaimFeudRecord {
        public static string Without(string ids, string clanId) { return ids ?? ""; }
    }
}
'@

$cases = @'
namespace BellumCivile {
    public static class Stage20BChecks {
        private static void Check(bool ok, string message) {
            if (!ok) throw new System.Exception(message);
        }
        private static ClaimFeudWarRecord NewWar(string id) {
            return new ClaimFeudWarRecord(id, "feud-" + id, "sturgia",
                "bc_feud_claimant", "bc_feud_holder", "bc_title_barony_castle_S5",
                "clan_6", "clan_7", "clan_6", "clan_7", "", "", 25f);
        }
        private static bool Stamp(ClaimFeudWarRecord war, ClaimFeudWarOutcome outcome,
            string kind, bool titleApplied, string jure, string facto,
            string returned, string destination) {
            return war.RecordFinalOutcome(outcome, kind, titleApplied,
                jure, facto, returned, destination);
        }
        public static void Run() {
            var original = NewWar("old-save");
            Check(!original.HasFinalOutcome, "Legacy save defaults to no result");
            Check(!Stamp(original, ClaimFeudWarOutcome.WhitePeace, "feud_peace", false,
                "", "", "sturgia", "returned_to_parent"), "Active war must not be stamped");
            original.QueueResolution(ClaimFeudWarOutcome.ClaimantVictory, "holder fell");
            original.SetActive(false);
            Check(original.PendingResolutionOutcome == ClaimFeudWarOutcome.None,
                "Original SetActive pending-clear changed");
            Check(!original.HasFinalOutcome, "Inactive legacy war is not authoritative");

            var win = NewWar("win"); win.SetActive(false);
            Check(Stamp(win, ClaimFeudWarOutcome.ClaimantVictory, "feud_claimant",
                true, "clan_6", "clan_6", "sturgia", "returned_to_parent"), "Claimant stamp");
            Check(win.HasFinalOutcome && win.FinalOutcome == ClaimFeudWarOutcome.ClaimantVictory,
                "Claimant final outcome");
            Check(win.FinalTitleAwardApplied && win.FinalTitleDeJureHolderClanId == "clan_6"
                && win.FinalTitleDeFactoHolderClanId == "clan_6", "Real title evidence");
            Check(win.WarId == "win" && win.ParentKingdomId == "sturgia", "Identity changed");
            Check(!Stamp(win, ClaimFeudWarOutcome.HolderVictory, "feud_holder", true,
                "clan_7", "clan_7", "sturgia", "returned_to_parent"),
                "Duplicate resolution overwrote durable truth");
            Check(win.FinalOutcome == ClaimFeudWarOutcome.ClaimantVictory, "Overwrite happened");

            var downgraded = NewWar("downgraded"); downgraded.SetActive(false);
            Check(Stamp(downgraded, ClaimFeudWarOutcome.WhitePeace, "feud_peace", false,
                "clan_7", "clan_6", "sturgia", "returned_to_parent"),
                "Failed claimant award must finalize WhitePeace");
            Check(downgraded.FinalOutcome == ClaimFeudWarOutcome.WhitePeace
                && !downgraded.FinalTitleAwardApplied, "Invented claimant title");

            var holder = NewWar("holder"); holder.SetActive(false);
            Check(Stamp(holder, ClaimFeudWarOutcome.HolderVictory, "feud_holder", true,
                "clan_7", "clan_7", "sturgia", "returned_to_parent"),
                "Holder settlement");
            Check(holder.FinalOutcome == ClaimFeudWarOutcome.HolderVictory &&
                holder.FinalTitleAwardApplied, "Holder title application");
            var unawarded = NewWar("unawarded"); unawarded.SetActive(false);
            Check(Stamp(unawarded, ClaimFeudWarOutcome.HolderVictory, "ended", false,
                "clan_7", "clan_6", "sturgia", "returned_to_parent"),
                "Unawarded holder result");
            Check(!unawarded.FinalTitleAwardApplied && unawarded.FinalResultKind == "ended",
                "Unawarded holder must not be represented as title applied");

            var invalid = NewWar("invalid-title"); invalid.SetActive(false);
            Check(Stamp(invalid, ClaimFeudWarOutcome.WhitePeace, "ended", false,
                "", "", "sturgia", "returned_to_parent"), "Invalid title settlement");
            Check(!invalid.FinalTitleAwardApplied, "Invalid title magically awarded");

            var lostParent = NewWar("independent"); lostParent.SetActive(false);
            Check(Stamp(lostParent, ClaimFeudWarOutcome.WhitePeace, "feud_peace", false,
                "clan_7", "clan_6", "", "independent_promotion_attempted"),
                "Missing parent outcome");
            Check(lostParent.FinalReturnKingdomId == "" &&
                lostParent.FinalDestinationKind == "independent_promotion_attempted",
                "Unverified promotion reported as accomplished");

            var noOutcome = NewWar("none"); noOutcome.SetActive(false);
            Check(!Stamp(noOutcome, ClaimFeudWarOutcome.None, "ended", false,
                "", "", "", "none"), "None must not become authoritative");
            Check(!noOutcome.HasFinalOutcome, "None became final");
        }
    }
}
'@
# Compile the real record with minimal TaleWorlds stubs. Merged C# snippets
# must not have 'using' directives after the first namespace declaration.
$recordForCompile = [regex]::Replace($record, '(?m)^using [^;]+;\\r?\\n', '')
Add-Type -TypeDefinition ($stubs + $outcomes + $recordForCompile + $cases) -ErrorAction Stop
[BellumCivile.Stage20BChecks]::Run()
Write-Host 'PASS Stage20B: save IDs, code ordering, legacy default, immutable outcome, claimant/holder/white-peace/invalid/parent cases.'
