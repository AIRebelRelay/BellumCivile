#Requires -Version 7.2
# Force launch: pwsh -NoProfile -ExecutionPolicy Bypass -File .\Tests\TreatyQaConsole.Tests.ps1
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
function Source([string]$path){Get-Content -LiteralPath (Join-Path $root $path) -Raw}
function Pass([string]$name,[bool]$condition){if(!$condition){throw "FAIL $name"};Write-Output "PASS $name"}
$command=Source 'CheatCommands.cs'
$proj=Source 'BellumCivile.csproj'
$runner=Source 'scripts/Verify-CrBellumNativeWitnessWindows.ps1'
$builder=Source 'scripts/Build-CrBellumModuleWindows.ps1'
$start=$command.IndexOf('#if BELLUM_TREATY_QA',[StringComparison]::Ordinal)
$end=$command.IndexOf('#endif',$start,[StringComparison]::Ordinal)
if($start -lt 0 -or $end -le $start){throw 'Missing QA-only source boundary'}
$qa=$command.Substring($start,$end-$start)
Pass 'qa_compile_opt_in_only' ($proj.Contains('Condition="''$(BellumTreatyQa)'' == ''true''"') -and $proj.Contains('BELLUM_TREATY_QA'))
Pass 'qa_build_flag_still_explicit_release_off' ($builder.Contains('if($TreatyQa){$arguments+=''-p:BellumTreatyQa=true''}') -and !$runner.Contains(' -WorkshopFolder $WorkshopFolder -TreatyQa'))
Pass 'qa_command_has_explicit_test_confirmation' ($qa.Contains('CONFIRM_TEST_SAVE') -and $qa.Contains('secondSeparator != args.Count - 2'))
Pass 'qa_command_checks_campaign_thread' ($qa.Contains('BellumIntegrationBehavior.RequireCampaignThread()'))
Pass 'qa_command_checks_revamp_enabled' ($qa.Contains('WarPeaceRevampBehavior.IsRevampEnabled()'))
Pass 'qa_command_rejects_player_participants' ($qa.Contains('WarPeaceRevampBehavior.IsPlayerPoliticalParticipant(first, second)'))
Pass 'qa_command_rejects_non_hostility' ($qa.Contains('first.IsAtWarWith(second)') -and $qa.Contains('second.IsAtWarWith(first)'))
Pass 'qa_command_requires_single_active_foreign_record' ($qa.Contains('WarScoreConflictType.ForeignWar') -and $qa.Contains('GetActiveWars().Count(') -and $qa.Contains('!= 1'))
Pass 'qa_command_requires_canonical_guid' ($qa.Contains('Guid.TryParseExact(') -and $qa.Contains('Guid.Empty'))
Pass 'qa_command_rejects_pending_conflict' ($qa.Contains('war.ParleyPending') -and $qa.Contains('war.TerminalResolutionQueued') -and $qa.Contains('war.ResolutionPending'))
Pass 'qa_requires_matching_native_witness_without_granting_authority' ($qa.Contains('score.ObserveForeignWarNativeWitness(') -and $qa.Contains('ForeignWarNativeWitnessStatus.WeakTimestampMatchNotProof') -and $qa.Contains('ForeignConflictIdentityStatus.RecordedActive'))
Pass 'qa_queues_existing_bellum_treaty' ($qa.Contains('treaties.TryQueueAiParley(war, forced: true, preferWhitePeace: true,'))
Pass 'qa_no_direct_native_actions_or_record_modifications' (!$qa.Contains('MakePeaceAction.') -and !$qa.Contains('SetState(') -and !$qa.Contains('EndParley(') -and !$qa.Contains('ApplyTreaty(') -and !$qa.Contains('Score ='))
Pass 'qa_exposes_result_and_logs_instance' ($qa.Contains('QA_BELLUM_PARLEY_QUEUED') -and $qa.Contains('BELLUM_QA_TREATY_WHITE_PEACE') -and $qa.Contains('instance={instanceId}'))
Pass 'qa_runner_uses_own_release_gate' ($runner.Contains('BELLUM_CR_DIPLOMACY_GATE_PASS version=1.4.12.19'))
Write-Output 'TREATY_QA_CONSOLE_PASS 15; QA command contract only; Windows build/game NOT_RUN'
