#Requires -Version 7.2
# Force launch: pwsh -NoProfile -ExecutionPolicy Bypass -File .\Tests\ForeignTerminalCrisis.Source.Tests.ps1
# Source evidence ONLY. Does not implement or behavior-test the proposed crisis contract.
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$w=Get-Content -Raw -LiteralPath (Join-Path $root 'Behaviors/WarScoreBehavior.cs')
$t=Get-Content -Raw -LiteralPath (Join-Path $root 'Behaviors/ForeignTreatyBehavior.cs')
$r=Get-Content -Raw -LiteralPath (Join-Path $root 'WarScoreRecord.cs')
$c=Get-Content -Raw -LiteralPath (Join-Path $root 'BellumCivileConstants.cs')
$j=Get-Content -Raw -LiteralPath (Join-Path $root 'ForeignDiplomacyJournal.cs')
$count=0
function Check([bool]$ok,[string]$name){if(!$ok){throw ('SOURCE_FACT_FAIL '+$name)};$script:count++;Write-Output ('SOURCE_FACT_PASS '+$name)}
function Section([string]$text,[string]$start,[string]$end){
 $a=$text.IndexOf($start,[StringComparison]::Ordinal);if($a -lt 0){throw ('Missing source boundary '+$start)}
 $b=$text.IndexOf($end,$a+$start.Length,[StringComparison]::Ordinal);if($b -le $a){throw ('Missing source boundary '+$end)}
 return $text.Substring($a,$b-$a)
}
$daily=Section $w 'private void OnDailyTick()' 'private void OnWarDeclared('
$terminal=Section $w 'private bool ResolveQueuedTerminalWarScore(' 'private bool TryCloseOrphanedForeignWarTracker('
$accept=Section $t 'public bool WouldCouncilAccept(' 'public bool'
$core=Section $t 'private bool ApplyTreatyCore(' 'internal static bool HasSettlementBudget('
$queue=Section $t 'private bool TryQueueParley(' 'private bool CanSubmitAutomaticDraft('
Check ($c.Contains('public const float WarScoreForcePeaceThreshold = 100f;')) 'native_terminal_threshold_100'
Check ($daily.Contains('ReconcileReversibleScores();') -and $daily.Contains('ProcessQueuedTerminalResolutions();') -and $daily.IndexOf('ReconcileReversibleScores();') -lt $daily.IndexOf('ProcessQueuedTerminalResolutions();')) 'reconcile_reversible_before_terminal_scheduler'
Check ($terminal.Contains('TryQueueAiParley(war, forced: true') -and $terminal.Contains('ResolveTerminalConflict(war,') -and $terminal.IndexOf('TryQueueAiParley(war, forced: true') -lt $terminal.IndexOf('ResolveTerminalConflict(war,')) 'failed_parley_can_reach_shared_resolver'
Check ([regex]::Matches($w,'\bResolveTerminalConflict\s*\(').Count -eq 3) 'shared_resolver_two_callers_plus_definition'
Check ($accept.Contains('IsBudgetBlocked') -and $accept.Contains('if (forcedAcceptance)') -and $accept.IndexOf('IsBudgetBlocked') -lt $accept.IndexOf('if (forcedAcceptance)')) 'budget_block_precedes_forced_acceptance'
Check ($accept.Contains("if (forcedAcceptance)`n                return true;") -or $accept.Contains("if (forcedAcceptance)`r`n                return true;")) 'forced_acceptance_distinct_from_ordinary_vote'
Check ($queue.Contains('StorylineWarProtectionHelper.IsPeaceBlocked') -and $queue.Contains('AlliancePeaceRestriction.TryGetPeaceBlock') -and $queue.Contains('IsAuxiliaryClientWar')) 'parley_preserves_story_alliance_client_guards'
Check ($t.Contains('if (proposal.IsForced)') -and $t.Contains('TryShowForcedPlayerParleyInquiry(war, proposal)')) 'dedicated_forced_player_inquiry_exists'
Check ($core.Contains('TransferCollectiveGold(') -and $core.Contains('MakePeaceAction.Apply(') -and $core.Contains('ApplyStructuralPoliticalTerms(') -and $core.IndexOf('TransferCollectiveGold(') -lt $core.IndexOf('MakePeaceAction.Apply(') -and $core.IndexOf('ApplyStructuralPoliticalTerms(') -gt $core.IndexOf('MakePeaceAction.Apply(')) 'term_effects_span_peace_action'
Check ($t.Contains('RecoverTreatyDelivery(proposal.ProposalId)')) 'hostage_delivery_has_recovery_owner'
Check ($r.Contains('string.CompareOrdinal(first, second) <= 0')) 'pair_key_not_unique_war_epoch'
Check ($r.Contains('System.Math.Abs(_score) < 100f) ClearTerminalResolution();')) 'reversible_score_can_clear_terminal_queue'
Check ($j.Contains('r.Source == ForeignDiplomacySource.AutomaticForeignWar') -and !$j.Contains('TerminalForeignWar')) 'ordinary_journal_does_not_admit_crisis_source'
Check ($terminal.Contains('TryCloseOrphanedForeignWarTracker') -and $w.Contains('war.MarkEnded(endedDay);')) 'external_or_orphan_reconciliation_exists'
Write-Output ('SOURCE FACTS PASS '+$count+'; proposed crisis behavior NOT_IMPLEMENTED; behavioral cases NOT_RUN')
