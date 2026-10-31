# Stage 32C — Native Court policy vote historical NPC recipient roster

2026-10-31. Native-only, source-bound, read-only output. **Not tested in the game and NOT a Court news delivery/authorization release.**

## Git pin and scope
- Repository: `AIRebelRelay/BellumCivile` (Native Bellum; **not** Bellum Bridge and **not** Relay Bridge).
- Branch: `feature/stage32c-native-court-policy-vote-recipient-roster-2026-10-31`.
- Parent verified Stage31L `b3f20677db6a0d00193d3ba05d07617a5df54fc7`; test-first RED `ddbffb86e40c30fd8787f9d7c95565ff09ed6ea4`.
- Native `main` had moved independently by 31 Oct; no rebase, merge, release or DLL replacement performed.

## ROOT CAUSE / call chain
Stage31K source-authored policy vote proof and Stage31F terminal receipt are joined safely by Stage31L, but neither saves **which specific Hero.StringIds belonged to that vote's audience**. Re-reading `realm.Clans`, current faction members or current clan heads later gives the wrong historical actors (membership/leadership can change).

Existing relevant execution:
`KingdomElection.ApplyChosenOutcome` prefix → `KingdomVoteAlignmentTracker.Capture` captures `possibleOutcomes` supporter clan keys (including opposition and neutral entries) → `KingdomPolicyDecision.ApplyChosenOutcome` → `PolicyVoteResolutionPatch.Postfix` → `CourtAgendaBehavior.Conclude` writes Stage31K explicit vote proof. The outer election postfix later clears the temporary vote snapshot.

Stage32C appends a read-only accessor to the pre-existing vote snapshot and captures historical **clan leaders' exact Hero.StringId at concluded vote time** only after verifying the Stage31K proof for that exact `IntegrationId`. Capture is held for missing/non-Court/invalid/mismatched proof, missing ballot, ambiguous actor, overflow or exception. It does not change vote outcome, political alignment, mood, relations, costs or election scheduling.

## CHANGE BOUNDARY — TOUCH
1. NEW `Behaviors/CourtPolicyVoteAudience.cs`: Native-only `Dictionary<string,string>` versioned roster with 1024 immutable IDs and persistent overflow; actor identities encoded separately as strict base64, canonical sorted and unique. Read side joins **only** Stage31L verified receipts and exact realm/policy/sponsor/vote day. Missing legacy audience holds that one result; corruption/conflict/overflow/unhealthy Stage31L empties all results.
2. NEW `CourtPolicyVoteAudienceJoinSnapshot.cs`: immutable per-result `HeroIds` and health counters, explicit `Audience=realm_court`. Does not announce or mark delivery.
3. `Patches/KingdomVoteAlignmentTracker.cs`: one additive read-only `TryGetRecordedParticipants`; does not modify Capture/GetAlignment/Clear or live vote decisions.
4. `Patches/PolicyVoteResolutionPatch.cs`: one call after `Conclude`, no mutation of existing resolution behavior.
5. `Behaviors/CourtAgendaBehavior.cs`: one additive SyncData call, reuse already registered `Dictionary<string,string>` save container.
6. `BellumIntegration.cs`: new campaign-thread-gated read-only `GetCourtPolicyVoteAudienceJoin` endpoint. Existing API semantics unchanged.
7. NEW `Tests/Stage32CCourtPolicyVoteRecipientRoster.Tests.ps1`; this handoff.

## DO NOT TOUCH / MUST NOT CHANGE
- Stage31F/G/K/L original proof/receipt schemas and readers, Court original `Conclude`, `GetObjective`, vote patches' existing semantics, the election outcome, influence, moods, faction reactions, W7 public `policy_enacted|policy_repealed`, social memory.
- `BellumCivileSaveDefiner` IDs/registrations, other Native votes, public events, personal notifications, sidecar, bridge ACK, AII event memory, Relay request/response, Relay Bridge or Bellum Bridge.
- No new Harmony patch, no second reader that guesses a fresh historical audience, no full-realm or faction-based recipient inference.

## Source-specific policy
- Eligible records are **exact clan leaders of clans represented in the pre-resolution Native ballot snapshot** at the vote's conclusion, including neutral/abstaining entries, once each. They must be valid realm clan heads at capture. Being a realm subject, faction member, relative, former/next ruler, or scene participant alone does **not** confer this private audience.
- This is evidence of a recorded electoral audience, **not proof of physical attendance or an in-world message already received**. Nor is it proof of their vote choice.
- Missing ballot or empty roster => no new proof; no fallback to winning side only, current `Kingdom.Clans`, sponsor or Crown guesses.
- Old saves without the new recorded roster are held; there is intentionally no retroactive audience reconstruction.
- Capture is immutable by exact `IntegrationId`. Later marriage, clan transfer, death or ruler change does not rewrite the historical IDs.
- New reader yields a candidate audience only when the older Stage31L `Matched` result joins on exact `IntegrationId`, realm, policy, sponsor, audience and identical vote day. No result before receipt eviction.

## Regression contract — written before code
Positive:
1. One Court policy vote, valid Stage31K proof, captured pre-result ballot with two opponents + neutral actor → same three `Hero.StringId` values, sorted and deduplicated, persisted across save/reload.
2. Stage31F terminal eviction and Stage31L valid match → exactly one matching recipient projection; two separate vote IDs for the same policy stay separate.
3. After roster capture, clan leader/realm membership changes → original Hero IDs remain; repeated read is non-mutating.
4. Existing unrelated vote mechanics, result shock, tie/ruler selection, unrelated election `GetAlignment`, `Clear`, W7 announcements and other Native APIs retain behavior.

Negative:
1. No Stage31K proof, stale/old save, missing active ballot, duplicate/invalid Hero IDs, empty ballot, wrong realm/sponsor/policy/outcome → held, never guess recipients.
2. Mispaired terminal receipt, missing terminal, flipped day, cancelled/technical cases → no recipient projection.
3. Malformed/mismatched version, GUID, UTF-8/base64, ordering, oversized roster/payload, corruption and overflow → fail closed. Duplicate save ID cannot overwrite prior roster.
4. Event or other user's `Hero.StringId` not on exact historic roster never gets private fact authorization.
5. New API cannot authorize/publish, cannot persist NPC memory or send private data to Relay.

## Evidence and outstanding gates
- Only the four existing production files have pure additive modifications (verified source diff against Stage31L; no old line removed).
- 14 targeted static invariants checked through GitHub-fetched source: passed. New test file was committed **RED before the first implementation**.
- **PowerShell test not run** (no `pwsh` available in authoring runtime); no `dotnet`/MSBuild/.NET Framework Bannerlord reference assemblies or game runtime. No DLL build, no save-load, no verified live vote, no NPC memory evidence.
- Need execute `Tests/Stage32CCourtPolicyVoteRecipientRoster.Tests.ps1` and the Stage31K/L source suites; a full .NET 4.7.2 Bannerlord build; real passed/defeated policy voting with opposing and neutral clan heads; save/load; terminal eviction; compare in-game roster with actual recorded voters. Then run legacy vote/relations/W7 regressions.
- Expected **new** Native log: `BC_COURT_POLICY_AUDIENCE status=recorded; id=...; realm=...; count=N; result=passed|defeated; audience=realm_court; relay_emitted=false; npc_memory_mutated=false`.
- Expected holds: `BC_COURT_POLICY_AUDIENCE status=held; reason=missing_recorded_ballot|missing_or_mismatched_native_vote_proof|...; relay_emitted=false` or `status=overflow`. Existing `BC_COURT_PUBLIC_PROVENANCE status=recorded|held|overflow` and `BC_COURT_TERMINAL_EVICTION ...` remain.
- Must NOT appear: private Court event published, `authorized=true`, changed vote result, altered influence or AII `DynamicEvents[]` attributed to this stage.

## Next single stage (not started)
Stage32D: Bellum Bridge → Relay restricted private delivery. Must independently prove trusted game-origin ingress plus the Stage32B request-local candidate, Stage31L healthy source, Stage32C exact Hero ID in historical audience for the specific event, same campaign, per-event idempotency and persistence. `RealmCourtSpeakerCandidate.authorized=false` remains until this complete check; do not treat Stage32C read-only roster alone as authorization. Stage32E must then verify named NPC memory in game. Issue #91 3 Nov 12:00 Kyiv is **not yet release GO**.
