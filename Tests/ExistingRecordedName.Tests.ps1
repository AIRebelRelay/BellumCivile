#Requires -Version 7.2
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$temp=Join-Path ([IO.Path]::GetTempPath()) ('recorded-name-'+[Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $temp | Out-Null
try {
    $source=Get-Content -Raw (Join-Path $root 'DynamicKingdomTitleNameHelper.cs')
    $peekStart=$source.IndexOf('internal static bool TryReadExistingNativeName(');$peekEnd=$source.IndexOf('public static string GetNativeName(Kingdom kingdom)',$peekStart)
    $readStart=$source.IndexOf('private static TextObject ResolveRecordedNativeText(');$readEnd=$source.IndexOf('private static void EnsureXmlNativeNamesLoaded()',$readStart)
    $copyStart=$source.IndexOf('private static TextObject Copy(TextObject text)');$copyEnd=$source.LastIndexOf('    }')
    $enumStart=$source.IndexOf('internal enum KingdomDisplayNameField');$enumEnd=$source.IndexOf('internal static class DynamicKingdomTitleNameHelper',$enumStart)
    if($peekStart -lt 0 -or $peekEnd -le $peekStart -or $readStart -lt 0 -or $readEnd -le $readStart -or $copyStart -lt 0 -or $copyEnd -le $copyStart -or $enumStart -lt 0 -or $enumEnd -le $enumStart) { throw 'Actual name helper extraction boundary changed' }
    $helpers='using TaleWorlds.CampaignSystem; using TaleWorlds.Localization; namespace BellumCivile {'+$source.Substring($enumStart,$enumEnd-$enumStart)+' internal static partial class DynamicKingdomTitleNameHelper {'+$source.Substring($peekStart,$peekEnd-$peekStart)+$source.Substring($readStart,$readEnd-$readStart)+$source.Substring($copyStart,$copyEnd-$copyStart)+' } }'
    Set-Content -LiteralPath (Join-Path $temp 'Helpers.cs') -Value $helpers
    $integration=Get-Content -Raw (Join-Path $root 'Behaviors/BellumIntegrationBehavior.cs')
    $thread=[regex]::Match($integration,'internal bool IsCampaignThread => [^;]+;');$guardStart=$integration.IndexOf('internal static void RequireCampaignThread()');$guardEnd=$integration.IndexOf('public override void RegisterEvents()',$guardStart)
    if(!$thread.Success -or $guardStart -lt 0 -or $guardEnd -le $guardStart) { throw 'Actual guard extraction boundary changed' }
    Set-Content -LiteralPath (Join-Path $temp 'Guard.cs') -Value ('using System;using System.Threading; namespace BellumCivile.Behaviors { public sealed partial class BellumIntegrationBehavior {'+$thread.Value+$integration.Substring($guardStart,$guardEnd-$guardStart)+'} }')
    foreach($name in @('Fixtures','Scenarios')) { Copy-Item (Join-Path $root "Tests/ExistingRecordedNameHarness/$name.cs.txt") (Join-Path $temp "$name.cs") }
    $paths=@('RecordedNameSnapshot.cs','BellumIntegrationRecordedNames.cs','Behaviors/FeudalRecordedNameState.cs','FeudalTitleRecord.cs','FeudalTitleType.cs') | ForEach-Object{Join-Path $root $_}
    $paths+=@(Get-ChildItem $temp -Filter *.cs | ForEach-Object FullName)
    Add-Type -Path $paths -CompilerOptions '/langversion:7.3'
    [RecordedNameScenarios]::Run()
} finally { Remove-Item -LiteralPath $temp -Recurse -Force }
