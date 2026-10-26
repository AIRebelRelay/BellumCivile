$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$scope = Get-Content -LiteralPath (Join-Path $root 'BellumNativeLeaveProvenance.cs') -Raw
$court = Get-Content -LiteralPath (Join-Path $root 'Patches/ExpelClanDecisionPatch.cs') -Raw
$ideology = Get-Content -LiteralPath (Join-Path $root 'Behaviors/IdeologyBehavior.cs') -Raw
function Must([bool]$valid, [string]$why) { if (-not $valid) { throw "STAGE27B_NATIVE_PROVENANCE_FAIL: $why" } }

# Boundaries and semantics of the single shared native scope.
Must ($scope.Contains('[ThreadStatic]')) 'scope is thread local'
Must ($scope.Contains('ReferenceEquals(_target, targetClan)')) 'matching uses Clan object identity'
Must ($scope.Contains('public static string ReadOwnerFor(Clan targetClan)')) 'Bridge read-only API'
Must ($scope.Contains('internal static IDisposable Enter(Clan targetClan, string owner)')) 'native-only scope enter'
Must ($scope.Contains('private sealed class RestoreScope : IDisposable')) 'scoped restoration helper'
Must ($scope.Contains('_target = _previousTarget;') -and $scope.Contains('_owner = _previousOwner;')) 'nested restoration of target AND owner'
Must ($scope.Contains('private static Clan _target;') -and $scope.Contains('private static string _owner;')) 'no shared static realm or target hash'

# Every exposed native leave call is guarded EXACTLY at the point of invocation.
Must ($court.Contains('using (BellumNativeLeaveProvenance.Enter(targetClan, "deferred_legal_court"))')) 'deferred Court fallback provenance'
Must ($court.Contains('ChangeKingdomAction.ApplyByLeaveKingdom(targetClan, showNotification: false);')) 'deferred leave remains exact'
Must ($court.Contains('ApplyExpulsionAftermath(targetClan, sponsorClan, kingdom);')) 'deferred aftermath retained'
Must (-not $court.Contains('_deferredLegalExpulsionTarget')) 'Stage27A narrow marker retired; one shared invariant'
Must (-not $court.Contains('IsCompletingDeferredLegalExpulsionFor')) 'no two competing source APIs'
Must ($ideology.Contains('using (BellumNativeLeaveProvenance.Enter(targetClan, "player_treason_judgment"))')) 'player judgment native call'
Must ($ideology.Contains('using (BellumNativeLeaveProvenance.Enter(targetClan, "treason_purge_no_refuge"))')) 'treason purge no-refuge call'
Must ($ideology.Contains('ChangeKingdomAction.ApplyByJoinToKingdom(targetClan, foreignRefuge);')) 'foreign refuge migration remains unchanged'
Must (($ideology.Split(@('ChangeKingdomAction.ApplyByLeaveKingdom(targetClan, false);'),[System.StringSplitOptions]::None)).Length -eq 3) 'both original direct leave invocations retained'
Must ($court.Contains('public static bool Prefix(ExpelClanFromKingdomDecision __instance, DecisionOutcome chosenOutcome, ref bool __state)')) 'Court Prefix remains'
Must ($court.Contains('public static void Postfix(ExpelClanFromKingdomDecision __instance, DecisionOutcome chosenOutcome, bool __state)')) 'Court Postfix remains'

# Compile the production scope with minimal Clan stub and test real nested IDisposable semantics.
$stub = 'namespace TaleWorlds.CampaignSystem { public sealed class Clan {} }'
$types = @(Add-Type -TypeDefinition ($scope + [Environment]::NewLine + $stub) -PassThru)
$clan = $types | Where-Object FullName -eq 'TaleWorlds.CampaignSystem.Clan' | Select-Object -First 1
$api = $types | Where-Object FullName -eq 'BellumCivile.BellumNativeLeaveProvenance' | Select-Object -First 1
Must ($null -ne $api -and $null -ne $clan) 'real production class compiled in isolated stub harness'
$a = [Activator]::CreateInstance($clan)
$b = [Activator]::CreateInstance($clan)
$read = $api.GetMethod('ReadOwnerFor')
$enter = $api.GetMethod('Enter', [System.Reflection.BindingFlags]::Static -bor [System.Reflection.BindingFlags]::NonPublic)
Must ([string]::IsNullOrEmpty([string]$read.Invoke($null,@($a)))) 'no scope => no source proof'
$outer = [IDisposable]$enter.Invoke($null,@($a,'deferred_legal_court'))
try {
    Must ([string]$read.Invoke($null,@($a)) -eq 'deferred_legal_court') 'same target is attested'
    Must ([string]::IsNullOrEmpty([string]$read.Invoke($null,@($b)))) 'other Clan is never attested'
    $inner = [IDisposable]$enter.Invoke($null,@($b,'player_treason_judgment'))
    try {
        Must ([string]$read.Invoke($null,@($b)) -eq 'player_treason_judgment') 'nested owner is attested'
        Must ([string]::IsNullOrEmpty([string]$read.Invoke($null,@($a)))) 'outer target hidden while inner is active'
        throw 'forced error to test finally restoration'
    } catch { Must ($_.Exception.Message.Contains('forced error')) 'unexpected nested exception' }
    finally { $inner.Dispose() }
    Must ([string]$read.Invoke($null,@($a)) -eq 'deferred_legal_court') 'prior target restored despite exception'
} finally { $outer.Dispose() }
Must ([string]::IsNullOrEmpty([string]$read.Invoke($null,@($a)))) 'no scope leaks after exit'
Write-Host 'STAGE27B_NATIVE_PROVENANCE_CONTRACT_PASS: same-target, other-target, nested and exception-safe source.'
