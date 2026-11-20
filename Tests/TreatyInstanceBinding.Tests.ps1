#Requires -Version 7.2
# Force launch: pwsh -NoProfile -ExecutionPolicy Bypass -File .\Tests\TreatyInstanceBinding.Tests.ps1
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
function Source([string]$path){Get-Content -LiteralPath (Join-Path $root $path) -Raw}
function Pass([string]$name,[bool]$condition){if(!$condition){throw "FAIL $name"};Write-Output "PASS $name"}
$source=Source 'TreatyWarInstanceBinding.cs'
# Compile *actual* pure production helper in its own pwsh process; only visibility changes
# so test script can invoke its internal method. No TaleWorlds test stubs required.
$testSource=$source.Replace('internal static class TreatyWarInstanceBinding','public static class TreatyWarInstanceBinding').Replace('internal static bool Matches','public static bool Matches')
Add-Type -TypeDefinition $testSource -CompilerOptions '/langversion:7.3' -ErrorAction Stop
$idA='a3e46c8eaa26484d8bc9bfbd25cb8f0e'
$idB='53f3eef645a747a3a3471b7746c81f79'
$pair='nord|vlandia'
function Match([string]$id,[string]$current,[string]$storedKey,[string]$currentKey,[bool]$active,[bool]$foreign,[bool]$ambiguous){
 [BellumCivile.TreatyWarInstanceBinding]::Matches($id,$current,$storedKey,$currentKey,$active,$foreign,$ambiguous)
}
Pass 'exact_active_foreign_war_bound' (Match $idA $idA $pair $pair $true $true $false)
Pass 'repeat_deterministic' ((Match $idA $idA $pair $pair $true $true $false) -and (Match $idA $idA $pair $pair $true $true $false))
Pass 'new_war_same_pair_rejects_old_treaty' (!(Match $idA $idB $pair $pair $true $true $false))
Pass 'different_pair_rejected' (!(Match $idA $idA $pair 'battania|empire_w' $true $true $false))
Pass 'ended_war_rejected' (!(Match $idA $idA $pair $pair $false $true $false))
Pass 'internal_war_rejected' (!(Match $idA $idA $pair $pair $true $false $false))
Pass 'native_repeat_ambiguity_rejected' (!(Match $idA $idA $pair $pair $true $true $true))
Pass 'legacy_pending_missing_id_rejected' (!(Match $null $idA $pair $pair $true $true $false))
Pass 'current_missing_id_rejected' (!(Match $idA $null $pair $pair $true $true $false))
Pass 'malformed_id_rejected' (!(Match 'bad' $idA $pair $pair $true $true $false))
Pass 'empty_guid_rejected' (!(Match '00000000000000000000000000000000' '00000000000000000000000000000000' $pair $pair $true $true $false))
Pass 'uppercase_guid_rejected' (!(Match $idA.ToUpperInvariant() $idA.ToUpperInvariant() $pair $pair $true $true $false))
Pass 'blank_pair_rejected' (!(Match $idA $idA '' '' $true $true $false))
Pass 'case_changed_pair_rejected' (!(Match $idA $idA 'NORD|vlandia' $pair $true $true $false))

$proposal=Source 'TreatyProposalRecord.cs'
$fields=[regex]::Matches($proposal,'\[SaveableField\((\d+)\)\]\s+private\s+(\S+)\s+(\w+);')
Pass 'proposal_schema_27_fields' ($fields.Count -eq 27)
$old=@($fields | Where-Object {[int]$_.Groups[1].Value -le 23} | Sort-Object {[int]$_.Groups[1].Value} | ForEach-Object {"$($_.Groups[1].Value):$($_.Groups[2].Value):$($_.Groups[3].Value)"})
$bytes=[Text.Encoding]::UTF8.GetBytes(($old -join "`n"))
$hash=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($bytes)).ToLowerInvariant()
Pass 'proposal_original_23_save_fields_byte_contract' ($hash -ceq '33d0fdae5982b2f8e18af84b7abdcde11d3d927d2066faf675347ddc34f1a72e')
Pass 'new_field24_only_string_id' ($proposal.Contains('[SaveableField(24)] private string _conflictInstanceId;'))
Pass 'optional_royal_save_fields_25_27' (
 $proposal.Contains('[SaveableField(25)] private bool _crRoyalAccord;') -and
 $proposal.Contains('[SaveableField(26)] private string _crRoyalFirstRulerId;') -and
 $proposal.Contains('[SaveableField(27)] private string _crRoyalSecondRulerId;') -and
 $proposal.Contains('internal bool WasCrRoyalAccord => _crRoyalAccord;')
)
Pass 'saved_id_bound_at_creation' ($proposal.Contains('_conflictInstanceId = conflictInstanceId;') -and $proposal.Contains('public string BoundConflictInstanceId => _conflictInstanceId;'))

$behavior=Source 'Behaviors/ForeignTreatyBehavior.cs'
function Slice([string]$from,[string]$to){
 $a=$behavior.IndexOf($from,[StringComparison]::Ordinal)
 $b=$behavior.IndexOf($to,$a + $from.Length,[StringComparison]::Ordinal)
 if($a -lt 0 -or $b -le $a){throw "Missing method boundary: $from => $to"}
 return $behavior.Substring($a,$b-$a)
}
$queue=Slice 'private bool TryQueueParley(' 'private bool CanSubmitAutomaticDraft('
Pass 'queue_requires_unique_active_record' ($queue.Contains('IsCurrentTreatyWar(war)') -and $queue.Contains('war.ConflictInstanceId);'))
Pass 'queue_cancels_old_pending_same_pair' ($queue.Contains('IsBoundToCurrentTreatyWar(war, candidate)') -and $queue.Contains('CancelStaleTreatyProposal(candidate);'))
$pending=Slice 'private bool TryPreparePendingProposalDraft(' 'private bool TryRebuildNpcDraftWithinBudget('
Pass 'pending_guards_before_hostage_recovery' ($pending.IndexOf('IsBoundToCurrentTreatyWar(war, proposal)') -gt -1 -and $pending.IndexOf('IsBoundToCurrentTreatyWar(war, proposal)') -lt $pending.IndexOf('RecoverTreatyDelivery(proposal.ProposalId)'))
$apply=Slice 'private bool ApplyTreaty(' 'internal static bool HasSettlementBudget('
Pass 'apply_and_core_guard_before_side_effects' ($apply.Contains('private bool ApplyTreatyCore(') -and ([regex]::Matches($apply,'IsBoundToCurrentTreatyWar\(war, proposal\)')).Count -eq 2 -and $apply.IndexOf('IsBoundToCurrentTreatyWar(war, proposal)', $apply.IndexOf('private bool ApplyTreatyCore(')) -lt $apply.IndexOf('ApplyTerritorialTerms('))
$cancel=Slice 'private void CancelStaleTreatyProposal(' 'internal const string CapitulationDraftLockedReason'
Pass 'stale_cancel_does_not_end_new_parley' ($cancel.Contains('CancelInvalidProposal(null, proposal, reason)') -and !$cancel.Contains('.EndParley('))
Pass 'user_entrypoints_check_instance' (([regex]::Matches($behavior,'IsBoundToCurrentTreatyWar\(')).Count -ge 10)
$recovery=Source 'Behaviors/HostageTreatyRecovery.cs'
Pass 'hostage_recovery_does_not_end_later_war_parley' ($recovery.Contains('TreatyWarInstanceBinding.Matches(') -and $recovery.Contains('GetExistingForeignConflictByInstance(') -and !$recovery.Contains('?.GetActiveWar(pact.FirstRealm, pact.SecondRealm)?.EndParley();'))
Pass 'history_debug_still_exposes_applied_records' ($behavior.Contains('Take(12)') -and $behavior.Contains('state={proposal.State}'))
Pass 'bellum_peace_execution_unchanged' ($apply.Contains('BellumPeaceResolutionContext.RunBellumPeaceResolution(') -and $apply.Contains('MakePeaceAction.Apply(winner, loser)'))
Write-Output 'TREATY_INSTANCE_BINDING_PASS 28; pure helper compiled and source contracts checked; gameplay/save-load NOT_RUN'
