# Bellum Civile 1.4.12.10 — S27 passive war-identity dump

**Purpose:** compare actual saved `WarScoreRecord` identities immediately before saving a NEW slot and after reloading that exact slot. An identical fingerprint is **record-continuity evidence**, not proof of Native war incarnation or callback correctness.

## Change contract

**ROOT CAUSE:** S26A stores `ConflictInstanceId` in `SaveableField(38)`; S26B reads one exact ID, but there was no safe whole-ledger observation command for a before/after experiment. There is no demonstrated save/load ID loss so far.

**TOUCH:** `Behaviors/WarScoreIdentityDump.cs` (new detached deterministic formatter, direct `_wars` read); `WarScoreRecord.cs` (internal raw ID getter, no setter); `CheatCommands.cs` (one guarded command); new targeted tests, version and source/build verification metadata.

**DO NOT TOUCH:** `RegisterConflict`, `SyncData`, save-field schema, `GetExistingForeignConflictByInstance`, `OnMakePeace`, `ReconcileExistingWars`, Native decisions, AI/Relay/Bridge, Naval companion code, journal and diplomacy executor.

**MUST FIX:** one read returns all active/ended/foreign/internal rows, ordered sides, ID and raw ID, kind, start/end day, and markers for missing/invalid/duplicate IDs; SHA-256 stable regardless of row order and log wall time. Read is campaign-thread guarded and must not mutate tracked records.

**MUST NOT CHANGE:** old data, new ID allocation, historical migration, war/peace behavior, immutable reader API, or any fallback semantics. No new `[SaveableField]` declarations.

## Regression contract

- Positive: repeat reads on one campaign -> same fingerprint without allocating IDs; save NEW slot -> reload same slot -> matching same-record ID/fingerprint when no world changes.
- Neighbors: empty, null list, null record, pre-migration null ID, malformed ID, duplicate across active/ended/internal, broken pair key, reordered rows, detached output and no record state changes; guard rejects missing/off-thread campaign.
- Existing S26A + S26B identity/reader regressions must still pass. All historic save fields retained. Core+Naval package must remain complete.

## One-game experiment

1. With a **loaded existing campaign** containing at least one tracked war, execute the new developer console command: `civilwars.dump_war_ids`.
2. Find `BELLUM_WAR_ID_DUMP_BEGIN`, each `BELLUM_WAR_ID_DUMP_ROW`, and matching `BELLUM_WAR_ID_DUMP_END` in `Modules\BellumCivile\logs\BellumCivileYYYYMMDD.log` (or rotated `_1.log`). Note the fingerprint and chosen `id`.
3. Save to a **new slot** immediately. Load **that new slot**, without advancing the campaign day; execute `civilwars.dump_war_ids` again.
4. Compare both fingerprints and exact row IDs. For a stable record with no changes: they must match. Missing/invalid/duplicate flags are a failure of clean identity evidence, not instructions to repair the save.
5. Optional: run the command again without save/load: it must not create a new ID and the fingerprint must not change.

**IMPORTANT:** A legacy save missing the ID may generate a fresh GUID during ordinary `SyncData` migration. Comparing two independent loads of that OLD unchanged slot is not proof of continuity. Use a NEW saved slot after migration, and compare its actual pre-save/post-load state. If tracked wars legitimately started/ended between captures, the all-row fingerprint can differ; compare the specific unchanged war row before claiming ID loss.

**What a PASS does not prove:** missed peace callbacks, Native war epoch, LLM intent authorization, any diplomatic execution, or that all war record fields round-trip without change. This diagnostic is log-only. Failure to write the best-effort log is not proof of empty game state.

## Verification on Windows

Run from `BellumCivile` folder after extracting the full source ZIP, with `Verification` as its sibling:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\Tests\WarIdentityDump.Tests.ps1
pwsh -NoProfile -ExecutionPolicy Bypass -File ..\Verification\Invoke-S26BVerification.ps1 -SourceRoot . -OutputRoot C:\CR_Builds\S27_141210_Gate_01
```

The wrapper runs **24 explicitly selected groups** and then builds Core + mandatory Naval, checks DLL hashes, and produces `C:\CR_Builds\S27_141210_Gate_01\build\Modules\BellumCivile` and `BellumCivile_1.4.12.10_complete.zip`. It does **not install** the module into the game. The game must be restarted after replacing binaries.

Manual builder when the combined verification wrapper is not required:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\scripts\Build-CrBellumModuleWindows.ps1 -OutputRoot C:\CR_Builds\Bellum_141210_01 -GameFolder "F:\Steam\steamapps\common\Mount & Blade II Bannerlord" -WorkshopFolder "F:\Steam\steamapps\workshop\content\261550"
```

Both scripts require an output folder that does not exist yet. They use Workshop Harmony/ButterLib/UIExtenderEx/MCM and the installed game's Native + Naval DLLs. Source ZIP is not a built mod.

**Gate status in the packaging environment:** static source/inventory checks only. No PowerShell 7, .NET Windows game references or running Bannerlord available there. The Windows test/build and live fingerprint comparison remain **NOT_RUN** until executed on the user's machine. No release/merge/deployment performed.
