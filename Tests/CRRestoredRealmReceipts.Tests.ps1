#Requires -Version 7.2
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$record = Get-Content -LiteralPath (Join-Path $root 'RestoredRealmCreationRecord.cs') -Raw
$restore = Get-Content -LiteralPath (Join-Path $root 'Behaviors/RestoredRealmRecovery.cs') -Raw
$snapshot = Get-Content -LiteralPath (Join-Path $root 'RestoredRealmCompletionSnapshot.cs') -Raw
$facade = Get-Content -LiteralPath (Join-Path $root 'BellumIntegrationRestoredRealms.cs') -Raw
$definer = Get-Content -LiteralPath (Join-Path $root 'BellumCivileSaveDefiner.cs') -Raw
$assembly = Get-Content -LiteralPath (Join-Path $root 'Properties/AssemblyInfo.cs') -Raw
[xml]$module = Get-Content -LiteralPath (Join-Path $root '_Module/SubModule.xml') -Raw
[xml]$naval = Get-Content -LiteralPath (Join-Path $root 'BellumCivile.NavalDLCPatch/_Module/SubModule.xml') -Raw
function Check([bool]$ok,[string]$name){if(!$ok){throw ('E2_RED '+$name)};Write-Output ('PASS '+$name)}
Check ($record.Contains('[SaveableField(18)] public string CompletionReceiptId;') -and $record.Contains('[SaveableField(19)] public double CompletedDay;')) 'additive saved fields'
Check ($definer.Contains('AddClassDefinition(typeof(RestoredRealmCreationRecord), 137)') -and !$definer.Contains('RestoredRealmCompletionSnapshot')) 'existing save registration'
$stamp = $restore.IndexOf('record.CompletionReceiptId = "restored_realm|" + record.SuccessorId;')
$day = $restore.IndexOf('record.CompletedDay = CampaignTime.Now.ToDays;')
$ready = $restore.IndexOf('record.Ready = true;')
$proof = $restore.IndexOf('if (realm.IsEliminated || !NobleClanEligibilityHelper.IsValidRulingClan(realm.RulingClan, realm)) return null;')
Check ($proof -ge 0 -and $stamp -gt $proof -and $day -gt $stamp -and $ready -gt $day) 'stamp only after native final proof'
Check ([regex]::Matches($restore,[regex]::Escape('record.Ready = true;')).Count -eq 1) 'single Ready writer'
Check ($restore.Contains('r.Ready && !string.IsNullOrEmpty(r.CompletionReceiptId)') -and $restore.Contains('.Take(100)')) 'legacy suppression and bounded history'
Check ($facade.Contains('BellumIntegrationBehavior.RequireCampaignThread();') -and $facade.Contains('GetCampaignBehavior<CivilWarResolutionBehavior>()')) 'campaign thread and existing behavior'
Check ($module.Module.Version.value -ceq 'v1.4.12.2' -and $assembly.Contains('AssemblyFileVersion("1.4.12.2")') -and $assembly.Contains('AssemblyInformationalVersion("1.4.12b-cr-alpha.2")')) 'native versions synchronized'
Check ($assembly.Contains('AssemblyVersion("1.0.0.0")') -and $naval.Module.Version.value -ceq 'v1.0.33') 'binding and separate Naval unaffected'
$start=$restore.IndexOf('internal IReadOnlyList<RestoredRealmCompletionSnapshot> GetRecentRestoredRealmCompletions()', [StringComparison]::Ordinal)
$end=$restore.IndexOf('internal bool OwnsRestoredHouseholdTransfer(', $start)
if($start -lt 0 -or $end -le $start){throw 'E2_RED getter extraction'}
$getter=$restore.Substring($start,$end-$start)
$stubs=@'
using System;
using System.Collections.Generic;
using System.Linq;
namespace TaleWorlds.CampaignSystem {
  public class Kingdom { public string StringId; public Kingdom(string id){StringId=id;} }
  public class Clan { public string StringId; public Clan(string id){StringId=id;} }
}
namespace BellumCivile {
  using TaleWorlds.CampaignSystem;
  public sealed class RestoredRealmCreationRecord {
    public Kingdom Parent; public Kingdom Source; public Clan Founder;
    public string SuccessorId; public string CompletionReceiptId;
    public bool Ready; public bool Replacement; public double CompletedDay;
  }
}
'@
$behavior=@'
namespace BellumCivile.Behaviors {
 using BellumCivile;
 public sealed class CivilWarResolutionBehavior {
  private List<RestoredRealmCreationRecord> _restoredCreations=new List<RestoredRealmCreationRecord>();
  public void Append(RestoredRealmCreationRecord record){_restoredCreations.Add(record);}
'@
$harness=@'
public static class E2ReceiptHarness {
 public static int Run() {
  int n=0;
  Action<bool,string> check=(ok,s)=>{if(!ok)throw new Exception("E2_FAIL "+s);n++;};
  var p=new TaleWorlds.CampaignSystem.Kingdom("parent");
  var s=new TaleWorlds.CampaignSystem.Kingdom("rebel");
  var f=new TaleWorlds.CampaignSystem.Clan("founder");
  var b=new BellumCivile.Behaviors.CivilWarResolutionBehavior();
  var r=new BellumCivile.RestoredRealmCreationRecord {Parent=p,Source=s,Founder=f,SuccessorId="successor"};
  b.Append(r);
  check(b.GetRecentRestoredRealmCompletions().Count==0,"incomplete hidden");
  r.Ready=true;
  check(b.GetRecentRestoredRealmCompletions().Count==0,"legacy ready hidden");
  r.Ready=false;r.CompletionReceiptId="restored_realm|successor";r.CompletedDay=42.125;
  check(b.GetRecentRestoredRealmCompletions().Count==0,"stamped but not Ready hidden");
  r.Ready=true;
  var a=b.GetRecentRestoredRealmCompletions();
  check(a.Count==1,"completed visible");
  check(a[0].Id=="restored_realm|successor","stable id");
  check(a[0].CompletedDay==42.125,"exact day");
  check(a[0].ParentRealmId=="parent"&&a[0].SourceRealmId=="rebel","source identities");
  check(a[0].SuccessorRealmId=="successor"&&a[0].FounderClanId=="founder","new realm and founder");
  check(!a[0].Replacement,"replacement");
  var reload=new BellumCivile.Behaviors.CivilWarResolutionBehavior();
  reload.Append(new BellumCivile.RestoredRealmCreationRecord {Parent=p,Source=s,Founder=f,
   SuccessorId=r.SuccessorId,CompletionReceiptId=r.CompletionReceiptId,CompletedDay=r.CompletedDay,Ready=true});
  check(reload.GetRecentRestoredRealmCompletions()[0].Id==a[0].Id,"reload id stable");
  check(reload.GetRecentRestoredRealmCompletions()[0].CompletedDay==a[0].CompletedDay,"reload day stable");
  var snapshot=a[0];r.CompletedDay=999;r.CompletionReceiptId="changed";
  check(snapshot.CompletedDay==42.125&&snapshot.Id=="restored_realm|successor","scalar copy immutable");
  var many=new BellumCivile.Behaviors.CivilWarResolutionBehavior();
  for(int i=0;i<120;i++)many.Append(new BellumCivile.RestoredRealmCreationRecord{
   Parent=p,Source=s,Founder=f,SuccessorId="s"+i.ToString("D3"),CompletionReceiptId="restored_realm|s"+i.ToString("D3"),CompletedDay=i,Ready=true});
  var bounded=many.GetRecentRestoredRealmCompletions();
  check(bounded.Count==100,"limit 100");
  check(bounded[0].SuccessorRealmId=="s119"&&bounded[99].SuccessorRealmId=="s020","ordering latest");
  many.Append(new BellumCivile.RestoredRealmCreationRecord{Parent=null,Source=s,Founder=f,
    SuccessorId="bad",CompletionReceiptId="restored_realm|bad",CompletedDay=500,Ready=true});
  check(many.GetRecentRestoredRealmCompletions()[0].SuccessorRealmId=="s119","invalid excluded");
  return n;
 }
}
'@
$definitions=$stubs+[Environment]::NewLine+$snapshot+[Environment]::NewLine+$behavior+[Environment]::NewLine+$getter+[Environment]::NewLine+'} }'+[Environment]::NewLine+$harness
Add-Type -TypeDefinition $definitions -ErrorAction Stop
$n=[E2ReceiptHarness]::Run()
Write-Host "CR_RESTORATION_E2_PASS $n named isolated behavioral cases; net472 build/real save/game NOT_RUN"
