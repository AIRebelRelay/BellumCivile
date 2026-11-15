# Bannerlord 1.5.7 incident API migration regression contract.
# Pure source checks only. Real 1.5.7 DLL compile and live council tests are separate gates.
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$registryPath = Join-Path $root 'CouncilIncidentRegistry.cs'
$behaviorPath = Join-Path $root 'Behaviors/CouncilIncidentBehavior.cs'
$guardPath = Join-Path $root 'Patches/CouncilIncidentResolvedPatch.cs'
foreach ($path in @($registryPath, $behaviorPath, $guardPath)) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "BELLUM157_INCIDENT_API FAIL missing_source=$path"
    }
}
$registry = [System.IO.File]::ReadAllText($registryPath)
$behavior = [System.IO.File]::ReadAllText($behaviorPath)
$guard = [System.IO.File]::ReadAllText($guardPath)
function Assert-Has([string]$body, [string]$fragment, [string]$caseName) {
    if (-not $body.Contains($fragment)) { throw "BELLUM157_INCIDENT_API FAIL $caseName" }
    Write-Output "PASS BELLUM157_INCIDENT_API $caseName"
}
function Assert-NotHas([string]$body, [string]$fragment, [string]$caseName) {
    if ($body.Contains($fragment)) { throw "BELLUM157_INCIDENT_API FAIL $caseName" }
    Write-Output "PASS BELLUM157_INCIDENT_API $caseName"
}

Assert-Has $registry 'string incidentType,' 'incident_type_constructor_157'
Assert-Has $registry 'public string IncidentType { get; }' 'incident_type_property_157'
Assert-NotHas $registry 'IncidentsCampaignBehaviour.IncidentType incidentType,' 'obsolete_type_parameter_removed'
Assert-NotHas $registry 'public IncidentsCampaignBehaviour.IncidentType IncidentType { get; }' 'obsolete_type_property_removed'
$categoryCount = ([regex]::Matches($registry, [regex]::Escape('IncidentsCampaignBehaviour.IncidentType.FiefManagement'))).Count
if ($categoryCount -ne 13) { throw "BELLUM157_INCIDENT_API FAIL category_constants_preserved count=$categoryCount" }
Write-Output "PASS BELLUM157_INCIDENT_API category_constants_preserved count=$categoryCount"

Assert-Has $behavior 'new Incident.IncidentTrigger(),' 'new_trigger_157'
Assert-NotHas $behavior '(IncidentsCampaignBehaviour.IncidentTrigger)0,' 'obsolete_trigger_removed'
Assert-Has $behavior 'new IncidentEffect(' 'new_effect_ctor_157'
Assert-NotHas $behavior 'IncidentEffect.Custom(' 'obsolete_effect_factory_removed'
Assert-Has $behavior 'new IncidentHint(new TextObject("{=!}{HINTS}")' 'localized_hint_wrapper_157'
Assert-Has $behavior '.SetTextVariable("HINTS", string.Join("\n", capturedOption.GetHints(context)))' 'original_hints_retained'
Assert-Has $behavior '() => ApplyOptionSafely(capturedOption, context),' 'option_effect_preserved'
Assert-Has $behavior 'condition: null,' 'option_condition_retained'
Assert-Has $behavior 'consequence: CompletePendingIncident);' 'option_completion_retained'
Assert-Has $behavior 'RuntimeIncidentIdPrefix + _incidentSerial' 'stable_incident_id_retained'
Assert-Has $behavior 'List<CouncilIncidentOptionDefinition> options = definition.GetOptions(context);' 'existing_option_selection_retained'
Assert-Has $guard 'CouncilIncidentBehavior.RuntimeIncidentIdPrefix' 'resolved_guard_retained'
Write-Output 'BELLUM157_INCIDENT_API SOURCE_PASS; compile_and_gameplay=NOT_RUN'
