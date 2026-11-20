# Bellum 1.4.12.16 — CR Royal Accord (source candidate)

ROOT CAUSE: CR rulers' OFFER+ACCEPT went through Bellum's automatic white-peace willingness and council pre-admission, canceling before treaty ratification. Revalidation would veto again at resolve/apply. This made the NPC decisions non-authoritative.

TOUCH: TreatyProposalRecord (three optional save fields 25-27), ForeignTreatyBehavior (narrow Royal Accord origin + provenance checks + resolve), BellumIntegrationCrDiplomacyGateway, two existing source tests, a new source gate, version/build gate; Bridge 0.2.2 prompt and version/build guard only.

DO NOT TOUCH: existing AI/automatic parley, player parley, civil/claim wars, WarScore scoring, terminal force, shared Native action, council evaluation, hostage/territory execution, feed, Relay, color rendering.

MUST FIX: exact two-NPC-ruler LLM consent queues a non-forced explicit white-peace accord, even if automatic war-will or council willingness disagrees. Council stances and relationship/influence consequences remain; Bellum's existing executor applies it no earlier than the normal next daily settlement tick.

MUST NOT CHANGE: storyline/alliance/client/protected wars, player participation, Revamp OFF, stale/redeclared war, duplicate/pending treaty, save/load, ruler death/abdication after consent, no native peace action outside Bellum, no Feed before Applied.

REGRESSION CONTRACT:
1. Positive: approved Vlandia–Nord accord creates one ParleyPending proposal with IsCrRoyalAccord, exactly one WhitePeace term, explicit war instance and two ruler IDs; normal Bellum executor applies next daily tick and CR publishes only after Applied.
2. Negative: HOLD/COUNTER/REJECT, wrong identity, duplicate/pending, player war, removed signatory, mismatched instance, story/alliance blocks, Revamp OFF -> no treaty effect.
3. Neighbor: ordinary auto white-peace remains bound by mutual eligibility and normal ratification; player vassal/ruler parley and forced terminal settlement unchanged; council stances produce reactions on royal accord.
4. Save/load: optional legacy defaults false; exact royal provenance persists; missing/changed ruler cancels safely before costs.
5. Full diff audit and Windows compile required before game test. Compiling does NOT prove safety or gameplay. Verify BELLUM_CR_DIPLOMACY status=queued and Foreign treaty applied (not bare MakePeaceAction); verify no old mutual eligibility cancellation for royal accord.

**SECURITY LIMITATION OF QA ALPHA:** gateway is callable by another mod; final release must add authenticated source/capability gating before enabling autonomous world-scale issuance. Alpha is opt-in in Bridge and applies only to AI-vs-AI wars with two validated LLM results.
