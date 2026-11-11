$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
function Read([string]$name) { Get-Content -Raw -LiteralPath (Join-Path $root $name) }
function Check([bool]$passed, [string]$description) {
    if (-not $passed) { throw "FAIL: $description" }
    Write-Output "PASS: $description"
}
$fixture = Read 'Tests/SuccessionEngineHarness/EncyclopediaFamilyTests.cs'
$compat = Read 'Tests/SuccessionEngineHarness/EncyclopediaFamilyCompatibilityTests.cs'
$tree = Read 'Tests/SuccessionEngineHarness/FamilyTreeRefreshCompatibilityTests.cs'
$startup = Read 'Tests/SuccessionEngineHarness/CampaignUiStartupProbe.cs'
$program = Read 'Tests/SuccessionEngineHarness/Program.cs'
$project = Read 'Tests/SuccessionEngineHarness/SuccessionEngineHarness.csproj'
Check ($fixture.Contains('internal static class EncyclopediaFamilyTests') -and
       $fixture.Contains('EncyclopediaFamilyCompatibilityTests()') -and
       $fixture.Contains('CheckLayout(check, game)')) 'Hero family harness runs compatible registry and actual native prefab layout checks.'
Check ($fixture.Contains('All-unknown ancestry hides the headings and the entire ancestry row') -and
       $fixture.Contains('Current and former husbands use their correct relationship labels') -and
       $fixture.Contains('Family portraits retain native ')) 'Hero family positive and neighboring portrait/navigation behavior are covered.'
Check ($fixture.Contains('Family follows Bellum titles and precedes Friends/Enemies regardless of patch order') -and
       $fixture.Contains('Reused native portrait supports encyclopedia links and hero tooltips on this game version')) 'Family ordering and native links are tested without replacing existing titles/claims.'
Check ($fixture.Contains('Open hero pages subscribe to family layout ownership changes') -and
       $fixture.Contains('Closing the page unsubscribes its family completion handler')) 'Already open family pages refresh and release events safely.'
Check ($compat.Contains('internal sealed class EncyclopediaFamilyCompatibilityTests : IDisposable') -and
       $compat.Contains('All six extensions from the actual supported Family Tree DLL are tested') -and
       $compat.Contains('An actual enabled foreign UIExtender registration restores the shared layout')) 'Real Family Tree and UIExtender supported and fallback paths are tested.'
Check ($compat.Contains('Actual Extender Perks use normal spacing after UIExtender finalization') -and
       $compat.Contains('Unfamiliar Perks layouts are untouched')) 'Perks extension regression is included; unknown layouts are left alone.'
Check ($compat.Contains('OtherMovieEditor') -and
       $compat.Contains('EncyclopediaClanPage') -and
       -not $compat.Contains('EncyclopediaClanHouseholdPrefabPatch')) 'Other-movie negative test does not import missing Clan Household implementation.'
Check ($tree.Contains('internal static class FamilyTreeRefreshCompatibilityTests') -and
       $tree.Contains('Only the exact blocking prefix registration is removed') -and
       $tree.Contains('A prefix already modified by another compatibility patch is left intact') -and
       $tree.Contains('A different Family Tree build with the same type name is left untouched')) 'Family Tree Harmony owner isolation and unknown-version protection are covered.'
Check ($tree.Contains('Other owners, Family Tree postfixes and existing refresh transpilers remain installed') -and
       $tree.Contains('Repeated compatibility setup does not alter other registrations')) 'Neighbor Harmony registrations and repeated startup remain intact.'
foreach ($route in @('--encyclopedia-family', '--encyclopedia-family-addon',
        '--encyclopedia-family-registry', '--encyclopedia-extender-addon', '--family-tree-refresh')) {
    Check ($program.Contains('args.Contains("' + $route + '")')) "Compiled harness has explicit route $route."
}
Check ($program.Contains('EncyclopediaFamilyTests.Run(Check, _game);') -and
       $program.Contains('EncyclopediaFamilyCompatibilityTests.RegistryProbe(Check, _game);') -and
       $program.Contains('FamilyTreeRefreshCompatibilityTests.Run(Check, original, working);')) 'Family routes invoke the behavior fixtures, not only static assertions.'
Check ($program.Contains('EncyclopediaInheritanceLayoutTests.Run(Check);') -and
       $program.Contains('FiefRedistributionTests.Run(Check);') -and
       $program.Contains('RealmNameTests.Run(Check);') -and
       $program.Contains('CampaignUiStartupProbe.Run(Check);')) 'Existing harness routes remain available.'
Check ($project.Contains('<Reference Include="Bannerlord.UIExtenderEx"') -and
       $project.Contains('<Reference Include="TaleWorlds.CampaignSystem.ViewModelCollection"') -and
       $project.Contains('<ProjectReference Include="../../BellumCivile.csproj" />')) 'Only necessary external test DLL references are added; production project still referenced.'
Check ($startup.Contains('Family mixin registers through the real UIExtender refresh transpiler before game texts exist') -and
       $startup.Contains('Optional Family Tree refresh inspection does not initialize native game texts') -and
       $startup.Contains('Startup probe begins before native game texts are initialized')) 'Startup path protects early GameTexts and Family Tree adapter.'
Check (-not $startup.Contains('LordshipAppointmentPatches') -and
       -not $startup.Contains('LordshipMapBannerPatch') -and
       -not $startup.Contains('EncyclopediaClanPageVM') -and
       -not $startup.Contains('HouseholdOccupationDisplayPatch')) 'Test-only startup probe does not import missing Lordship, retainer or Clan Household dependencies.'
Check ($startup.Contains('Deferred hostage history patch installs successfully') -and
       $startup.Contains('Startup patches leave CampaignUIHelper usable after game-text initialization')) 'Original hostage startup and CampaignUIHelper checks remain.'
'P0-14A source regression contract passed; PowerShell and compiled/net472/game harness remain unexecuted.'
