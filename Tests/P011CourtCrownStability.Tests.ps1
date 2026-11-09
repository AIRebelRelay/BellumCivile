$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$agenda = Get-Content -Raw (Join-Path $root 'Behaviors/CourtAgendaBehavior.cs')
$executive = Get-Content -Raw (Join-Path $root 'Behaviors/CourtExecutiveAgendas.cs')
function Check([bool]$condition, [string]$message) {
    if (-not $condition) { throw "FAIL: $message" }
    Write-Output "PASS: $message"
}
function Slice([string]$content, [string]$start, [string]$end) {
    $i = $content.IndexOf($start, [StringComparison]::Ordinal)
    if ($i -lt 0) { throw "Missing section: $start" }
    $j = $content.IndexOf($end, $i + $start.Length, [StringComparison]::Ordinal)
    if ($j -lt 0) { throw "Missing section boundary: $end" }
    return $content.Substring($i, $j - $i)
}
function Count([string]$value, [string]$literal) {
    return ([regex]::Matches($value, [regex]::Escape($literal))).Count
}
$admission = Slice $agenda 'private static bool TryGetCourtRuler(' 'internal static bool Eligible('
Check ($admission.Contains('NobleClanEligibilityHelper.IsValidRulingClan(house, realm)') -and
       $admission.Contains('CrownAccessionBehavior.Instance?.IsPending(realm) != true') -and
       $admission.Contains('!CivilWarConflictBehavior.IsRealmTransferPending(realm)')) 'Court refuses invalid ruling house and in-progress Crown/realm transfer.'
Check ($admission.Contains('currentHouse == house && currentRuler == ruler')) 'Same court snapshot requires same ruling clan and monarch.'

$tick = Slice $agenda 'private void Tick()' 'private void OpenTerm('
Check ($tick.Contains('if (!TryGetCourtRuler(realm, out Clan house, out Hero ruler)) continue;')) 'Daily court processing admits only a stable ruler.'
foreach ($mutator in @('CheckMandate(realm);', 'Maintain(realm);', 'ScanDecreeCases(realm, ideology);', 'MaintainCouncilVacancyPriority(realm);')) {
    $pos = $tick.IndexOf($mutator, [StringComparison]::Ordinal)
    Check ($pos -ge 0 -and $tick.IndexOf('if (!CourtRulerUnchanged(realm, house, ruler)) continue;', $pos, [StringComparison]::Ordinal) -gt $pos) "Daily ruler recheck follows $mutator"
}
Check ((Count $tick 'if (!CourtRulerUnchanged(realm, house, ruler)) break;') -eq 2) 'Both emergency-challenge and agenda-advance loops stop on a Crown change.'

$open = Slice $agenda 'private void OpenTerm(' 'private void Advance('
Check ($open.Contains('if (!TryGetCourtRuler(realm, out Clan house, out Hero ruler)) return;')) 'New court term refuses unstable Crown.'
foreach ($mutator in @('UpdatePlayerAgenda(old);', 'ideology.BeginCourtTerm(realm);', 'ElectiveSuccessionBehavior.Instance?.Maintain(realm, renewal: true);', 'OpenCrownTerm(realm, manager);')) {
    $pos = $open.IndexOf($mutator, [StringComparison]::Ordinal)
    Check ($pos -ge 0 -and $open.IndexOf('if (!CourtRulerUnchanged(realm, house, ruler)) return;', $pos, [StringComparison]::Ordinal) -gt $pos) "Term admission rechecked after $mutator"
}
Check ($open.Contains('foreach (FactionObject owner in factions.Concat(new FactionObject[] { null }))') -and
       $open.Contains('if (!CourtRulerUnchanged(realm, house, ruler)) return;')) 'Term owner iteration preserves sovereign consistency.'

$scan = Slice $executive 'private void ScanDecreeCases(' 'private void AnnounceDeferredDecree('
Check ($scan.Contains('!TryGetCourtRuler(realm, out Clan house, out Hero ruler)') -and
       $scan.Contains('if (!CourtRulerUnchanged(realm, house, ruler)) return;')) 'Treason scanning checks Crown before and during new-case creation.'
$priority = Slice $executive 'private bool AssignPriorityDecree(' 'public bool TryNominateTreason('
Check ($priority.Contains('if (!TryGetCourtRuler(agenda?.Realm, out _, out Hero ruler)) return false;') -and
       $priority.Contains('return AssignDecree(agenda, entry);')) 'Priority decree reports success only after actual assignment.'
Check ($priority.Contains('private bool AssignDecree(') -and
       $priority.Contains('entry.Ruler != ruler) return false;') -and
       $priority.Contains('return true;')) 'Decree assignment rejects obsolete authority before mutation and confirms successful commit.'
$advance = Slice $executive 'private void AdvanceExecutive(' 'private static bool'
Check ($advance.Contains('if (!TryGetCourtRuler(agenda.Realm, out _, out Hero ruler)) return;') -and
       $advance.Contains('entry.Ruler != ruler')) 'Stored decree cannot advance under a different or pending ruler.'

# Neighboring features are not implementation targets: retain our custom court owners.
Check ($tick.Contains('CaptureEvictedCourtTerminals(') -and
       $tick.Contains('MaintainNpcTreasonLifecycle();') -and $tick.Contains('MaintainNpcCouncilIntentLifecycle();')) 'Saved terminal and NPC-lifecycle reconciliation remains enabled.'
Check ($open.Contains('FreezeNpcCouncilTerminalResults(realm);') -and
       $open.Contains('TryAttachStagedNpcTreason(agenda, context)') -and
       $open.Contains('TryAttachStagedNpcCouncil(agenda, context, choices, i)')) 'Custom NPC council/treason agenda owners remain unchanged.'
Check ($agenda.Contains('QueuePolicyVote(agenda.Realm, policy, agenda.Abolish, agenda.Faction, agenda.Sponsor, agenda.VoteDate)')) 'Policy filing retains original frozen vote date and owner.'
Check ($executive.Contains('if (IsPeaceObjective(agenda)) { AdvancePeaceObjective(agenda); return; }') -and
       $executive.Contains('if (IsCouncil(agenda)) { AdvanceCouncil(agenda); return; }')) 'Unrelated peace/council executive dispatch remains available.'
'UP148-SUCCESSION Court source contracts passed. Windows build and actual campaign validation still pending.'
