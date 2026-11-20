# S07 — recorded war will and political pressure (source candidate)

Repository AIRebelRelay/BellumCivile. Verified base PR #50, feature/cr-existing-claim-state-2026-11-16, f6d973bdac60bfe06a0a5b7f9acc179cc63e59d0. Additive source work authorized while prior native/live gates await testing. Prior council, war and claim source candidates are preserved. This reads Bellum war-will pressure specifically, not all faction opinion or individual grievances.

## Analysis and boundary established before production edit

ROOT CAUSE: GetWarWill initializes storage and inserts WarWillInitial when the clan has no saved entry; PeekWarWill returns WarWillInitial without exposing whether a value was recorded. GetActivePressureRecords also initializes collections. These gameplay APIs are not broken; a passive integration contract needs explicit absence and detached saved pressure rows.

Call chain: new BellumIntegration.GetExistingPoliticalPressureState -> unchanged RequireCampaignThread -> campaign WarPeaceRevampBehavior -> single new forwarding method GetExistingPoliticalPressureStateSnapshot -> new PoliticalPressureStateReader.Read -> direct TryGetValue on existing _warWillByClanId and read-only projection of existing _pressureRecords -> actual WarWillPressureRecord.IsExpired. Float capture day matches the existing pressure predicate.

GetWarWill/PeekWarWill consumers examined: WarPeaceRevampBehavior daily recovery/pressure application/evaluation/voting/diagnostics, WarScoreBehavior peace decisions, treaty draft/ratification enthusiasm, CourtRally/Protection/Liberation and ClientLiberation proposal/resolve paths, ForeignTreatyBehavior and ClientKingdomBehavior. Existing getters and every caller retain their current semantics. No shared helper/default/scheduler/save semantics change.

TOUCH:
- New PoliticalPressureStateSnapshot.cs (immutable DTO/statuses).
- New PoliticalPressureStateReader.cs (detached technical projection).
- New BellumIntegrationPoliticalPressure.cs (campaign-thread facade).
- Behaviors/WarPeaceRevampBehavior.cs: exactly one six-line insertion, forwarding the two existing stores. Class remains sealed/non-partial. Removing these exact inserted bytes restores the base Git blob. No existing method body is edited.

DO NOT TOUCH: GetWarWill, PeekWarWill, GetActivePressureRecords, EnsureCollectionsInitialized, all scoring/war-will calculations, target ranking/preferences, evaluations, pressure ending/cleanup/retarget, voting, peace/parley, faction mood/relations, individual memories, save schema, previous APIs, CR/Relay/prompts/actions/workflows.

MUST FIX: missing recorded will is null with NotRecorded or RecordsUnavailable; saved zero remains zero; section availability is explicit; active pressure expiry uses actual Native IsExpired (positive expiry at day is expired; zero/negative expiry is non-expiring); amounts keep their signs; no mutable record or private free text/context escapes; invalid/overflow results are never partial complete results.

MUST NOT CHANGE: no Ensure/default insertion/cleanup/recalculation, no clamping of finite source values, no pressure deltas applied again, no NPC knowledge or actions. Existing gameplay getters still behave as before when explicitly called.

Regression contract before implementation: stored/missing/zero will; independently unavailable sections; positive/negative pressure; zero/negative/exact-day expiry; other-clan exclusion; invalid/capacity records; detached copies/source preservation; actual campaign-thread guard and neighboring original getter semantics.

## Contract and limits

Technical clan-scoped API only. It accepts a current Clan object but does not establish that an arbitrary calling actor knows that clan's private state. Future Bridge context must resolve the actor's clan, authorization and CR knowledge before using this output. No prompt/feed/provider registration, logs or diplomacy execution is introduced.

Top-level Recorded means the read succeeded; callers MUST also inspect WarWillStatus and PressureStatus. Either storage can be unavailable independently. Missing will entry is NotRecorded, not WarWillInitial; a missing pressure list is RecordsUnavailable, not known-empty. Recorded pressure + empty means no matching active saved pressure rows. InvalidRecords/CapacityExceeded suppress usable values/rows. Capacity is 128 active matching pressure records; over-capacity explicitly returns count and no partial rows.

Pressure row fields: RecordId, TargetRealmId, ConflictKey, Amount, ReasonType, CreatedDay, ExpiresDay. Reason free text and context hero/settlement/title are absent; future target preferences/ranked targets are never accessed. TargetRealmId/ConflictKey are private technical source identifiers, not permission to broadcast them. A pressure amount is an already applied delta, not a relation penalty, faction reaction, personal grievance, fresh action or number to add to current will. No total is synthesized. LandlessPressureScore belongs to War Score and is not read here.

Null unscopable rows or malformed selected active-flag rows fail closed without repair, including malformed expired selected rows. Ended and other-clan rows are excluded. Raw finite stored will is copied without inventing validity/eligibility or silently clamping it. The reader does not choose a preferred war target.

## Evidence

- 49 named offline cases PASS with C# 7.3 Add-Type. Actual new DTO/reader/facade, WarWillPressureRecord/WarWillReasonType compile unchanged. Actual forwarding/GetWarWill/PeekWarWill bodies and RequireCampaignThread/IsCampaignThread are extracted with checked boundaries into Native behavior fixtures. Full WarPeaceRevampBehavior/game assembly is NOT compiled by this test. Campaign, Clan, behavior storage, option value and SaveableField are boundary doubles.
- Regression: 45 claim-state, 35 war-state, 20 council-state named cases PASS.
- CourtRally, RallyPeaceReadiness and ClientLiberation suites PASS. Rally/readiness includes 8 named math scenarios; other checks are source/XML assertions, not real votes/treaty/client transfers.
- Full diff audit: of 1,557 baseline blobs, 1,556 byte-identical and one exact six-line forwarding insertion. Three new production files; no other production edits/deletions, no debug fallback or defaults/workflow changes. Fixtures remain .cs.txt, not Native compile-glob .cs files. ZIP excludes scratch bin/obj.
- Windows/net472 shipping compilation, Native ABI and live game/save-load validation PENDING; all previous native/live gates remain open. No Actions run requested, merge or release performed.

Offline command from full source ZIP: `pwsh -NoProfile -File .\Tests\ExistingPoliticalPressure.Tests.ps1` (PowerShell 7.2+). This is not the shipping build.

## Live acceptance gates

S07A: compile Native candidate on Windows against actual installed game and Workshop dependencies; identify source pin/DLL versions and preserve full build output.

S07B: on campaign thread compare one real clan's recorded will and pressure records. Expected: stored value copied exactly; missing value stays null/NotRecorded without creating a key; missing stores remain null/unavailable; pressure zero expiry persists and exact positive expiry is excluded without End(). Existing display/evaluation paths may legitimately initialize will when separately invoked; isolate the before/after read check.

S07C: repeated read and save/reload must leave dictionary/list/flags unchanged. Positive/negative recorded pressure must keep signs; reading must never apply Amount again. Check existing recovery, pressure event creation, rally/peace-readiness, client-liberation and vote/treaty paths still work normally. Retargeted/ended records must appear correctly on the next read; older snapshots stay detached.

S07D: no automatic diagnostic log is added for this unregistered API. A future explicit diagnostic consumer should print status, clan, capture day, will/pressure section statuses and count. Unexpected: initial value created by this read, pressure list cleanup, changed will/flags/preferences, inferred grievance or faction mood, raw Reason/context in prompt/feed, partial overflow treated as complete, action or worker-thread access.

S07E: actor/awareness/private context projection and runtime activation remain separate NOT IMPLEMENTED stages. This source API does not finish the diplomacy/events LLM integration or satisfy pending native/live gates.
