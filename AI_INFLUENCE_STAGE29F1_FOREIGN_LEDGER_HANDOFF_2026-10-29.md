# Stage29F1 — AII-owned ForeignWar ledger without Native autonomous diplomacy

Date 2026-10-29. **Native source patch committed test-first; source diff inspected; NOT compiled, unit-tested in .NET, CI-tested or game-tested. This feature is NOT yet live or integrated with Bellum Bridge.**

## Pinned HEAD and design

- Native Bellum 1.4.5 repository `AIRebelRelay/BellumCivile`, source baseline `feature/stage27b-unified-native-leave-provenance-2026-10-26@64b0005ba36f0697ab667a3c29767ed78ce782fc`; native main `b1d9a4e8fb74d4f9dd045793c156abeac6f9f4eb` is **56 commits behind** this baseline. No merge, no release.
- Native feature branch `feature/stage29f1-ai-owned-foreign-ledger-native-2026-10-29`. Keep Relay Bridge (`ai-rebel-relay-bridge`) fully separate from Bellum Bridge.
- User-selected Bellum `War & Peace Revamp OFF` means AI Influence 6.0.2 / LLM owns strategic foreign decisions; Native Bellum handles law, accounting and eventual consequences, but not autonomous foreign peace.
- Stage29F/29E source-tracing reports in Bellum Bridge `audit/stage29f-war-ledger-no-autonomy-proof-2026-10-29@b6a643c206a0e9f38820610d1a7d7301a362bc2f`.

## ROOT CAUSE and exact call chain

Native `WarScoreBehavior.OnWarDeclared → ShouldTrackForeignWar → CanRegisterConflict` cannot create a ForeignWar score while Revamp OFF. Existing `WarScoreBehavior.OnDailyTick → ProcessQueuedTerminalResolutions → ResolveQueuedTerminalWarScore → TryQueueAiParley(forced:true)` **falls through** on a failed queue to `ResolveTerminalConflict(ForeignWar) → MakePeaceAction.Apply`, so simply enabling generic score registration would create spontaneous peace. `ProcessActiveWars`, battle/raid/occupation/prisoner callbacks are shared with civil/claim-feud states and native May-October settlement fixes. `ReconcileExistingWars` randomly infers old attacker. None of these can be globally overridden.

## TOUCH / DO NOT TOUCH / MUST FIX / MUST NOT CHANGE

**TOUCH 4 source+test files, plus this handoff**:

1. `Tests/SuccessionEngineHarness/AiInfluenceForeignLedgerTests.cs` **committed first**, tests exact source marker, nonforeign exclusion, native opt-in, terminal threshold, saved pending, ordinary foreign OFF vs ON policy, unchanged civil-war terminal semantics, existing `SaveableField(17)`.
2. `Behaviors/WarScoreAiInfluenceForeignLedger.cs` new **partial** of `WarScoreBehavior`. Only public entrypoint `TryRegisterAiInfluenceForeignWar(Kingdom attacker, Kingdom defender, string aiEventId, out string report)`, which requires actual current hostile stance, two different valid permanent kingdoms, Revamp OFF, exact nonblank event ID ≤128, active-pair absence or same-event idempotency, old-event replay prohibition. Logs exact attacker, defender, ID and `accounting_only=true`. **Does not declare war, make peace, change treaty, or receive raw LLM text.** Source authority for the event ID must be proved later by the exact Bridge/W1 integration caller: the C# method itself only validates an ID's form, uniqueness and in-game situation; it cannot verify the origin of a caller-supplied ID.
3. `Behaviors/WarScoreBehavior.cs` limited additions to OFF-aware exact AII foreign scoring (new registered records only) for real battle/raid/occupied fiefs/prisoner/ticking data, plus nonautonomous reconciliation and **three foreign-only terminal gates** (`QueueTerminalWarScoreResolution`, `ResolveQueuedTerminalWarScore`, `ResolveTerminalConflict`). Internal `CanRegisterConflict` and `IsRevampEnabled` remain **byte-for-byte unchanged**, original public Native war/peace event registration unaffected. Existing `OnMakePeace` still closes exact score. Legacy restored ForeignWar terminal under OFF now clears unsafe terminal without making peace. Civil/claim-feud still use previous terminal path. Source score updates never grant treaty execution authority.
4. `Tests/SuccessionEngineHarness/Program.cs` adds `--ai-foreign-ledger` option running new focused tests and existing `ReversibleWarScoreTests`, also adds new tests to default harness suite.

**DO NOT TOUCH** `WarScoreRecord.cs`, save type ID definition, Native `WarPeaceRevampBehavior`, `ForeignTreatyBehavior`, MCM/defaults, native Harmony voter/declaration patches, `CourtProtection`, `ClientKingdomBehavior`, `SubModule`, existing civil-war mercenary settlement Oct 12 code, all Relay/Bridge source, current AII fallback peace, Unity/game data or live saves. No new save key: Native already stores `WarScoreRecord.ContextId` as `SaveableField(17)`; only a reserved tag `aii_foreign_ledger:v1:<AII event ID>` distinguishes accounting-only foreign records.

**MUST FIX:** Native can *explicitly* register, track and reload AII-authorized hostility under OFF and cannot autonomously ratify parley, force white peace or call MakePeaceAction on it. No registration automatically from ordinary `OnWarDeclared`. No random backfill, no legacy OFF surprise settlement.

**MUST NOT CHANGE:** Native civil/feud terminal, protected client liberation and bloc, old save schema, AII W1 and original native fallback on OFF, player/vanilla foreign policy, Bhelogan 5.1.9 provider/session/TTS, Court foreign-pressure freeze #85, ExpelClan P0 #88.

## Exact source code logic

- Permanent foreign war validated via existing `IsValidPermanentKingdom` and `IsForeignWarPair`; requires `IsAtWarWith` **before** recording, and checks the direction supplied by the exact Bridge caller.
- Saves source ID in existing `WarScoreRecord.ContextId`, and an initial snapshot in the original Native `_wars` list (`BellumCivile_WarScore_Wars`), so old saves remain valid and replayed event IDs can be rejected by scanning old records. Same current event/actor/pair is idempotent.
- Existing event callbacks for `MapEventEnded`, `VillageLooted`, `HeroPrisonerTaken`, `OnSettlementOwnerChanged` run under OFF **only when a saved AII foreign ledger is active**, and mutate only that exact record. Existing `HostageCustodyGuard` respected.
- Daily scoring for AII foreign ledger uses `UpdateOccupationScore` and `ApplyTickingLeverage` but explicitly **skips** `TryForceFullOccupation`, `ApplyLandlessRealmPressure` and Native `QueueTerminalWarScoreResolution`. There are additionally three guards against terminal queue/resolve/final foreign `MakePeaceAction`, including old queued terminal records under OFF; no change to CivilWar or ClaimFeud.
- Old `ReconcileExistingWars` random aggressor branch stays OFF when user revamp OFF. A new specific `ReconcileAiInfluenceForeignLedgers` only closes records after the actual war stance ends, realm disappears or the pair ceases to be lawful, and clears stale terminal queues. It never originates or finishes hostilities.
- Existing Bellum Bridge `BridgeV1SourceBackedForeignTreaty.Runtime` has a separate OFF execution-owner fallback; **even when this ledger becomes wired into the Bridge**, that Bridge route must explicitly distinguish accounting-only records from executable native Bellum treaties. Presence of a `WarScoreRecord` is NOT ratification/authorization.

## Regression contract and implementation checkpoints

**Unit tests committed FIRST** in `6dbef8bff7d3e0bb46be76d4ddc888e47b2d902f`, with expanded legacy-OFF terminal regression before modifying that second terminal guard in `0b14a6da60139cc81a53a1c8bf62369aa681ae4f`. New `AiInfluenceForeignLedgerTests.Run` covers context marker, foreign-only privilege, null source, immediate score100 never terminal, saved pending cleared, foreign OFF vs ON and civil terminal unaffected, persistence field exists. **No .NET test was executed on the model host**: no dotnet/pwsh/GameFolder installed and GitHub Actions intentionally NOT triggered for every small commit.

Source static audit (not a substitute for tests): four expected C# files, 17/17 direct source/path invariants PASS. Original `CanRegisterConflict`, old `ReconcileExistingWars`, `ForeignTreatyBehavior`, `WarPeaceRevampBehavior`, C# save schema, Native Oct 12 civil settlement path and both bridge repos were not changed.

**Run later on Windows with game dependencies installed** (on isolated Native branch):
```powershell
$env:GameFolder = "C:\Program Files (x86)\Steam\steamapps\common\Mount & Blade II Bannerlord"
dotnet run --project .\Tests\SuccessionEngineHarness\SuccessionEngineHarness.csproj --property:GameFolder="$env:GameFolder" -- --ai-foreign-ledger
```
Also run neighboring `--civil-war-settlement`, `--client-liberation`, `--treaty-balance`, plus **real Native Bellum build** with the correct Bannerlord game references. Then inspect full source diff again after any fix. Do not release/merge based only on build.

**Integrated game/Relay log contract (later, after Bridge authorized caller exists)**:
- Expect exactly one `AII foreign War Score ledger registered; war=<key>; attacker=<id>; defender=<id>; event_id=<source>; accounting_only=true; bellum_autonomous_peace=false` only after authoritative AII W1 real hostility.
- Expect battle/raid/occupation/prisoner and daily scoring reflected under OFF; save/load retains exact source ID and orientation; same W1 event is idempotent; other/old/client/civil pairs not silently claimed.
- Must **NOT** see `War Score forced foreign peace` or autonomous `Foreign treaty parley queued` for owned ForeignWar; no lower `MakePeaceAction.Apply` until AII authoritative peace, no terminal latches restored from old saves, no double relation/ClientKingdom/Treaty effects.
- Existing AII `BRIDGE_V1_SOURCE_BACKED_NATIVE_FALLBACK execution_owner=ai_influence_native` remains for unsupported/off routes. Player, internal/civil, old vanilla peace must work.

## Next distinct stage (NOT included here)

**Stage29F2: Bellum Bridge exact W1 event-id/war provenance → Native `TryRegisterAiInfluenceForeignWar` only AFTER real authoritative hostility; no implicit registration from naked war event.** Must audit Bridge route and callers before patch; route must retain AII fallback peace even when ledger is present. Native 29F1 cannot be called by LLM until F2 passes regressions. Then later Stage29G treaty executor (MakeClientKingdom/ReleaseClientState) with independently saved consent/war-score/council/terminal receipt; clientage not yet implemented for current OFF setting.

## Final status

Source implemented on an isolated Native branch; **pending test execution, successful build, Bridge F2 integration, and game logs**. Not marked fixed, not merged to main, no release. No change required for user to install at this point.
