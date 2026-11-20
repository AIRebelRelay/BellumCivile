#!/usr/bin/env python3
"""Stage 6 SOURCE-ONLY RED/GREEN test for proposed Native peace eligibility API.

--baseline: proves the existing risky shared entrypoints still need isolation.
--candidate: RED while the four proposed Native files are absent; afterwards
             performs limited SOURCE checks, never a substitute for runtime QA.
--self-test: checks that the source scanner detects known forbidden patterns.

No TaleWorlds, game DLLs, CR, network, provider calls, or saves are used.
"""
from __future__ import annotations

import argparse
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
PLANNED = (
    "BellumIntegrationForeignPeacePreview.cs",
    "ForeignPeaceEligibilitySnapshot.cs",
    "Behaviors/WarScoreForeignPeacePreview.cs",
    "Behaviors/ClientKingdomForeignPeacePreview.cs",
)
BLOCKED_CALLS = (
    r"\bGetActiveWar\s*\(",
    r"\bGetClientRecord\s*\(",
    r"\bGetSuzerain\s*\(",
    r"\bCanMakePeace\s*\(",
    r"\bGetWarWill\s*\(",
    r"\bGetRankedTargets\s*\(",
    r"\bIsMutualWhitePeaceEligible\s*\(",
    r"\bIsPeaceBlocked\s*\(",
    r"\bTryQueueParley\s*\(",
    r"\bTryQueueAiParley\s*\(",
    r"\bTryQueuePlayerParley\s*\(",
    r"\bTryValidateAndNormalize\s*\(",
    r"\bGetOrCreateCouncilSnapshot\s*\(",
    r"\bBeginParley\s*\(",
    r"\bBeginResolution\s*\(",
    r"\bMakePeaceAction\s*\.\s*Apply\s*\(",
    r"\bApplyTreaty\s*\(",
    r"\bEnsureCollectionsInitialized\s*\(",
    r"\bRegisterConflict\s*\(",
    r"\bSyncData\s*\(",
    r"\bRegisterEvents\s*\(",
    r"\bMBRandom\s*\.",
    r"\bAddEvent\s*\(",
    r"\b(?:_wars|_clients|_proposals|_councilSnapshots|_warWillByClanId|_targetScoresByClanId)\s*=(?!=)",
    r"\b(?:_wars|_clients|_proposals|_councilSnapshots|_warWillByClanId|_targetScoresByClanId)\s*\.\s*(?:Add|Remove|RemoveAll|Clear|Insert)\s*\(",
)


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8-sig")


def body(source: str) -> str:
    # Approximate comment and string removal. Never claim this establishes purity.
    source = re.sub(r"/\*.*?\*/", "", source, flags=re.S)
    source = re.sub(r"//[^\r\n]*", "", source)
    source = re.sub(r'@"(?:[^"]|"")*"|"(?:\\.|[^"\\])*"', '""', source)
    return source


def section(source: str, begin: str, end: str) -> str:
    start = source.find(begin)
    stop = source.find(end, start + len(begin)) if start >= 0 else -1
    if start < 0 or stop <= start:
        raise AssertionError(f"source boundary changed: {begin} -> {end}")
    return source[start:stop]


def baseline() -> None:
    checks = [
        ("campaign_thread_guard", "Behaviors/BellumIntegrationBehavior.cs",
         "internal static void RequireCampaignThread()", "Current?.IsCampaignThread"),
        ("native_api_version_v1", "BellumIntegration.cs",
         "public const int ApiVersion = 1;", "public const int ApiVersion = 1;"),
        ("war_tracker_lazy_init", "Behaviors/WarScoreBehavior.cs",
         "public WarScoreRecord GetActiveWar(Kingdom first, Kingdom second)",
         "EnsureCollectionsInitialized();"),
        ("client_query_lazy_cleanup", "Behaviors/ClientKingdomBehavior.cs",
         "public ClientKingdomRecord GetClientRecord(Kingdom client)",
         "EnsureCollectionsInitialized();"),
        ("client_cleanup_mutates_revision", "Behaviors/ClientKingdomBehavior.cs",
         "private void EnsureCollectionsInitialized()", "AdvanceRuntimeRevision();"),
        ("war_will_getter_writes_state", "Behaviors/WarPeaceRevampBehavior.cs",
         "public float GetWarWill(Clan clan)", "_warWillByClanId[clan.StringId] = value;"),
        ("story_reflection_can_report_clear_on_unknown", "StorylineWarProtectionHelper.cs",
         "internal static bool IsPeaceBlocked(Kingdom first, Kingdom second)",
         "if (!TryGetActiveThirdPhase(out object thirdPhase))"),
        ("native_queue_combines_policy_and_mutation", "Behaviors/ForeignTreatyBehavior.cs",
         "private bool TryQueueParley(", "DraftAiTerms(war, proposal"),
    ]
    for name, path, start, witness in checks:
        text = read(path)
        if start not in text or witness not in text[text.index(start):]:
            raise AssertionError(f"{name}: expected current HEAD code witness changed in {path}")
        print(f"STAGE6_BASELINE_PASS {name}")
    print(f"STAGE6_BASELINE_PASS checks={len(checks)} (existing Native risky seams verified)")


def check_candidate() -> None:
    missing = [name for name in PLANNED if not (ROOT / name).is_file()]
    if missing:
        raise FileNotFoundError(
            "STAGE6_RED_NOT_IMPLEMENTED missing=" + ",".join(missing)
            + " (EXPECTED until Native Stage 7; do not fake GREEN)"
        )
    files = {path: body(read(path)) for path in PLANNED}
    for path, content in files.items():
        for expression in BLOCKED_CALLS:
            if re.search(expression, content):
                raise AssertionError(f"STAGE6_UNSAFE_CALL {path}: {expression}")
    api = files["BellumIntegrationForeignPeacePreview.cs"]
    snapshot = files["ForeignPeaceEligibilitySnapshot.cs"]
    war = files["Behaviors/WarScoreForeignPeacePreview.cs"]
    client = files["Behaviors/ClientKingdomForeignPeacePreview.cs"]
    structural = {
        "public_entrypoint": (api, r"\bGetForeignPeaceEligibility\s*\("),
        "campaign_thread_guarantee": (api, r"\bBellumIntegrationBehavior\.RequireCampaignThread\s*\("),
        "snapshot_type": (snapshot, r"\bclass\s+ForeignPeaceEligibilitySnapshot\b"),
        "no_snapshot_setters": (snapshot, r"\bset\s*;"),
        "no_save_type_metadata": (snapshot, r"\bSaveable(?:Field|Property)\s*\("),
        "read_only_war_partial": (war, r"\bpartial\s+class\s+WarScoreBehavior\b"),
        "read_only_client_partial": (client, r"\bpartial\s+class\s+ClientKingdomBehavior\b"),
        "war_owned_storage": (war, r"\b_wars\b"),
        "client_owned_storage": (client, r"\b_clients\b"),
        "never_immediate_execution": (snapshot, r"\bMayExecuteImmediately\b"),
    }
    for name, (content, expression) in structural.items():
        found = bool(re.search(expression, content))
        if found == (name in {"no_snapshot_setters", "no_save_type_metadata"}):
            raise AssertionError(f"STAGE6_STRUCTURE_FAIL {name}")
        print(f"STAGE6_SOURCE_PASS {name}")
    print("STAGE6_SOURCE_PASS candidate shape only; runtime purity NOT verified")


def self_test() -> None:
    for unsafe in [
        "var w = score.GetActiveWar(a,b);",
        "_clients.RemoveAll(x => x == null);",
        "MakePeaceAction.Apply(first,second);",
        "GetWarWill(clan);",
        "BeginParley(true, currentDay);",
    ]:
        if not any(re.search(pattern, body(unsafe)) for pattern in BLOCKED_CALLS):
            raise AssertionError(f"scanner failed to reject {unsafe}")
    # A null/equality *read* must not be confused with a field write.
    if any(re.search(pattern, body("if (_wars == null || _clients == null) return;"))
           for pattern in BLOCKED_CALLS):
        raise AssertionError("scanner falsely flagged an equality-only read")
    if any(re.search(pattern, body("// BeginParley()\nvar x = 1;"))
           for pattern in BLOCKED_CALLS):
        raise AssertionError("scanner falsely flagged a comment")
    print("STAGE6_SCANNER_PASS rejected_unsafe=5 ignored_comment=1")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--mode", choices=("baseline", "candidate", "self-test"),
                        default="baseline")
    args = parser.parse_args()
    if args.mode == "baseline":
        baseline()
    elif args.mode == "candidate":
        check_candidate()
    else:
        self_test()


if __name__ == "__main__":
    main()
