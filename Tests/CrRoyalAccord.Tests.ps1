#Requires -Version 7.2
# Force: pwsh -NoProfile -ExecutionPolicy Bypass -File .\Tests\CrRoyalAccord.Tests.ps1
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
function Read([string]$rel){Get-Content -LiteralPath (Join-Path $root $rel) -Raw}
function Pass([string]$n,[bool]$ok){if(!$ok){throw "ROYAL_ACCORD_FAIL $n"};Write-Output "PASS $n"}
$p=Read 'TreatyProposalRecord.cs'
$t=Read 'Behaviors/ForeignTreatyBehavior.cs'
$g=Read 'BellumIntegrationCrDiplomacyGateway.cs'
Pass 'gateway_v2_and_only_exact_instance_actors' ($g.Contains('CrDiplomacyGatewayApiVersion = 2') -and
 $g.Contains('war.ConflictInstanceId, conflictInstanceId') -and $g.Contains('RulerChanged') -and
 $g.Contains('TryQueueCrRoyalAccordParley(war, first,') -and $g.Contains('AlreadyPending'))
Pass 'ordinary_auto_path_unchanged' ($t.Contains('TryQueueParley(war, forced, preferWhitePeace, reason, requireAiOnly: !playerInvolved, automaticRequest: true, drafter, out report);') -and
 $t.Contains('if (automaticRequest && !CanSubmitAutomaticDraft(') -and
 $t.Contains('if (automaticRequest && !TryValidateCouncilControlledWhitePeace('))
Pass 'royal_entry_only_on_npc_explicit_white_peace' ($t.Contains('public bool TryQueueCrRoyalAccordParley(') -and
 $t.Contains('if (!IsAiOnlyWar(attacker, defender)) return false;') -and
 $t.Contains('automaticRequest: false, drafter: drafter, report: out report,') -and
 $t.Contains('proposal.TryMarkCrRoyalAccord(war.ConflictInstanceId,'))
Pass 'royal_is_nonforced_and_persisted' ($p.Contains('[SaveableField(25)] private bool _crRoyalAccord;') -and
 $p.Contains('[SaveableField(26)] private string _crRoyalFirstRulerId;') -and
 $p.Contains('[SaveableField(27)] private string _crRoyalSecondRulerId;') -and
 $p.Contains('public bool IsCrRoyalAccord => _crRoyalAccord && !_isForced && IsExplicitWhitePeace') -and
 $p.Contains('internal bool TryMarkCrRoyalAccord('))
Pass 'no_auto_willingness_veto_on_royal' ($g.Contains('return new CrForeignPeaceSnapshot("Ready", war, canSuggest: true);') -and
 $t.Contains('if (proposal.IsCrRoyalAccord)') -and
 $t.Contains('!proposal.IsForced && !proposal.IsCrRoyalAccord && Math.Abs(war.Score)'))
Pass 'ruler_and_war_reevaluated_before_effects' ($t.Contains('private static bool IsCurrentCrRoyalAccord(') -and
 ([regex]::Matches($t,'proposal.WasCrRoyalAccord && !IsCurrentCrRoyalAccord')).Count -ge 4 -and
 $t.Contains('IsBoundToCurrentTreatyWar(war, proposal)') -and
 $t.Contains('IsAiOnlyWar(drafter, opposite)'))
Pass 'council_opinions_inform_effects_not_veto' ($t.Contains('winnerUsesOverride = !winnerAccepts;') -and
 $t.Contains('winnerAccepts = true;') -and $t.Contains('loserAccepts = true;') -and
 $t.Contains('SpendCouncilCommitments(proposal, winnerCouncil, loserCouncil);') -and
 $t.Contains('ApplyFinalCouncilConsequences(proposal, winnerRuler, winnerCouncil, winnerAccepts, winnerUsesOverride,'))
Pass 'old_treaty_executor_and_safety_stay' ($t.Contains('BellumPeaceResolutionContext.RunBellumPeaceResolution(') -and
 $t.Contains('MakePeaceAction.Apply(winner, loser)') -and
 $t.Contains('TryCancelStorylineProtectedProposal(war, proposal, out _)') -and
 $t.Contains('TryCancelAllianceRestrictedProposal(war, proposal, out _)') -and
 !$g.Contains('MakePeaceAction.') -and !$g.Contains('forced: true'))
Write-Output 'CR_ROYAL_ACCORD_SOURCE_CONTRACT_PASS 8; gameplay/save-load NOT_RUN'
