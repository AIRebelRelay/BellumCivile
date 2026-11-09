$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
function Read([string]$p) { Get-Content -Raw (Join-Path $root $p) }
function Check([bool]$ok, [string]$description) { if (-not $ok) { throw "FAIL: $description" }; "PASS: $description" }
$feudal = Read 'Behaviors/FeudalTitleBehavior.cs'
$vote = Read 'Patches/FiefVoteResolutionPatch.cs'
$deliberation = Read 'Behaviors/FiefDeliberationBehavior.cs'
$barter = Read 'Tests/SettlementBarter.Tests.ps1'
$stub = Read 'Tests/InheritedPossession.Tests.ps1'
$program = Read 'Tests/SuccessionEngineHarness/Program.cs'
$fixture = Read 'Tests/SuccessionEngineHarness/FiefRedistributionTests.cs'
$start = $feudal.IndexOf('private void OnSettlementOwnerChanged(', [StringComparison]::Ordinal)
$end = $feudal.IndexOf('private bool TryApplySubinfeudationOwnershipChange(', $start + 1, [StringComparison]::Ordinal)
if ($start -lt 0 -or $end -lt $start) { throw 'Missing ownership event method boundary' }
$transfer = $feudal.Substring($start, $end - $start)
Check ($vote.Contains('internal Clan VoluntaryGrantor;') -and
       $vote.Contains('internal static bool IsVoluntaryRelinquishment(Settlement settlement, string formerHolderId, Clan recipient)')) 'Native award scope distinguishes voluntary donor from ordinary exclusion.'
Check ($vote.Contains('__instance.ProposerClan == excluded') -and
       $vote.Contains('__instance.Settlement?.OwnerClan == excluded') -and
       $vote.Contains('excluded.Kingdom == __instance.Kingdom')) 'Only a self-proposed relinquishment by current in-realm owner is voluntary.'
Check ($vote.Contains('ActiveAwards.LastOrDefault(s => s.Decision.Settlement == settlement)') -and
       $vote.Contains('scope.VoluntaryGrantor.StringId == formerHolderId') -and
       $vote.Contains('recipient.Kingdom == scope.Decision.Kingdom')) 'Scope prevents wrong recipient, wrong donor and nested-vote context bleed.'
Check ($vote.Contains('ActiveAwards.RemoveAt(index);') -and
       $vote.Contains('return __exception;')) 'Native award finalizer cleans intent and preserves original exceptions.'
Check ($transfer.Contains('ShouldPreserveDomesticBaronyHierarchy(titleBeforeTransfer, newOwner?.Clan ?? settlement.OwnerClan)') -and
       $transfer.Contains('possessionOnly || preserveLegalHierarchy ? GetDriftOriginKingdomId(titleBeforeTransfer) : null') -and
       $transfer.Contains('if (possessionOnly || preserveLegalHierarchy)')) 'Same-realm grants keep the original legal parent and territorial origin across title synchronization.'
Check ($transfer.Contains('if (!preserveLegalHierarchy)') -and
       $transfer.Contains('UpdateBaronyParentToCurrentKingdom(title, newClan);')) 'Only unprotected legal transfers reparent to the new realm.'
Check ($transfer.Contains('detail == ChangeOwnerOfSettlementAction.ChangeOwnerOfSettlementDetail.ByKingDecision') -and
       $transfer.Contains('Patches.FiefVoteResolutionPatch.IsVoluntaryRelinquishment(settlement, previousDeFacto, newClan)')) 'Voluntary claims are suppressed only for an actual king-decision award.'
Check ($transfer.Contains('if (voluntaryRelinquishment && previousDeJure == previousDeFacto)') -and
       $transfer.Contains('else if (!wasAllocationCustody || previousDeJure != previousDeFacto)')) 'Voluntary owner claim is suppressed while separate third-party legal claims remain.'
Check ($transfer.Contains('if (voluntaryRelinquishment)') -and
       $transfer.Contains('DeactivateClaimsForTitle(ResolveClan(previousDeFacto), title);')) 'Donor relinquishes only claims attached to the granted title after award.'
$helper = $feudal.Substring($feudal.IndexOf('private bool ShouldPreserveDomesticBaronyHierarchy('))
Check ($helper.Contains('parent != null && parent.IsActive && parent.TitleType > title.TitleType') -and
       $helper.Contains('ResolveClan(title.DeJureHolderClanId)?.Kingdom == recipient.Kingdom') -and
       $helper.Contains('ResolveClan(title.DeFactoHolderClanId)?.Kingdom == recipient.Kingdom')) 'Preservation requires active higher legal parent and matching political realm.'
$decouple = $feudal.Substring($feudal.IndexOf('private bool ShouldDecoupleFromLegalParent('), 850)
Check ($decouple.Contains('IsDeFactoParentControlledByKingdom(title, legalParent, holderKingdom)') -and
       $feudal.Contains('IsLegalParentCompatibleWithKingdom(title, currentLegalParent, kingdom)')) 'De facto decoupling uses political control but foreign legal-reparent decisions keep their existing gate.'
Check ($deliberation.Contains('QueueRelinquishedSettlementVote(Settlement settlement)') -and
       $deliberation.Contains('BellumCivile_PendingFiefProposer') -and
       $deliberation.Contains('BellumCivile_PendingFiefExclude')) 'Existing queue serialization supports voluntary context without new save fields.'
Check ($barter.Contains('preserveLegalHierarchy') -and
       $barter.Contains('RegisterDisplacedLegalOwnerClaimIfNeeded') -and
       $barter.Contains('DeactivateClaimsForTitle')) 'Existing barter regression checks legal-parent and seller-claim protections.'
Check ($stub.Contains('public static bool IsVoluntaryRelinquishment(Settlement settlement, string formerHolder, Clan recipient)')) 'Isolated inheritance-ownership fixture compiles against the new local vote API.'
Check ($program.Contains('FiefRedistributionTests.Run(Check);') -and
       $program.Contains('--fief-redistribution') -and
       $fixture.Contains('Nested nonvoluntary ballot cannot borrow outer voluntary intent') -and
       $fixture.Contains('Loaded pending vote') -and
       $fixture.Contains('Rank-aware award to ')) 'Compiled test scenarios cover nested votes, old-save reload and de facto rank handling.'
Check ($transfer.Contains('legal_hierarchy_preserved={preserveLegalHierarchy}; voluntary_relinquishment={voluntaryRelinquishment}')) 'Existing title sync diagnostic gains explicit ownership provenance.'
'P0-13A source contracts passed; Windows harness/PowerShell and game checks remain PENDING.'
