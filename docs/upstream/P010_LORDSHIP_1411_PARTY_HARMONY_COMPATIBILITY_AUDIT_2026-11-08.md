# P0-10 — Native Bellum 1.4.11 Lordship owner and asylum/Harmony party safety audit

**STATUS: DOCS-ONLY RISK REVIEW, NOT A PATCH OR RELEASE VALIDATION.**
Native custom repo `AIRebelRelay/BellumCivile`, stacked upon Draft PR #20 `81f02cfdd6fdac9644f2846dff5af8ba35f9600e`; Native main `71c7ab8b8b7a21fc2661f5f25e0a18d74b952ca7` is untouched. **Do not confuse** this Native source fork with `AIRebelRelay/Bannerlord2-AiInfluence-BellumCivile` (Bellum Bridge) or `AIRebelRelay/ai-rebel-relay-bridge` (Relay Bridge). The current project text `Rules for updating Bellum's version.txt` explicitly maps the latter Bellum Bridge repo but does **not** separately name Native `AIRebelRelay/BellumCivile`; treat this as a future instructions-correction, not permission to edit the wrong repository.

## Version-chain / source-of-truth evidence

Functional ancestry is official 1.4.5-era author source plus our customization (the 1.4.6 label in the custom module is not official author 1.4.6). The exact historical published 1.4.5 archive commit is not independently proven; the pinned historical candidate and all earlier 1.4.5†→1.4.9 checkpoint diffs remain documented in the 304-path source matrix. Current 1.4.11 parity **requires all intermediate deltas**, never merely file presence.

| Official era source | SHA | `Behaviors/LordshipBehavior.cs` blob | Main functional notes |
|---|---|---|---|
| 1.4.9 | `e2ff7d074adeef3b539e7ec47094171c388b6842` | `535199299ea157ed13f1f17e69e9cad74651a801` | Lordship grant/appointment foundation already exists upstream but not in our customized fork |
| 1.4.10 | `fe799297ed931ee0d1b69d8a7d4f57a7c22dd983` | `6899dae79a4457d862593f354575255e847d1768` | Fixes selected retirement/party handling; HAP income integration; author adds the asylum visit state machine (see P0-09) |
| 1.4.11 | `da426b23c64f3a66ae2b389d2db8f23489736bf9` | `67147fb9a43bd9149a6516f4e0f76262bd173304` | Saved command-transfer and indenture contracts, richer legal commander handoff, repair of disbanding-party ownership, broader title/finance support |

Official 1.4.9→1.4.10 changed 61 paths; 1.4.10→1.4.11 changed 64 paths (not all in this feature). Both intervals modify Lordship source and its adjacent hooks. The Native Draft #20 tree has **no** `Behaviors/LordshipBehavior.cs`, `Behaviors/LordshipCommandTransfers.cs`, `Behaviors/RetainerIndentures.cs`, `Patches/LordshipAppointmentPatches.cs`, `Patches/AsylumVisitorPatches.cs`, or `AsylumVisitRecord.cs`. Existing Native `SubModule.cs` does not register `LordshipBehavior`.

### Exact changes missed by using 1.4.10 Lordship as an older base

- Official 1.4.11 `LordshipBehavior.SyncData` adds `BellumCivile_LordshipCommandTransfers` / `_commandTransfers` (save type **143**) and `BellumCivile_RetainerIndentures` / `_indentures` (**144**) and reindexes indentures during load. Both owners are defined in separate partial-class files; registering types without owners would create a misleading save-parity claim.
- `OnLoaded`, `CheckAppointment`, `EnsureAppointmentGrant`, `Maintain`, `OnTick`, `Validate`, and `OnClanDay` now use **`HasServiceSupport`** (grant **or** active paid indenture), not the older `GetGrant`-only policy. In `Patches/LordshipFinancePatches.cs`, grant-only filtering also changes to service-support filtering. Using 1.4.10 logic with 1.4.11 records could dismiss legitimate commanders or misattribute party income.
- Unendowed retainer retirement changed from direct disband/fugitive paths to `ReplacementCandidates → BeginCommandTransfer → ReleaseRetiredCommander/DisbandRetiredParty` with delayed/instant native hero transport and saved retry record. The new `RepairRetiredCommanders` checks both player and eligible non-player disbanding parties, keeping unsafe candidates for retry. Incorrect transplant can leave a hero commanderless, spawn/disband an unwanted party, or lose troops.
- Official `Patches/LordshipAppointmentPatches.cs` changed from **17 to 19 explicit `Patch(...)` sites** (source count, not evidence all installed). New 1.4.11 `DisbandPartyCampaignBehavior.OnPartyDisbandStarted` **transpiler** (`RetirementDisbandCode`) demands exactly one matching `Hero.IsActive` call; an unknown game-version IL body can break this invariant. A `TeleportHeroAction.ApplyImmediateTeleportToPartyAsPartyLeader` prefix validates replacement arrival. Other existing 1.4.10 transpilers target `HeroSpawnCampaignBehavior.GetBestAvailableCommander` and `ClanVariablesCampaignBehavior.UpdateGovernorsOfClan`, with strict expected instruction-count contracts. These are high-risk/shared internal hooks.
- `Behaviors/LordshipBehavior.cs::OnLoaded` invokes `LordshipFinancePatches.Initialize`, `LordshipAppointmentPatches.Initialize`, `VassalLordshipPatches.Initialize`, `LordshipMapBannerPatch.Initialize` and `LordshipHapIncome.Initialize`. These are not merely data-model dependencies: they can patch financial calculation, party/hero selection, governor replacement, and UI. Startup failures may occur before feature readiness; owner/original-method audit needed.
- `Behaviors/VassalLordships.cs::TryGrantVassal` calls `TitleAcquisitionBehavior.Granted` and awards relation memory. The asylum optional estate step invokes this path and uses the new saved `AsylumVisitRecord` receipt fields 12–14, while the oath's clan admission precedes any optional estate gift. A missing Lordship registry would make an author-equivalent estate grant unavailable; silently dropping it would be a **deliberate functional exclusion**, not full 1.4.11 parity.

## Harmony / shared-party call graph and collision surface

1. **Module startup, reflective registration:** our existing `SubModule.cs::OnSubModuleLoad` enumerates `Assembly.GetExecutingAssembly().GetTypes()` and automatically `CreateClassProcessor(type).Patch()` for `[HarmonyPatch]` types (unless its optional-skip gate applies). Importing official `Patches/AsylumVisitorPatches.cs` adds two active Prefix classes **without any explicit new call**.
2. **`HeroSpawnCampaignBehavior.CanHeroMoveToAnotherSettlement`:** `AsylumVisitorRelocationPatch.Prefix(Hero hero, ref bool __result)` returns true for unrelated heroes; for a valid waiting asylum guest it returns false and sets result false, suppressing native relocation.
3. **`HeroSpawnCampaignBehavior.SpawnLordParty`:** `AsylumVisitorCommandPatch.Prefix(Hero __0, ref MobileParty __result)` similarly returns false with result null for a waiting guest, suppressing native party creation.
4. **Second Prefix on `SpawnLordParty`:** official `LordshipAppointmentPatches.Initialize` explicitly patches this *same exact target*, its `BeforeSpawn(Hero, ref MobileParty)` checks `LordshipEligibility.Required / HasServiceSupport / EnsureAppointmentGrant`. It is installed under a separate Harmony ID (`com.bellumcivile.lordship.appointments`) on campaign load, not by reflective `[HarmonyPatch]` scanning. The two Prefixes have an **overlapping target but not a confirmed runtime conflict**. Order, other mods' owners, exact native method signature and side effects are **not** established by source-only inspection.
5. **Additional party blast radius:** the appointment owner also patches `Hero.CanLeadParty`, `DefaultArmyManagementCalculationModel.CanLordCreateArmy`, `HeroSpawnCampaignBehavior.GetBestAvailableCommander` (transpiler), `ClanVariablesCampaignBehavior.UpdateGovernorsOfClan` (transpiler), `DisbandPartyCampaignBehavior.OnPartyDisbandStarted` (transpiler), clan party UI, governor actions, `MobileParty.ChangePartyLeader/RemovePartyLeader`, marriage and tooltip hooks. Patches and `LordshipBehavior.Maintain` are part of one feature-owner boundary: importing only the two asylum Prefixes can leave an unreviewed gap.
6. **Other installed systems:** GitHub default-branch code search did not surface exact `HeroSpawnCampaignBehavior` symbols in the Bellum Bridge repository, but that does not prove no Harmony conflicts across other mods, unmerged branches, AI Influence or the live process. A runtime Harmony owner/priority snapshot and native version metadata are required. Do not infer safety from absence of GitHub search results.
7. **No-Harmony alternative:** not yet demonstrated. Before replacing these prefixes, trace whether TaleWorlds provides a supported event/campaign mechanism that guarantees **both** guest relocation and native party-spawn suppression. `MobilePartyAi.DisableForHours` alone is not proof it blocks `HeroSpawnCampaignBehavior.SpawnLordParty`. Do not invent a safer replacement or remove protections speculatively.

## Surgical change boundary

**ROOT CAUSE:** the asylum 1.4.10/11 upgrade is blocked by absent *feature-owner* Lordship source and 1.4.11 revisions, plus a shared native party-spawn target exposed by multiple Harmony Prefixes. It is a verifiable dependency/compatibility **risk**, not a reproduced crash or proof that any patch already breaks the game.

**TOUCH:** exactly this new docs file. No buildable code edit, no imported class, no new Harmony hook, no SaveDefiner changes.

**DO NOT TOUCH:** Native `SubModule.cs`, `Behaviors/LordshipBehavior.cs`, `Behaviors/ExiledClanRecoveryBehavior.cs`, `BellumCivileSaveDefiner.cs`, current crown/civil-war/restore paths, global patch infrastructure, party scheduler, optional HAP adapter, AI Influence external diplomacy (Bellum War & Peace Revamp OFF), Bellum Bridge, Relay Bridge, Relay, installed saves or defaults.

**MUST FIX (later explicitly bounded feature-owner stage):** choose a fully 1.4.11-equivalent Lordship lifecycle port with all required registrations/hooks and compatibility tests, **or** explicitly approve a narrower asylum-without-estate design and document its non-parity. Any production change must separately enumerate exact source files/callers, test the actual installed TaleWorlds and Harmony-target signatures first, then use RED-first positive and neighbor regression tests. Do **not** silently import v1.4.10 Lordship or isolated serializer IDs 142–144.

**MUST NOT CHANGE:** existing legacy instant asylum, saved pending exile requests and detailed exile/Court narrative until a complete replacement is regression-certified; foreign diplomacy owner AII; existing kingdom/party/leader states, retainer/captive/quest safety, title/estate consistency, single money and relation credits, Bellum Bridge event cardinality, Grace P0-04, Crown P0-05, P0-06 and P0-07 handling and historical save IDs.

## Pre-code regression contract and required evidence

**Positive cases:**
- On eventual feature activation, valid retainer with legal village grant **or active indenture** may govern/command; expired unsupported retainer is retired safely without losing the original party or resurrecting a second commander. 1.4.11 command transfer must survive interrupted travel, save/load and restored party while retaining one legal leader.
- For asylum after scoped migration, actual landless clan leader waits in a safe keep for **7 game days**, cannot relocate or spawn an independent party, gets only an acknowledgement notice before an in-person oath. Oath joins once; optional estate grants only when the 1.4.11 owner is Ready, available, and its existing receipt is valid.
- Save-load after asylum arrival, paid indenture, pending handover and a safe party hold should preserve owner state and not replay gold, relations, village grant, lord party spawn or notifications.

**Neighbor cases that must continue working:**
- Ordinary family ruler and unrelated NPC can naturally spawn/change a party, choose governors, join/leave kingdom, use a quest/army/siege/sea party and move between settlements. Waiting asylum guest must not become a separate independent army or free itself during an unsafe scene. After visit completion/expiry, blocking prefixes must stop applying to that guest.
- AI Influence-owned foreign war/peace and Bellum Bridge political-event flow retain existing ownership; player-clan parties, kingdom leader, family and existing household retainer paths do not inherit premature Lordship default changes.
- Older 1.4.5-custom campaign without the new 138–144 save types must load with sane empty owner collections; saved legacy asylum requests must not disappear or restart the clock until actual safe arrival; save IDs and original field IDs remain stable.
- A different plugin's newer AI hold must not be released by asylum cleanup. A native disband in progress must not destroy a continuing, lawfully replaced party. Overlapping Prefixes on `SpawnLordParty` require a real owner/order snapshot; newly added transpilers must match actual installed game IL.

**Compilation is necessary, not sufficient.** Run the author's `Tests/SuccessionEngineHarness/AsylumVisitTests.cs`, `LordshipAppointmentTests.cs`, `RetainerIndentureTests.cs`, `LordshipFinanceStartupTests.cs`, `Tests/AsylumAudience.Tests.ps1` and native existing P0-04/P0-05/P0-06/P0-07 and P1-01A–F tests on a complete final candidate. On Windows, verify actual Harmony patch info for both `SpawnLordParty` and `CanHeroMoveToAnotherSettlement`, `GetBestAvailableCommander`, `OnPartyDisbandStarted`; verify expected IL counts before activation; compare old-save and new-game membership/party-lord counts and live logs before approving merge/release.

**Source-backed positive log tags (future only):**
- `Asylum audience arranged; clan=...`
- `Replacing retired lordship commander; party=...`
- `Retired unendowed lordship commander; hero=...`
- `Repaired retired lordship commander attached to a disbanding party; hero=...`
- `Agreed retainer indenture; hero=...`

**Unexpected / watch:** `Failed to apply Harmony patch`, repeated `Asylum placement deferred` / `Asylum audience recovery deferred` without a successful retry, duplicate party or kingdom join, duplicated income/fee/relations, an active quest party losing its leader, or a non-guest being blocked. Exact target methods and Harmony owners are **not yet validated against the installed game**, and this docs-only stage emits no new logs.

## Go / no-go

**NO-GO on production import today.** The technical design cannot fit into a safe one-file/one-method patch. Validate the exact game/Harmony owner surface and agree on full 1.4.11 Lordship owner scope (rather than a stale 1.4.10 baseline) before creating RED-first implementation tests. Separate the eventual Lordship and Asylum implementation stages; don't combine independent features merely to reach a version number.

**Evidence limitations:** GitHub official upstream snapshots, current Native Draft #20 tree, direct Git file comparisons and known call sites only. No actual full Windows PowerShell/.NET test, Bannerlord compilation, loaded Harmony patch inspection, live game, historical save or Bridge DLL ABI validation. The 304-path version matrix is inventory, not complete functional coverage.
