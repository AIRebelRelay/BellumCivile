# S23B — persisted owner-bound intent journal; candidate 1.4.12.5

## Base and authorization

Local cumulative source candidate S23A / 1.4.12.4, based on
AIRebelRelay/BellumCivile feature/cr-realm-preparation-receipts-2026-11-18,
903f6772a8bebab68b1296121d770b741ae1a232 (Draft PR54). Remote branch/head rechecked
unchanged this stage. The previously delivered S23A archive remains untouched.
This is additive development of the authorized controlled-diplomacy architecture,
not a claim to have fixed a demonstrated live-game bug.

The existing S23A source policy, war/peace producer methods and all unrelated
production code remain exact. Historical S23A docs/hash inventories describe
that earlier checkpoint; S23B's new inventory describes this ZIP.

## What is implemented

Three new production files:
- ForeignDiplomacyJournalRecords.cs: independent persisted journal and intent records.
- ForeignDiplomacyJournal.cs: bounded journal, idempotency, immutable evidence views.
- Behaviors/IntegrationForeignDiplomacy.cs: campaign-thread/instance checked internal
  metadata entrypoints, early load invalidation and independent IDataStore key.

BellumIntegrationBehavior.SyncData now invalidates only the new journal session
BEFORE legacy loading and serializes only the new journal AFTER existing legitimacy,
partition and vote sync calls. Original calls and their order/implementations are
unchanged. The early call is necessary when an earlier loader throws.

BellumCivileSaveDefiner adds class IDs150/151 and List<ForeignDiplomacyIntentRecord>.
SaveBaseId8456123, all prior class/enum IDs, container registrations, and prior
record field schemas remain unchanged. Candidate module/file identity 1.4.12.5;
AssemblyVersion stays 1.0.0.0. Four version-only existing files are updated.

### Persisted evidence

Schema version, campaign ID; operation ID, stable request key, owner ID, origin ID,
ordered realm IDs, both ruler IDs, conflict epoch, draft fingerprint, source,
original creation day and cancellation tombstone. Strings and primitive fields
only: no live Hero/Kingdom references, callbacks, tasks, consent or treaty objects.

The caller supplies stable origin/key, epoch and draft identity. No runtime adapter
currently constructs those facts or claims a kingdom pair. This journal records
ownership of an intent, not global authority registration or readiness.

Duplicate matching identity returns the original operation ID, including after
field-copy load. Reusing origin/key with changed owner/pair/ruler/epoch/draft/source
returns Conflict. A retry does not refresh creation day or uncancel an entry.

The runtime session token is never saved. Loading invalidates old tokens even if
an earlier legacy loader or the new data store then throws. Saving preserves the
current token. Every internal entrypoint uses the unchanged campaign-thread guard
AND checks that this behavior instance is the current campaign's instance.

Recovery inventory is detached, read-only, owner-filtered and excludes cancelled
entries. Individual reads may inspect a tombstone. ALL returned snapshots require
world revalidation; Existing/Found never means accepted/applied/executable.

Missing save key initializes an empty journal. Present-null, future schema,
malformed/duplicate/oversize payloads remain quarantined without erasing or
normalizing the original evidence. Tests assume IDataStore false means key absent;
actual engine missing-key/error behavior must be verified during Native save/load.

Capacity is 128 TOTAL records, including tombstones. Full journals refuse new work
without evicting replay protection. Compaction/archival is NOT implemented; do not
enable long-campaign ownership with this finite journal as an unbounded service.

## What remains unimplemented

No gameplay producer calls Begin/Get/List/Cancel. Only the new save lifecycle is
connected. No MCM switch, active ownership handshake, public Bridge API, producer
interception, LLM dispatch, actual world revalidation, ratification, Native execution,
terminal receipt, bounded crisis policy, event/news injection or NPC awareness.
Terminal foreign wars, pacts and hostages cannot be journalled by these new entrypoints.
All current gameplay diplomacy continues as before. No mode is activated.

## Regression evidence

The contract was written and tests prepared before production edits. Initial RED
was the absence of this new feature, not a reproduced save bug.

- 104 C# behavioral assertions PASS. Actual new code AND complete actual shared
  BellumIntegrationBehavior.cs compile together; engine events, behavior manager,
  legacy sync bodies and IDataStore are doubles. Save doubles recursively copy only
  [SaveableField] data; they do NOT invoke TaleWorlds serialization.
- 8 source schema-contract checks PASS, retaining every prior registration/order,
  unique class/enum IDs, exact two additions and one new container.
- 5 journal mutations rejected by behavioral assertions: stale session acceptance,
  lost ruler binding, retry replacing ID, cancelled intent resurrection, retained
  old session after load. Previous policy mutations also still reject all five.
- S23A's actual policy: 65 assertions PASS, production source byte-identical.
- Existing state/receipt fixture suites: political pressure49, war state35, claims45,
  councils20, names36, realm preparation37, all PASS (222 cases, engine doubles).
- CompleteReleaseNaval source contract PASS. This does not prove a Windows build.

Open inherited failure: ModuleLocalLogs.Tests.ps1's packager fixture has no $navalDll.
It was reproduced on unmodified remote base and S23A. This stage only updates the
fixture's two expected-version literals; it does not fix that independent problem.
S23B did not rerun that unchanged failing test body. The cumulative PowerShell runner
includes it, reports failures honestly and will not report a fully green checkpoint.

Windows build NOT_RUN: actual builder was invoked and rejected Linux. No DLL included.
Native save registration/startup, game serialization, old saves, interrupted save/load,
Harmony binding and real diplomacy remain NOT_RUN. Fixture field-copy recovery is
not evidence that engine save/load works. No merge/release/deploy/CI occurred.

## Replacement and acceptance evidence

In-game files to replace NOW: none. No new gameplay log messages are emitted here.
Expected fixture output: JOURNAL TOTAL PASS 104; SCHEMA TOTAL PASS8;
JOURNAL MUTATIONS REJECTED5. Logs are in this directory.

Later Native acceptance must verify: startup registers IDs150/151 without collision;
old save without key loads; journal saved/loaded retains campaign/operation IDs,
owner and exact historical identities; pending inventory requires world revalidation;
stale callback after load/switch is refused; duplicate request/cancel has no new ID;
legacy council/partition saves and actual wars/treaties remain unchanged.
No pending entry may automatically produce peace, spend influence, ratify or become
news. Enablement stays blocked until real world/gateway/crisis/recovery gates pass.
