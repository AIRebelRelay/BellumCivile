# Bannerlord 1.5.7 UI realm-name compatibility regression contract.
# Source-level tests only. Build and in-game UI/save checks must follow.
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$files = @{
    Map = 'UI/Map/WarScoreMapWidgetVM.cs'
    Hierarchy = 'UI/VanillaTabs/Kingdoms/Hierarchy/KingdomHierarchyTabVM.cs'
    Parley = 'UI/Parley/PeaceParleyVM.cs'
}
$source = @{}
foreach ($entry in $files.GetEnumerator()) {
    $path = Join-Path $root $entry.Value
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "BELLUM157_UI_FORMAL FAIL missing_source=$path"
    }
    $source[$entry.Key] = [System.IO.File]::ReadAllText($path)
}
function Assert-Has([string]$body, [string]$fragment, [string]$name) {
    if (-not $body.Contains($fragment)) {
        throw "BELLUM157_UI_FORMAL FAIL $name"
    }
    Write-Output "PASS BELLUM157_UI_FORMAL $name"
}
function Assert-NotHas([string]$body, [string]$fragment, [string]$name) {
    if ($body.Contains($fragment)) {
        throw "BELLUM157_UI_FORMAL FAIL $name"
    }
    Write-Output "PASS BELLUM157_UI_FORMAL $name"
}

Assert-Has $source.Map 'TextObject encyclopediaName = kingdom?.FormalName;' 'war_map_formal_source'
Assert-Has $source.Map '!string.IsNullOrWhiteSpace(encyclopediaName.ToString())' 'war_map_empty_formal_guard_retained'
Assert-Has $source.Map ': kingdom?.Name ?? new TextObject("{=BC_MapWarScore_UnknownRealm}Unknown realm");' 'war_map_native_fallback_retained'
Assert-Has $source.Map 'status.SetTextVariable("REALM_NAME", realmName);' 'war_map_war_status_binding_retained'
Assert-NotHas $source.Map 'kingdom?.EncyclopediaTitle' 'war_map_old_member_removed'

Assert-Has $source.Hierarchy 'string nativeTitle = isHistorical ? null : kingdom?.FormalName?.ToString();' 'hierarchy_formal_source'
Assert-Has $source.Hierarchy 'if (!string.IsNullOrWhiteSpace(nativeTitle))' 'hierarchy_formal_guard_retained'
Assert-Has $source.Hierarchy ': FeudalTitleDisplayHelper.FormatTitleName(root, kingdom?.RulingClan);' 'hierarchy_feudal_fallback_retained'
Assert-Has $source.Hierarchy '? new TextObject("{=BC_Hierarchy_NoSovereignTitle}No sovereign title").ToString()' 'hierarchy_null_title_fallback_retained'
Assert-NotHas $source.Hierarchy 'kingdom?.EncyclopediaTitle' 'hierarchy_old_member_removed'

Assert-Has $source.Parley 'string encyclopediaTitle = kingdom.FormalName?.ToString();' 'parley_formal_source'
Assert-Has $source.Parley 'if (kingdom == null)' 'parley_null_realm_guard_retained'
Assert-Has $source.Parley 'FeudalTitleDisplayHelper.FormatTitleName(sovereignTitle, kingdom.RulingClan)' 'parley_feudal_title_priority_retained'
Assert-Has $source.Parley 'return !string.IsNullOrWhiteSpace(encyclopediaTitle)' 'parley_formal_guard_retained'
Assert-Has $source.Parley ': kingdom.Name?.ToString() ?? string.Empty;' 'parley_native_name_fallback_retained'
Assert-Has $source.Parley 'private static IEnumerable<TreatyCouncilMemberEvaluation> OrderCouncilMembers(' 'parley_vote_roster_neighbor_retained'
Assert-NotHas $source.Parley 'kingdom.EncyclopediaTitle' 'parley_old_member_removed'
Write-Output 'BELLUM157_UI_FORMAL SOURCE_PASS; compile_and_gameplay=NOT_RUN'
