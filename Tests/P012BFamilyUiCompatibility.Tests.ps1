$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
function Read([string]$path) { Get-Content -Raw (Join-Path $root $path) }
function Check([bool]$ok, [string]$why) { if (!$ok) { throw "FAIL: $why" }; Write-Output "PASS: $why" }
$extension = Read 'UI/EncyclopediaHeroFeudalTitlesPrefabExtension.cs'
$mixin = Read 'UI/EncyclopediaHeroFamilyMixin.cs'
$prefab = Read 'UI/EncyclopediaHeroFamilyPrefabPatch.cs'
$policy = Read 'UI/EncyclopediaFamilyLayoutCompatibility.cs'
$final = Read 'UI/EncyclopediaFamilyPrefabFinalizationPatch.cs'
$divider = Read 'UI/EncyclopediaNativeFamilyDividerPatch.cs'
$tree = Read 'Patches/FamilyTreeRefreshCompatibility.cs'
$module = Read 'SubModule.cs'
$model = Read 'UI/EncyclopediaHeroFamilyVM.cs'
Check ($extension.Contains('EncyclopediaHeroFamilyPrefabPatch.InsertSection(_document);')) 'Existing hero titles/claims/inheritance extension appends Bellum Family before Allies.'
Check ($extension.Contains('BellumTitlesDivider') -and $extension.Contains('BellumClaimsDivider') -and
       $extension.Contains('BellumInheritanceDivider') -and $extension.Contains('AlliesDivider')) 'Prior hero encyclopedia sections remain in the native replacement prefab.'
Check ($mixin.Contains('[ViewModelMixin("RefreshValues", true)]') -and
       $mixin.Contains('BaseViewModelMixin<EncyclopediaHeroPageVM>') -and $mixin.Contains('BellumFamily')) 'Family mixin targets the hero page only.'
Check ($mixin.Contains('IsLoadingOver) && ViewModel.IsLoadingOver') -and
       $mixin.Contains('ViewModel.IsInformationHidden || !BellumUseFamilyLayout')) 'Hero family refresh is gated until page ready and respects hidden/fallback state.'
Check ($mixin.Contains('EncyclopediaFamilyLayoutCompatibility.Changed += OnLayoutChanged;') -and
       $mixin.Contains('EncyclopediaFamilyLayoutCompatibility.Changed -= OnLayoutChanged;') -and
       $mixin.Contains('ViewModel.PropertyChangedWithBoolValue -= OnPageChanged;') -and
       $mixin.Contains('BellumFamily.OnFinalize();')) 'Mixin unsubscribes and finalizes, avoiding stale family refresh.'
Check ($prefab.Contains('[PrefabExtension("EncyclopediaHeroPage", null)]') -and
       $prefab.Contains('ConditionalWeakTable<XmlDocument, List<XmlElement>> HiddenNativeNodes')) 'Family patch is hero-only and tracks original nodes by document.'
Check ($prefab.Contains('if (node.GetAttribute("IsHidden") == "true") node.RemoveAttribute("IsHidden");') -and
       $prefab.Contains('EncyclopediaFamilyLayoutCompatibility.Refresh(document);') -and
       $prefab.Contains('if (!EncyclopediaFamilyLayoutCompatibility.Enabled) return;')) 'Foreign editor fallback restores native nodes before skipping Bellum layout.'
Check ($prefab.Contains('FamilyGrid') -and $prefab.Contains('FamilyDivider') -and
       $prefab.Contains('NavigationScopeTargeter') -and $prefab.Contains('node.SetAttribute("IsHidden", "true");')) 'Family override hides rather than deletes native anchors.'
Check ($prefab.Contains('document.SelectSingleNode("//*[@Id=' + "'BellumFamilySection'" + ']")') -and
       $prefab.Contains('allies.ParentNode.InsertBefore(section, allies);')) 'Bellum family section is idempotent and before Allies.'
Check ($prefab.Contains('AdjustedPerksDividers') -and $prefab.Contains('PerksColumns') -and
       $prefab.Contains('perksDividers.Add(node);')) 'Latest Perks/Encyclopedia Extender spacing repair preserved.'
Check ($policy.Contains('EncyclopediaFamilyPrefabFinalizationPatch.Supported') -and
       $policy.Contains('!_nativeLayoutAvailable') -and
       $policy.Contains('another family editor is active:')) 'Policy refuses unsupported hook, missing native anchors and foreign family editors.'
Check ($policy.Contains('typeof(CustomPatch<XmlDocument>).IsAssignableFrom(type)') -and
       $policy.Contains('!enabled.Contains(type)') -and
       $policy.Contains('IsComposable(type, extensions)')) 'Unknown document-wide editors fail safe; disabled and simple composable editors are handled separately.'
Check ($policy.Contains('PatchProcessor.GetOriginalInstructions(getter)') -and
       $policy.Contains('GetAllRuntimes') -and
       !$policy.Contains('Activator.CreateInstance')) 'Compatibility identifies registrations without executing foreign constructors.'
Check ($final.Contains('internal static bool Supported { get; private set; } = true;') -and
       $final.Contains('private static bool Prepare()') -and
       $final.Contains('FindTarget(') -and
       $final.Contains('ApplyPatches') -and $final.Contains('ProcessMovie')) 'Prefab finalizer verifies installed UIExtender method shape before patching.'
Check ($final.Contains('if (movieName == "EncyclopediaHeroPage")') -and
       !$final.Contains('EncyclopediaClanHouseholdPrefabPatch') -and
       !$final.Contains('EncyclopediaClanPage')) 'Finalizer touches only Hero Family; unported clan household is excluded.'
Check ($divider.Contains('if (__instance.Id != "FamilyDivider" || !EncyclopediaFamilyLayoutCompatibility.Enabled) return true;') -and
       !$divider.Contains('MembersDivider') -and
       !$divider.Contains('EncyclopediaClanHousehold')) 'Native divider patch is disabled for all other widgets, including clan members.'
Check ($tree.Contains('Bannerlord.FamilyTree.1.4.8') -and $tree.Contains('new Version(1, 4, 8, 0)') -and
       $tree.Contains('MatchesToggleBody(toggle, PatchProcessor.GetOriginalInstructions(prefix))')) 'Only known Family Tree 1.4.8 IL signature can be adapted.'
Check ($tree.Contains('!IsKnownPrefix(prefix) || HasOwnPatches(prefix)') -and
       $tree.Contains('harmony.Unpatch(refresh, prefix);') -and
       !$tree.Contains('UnpatchAll')) 'Foreign Harmony patch is removed only if exact and unmodified; other owners remain.'
Check ($module.Contains('Patches.FamilyTreeRefreshCompatibility.TryApply(_harmony);') -and
       $module.Contains('Patches.ArtemRealmNameCompatibility.TryApply(_harmony);') -and
       $module.Contains('Patches.PocBannerCompatibility.TryApply(_harmony);') -and
       $module.Contains('Patches.BannerPersistenceCompatibility.Initialize();')) 'Optional Family Tree adapter joins existing module startup without displacing other integration.'
Check ($module.Contains('_uiExtender.Register(Assembly.GetExecutingAssembly());') -and
       $module.Contains('_uiExtender.Enable();') -and
       $module.Contains('ShouldSkipOptionalPatch(type)')) 'Existing UIExtender registration and optional Harmony startup guards remain.'
Check ($model.Contains('EncyclopediaHeroFamilyVM : ViewModel') -and
       $model.Contains('EncyclopediaFamilyPortraitVM : HeroVM')) 'P0-12A hero family ViewModels stay intact.'
'P0-12B source contracts passed. Compiled harness, UIExtender ABI and Bannerlord live tests still PENDING.'
