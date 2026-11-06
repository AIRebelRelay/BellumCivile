$ErrorActionPreference = 'Stop'
# P0-02B RED-first; source contract plus actual native guard under fake TaleWorlds.
# Not a Bannerlord build/Harmony/game/save validation.
$root = Split-Path -Parent $PSScriptRoot
$guardPath = Join-Path $root 'AlliancePeaceRestriction.cs'
$foreignPath = Join-Path $root 'Behaviors/ForeignTreatyBehavior.cs'
if (-not (Test-Path -LiteralPath $guardPath)) { throw 'P002B_RED: source-native AlliancePeaceRestriction.cs missing' }
$guard = Get-Content -LiteralPath $guardPath -Raw
$foreign = Get-Content -LiteralPath $foreignPath -Raw
function Check([bool]$ok, [string]$label) {
    if (-not $ok) { throw "P002B_RED $label" }
    Write-Host "P002B_PASS $label"
}
$start = $foreign.IndexOf('private bool TryQueueParley(', [StringComparison]::Ordinal)
$end = $foreign.IndexOf('private bool CanSubmitAutomaticDraft(', $start + 1, [StringComparison]::Ordinal)
Check ($start -ge 0 -and $end -gt $start) 'native queue method found'
$queue = $foreign.Substring($start, $end - $start)
$revamp = $queue.IndexOf('if (!WarPeaceRevampBehavior.IsRevampEnabled()', [StringComparison]::Ordinal)
$storyline = $queue.IndexOf('if (StorylineWarProtectionHelper.IsPeaceBlocked(attacker, defender))', [StringComparison]::Ordinal)
$alliance = $queue.IndexOf('if (AlliancePeaceRestriction.TryGetPeaceBlock(attacker, defender, out TextObject allianceReason))', [StringComparison]::Ordinal)
$client = $queue.IndexOf('if (ClientKingdomBehavior.Instance?.IsAuxiliaryClientWar(attacker, defender) == true)', [StringComparison]::Ordinal)
$add = $queue.IndexOf('_proposals.Add(proposal);', [StringComparison]::Ordinal)
Check ($revamp -ge 0 -and $storyline -gt $revamp -and $alliance -gt $storyline -and $client -gt $alliance -and $add -gt $client) 'OFF and storyline precede the new native alliance rejection; no draft mutation before it'
$refusal = $queue.Substring($alliance, $client - $alliance)
Check ($refusal.Contains('report = allianceReason.ToString();') -and $refusal.Contains('return false;')) 'blocked admission returns native reason and no proposal'
Check ($queue.Contains('if (!WarPeaceRevampBehavior.IsRevampEnabled() || war == null || !war.IsActive') -and $queue.Contains('IsPlayerPoliticalParticipant')) 'Revamp OFF and previous player admission retained'
$ns = $guard.IndexOf('namespace BellumCivile', [StringComparison]::Ordinal)
Check ($ns -ge 0) 'native restriction namespace available'
$stubs = @'
using System;
using TaleWorlds.CampaignSystem;
using TaleWorlds.CampaignSystem.CampaignBehaviors;
using TaleWorlds.Localization;
namespace TaleWorlds.Localization {
  public sealed class TextObject {
    private string _text;
    public TextObject(string s) { _text = s; }
    public static TextObject GetEmpty() { return new TextObject(""); }
    public void SetTextVariable(string name, TextObject val) {
      _text = _text.Replace("{" + name + "}", val == null ? "" : val.ToString());
    }
    public override string ToString() { return _text; }
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
    public IAllianceCampaignBehavior Alliances { get; set; }
    public T GetCampaignBehavior<T>() where T : class { return Alliances as T; }
  }
}
namespace TaleWorlds.CampaignSystem.CampaignBehaviors {
  public interface IAllianceCampaignBehavior {
    bool IsAtWarByCallToWarAgreement(Kingdom called, Kingdom enemy, out Kingdom caller);
  }
  public sealed class FakeAlliances : IAllianceCampaignBehavior {
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
'@
$tests = @'
namespace P002B {
  public static class Cases {
    static void Verify(bool ok, string label) {
      if (!ok) throw new System.Exception("P002B_RED " + label);
      System.Console.WriteLine("P002B_PASS " + label);
    }
    public static void Run() {
      var called = new Kingdom("called");
      var enemy = new Kingdom("enemy");
      var caller = new Kingdom("calling");
      var other = new Kingdom("other");
      Campaign.Current = null;
      Verify(!BellumCivile.AlliancePeaceRestriction.IsPeaceBlocked(called, enemy), "no campaign");
      Campaign.Current = new Campaign();
      Verify(!BellumCivile.AlliancePeaceRestriction.IsPeaceBlocked(called, enemy), "no native behavior");
      var ally = new FakeAlliances();
      Campaign.Current.Alliances = ally;
      Verify(!BellumCivile.AlliancePeaceRestriction.IsPeaceBlocked(called, enemy)
        && !BellumCivile.AlliancePeaceRestriction.IsPeaceBlocked(null, enemy)
        && !BellumCivile.AlliancePeaceRestriction.IsPeaceBlocked(called, called),
        "no obligation, null and same kingdom");
      ally.Called=called; ally.Enemy=other; ally.Caller=caller;
      Verify(!BellumCivile.AlliancePeaceRestriction.IsPeaceBlocked(called, enemy), "unrelated obligation");
      ally.Enemy=enemy;
      Verify(BellumCivile.AlliancePeaceRestriction.IsPeaceBlocked(called, enemy)
        && BellumCivile.AlliancePeaceRestriction.IsPeaceBlocked(enemy, called), "both party orders blocked");
      Verify(!BellumCivile.AlliancePeaceRestriction.IsPeaceBlocked(caller, enemy), "calling ally remains free");
      TextObject reason;
      Verify(BellumCivile.AlliancePeaceRestriction.TryGetPeaceBlock(called, enemy, out reason)
        && reason.ToString().Contains("called") && reason.ToString().Contains("calling")
        && reason.ToString().Contains("enemy"), "reason identifies parties");
      ally.Called=enemy; ally.Enemy=called;
      Verify(BellumCivile.AlliancePeaceRestriction.IsPeaceBlocked(called, enemy), "reverse agreement");
      ally.Called=null; ally.Enemy=null;
      Verify(!BellumCivile.AlliancePeaceRestriction.IsPeaceBlocked(called, enemy), "expired agreement");
    }
  }
}
'@
$fixture = $stubs + [Environment]::NewLine + $guard.Substring($ns) + [Environment]::NewLine + $tests
Add-Type -TypeDefinition $fixture -ErrorAction Stop
[P002B.Cases]::Run()
Write-Host 'P002B_SOURCE_PROBE_PASS; Windows build, Harmony and real-game/save proof remain deferred.'
