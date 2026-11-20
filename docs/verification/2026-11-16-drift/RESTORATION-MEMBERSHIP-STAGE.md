# Restoration membership regression — surgical candidate, not release-ready

ROOT CAUSE: upstream reconciliation commit d7c089182568278321cf3c58366027af0cef6fdf
reintroduced a broad IsRestoredCreationPending(faction.ParentKingdom) skip after
the two exact owned-transfer guards. This undoes the custom P1-01E/F invariant
(previous narrow fix a7a7d39e3bacac4799dc2d301831b2926171ebea): a pending journal
for a parent realm must not freeze unrelated factions, clans or transfer routes.

Call chain: CampaignEvents.OnClanChangedKingdomEvent (registration line 60) ->
FactionManagerBehavior.OnClanChangedKingdom -> per-active-faction guards -> ordinary
ideology/rebel/loyalist handling -> RemoveMember -> empty-faction cleanup ->
new-rebel membership/settlement refresh/ruler repair. The private event listener has
one source registration. The broad helper uses RestoredRealmCreationRecord.Protects,
which checks pending realm identity, not the owner, house or transfer direction.

TOUCH: Behaviors/FactionManagerBehavior.cs, exactly two deleted lines in that
listener; Tests/RestorationMembershipScope.Tests.ps1; this stage documentation.
DO NOT TOUCH: helper definitions, journal fields/save IDs, recovery execution,
CivilWarCrownTransfer, ideology logic, queued loyalist resolution, rebel transfers,
Crown/title legality, UI, Bridge/Relay/CR or drift.
MUST FIX: unrelated transfers reach their original handling while a journal is pending.
MUST NOT CHANGE: owned Stage 2 collapse and owned synchronous restoration remain
protected; inactive/finished journals cannot hold unrelated membership.

Shared-call review: IsRestoredCreationPending is also used by CivilWarCrownTransfer
for actual Crown protection. That consumer and the helper remain byte-identical.
Both exact ownership helpers and their callers remain unchanged. The remainder of
the event listener is byte-identical, including queued loyalist and rebel exceptions
and post-loop side effects. No architecture replacement or new exception introduced.

## Regression contract and evidence

New regression compiles the exact current entry guards, ownership expressions and
Protects expression with minimal types. It deliberately does not pretend to run the
entire TaleWorlds callback. Original source: 5/12 cases RED (inactive journal, foreign
destination, wrong source, other faction, uncaptured clan). After the two-line change:
12/12 PASS. Positive owned restoration/collapse, ready record, ideology, no campaign,
no pending record and later collapse stage retain their expected results.

Recovered original P101E: 35 concrete source/isolated-ownership assertions PASS,
plus its final informational PASS line. P101F: 24 assertions PASS plus final line.
P005: 13 checks PASS. Stage32C: 16 checks PASS. All 227 PowerShell test files parse.
Roslyn syntax parsing of FactionManagerBehavior PASS. Full production diff is exactly
two removed lines; all other shipping bytes are unchanged versus drift candidate.

Repeated read-only source sweep: 129/158 PASS, 29 FAIL. The original 31 failures all
also failed on bf1e019; two recovered parsers account for the change. The remaining
29 are explicit unresolved gates, not silently accepted. Details are saved alongside.

Not performed: full net472 native build, full native harness, save/load, in-game
callbacks, postwar interrupted recovery. SDK 10.0.100 is now available, but complete
matching Bannerlord/dependency DLLs are still absent. No Windows PASS claimed.

## Reproduce and live acceptance

Run Tests/RestorationMembershipScope.Tests.ps1, P101ECollapseClaimantCrown.Tests.ps1,
P101FRestoredHouseholdOwnership.Tests.ps1; then the existing full Windows runner.
In game: exact captured houses stay in their coalition during their owned transfer;
a different clan/faction or foreign move must follow ordinary membership rules even
while another restoration is pending. Verify active rebellion, loyalist queued
resolution, Crown delivery and interrupted save/reload on the same candidate.
No new log marker was added. Validate actual membership and existing recovery logs;
absence of a log line is not proof that an event callback ran.

Do not merge/release. This is an independent candidate; the drift Windows gate
remains pending. No further production stages are started after this change.
