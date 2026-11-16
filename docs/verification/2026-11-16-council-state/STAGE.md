# Existing council state API — independent additive candidate

Source base: custom Bellum 73f53ededb351c50928104612cbffc61e795145b. No merge/release. Native Windows and actual game validation of the base and this candidate are pending; the user explicitly authorized independent work while build tests wait until around noon on 16 November 2026.

## Root cause / call chain

A future read-only CR context reader cannot safely call PrivyCouncilBehavior.GetOfficeRecords: on missing records it invokes EnsureCouncilForKingdom -> creates PrivyCouncilOfficeRecord entries -> SeedInitialCouncil (may appoint initial holders) -> assignment initialization/review scheduling -> legacy controversy migration. GetOfficeRecord/GetOfficeHolder can reach the same initializer. No claim is made that these existing Native getters are gameplay bugs; they are unsuitable as a passive observer door.

## Boundary

TOUCH: three new production files only: CouncilOfficeStateSnapshot.cs, BellumIntegrationCouncilState.cs, Behaviors/PrivyCouncilIntegrationState.cs. New isolated test script and .cs.txt fixtures, plus this evidence.
DO NOT TOUCH: existing PrivyCouncilBehavior methods, caches/indexes, assignments, initialization, appointment/vote/economic behavior, save keys/types, Bridge council-feed code, CR, Relay or Relay Bridge.
MUST FIX: a new passive public door that copies only already-stored council rows without creating, repairing, pruning, resolving holders or updating any record/index.
MUST NOT CHANGE: behavior of any existing getter/caller; reading missing data must not claim a vacant available office or a nonexistent council.

## API

BellumIntegration.GetExistingCouncilState(Kingdom realm) -> CouncilOfficeStateSnapshot (ApiVersion=1), campaign thread only. Snapshot properties: RealmId, CapturedDay, Status, Offices and HasAllOfficeRecords. Each detached row exposes exactly RecordId, RealmId, Office and RecordedHolderClanId. The collection is read-only and contains no live Native object or mutable saved record.

Statuses distinguish Recorded, NotRecorded, UnavailableRealm, BehaviorUnavailable, UninitializedRecords and InvalidRecords. Missing/partial data never synthesizes offices. Duplicate office, corrupt record ID and unknown enum produce InvalidRecords. Uninitialized rows do not trigger seeding. Existing private IsEligiblePermanentRealm remains unchanged and guards eliminated, temporary rebellion/feud and superseded empty shells. New internal reader scans _officeRecords without invoking existing materializing getters or cache helpers.

RecordedHolderClanId is a copy of the saved holder field, NOT confirmation of current holder eligibility, real-time competence, authority, availability or appointment success. Empty recorded holder is not permission to fill the office. HasAllOfficeRecords only means one recorded row for every enum member; locked advisor records can exist, so it does not mean every office is unlocked. A future actor-scoped CR adapter must separately establish knowledge/authority/visibility and must not turn this raw state into omniscient NPC context. No CrPrompt variable registration, prompt changes, events, memory injection or gameplay execution are wired in this stage.

Callers: the only new production call is the public facade -> new internal reader. No existing consumers are redirected. IsEligiblePermanentRealm and BellumKingdomVisibilityHelper are read-only existing predicates and remain byte-identical.

## Regression contract / evidence

20 named cases PASS with actual new DTO/reader/facade sources, actual PrivyCouncilOfficeRecord, enum and BellumKingdomVisibilityHelper. The exact existing IsEligiblePermanentRealm body is extracted into an isolated partial fixture. Campaign/entity/thread/service boundaries are doubles, not the real Native runtime.

Cases: complete sorted snapshot; missing and null lists unchanged; null/eliminated/temporary/superseded realms; partial records without synthetic offices; uninitialized record unchanged; duplicate office/corrupt identity/unknown enum rejection; detached result after source mutation; immutable collection; exact public field allowlist and full private-field fingerprint unchanged; empty holder without vacancy eligibility; other-realm/null rows not leaked or pruned; missing behavior; required campaign-thread gate; captured-day independence and NaN rejection.

All pre-existing files were compared byte-for-byte to the published 73f53ede ZIP: zero changed. Only three new *.cs production files are added. Fixture sources use .cs.txt, copied to temporary *.cs only during the test, so the Native project's default compile glob cannot ship fake TaleWorlds types. No project file or save definer changes required. The new PowerShell test parses.

Run from this candidate source root with PowerShell 7.2+:

```powershell
pwsh -NoProfile -File .\Tests\ExistingCouncilState.Tests.ps1
```

Native validation still required: compile this branch with the real 1.5.7+ references; call the public door on campaign thread for an existing and not-yet-recorded realm; compare office records/holders/assignments/controversy and save state before/after repeated reads, save/load and the independent council-feed path. An observer must not generate council creation, appointment, assignment or political-change notifications. Then resume actor-scoped CR context wiring as a separately bounded stage.
