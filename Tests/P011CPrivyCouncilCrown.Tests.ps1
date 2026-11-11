$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$source = Get-Content -Raw (Join-Path $root 'Behaviors/PrivyCouncilBehavior.cs')
function Check([bool]$condition, [string]$message) {
    if (-not $condition) { throw "FAIL: $message" }
    Write-Output "PASS: $message"
}
$start = $source.IndexOf('private void OnRulingClanChanged(', [StringComparison]::Ordinal)
$end = $source.IndexOf('private void ApplyMarshalPressures(', [StringComparison]::Ordinal)
if ($start -lt 0 -or $end -le $start) { throw 'Council Crown callback boundaries missing.' }
$method = $source.Substring($start, $end - $start)
Check ($method.Contains('OnRulingClanChanged(Kingdom kingdom, Clan oldRulingClan)')) 'Callback explicitly identifies the displaced ruling clan.'
Check ($method.Contains('if (!IsEligiblePermanentRealm(kingdom))') -and
       $method.Contains('Clan newRulingClan = kingdom.RulingClan;')) 'Valid permanent realm is required before reading current ruling clan.'
Check ($method.IndexOf('Clan newRulingClan = kingdom.RulingClan;') -gt $method.IndexOf('if (!IsEligiblePermanentRealm(kingdom))') -and
       $method.IndexOf('Clan newRulingClan = kingdom.RulingClan;') -lt $method.IndexOf('EnsureCouncilForKingdom(kingdom);')) 'Current Crown is captured before council reconciliation.'
Check ($method.Contains('record.HolderClanId == newRulingClan?.StringId')) 'Only incoming house office-holders are vacated.'
Check (-not $method.Contains('record.HolderClanId == oldRulingClan?.StringId')) 'Displaced clan cannot be mistaken for newly crowned house.'
Check ($method.Contains('foreach (PrivyCouncilOfficeRecord record in GetOfficeRecords(kingdom))')) 'Each incumbent office is inspected against current Crown.'
Check ($method.Contains('record.Vacate(currentDay);') -and $method.Contains('InvalidateRuntimeCache();')) 'Existing vacancy timing and cache invalidation remain intact.'
Check ($source.Contains('CampaignEvents.RulingClanChanged.AddNonSerializedListener(this, OnRulingClanChanged);')) 'Original event registration retained.'
Check ($source.Contains('EnsureCouncilForKingdom(kingdom);') -and
       $source.Contains('GetOfficeHolder(kingdom, PrivyCouncilOffice.Spymaster)')) 'Council initialization and existing office consumers remain available.'
'P0-11C Council incoming Crown source checks passed; actual Windows/game tests deferred.'
