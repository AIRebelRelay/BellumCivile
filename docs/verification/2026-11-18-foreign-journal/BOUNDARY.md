# S23B — durable intent journal, no gameplay admission activation

ROOT CAUSE: S23A is a stateless policy; no campaign-local persisted owner/operation exists. Retrying after save/load cannot yet distinguish the original intent from a new operation, and in-flight callbacks must not mutate a reloaded campaign session.
TOUCH: new ForeignDiplomacyJournalRecords.cs, ForeignDiplomacyJournal.cs, Behaviors/IntegrationForeignDiplomacy.cs; BellumIntegrationBehavior.SyncData adds an early load-session invalidation call and a final journal serialization call; BellumCivileSaveDefiner adds types 150/151 and List<ForeignDiplomacyIntentRecord>; candidate metadata 1.4.12.5 and metadata-only existing package-test version expectations; new Tests/ForeignDiplomacyJournal* and evidence/docs.
DO NOT TOUCH: S23A policy, legacy SyncLegitimacy/SyncPartitions/SyncVotes implementations, existing save keys/IDs/record fields, execution/treaties/WarScore/WarWill/Harmony, CR/Bridge/Relay/public APIs, pacts/hostages/news.
MUST FIX: owner-bound idempotent creation; persisted campaign/operation provenance; immutable detached projections; stale-session refusal after actual load hook; old-save initialization; malformed/future/duplicate/overflow state quarantine without erasure; no unbounded growth or tombstone eviction; cancellation preserves replay protection. Loading never executes, ratifies or restores consent.
MUST NOT CHANGE: all current gameplay, previous admission policy, native pending treaties, council/partition saves and callbacks. The new live hooks invalidate only the new journal session before load and serialize independent additive metadata after legacy Sync calls. Audit refinement within the same declared SyncData boundary: early invalidation is required even when a preceding legacy loader throws. No MCM/activation/foreign interception.

REGRESSION CONTRACT (before implementation):
- Same owner/key/payload returns identical operation ID before/after field-copy load; altered owner/pair/ruler/draft/epoch/source/origin returns conflict.
- Save includes all identity fields and status; missing key old save creates fresh journal; present-null, future schema, invalid identifiers/source/status, duplicates, missing list, capacity overflow quarantine; do not silently replace corrupted saved evidence.
- Session refreshes on load, not save; stale session/campaign denied for create/read-for-revalidation/cancel; callback must use current behavior and actual campaign thread.
- Read-for-revalidation returns detached historical evidence, NOT a resumed executable command, acceptance or world validation.
- Cancellation leaves tombstone and cannot resurrect or allocate a new operation on replay; capacity refuses safely without evicting identity.
- New save types/fields/container registered uniquely; all existing definitions/IDs remain exact; shared SyncData preserves old calls/order.
- Existing S23A 65 tests + mutation probes and neighboring state/receipt suites remain passing; known pre-existing ModuleLocalLogs Naval fixture failure remains open.

Evidence limits: field-copy IDataStore doubles are not TaleWorlds serialization. New internal queue/read/cancel entrypoints have no gameplay producer or public Bridge caller. Shipping net472 build and actual interrupted save/load remain mandatory before activation.
