$ErrorActionPreference = 'Stop'
# P0-04B RED-first. Execute the ACTUAL extracted new Prefix plus both existing
# Kingdom.AddDecision Prefix bodies in isolated C# stubs. Not game/Harmony proof.
$root = Split-Path -Parent $PSScriptRoot
$entry = Get-Content -LiteralPath (Join-Path $root 'Patches/PeaceParleyEntryPointPatches.cs') -Raw
$internal = Get-Content -LiteralPath (Join-Path $root 'Patches/InternalPeaceVotePatches.cs') -Raw
$feud = Get-Content -LiteralPath (Join-Path $root 'Patches/TemporaryFeudKingdomDecisionPatch.cs') -Raw
$module = Get-Content -LiteralPath (Join-Path $root 'SubModule.cs') -Raw
$native = Get-Content -LiteralPath (Join-Path $root 'AlliancePeaceRestriction.cs') -Raw
function Check([bool]$ok, [string]$label) {
    if (-not $ok) { throw "P004B_RED $label" }
    Write-Host "P004B_PASS $label"
}
$start=$entry.IndexOf('public static class KingdomPeaceDecisionAddedParleyCleanupPatch',[StringComparison]::Ordinal)
$end=if($start -lt 0){-1}else{$entry.IndexOf('public static class KingdomPeaceDecisionScreenFallbackPatch',$start+1,[StringComparison]::Ordinal)}
Check ($start -ge 0 -and $end -gt $start) 'existing Postfix class found'
$block=$entry.Substring($start,$end-$start)
$pre=$block.IndexOf('[HarmonyPrefix]',[StringComparison]::Ordinal)
$post=$block.IndexOf('[HarmonyPostfix]',[StringComparison]::Ordinal)
Check ($pre -ge 0 -and $post -gt $pre) 'new Prefix precedes preserved Postfix in the same installed Harmony class'
Check ($block.Contains('private static void Postfix(Kingdom __instance, KingdomDecision kingdomDecision)')
    -and $block.Contains('PeaceParleyDecisionRedirector.TryQueueAndRetire(')) 'old post-insertion mirror cleanup preserved'
Check (-not $block.Contains('[HarmonyPriority') -and -not $block.Contains('[HarmonyBefore')
    -and -not $block.Contains('[HarmonyAfter')) 'no unreviewed Harmony priority/order override'
Check ($module.Contains('_harmony.CreateClassProcessor(type).Patch();')) 'existing class registration discovers new Prefix without startup edits'
Check ($native.Contains('IsAtWarByCallToWarAgreement(first, second, out caller)')
    -and $native.Contains('IsAtWarByCallToWarAgreement(second, first, out caller)')) 'native call-to-arms checks both pair directions'

$prefix=$block.Substring($pre,$post-$pre)
Check ($prefix.Contains('if (!WarPeaceRevampBehavior.IsRevampEnabled() || !(kingdomDecision is MakePeaceKingdomDecision peace))')) 'OFF and non-peace bail out before foreign state resolution'
Check ($prefix.Contains('peace.FactionToMakePeaceWith as Kingdom')
    -and $prefix.Contains('GetActiveWar(first, second)')
    -and $prefix.Contains('war?.ConflictType != WarScoreConflictType.ForeignWar')
    -and $prefix.Contains('AlliancePeaceRestriction.IsPeaceBlocked(first, second)')) 'only real tracked foreign pair with native obligation denied'
Check ($prefix.Contains('Suppressed separate peace decision during an active call-to-arms agreement')
    -and $prefix.Contains('return false;')) 'blocked decision skips original AddDecision and reports specific reason'
Check ($prefix.Contains('return true;')) 'ordinary decisions remain eligible for existing other-prefix/postfix chain'

function ExistingPrefix([string]$source, [string]$className) {
    $a=$source.IndexOf('class ' + $className,[StringComparison]::Ordinal)
    Check ($a -ge 0) "existing sibling class: $className"
    $p=$source.IndexOf('private static bool Prefix(', $a, [StringComparison]::Ordinal)
    $e=if($p -lt 0){-1}else{$source.IndexOf([char]10 + '        }',$p,[StringComparison]::Ordinal)}
    Check ($p -ge 0 -and $e -gt $p) "existing sibling Prefix body: $className"
    return $source.Substring($p,$e-$p+([char]10+'        }').Length)
}
$nativeMethod=$prefix.Substring($prefix.IndexOf('private static bool Prefix(',[StringComparison]::Ordinal))
$rival=ExistingPrefix $internal 'InternalPeaceRivalInsertionPatch'
$temp=ExistingPrefix $feud 'TemporaryFeudKingdomDecisionPatch'
Check ($rival.Contains('InternalPeaceVoteText.IsInternal(')
    -and $rival.Contains('HasOffer(peace) == true')) 'internal rival rejection/valid-offer semantics not lost'
Check ($temp.Contains('BellumKingdomVisibilityHelper.IsTemporaryFeudKingdom(')) 'temporary-feud decision suppression preserved'

# C# fake world; compile all THREE ACTUAL native Prefix method bodies with Add-Type.
$stubs=@'
using System;
using System.Reflection;
using System.Collections.Generic;
using TaleWorlds.CampaignSystem;
using TaleWorlds.CampaignSystem.Election;
using BellumCivile;
using BellumCivile.Behaviors;
namespace TaleWorlds.CampaignSystem {
 public sealed class Kingdom {
  public string StringId; public bool Temporary;
  public Kingdom(string id) { StringId=id; }
 }
 public sealed class Campaign {
  public static Campaign Current;
  public WarScoreBehavior Score;
  public T GetCampaignBehavior<T>() where T:class { return Score as T; }
 }
}
namespace TaleWorlds.CampaignSystem.Election {
 public class KingdomDecision {}
 public sealed class MakePeaceKingdomDecision: KingdomDecision {
  public Kingdom Kingdom; public object FactionToMakePeaceWith;
  public bool Rival; public bool Offer;
 }
}
namespace BellumCivile {
 public enum WarScoreConflictType { ForeignWar, CivilWar, ClaimFeud }
 public sealed class WarScoreRecord {
  public WarScoreConflictType ConflictType; public string WarKey="a|b";
 }
 public static class AlliancePeaceRestriction {
  public static bool Active;
  public static bool IsPeaceBlocked(Kingdom a, Kingdom b) {
   return Active && a != null && b != null &&
    ((a.StringId=="a" && b.StringId=="b") || (a.StringId=="b" && b.StringId=="a"));
  }
 }
 public static class BellumCivileLogger {
  public static readonly List<string> Lines=new List<string>();
  public static void Log(string line) { Lines.Add(line); }
 }
 public static class BellumKingdomVisibilityHelper {
  public static bool IsTemporaryFeudKingdom(Kingdom k) { return k != null && k.Temporary; }
 }
}
namespace BellumCivile.Behaviors {
 public static class WarPeaceRevampBehavior {
  public static bool Enabled;
  public static bool IsRevampEnabled() { return Enabled; }
 }
 public sealed class WarScoreBehavior {
  public Kingdom First, Second; public WarScoreRecord Record;
  public WarScoreRecord GetActiveWar(Kingdom a, Kingdom b) {
   return (Object.ReferenceEquals(a,First)&&Object.ReferenceEquals(b,Second)
      || Object.ReferenceEquals(a,Second)&&Object.ReferenceEquals(b,First)) ? Record : null;
  }
 }
 public sealed class InternalPeaceSettlementBehavior {
  public static InternalPeaceSettlementBehavior Current;
  public bool HasOffer(MakePeaceKingdomDecision p) { return p != null && p.Offer; }
 }
}
namespace BellumCivile.Patches {
 public static class InternalPeaceVoteText {
  public static bool IsInternal(MakePeaceKingdomDecision p, out bool rival) {
   rival = p != null && p.Rival; return rival;
  }
 }
'@
$cases=@'
public static class P004BCases {
 static bool Call(Type t, params object[] args) {
  var m=t.GetMethod("Prefix",BindingFlags.NonPublic|BindingFlags.Static);
  if(m==null) throw new Exception("missing actual Prefix "+t.Name);
  return (bool)m.Invoke(null,args);
 }
 static void Expect(bool pass,string label) {
  if(!pass) throw new Exception("P004B_RED "+label);
  Console.WriteLine("P004B_PASS "+label);
 }
 public static void Run() {
  var first=new Kingdom("a"); var second=new Kingdom("b"); var other=new Kingdom("other");
  var score=new WarScoreBehavior {First=first,Second=second,
    Record=new WarScoreRecord {ConflictType=WarScoreConflictType.ForeignWar}};
  Campaign.Current=new Campaign {Score=score};
  WarPeaceRevampBehavior.Enabled=true;
  AlliancePeaceRestriction.Active=true;
  InternalPeaceSettlementBehavior.Current=new InternalPeaceSettlementBehavior();
  var peace=new MakePeaceKingdomDecision {Kingdom=first,FactionToMakePeaceWith=second};
  Expect(!Call(typeof(NativeForeignPrefix),peace)
    && BellumCivileLogger.Lines.Count==1, "blocked foreign peace decision before insertion");
  Expect(Call(typeof(NativeRivalPrefix),peace) && Call(typeof(NativeFeudPrefix),first,peace),
    "both pre-existing Prefixes still pass ordinary foreign decision");
  Expect(!Call(typeof(NativeForeignPrefix),new MakePeaceKingdomDecision {
      Kingdom=second,FactionToMakePeaceWith=first}), "reverse war endpoints");
  AlliancePeaceRestriction.Active=false;
  Expect(Call(typeof(NativeForeignPrefix),peace), "no obligation permits normal peace");
  AlliancePeaceRestriction.Active=true;
  WarPeaceRevampBehavior.Enabled=false;
  Expect(Call(typeof(NativeForeignPrefix),peace), "Revamp OFF remains unaffected");
  WarPeaceRevampBehavior.Enabled=true;
  score.Record.ConflictType=WarScoreConflictType.CivilWar;
  peace.Rival=true; peace.Offer=false;
  Expect(Call(typeof(NativeForeignPrefix),peace) && !Call(typeof(NativeRivalPrefix),peace),
    "foreign Prefix leaves unsupported internal rival veto intact");
  peace.Offer=true;
  Expect(Call(typeof(NativeForeignPrefix),peace) && Call(typeof(NativeRivalPrefix),peace),
    "valid internal rival treaty still allowed by sibling Prefix");
  score.Record.ConflictType=WarScoreConflictType.ClaimFeud;
  Expect(Call(typeof(NativeForeignPrefix),peace), "claim-feud is not foreign decision");
  peace.Rival=false; score.Record.ConflictType=WarScoreConflictType.ForeignWar;
  first.Temporary=true;
  Expect(!Call(typeof(NativeFeudPrefix),first,new KingdomDecision())
    && !Call(typeof(NativeFeudPrefix),first,peace),
    "temporary-feud sibling Prefix still blocks any decision type");
  first.Temporary=false;
  Expect(Call(typeof(NativeForeignPrefix),new KingdomDecision())
    && Call(typeof(NativeFeudPrefix),first,new KingdomDecision()),
    "unrelated policy or war decision remains allowed");
  peace.FactionToMakePeaceWith=other;
  Expect(Call(typeof(NativeForeignPrefix),peace), "unrelated foreign war not blocked");
  peace.FactionToMakePeaceWith=second;
  score.Record=null;
  Expect(Call(typeof(NativeForeignPrefix),peace), "missing tracked foreign war fails open");
  Campaign.Current=null;
  Expect(Call(typeof(NativeForeignPrefix),peace), "missing campaign fails open");
 }
}
}
'@
$cs=$stubs + [Environment]::NewLine +
    'public static class NativeForeignPrefix {' + [Environment]::NewLine + $nativeMethod + [Environment]::NewLine + '}' +
    [Environment]::NewLine + 'public static class NativeRivalPrefix {' + [Environment]::NewLine + $rival + [Environment]::NewLine + '}' +
    [Environment]::NewLine + 'public static class NativeFeudPrefix {' + [Environment]::NewLine + $temp + [Environment]::NewLine + '}' +
    [Environment]::NewLine + $cases
Add-Type -TypeDefinition $cs -ErrorAction Stop
[BellumCivile.Patches.P004BCases]::Run()
Write-Host 'P004B_SOURCE_AND_THREE_PREFIXES_PASS. Real Harmony order/game/saves/build remain deferred.'
