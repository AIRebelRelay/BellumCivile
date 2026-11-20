# BellumCivile 1.4.12.14 — QA-only controlled treaty test

## ROOT CAUSE / aim
Native `campaign.declare_peace` is intentionally blocked by Bellum's war/peace revamp. A credible test of treaty instance binding requires the actual Bellum ForeignTreatyBehavior -> council -> ApplyTreaty -> protected MakePeaceAction path.

## TOUCH
`CheatCommands.cs` (one QA compile-gated console entrypoint), `BellumCivile.csproj` (opt-in symbol), `scripts/Build-CrBellumModuleWindows.ps1` and `scripts/Verify-CrBellumNativeWitnessWindows.ps1` (explicit QA build), version metadata, dedicated QA tests and source inventory.

## DO NOT TOUCH
ForeignTreatyBehavior, TreatyProposalRecord save schema, HostageTreatyRecovery, WarScoreBehavior, Native Witness, diplomatic policy, Bridge/Relay, general peace protection.

## REGRESSION CONTRACT
Positive: an explicit CONFIRM_TEST_SAVE on active foreign NPC/NPC war queues a forced white-peace proposal using existing TryQueueAiParley, leaves war active immediately, then normal daily Bellum treaty settlement resolves after >1 in-game day. Existing Saved ConflictInstanceId is carried through queue; after peace that record ends; redeclaring war creates a fresh ID, old Applied remains historical.

Negative: no confirmation, invalid kingdom, player involved, unilateral peace, no active Bellum foreign record, invalid/nonunique ID, missing/changed/ambiguous Native witness, already pending parley or terminal resolution, storyline/alliance/client restrictions all refuse. No QA command exists in normal production builds (BellumTreatyQa default OFF). No direct MakePeaceAction or WarScore writes in command. Old treaty pending cannot bind by WarKey alone. Other war/treaty controls must remain unchanged.

## WINDOWS GATE
From extracted `BellumCivile` directory run with PowerShell 7:

```
pwsh -NoProfile -ExecutionPolicy Bypass -File .\scripts\Verify-CrBellumNativeWitnessWindows.ps1 -OutputRoot C:\CR_Builds\Bellum_141214_QA_01 -GameFolder 'D:\SteamLibrary\steamapps\common\Mount & Blade II Bannerlord' -WorkshopFolder 'D:\SteamLibrary\steamapps\workshop\content\261550'
```

This makes QA-tagged module ZIP/folder. DO NOT ship as public release. No native ABI available in Linux. Legacy 7 tests + QA console contract test must all pass on user's Windows PC.

## LIVE TEST: new independent test save only
1. Install QA module, restart game, load a safe fork of current test save with Vlandia vs Nords active (neither is player).
2. Run `civilwars.dump_war_ids` / `civilwars.dump_war_native_witness`, record ID and witness; `civilwars.foreign_treaties` baseline.
3. Run `civilwars.qa_force_white_peace Vlandia | Nords | CONFIRM_TEST_SAVE`. Expect `QA_BELLUM_PARLEY_QUEUED` (not instant peace). This is an explicit forced surrender TEST, not an organic council decision.
4. Unpause game >1 in-game day. `civilwars.foreign_treaties` should show new proposal Applied and `civilwars.dump_war_ids` should show that ID ENDED; if rejected, preserve log and stop.
5. Save/load in separate test slot and repeat dump. `campaign.declare_war Vlandia | Nords` creates next war; `dump_war_ids` should show new ID and old ENDED.
6. Observe `BELLUM_QA_TREATY_WHITE_PEACE`, `Foreign treaty parley queued`, `Foreign treaty applied`, `War Score tracking ended` and absence of `BELLUM_TREATY_STALE_REJECTED` for correct new proposal. `BELLUM_TREATY_STALE_REJECTED` should occur only on an actual stale pending proposal.
7. Do not use QA-tagged module in ongoing saves. Final release must be built with QA flag OFF and independently gameplay-validated.

## NOT PROVEN
This does not demonstrate missed Native peace callback recovery or uniquely identify Native war epoch; QA-induced forced settlement bypasses natural council consent by design but goes through the real treaty action path.
