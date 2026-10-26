$ErrorActionPreference = 'Stop'
$s = Get-Content -LiteralPath (Join-Path (Split-Path $PSScriptRoot -Parent) 'Patches/ExpelClanDecisionPatch.cs') -Raw
function Must([bool]$ok,[string]$why) { if (-not $ok) { throw "STAGE27A_NATIVE_FAIL: $why" } }
Must ($s.Contains('[ThreadStatic]')) 'thread-local provenance'
Must ($s.Contains('private static Clan _deferredLegalExpulsionTarget;')) 'exact target scope'
Must ($s.Contains('public static bool IsCompletingDeferredLegalExpulsionFor(Clan targetClan)')) 'public read-only API'
Must ($s.Contains('ReferenceEquals(_deferredLegalExpulsionTarget, targetClan)')) 'reference match'
Must ($s.Contains('Clan previousDeferredTarget = _deferredLegalExpulsionTarget;')) 'nested scope restoration'
$a = $s.IndexOf('private static void CompleteDeferredLegalExpulsion(',[StringComparison]::Ordinal)
$b = $s.IndexOf('private static void ApplyCustomResolutionBookkeeping(', $a, [StringComparison]::Ordinal)
Must ($a -ge 0 -and $b -gt $a) 'method boundaries'
$m = $s.Substring($a,$b-$a)
Must ($m.Contains('if (resolution != UltimatumResolution.Failed || targetClan == null || targetClan.Kingdom != kingdom)')) 'legal gate'
Must ($m.Contains('_deferredLegalExpulsionTarget = targetClan;')) 'scope enter'
Must ($m.Contains('ChangeKingdomAction.ApplyByLeaveKingdom(targetClan, showNotification: false);')) 'original exact leave'
Must ($m.Contains('finally') -and $m.Contains('_deferredLegalExpulsionTarget = previousDeferredTarget;')) 'exception-safe scope exit'
Must ($m.IndexOf('_deferredLegalExpulsionTarget = targetClan;') -lt $m.IndexOf('ChangeKingdomAction.ApplyByLeaveKingdom(')) 'enter before leave'
Must ($m.IndexOf('_deferredLegalExpulsionTarget = previousDeferredTarget;') -lt $m.IndexOf('ApplyExpulsionAftermath(')) 'exit before aftermath'
Must ($s.Contains('public static void Postfix(ExpelClanFromKingdomDecision __instance, DecisionOutcome chosenOutcome, bool __state)')) 'unchanged Court Postfix'
Write-Host 'STAGE27A_NATIVE_DEFERRED_SCOPE_SOURCE_PASS'
