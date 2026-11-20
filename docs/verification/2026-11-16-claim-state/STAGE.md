# S06 — existing clan claim state (source candidate)

Repository AIRebelRelay/BellumCivile. Analysis started against council source b7b03265a1ec98922b3f16812d3aee0f1044e539 / PR #48. Packaging base is verified current war candidate PR #49, feature/cr-existing-war-state-2026-11-16, 7c31ecba800374d50859b7fb8ebf7a9cc90ce1f6. All 1,544 tracked base blobs are byte-identical: existing council and war APIs/evidence are retained. This is an additive, unactivated source stage while previously authorized native/live gates remain pending; no merge/release or ownership change.

## Analysis and change boundary

ROOT CAUSE: GetAllClaims/GetActiveClaims initialize collections and return mutable saved rows; GetActiveClaimsByClan also consumes rebuilt claim indexes. They remain valid gameplay APIs, but cannot serve as a detached, non-materializing integration contract. IsClaimCurrentlyActive rejects inactive/expired claims and hereditary claims whose current carrier (fallback SourceHeroId when carrier is empty) is barred. Expiry <0 is indefinite, expiry=0 is expired at current time. No private source provenance should be copied to public feeds or all NPCs.

New chain: BellumIntegration.GetExistingClaimState -> existing RequireCampaignThread -> campaign FeudalTitleBehavior -> new GetExistingClaimStateSnapshot -> direct authoritative _claims/_titlesById reads -> unchanged IsClaimCurrentlyActive -> IsHereditaryClaim -> BellumIntegrationBehavior.IsBarredId. Snapshot capture uses Native float-day precision, matching the existing active predicate. Campaign-thread reads do not advance simulation time.

Existing consumers examined: GetActiveClaimsByClan feeds title display, dynamic relations, treaty drafting/ratification, foreign policy and target scoring, ClaimFeud, partition/abdication capture, war will and title usurpation. GetActiveClaims and shared predicates also feed claim normalization and carrier relocation. Their implementations, indexes, mutation and calling semantics remain untouched. No code is copied from AI Influence.

TOUCH: three new production files only:
- ClaimStateSnapshot.cs: detached immutable snapshots, statuses, target-state enum.
- BellumIntegrationClaimState.cs: campaign-thread technical facade.
- Behaviors/FeudalClaimIntegrationState.cs: read-only partial FeudalTitleBehavior projection.

DO NOT TOUCH: existing getters/predicates/indexes, grants/renunciation, succession/legitimacy decisions, title ownership, war score/parley, political pressure, Native save schema, council feed/context, CR/Relay/prompts/actions.

MUST FIX: restrict saved rows to requested current clan; preserve Native active/expiry/legitimacy semantics; distinguish active/missing/inactive/dissolved/unavailable target records without manufacturing title rights; reject corrupt selected data, unscopable null rows or over 128 active claims without partial results; copy no mutable records.

MUST NOT CHANGE: no Ensure/init, index rebuild, duplicate normalization, activation/expiration writes, target repair, memory/news/LLM calls or gameplay actions. Distinct saved claim IDs to one title are retained as recorded, not normalized or ranked into an inferred winning right.

Regression contract set before production edit: exact expiry boundaries and missing data; barred hereditary carrier/source fallback and nonhereditary neighbor; all hereditary source labels and generation depth; other clan exclusion; detached collection/object scope, malformed records, capacity and campaign/thread guard; neighboring war/council and claim-consumer source contracts.

## Contract and privacy limits

GetExistingClaimState(Clan) is a trusted mechanical API, NOT a player/NPC authorization or knowledge API. It scopes records to its requested clan but does not establish that a calling NPC knows those records. Future Bridge projection must resolve the actor's actual clan and apply CR awareness/private scope. No prompt provider/feed registration is added.

ClaimRecordSnapshot contains only ClaimId, TargetTitleId, Strength, CreatedDay, ExpiresDay and TargetState. No source text, fabrication provenance, carrier/source hero IDs, origin clan, title names or holder claims are exported. A claim is not ownership; TargetState.Active is not sufficient permission to enforce it. Recorded+empty is no matching active saved claims, not proof that a house has no possible rights.

Missing title collection => RecordsUnavailable; missing/null dictionary entry => Missing; deliberately dissolved => Dissolved (even if active flag is inconsistent); otherwise active/inactive. A mismatched dictionary key/title ID => InvalidRecords. Missing/inactive targets do not silently erase a saved active claim. Complete results are available only with Recorded status; capacity/malformed data must not be read as empty complete state.

## Validation

- 45 named offline cases PASS under C# 7.3 Add-Type. Actual FeudalClaimRecord/FeudalTitleRecord/enums and FeudalLegitimacyClaims compile unchanged. Active predicate, CurrentDay, IsBarredId, RequireCampaignThread and IsCampaignThread are extracted from current production source with checked boundaries. Campaign/Clan/Hero/behavior storage/SaveableField are boundary doubles. Worker-thread rejection exercises the extracted actual guard; this is still not game ABI proof.
- Existing war-state 35 named cases PASS and council-state 20 named cases PASS.
- CrownClaimCarrier and CourtClaimObjective source/XML contracts PASS. These are source assertions, not Native transfers or save/load proof.
- Full diff audit: all 1,544 base blobs unchanged; three declared production additions; .cs.txt fixtures excluded from normal Native compile glob; source ZIP excludes scratch bin/obj. No temporary debug hooks, workflow or default changes.
- Windows/net472 shipping compilation, actual Native ABI and live game/save-load checks PENDING. No Actions run, shipping DLL, merge or release is claimed.

Offline command from full source: `pwsh -NoProfile -File .\Tests\ExistingClaimState.Tests.ps1` (PowerShell 7.2+). This is not a Native shipping build.

## Runtime evidence required

S06A: build the Native source candidate with actual installed game references and specified Workshop dependency DLL paths. Preserve full output and identify source commit/DLL versions. Do not use offline Add-Type success as the build gate.

S06B: on campaign thread, compare technical snapshot to saved claim/title state for one clan. Expected: exact ClanId/day, only that clan's active rows; expired-at-day/expiry-zero and barred hereditary carrier excluded; eligible current carrier retained even if its source hero is barred. Nonhereditary barred person keeps existing semantics. Missing/inactive/dissolved target flags do not award ownership.

S06C: repeat reads/save/reload, carrier relocation and legitimacy change. Snapshot must reflect current eligibility on the next read; old snapshot stays detached. Source collections, indexes, claim flags/holders and council/war behavior must not change from reading. Verify actual claim displays, allocation, succession and treaty paths continue working.

S06D: expected absence: no new news, NPC memory, diplomacy action or automatic API log is emitted. API is unregistered. A later diagnostic consumer must explicitly print status/scope/count/target state. Unexpected: initialized collections, normalized claims, wrong clan rows, private provenance in prompt/feed, title possession inferred from claim, silent overflow or worker-thread read.

S06E: actor/knowledge projection and political-pressure snapshot remain NOT IMPLEMENTED. Existing S03–S05 native/live gates remain open. War will missing-value and distinct expiry semantics are still next-stage analysis, not part of this patch.
