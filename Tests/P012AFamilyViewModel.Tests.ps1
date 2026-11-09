$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$source = Get-Content -Raw (Join-Path $root 'UI/EncyclopediaHeroFamilyVM.cs')
[xml]$english = Get-Content -Raw (Join-Path $root 'ModuleData/Languages/EN/strings.xml')
function Check([bool]$ok, [string]$reason) {
    if (-not $ok) { throw "FAIL: $reason" }
    "PASS: $reason"
}
# Foundation stage: DATA ONLY. Family UI registration and Harmony compatibility are separate.
Check ($source.Contains('internal sealed class EncyclopediaHeroFamilyVM : ViewModel') -and
       $source.Contains('internal sealed class EncyclopediaFamilyPortraitVM : HeroVM')) 'Display-only family ViewModels exist.'
foreach ($group in @('Parents','Grandparents','Spouses','Children','Siblings','Grandchildren')) {
    Check ($source.Contains("MBBindingList<EncyclopediaFamilyPortraitVM> $group")) "Family has $group list."
}
Check ($source.Contains('Clear();') -and $source.Contains('IsVisible = hero != null && !informationHidden && canDisplay != null;') -and
       $source.Contains('if (IsVisible)')) 'No valid/visible hero means no family traversal.'
Check ($source.Contains('Known(Hero relative) => relative != null && relative != hero && canDisplay(relative);')) 'Unknown, self and hidden heroes are rejected.'
Check ($source.Contains('Add(Parents, father,') -and $source.Contains('Add(Parents, mother,')) 'Father and mother maintain stable slots.'
Check ($source.Contains('Add(Grandparents, Known(father?.Father)') -and
       $source.Contains('Add(Grandparents, Known(mother?.Mother)')) 'Both paternal and maternal grandparent slots are retained.'
Check ($source.Contains('if (Known(hero.Spouse)) Add(Spouses, hero.Spouse,') -and
       $source.Contains('hero.ExSpouses.Where(Known).Distinct().Where(h => h != hero.Spouse)')) 'Current spouse first, former spouses unique.'
Check ($source.Contains('hero.Father?.Children.AsEnumerable()') -and
       $source.Contains('hero.Mother?.Children.AsEnumerable()') -and
       $source.Contains('=> heroes.Distinct().OrderBy(h => h.BirthDay.ToDays).ThenBy(h => h.StringId, StringComparer.Ordinal)')) 'Both parental sibling lines, sorted and deduplicated.'
Check ($source.Contains('children.Where(Known).SelectMany(h => h.Children)') -and
       $source.Contains('!children.Contains(h)')) 'Grandchildren use eligible children and exclude child duplicates.'
Check ($source.Contains('IsVisible = IsVisible && (HasAncestors || HasHousehold || HasDescendantsOrSiblings);')) 'Completely empty/hidden family has no section.'
Check ($source.Contains('ChildrenColumns => HasSpouses ? 6 : 7') -and
       $source.Contains('SiblingsColumns => HasGrandchildren ? 3 : 7') -and
       $source.Contains('GrandchildrenColumns => HasSiblings ? 4 : 7') -and
       $source.Contains('GroupGap = 16')) 'Portrait width and paired-row spacing preserve 1.4.8 layout contract.'
Check ($source.Contains('foreach (var member in list) member.OnFinalize();') -and
       $source.Contains('list.Clear();')) 'Portrait ViewModels are finalized before lists are cleared.'
Check ($source.Contains('OnPropertyChanged(property);') -and $source.Contains('RefreshValues();')) 'ViewModel refresh publishes visibility and layout changes.'
$ids = @(
 'Header','Parents','Grandparents','Spouse','Children','Siblings','Grandchildren',
 'Father','Mother','PaternalGrandfather','PaternalGrandmother','MaternalGrandfather','MaternalGrandmother',
 'Wife','Husband','FormerWife','FormerHusband','Daughter','Son','Sister','Brother','Granddaughter','Grandson'
)
$strings = @($english.SelectNodes('//string[starts-with(@id, "BC_HeroFamily_")]'))
Check ($strings.Count -eq 23) 'Only 23 expected Bellum family localizations are added.'
foreach ($short in $ids) {
    $id = 'BC_HeroFamily_' + $short
    Check (@($strings | Where-Object { $_.GetAttribute('id') -eq $id }).Count -eq 1) "Localized family key $id appears exactly once."
    Check ($source.Contains('BC_HeroFamily_' + $short)) "Family ViewModel references $id."
}
Check (@($english.SelectNodes('//string[@id="BC_EstatePreview_Caveat"]')).Count -eq 1) 'Existing inheritance preview localization remains intact.'
'P0-12A source/localization contracts passed. Compiled ViewModel/harness and game rendering remain deferred.'
