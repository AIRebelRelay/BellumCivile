# Native realm preparation receipt — candidate 1.4.12.3

18.11.2026. Source candidate, not a release. Base: Native PR53 branch `fix/cr-module-local-logs-2026-11-16`, HEAD `452c57b5b19e938c2a2d51d015b53194ad612999`. Re-read current PR/head and recent logger/version commit; older main was not substituted. This is an additive local source feature, not another upstream port. The existing 1.4.12b port is retained.

## Root cause and callers

`CreatedNotified` is saved before KingdomCreated callbacks; a callback may throw or invalidate the successor before `Ready`. Neither flag includes a detached identity/day. `Ready` ends preparation only: parent-collapse and succession callers continue rewards, Crown legalization, faction cleanup and CompleteWarOutcome. The source fact exposed here is **realm_prepared**, never “war/claimant settlement completed”.

Reviewed chain: HandleParentCollapse/CreateRestoredSuccessorKingdom; ResumeChallengeOutcome; TryRepairEliminatedKingdomWithLiveState/CreateRestoredReplacementKingdom; hourly ResumePendingRestoredCreations. The single production Ready assignment is in PrepareRestoredRealm. The list is allocated/appended there, synced under BC_RestoredRealmCreations and null-initialized in SyncData; no production removal/clear writer was found. LandlessRealmRecovery, household/drain/retirement guards and RealmLeadershipDiagnostics also read it. Those consumers remain byte-identical.

## Boundary, fixed before implementation

TOUCH: RestoredRealmCreationRecord adds primitive saved fields 18–27; RestoredRealmRecovery adds one call after Ready/challenge flag; new RealmPreparationReceipt.cs, Behaviors/RestoredRealmPreparationState.cs and BellumIntegrationRealmPreparations.cs. Version metadata advances to 1.4.12.3 / alpha.3, stable AssemblyVersion retained. Windows packager version checks and its fixture follow the new identity; force-launch command is included. New receipt fixtures/runner and the existing exact-count P101B schema test are the test boundary.

DO NOT TOUCH: existing fields 1–17, save key/class ID 137/container registration, transfer ownership, callback order, Crown/peace/settlement/recovery semantics, Native integration guard, other APIs, logger, optional Naval project, Bridge/CR/SDK/Relay, prompt/routes/activation.

MUST FIX: new preparation completion produces saved ID/day and historical source IDs; passive reading cannot manufacture past news. MUST NOT CHANGE: mechanical completion/retry, callbacks, deferred transfers or previously working integrations. No source-receipt metadata failure may undo successful preparation.

## Implementation contract

- The exact terminal block sets Ready, clears Failure and marks challenge.RestoredRealmReady as before, then attempts a receipt with no new campaign callback. A pre-existing Ready record exits before this call. No backfill or today-stamping old saves.
- Capture reads/validates/allocates before primitive writes; saved receipt ID is the final marker. A GUID is persisted once per source record, not reconstructed from names/day/ruler. Exceptions are contained. This is not a claim of storage atomicity or exactly-once across arbitrary engine save behavior.
- Fields 18–27 store ID, day, parent/source/successor realm IDs, founder/ruling house IDs, optional verified living ruler ID, replacement kind and optional challenge ID. Founder is not assumed to be ruler. No mutable engine object appears in the public receipt.
- Existing source record/list registration suffices because all added fields are already supported primitive types. No new save type/container ID is allocated. Actual old-save compatibility remains a required native test.
- `BellumIntegration.GetRecentRealmPreparations()` uses the unchanged production campaign-thread guard and reads only existing records. Snapshot API1 provides status, capture day, a read-only list and counts for undated Ready, pending, and omitted records. NotRecorded is not “no restoration ever occurred”.
- Up to 100 valid receipts, ordered by completion day then stable ID. Underlying source history is not compacted/deleted. Invalid/future/duplicate/noncanonical ID or partial stamps fail the batch closed as InvalidRecords; corrupt state is not silently repaired. Missing behavior is explicit. Optional unknown ruler/challenge is empty.
- No live caller, poller, public proclamation, Feed write, actor memory, NPC awareness or action authority is added. A later Bridge adapter remains blocked on this candidate's native gates.

## Regression evidence

- Before.log: original saved record compiled with boundary doubles, then failed the missing receipt-field assertion. This proves the schema gap, not a reproduced game failure. A first invalid probe using a .txt extension was discarded; Before.log is the subsequent compiled probe.
- **37 named isolated cases PASS**, actual new capture/DTO/reader/facade and actual saved record, extracted current post-transfer KingdomCreated-through-return slice and actual campaign-thread guard. Doubles stand in for engine properties, behavior lookup, clock, event dispatcher and eligibility. Callback throw/invalidation cannot reach Ready/stamp; retry dates the later successful completion. Full transfer/recovery method is not executed.
- Other cases: old Ready remains undated; pending completes later; distinct receipts for separate records with identical entity IDs; duplicate/future/corrupt/partial source rejection; missing behavior/campaign/integration; worker denial; historical strings survive live ruler/house changes; day zero; bounded projection and primitive-only public shape.
- “Save-field copy” copies all actual attributed fields into a new record; it is **not** TaleWorlds serialization or a save-file test.
- P101B, P101E and P101F PASS. P101B originally failed its exact count=17 contract after this intentional schema extension; it now checks unique 1–27 and separately verifies each original 1–17 type/name. No old assertion about recovery/ownership was removed.
- Existing council 20 and recorded-name 36 named cases PASS. RestoredRealmRecovery source contracts and module-local logger/package 13 fixture checks PASS. Package fixture exercises full folder creation with a synthetic managed DLL, not a native build.
- All new C# files and actual saved record compile together under C#7.3 via PowerShell Add-Type. Full net472 project/game ABI compilation is NOT RUN.

## Full diff audit

Against the pinned ZIP: exactly seven existing files changed (record, terminal hook, AssemblyInfo, module XML, version-only build script plus launch comment, module-package fixture, schema test); three new production files plus tests/docs/evidence. No removals. 1,584 pre-existing files are byte-identical, including SaveDefiner, all shared guards, challenge/collapse settlement and logger. Test fixtures use .cs.txt and are not compiled into the game assembly. No Actions run, release, merge, deployment or branch promotion.

## Open gates and expected evidence

1. Full native Windows/net472 build with documented game/Workshop refs. Attempt here stopped at the Windows environment preflight (WindowsBuildGate.log), before creating output. Existing full module builder is kept; it produces Modules/BellumCivile with XML/bin/logs/assets and does not deploy. Optional Naval companion is outside this core builder.
2. Real old save: Ready rows have no receipt/date; a pending old row completing after upgrade receives exactly one source receipt. Save/reload preserves ID/day/historical actors. No fabricated today event.
3. Real callback exception/save-inside-callback, household-transfer pending, title unavailable and source retirement pending. Verify recovery retains original behavior; only actual Ready transition can add source evidence. No new automatic receipt log is implemented: a controlled diagnostic consumer must inspect snapshot status/counts/IDs.
4. Real completed preparation with later political settlement deferred: receipt may exist, but no settled-war/peace assertion or event. Ordinary non-restoration kingdom creation, landless protection, unions/clientage, Crown and collapse recovery must remain functional.
5. Receipt metadata capture failure leaves Ready success and an undated count; malformed stamp yields InvalidRecords/no payload. Engine save behavior during allocation and future save rollback are still native evidence gaps.

From extracted ZIP root, isolated runner: `pwsh -NoProfile -ExecutionPolicy Bypass -File .\Tests\RealmPreparationReceipt.Tests.ps1`.
Full Windows command is in scripts/Build-CrBellumModuleWindows.ps1, using the user's F: paths and a fresh output directory. No DLL replacement is requested before those gates. This candidate must not be merged/released on offline PASS alone.
