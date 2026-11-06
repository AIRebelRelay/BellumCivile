$ErrorActionPreference = 'Stop'
# P0-04A RED-first contract: installed Harmony entrypoints must NOT fall back to
# vanilla treaty actions for native active call-to-arms. Source assertions only.
# Windows pwsh, Harmony compile/game and rollback checks are deferred.
$root = Split-Path -Parent $PSScriptRoot
$src = Get-Content -LiteralPath (Join-Path $root 'Patches/PeaceParleyEntryPointPatches.cs') -Raw
$guard = Get-Content -LiteralPath (Join-Path $root 'AlliancePeaceRestriction.cs') -Raw
$native = Get-Content -LiteralPath (Join-Path $root 'Behaviors/ForeignTreatyBehavior.cs') -Raw
function Check([bool]$ok, [string]$label) {
    if (-not $ok) { throw "P004A_RED $label" }
    Write-Host "P004A_SOURCE_PASS $label"
}
function Part([string]$a, [string]$b) {
    $x = $src.IndexOf($a, [StringComparison]::Ordinal)
    $y = if ($x -lt 0) { -1 } else { $src.IndexOf($b, $x + $a.Length, [StringComparison]::Ordinal) }
    Check ($x -ge 0 -and $y -gt $x) "source segment $a"
    return $src.Substring($x, $y-$x)
}
function Ahead([string]$body, [string]$first, [string]$next, [string]$what) {
    $a = $body.IndexOf($first, [StringComparison]::Ordinal)
    $b = $body.IndexOf($next, [StringComparison]::Ordinal)
    Check ($a -ge 0 -and $b -gt $a) $what
}
$ruler = Part 'public static class RulerPeaceOfferParleyPatch' 'public static class KingdomDiplomacyPeaceParleyPatch'
$button = Part 'public static class KingdomDiplomacyPeaceParleyPatch' 'public static class KingdomPeaceVoteNotificationParleyPatch'
$inspect = Part 'public static class KingdomPeaceVoteNotificationParleyPatch' 'public static class KingdomPeaceVoteNotificationQueuedParleyPatch'
$queued = Part 'public static class KingdomPeaceVoteNotificationQueuedParleyPatch' 'public static class KingdomPeaceDecisionAddedParleyCleanupPatch'
$added = Part 'public static class KingdomPeaceDecisionAddedParleyCleanupPatch' 'public static class KingdomPeaceDecisionScreenFallbackPatch'
$screen = Part 'public static class KingdomPeaceDecisionScreenFallbackPatch' 'internal static class PeaceParleyDecisionRedirector'
$redirect = $src.Substring($src.IndexOf('internal static class PeaceParleyDecisionRedirector', [StringComparison]::Ordinal))

Check ($guard.Contains('IsAtWarByCallToWarAgreement(first, second, out caller)') -and
       $guard.Contains('IsAtWarByCallToWarAgreement(second, first, out caller)')) 'native exact call-to-arms obligation kept'
Check ($native.Contains('private bool TryCancelAllianceRestrictedProposal(') -and
       $native.Contains('if (AlliancePeaceRestriction.TryGetPeaceBlock(attacker, defender, out TextObject allianceReason))')) 'P0-02B/C native treaty fences remain'

# Ruler courier and diplomacy button: deny before vanilla fallback or any influence.
Check ($ruler.Contains('|| AlliancePeaceRestriction.TryGetPeaceBlock(playerKingdom, opponent, out storylineReason)')) 'ruler courier combines storyline and native alliance reason'
Ahead $ruler 'AlliancePeaceRestriction.TryGetPeaceBlock(' 'TryQueueDeferredPlayerParleyOpen(' 'ruler stops native alliance peace before new parley'
Check ($ruler.Contains('____opponentFaction = null;') -and $ruler.Contains('InformationManager.DisplayMessage(') -and $ruler.Contains('return false;')) 'ruler restricted offer closes courier lock and suppresses vanilla acceptance'
Ahead $ruler 'if (!WarPeaceRevampBehavior.IsRevampEnabled())' 'AlliancePeaceRestriction.TryGetPeaceBlock(' 'ruler OFF remains native pass-through'

Check ($button.Contains('|| AlliancePeaceRestriction.TryGetPeaceBlock(playerKingdom, opponent, out storylineReason)')) 'diplomacy button displays native alliance reason'
Ahead $button 'AlliancePeaceRestriction.TryGetPeaceBlock(' 'TryOpenPlayerParley(' 'diplomacy button denies before redirect/influence'
Ahead $button 'AlliancePeaceRestriction.TryGetPeaceBlock(' 'ChangeClanInfluenceAction.Apply(' 'no proposal influence cost for prohibited peace'
Check ($button.Contains('InternalPeaceSettlementBehavior.TryIdentify(playerKingdom, opponent') -and
       $button.Contains('if (!WarPeaceRevampBehavior.IsRevampEnabled() || item == null)')) 'internal war and OFF keep original path'

# Inspected and newly queued vote notifications can otherwise launch vanilla voting.
Ahead $inspect 'AlliancePeaceRestriction.TryGetPeaceBlock(playerKingdom, opponent, out TextObject allianceReason)' 'StorylineWarProtectionHelper.TryGetPeaceBlock(' 'stale notification checks native alliance before opening parley'
Check ($inspect.Contains('peaceDecision.Kingdom?.RemoveDecision(peaceDecision);') -and
       $inspect.Contains('InformationManager.DisplayMessage(new InformationMessage(allianceReason.ToString()') -and
       $inspect.Contains('return false;')) 'stale notification removed with reason; cannot open vanilla vote'
Ahead $inspect 'AlliancePeaceRestriction.TryGetPeaceBlock(' 'treaties.TryOpenPlayerParley(' 'inspect denial before vanilla vote/Native parley'
Check ($inspect.Contains('private static bool Prefix(KingdomDecision ____decision)')) 'existing Harmony Prefix signature stays intact'

Check ($queued.Contains('|| AlliancePeaceRestriction.IsPeaceBlocked(playerKingdom, opponent)')) 'notification creation checks native alliance'
Ahead $queued 'AlliancePeaceRestriction.IsPeaceBlocked(' 'TryQueuePlayerParley(' 'new notification stops before Native queue'
Check ($queued.Contains('peaceDecision.Kingdom?.RemoveDecision(peaceDecision);') -and
       $queued.Contains('return;')) 'blocked notification retires vanilla decision'

# Shared redirector is only used by existing AddDecision Postfix and old-save UI Prefix.
Ahead $redirect 'if (AlliancePeaceRestriction.IsPeaceBlocked(playerKingdom, opponent))' 'if (StorylineWarProtectionHelper.IsPeaceBlocked(playerKingdom, opponent))' 'redirector native alliance guard has priority'
Ahead $redirect 'if (AlliancePeaceRestriction.IsPeaceBlocked(playerKingdom, opponent))' 'TryQueueDeferredPlayerParleyOpen(' 'redirector refuses before queued parley or vanilla continuation'
Check ($redirect.Contains('report = AlliancePeaceRestriction.CancellationReason;') -and
       $redirect.Contains('peaceDecision.Kingdom?.RemoveDecision(peaceDecision);') -and
       $redirect.Contains('return true;')) 'redirector reports handled retirement so old-save screen cannot fall back'
Check ($added.Contains('private static void Postfix(Kingdom __instance, KingdomDecision kingdomDecision)') -and
       -not $added.Contains('[HarmonyPrefix]')) 'AddDecision still uses existing Postfix only; no new early Harmony hook'
Check ($screen.Contains('private static bool Prefix(KingdomDecision curDecision)') -and
       $screen.Contains('PeaceParleyDecisionRedirector.TryQueueAndRetire(')) 'old saved peace decision still uses shared redirector'

# Neighbors must still exist on unblocked path, without removing original behavior.
Check ($ruler.Contains('TryQueueDeferredPlayerParleyOpen(') -and
       $button.Contains('TryOpenPlayerParley(') -and
       $queued.Contains('TryQueuePlayerParley(') -and
       $redirect.Contains('TryQueueDeferredPlayerParleyOpen(')) 'ordinary legal peace redirect paths retained'
Check ($ruler.Contains('Suppressed a ruler courier peace offer for a protected foreign war;') -and
       $queued.Contains('Prevented a peace vote notification from queuing during a protected foreign war;')) 'shared protected-war logs do not falsely label alliance blocks as Story Mode'
Check ($src.Contains('StorylineWarProtectionHelper.TryGetPeaceBlock') -and
       $src.Contains('InternalPeaceSettlementBehavior.TryIdentify')) 'storyline and internal peace routing unchanged'

Write-Host 'P004A_SOURCE_CONTRACT_PASS; PowerShell not verified here; Harmony, game ON/OFF, old saves and runtime ABI deferred.'
