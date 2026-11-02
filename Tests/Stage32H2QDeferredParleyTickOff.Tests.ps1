# Stage32H2Q — RED-first Native source regression contract.
# Real pwsh execution, .NET build and game timing tests are deferred to alpha QA.
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$path = Join-Path $root 'Behaviors/ForeignTreatyBehavior.cs'
$code = Get-Content -LiteralPath $path -Raw
function Check([bool]$pass, [string]$why) {
    if (-not $pass) { throw "STAGE32H2Q_RED $why" }
    Write-Host "STAGE32H2Q_CHECK $why"
}
function Part([string]$start, [string]$end) {
    $i = $code.IndexOf($start, [StringComparison]::Ordinal)
    if ($i -lt 0) { throw "STAGE32H2Q_RED missing $start" }
    $j = $code.IndexOf($end, $i + $start.Length, [StringComparison]::Ordinal)
    if ($j -lt 0) { throw "STAGE32H2Q_RED missing $end" }
    return $code.Substring($i, $j-$i)
}
$onTick = Part 'private void OnTick(float dt)' 'private void OnDailyTick()'
$onDaily = Part 'private void OnDailyTick()' 'private void ResolvePendingParley('
$onHour = Part 'private void OnHourlyTick()' 'private static void TryResolveTreatyBackedRebellion('
$firstGuard = $onTick.IndexOf('if (string.IsNullOrWhiteSpace(_pendingPlayerParleyOpenProposalId)', [StringComparison]::Ordinal)
$offGuard = $onTick.IndexOf('|| !WarPeaceRevampBehavior.IsRevampEnabled()', [StringComparison]::Ordinal)
$scan = $onTick.IndexOf('EnsureCollectionsInitialized();', [StringComparison]::Ordinal)
Check ($firstGuard -ge 0 -and $offGuard -gt $firstGuard -and $offGuard -lt $scan) 'Revamp OFF returns before scanning proposal and war every tick'
Check ($onTick.Contains('|| InformationManager.IsAnyInquiryActive()') -and
    $onTick.Contains('|| PeaceParleyInterface.Instance.IsShown)') -and
    $onTick.Contains('string.IsNullOrWhiteSpace(_pendingPlayerParleyOpenProposalId)')) 'existing UI and empty deferred ID fences retained'
Check ($onTick.Contains('if (proposal == null || proposal.State != TreatyProposalState.ParleyPending)') -and
    $onTick.Contains('if (war == null || !war.IsActive)') -and
    $onTick.Contains('TryOpenPlayerParley(')) 'Revamp ON resumes original deferred flow and invalid-state cleanup'
Check ($onTick.Contains('_pendingPlayerParleyOpenProposalId = null;') -and
    $onTick.Contains('_forcedPlayerParleyInquiryProposalId = null;')) 'original success and invalid cleanup retained'
Check ($onDaily.Contains('if (!WarPeaceRevampBehavior.IsRevampEnabled())') -and
    $onHour.Contains('RecoverTreatyDeliveries()') -and
    $onHour.Contains('TryResolveTreatyBackedRebellion(pending)')) 'daily and already-committed hourly paths unchanged'
Check ($code.Contains('report = "Bellum foreign treaty is frozen while War & Peace Revamp is disabled";') -and
    $code.Contains('public bool TrySignPlayerParley(') -and
    $code.Contains('public bool TryRejectPlayerParley(')) 'H2P existing player treaty mutation freeze preserved'
Write-Host 'STAGE32H2Q_SOURCE_CONTRACT_PASS; Windows build, live GUI/FPS, save/rollback PENDING'
