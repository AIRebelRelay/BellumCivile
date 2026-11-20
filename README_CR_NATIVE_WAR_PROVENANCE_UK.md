# BellumCivile 1.4.12.12 — CR foreign-war Native witness + float-day reader precision fix

**Regression from live 1.4.12.11:** new Vlandia–Nord war logged a captured Native witness yet its passive identity reader returned `InvalidRecords` at campaign day ~396062.747372. Existing `StartedDay` is a saved `float` rounded to `396062.75`; comparing against a double-precision capture time falsely marked this same-instant record as future. The shared detached identity reader now only rejects future starts at the persisted `float` precision. It does NOT authorize actions and does not change war state, save fields, or peace ownership. Positive same-instant and negative genuinely-future tests added to existing identity/native witness suites. Windows/game validation for 1.4.12.12 still required.


Це **source candidate**, не готові DLL. S27 1.4.12.10: Windows 24/24 groups PASS, Core+Naval build 0 errors/warnings; live 5 WarScore records retained identical IDs and fingerprint before/after reload. This is record persistence, not unique Native war identity.

## Що додано

- Save fields `39`–`41` on `WarScoreRecord` exclusively for weak foreign-war Native start witness and ambiguity flag; previous fields/war ID/score remain unchanged.
- `OnWarDeclared`: new foreign record may capture existing Native `WarStartDate`; an already-active pair receiving another declaration is marked ambiguous, **not automatically closed, re-registered, or re-scored**.
- Passive `BellumIntegration.ObserveForeignWarNativeWitness(...)` and console `civilwars.dump_war_native_witness`; both return weak evidence only. No other Bridge/Relay/LLM code is changed.
- Existing `civilwars.dump_war_ids` remains unchanged.

**Critical:** WarStartDate is NOT proven unique, and a matching timestamp NEVER authorizes treaty execution. Old saves, reconciliation-created records and missed information remain unknown/ambiguous. Missed-peace lifecycle gap is therefore not declared fixed. No AI diplomatic executor enabled.

## Windows test + Core/Naval build (one command)

From the extracted `BellumCivile` source folder:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\scripts\Verify-CrBellumNativeWitnessWindows.ps1 -OutputRoot C:\CR_Builds\Bellum_141212_Precision_01
```

Checks the source inventory, six relevant actual-record/caller test groups, then builds full `Modules\BellumCivile` with Core + Naval DLC patch using installed Game and Workshop libraries. It does NOT install to the game. Output root must be fresh. Required paths are the usual `F:\Steam\steamapps\common\Mount & Blade II Bannerlord` and `F:\Steam\steamapps\workshop\content\261550`.

After the successful gate, available at `C:\CR_Builds\Bellum_141212_Precision_01\build\Modules\BellumCivile`; complete build ZIP at `C:\CR_Builds\Bellum_141212_Precision_01\build\BellumCivile_1.4.12.12_complete.zip`.

## Game observation AFTER build

In the campaign console:

```text
civilwars.dump_war_native_witness
```

In `Modules\BellumCivile\logs\BellumCivileYYYYMMDD.log` look for `BELLUM_NATIVE_WAR_WITNESS_BEGIN`, `_ROW`, `_END`, with `identity=`, `witness=`, and `authority=false`. On old saved wars expect `Unwitnessed` — this is correct and does not mean save corruption. A new **real** foreign declaration in the current game may log `Native foreign war-start witness captured`; rerunning the command is read-only. Repeat after save/load to compare. Avoid forcing a new war merely for this test.

Static check only in packaging environment; Windows net472/real serializer/live-game validation NOT_RUN for version 1.4.12.12. No merge or release. Full technical contract: `docs/backlog/2026-11-19-foreign-war-native-witness-contract.md`.
