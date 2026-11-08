# Bellum Civile upstream changes — source-file audit matrix (1.4.5 → 1.4.11)

> **Status: INVENTORY ONLY, NOT A COMPLETED PORT.** Created 2026-11-08. This file is intentionally committed to a **docs-only audit branch** of our Native Bellum fork. **Do not confuse** this fork with Bellum Bridge (`AIRebelRelay/Bannerlord2-AiInfluence-BellumCivile`) or Relay Bridge (`AIRebelRelay/ai-rebel-relay-bridge`). No production files changed.

## Source-of-truth and baseline caveat

- **Custom Native Bellum:** `AIRebelRelay/BellumCivile` main @ `71c7ab8b8b7a21fc2661f5f25e0a18d74b952ca7`; our label **1.4.6**, with user-confirmed functional ancestry **official 1.4.5 + custom changes**. This is **not** official upstream 1.4.6 source.
- **Prepared stacked Native drafts:** PR #9 → #10 → #11 → #12 → #13, combined head `a7a7d39e3bacac4799dc2d301831b2926171ebea`; these are **not merged**. A "Draft touched" mark is a candidate for review, **not** proof of upstream parity.
- **Official upstream:** [`Vonbalt/BellumCivile`](https://github.com/Vonbalt/BellumCivile); target frozen commit `da426b23c64f3a66ae2b389d2db8f23489736bf9` (source `v1.4.11`). No `v1.4.x` git refs/tags resolved through repository file access; all comparisons below use **immutable full SHA**.
- **CRITICAL BASELINE UNCERTAINTY:** author's accessible `_Module/SubModule.xml` history goes from `v1.4.4` at `40a25a8db99fa8f5fcf63595de3aa29bcfcdde0c` directly to `v1.4.6` in later commits; an independently verified official **1.4.5 source SHA was not found**. For safety the first interval uses the **older, broad pre-1.4.6 checkpoint** (`v1.4.4` string), so it may contain extra changes and MUST NOT be mislabeled as an exact official 1.4.5 diff. Resolve this by locating the 1.4.5 source/release archive, its build commit or matching tree before claiming 100% accuracy.
- **Additional boundary nuance:** upstream module version string can lag development changes: early commits for a later feature sometimes still carry an earlier `SubModule.xml` version. These checkpoints are **version-era source snapshots**, not independently proven release-package contents. Verify against actual released archives when determining an exact version boundary.

## Frozen comparison checkpoints

| Phase | Base SHA | Head SHA | Commits | GitHub diff files | Source compare |
|---|---|---|---:|---:|---|
| pre-1.4.6* → 1.4.6 | `40a25a8db99fa8f5fcf63595de3aa29bcfcdde0c` | `2e4232521c469f5a9603c33cc1da5c2673a99162` | 12 | 96 | [Compare](https://github.com/Vonbalt/BellumCivile/compare/40a25a8db99fa8f5fcf63595de3aa29bcfcdde0c...2e4232521c469f5a9603c33cc1da5c2673a99162) |
| 1.4.6 → 1.4.7 | `2e4232521c469f5a9603c33cc1da5c2673a99162` | `d93a20269e66226843df764be69b8a0dd1f264a0` | 5 | 19 | [Compare](https://github.com/Vonbalt/BellumCivile/compare/2e4232521c469f5a9603c33cc1da5c2673a99162...d93a20269e66226843df764be69b8a0dd1f264a0) |
| 1.4.7 → 1.4.8 | `d93a20269e66226843df764be69b8a0dd1f264a0` | `ea0cc7b555bd05e4d246d5b1c98f643ec81da3d4` | 7 | 102 | [Compare](https://github.com/Vonbalt/BellumCivile/compare/d93a20269e66226843df764be69b8a0dd1f264a0...ea0cc7b555bd05e4d246d5b1c98f643ec81da3d4) |
| 1.4.8 → 1.4.9 | `ea0cc7b555bd05e4d246d5b1c98f643ec81da3d4` | `e2ff7d074adeef3b539e7ec47094171c388b6842` | 4 | 28 | [Compare](https://github.com/Vonbalt/BellumCivile/compare/ea0cc7b555bd05e4d246d5b1c98f643ec81da3d4...e2ff7d074adeef3b539e7ec47094171c388b6842) |
| 1.4.9 → 1.4.10 | `e2ff7d074adeef3b539e7ec47094171c388b6842` | `fe799297ed931ee0d1b69d8a7d4f57a7c22dd983` | 11 | 61 | [Compare](https://github.com/Vonbalt/BellumCivile/compare/e2ff7d074adeef3b539e7ec47094171c388b6842...fe799297ed931ee0d1b69d8a7d4f57a7c22dd983) |
| 1.4.10 → 1.4.11 | `fe799297ed931ee0d1b69d8a7d4f57a7c22dd983` | `da426b23c64f3a66ae2b389d2db8f23489736bf9` | 10 | 64 | [Compare](https://github.com/Vonbalt/BellumCivile/compare/fe799297ed931ee0d1b69d8a7d4f57a7c22dd983...da426b23c64f3a66ae2b389d2db8f23489736bf9) |

**Inventory:** **261 unique file paths**, union of **370 version-interval change entries** (same file can occur in several intervals). By initial review priority: P0=89, P1=85, P2=87. Raw GitHub compare indicates no oversized diff for these intervals; each supplied an explicit file array. This is a union of **checkpoint diffs**, not a per-commit audit of temporary changes later reverted inside the same interval.

## How to use this tracker

1. Review **P0 first** (save schema, kingdom restoration, civil war, succession, war/peace ownership), then P1 (shared behavior, Harmony, settings, XML), then P2 (UI, tests, documentation). Do **not** treat matching file names as matching implementations.
2. For each path compare (a) original custom Native main `71c7ab8b8b7a`, (b) combined stacked PR #13 `a7a7d39e3bac`, (c) pinned official 1.4.9/1.4.10/1.4.11 SHA and earlier checkpoints; trace affected callers, shared dependencies and **custom features**. Record exact function/field/API mismatches.
3. Replace `TODO` with one of `MATCH`, `PARTIAL`, `MISSING`, `CUSTOM-KEEP`, `EXCLUDE-JUSTIFIED`, `NOT-IN-FORK` **only after a source-backed comparison**, and add commit/line/test evidence in the notes or a separate per-file issue. The initial `Draft touched?` flag does **not** imply completed validation.
4. Before production changes define ROOT CAUSE, TOUCH, DO NOT TOUCH, MUST FIX, MUST NOT CHANGE and RED/neighbor regressions. Isolate one stage per Draft PR; audit its entire diff; execute real Windows PowerShell / .NET Native build, Bellum Bridge ABI test and copied-old-save / new-game logs before merge. Do not merge directly to main or release while these gates are pending.
5. Preserve AI Influence external diplomacy ownership with Bellum War & Peace Revamp **OFF**, and verify no duplicate Bellum Bridge/Relay political events. Audit all new `SaveDefiner` class IDs, containers and original field IDs; never copy only newer schema registrations.

**Stage cell legend:** `A` added; `M` modified; `D` deleted; `R` renamed; `C` copied; `—` not in that endpoint's changed-file list. `Draft touched?` compares our original Native main to stacked PR #13. Every status initially `TODO`. **P→6 uses the provisional pre-1.4.6 source**, not a proven 1.4.5 release SHA.

## Complete changed-file matrix — 261 paths

| Priority | File | Area | P→6* | 6→7 | 7→8 | 8→9 | 9→10 | 10→11 | Draft touched? | Audit status |
|:---:|---|---|:---:|:---:|:---:|:---:|:---:|:---:|:---:|---|
| P2 | `_Module/SubModule.xml` | Module | M | M | M | M | M | M | — | TODO |
| P2 | `AlliancePeaceRestriction.cs` | Politics/war | — | — | — | A | — | — | — | TODO |
| P1 | `AsylumVisitRecord.cs` | Save/state | — | — | — | — | A | — | — | TODO |
| P2 | `BC Changelog.txt` | Other | M | M | M | M | M | M | — | TODO |
| P1 | `Behaviors/AcceptedIndependence.cs` | Behavior | A | — | — | — | — | — | — | TODO |
| P1 | `Behaviors/BellumMarriageEvaluation.cs` | Court/title | — | — | M | — | — | M | — | TODO |
| P1 | `Behaviors/BellumMarriageStrategyHelper.cs` | Court/title | — | — | M | — | — | M | — | TODO |
| P0 | `Behaviors/CivilWarCollapseContinuation.cs` | Politics/war | M | — | — | — | — | — | YES | TODO |
| P0 | `Behaviors/CivilWarCrownTransfer.cs` | Politics/war | M | — | — | — | — | — | YES | TODO |
| P0 | `Behaviors/CivilWarResolutionBehavior.cs` | Politics/war | M | — | — | — | — | — | YES | TODO |
| P0 | `Behaviors/CivilWarSuccessionSettlement.cs` | Politics/war | M | — | — | — | — | — | — | TODO |
| P1 | `Behaviors/ClaimFeudBehavior.cs` | Behavior | — | M | — | — | — | — | — | TODO |
| P1 | `Behaviors/CouncilAppointmentDeliberationBehavior.cs` | Court/title | M | — | — | — | — | — | — | TODO |
| P1 | `Behaviors/CourtAgendaBehavior.cs` | Court/title | M | — | — | — | M | — | — | TODO |
| P1 | `Behaviors/CourtAgendaPlayerFlow.cs` | Court/title | M | — | — | — | — | — | — | TODO |
| P1 | `Behaviors/CourtClientGrantAgendas.cs` | Court/title | — | — | — | — | M | — | — | TODO |
| P1 | `Behaviors/CourtCouncilAgendas.cs` | Court/title | M | — | — | — | — | — | — | TODO |
| P1 | `Behaviors/CourtExecutiveAgendas.cs` | Court/title | M | — | — | — | — | — | — | TODO |
| P1 | `Behaviors/CourtPlayerCrownActions.cs` | Politics/war | — | — | — | — | M | — | — | TODO |
| P1 | `Behaviors/CourtTitleGrantAgendas.cs` | Court/title | M | — | — | — | — | — | — | TODO |
| P1 | `Behaviors/CourtTitleGrantRecipientFlow.cs` | Court/title | A | — | — | — | — | — | — | TODO |
| P1 | `Behaviors/CrownAccessionBehavior.cs` | Politics/war | — | — | M | — | — | — | — | TODO |
| P1 | `Behaviors/CrownForcedAbdication.cs` | Politics/war | M | — | — | — | — | — | — | TODO |
| P1 | `Behaviors/DynamicMercenaryBandBehavior.cs` | Behavior | — | — | M | — | — | — | — | TODO |
| P1 | `Behaviors/DynamicMercenaryPartyRepair.cs` | Behavior | — | — | A | — | — | — | — | TODO |
| P1 | `Behaviors/DynamicRelationBehavior.cs` | Behavior | — | — | M | — | — | — | — | TODO |
| P1 | `Behaviors/DynasticHeirBehavior.cs` | Behavior | M | — | — | — | — | — | — | TODO |
| P1 | `Behaviors/ExileAsylumDialogues.cs` | Behavior | — | — | — | — | A | — | — | TODO |
| P1 | `Behaviors/ExileAsylumTesting.cs` | Behavior | — | — | — | — | A | — | — | TODO |
| P1 | `Behaviors/ExileAsylumVisits.cs` | Behavior | — | — | — | — | A | — | — | TODO |
| P1 | `Behaviors/ExiledClanRecoveryBehavior.cs` | Behavior | — | — | — | — | M | — | — | TODO |
| P0 | `Behaviors/FactionManagerBehavior.cs` | Politics/war | M | — | — | — | — | — | YES | TODO |
| P0 | `Behaviors/FactionSuccessionSafety.cs` | Politics/war | A | — | — | — | — | — | — | TODO |
| P1 | `Behaviors/FeudalAllocationCustody.cs` | Behavior | — | — | M | — | — | — | — | TODO |
| P1 | `Behaviors/FeudalClientLandGrant.cs` | Behavior | — | — | — | — | M | — | — | TODO |
| P1 | `Behaviors/FeudalTitleBehavior.cs` | Court/title | M | M | M | — | M | — | — | TODO |
| P1 | `Behaviors/ForeignTreatyBehavior.cs` | Politics/war | M | — | — | M | — | — | — | TODO |
| P1 | `Behaviors/HostagePactPlacement.cs` | Politics/war | M | — | — | — | — | — | — | TODO |
| P1 | `Behaviors/HostagePactTreatyDelivery.cs` | Politics/war | M | — | — | — | — | — | — | TODO |
| P1 | `Behaviors/IdeologyBehavior.cs` | Behavior | — | M | — | — | — | — | — | TODO |
| P1 | `Behaviors/IndependenceRulerSaveRepair.cs` | Behavior | A | — | — | — | — | — | — | TODO |
| P1 | `Behaviors/LordshipBehavior.cs` | Court/title | — | — | A | M | M | M | — | TODO |
| P1 | `Behaviors/LordshipCommandTransfers.cs` | Court/title | — | — | — | — | — | A | — | TODO |
| P1 | `Behaviors/LordshipDialogues.cs` | Court/title | — | — | A | M | M | M | — | TODO |
| P1 | `Behaviors/MarriageAllianceBehavior.cs` | Politics/war | — | — | — | — | — | M | — | TODO |
| P1 | `Behaviors/MarriageHealthRules.cs` | Court/title | — | — | — | — | — | M | — | TODO |
| P1 | `Behaviors/MarriageHouseHealth.cs` | Court/title | — | — | M | — | — | M | — | TODO |
| P1 | `Behaviors/MarriageMatchmakingRules.cs` | Court/title | — | — | M | — | — | — | — | TODO |
| P1 | `Behaviors/PrivyCouncilBehavior.cs` | Court/title | M | — | — | — | — | — | — | TODO |
| P1 | `Behaviors/ProxyWarBehavior.cs` | Politics/war | — | — | M | — | — | — | — | TODO |
| P1 | `Behaviors/RegencyAdulthood.cs` | Behavior | A | — | — | — | — | — | — | TODO |
| P1 | `Behaviors/RegencyBehavior.cs` | Behavior | M | — | — | — | — | — | — | TODO |
| P0 | `Behaviors/RestoredRealmOrphanRecovery.cs` | Behavior | A | — | — | — | — | — | YES | TODO |
| P0 | `Behaviors/RestoredRealmRecovery.cs` | Behavior | A | — | — | — | — | — | YES | TODO |
| P1 | `Behaviors/RetainerIndentureDialogues.cs` | Court/title | — | — | — | — | — | A | — | TODO |
| P1 | `Behaviors/RetainerIndentures.cs` | Court/title | — | — | — | — | — | A | — | TODO |
| P1 | `Behaviors/SpecificMarriageProposalBehavior.cs` | Court/title | — | — | M | — | — | M | — | TODO |
| P1 | `Behaviors/StrategicMarriageBehavior.cs` | Court/title | — | — | M | — | — | M | — | TODO |
| P1 | `Behaviors/StrategicMarriageProspects.cs` | Court/title | — | — | — | — | — | M | — | TODO |
| P1 | `Behaviors/TitleAcquisitionBehavior.cs` | Court/title | — | — | A | — | — | — | — | TODO |
| P1 | `Behaviors/VassalLordshipDialogues.cs` | Court/title | — | — | A | M | M | — | — | TODO |
| P1 | `Behaviors/VassalLordships.cs` | Court/title | — | — | A | M | M | — | — | TODO |
| P1 | `Behaviors/WarScoreBehavior.cs` | Politics/war | — | — | — | M | — | — | — | TODO |
| P2 | `BellumCivile.csproj` | Politics/war | — | — | M | — | — | — | — | TODO |
| P1 | `BellumCivileConstants.cs` | Politics/war | M | — | M | — | — | M | — | TODO |
| P2 | `BellumCivileOptions.cs` | Politics/war | M | — | — | — | — | — | — | TODO |
| P0 | `BellumCivileSaveDefiner.cs` | Save/state | M | — | M | — | M | M | YES | TODO |
| P1 | `BellumCivileSettings.cs` | Politics/war | M | — | — | — | — | M | — | TODO |
| P2 | `BellumClanPoliticsModel.cs` | Other | — | — | M | — | — | — | — | TODO |
| P2 | `BellumFeudalClanFinanceModel.cs` | Other | — | — | M | — | — | — | — | TODO |
| P2 | `BellumIntegrationLordships.cs` | Court/title | — | — | A | — | — | — | — | TODO |
| P2 | `BellumMarriageModel.cs` | Court/title | — | — | M | — | — | — | — | TODO |
| P2 | `CheatCommands.cs` | Other | — | — | — | — | M | — | — | TODO |
| P0 | `CivilWarCollapseRecord.cs` | Save/state | M | — | — | — | — | — | YES | TODO |
| P2 | `CourtClientGrantObjectiveSource.cs` | Court/title | — | — | — | — | M | — | — | TODO |
| P1 | `CourtClientGrantRecord.cs` | Save/state | — | — | — | — | M | — | — | TODO |
| P1 | `CourtTitleGrantRecord.cs` | Save/state | M | — | — | — | — | — | — | TODO |
| P2 | `DynamicKingdomTitleNameHelper.cs` | Politics/war | — | M | — | — | — | — | — | TODO |
| P2 | `DynamicMercenaryBandService.cs` | Other | — | — | M | — | — | — | — | TODO |
| P2 | `EstateInheritanceDisplay.cs` | Other | — | — | M | — | — | — | — | TODO |
| P2 | `FactionObject.cs` | Politics/war | M | M | — | — | — | — | — | TODO |
| P2 | `FeudalTitleActionPreviews.cs` | Court/title | — | M | — | — | — | — | — | TODO |
| P2 | `FeudalTitleConfig.cs` | Court/title | — | — | — | M | — | — | — | TODO |
| P2 | `FeudalTitleDisplayHelper.cs` | Court/title | — | — | M | M | — | M | — | TODO |
| P2 | `FeudalTitlePlayerActionService.cs` | Court/title | — | M | M | — | — | — | — | TODO |
| P2 | `GUI/Prefabs/KingdomManagement/Factions/BellumFactionsPanel.xml` | Politics/war | M | — | — | — | — | — | — | TODO |
| P2 | `GUI/Prefabs/KingdomManagement/Hierarchy/BellumHierarchyPanel.xml` | Politics/war | — | — | M | — | — | — | — | TODO |
| P2 | `GUI/Prefabs/KingdomManagement/Hierarchy/BellumHierarchyTitleTreeNode.xml` | Politics/war | — | — | M | — | — | — | — | TODO |
| P2 | `GUI/Prefabs/Parley/BellumPeaceParley.xml` | Politics/war | M | — | — | — | — | — | — | TODO |
| P1 | `HostagePactRecord.cs` | Save/state | M | — | — | — | — | — | — | TODO |
| P2 | `HostagePactRules.cs` | Politics/war | M | — | — | — | — | — | — | TODO |
| P2 | `HouseholdMembership.cs` | Court/title | — | — | A | — | — | M | — | TODO |
| P2 | `IndependentKingdomProfile.cs` | Politics/war | M | — | — | — | — | — | — | TODO |
| P2 | `KingdomVisualHelper.cs` | Politics/war | M | — | — | — | — | — | — | TODO |
| P2 | `LordshipEligibility.cs` | Court/title | — | — | A | M | M | M | — | TODO |
| P2 | `LordshipHapIncome.cs` | Court/title | — | — | — | — | A | — | — | TODO |
| P2 | `LordshipIncome.cs` | Court/title | — | — | A | — | M | — | — | TODO |
| P2 | `LordshipPlayerActions.cs` | Court/title | — | — | A | M | M | M | — | TODO |
| P2 | `MarriageAllianceHelper.cs` | Politics/war | — | — | — | — | — | M | — | TODO |
| P2 | `MarriageParticipantPolicy.cs` | Court/title | — | — | A | — | — | M | — | TODO |
| P1 | `ModuleData/bellum_concepts.xml` | Data/XML | M | — | — | — | — | — | — | TODO |
| P1 | `ModuleData/bellum_feudal_titles_patch.xml` | Data/XML | — | — | M | — | — | — | — | TODO |
| P1 | `ModuleData/bellum_feudal_titles.xml` | Data/XML | — | — | M | — | — | M | — | TODO |
| P1 | `ModuleData/bellum_title_styles_anglicized.xml` | Data/XML | — | — | M | M | — | M | — | TODO |
| P1 | `ModuleData/bellum_title_styles_bannerkings.xml` | Data/XML | — | — | M | M | — | M | — | TODO |
| P1 | `ModuleData/bellum_title_styles_immersive.xml` | Data/XML | — | — | M | M | — | M | — | TODO |
| P1 | `ModuleData/Languages/EN/strings.xml` | Data/XML | M | — | M | M | M | M | — | TODO |
| P2 | `NexusModDescription_Revised.txt` | Other | — | — | — | — | D | — | — | TODO |
| P1 | `Patches/AsylumVisitorPatches.cs` | Harmony | — | — | — | — | A | — | — | TODO |
| P0 | `Patches/CivilWarParentDestructionPatch.cs` | Harmony | M | — | — | — | — | — | YES | TODO |
| P1 | `Patches/CompanionMarriageTransferPatch.cs` | Harmony | — | — | A | — | — | — | — | TODO |
| P1 | `Patches/CourtDynasticPatches.cs` | Harmony | — | — | — | — | — | M | — | TODO |
| P1 | `Patches/DiplomacyRuntimeCompatibilityPatches.cs` | Harmony | — | — | — | M | — | — | — | TODO |
| P1 | `Patches/FamilyTreeRefreshCompatibility.cs` | Harmony | — | — | A | — | — | — | — | TODO |
| P1 | `Patches/FeudalTitleHeroNamePatch.cs` | Harmony | — | — | M | — | — | M | — | TODO |
| P1 | `Patches/FiefVoteResolutionPatch.cs` | Harmony | — | M | — | — | — | — | — | TODO |
| P1 | `Patches/HouseholdOccupationDisplayPatch.cs` | Harmony | — | — | A | — | — | — | — | TODO |
| P1 | `Patches/LordshipAppointmentPatches.cs` | Harmony | — | — | A | M | M | M | — | TODO |
| P1 | `Patches/LordshipFinancePatches.cs` | Harmony | — | — | A | — | M | M | — | TODO |
| P1 | `Patches/LordshipMapBannerPatch.cs` | Harmony | — | — | A | — | M | — | — | TODO |
| P0 | `Patches/PeaceParleyEntryPointPatches.cs` | Harmony | — | — | — | M | — | — | — | TODO |
| P1 | `Patches/ProtectedRealmLoadMigrationPatch.cs` | Harmony | A | — | — | — | — | — | — | TODO |
| P1 | `Patches/RealmLeadershipDiagnosticPatch.cs` | Harmony | A | — | — | — | — | — | — | TODO |
| P1 | `Patches/RegencyAdulthoodEventPatch.cs` | Harmony | A | — | — | — | — | — | — | TODO |
| P1 | `Patches/SeparateSpouseHouseholdPatch.cs` | Harmony | — | — | — | — | — | M | — | TODO |
| P1 | `Patches/TitleAcquisitionNotificationPatch.cs` | Harmony | — | — | A | — | — | — | — | TODO |
| P1 | `Patches/VassalLordshipPatches.cs` | Harmony | — | — | A | — | — | — | — | TODO |
| P2 | `PeaceReadiness.cs` | Politics/war | M | — | — | — | — | — | — | TODO |
| P2 | `PendingMarriageProspect.cs` | Court/title | — | — | — | — | — | M | — | TODO |
| P1 | `PersonalLordshipRecord.cs` | Save/state | — | — | A | — | M | M | — | TODO |
| P2 | `PlayerMarriagePricing.cs` | Court/title | — | — | — | — | — | M | — | TODO |
| P2 | `README.md` | Other | M | M | M | M | M | — | — | TODO |
| P2 | `RealmLeadershipDiagnostics.cs` | Other | A | — | — | — | — | — | — | TODO |
| P2 | `RegencyAdulthoodEquipment.cs` | Other | A | — | — | — | — | — | — | TODO |
| P1 | `RegencyRecord.cs` | Save/state | M | — | — | — | — | — | — | TODO |
| P2 | `RelationMemoryService.cs` | Other | M | — | M | — | M | — | — | TODO |
| P0 | `RestoredRealmCreationRecord.cs` | Save/state | A | — | — | — | — | — | YES | TODO |
| P1 | `RetainerIndentureRecord.cs` | Save/state | — | — | — | — | — | A | — | TODO |
| P2 | `SubModule.cs` | Other | — | — | M | — | M | — | — | TODO |
| P2 | `Tests/AcceptedIndependence.Tests.ps1` | Tests | A | — | — | — | — | — | — | TODO |
| P2 | `Tests/AsylumAudience.Tests.ps1` | Tests | — | — | — | — | A | — | — | TODO |
| P2 | `Tests/BilateralMarriage.Tests.ps1` | Tests | — | — | — | — | — | M | — | TODO |
| P2 | `Tests/ClaimFeudPlayerControl.Tests.ps1` | Tests | M | — | — | — | — | — | — | TODO |
| P2 | `Tests/CourtRedesignHarness/CourtRedesignHarness.csproj` | Tests | — | — | — | — | — | M | — | TODO |
| P2 | `Tests/CourtRedesignHarness/Program.cs` | Tests | — | — | — | — | — | M | — | TODO |
| P2 | `Tests/CourtTitleGrant.Tests.ps1` | Tests | M | — | — | — | — | — | — | TODO |
| P2 | `Tests/CrownPanelCleanup.Tests.ps1` | Tests | M | — | — | — | — | — | — | TODO |
| P2 | `Tests/EstateInheritanceDisplay.Tests.ps1` | Tests | — | — | M | — | — | — | — | TODO |
| P2 | `Tests/ForcedAbdication.Tests.ps1` | Tests | M | — | — | — | — | — | — | TODO |
| P2 | `Tests/HierarchyActionMenu.Tests.ps1` | Tests | — | M | M | — | — | — | — | TODO |
| P2 | `Tests/IndependenceRulerSaveRepair.Tests.ps1` | Tests | A | — | — | — | — | — | — | TODO |
| P2 | `Tests/InheritedPossession.Tests.ps1` | Tests | — | M | — | — | — | — | — | TODO |
| P2 | `Tests/PartyVisualRefresh.Tests.ps1` | Tests | A | — | — | — | — | — | — | TODO |
| P2 | `Tests/PeaceParleyCapitulation.Tests.ps1` | Tests | A | — | — | — | — | — | — | TODO |
| P2 | `Tests/PeaceParleyOverBudget.Tests.ps1` | Tests | M | — | — | — | — | — | — | TODO |
| P2 | `Tests/RealmLeadershipDiagnostics.Tests.ps1` | Tests | A | — | — | — | — | — | — | TODO |
| P2 | `Tests/RegencyAdulthood.Tests.ps1` | Tests | A | — | — | — | — | — | — | TODO |
| P0 | `Tests/RestoredRealmLifecycleAudit.md` | Tests | A | — | — | — | D | — | — | TODO |
| P0 | `Tests/RestoredRealmRecovery.Tests.ps1` | Tests | A | — | — | — | — | — | — | TODO |
| P2 | `Tests/SettlementBarter.Tests.ps1` | Tests | — | M | — | — | — | — | — | TODO |
| P0 | `Tests/SuccessionEngineHarness/AcceptedIndependenceTests.cs` | Tests | A | — | — | — | — | — | — | TODO |
| P0 | `Tests/SuccessionEngineHarness/AlliancePeaceTests.cs` | Tests | — | — | — | A | — | — | — | TODO |
| P0 | `Tests/SuccessionEngineHarness/AsylumDialogueFlowTests.cs` | Tests | — | — | — | — | A | — | — | TODO |
| P0 | `Tests/SuccessionEngineHarness/AsylumVisitTests.cs` | Tests | — | — | — | — | A | — | — | TODO |
| P0 | `Tests/SuccessionEngineHarness/CampaignRunRecoveryTests.cs` | Tests | A | — | — | — | — | — | — | TODO |
| P0 | `Tests/SuccessionEngineHarness/CampaignUiStartupProbe.cs` | Tests | — | — | M | — | M | — | — | TODO |
| P0 | `Tests/SuccessionEngineHarness/CaptainTitleTests.cs` | Tests | — | — | — | — | — | A | — | TODO |
| P0 | `Tests/SuccessionEngineHarness/CivilWarGraceTests.cs` | Tests | M | — | — | — | — | — | — | TODO |
| P0 | `Tests/SuccessionEngineHarness/ClaimFeudCooldownTests.cs` | Tests | — | A | — | — | — | — | — | TODO |
| P0 | `Tests/SuccessionEngineHarness/CollapseClaimantRecoveryTests.cs` | Tests | A | — | — | — | — | — | — | TODO |
| P0 | `Tests/SuccessionEngineHarness/CompanionOffspringTests.cs` | Tests | — | — | — | — | — | A | — | TODO |
| P0 | `Tests/SuccessionEngineHarness/CourtClientGrantTests.cs` | Tests | — | — | — | — | M | — | — | TODO |
| P0 | `Tests/SuccessionEngineHarness/CourtTitleGrantEngineTests.cs` | Tests | M | — | — | — | — | — | — | TODO |
| P0 | `Tests/SuccessionEngineHarness/CrownRebellionSafetyTests.cs` | Tests | A | — | — | — | — | — | — | TODO |
| P0 | `Tests/SuccessionEngineHarness/DynamicMercenaryPartyRepairTests.cs` | Tests | — | — | A | — | — | — | — | TODO |
| P0 | `Tests/SuccessionEngineHarness/DynamicMercenarySpawnTests.cs` | Tests | — | — | A | — | — | — | — | TODO |
| P0 | `Tests/SuccessionEngineHarness/EncyclopediaFamilyCompatibilityTests.cs` | Tests | — | — | A | — | M | — | — | TODO |
| P0 | `Tests/SuccessionEngineHarness/EncyclopediaFamilyTests.cs` | Tests | — | — | A | — | — | — | — | TODO |
| P0 | `Tests/SuccessionEngineHarness/EncyclopediaInheritanceLayoutTests.cs` | Tests | — | — | M | — | — | — | — | TODO |
| P0 | `Tests/SuccessionEngineHarness/EstateInheritanceTooltipTests.cs` | Tests | — | — | A | — | — | — | — | TODO |
| P0 | `Tests/SuccessionEngineHarness/ExileRecoveryTests.cs` | Tests | — | — | — | — | M | — | — | TODO |
| P0 | `Tests/SuccessionEngineHarness/FamilyTreeRefreshCompatibilityTests.cs` | Tests | — | — | A | — | — | — | — | TODO |
| P0 | `Tests/SuccessionEngineHarness/FiefRedistributionTests.cs` | Tests | — | A | — | — | M | — | — | TODO |
| P0 | `Tests/SuccessionEngineHarness/HapLordshipIncomeTests.cs` | Tests | — | — | — | — | A | — | — | TODO |
| P0 | `Tests/SuccessionEngineHarness/HierarchyPerformanceTests.cs` | Tests | — | — | — | — | A | — | — | TODO |
| P0 | `Tests/SuccessionEngineHarness/HighwaymenCleanupTests.cs` | Tests | — | — | A | — | — | — | — | TODO |
| P0 | `Tests/SuccessionEngineHarness/HostagePactDurationTests.cs` | Tests | M | — | — | — | — | — | — | TODO |
| P0 | `Tests/SuccessionEngineHarness/HostageTreatyTermTests.cs` | Tests | M | — | — | — | — | — | — | TODO |
| P0 | `Tests/SuccessionEngineHarness/HouseholdMembershipTests.cs` | Tests | — | — | — | — | — | A | — | TODO |
| P0 | `Tests/SuccessionEngineHarness/IndependenceRulerRepairTests.cs` | Tests | A | — | — | — | — | — | — | TODO |
| P0 | `Tests/SuccessionEngineHarness/IntegrationSaveDefinitionTests.cs` | Tests | M | — | M | — | — | — | — | TODO |
| P0 | `Tests/SuccessionEngineHarness/InternalPeaceTests.cs` | Tests | M | — | — | — | — | — | — | TODO |
| P0 | `Tests/SuccessionEngineHarness/LordshipApiTests.cs` | Tests | — | — | A | — | — | — | — | TODO |
| P0 | `Tests/SuccessionEngineHarness/LordshipAppointmentTests.cs` | Tests | — | — | — | — | A | M | — | TODO |
| P0 | `Tests/SuccessionEngineHarness/LordshipBeneficiaryBannerTests.cs` | Tests | — | — | — | — | A | — | — | TODO |
| P0 | `Tests/SuccessionEngineHarness/LordshipDialogueFlowTests.cs` | Tests | — | — | — | — | A | M | — | TODO |
| P0 | `Tests/SuccessionEngineHarness/LordshipDisplayTests.cs` | Tests | — | — | A | — | — | — | — | TODO |
| P0 | `Tests/SuccessionEngineHarness/LordshipFinanceStartupTests.cs` | Tests | — | — | — | — | A | — | — | TODO |
| P0 | `Tests/SuccessionEngineHarness/LordshipHierarchyTests.cs` | Tests | — | — | A | — | — | — | — | TODO |
| P0 | `Tests/SuccessionEngineHarness/LordshipNamingTests.cs` | Tests | — | — | — | A | M | M | — | TODO |
| P0 | `Tests/SuccessionEngineHarness/LordshipTests.cs` | Tests | — | — | A | — | — | — | — | TODO |
| P0 | `Tests/SuccessionEngineHarness/LordshipVassalTests.cs` | Tests | — | — | A | M | — | — | — | TODO |
| P0 | `Tests/SuccessionEngineHarness/LordshipVisualTests.cs` | Tests | — | — | A | — | — | — | — | TODO |
| P0 | `Tests/SuccessionEngineHarness/MarriageClaimForecastTests.cs` | Tests | — | — | M | — | — | — | — | TODO |
| P0 | `Tests/SuccessionEngineHarness/MarriageCombinedScoreTests.cs` | Tests | — | — | M | — | — | M | — | TODO |
| P0 | `Tests/SuccessionEngineHarness/MarriageHealthCacheTests.cs` | Tests | — | — | M | — | — | M | — | TODO |
| P0 | `Tests/SuccessionEngineHarness/MarriageHeiressSimulation.cs` | Tests | — | — | M | — | — | M | — | TODO |
| P0 | `Tests/SuccessionEngineHarness/MarriageHouseholdTests.cs` | Tests | — | — | — | — | — | M | — | TODO |
| P0 | `Tests/SuccessionEngineHarness/MarriageMatchmakingTests.cs` | Tests | — | — | — | — | — | M | — | TODO |
| P0 | `Tests/SuccessionEngineHarness/MarriageOfferCommandTests.cs` | Tests | — | — | — | — | — | M | — | TODO |
| P0 | `Tests/SuccessionEngineHarness/MarriageProposalDialogueTests.cs` | Tests | — | — | — | — | — | A | — | TODO |
| P0 | `Tests/SuccessionEngineHarness/MarriageProspectTests.cs` | Tests | — | — | — | — | — | M | — | TODO |
| P0 | `Tests/SuccessionEngineHarness/MarriageRevisionTests.cs` | Tests | — | — | — | — | — | A | — | TODO |
| P0 | `Tests/SuccessionEngineHarness/MercenaryLeaderStyleTests.cs` | Tests | — | — | — | — | — | M | — | TODO |
| P0 | `Tests/SuccessionEngineHarness/PartyNavigationTestScene.cs` | Tests | — | — | A | — | — | — | — | TODO |
| P0 | `Tests/SuccessionEngineHarness/PartyVisualRefreshTests.cs` | Tests | A | — | — | — | — | — | — | TODO |
| P0 | `Tests/SuccessionEngineHarness/PeaceCouncilReadinessTests.cs` | Tests | M | — | — | — | — | — | — | TODO |
| P0 | `Tests/SuccessionEngineHarness/PeaceParleyCapitulationTests.cs` | Tests | A | — | — | — | — | — | — | TODO |
| P0 | `Tests/SuccessionEngineHarness/PeaceReadinessTests.cs` | Tests | M | — | — | — | — | — | — | TODO |
| P0 | `Tests/SuccessionEngineHarness/PlayerMarriageAgreementTests.cs` | Tests | — | — | — | — | — | M | — | TODO |
| P0 | `Tests/SuccessionEngineHarness/PrefabFinalizationCompatibilityTests.cs` | Tests | — | — | — | — | A | — | — | TODO |
| P0 | `Tests/SuccessionEngineHarness/PregnancyVisitGuardTests.cs` | Tests | — | — | — | — | — | A | — | TODO |
| P0 | `Tests/SuccessionEngineHarness/Program.cs` | Tests | M | M | M | M | M | M | — | TODO |
| P0 | `Tests/SuccessionEngineHarness/RealmLeadershipDiagnosticTests.cs` | Tests | A | — | — | — | — | — | — | TODO |
| P0 | `Tests/SuccessionEngineHarness/RealmNameTests.cs` | Tests | — | M | — | — | — | — | — | TODO |
| P0 | `Tests/SuccessionEngineHarness/RegencyAdulthoodTests.cs` | Tests | A | — | — | — | — | — | — | TODO |
| P0 | `Tests/SuccessionEngineHarness/RegencySettingsTests.cs` | Tests | M | — | — | — | — | — | — | TODO |
| P0 | `Tests/SuccessionEngineHarness/RestoredRealmRecoveryTests.cs` | Tests | A | — | — | — | — | — | — | TODO |
| P0 | `Tests/SuccessionEngineHarness/RetainerIndentureTests.cs` | Tests | — | — | — | — | — | A | — | TODO |
| P0 | `Tests/SuccessionEngineHarness/RetainerMarriageTests.cs` | Tests | — | — | A | — | — | M | — | TODO |
| P0 | `Tests/SuccessionEngineHarness/SuccessionEngineHarness.csproj` | Tests | M | — | M | — | M | — | — | TODO |
| P0 | `Tests/SuccessionEngineHarness/TitleAcquisitionTests.cs` | Tests | — | — | A | — | — | — | — | TODO |
| P0 | `Tests/SuccessionEngineHarness/TitleNameCacheTests.cs` | Tests | — | — | — | — | — | M | — | TODO |
| P0 | `Tests/SuccessionEngineHarness/TitlePresetLocalizationTests.cs` | Tests | — | — | M | M | — | M | — | TODO |
| P2 | `Tests/TreatyDurationSettings.Tests.ps1` | Tests | A | — | — | — | — | — | — | TODO |
| P2 | `TitleAcquiredMapNotification.cs` | Court/title | — | — | A | — | — | — | — | TODO |
| P2 | `TownPartyPositionHelper.cs` | Other | — | — | A | — | — | — | — | TODO |
| P2 | `TreatyAiDraftService.cs` | Politics/war | M | — | — | — | — | — | — | TODO |
| P2 | `TreatyHostageTerms.cs` | Politics/war | M | — | — | — | — | — | — | TODO |
| P2 | `TreatyRatificationService.cs` | Politics/war | M | — | — | — | — | — | — | TODO |
| P2 | `TreatyRoyalMarriageService.cs` | Politics/war | — | — | M | — | — | — | — | TODO |
| P1 | `TreatyTermRecord.cs` | Save/state | M | — | — | — | — | — | — | TODO |
| P2 | `UI/EncyclopediaClanHouseholdMixin.cs` | UI | — | — | A | — | — | — | — | TODO |
| P2 | `UI/EncyclopediaClanHouseholdPrefabPatch.cs` | UI | — | — | A | — | M | — | — | TODO |
| P2 | `UI/EncyclopediaFamilyLayoutCompatibility.cs` | UI | — | — | A | — | M | — | — | TODO |
| P2 | `UI/EncyclopediaFamilyPrefabFinalizationPatch.cs` | UI | — | — | A | — | M | — | — | TODO |
| P2 | `UI/EncyclopediaHeroFamilyMixin.cs` | UI | — | — | A | — | — | — | — | TODO |
| P2 | `UI/EncyclopediaHeroFamilyPrefabPatch.cs` | UI | — | — | A | — | M | — | — | TODO |
| P2 | `UI/EncyclopediaHeroFamilyVM.cs` | UI | — | — | A | — | — | — | — | TODO |
| P2 | `UI/EncyclopediaHeroFeudalTitlesMixin.cs` | UI | — | — | M | — | — | — | — | TODO |
| P2 | `UI/EncyclopediaHeroFeudalTitlesPrefabExtension.cs` | UI | — | — | M | — | — | — | — | TODO |
| P2 | `UI/EncyclopediaNativeFamilyDividerPatch.cs` | UI | — | — | A | — | — | — | — | TODO |
| P2 | `UI/FactionsWindowVM.cs` | UI | M | — | — | — | — | — | — | TODO |
| P2 | `UI/KingdomManagementBellumFactionsVMMixin.cs` | UI | — | — | — | — | M | — | — | TODO |
| P2 | `UI/Parley/PeaceParleyHostages.cs` | UI | M | — | — | — | — | — | — | TODO |
| P2 | `UI/Parley/PeaceParleyVM.cs` | UI | M | — | — | M | — | — | — | TODO |
| P2 | `UI/TitleAcquiredNotificationItemVM.cs` | UI | — | — | A | — | — | — | — | TODO |
| P2 | `UI/VanillaTabs/Kingdoms/Hierarchy/HierarchyBuildContext.cs` | UI | — | — | — | — | A | — | — | TODO |
| P2 | `UI/VanillaTabs/Kingdoms/Hierarchy/HierarchyTitleNodeVM.cs` | UI | — | M | M | M | M | — | — | TODO |
| P2 | `UI/VanillaTabs/Kingdoms/Hierarchy/HierarchyTitleTreeNodeWidget.cs` | UI | — | — | A | — | — | — | — | TODO |
| P2 | `UI/VanillaTabs/Kingdoms/Hierarchy/KingdomHierarchyTabVM.cs` | UI | — | — | M | — | M | — | — | TODO |

## Pending coverage blockers / separate checks

- [ ] Establish official author's **1.4.5 source tree SHA**, or match the available 1.4.5 release archive to a commit/tree; then **regenerate the first interval** and count. Keep the conservative pre-1.4.6 checkpoint until evidence replaces it.
- [ ] Check inter-checkpoint **commit-by-commit paths** for any file changed and fully reverted within one interval. The matrix intentionally does not claim such transient history was exhaustively inspected.
- [ ] Compare independent Draft PR #2–#7 and PR #9–#13 against latest upstream, custom Native features, and each other. PR #7 (collapse ID reference guard) is **not** included in the #9→#13 stack; validate merge ordering, don't assume it is integrated.
- [ ] Compare upstream 1.4.10 → 1.4.11 new save classes `LordshipCommandTransferRecord` (ID 143), `RetainerIndentureRecord` (ID 144), dependencies and containers; they do not exist in our staged Native as part of this port. Never import those IDs without importing and testing the corresponding feature.
- [ ] Review changed public APIs/callers (Bellum Bridge compatibility, Native politics, titles, retainer/lordship/marriage, Dynasty, Kingdom, Court), all Harmony patches, tests and XML assets. Preserve custom war/peace Revamp OFF behavior and player ruler/court logic.
- [ ] Perform Windows P101A–F regression suite, upstream-derived restored realm and claimant harness tests, full Native compile, Bellum Bridge ABI/load, and in-game before/after logs on copied historical saves and fresh campaign. Explicitly record tests executed, outputs and failures; static matching is not behavioral proof.
- [ ] Do not auto-repair old saves; P1-01G concluded retroactive faction membership cannot be safely inferred without provenance.

**Update discipline:** mark each audited row only after inspecting its source and affected callers; maintain a small explicit audit/decision log and per-row source SHA. Do not automatically mark 1.4.10→1.4.11 core files as safe just because upstream blob hashes match. This file is an inventory checkpoint, **not a migration certificate**.
