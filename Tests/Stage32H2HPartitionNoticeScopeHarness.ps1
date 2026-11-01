# Stage32H2H isolated executable scope regression.
# Compiles the real PartitionNoticeOrigin.cs with a minimal Campaign stub.
# Does NOT compile game DLL or prove actual Show postfix timing.
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$path = Join-Path $root 'PartitionNoticeOrigin.cs'
if (-not (Test-Path -LiteralPath $path)) { throw 'STAGE32H2H_SCOPE_RED missing native scope source' }
$native = Get-Content -LiteralPath $path -Raw

$harness = @'
namespace TaleWorlds.CampaignSystem
{
    public sealed class Campaign
    {
        public static Campaign Current { get; set; }
    }
}

public static class Stage32H2HScopeHarness
{
    private static void Check(bool condition, string name)
    {
        if (!condition) throw new System.Exception("STAGE32H2H_SCOPE_FAIL " + name);
    }

    public static string Run()
    {
        var saveA = new TaleWorlds.CampaignSystem.Campaign();
        var saveB = new TaleWorlds.CampaignSystem.Campaign();
        TaleWorlds.CampaignSystem.Campaign.Current = saveA;

        Check(BellumCivile.Behaviors.PartitionNoticeOriginScope.GetCurrent() == null, "outside_no_claim");
        using (BellumCivile.Behaviors.PartitionNoticeOriginScope.Begin(
            "dead", "house", "heir", "cadet", "ordinary", "heir:heir"))
        {
            var first = BellumCivile.Behaviors.PartitionNoticeOriginScope.GetCurrent();
            Check(first != null && first.EpisodeId == "partition|dead|house"
                && first.DeceasedId == "dead" && first.OriginHouseId == "house"
                && first.HeirId == "heir" && first.RecipientHouseId == "cadet"
                && first.Executor == "ordinary" && first.NoticeKey == "heir:heir",
                "exact_source_fields");

            using (BellumCivile.Behaviors.PartitionNoticeOriginScope.Begin(
                "dead2", "house2", "heir2", "cadet2", "mixed", "mixed-share:3"))
            {
                var nested = BellumCivile.Behaviors.PartitionNoticeOriginScope.GetCurrent();
                Check(nested != null && nested.EpisodeId == "partition|dead2|house2"
                    && nested.NoticeKey == "mixed-share:3", "nested_exact_claim");
            }
            Check(System.Object.ReferenceEquals(first,
                BellumCivile.Behaviors.PartitionNoticeOriginScope.GetCurrent()),
                "nested_previous_restored");

            try
            {
                using (BellumCivile.Behaviors.PartitionNoticeOriginScope.Begin(
                    "dead3", "house3", "heir3", "cadet3", "crown", "heir:heir3"))
                {
                    throw new System.InvalidOperationException("test throw");
                }
            }
            catch (System.InvalidOperationException) { }
            Check(System.Object.ReferenceEquals(first,
                BellumCivile.Behaviors.PartitionNoticeOriginScope.GetCurrent()),
                "throw_previous_restored");

            using (BellumCivile.Behaviors.PartitionNoticeOriginScope.Begin(
                null, "house", "heir", "cadet", "ordinary", "heir:heir"))
                Check(BellumCivile.Behaviors.PartitionNoticeOriginScope.GetCurrent() == null,
                    "invalid_claim_fails_closed");
            Check(System.Object.ReferenceEquals(first,
                BellumCivile.Behaviors.PartitionNoticeOriginScope.GetCurrent()),
                "invalid_nested_previous_restored");

            TaleWorlds.CampaignSystem.Campaign.Current = saveB;
            Check(BellumCivile.Behaviors.PartitionNoticeOriginScope.GetCurrent() == null,
                "other_campaign_denied");
            TaleWorlds.CampaignSystem.Campaign.Current = saveA;
            Check(System.Object.ReferenceEquals(first,
                BellumCivile.Behaviors.PartitionNoticeOriginScope.GetCurrent()),
                "original_campaign_same_thread_valid");
        }
        Check(BellumCivile.Behaviors.PartitionNoticeOriginScope.GetCurrent() == null,
            "after_dispose_no_claim");

        TaleWorlds.CampaignSystem.Campaign.Current = null;
        using (BellumCivile.Behaviors.PartitionNoticeOriginScope.Begin(
            "dead", "house", "heir", "cadet", "ordinary", "heir:heir"))
            Check(BellumCivile.Behaviors.PartitionNoticeOriginScope.GetCurrent() == null,
                "without_campaign_denied");

        return "STAGE32H2H_SCOPE_BEHAVIOR_PASS";
    }
}
'@
Add-Type -TypeDefinition ($native + [Environment]::NewLine + $harness) -Language CSharp -ErrorAction Stop
Write-Host ([Stage32H2HScopeHarness]::Run())
