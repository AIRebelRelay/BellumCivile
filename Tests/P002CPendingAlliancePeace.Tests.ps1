$ErrorActionPreference = 'Stop'
# P0-02C RED-first. Source order + extracted actual native helper under fake TaleWorlds.
# This is not a Bannerlord build, Harmony test, or game/save proof.
$root = Split-Path -Parent $PSScriptRoot
$src = Get-Content -LiteralPath (Join-Path $root 'Behaviors/ForeignTreatyBehavior.cs') -Raw
$guard = Get-Content -LiteralPath (Join-Path $root 'AlliancePeaceRestriction.cs') -Raw

function Check([bool]$ok, [string]$name) {
    if (-not $ok) { throw "P002C_RED $name" }
    Write-Host "P002C_PASS $name"
}
function Slice([string]$from, [string]$to) {
    $a = $src.IndexOf($from, [StringComparison]::Ordinal)
    $b = if ($a -lt 0) { -1 } else { $src.IndexOf($to, $a + $from.Length, [StringComparison]::Ordinal) }
    Check ($a -ge 0 -and $b -gt $a) "method slice: $from"
    return $src.Substring($a, $b - $a)
}
function Before([string]$body, [string]$first, [string]$second, [string]$name) {
    $a = $body.IndexOf($first, [StringComparison]::Ordinal)
    $b = $body.IndexOf($second, [StringComparison]::Ordinal)
    Check ($a -ge 0 -and $b -gt $a) $name
}
$register = Slice 'public override void RegisterEvents()' 'public override void SyncData('
$reject = Slice 'public bool TryRejectPlayerParley(' 'public bool TrySignPlayerParley('
$sign = Slice 'public bool TrySignPlayerParley(' 'private TreatyProposalRecord FindPendingPlayerProposal('
$open = Slice 'public bool TryOpenPlayerParley(WarScoreRecord war, bool forced, bool preferWhitePeace, string reason, Kingdom drafter, Action onClosed, out string report)' 'private void EnsureProposalHasDraft('
$prepare = Slice 'private bool TryPreparePendingProposalDraft(' 'private bool TryValidateCouncilControlledWhitePeace('
$helper = Slice 'private bool TryCancelAllianceRestrictedProposal(' 'private void OnSessionLaunched('
$session = Slice 'private void OnSessionLaunched(' 'private static bool IsTreatyRealmAvailable('
$forced = Slice 'private bool TryShowForcedPlayerParleyInquiry(' 'private void OnTick(float dt)'
$daily = Slice 'private void OnDailyTick()' 'private void ResolvePendingParley('
$pending = Slice 'private void ResolvePendingParley(' 'private void OnHourlyTick()'
$apply = Slice 'private bool ApplyTreaty(' 'private bool ApplyTreatyCore('
$core = Slice 'private bool ApplyTreatyCore(' 'private static bool HasSettlementBudget('

Check ($register.Contains('CampaignEvents.OnSessionLaunchedEvent.AddNonSerializedListener(this, OnSessionLaunched);')) 'session-launch event subscribed once'
Before $reject 'if (!WarPeaceRevampBehavior.IsRevampEnabled())' 'TryCancelAllianceRestrictedProposal(war, proposal, out report)' 'reject: OFF remains before cancellation'
Before $reject 'TryCancelStorylineProtectedProposal(war, proposal, out report)' 'TryCancelAllianceRestrictedProposal(war, proposal, out report)' 'reject: preserve storyline priority'
Before $reject 'TryCancelAllianceRestrictedProposal(war, proposal, out report)' 'SpendRulerOverride(playerSide, rejectionOverrideCost)' 'reject: cancellation before influence'
Before $sign 'if (!WarPeaceRevampBehavior.IsRevampEnabled())' 'TryPreparePendingProposalDraft(war, proposal, out report)' 'sign: OFF before preparation'
Before $sign 'TryPreparePendingProposalDraft(war, proposal, out report)' 'SpendCouncilCommitments(proposal, winnerCouncil, loserCouncil)' 'sign: guarded prepare before council costs'
Before $open 'if (!WarPeaceRevampBehavior.IsRevampEnabled())' 'TryCancelAllianceRestrictedProposal(war, proposal, out report)' 'open: OFF first'
Before $open 'TryCancelAllianceRestrictedProposal(war, proposal, out report)' 'EnsureProposalHasDraft(war, proposal);' 'open: cancel before draft'
Before $open 'TryCancelAllianceRestrictedProposal(war, proposal, out report)' 'PeaceParleyInterface.Instance.Show(proposal, onClosed)' 'open: cancel before UI'
Before $prepare 'TryCancelStorylineProtectedProposal(war, proposal, out report)' 'TryCancelAllianceRestrictedProposal(war, proposal, out report)' 'prepare: storyline then alliance'
Before $prepare 'TryCancelAllianceRestrictedProposal(war, proposal, out report)' 'EnsureProposalHasDraft(war, proposal);' 'prepare: veto before draft repair'
Before $forced 'TryCancelAllianceRestrictedProposal(war, proposal, out _)' 'InformationManager.IsAnyInquiryActive()' 'forced inquiry cannot reopen cancelled parley'
Before $daily 'if (!WarPeaceRevampBehavior.IsRevampEnabled())' 'TryCancelAllianceRestrictedProposal(war, proposal, out _)' 'daily: OFF first'
Before $daily 'TryCancelStorylineProtectedProposal(war, proposal, out _)' 'TryCancelAllianceRestrictedProposal(war, proposal, out _)' 'daily: storyline priority'
Before $daily 'TryCancelAllianceRestrictedProposal(war, proposal, out _)' 'ResolvePendingParley(war, proposal)' 'daily: prevent automatic signed peace'
Check ($pending.Contains('if (!TryPreparePendingProposalDraft(war, proposal, out _))')) 'auto resolve still funnels guarded prepare'
Before $apply 'TryCancelStorylineProtectedProposal(war, proposal, out _)' 'TryCancelAllianceRestrictedProposal(war, proposal, out _)' 'apply: storyline then alliance'
Before $apply 'TryCancelAllianceRestrictedProposal(war, proposal, out _)' 'DeliverTreaty(proposal, winner, loser' 'apply: guard before hostage delivery'
Before $core 'TryCancelAllianceRestrictedProposal(war, proposal, out _)' 'CourtAgendaBehavior.Current?.BeginRallySettlement(war)' 'core: guard before any political effects'
Check ($session.Contains('if (!WarPeaceRevampBehavior.IsRevampEnabled()) return;') -and $session.Contains('TreatyProposalState.ParleyPending') -and $session.Contains('TryCancelAllianceRestrictedProposal(scores?.GetActiveWar(proposal.WarKey), proposal, out _);')) 'session load: ON pending cleanup, OFF untouched'
Check ($helper.Contains('proposal.State != TreatyProposalState.ParleyPending') -and $helper.Contains('AlliancePeaceRestriction.IsPeaceBlocked(')) 'cancel helper rejects already terminal proposals'
Check ($helper.Contains('CancelInvalidProposal(war, proposal, report);') -and $helper.Contains('_pendingPlayerParleyOpenProposalId == proposal.ProposalId') -and $helper.Contains('_forcedPlayerParleyInquiryProposalId == proposal.ProposalId')) 'cancel helper clears only matching UI markers'
Check ($src.Contains('dataStore.SyncData("BellumCivile_ForeignTreaty_Proposals", ref _proposals);') -and $src.Contains('war?.EndParley();')) 'existing proposal persistence and state cleanup preserved'

# Executable isolated regression: compile the ACTUAL private cancellation method and
# upstream native obligation helper against tiny fakes; downstream CancelInvalidProposal
# uses a stub and is separately source-checked above.
$ns = $guard.IndexOf('namespace BellumCivile', [StringComparison]::Ordinal)
Check ($ns -ge 0) 'native alliance helper namespace found'
$imports = @'
using System;
using System.Collections.Generic;
using TaleWorlds.CampaignSystem;
using TaleWorlds.CampaignSystem.CampaignBehaviors;
using TaleWorlds.Localization;
using BellumCivile;
'@
$fake = @'
namespace TaleWorlds.Localization {
  public sealed class TextObject {
    private string _value;
    public TextObject(string value) { _value = value; }
    public static TextObject GetEmpty() { return new TextObject(""); }
    public void SetTextVariable(string name, TextObject value) {
      _value = _value.Replace("{" + name + "}", value == null ? "" : value.ToString());
    }
    public override string ToString() { return _value; }
  }
}
namespace TaleWorlds.CampaignSystem {
  public sealed class Kingdom {
    public Kingdom(string id) { StringId = id; Name = new TextObject(id); }
    public string StringId { get; private set; }
    public TextObject Name { get; private set; }
  }
  public sealed class Campaign {
    public static Campaign Current { get; set; }
    public IAllianceCampaignBehavior Alliances;
    public T GetCampaignBehavior<T>() where T: class { return Alliances as T; }
  }
}
namespace TaleWorlds.CampaignSystem.CampaignBehaviors {
  public interface IAllianceCampaignBehavior {
    bool IsAtWarByCallToWarAgreement(Kingdom called, Kingdom enemy, out Kingdom caller);
  }
  public sealed class FakeAlliances: IAllianceCampaignBehavior {
    public Kingdom Called, Enemy, Caller;
    public bool IsAtWarByCallToWarAgreement(Kingdom called, Kingdom enemy, out Kingdom caller) {
      caller = null;
      if (Object.ReferenceEquals(called, Called) && Object.ReferenceEquals(enemy, Enemy)) {
        caller = Caller; return true;
      }
      return false;
    }
  }
}
namespace BellumCivile {
  public enum WarScoreConflictType { ForeignWar, CivilWar }
  public enum TreatyProposalState { ParleyPending, Cancelled, Applied }
  public sealed class WarScoreRecord {
    public string AttackerKingdomId, DefenderKingdomId;
    public WarScoreConflictType ConflictType;
    public bool ParleyPending = true;
    public void EndParley() { ParleyPending = false; }
  }
  public sealed class TreatyProposalRecord {
    public string ProposalId = "p";
    public TreatyProposalState State = TreatyProposalState.ParleyPending;
    public string ResolutionNote = "initial";
  }
}
'@
$container = @'
namespace BellumCivile.Behaviors {
  public class PendingFixture {
    public string _pendingPlayerParleyOpenProposalId, _forcedPlayerParleyInquiryProposalId;
    public int CancelCalls;
    private readonly Dictionary<string,Kingdom> _realms = new Dictionary<string,Kingdom>();
    public void Add(Kingdom k) { _realms.Add(k.StringId, k); }
    private Kingdom ResolveKingdom(string id) {
      Kingdom k; return id != null && _realms.TryGetValue(id,out k) ? k : null;
    }
    private void CancelInvalidProposal(WarScoreRecord war, TreatyProposalRecord proposal, string reason) {
      CancelCalls++; proposal.State=TreatyProposalState.Cancelled; proposal.ResolutionNote=reason;
      if (war != null) war.EndParley();
    }
    public bool Try(WarScoreRecord w, TreatyProposalRecord p, out string report) {
      return TryCancelAllianceRestrictedProposal(w,p,out report);
    }
'@
$cases = @'
  }
  public static class Cases {
    private static void Verify(bool ok, string msg) {
      if (!ok) throw new Exception("P002C_RED " + msg);
      Console.WriteLine("P002C_PASS " + msg);
    }
    public static void Run() {
      var a = new Kingdom("a"); var b = new Kingdom("b"); var caller = new Kingdom("ally");
      var fixture = new PendingFixture(); fixture.Add(a); fixture.Add(b); fixture.Add(caller);
      var war = new WarScoreRecord { AttackerKingdomId="a", DefenderKingdomId="b", ConflictType=WarScoreConflictType.ForeignWar };
      var p = new TreatyProposalRecord();
      fixture._pendingPlayerParleyOpenProposalId="p";
      fixture._forcedPlayerParleyInquiryProposalId="p";
      string report;
      Campaign.Current = null;
      Verify(!fixture.Try(war,p,out report) && fixture.CancelCalls==0 && p.State==TreatyProposalState.ParleyPending, "no campaign preserves pending");
      var alliance = new FakeAlliances();
      Campaign.Current = new Campaign { Alliances=alliance };
      Verify(!fixture.Try(war,p,out report) && fixture.CancelCalls==0, "no native obligation preserves pending");
      alliance.Called=a; alliance.Enemy=b; alliance.Caller=caller;
      war.ConflictType=WarScoreConflictType.CivilWar;
      Verify(!fixture.Try(war,p,out report) && fixture.CancelCalls==0, "civil war never cancelled");
      war.ConflictType=WarScoreConflictType.ForeignWar;
      Verify(fixture.Try(war,p,out report) && report==BellumCivile.AlliancePeaceRestriction.CancellationReason
         && p.State==TreatyProposalState.Cancelled && fixture.CancelCalls==1 && !war.ParleyPending
         && fixture._pendingPlayerParleyOpenProposalId==null && fixture._forcedPlayerParleyInquiryProposalId==null,
         "forbidden pending foreign treaty cancels once and clears matching GUI markers");
      Verify(!fixture.Try(war,p,out report) && fixture.CancelCalls==1 && p.ResolutionNote==report || 
         !fixture.Try(war,p,out report) && fixture.CancelCalls==1, "terminal proposal not cancelled twice");
      var p2=new TreatyProposalRecord { ProposalId="other" };
      var w2=new WarScoreRecord { AttackerKingdomId="a", DefenderKingdomId="b", ConflictType=WarScoreConflictType.ForeignWar };
      fixture._pendingPlayerParleyOpenProposalId="unrelated";
      fixture._forcedPlayerParleyInquiryProposalId="unrelated";
      alliance.Called=b; alliance.Enemy=a;
      Verify(fixture.Try(w2,p2,out report) && fixture.CancelCalls==2 
         && fixture._pendingPlayerParleyOpenProposalId=="unrelated" 
         && fixture._forcedPlayerParleyInquiryProposalId=="unrelated", "reverse obligation keeps other GUI ids intact");
      alliance.Called=a; alliance.Enemy=caller;
      var p3=new TreatyProposalRecord();
      Verify(!fixture.Try(w2,p3,out report) && fixture.CancelCalls==2 && p3.State==TreatyProposalState.ParleyPending, "unrelated native agreement permits pending");
    }
  }
}
'@
$cs = $imports + [Environment]::NewLine + $fake + [Environment]::NewLine + $guard.Substring($ns) + [Environment]::NewLine + $container + $helper + $cases
Add-Type -TypeDefinition $cs -ErrorAction Stop
[BellumCivile.Behaviors.Cases]::Run()
Write-Host 'P002C_SOURCE_AND_ISOLATED_PASS; full Windows DLL, Harmony, save and in-game ON/OFF tests deferred.'
