#!/usr/bin/env python3
"""Stage 7 source-backed optional-mod safety regression.

Requires a repository checkout, no game DLLs. It inspects static shape;
NO claim of runtime purity, StoryMode API validity or binary compatibility.
"""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def load(path):
    return (ROOT / path).read_text(encoding="utf-8-sig")


def verify():
    entry = load("BellumIntegrationForeignPeacePreview.cs")
    probe = load("ForeignPeaceOptionalModSafetyProbe.cs")

    # Story Mode source contract: only an actual player-side foreign war requires
    # a sensitive quest check; unverified player-side protection remains UNKNOWN.
    assert "Hero.MainHero?.MapFaction as Kingdom" in probe
    assert "source == playerKingdom" in probe
    assert "target == playerKingdom" in probe
    assert "ForeignPeaceOptionalVerdict.Unknown" in probe
    assert "ForeignPeaceOptionalVerdict.Clear" in probe
    assert "ForeignPeaceOptionalVerdict.Blocked" in probe
    assert "StorylineWarProtectionHelper.IsPeaceBlocked(" not in entry + probe

    # Source-confirmed optional assembly names and exact read-only extension.
    for marker in ("Bannerlord.Diplomacy", "Bannerlord.ModuleLoader.Bannerlord.Diplomacy",
                   "Diplomacy.Extensions.KingdomExtensions", "IsRebelKingdom"):
        assert marker in probe, marker
    assert "GetMethod(" in probe
    assert "typeof(Kingdom)" in probe
    assert "typeof(bool)" in probe
    assert "MethodInfo" in probe

    # Fail closed if optional API cannot prove its presence, signature,
    # readout or known source-backed semantics. The actual game/assembly
    # tests remain a separate gate.
    assert "catch (" in probe
    assert "ForeignPeaceOptionalVerdict.Unknown" in probe
    assert re.search(r"ForeignPeaceOptionalVerdict\.Blocked", entry)
    assert re.search(r"ForeignPeaceOptionalVerdict\.Unknown", entry)

    # Neither optional bridge can invoke the mutating shared helpers.
    banned = (
        "ModIntegrationHelper.IsDiplomacyRebelKingdom(",
        "StorylineWarProtectionHelper.IsPeaceBlocked(",
        "TryQueueParley(", "GetWarWill(", "CanMakePeace(",
        "MakePeaceAction.Apply(", "BeginParley(",
        "ProcessTributes(", "RegisterConflict(",
    )
    for candidate in banned:
        assert candidate not in entry + probe, candidate

    # Baseline semantics retained: API is NOT a peace commit or treaty receipt.
    assert "ForeignPeaceExecutionReadiness.NotReady" in entry
    assert "negotiated_treaty_gateway_not_implemented" in entry
    print("STAGE7_OPTIONAL_MOD_SOURCE_PASS checks=26 runtime_tests=NOT_RUN")


if __name__ == "__main__":
    try:
        verify()
    except (AssertionError, OSError) as error:
        print("STAGE7_OPTIONAL_MOD_SOURCE_FAIL", str(error), file=sys.stderr)
        sys.exit(1)
