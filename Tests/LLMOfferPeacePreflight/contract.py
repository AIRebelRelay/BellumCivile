#!/usr/bin/env python3
"""Independent OFFER_PEACE preflight *contract oracle*, NOT Native Bellum code.

No TaleWorlds/CR imports, no effects, no network or game access. Future Native API
implementation must be independently tested against these input/output fixtures.
"""
from __future__ import annotations

import copy
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent
REQUIRED_FACTS = {
    "campaignLoaded", "campaignIdKnown", "actorAlive", "actorRulesSource",
    "actorControlledByPlayer", "sourceValidPermanent", "targetValidPermanent",
    "sameRealm", "foreignConflict", "atWar", "storyProtection",
    "clientPeaceAuthority", "targetControlledByPlayer", "trackedWarExists",
    "trackedConflictKind", "nativeGatewayAvailable", "revampEnabled",
    "warWill", "terms", "nativeDraftValidation",
    "normalizedTermsMateriallyChanged", "usedWarScore", "warScoreBudget",
}
OUTCOMES = {
    "legality": {"allowed_to_propose", "blocked", "unknown"},
    "executionReadiness": {"ready", "not_ready", "unknown"},
    "draftReview": {"not_requested", "valid", "invalid", "unknown"},
    "responseAuthority": {"npc", "player", "unknown"},
}


def preview(facts: dict) -> dict:
    """Pure example contract semantics. This does NOT evaluate TaleWorlds state."""
    if set(facts) != REQUIRED_FACTS:
        raise ValueError(f"facts schema mismatch: missing={sorted(REQUIRED_FACTS-set(facts))}; "
                         f"unexpected={sorted(set(facts)-REQUIRED_FACTS)}")

    reasons: list[str] = []
    hard_blocks = [
        ("actorAlive", False, "actor_not_alive"),
        ("actorRulesSource", False, "actor_not_ruler"),
        ("actorControlledByPlayer", True, "actor_is_player"),
        ("sourceValidPermanent", False, "source_not_permanent"),
        ("targetValidPermanent", False, "target_not_permanent"),
        ("sameRealm", True, "same_realm"),
        ("foreignConflict", False, "not_ordinary_foreign_conflict"),
        ("atWar", False, "not_at_war"),
        ("storyProtection", "blocked", "storyline_peace_blocked"),
        ("clientPeaceAuthority", "blocked", "suzerain_authority_required"),
    ]
    unknown_facts = [
        ("actorAlive", "actor_alive_unknown"),
        ("actorRulesSource", "actor_rulership_unknown"),
        ("actorControlledByPlayer", "actor_player_status_unknown"),
        ("targetControlledByPlayer", "target_response_authority_unknown"),
        ("sourceValidPermanent", "source_permanence_unknown"),
        ("targetValidPermanent", "target_permanence_unknown"),
        ("sameRealm", "realm_identity_unknown"),
        ("foreignConflict", "conflict_kind_unknown"),
        ("atWar", "hostility_unknown"),
    ]
    if facts["campaignLoaded"] is not True:
        legality = "unknown"
        reasons.append("campaign_unavailable")
    elif facts["campaignIdKnown"] is not True:
        legality = "unknown"
        reasons.append("save_identity_unknown")
    else:
        hard = [code for key, value, code in hard_blocks if facts[key] == value]
        soft = [code for key, code in unknown_facts if facts[key] is None]
        if facts["storyProtection"] not in {"clear", "blocked"}:
            soft.append("storyline_state_unknown")
        if facts["clientPeaceAuthority"] not in {"clear", "blocked"}:
            soft.append("client_authority_unknown")
        reasons.extend(hard + soft)
        legality = "blocked" if hard else ("unknown" if soft else "allowed_to_propose")

    response = ("player" if facts["targetControlledByPlayer"] is True else
                "npc" if facts["targetControlledByPlayer"] is False else "unknown")
    if response == "unknown":
        reasons.append("target_player_status_unknown")

    if facts["campaignLoaded"] is not True or facts["campaignIdKnown"] is not True:
        readiness = "unknown"
    elif legality != "allowed_to_propose":
        readiness = "not_ready"
    else:
        if facts["nativeGatewayAvailable"] is not True:
            reasons.append("native_gateway_unavailable" if facts["nativeGatewayAvailable"] is False else "native_gateway_unknown")
        if facts["trackedWarExists"] is not True:
            reasons.append("foreign_war_untracked" if facts["trackedWarExists"] is False else "war_tracking_unknown")
        elif facts["trackedConflictKind"] != "ForeignWar":
            reasons.append("wrong_tracked_conflict_kind" if facts["trackedConflictKind"] is not None else "tracked_conflict_kind_unknown")
        readiness = ("ready" if facts["nativeGatewayAvailable"] is True
                     and facts["trackedWarExists"] is True
                     and facts["trackedConflictKind"] == "ForeignWar"
                     else "not_ready")

    terms = facts["terms"]
    if terms is None:
        draft_review = "not_requested"
    elif not isinstance(terms, list) or not terms:
        draft_review = "invalid"
        reasons.append("empty_terms_not_white_peace")
    elif any(not isinstance(t, dict) or not isinstance(t.get("type"), str) or not t["type"] for t in terms):
        draft_review = "invalid"
        reasons.append("invalid_term_shape")
    elif any(t["type"] == "WhitePeace" for t in terms) and (len(terms) != 1 or terms[0]["type"] != "WhitePeace"):
        draft_review = "invalid"
        reasons.append("mixed_white_peace_terms")
    elif facts["trackedWarExists"] is not True or facts["trackedConflictKind"] != "ForeignWar":
        draft_review = "unknown"
        reasons.append("draft_requires_tracked_war")
    elif facts["nativeDraftValidation"] == "invalid":
        draft_review = "invalid"
        reasons.append("native_draft_invalid")
    elif facts["nativeDraftValidation"] != "valid":
        draft_review = "unknown"
        reasons.append("native_draft_validation_unknown")
    elif facts["normalizedTermsMateriallyChanged"] is True:
        draft_review = "invalid"
        reasons.append("material_terms_changed")
    elif facts["warScoreBudget"] is None or facts["usedWarScore"] is None:
        draft_review = "unknown"
        reasons.append("war_score_budget_unknown")
    elif not isinstance(facts["warScoreBudget"], int) or not isinstance(facts["usedWarScore"], int) or facts["warScoreBudget"] < 0 or facts["usedWarScore"] < 0:
        draft_review = "unknown"
        reasons.append("war_score_accounting_unknown")
    elif facts["usedWarScore"] > facts["warScoreBudget"]:
        draft_review = "invalid"
        reasons.append("war_score_over_budget")
    else:
        draft_review = "valid"

    return {
        "legality": legality,
        "executionReadiness": readiness,
        "draftReview": draft_review,
        "responseAuthority": response,
        "mayExecuteImmediately": False,
        "reasonCodes": reasons,
    }


def main() -> None:
    payload = json.loads((ROOT / "fixtures.json").read_text(encoding="utf-8"))
    assert payload["schemaVersion"] == 1
    baseline = payload["baselineFacts"]
    assert set(baseline) == REQUIRED_FACTS
    seen = set()
    failures = []
    for case in payload["cases"]:
        case_id = case["id"]
        assert case_id not in seen, f"duplicate fixture: {case_id}"
        seen.add(case_id)
        facts = copy.deepcopy(baseline)
        facts.update(copy.deepcopy(case["facts"]))
        before = copy.deepcopy(facts)
        first = preview(facts)
        second = preview(facts)
        expected = case["expected"]
        issues = []
        for key, valid_values in OUTCOMES.items():
            if expected[key] not in valid_values:
                issues.append(f"invalid expected {key}={expected[key]}")
            if first[key] != expected[key]:
                issues.append(f"{key} expected={expected[key]} actual={first[key]}")
        for code in expected["reasonIncludes"]:
            if code not in first["reasonCodes"]:
                issues.append(f"missing expected reason={code}")
        if first["mayExecuteImmediately"] is not False:
            issues.append("preflight unexpectedly claims immediate execution")
        if facts != before or first != second:
            issues.append("preflight changed fixture state or produced non-deterministic output")
        if issues:
            failures.append((case_id, issues))
            print(f"FAIL {case_id}: {'; '.join(issues)}")
        else:
            print(f"PASS {case_id}")
    print(f"LLM_OFFER_PEACE_CONTRACT fixtures={len(seen)} passed={len(seen)-len(failures)} failed={len(failures)}")
    if failures:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
