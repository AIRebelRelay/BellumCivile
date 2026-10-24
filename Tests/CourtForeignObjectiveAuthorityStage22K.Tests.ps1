$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
function Read($name) { Get-Content -Raw -LiteralPath (Join-Path $root $name) }
function Check([bool]$ok, [string]$name) { if (!$ok) { throw "STAGE22K FAIL $name" }; "STAGE22K PASS $name" }
$war = Read 'CourtCampaignObjectiveSource.cs'
$peace = Read 'CourtPeaceObjectiveSource.cs'
$courtWar = Read 'Behaviors/CourtCampaignAgendas.cs'
$courtPeace = Read 'Behaviors/CourtPeaceAgendas.cs'
$revamp = Read 'Behaviors/WarPeaceRevampBehavior.cs'
$rules = Read 'CourtCampaignRules.cs'
$api = Read 'BellumIntegration.cs'
$record = Read 'IntegrationSnapshots.cs'
# These are CURRENT-HEAD authority constraints. Any decoupling requires a separately reviewed stage.
Check ($war.Contains('WarPeaceRevampBehavior.IsRevampEnabled()') -and
    $war.Contains('private static bool EligibleOwner(') -and
    $war.Contains('ValidPair(context.Realm, target)')) 'campaign_selectability_currently_revamp_gated'
Check ($peace.Contains('WarPeaceRevampBehavior.IsRevampEnabled()') -and
    $peace.Contains('EligibleWar(context.Realm, target, war)') -and
    $peace.Contains('candidate.ActionId == "seek_peace"')) 'peace_selectability_currently_revamp_gated'
Check ($revamp.Contains('return BellumCivileOptions.EnableWarPeaceLogicRevamp;')) 'revamp_is_global_mcm_switch'
Check ($courtWar.Contains('!CourtCampaignObjectiveSource.ValidPair(agenda.Realm, plan.Target)') -and
    $courtWar.Contains('FinishCampaignObjective(agenda, CourtObjectiveState.Cancelled')) 'existing_campaign_closes_on_revamp_disabled'
Check ($courtPeace.Contains('!CourtPeaceObjectiveSource.EligibleWar(agenda.Realm, plan.Target, plan.War)') -and
    $courtPeace.Contains('FinishPeaceObjective(agenda, CourtObjectiveState.Cancelled')) 'existing_peace_closes_on_revamp_disabled'
Check ($rules.Contains('initiated && authorized ? CourtObjectiveState.Succeeded') -and
    $courtWar.Contains('DeclareWarAction.DeclareWarDetail.CausedByKingdomDecision')) 'campaign_success_requires_native_decision_cause'
Check ($peace.Contains('"liberty_peace_initiative; acceptance_bonus=15; no_automatic_parley"') -and
    $courtPeace.Contains('Other interests and treaty terms still govern their votes; your own vote remains yours.')) 'peace_pressure_is_advisory_not_command'
Check ($courtPeace.Contains('agenda.State = CourtAgendaState.PursuingObjective;') -and
    $courtPeace.Contains('BellumCivileNotifications.Show(') -and
    $courtWar.Contains('BellumCivileNotifications.Show(')) 'public_court_notices_already_exist'
Check ($api.Contains('GetCourtAgendas(Kingdom realm)') -and
    $record.Contains('public bool ResultApplied { get; }')) 'read_only_saved_court_snapshot_exists'
Write-Host 'STAGE22K_NATIVE_SOURCE_CONTRACT_PASS (no DLL/game execution)'