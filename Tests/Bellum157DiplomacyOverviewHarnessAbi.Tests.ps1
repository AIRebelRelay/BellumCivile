# Stage 2A: 1.5.7 diplomacy overview harness ABI regression contract.
# Preserve the supported getters and every neighboring diplomacy scenario.
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$testPath = Join-Path $root 'Tests/SuccessionEngineHarness/DiplomacyOverviewTests.cs'
$runnerPath = Join-Path $root 'Tests/SuccessionEngineHarness/Program.cs'
$test = [IO.File]::ReadAllText($testPath)
$runner = [IO.File]::ReadAllText($runnerPath)
function Require([bool]$condition,[string]$name) {
    if (-not $condition) { throw "BELLUM157_OVERVIEW_ABI FAIL $name" }
    "PASS BELLUM157_OVERVIEW_ABI $name"
}
Require ($test.Contains('foreach (var property in new[] { "Name", "FormalName" })')) 'native_name_formalname_getters'
Require (!$test.Contains('EncyclopediaTitle')) 'obsolete_beta_getter_removed'
Require ($test.Contains('harmony.Patch(AccessTools.PropertyGetter(typeof(Kingdom), property), prefix: new HarmonyMethod(typeof(DiplomacyOverviewTests), "RealmName"));')) 'existing_harmony_test_hook_preserved'
Require ($test.Contains('finally { harmony.UnpatchAll(harmony.Id); }')) 'harmony_cleanup_preserved'
Require ($test.Contains('Overview alliance exclusion recognizes clientage from both realm perspectives')) 'clientage_overview_unchanged'
Require ($test.Contains('Former clientage no longer excludes a surviving ordinary alliance')) 'released_client_ordinary_alliance_visibility'
Require ($test.Contains('Overview war totals reverse with the column realm')) 'warscore_perspective_test_retained'
Require ($test.Contains('Shared map and overview war components reverse with viewing realm')) 'warscore_components_regression_retained'
Require ($test.Contains('Shared war tooltip handles missing record without fabricated score')) 'null_record_regression_retained'
Require ($test.Contains('Overview finalizes without a campaign or selected kingdom')) 'no_campaign_finalizer_retained'
Require ($runner.Contains('DiplomacyOverviewTests.Run(Check, _game);')) 'existing_caller_preserved'
Require ($runner.Contains('ClientVoluntaryReleaseTests.Run(Check);')) 'stage2_release_scenario_preserved'
'BELLUM157_OVERVIEW_ABI SOURCE_PASS; native_runtime_gameplay=NOT_RUN'
