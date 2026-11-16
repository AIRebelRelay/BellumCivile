$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
function Read($p){Get-Content -Raw -LiteralPath (Join-Path $root $p)}
function Check($v,$text){if(!$v){throw $text};"PASS: $text"}
$source=Read 'CourtRallyObjectiveSource.cs'
$behavior=Read 'Behaviors/CourtRallyAgendas.cs'
$treaty=Read 'Behaviors/ForeignTreatyBehavior.cs'
$settlement=Read 'CourtRallySettlement.cs'
$will=Read 'Behaviors/WarPeaceRevampBehavior.cs'
$score=Read 'Behaviors/WarScoreBehavior.cs'
$ratification=Read 'TreatyRatificationService.cs'
$draft=Read 'TreatyAiDraftService.cs'
$picker=Read 'Behaviors/CourtPlayerMotionPicker.cs'
Check ($source.Contains('FactionType.Glory') -and $source.Contains('Mood > 0') -and $source.Contains('MemberCount(o.Faction) >= 2')) 'Positive Glory with two houses owns the motion.'
Check ($source.Contains('PeekWarWill') -and $source.Contains('/ power > 60') -and $source.Contains('c.RallyCandidates(o.Faction)')) 'Need uses cached discovery and base military-weighted enthusiasm.'
Check ($source.Contains('!war.ParleyForced') -and $source.Contains('!war.TerminalResolutionQueued') -and $source.Contains('IsStorylineProtectedForeignWar')) 'Forced and protected wars cannot be selected.'
Check (!$behavior.Contains('ApplyWarWillShock') -and !$behavior.Contains('SetWarWill')) 'Rally never mutates global enthusiasm.'
Check ($behavior.Contains('_rallyIndex.TryGetValue(war') -and $behavior.Contains('now < a.Rally.Expires') -and $behavior.Contains('ReceivesPoliticalSupport(a,clan,a.Rally.Members)')) 'Indexed query preserves expiry, membership and Crown alignment.'
Check ($behavior.Contains('clan == Clan.PlayerClan') -and $behavior.Contains('a.Rally.War.AttackerKingdomId == a.Rally.Attacker')) 'Player agency and original identity retained.'
Check ($behavior.Contains('TryClaimResult()') -and $behavior.Contains('if(a.Rally.OutcomeRecorded) continue')) 'Outcome and approval receipts are one shot.'
Check ($behavior.IndexOf('if(r.OutcomeRecorded)') -lt $behavior.IndexOf('if(!CourtPeaceObjectiveSource.EligibleWar')) 'Timely outcome is handled before closed-war invalidation.'
Check ($behavior.Contains('now <= r.PendingDay+1') -and $behavior.Contains('"unverified_closure"')) 'Interrupted treaty delivery waits briefly then closes neutrally.'
Check ($treaty.IndexOf('BeginRallySettlement(war)') -lt $treaty.IndexOf('var rallyGold')) 'Settlement stages before destructive actions.'
Check ($treaty.IndexOf('CourtRallySettlement.Record(') -gt $treaty.IndexOf('QueueRebelDemandResolutions(proposal);')) 'Outcome receipt follows structural and concession delivery.'
Check ($settlement.Contains('gold.TryGetValue(t,out int paid)') -and $settlement.Contains('!delivered.Contains(t)') -and $settlement.Contains('OwnerClan?.Kingdom?.StringId')) 'Result uses paid gold and verified structural/territorial delivery.'
Check (!$settlement.Contains('UsedWarScore') -and $settlement.Contains('TreatyTermType.ReleasePrisoner') -and $settlement.Contains('TreatyTermType.ArrangeRoyalMarriage')) 'Budget credits and reciprocal/marriage clauses do not manufacture victory.'
Check ($will.Contains('requireLowWill: true') -and $score.Contains('.Where(war => !requireLowWill || CourtAgendaBehavior.EffectiveWarWill')) 'Proposer keeps looking for another eligible front.'
Check ($score.Contains('CalculatePowerWeightedWarWill(primary,war)') -and $score.Contains('float losingWill = CalculatePowerWeightedWarWill(losingSide, war);') -and
    $behavior.Contains('CourtPeaceObjectiveSource.EligibleWar(a.Realm,a.Rally.Target,war)') -and
    (Read 'CourtPeaceObjectiveSource.cs').Contains('war.ConflictType == WarScoreConflictType.ForeignWar') -and
    $behavior.Contains('if (clan == null || clan == Clan.PlayerClan || war?.IsActive != true || !WarPeaceRevampBehavior.IsRevampEnabled()) return baseline;')) 'War context reaches exhaustion while rally eligibility excludes internal, inactive, player and OFF cases.'
Check ($ratification.Contains('float effectiveWill = CourtAgendaBehavior.EffectiveWarWill(clan, war, enthusiasm);') -and
    $ratification.Contains('if (effectiveWill != enthusiasm)') -and
    $ratification.Contains('var readiness = PeaceReadiness.Evaluate(days, war?.Score ?? warScoreBudget, enthusiasm, BellumCivileOptions.WarDurationReluctanceDays);') -and
    $ratification.Contains('var rallied = PeaceReadiness.Evaluate(days, war?.Score ?? warScoreBudget, effectiveWill, BellumCivileOptions.WarDurationReluctanceDays);') -and
    ([regex]::Matches($ratification, 'Add\(reasons, ref utility, rallied.Total - readiness.Total, "Court rally"\);')).Count -eq 1 -and
    (Read 'CourtRallyRecord.cs').Contains('eligible ? Math.Min(100, baseline + 15) : baseline')) 'Snapshot base receives one capped rally delta through the current nonlinear peace-readiness model.'
Check ($draft.Contains('CalculateRealmWarWill(drafter,war)') -and $draft.Contains('CalculateRealmWarWill(loser,war)') -and $draft.Contains('CalculateRealmWarWill(drafter ?? winner,war)')) 'All draft enthusiasm consumers receive original war context.'
Check ($picker.Contains('agenda.Rally = prepared.Rally') -and $picker -match 'kind == CourtRallyRules.Kind[^\r\n]*BC_CourtPickerForeignAffairs') 'Player choice copies rally snapshot and uses foreign affairs category.'
Check ((Read 'BellumCivileSaveDefiner.cs').Contains('AddClassDefinition(typeof(CourtRallyRecord), 104)') -and (Read 'Behaviors/CourtAgendaBehavior.cs').Contains('BC_CourtRallies')) 'Appended save identity and independent journal wired.'
[xml]$xml=Read 'ModuleData/Languages/EN/strings.xml'
$texts=$behavior+$picker+(Read 'CourtAgendaPresentation.cs')+$ratification
$ids=[regex]::Matches($texts,'\{=(BC_Rally[^}]+)\}') | ForEach-Object {$_.Groups[1].Value} | Sort-Object -Unique
foreach($id in $ids){
    $nodes=@($xml.SelectNodes("//string[@id='$id']"))
    Check ($nodes.Count -eq 1) "Unique localization: $id"
    $fallback=[regex]::Match($texts,('\{='+[regex]::Escape($id)+'\}([^"\r\n]*)')).Groups[1].Value.Replace('\n',"`n")
    Check ($nodes[0].text -ceq $fallback) "Matching fallback: $id"
}
'Rally source/XML contracts passed; actual campaign/treaty delivery and native save/load remain to test.'
