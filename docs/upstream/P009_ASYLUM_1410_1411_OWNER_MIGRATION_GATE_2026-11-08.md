# P0-09 — source-backed asylum 1.4.9 → 1.4.10 → 1.4.11 migration gate

**STATUS: READ-ONLY FEATURE-OWNER AUDIT / DRAFT, NOT AN IMPLEMENTATION, NOT GAME QA.**
Snapshot: custom Native `AIRebelRelay/BellumCivile` staged at [Draft PR #19](https://github.com/AIRebelRelay/BellumCivile/pull/19), head `68436697fdc112d305f1deb21a401ec552dd7051`; main `71c7ab8b8b7a21fc2661f5f25e0a18d74b952ca7` remains unchanged. Native Bellum source is **not** Bellum Bridge `AIRebelRelay/Bannerlord2-AiInfluence-BellumCivile`, and is **not** separate Relay Bridge.

## Full version-chain provenance

- The functional base of our custom Native fork is the 1.4.5-era author implementation (internal module label 1.4.6 is **not** official author 1.4.6).
- Official 1.4.9 source checkpoint: `Vonbalt/BellumCivile@e2ff7d074adeef3b539e7ec47094171c388b6842`. Our current `Behaviors/ExiledClanRecoveryBehavior.cs` Git blob **`09525d71e6588b282a25c1e6a42ee6876f9af909`** is exactly identical to this official 1.4.9 file: this subsystem's divergence is demonstrably *old behavior retained*, not a recent custom patch.
- Official 1.4.10: `Vonbalt/BellumCivile@fe799297ed931ee0d1b69d8a7d4f57a7c22dd983`. Introduces audience/visit state, record 142, dialogue, tester, Harmony patches, event listeners, saved state and replaces immediate acceptance.
- Official frozen 1.4.11: `Vonbalt/BellumCivile@da426b23c64f3a66ae2b389d2db8f23489736bf9`. The **six** asylum-specific source files checked are byte-identical between official 1.4.10 and 1.4.11:

| File | Unchanged official Git blob |
|---|---|
| `AsylumVisitRecord.cs` | `09797a09a4977875a1070ed3fa33ae8cd770c3b6` |
| `Behaviors/ExileAsylumVisits.cs` | `e59fa6cea79dbebe94eed79a7d75fd24cdac1f51` |
| `Behaviors/ExileAsylumDialogues.cs` | `d09491966c21dec38ec0f114fce93030fafa9f04` |
| `Behaviors/ExileAsylumTesting.cs` | `8edc377e299512447752bb1ae84f948fb4d8c5b9` |
| `Patches/AsylumVisitorPatches.cs` | `ab591ac31def376f1f13c8864e8078627672ad93` |
| `Behaviors/ExiledClanRecoveryBehavior.cs` | `bbc4e56793aab56f2cf5db13977f92fb587897c4` |

**Intermediate-release caveat:** six identical asylum blobs do **not** prove the entire behavior is compatible with 1.4.11: `Behaviors/LordshipBehavior.cs` changed between 1.4.10 (Git blob `6899dae79a4457d862593f354575255e847d1768`) and 1.4.11 (`67147fb9a43bd9149a6516f4e0f76262bd173304`). Asylum estate grants depend on that owner. Independently inspect any upstream per-commit reverts and linked owner changes before declaring source parity. Initial 1.4.5† archive provenance remains unverified as a binary.

## ROOT CAUSE — demonstrable feature gap, not a demonstrated corrupted save

Current `ExiledClanRecoveryBehavior` still implements 1.4.9 immediate request:
`QueuePlayerAsylumRequest → TryShowNextPendingAsylumRequest → ShowPlayerAsylumInquiry → AcceptPlayerAsylum → ChangeKingdomAction.ApplyByJoinToKingdom → RecordPlayerInvitation → RemoveTrackedExile`.
The user can accept from a popup, without requiring a guest to enter a lord's hall or speak a sworn oath. The saved legacy pending-request dictionaries/IDs exist.

The official 1.4.10/11 flow instead:
`QueuePlayerAsylumRequest` checks actual player ruler, safe host/guest/party and uniqueness before mutation; it queues and calls `ProcessAsylumVisits`.
`TryCreateAsylumVisit → PlaceAsylumGuest` teleports a *party-less* guest or uses native `LeaveSettlementAction/EnterSettlementAction` with a bounded `MobilePartyAi.DisableForHours` hold for an intact party.
`TryShowNextPendingAsylumRequest → ShowPlayerAsylumInquiry` sends an **acknowledgement-only** letter (not acceptance), after the visit is physically arranged.
`RegisterAsylumDialogues → BeginAsylumConversation → AcknowledgeAsylumOath → CompleteAsylumOath → CompleteAsylumAdmission` checks current player ruler, same guest at the specified keep, seven-day deadline, clan neutrality and current ownership before one-time join/invitation/relation receipt. Optional `CompleteAsylumEstate` depends on `LordshipBehavior.GetGrant/TryGrantVassal`, persisted in `AsylumVisitRecord` fields 12–14.
`ProcessAsylumVisits / FinishAsylumVisit` handles old saved pending requests, expiry, refusal, clan joining elsewhere, wrong ruler, unsafe scene, party release and exile recovery. Saves `BellumCivile_AsylumVisits` as `Dictionary<string, AsylumVisitRecord>`.

This is a **state-machine and gameplay redesign**, not just `AsylumVisitRecord` and SaveDefiner ID 142. The existing custom text `BuildExileCauseContext` (specific rebellion/treason/loyalist causes) and `BuildCourtFactionContext` is richer than official `BuildAsylumLetterContext`; replacing the whole file would drop existing personalized political context. Keep such custom context explicitly unless its author-backed migration is separately designed and tested.

## SHARED-CALLER / BLAST-RADIUS INVENTORY

1. **Exile state and migration** — `Behaviors/ExiledClanRecoveryBehavior.cs`: queue/show/deny/retry, old save keys `BellumCivile_PendingAsylum*`, relation memory, clan departure and join, same-clan in-flight deduplication. The official class has new `RegisterEvents` OnSessionLaunched, HourlyTick and Tick listeners and `SyncAsylumVisits` wiring; current class does not.
2. **World/UI timing** — `Behaviors/ExileAsylumVisits.cs` rejects game conversations/menus/encounters, unsafe hosts, siege, battle, quest and naval/army parties. `Behaviors/ExileAsylumDialogues.cs` offers audience and oath; `ModuleData/Languages/EN/strings.xml` translations and `FeudalTitleDisplayHelper` are related compatibility seams.
3. **Party/AI Harmony — high-risk** — Official `Patches/AsylumVisitorPatches.cs` has `HeroSpawnCampaignBehavior.CanHeroMoveToAnotherSettlement` and `SpawnLordParty` Prefixes that suppress vanilla behavior only while `IsAwaitingAsylum` is true. **Our existing `SubModule.cs` enumerates every `[HarmonyPatch]` class and auto-applies it**; adding this file would introduce live patches without an explicit registration edit. Must audit real target signatures, all Harmony owners/other mods, party lifecycle alternatives and exit cleanup; do not import these hooks opportunistically.
4. **Lordship/finance/feudal titles** — `CompleteAsylumAdmission` and `ExileAsylumDialogues` use `LordshipBehavior.Instance`, `GetGrant`, `Villages`, `CanGrantVassal`, `TryGrantVassal`. **Our current staged tree lacks `Behaviors/LordshipBehavior.cs` and registration of its `CampaignBehaviorBase`**. Official 1.4.11 owner has further changes, including party-command and retainer finance, that are not in our fork. Importing asylum source alone fails dependency closure or silently alters author estate promises.
5. **Save compatibility** — `AsylumVisitRecord` ID 142 has **15 saved fields** (clan, guest, ruler, realm, settlement, party, deadline, notification, hold, state, relation, promised village and grant receipts, held-party flag). Official SaveDefiner has `AddClassDefinition(typeof(AsylumVisitRecord), 142)` and `ConstructContainerDefinition(typeof(Dictionary<string, AsylumVisitRecord>))`. Neither is in current staged Native. Old saves must retain original `BellumCivile_PendingAsylum*` collections; 1.4.10 logic grants them a new seven-day window on actual safe arrival, not on merely loading the save.
6. **Game testing** — Official `Tests/SuccessionEngineHarness/AsylumVisitTests.cs` includes real fixture checks for safe placement, unique join/relation/estate, expiry, replacement-party hold, active scene deferral, legacy pending restore, rejection of unsafe guest/host, save-load receipts. `Behaviors/ExileAsylumTesting.cs` and `CheatCommands.TestAsylum` are testing aids requiring separately reviewed opt-in semantics; don't import debug functionality by default.

## CHANGE BOUNDARY — P0-09 IS ANALYSIS ONLY

**TOUCH:** this new Markdown document only. No production file copied or amended.

**DO NOT TOUCH:** current `ExiledClanRecoveryBehavior.cs`, `BellumCivileSaveDefiner.cs`, `SubModule.cs`, `FactionManagerBehavior.cs`, existing Harmony registration, party creation/scheduler, Court, lordship/finance, AI Influence external diplomacy (Bellum foreign War & Peace Revamp OFF), Bellum Bridge, Relay, separate Relay Bridge, old saves, MCM/defaults, main branch.

**MUST FIX (future separately approved owner migrations):** add author-compatible saved visit lifecycle with safe old-request migration, actual arrival/oath acceptance and durable one-time world-state receipts; first solve the absent lordship/estate dependency and explain/validate how vanilla party movement/creation is fenced, without expanding a single asylum bugfix into a shared Harmony refactor.

**MUST NOT CHANGE:** existing exile-cause and Court-faction narrative provenance, separate AI Influence foreign-war/peace owner, valid exile/denial fallback, no losses of pending old requests, no unauthorized clan transfers, no duplicate relation, gold, estate or Bellum Bridge event effects, existing old-save readability. Do not accept or reject asylum merely because one optional title/estate subsystem is currently unavailable.

## PRE-IMPLEMENTATION REGRESSION CONTRACT

**Positive / new gameplay:**
- Correct active player ruler + safely available keep + valid landless clan/guest → exactly one saved waiting visit with actual position and **7 campaign days** from placement; the notice can be acknowledged without joining.
- In-person audience at same keep, swearing final oath while authority and guest remain valid → one clan join, one original invitation receipt, exactly +10 asylum relation; estate is a separate voluntary second transaction if the correct owner is installed and village available.
- Repeated ticking, dialogue callbacks, save/load and join notifications cannot duplicate membership, relation, villa grant, party hold or event.
- Old save containing pending request **without** visit record remains queued until safe map notice; safe placement starts a **fresh** seven-day interval; timer/receipt survives save/load.

**Neighbor/negative:**
- Wrong player/ruler, no available keep, imprisoned/dead/underage guest, disabled or non-lord party, army/battle/siege/naval travel, quest party, hostile kingdom, player conversation/encounter, another inquiry → no unsafe teleport/join or consumed audience time.
- Refusal/expiration/host lost/ruler changed/guest joins elsewhere → no admission, cleanup after safe scene, restore ordinary exile retry, no forced release of prisoners and no phantom kingdom.
- If party has a newer hold from another system, asylum cleanup must **not** remove that hold or make the party spawn an extra leader.
- Existing legacy asylum UI and political narrative must not be silently bypassed until replacement is complete and tested.
- Crown, civil war, Grace, restore journal, call-to-arms, international diplomacy Revamp OFF, Bellum Bridge events and original saved class/field IDs remain unchanged.

**Regression evidence to demand:** author `AsylumVisitTests.cs` and independent native RED-first tests executed against the final integrated source (not just static string matches), Windows game-DLL compile, Harmony target owner/order audit, actual copied pre-migration save and new-game test. Explicitly compare pre/post clan membership, kingdom, guest/party location and leader, AI hold, deadline, inquiry, relation, title/estate receipt and event stream.

## EXPECTED LOG / GAME VALIDATION (future migration only)

Source-backed official log tags:
- `Asylum audience arranged; clan=...; guest=...; settlement=...; deadline=...` after valid safe placement.
- `Asylum placement deferred; clan=...; error=...` or `Asylum audience recovery deferred; clan=...; error=...` on exceptional failures; repeated endless errors are not successful recovery.
- `Asylum admitted without promised estate; clan=...; village=...` only if oath succeeded but promised grant failed; no false duplicated 'estate granted' receipt.
- For the author opt-in test: `Asylum test: ...` only if explicitly enabled. Do not add the test command until approved.
- **Negative:** no duplicate join/invitation/relation, no unowned second party, no unrelated Harmony suppression, no early expiry on a legacy save, no scene-time teleport or cleanup.
No P0-09 runtime logs exist yet: **this Draft creates none**.

## STOP / NEXT OWNER DECISION

Do **not** stage 142 or a `Patches/AsylumVisitorPatches.cs` file in isolation. Before a production P0-09 implementation, audit and resolve the **exact** LordshipBehavior dependency in source 1.4.11 (import it as its own feature-owned stage if appropriate, or explicitly design and approve a limited asylum-without-estate target), verify party/Harmony owners, and define minimum connected asylum-file scope. Treat any expanded file list as a revised stage boundary, not an excuse for a wholesale merge.

**Evidence status:** direct GitHub SHA/file/caller and author harness inspection only; no PowerShell, .NET, Bannerlord compile, saved-game run, live Harmony owner snapshot, CI, merge or release. Current full 304-path version matrix remains inventory-only, not a migration certificate.
