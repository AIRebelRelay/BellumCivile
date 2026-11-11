$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$source = Get-Content -Raw (Join-Path $root 'Behaviors/DynasticHeirBehavior.cs')
function Check([bool]$ok, [string]$why) {
    if (-not $ok) { throw "FAIL: $why" }
    Write-Output "PASS: $why"
}
$start = $source.IndexOf('private void OnRulingClanChanged(', [StringComparison]::Ordinal)
if ($start -lt 0) { throw 'RulingClanChanged handler missing' }
$end = $source.IndexOf([Environment]::NewLine + '        private ', $start + 20, [StringComparison]::Ordinal)
if ($end -lt 0) { $end = $source.IndexOf([char]10 + '        private ', $start + 20, [StringComparison]::Ordinal) }
if ($end -lt 0) { throw 'RulingClanChanged handler boundary missing' }
$method = $source.Substring($start, $end - $start)
Check ($method.Contains('OnRulingClanChanged(Kingdom kingdom, Clan oldRulingClan)')) 'Callback explicitly treats event argument as displaced house.'
Check ($method.Contains('if (kingdom == null) return;') -and $method.Contains('Clan newRulingClan = kingdom.RulingClan;')) 'Incoming ruler is read from live Kingdom after null guard.'
Check ($method.IndexOf('Clan newRulingClan = kingdom.RulingClan;') -lt $method.IndexOf('_pendingUsurperKingdoms.Contains(')) 'Live Crown snapshot occurs before claimant state reconciliation.'
Check ($method.Contains('installedDynasticCandidate?.Clan == newRulingClan')) 'Valid installed dynastic house is compared with incoming, not displaced, clan.'
Check ($method.Contains('reigning_clan={newRulingClan?.StringId ?? "none"}')) 'Displaced-dynasty diagnostic identifies actual reigning clan.'
Check (-not $method.Contains('installedDynasticCandidate?.Clan == oldRulingClan')) 'Historical callback clan never drives heir identity.'
Check ($source.Contains('CampaignEvents.RulingClanChanged.AddNonSerializedListener(this, OnRulingClanChanged);')) 'Existing event ownership and registration preserved.'
Check ($method.Contains('_pendingUsurperKingdoms.Remove(kingdom.StringId);') -and
       $method.Contains('_usurperKingdoms.Remove(kingdom.StringId);')) 'Usurper state changes retain existing logic.'
Check (([regex]::Matches($method, [regex]::Escape('RecalculateHeirForKingdom(kingdom);'))).Count -eq 3) 'Heir recalculation remains on all three existing branches.'
Check ($method.Contains('ResolveDynasticSuccessionCandidate(kingdom, trackedHeir)') -and
       $method.Contains('TraceDynasticSuccession(')) 'Candidate resolution and displaced-line reporting preserved.'
'P0-11B Dynastic callback source contracts passed; campaign runtime and old-save checks pending.'
