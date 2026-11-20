# Bannerlord 1.5.7 hostage betrayal Honor ABI and neighbor regression contract.
# Source assertions only. Harness runtime execution and 1.5.7 compilation/game tests remain required.
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$sourceFiles = @{
    Termination = 'Behaviors/HostagePactTermination.cs'
    Harness = 'Tests/SuccessionEngineHarness/HostageTerminationTests.cs'
    Record = 'HostagePactRecord.cs'
    Maintenance = 'Behaviors/HostagePactMaintenance.cs'
}
$contents = @{}
foreach ($entry in $sourceFiles.GetEnumerator()) {
    $p = Join-Path $root $entry.Value
    if (-not (Test-Path -LiteralPath $p -PathType Leaf)) { throw "BELLUM157_HOSTAGE_HONOR FAIL missing_source=$p" }
    $contents[$entry.Key] = [System.IO.File]::ReadAllText($p)
}
function Assert-Has([string]$body, [string]$fragment, [string]$caseName) {
    if (-not $body.Contains($fragment)) { throw "BELLUM157_HOSTAGE_HONOR FAIL $caseName" }
    Write-Output "PASS BELLUM157_HOSTAGE_HONOR $caseName"
}
function Assert-No([string]$body, [string]$fragment, [string]$caseName) {
    if ($body.Contains($fragment)) { throw "BELLUM157_HOSTAGE_HONOR FAIL $caseName" }
    Write-Output "PASS BELLUM157_HOSTAGE_HONOR $caseName"
}
$t = $contents.Termination
$h = $contents.Harness
$r = $contents.Record
$m = $contents.Maintenance

Assert-No $t 'TraitLevelingHelper.OnLordExecuted()' 'obsolete_execution_trait_api_removed'
Assert-Has $t 'private static bool NeedsHostageBetrayalHonorPenalty(Hero victim)' 'dedicated_honor_policy'
Assert-Has $t 'victim.GetTraitLevel(DefaultTraits.Honor) < 0 || victim.Clan?.HasBloodFeudWithPlayer == true;' 'native_honor_or_blood_feud_policy'
Assert-Has $t 'pact.ExecutionNeedsHonorPenalty = NeedsHostageBetrayalHonorPenalty(victim.Hero);' 'honor_policy_snapshotted_before_execution'
Assert-Has $t 'KillCharacterAction.ApplyByExecution(victim.Hero, pact.TerminatingRuler, true, false);' 'native_execution_retained'
Assert-Has $t 'if (pact.ExecutionNeedsHonorPenalty && pact.TerminatingRuler == Hero.MainHero)' 'player_only_extra_honor_penalty'
Assert-Has $t 'TraitLevelingHelper.OnIncidentResolved(DefaultTraits.Honor, -1000);' 'on_incident_resolved_honor_loss'
Assert-Has $t 'if (!pact.TerminationTraitApplied)' 'single_trait_receipt_guard'
Assert-Has $t 'pact.TerminationTraitApplied = true;' 'trait_receipt_persisted'
Assert-Has $t 'if (!victim.ExecutionSucceeded) return;' 'failed_execution_no_penalty'
Assert-Has $t 'if (!pact.BreachMemoryApplied)' 'one_time_breach_memory_guard'
Assert-Has $t 'RelationMemorySources.BetrayedHostagePledge, 10, RelationMemoryScope.House);' 'oathbreaking_relation_memory_retained'
Assert-Has $t 'if (!victim.ActionStarted)' 'execution_idempotency_retained'
Assert-Has $t 'CancelHostageJudgment(pact, victim);' 'cancellation_retained'
Assert-Has $t 'if (pact.EndReason != HostagePactEndReason.EarlyRelease) return;' 'early_release_scope_retained'
Assert-Has $t 'TraitLevelingHelper.OnIncidentResolved(DefaultTraits.Honor, 20);' 'early_release_reward_retained'
Assert-Has $t 'ResolveWarHostage(pact, pact.FirstHostage == victim ? pact.SecondHostage : pact.FirstHostage);' 'reciprocal_response_retained'

Assert-Has $r '[SaveableField(24)] public bool TerminationTraitApplied;' 'honor_receipt_save_id_retained'
Assert-Has $r '[SaveableField(26)] public bool ExecutionNeedsHonorPenalty;' 'honor_policy_save_id_retained'
Assert-Has $m 'if (pact.EndReason == HostagePactEndReason.Betrayal && !ResolveHostageBetrayal(pact)) return;' 'judgment_dispatch_retained'
Assert-Has $m 'ApplyEarlyReleaseRewards(pact);' 'release_dispatch_retained'

Assert-No $h 'OnLordExecuted' 'harness_obsolete_hook_removed'
Assert-Has $h 'HasBloodFeudWithPlayer' 'harness_feud_mock'
Assert-Has $h 'HonorLevel' 'harness_honor_mock'
Assert-Has $h 'foreach (int honor in new[] { -1, 0, 1 })' 'harness_three_honor_levels'
Assert-Has $h 'foreach (bool feud in new[] { false, true })' 'harness_two_feud_states'
Assert-Has $h 'honor < 0 || feud' 'harness_six_policy_cases'
Assert-Has $h 'Events.SequenceEqual(new[] { "betrayed_hostage_pledge:-30", "honor:-1000" })' 'harness_one_time_honor_loss'
Assert-Has $h 'Events.SequenceEqual(new[] { "released_treaty_hostage_early:5", "released_treaty_hostage_early:5", "honor:20" })' 'harness_early_release_reward'
Assert-Has $h 'Events.SequenceEqual(new[] { "betrayed_hostage_pledge:-30", "honor:-1000", "response" })' 'harness_execution_order'
Write-Output 'BELLUM157_HOSTAGE_HONOR SOURCE_PASS; harness_execution_and_gameplay=NOT_RUN'
