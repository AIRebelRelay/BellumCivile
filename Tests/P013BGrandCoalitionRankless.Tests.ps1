$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
function Read([string]$name) { Get-Content -Raw -LiteralPath (Join-Path $root $name) }
function Check([bool]$condition, [string]$reason) {
    if (-not $condition) { throw "FAIL: $reason" }
    "PASS: $reason"
}
$helper = Read 'DynamicKingdomTitleNameHelper.cs'
$ideology = Read 'Behaviors/IdeologyBehavior.cs'
$faction = Read 'FactionObject.cs'
$tests = Read 'Tests/SuccessionEngineHarness/RealmNameTests.cs'
$program = Read 'Tests/SuccessionEngineHarness/Program.cs'
Check ($helper.Contains('internal static TextObject GetRanklessNameText(Kingdom kingdom)')) 'New helper has separate internal naming API, no changed global realm-name semantics.'
Check ($helper.Contains('if (kingdom == null)') -and
       $helper.Contains('return TextObject.GetEmpty();')) 'Null kingdom resolves to safe empty TextObject.'
Check ($helper.Contains('TryResolveDisplayText(kingdom, KingdomDisplayNameField.InformalName, out TextObject root)') -and
       $helper.Contains('return root;')) 'Configured Realm Identity / Sovereign mode returns localized name root.'
Check ($helper.Contains('TextObject nativeName = GetNativeNameText(kingdom);') -and
       $helper.Contains('RealmNameConfig.ResolveRootText(kingdom.StringId, nativeName?.ToString())') -and
       $helper.Contains('IndependentKingdomProfileHelper.ResolveFallbackNameRoot(nativeName)') -and
       $helper.Contains('?? nativeName ?? TextObject.GetEmpty();')) 'Native mode avoids informal demonyms and never strips custom names heuristically.'
Check ($ideology.Contains('string coalitionName = $"{DynamicKingdomTitleNameHelper.GetRanklessNameText(kingdom)} {sourceFactionName} Grand Coalition";') -and
       $ideology.Contains('new FactionObject(coalitionName, kingdom, coalitionLeader, blueprint)')) 'New Grand Coalition uses rank-free realm without altering the constructor or formation.'
Check ($faction.Contains('TextObject realmName = DynamicKingdomTitleNameHelper.GetRanklessNameText(ParentKingdom);') -and
       ([regex]::Matches($faction, 'SetTextVariable\("KINGDOM_NAME", realmName\)')).Count -eq 2) 'Both saved typed and legacy Grand Coalition displays use the same rank-free name.'
Check ($faction.Contains('if (!_hasGrandCoalitionSourceIdeology)') -and
       $faction.Contains('GetIdeologyDisplayName(_grandCoalitionSourceIdeology, ParentKingdom)') -and
       $faction.Contains('IsLegacyGrandCoalitionName(string name)')) 'Old saved coalition metadata, ideology names and legacy detection remain.'
Check ($tests.Contains('void AssertCoalitionNames(string root, string context)') -and
       $tests.Contains('FactionType.Nobility, FactionType.Glory, FactionType.Liberty') -and
       $tests.Contains('Old ranked realm Grand Coalition')) 'Behavioral harness covers every ideology plus untagged saved coalition.'
Check ($tests.Contains('AssertCoalitionNames("Vlandia", "Identity mode")') -and
       $tests.Contains('AssertCoalitionNames("Morcomb", "Sovereign mode")') -and
       $tests.Contains('AssertCoalitionNames("New Morcomb", "Title rename")') -and
       $tests.Contains('AssertCoalitionNames("Calradia", "Sovereign promotion")')) 'Rankless display changes with mode, rename and title rank.'
Check ($tests.Contains('AssertCoalitionNames("Vlandia", "Native mode avoids native informal demonyms")') -and
       $tests.Contains('AssertCoalitionNames("Valandie", "Translated identity and suffix rank format")') -and
       $tests.Contains('AssertCoalitionNames("Morcombie", "Translated sovereign territory")')) 'Native mode and translations preserve full names outside coalition.'
Check ($tests.Contains('AssertCoalitionNames("al-Asarin", "Immersive Aserai example")') -and
       $tests.Contains('Generated native realm names recover their stored root without string stripping') -and
       $tests.Contains('Rank-free fallback does not strip words from an explicit custom realm identity')) 'Culture formats, generated roots and explicit user names remain distinct.'
Check ($tests.Contains('GetRanklessNameText", new object[] { null }') -and
       $tests.Contains('New coalition records use the same rank-free root as their localized display')) 'Null guard and coalition creation IL route are covered in compiled regression.'
Check ($tests.Contains('Two thousand full/short reads reuse one sovereign lookup') -and
       $tests.Contains('Save writer retains native ') -and
       $tests.Contains('Artem route renders exactly one rank')) 'Existing realm-cache, save serialization and map label regressions stay enabled.'
Check ($program.Contains('--realm-names') -and
       $program.Contains('RealmNameTests.Run(Check);')) 'Existing isolated realm-name harness entrypoint remains callable.'
'P0-13B source contracts pass; runtime harness, compile and in-game UI remain PENDING.'
