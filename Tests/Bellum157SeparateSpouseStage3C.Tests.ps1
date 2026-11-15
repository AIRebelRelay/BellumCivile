# Stage 3C regression contract for the complete SeparateSpouse/birth-occupation/pregnancy-guard subsystem.
# Source assertions precede production edits. Native Harmony and behavior cases run in harness.
$ErrorActionPreference='Stop'
$root=Split-Path -Parent $PSScriptRoot
$patch=[IO.File]::ReadAllText((Join-Path $root 'Patches/SeparateSpouseHouseholdPatch.cs'))
$house=[IO.File]::ReadAllText((Join-Path $root 'HouseholdMembership.cs'))
$source=[IO.File]::ReadAllText((Join-Path $root 'Tests/SpouseHousehold.Tests.ps1'))
$program=[IO.File]::ReadAllText((Join-Path $root 'Tests/SuccessionEngineHarness/Program.cs'))
$guard=[IO.File]::ReadAllText((Join-Path $root 'Tests/SuccessionEngineHarness/PregnancyVisitGuardTests.cs'))
$occupation=[IO.File]::ReadAllText((Join-Path $root 'Tests/SuccessionEngineHarness/SeparateSpouseBirthOccupationTests.cs'))
function Check([bool]$pass,[string]$id) { if (!$pass) { throw "BELLUM157_SPOUSE FAIL case=$id" }; Write-Output "PASS BELLUM157_SPOUSE case=$id" }
Check ($patch.Contains('[HarmonyPatch(typeof(HeroCreator), nameof(HeroCreator.DeliverOffSpring))]')) 'birth_native_entrypoint_preserved'
Check ($patch.Contains('[HarmonyPatch(typeof(PregnancyCampaignBehavior), "CheckAreNearby")]')) 'visit_native_entrypoint_preserved'
Check ($patch.Contains('codes.Count(c => c.Calls(clanGetter)) != 2')) 'two_birth_clan_anchor_guard'
Check ($patch.Contains('codes.Count(c => c.Calls(occupationGetter)) != 2')) 'two_birth_occupation_anchor_guard'
Check ($patch.Contains('bool clan = code.Calls(clanGetter);')) 'birth_rewrites_clan_and_occupation'
Check ($patch.Contains('clan ? nameof(ResolveBirthClan) : nameof(ResolveBirthOccupation)')) 'right_resolver_per_native_call'
Check ($patch.Contains('mother.labels.AddRange(code.labels);') -and $patch.Contains('mother.blocks.AddRange(code.blocks);')) 'il_branch_exception_metadata_preserved'
Check ($patch.Contains('mother?.Clan != null && father?.Clan != null && mother.Clan != father.Clan')) 'different_household_maternal_clan_rule_preserved'
Check ($patch.Contains('Occupation occupation = nativeParent.Occupation;')) 'native_occupation_read'
Check ($patch.Contains('if (occupation != Occupation.Wanderer) return occupation;')) 'non_wanderer_unmodified'
Check ($patch.Contains('player != null && (mother == player || father == player) ? player : father')) 'symmetric_player_parent_handling'
Check ($patch.Contains('return HouseholdMembership.Supports(household) ? Occupation.Lord : occupation;')) 'only_eligible_household_promotes_to_lord'
Check ($house.Contains('internal static bool Supports(Clan clan) => clan != null && !clan.IsEliminated')) 'real_upstream_membership_helper_not_stub'
Check ($house.Contains('clan.Leader?.IsAlive == true && !clan.IsBanditFaction')) 'native_household_eligibility_guards'
Check ($house.Contains('internal static bool IsFamily(Hero hero)')) 'future_lordship_family_semantics_preserved'
Check ($patch.Contains('if (hero.Clan == null)') -and $patch.Contains('ReportClanlessVisit(hero, spouse);')) 'clanless_pregnancy_guard'
Check ($patch.Contains('ConditionalWeakTable<Campaign, HashSet<Hero>>')) 'once_per_campaign_diagnostic'
Check ($patch.Contains('[SPOUSE-VISIT] skipped=missing_pregnancy_clan;')) 'diagnostic_label'
Check ($patch.Contains('BellumCivileLogger.Flush();')) 'diagnostic_flush_even_without_debug'
Check ($patch.Contains('float roll = !captive && !hostile && !together ? MBRandom.RandomFloat : 1f;')) 'visitation_randomness_unchanged'
Check ($patch.Contains('!captive && !hostile && (together || roll < 0.2f);')) 'native_visit_probability_captivity_hostility'
Check ($patch.Contains('if (party?.AttachedTo != null) party = party.AttachedTo;')) 'attached_party_location_preserved'
Check ($source.Contains("Production visit rules do not privilege player sex")) 'existing_source_test_understands_birth_exception'
Check ($program.Contains('else if (args.Contains("--separate-spouse-157"))')) 'focused_harness_route_exists'
Check ($program.Contains('PregnancyVisitGuardTests.Run(Check);')) 'native_clanless_pregnancy_regression'
Check ($program.Contains('SeparateSpouseBirthOccupationTests.Run(Check);')) 'birth_occupation_behavior_regression'
Check ($program.Contains('TestHouseholdFoundation();')) 'existing_birth_foundation_retained'
Check ($guard.Contains('The real native visit caller short-circuits before location checks')) 'native_refresh_spouse_visit_test'
Check ($guard.Contains('Daily retries produce only one diagnostic')) 'diagnostic_deduplication_test'
Check ($guard.Contains('The guard does not require an unrelated clan reference on the other spouse')) 'only_mother_clan_required'
Check ($occupation.Contains('ResolveBirthOccupation')) 'native_birth_occupation_behavior_exercised'
'BELLUM157_SPOUSE SOURCE_PASS; native_game_harmony_runtime_and_save=NOT_RUN'
