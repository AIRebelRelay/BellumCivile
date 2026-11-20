#Requires -Version 7.2
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot
$record = Get-Content "$root/CrownAccessionRecord.cs" -Raw
$behavior = Get-Content "$root/Behaviors/CrownAccessionBehavior.cs" -Raw
$stubs = @'
using System;
namespace TaleWorlds.SaveSystem { public class SaveableFieldAttribute : Attribute { public SaveableFieldAttribute(int id){} } }
namespace TaleWorlds.CampaignSystem { public class Kingdom { public Clan RulingClan; public bool IsEliminated; } public class Clan {} public class Hero { public Clan Clan; } public struct CampaignTime {} }
namespace TaleWorlds.CampaignSystem.Election { public class KingSelectionKingdomDecision {} }
namespace TaleWorlds.CampaignSystem.Party { public class MobileParty {} }
namespace BellumCivile { public enum HouseSuccessionLaw {} public enum GenderSuccessionLaw {} public enum FactionType {} public class RealmUnionRecord {} public class CadetNameRecord {} }
'@
$cases = @'
namespace BellumCivile {
 public static class OccurrenceTests {
  static CrownAccessionRecord Ready() {
   var house = new TaleWorlds.CampaignSystem.Clan();
   return new CrownAccessionRecord { Realm = new TaleWorlds.CampaignSystem.Kingdom { RulingClan = house },
    Heir = new TaleWorlds.CampaignSystem.Hero { Clan = house }, Predecessor = new TaleWorlds.CampaignSystem.Hero { Clan = house },
    TitleTransferred = true, Completed = true };
  }
  static void Check(bool value,string name) { if(!value) throw new System.Exception(name); }
  public static void Run() {
   var first = Ready();
   Check(first.CoronationId == null,"old completed record starts unknown");
   first.StampCoronation();
   string id = first.CoronationId;
   Check(System.Guid.TryParseExact(id,"N",out var parsed),"same-house accession");
   first.StampCoronation(); Check(first.CoronationId == id,"repeat");
   var other = Ready(); other.Realm = first.Realm; other.Heir = first.Heir; other.Predecessor = first.Predecessor;
   other.Emergency = true; other.StampCoronation(); Check(other.CoronationId != null && other.CoronationId != id,"re-accession");
   foreach(var change in new System.Action<CrownAccessionRecord>[] {
    r => r.TitleTransferred=false, r => r.Completed=false, r => r.RegentReplacement=true, r => r.Realm.IsEliminated=true,
    r => r.Heir=r.Predecessor, r => r.Heir=null, r => r.Predecessor=null, r => r.Realm=null, r => r.Heir.Clan=null,
    r => r.Realm.RulingClan=new TaleWorlds.CampaignSystem.Clan() }) {
    var rejected=Ready(); change(rejected); rejected.StampCoronation(); Check(rejected.CoronationId==null,"invalid record");
   }
  }
 }
}
'@
Add-Type -TypeDefinition ($record + [Environment]::NewLine + $stubs.Replace('using System;', '').Replace(': Attribute', ': System.Attribute') + [Environment]::NewLine + $cases)
[BellumCivile.OccurrenceTests]::Run()
if ($record -notmatch '\[SaveableField\(93\)\]\s+public string CoronationId;' -or
    [regex]::Matches($behavior,'record\.StampCoronation\(\)').Count -ne 1 -or
    $behavior -notmatch 'record\.Completed = true;\s+bool firstCoronation = record\.CoronationId == null;\s+record\.StampCoronation\(\);\s+if \(firstCoronation && record\.CoronationId != null\) NotifyCoronation\(record\);\s+if \(!record\.RegentReplacement\) TitleAcquisitionBehavior') {
 throw 'Expected append-only saved field and a single call at the successful Finish site.'
}
'F4_CORONATION_OCCURRENCE_OFFLINE_PASS'
