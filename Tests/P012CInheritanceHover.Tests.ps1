$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
function Read([string]$file) { Get-Content -LiteralPath (Join-Path $root $file) -Raw }
function Check([bool]$test, [string]$label) { if (-not $test) { throw "FAIL: $label" }; Write-Output "PASS: $label" }
$display = Read 'EstateInheritanceDisplay.cs'
$prefab = Read 'UI/EncyclopediaHeroFeudalTitlesPrefabExtension.cs'
[xml]$english = Read 'ModuleData/Languages/EN/strings.xml'
$xmlValue = [regex]::Match($prefab, '(?s)_document\.LoadXml\(@"(.*?)"\);').Groups[1].Value
if (-not $xmlValue) { throw 'Missing native inheritance XML content' }
[xml]$xml = $xmlValue
Check ($display.Contains('private enum AssetKind { Ordinary, CrownEstate, Sovereign }') -and
       $display.Contains('internal string Label => Kind == AssetKind.Sovereign ? SovereignTitle(Name)')) 'Structured asset kinds retain legal labels without parsing translated title names.'
Check ($display.Contains('private static StringPairItemVM HeroEntry(Asset asset, string context)') -and
       $display.Contains('new StringPairItemVM(asset.Name, string.Empty, new BasicTooltipViewModel(() => hint))')) 'Hero rows show full bare title names and native hint.'
Check ($display.Contains('new TextObject("{=BC_EstatePreview_HeroHint}{KIND} - {SOURCE}")') -and
       $display.Contains('BC_EstatePreview_CrownEstateKind') -and
       $display.Contains('BC_EstatePreview_SovereignKind')) 'Hover distinguishes ordinary, Crown estate and sovereign origins.'
Check ($display.Contains('List<Asset> assets = GetAssets(record, share, pending)') -and
       $display.Contains('foreach (Asset asset in assets)') -and
       $display.Contains('entries.Add(HeroEntry(asset, context))')) 'Hero entries include every asset rather than truncating the inheritance list.'
Check ($display.Contains('group.SelectMany(share => GetAssets(record, share, pending)).Select(asset => asset.Label).ToList()') -and
       $display.Contains('assets.Take(TooltipAssetLimit)') -and $display.Contains('assets.Count - TooltipAssetLimit')) 'Clan tooltip retains legal suffixes and original five-asset summary cap.'
Check ($display.Contains('share.DeliveredSovereignTransfers, share.SupersededTitles, true') -and
       $display.Contains('shownBaronySettlements.Add(title.CapitalSettlementId)') -and
       $display.Contains('if (shownBaronySettlements.Contains(id))')) 'Pending sovereign transfers and barony/fief dedup remain intact.'
Check ($display.Contains('BC_EstatePreview_SettlementPending') -and
       !$display.Contains('DailyTick') -and !$display.Contains('HourlyTick') -and !$display.Contains('RegisterEvents(')) 'Pending fallback remains read-only and no scheduling added.'
$grid = $xml.SelectSingleNode("//GridWidget[@DataSource='{BellumInheritance}']")
Check ($grid -ne $null -and $grid.GetAttribute('ColumnCount') -eq '2' -and
       $grid.GetAttribute('DefaultCellHeight') -eq '30' -and $grid.GetAttribute('UseDynamicCellHeight') -eq 'true') 'Inheritance uses compact two-column dynamic-height grid.'
Check ($xml.SelectNodes("//GridWidget[@DataSource='{BellumInheritance}']//TextWidget[@Text='@Definition']").Count -eq 1 -and
       $xml.SelectNodes("//GridWidget[@DataSource='{BellumInheritance}']//TextWidget[@Text='@Value']").Count -eq 0 -and
       $xml.SelectNodes("//GridWidget[@DataSource='{BellumInheritance}']//HintWidget[@DataSource='{Hint}']").Count -eq 1) 'Only title text is visible; native hover covers name text.'
Check ($xml.SelectNodes("//*[@Id='BellumTitlesDivider']").Count -eq 1 -and
       $xml.SelectNodes("//*[@Id='BellumClaimsDivider']").Count -eq 1 -and
       $xml.SelectNodes("//*[@Id='BellumInheritanceDivider']").Count -eq 1 -and
       $xml.SelectNodes("//*[@Id='BellumFamilySection']").Count -eq 1 -and
       $xml.SelectNodes("//*[@Id='AlliesDivider']").Count -eq 1) 'Existing titles, claims, family and Allies sections are preserved.'
Check ($prefab.Contains('EncyclopediaHeroFamilyPrefabPatch.InsertSection(_document);')) 'P0-12B family insertion remains intact.'
foreach ($pair in @(
    @('BC_EstatePreview_CrownEstateKind','Crown estate'),
    @('BC_EstatePreview_SovereignKind','Sovereign succession'),
    @('BC_EstatePreview_HeroHint','{KIND} - {SOURCE}')
)) {
    $matches = @($english.SelectNodes("//string[@id='$($pair[0])']"))
    Check ($matches.Count -eq 1 -and $matches[0].text -ceq $pair[1]) "English provenance key $($pair[0]) is unique and matches upstream."
}
'P0-12C source contract passed. Compiled tests and live rendering are deferred.'
