$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$s = Get-Content -LiteralPath (Join-Path $root 'Patches/ExpelClanDecisionPatch.cs') -Raw
$scope = Get-Content -LiteralPath (Join-Path $root 'BellumNativeLeaveProvenance.cs') -Raw
function Must([bool]$ok,[string]$why) { if (-not $ok) { throw "STAGE27A_NATIVE_FAIL: $why" } }
Must ($scope.Contains('[ThreadStatic]')) 'thread-local owner still required'
Must ($scope.Contains('ReferenceEquals(_target, targetClan)')) 'exact Clan reference required'
Must ($scope.Contains('private sealed class RestoreScope : IDisposable')) 'automatic exception-safe restoration'
$a = $s.IndexOf('private static void CompleteDeferredLegalExpulsion(',[StringComparison]::Ordinal)
$b = $s.IndexOf('private static void ApplyCustomResolutionBookkeeping(', $a, [StringComparison]::Ordinal)
Must ($a -ge 0 -and $b -gt $a) 'lawful fallback method boundaries unchanged'
$m = $s.Substring($a,$b-$a)
Must ($m.Contains('if (resolution != UltimatumResolution.Failed || targetClan == null || targetClan.Kingdom != kingdom)')) 'same Court legality gate'
Must ($m.Contains('using (BellumNativeLeaveProvenance.Enter(targetClan, "deferred_legal_court"))')) 'deferred owner exact, with scope'
Must ($m.Contains('ChangeKingdomAction.ApplyByLeaveKingdom(targetClan, showNotification: false);')) 'TaleWorlds API and arguments unchanged'
Must ($m.IndexOf('using (BellumNativeLeaveProvenance.Enter(',[StringComparison]::Ordinal) -lt $m.IndexOf('ChangeKingdomAction.ApplyByLeaveKingdom(',[StringComparison]::Ordinal)) 'attestation starts before leave'
Must ($m.Contains('ApplyExpulsionAftermath(targetClan, sponsorClan, kingdom);')) 'aftermath preserved after using'
Must ($s.Contains('public static void Postfix(ExpelClanFromKingdomDecision __instance, DecisionOutcome chosenOutcome, bool __state)')) 'Court finalization unchanged'
Write-Host 'STAGE27A_NATIVE_DEFERRED_SCOPE_SOURCE_PASS (Stage27B unified scope)'
