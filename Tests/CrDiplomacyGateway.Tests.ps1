#Requires -Version 7.2
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$gateway=Get-Content -LiteralPath (Join-Path $root 'BellumIntegrationCrDiplomacyGateway.cs') -Raw
$build=Get-Content -LiteralPath (Join-Path $root 'scripts/Verify-CrBellumNativeWitnessWindows.ps1') -Raw
function Pass($label,[bool]$ok){if(!$ok){throw "GATEWAY FAIL $label"};Write-Output "PASS $label"}
Pass 'public_detached_snapshot' ($gateway.Contains('public sealed class CrForeignPeaceSnapshot') -and $gateway.Contains('public sealed class CrForeignTreatyReceipt'))
Pass 'exact_instance_and_ruler_checks' ($gateway.Contains('war.ConflictInstanceId, conflictInstanceId') -and $gateway.Contains('RulerChanged'))
Pass 'global_id_and_native_witness' ($gateway.Contains('GetExistingForeignConflictByInstance(') -and $gateway.Contains('WeakTimestampMatchNotProof'))
Pass 'forbid_player_and_nonforeign' ($gateway.Contains('PlayerRealmExcluded') -and $gateway.Contains('WarScoreConflictType.ForeignWar'))
Pass 'forbid_ambiguous_pair' ($gateway.Contains('candidates.Count != 1'))
Pass 'forbid_pending_proposals' ($gateway.Contains('return new CrForeignTreatyReceipt("AlreadyPending")'))
Pass 'no_forced_or_native_peace' ($gateway.Contains('TryQueueCrRoyalAccordParley(') -and !$gateway.Contains('TryQueueAiParley(') -and !$gateway.Contains('forced: true') -and !$gateway.Contains('MakePeaceAction.') -and !$gateway.Contains('DeclareWarAction.'))
Pass 'exact_receipt_no_warkey_fallback' ($gateway.Contains('p.BoundConflictInstanceId != conflictInstanceId') -and $gateway.Contains('row.ProposalId == proposalId'))
Pass 'fail_closed_unknown_after_possible_side_effects' ($gateway.Contains('UnknownAfterQueue'))
Pass 'release_without_qa' ($build.Contains('BELLUM_CR_DIPLOMACY_GATE_PASS') -and !$build.Contains(' -WorkshopFolder $WorkshopFolder -TreatyQa'))
Write-Output 'CR_DIPLOMACY_GATEWAY_SOURCE_CONTRACT_PASS 10; game NOT_RUN'
