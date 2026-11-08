# Bellum Civile upstream changes — source-file audit matrix (1.4.5 → 1.4.11)

> **Status: INVENTORY ONLY, NOT A COMPLETED PORT.** Created 2026-11-08. This file is intentionally committed to a **docs-only audit branch** of our Native Bellum fork. **Do not confuse** this fork with Bellum Bridge (`AIRebelRelay/Bannerlord2-AiInfluence-BellumCivile`) or Relay Bridge (`AIRebelRelay/ai-rebel-relay-bridge`). No production files changed.

## Source-of-truth and baseline caveat

- **Custom Native Bellum:** `AIRebelRelay/BellumCivile` main @ `71c7ab8b8b7a21fc2661f5f25e0a18d74b952ca7`; our label **1.4.6**, with user-confirmed functional ancestry **official 1.4.5 + custom changes**. This is **not** official upstream 1.4.6 source.
- **Prepared stacked Native drafts:** PR #9 → #10 → #11 → #12 → #13, combined head `a7a7d39e3bacac4799dc2d301831b2926171ebea`; these are **not merged**. A "Draft touched" mark is a candidate for review, **not** proof of upstream parity.
- **Official upstream:** [`Vonbalt/BellumCivile`](https://github.com/Vonbalt/BellumCivile); target frozen commit `da426b23c64f3a66ae2b389d2db8f23489736bf9` (source `v1.4.11`). No `v1.4.x` git refs/tags resolved through repository file access; all comparisons below use **immutable full SHA**.
- **1.4.5† CANDIDATE (source-backed, NOT RELEASE-BINARY-VERIFIED):** official Nexus [version 1.4.5 history](https://www.nexusmods.com/mountandblade2bannerlord/mods/10609?BH=14) lists the Oct 17–18 fixes (siege ownership, hostage checks, MCM instability/regency, Enforce Peace). In `Vonbalt/BellumCivile` those exact successive commits culminate in `b1d9a4e8fb74d4f9dd045793c156abeac6f9f4eb` (2026-10-18 02:30 UTC), before next known v1.4.6-era code. **Crucially our Native main `BellumCivileSaveDefiner.cs` Git blob `ca7ce54894239d7132b3ab79c81bcf1fc3037402` exactly matches this upstream commit** (99 class IDs, 97 containers). Git `_Module/SubModule.xml` still says `v1.4.4` in this candidate, so the exact **published 1.4.5 package source SHA is not independently proven**. Use this *high-confidence historical source candidate* as the narrower first checkpoint, and recheck against the release archive once obtainable.
- **Additional boundary nuance:** upstream module version string can lag development changes: early commits for a later feature sometimes still carry an earlier `SubModule.xml` version. These checkpoints are **version-era source snapshots**, not independently proven release-package contents. Verify against actual released archives when determining an exact version boundary.

## Frozen comparison checkpoints

| Phase | Base SHA | Head SHA | Commits | GitHub diff files | Source compare |
|---|---|---|---:|---:|---|
| 1.4.5† → 1.4.6 | `b1d9a4e8fb74d4f9dd045793c156abeac6f9f4eb` | `2e4232521c469f5a9603c33cc1da5c2673a99162` | 21 | 143 | [Compare](https://github.com/Vonbalt/BellumCivile/compare/b1d9a4e8fb74d4f9dd045793c156abeac6f9f4eb...2e4232521c469f5a9603c33cc1da5c2673a99162) |
| 1.4.6 → 1.4.7 | `2e4232521c469f5a9603c33cc1da5c2673a99162` | `d93a20269e66226843df764be69b8a0dd1f264a0` | 5 | 19 | [Compare](https://github.com/Vonbalt/BellumCivile/compare/2e4232521c469f5a9603c33cc1da5c2673a99162...d93a20269e66226843df764be69b8a0dd1f264a0) |
| 1.4.7 → 1.4.8 | `d93a20269e66226843df764be69b8a0dd1f264a0` | `ea0cc7b555bd05e4d246d5b1c98f643ec81da3d4` | 7 | 102 | [Compare](https://github.com/Vonbalt/BellumCivile/compare/d93a20269e66226843df764be69b8a0dd1f264a0...ea0cc7b555bd05e4d246d5b1c98f643ec81da3d4) |
| 1.4.8 → 1.4.9 | `ea0cc7b555bd05e4d246d5b1c98f643ec81da3d4` | `e2ff7d074adeef3b539e7ec47094171c388b6842` | 4 | 28 | [Compare](https://github.com/Vonbalt/BellumCivile/compare/ea0cc7b555bd05e4d246d5b1c98f643ec81da3d4...e2ff7d074adeef3b539e7ec47094171c388b6842) |
| 1.4.9 → 1.4.10 | `e2ff7d074adeef3b539e7ec47094171c388b6842` | `fe799297ed931ee0d1b69d8a7d4f57a7c22dd983` | 11 | 61 | [Compare](https://github.com/Vonbalt/BellumCivile/compare/e2ff7d074adeef3b539e7ec47094171c388b6842...fe799297ed931ee0d1b69d8a7d4f57a7c22dd983) |
| 1.4.10 → 1.4.11 | `fe799297ed931ee0d1b69d8a7d4f57a7c22dd983` | `da426b23c64f3a66ae2b389d2db8f23489736bf9` | 10 | 64 | [Compare](https://github.com/Vonbalt/BellumCivile/compare/fe799297ed931ee0d1b69d8a7d4f57a7c22dd983...da426b23c64f3a66ae2b389d2db8f23489736bf9) |

**Inventory:** **304 unique file paths**, union of **417 version-interval change entries** (same file can occur in several intervals). By initial review priority: P0=107, P1=96, P2=101. GitHub compare returned complete file arrays for these interval endpoints. This is a union of **checkpoint diffs**, not a per-commit audit of temporary changes later reverted inside an interval.

## How to use this tracker

1. Review **P0 first** (save schema, kingdom restoration, civil war, succession, war/peace ownership), then P1 (shared behavior, Harmony, settings, XML), then P2 (UI, tests, documentation). Do **not** treat matching file names as matching implementations.
2. For each path compare (a) original custom Native main `71c7ab8b8b7a`, (b) combined stacked PR #13 `a7a7d39e3bac`, (c) pinned official 1.4.9/1.4.10/1.4.11 SHA and earlier checkpoints; trace affected callers, shared dependencies and **custom features**. Record exact function/field/API mismatches.
3. Replace `TODO` with one of `MATCH`, `PARTIAL`, `MISSING`, `CUSTOM-KEEP`, `EXCLUDE-JUSTIFIED`, `NOT-IN-FORK` **only after a source-backed comparison**, and add commit/line/test evidence in the notes or a separate per-file issue. The initial `Draft touched?` flag does **not** imply completed validation.
4. Before production changes define ROOT CAUSE, TOUCH, DO NOT TOUCH, MUST FIX, MUST NOT CHANGE and RED/neighbor regressions. Isolate one stage per Draft PR; audit its entire diff; execute real Windows PowerShell / .NET Native build, Bellum Bridge ABI test and copied-old-save / new-game logs before merge. Do not merge directly to main or release while these gates are pending.
5. Preserve AI Influence external diplomacy ownership with Bellum War & Peace Revamp **OFF**, and verify no duplicate Bellum Bridge/Relay political events. Audit all new `SaveDefiner` class IDs, containers and original field IDs; never copy only newer schema registrations.

**Stage cell legend:** `A` added; `M` modified; `D` deleted; `R` renamed; `C` copied; `—` not in that endpoint's changed-file list. `Draft touched?` compares our original Native main to stacked PR #13. All rows start as `TODO` except `BellumCivileSaveDefiner.cs` = `PARTIAL` after the source-registry evidence below; no runtime or game QA completed. **5→6† uses the source-backed Oct 18 1.4.5 candidate**, not independently verified release-package source.

## Complete changed-file matrix — 304 paths

| Priority | File | Area | 5→6† | 6→7 | 7→8 | 8→9 | 9→10 | 10→11 | Draft touched? | Audit status |
|:---:|---|---|:---:|:---:|:---:|:---:|:---:|:---:|:---:|---|
| P2 | `_Module/SubModule.xml` | Module | M | M | M | M | M | M | — | TODO |
| P2 | `AlliancePeaceRestriction.cs` | Politics/war | — | — | — | A | — | — | — | TODO |
| P1 | `AsylumVisitRecord.cs` | Save/state | — | — | — | — | A | — | — | MISSING |
| P2 | `BC Changelog.txt` | Other | M | M | M | M | M | M | — | TODO |
| P1 | `Behaviors/AcceptedIndependence.cs` | Behavior | A | — | — | — | — | — | — | TODO |
| P1 | `Behaviors/BellumMarriageEvaluation.cs` | Court/title | — | — | M | — | — | M | — | TODO |
| P1 | `Behaviors/BellumMarriageStrategyHelper.cs` | Court/title | — | — | M | — | — | M | — | TODO |
| P0 | `Behaviors/CivilWarCollapseContinuation.cs` | Politics/war | M | — | — | — | — | — | YES | TODO |
| P0 | `Behaviors/CivilWarCrownTransfer.cs` | Politics/war | M | — | — | — | — | — | YES | TODO |
| P0 | `Behaviors/CivilWarGrace.cs` | Politics/war | A | — | — | — | — | — | — | MISSING |
| P0 | `Behaviors/CivilWarResolutionBehavior.cs` | Politics/war | M | — | — | — | — | — | YES | PARTIAL |
| P0 | `Behaviors/CivilWarSuccessionSettlement.cs` | Politics/war | M | — | — | — | — | — | — | TODO |
| P1 | `Behaviors/ClaimFeudBehavior.cs` | Behavior | — | M | — | — | — | — | — | TODO |
| P1 | `Behaviors/CouncilAppointmentDeliberationBehavior.cs` | Court/title | M | — | — | — | — | — | — | TODO |
| P1 | `Behaviors/CourtAgendaBehavior.cs` | Court/title | M | — | — | — | M | — | — | TODO |
| P1 | `Behaviors/CourtAgendaPlayerFlow.cs` | Court/title | M | — | — | — | — | — | — | TODO |
| P1 | `Behaviors/CourtClientGrantAgendas.cs` | Court/title | — | — | — | — | M | — | — | TODO |
| P1 | `Behaviors/CourtCouncilAgendas.cs` | Court/title | M | — | — | — | — | — | — | TODO |
| P1 | `Behaviors/CourtExecutiveAgendas.cs` | Court/title | M | — | — | — | — | — | — | TODO |
| P1 | `Behaviors/CourtInstability.cs` | Court/title | M | — | — | — | — | — | — | TODO |
| P1 | `Behaviors/CourtNominationMandates.cs` | Court/title | M | — | — | — | — | — | — | TODO |
| P1 | `Behaviors/CourtPlayerCrownActions.cs` | Politics/war | — | — | — | — | M | — | — | TODO |
| P1 | `Behaviors/CourtPlayerMotionPicker.cs` | Court/title | M | — | — | — | — | — | — | TODO |
| P1 | `Behaviors/CourtTitleGrantAgendas.cs` | Court/title | M | — | — | — | — | — | — | TODO |
| P1 | `Behaviors/CourtTitleGrantRecipientFlow.cs` | Court/title | A | — | — | — | — | — | — | TODO |
| P1 | `Behaviors/CrownAbdication.cs` | Politics/war | M | — | — | — | — | — | — | TODO |
| P1 | `Behaviors/CrownAccessionBehavior.cs` | Politics/war | M | — | M | — | — | — | — | TODO |
| P1 | `Behaviors/CrownForcedAbdication.cs` | Politics/war | M | — | — | — | — | — | — | TODO |
| P1 | `Behaviors/CrownHouseholdRecovery.cs` | Politics/war | M | — | — | — | — | — | — | TODO |
| P1 | `Behaviors/CrownPlayerDeparture.cs` | Politics/war | A | — | — | — | — | — | — | TODO |
| P1 | `Behaviors/DynamicMercenaryBandBehavior.cs` | Behavior | M | — | M | — | — | — | — | TODO |
| P1 | `Behaviors/DynamicMercenaryPartyRepair.cs` | Behavior | — | — | A | — | — | — | — | TODO |
| P1 | `Behaviors/DynamicRelationBehavior.cs` | Behavior | — | — | M | — | — | — | — | TODO |
| P1 | `Behaviors/DynasticHeirBehavior.cs` | Behavior | M | — | — | — | — | — | — | TODO |
| P1 | `Behaviors/ElectiveContestBehavior.cs` | Behavior | M | — | — | — | — | — | — | TODO |
| P1 | `Behaviors/ExileAsylumDialogues.cs` | Behavior | — | — | — | — | A | — | — | TODO |
| P1 | `Behaviors/ExileAsylumTesting.cs` | Behavior | — | — | — | — | A | — | — | TODO |
| P1 | `Behaviors/ExileAsylumVisits.cs` | Behavior | — | — | — | — | A | — | — | MISSING |
| P1 | `Behaviors/ExiledClanRecoveryBehavior.cs` | Behavior | — | — | — | — | M | — | — | PARTIAL |
| P0 | `Behaviors/FactionManagerBehavior.cs` | Politics/war | M | — | — | — | — | — | YES | PARTIAL |
| P0 | `Behaviors/FactionSuccessionSafety.cs` | Politics/war | A | — | — | — | — | — | — | TODO |
| P1 | `Behaviors/FeudalAllocationCustody.cs` | Behavior | — | — | M | — | — | — | — | TODO |
| P1 | `Behaviors/FeudalClientLandGrant.cs` | Behavior | — | — | — | — | M | — | — | TODO |
| P1 | `Behaviors/FeudalTitleBehavior.cs` | Court/title | M | M | M | — | M | — | — | TODO |
| P1 | `Behaviors/ForeignTreatyBehavior.cs` | Politics/war | M | — | — | M | — | — | — | TODO |
| P1 | `Behaviors/HostagePactPlacement.cs` | Politics/war | M | — | — | — | — | — | — | TODO |
| P1 | `Behaviors/HostagePactTreatyDelivery.cs` | Politics/war | M | — | — | — | — | — | — | TODO |
| P1 | `Behaviors/IdeologyBehavior.cs` | Behavior | M | M | — | — | — | — | — | TODO |
| P1 | `Behaviors/IndependenceRulerSaveRepair.cs` | Behavior | A | — | — | — | — | — | — | TODO |
| P1 | `Behaviors/LordshipBehavior.cs` | Court/title | — | — | A | M | M | M | — | MISSING |
| P1 | `Behaviors/LordshipCommandTransfers.cs` | Court/title | — | — | — | — | — | A | — | MISSING |
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
| P1 | `Behaviors/RetainerIndentures.cs` | Court/title | — | — | — | — | — | A | — | MISSING |
| P1 | `Behaviors/SpecificMarriageProposalBehavior.cs` | Court/title | — | — | M | — | — | M | — | TODO |
| P1 | `Behaviors/StrategicMarriageBehavior.cs` | Court/title | — | — | M | — | — | M | — | TODO |
| P1 | `Behaviors/StrategicMarriageProspects.cs` | Court/title | — | — | — | — | — | M | — | TODO |
| P0 | `Behaviors/SuccessionChallengeBehavior.cs` | Politics/war | M | — | — | — | — | — | — | TODO |
| P0 | `Behaviors/SuccessionChallengeInitiation.cs` | Politics/war | M | — | — | — | — | — | — | TODO |
| P0 | `Behaviors/SuccessionChallengePlayer.cs` | Politics/war | M | — | — | — | — | — | — | TODO |
| P0 | `Behaviors/SuccessionChallengeWar.cs` | Politics/war | M | — | — | — | — | — | — | TODO |
| P1 | `Behaviors/TitleAcquisitionBehavior.cs` | Court/title | — | — | A | — | — | — | — | MISSING |
| P1 | `Behaviors/VassalLordshipDialogues.cs` | Court/title | — | — | A | M | M | — | — | TODO |
| P1 | `Behaviors/VassalLordships.cs` | Court/title | — | — | A | M | M | — | — | MISSING |
| P0 | `Behaviors/WarPeaceRevampBehavior.cs` | Politics/war | M | — | — | — | — | — | — | TODO |
| P1 | `Behaviors/WarScoreBehavior.cs` | Politics/war | — | — | — | M | — | — | — | TODO |
| P2 | `BellumCivile.csproj` | Politics/war | M | — | M | — | — | — | — | TODO |
| P1 | `BellumCivileConstants.cs` | Politics/war | M | — | M | — | — | M | — | TODO |
| P2 | `BellumCivileOptions.cs` | Politics/war | M | — | — | — | — | — | — | TODO |
| P0 | `BellumCivileSaveDefiner.cs` | Save/state | M | — | M | — | M | M | YES | PARTIAL |
| P1 | `BellumCivileSettings.cs` | Politics/war | M | — | — | — | — | M | — | TODO |
| P2 | `BellumClanPoliticsModel.cs` | Other | — | — | M | — | — | — | — | TODO |
| P2 | `BellumFeudalClanFinanceModel.cs` | Other | — | — | M | — | — | — | — | TODO |
| P2 | `BellumIntegrationLordships.cs` | Court/title | — | — | A | — | — | — | — | TODO |
| P2 | `BellumMarriageModel.cs` | Court/title | — | — | M | — | — | — | — | TODO |
| P2 | `CheatCommands.cs` | Other | — | — | — | — | M | — | — | TODO |
| P0 | `CivilWarCollapseRecord.cs` | Save/state | M | — | — | — | — | — | YES | TODO |
| P0 | `CivilWarGraceRecord.cs` | Save/state | A | — | — | — | — | — | — | MISSING |
| P2 | `CourtClientGrantObjectiveSource.cs` | Court/title | — | — | — | — | M | — | — | TODO |
| P1 | `CourtClientGrantRecord.cs` | Save/state | — | — | — | — | M | — | — | TODO |
| P1 | `CourtTitleGrantRecord.cs` | Save/state | M | — | — | — | — | — | — | TODO |
| P1 | `CrownAccessionRecord.cs` | Save/state | M | — | — | — | — | — | — | TODO |
| P2 | `DynamicKingdomTitleNameHelper.cs` | Politics/war | — | M | — | — | — | — | — | TODO |
| P2 | `DynamicMercenaryBandService.cs` | Other | — | — | M | — | — | — | — | TODO |
| P2 | `EstateInheritanceDisplay.cs` | Other | — | — | M | — | — | — | — | TODO |
| P2 | `FactionObject.cs` | Politics/war | M | M | — | — | — | — | — | TODO |
| P2 | `FeudalTitleActionPreviews.cs` | Court/title | — | M | — | — | — | — | — | TODO |
| P2 | `FeudalTitleConfig.cs` | Court/title | — | — | — | M | — | — | — | TODO |
| P2 | `FeudalTitleDisplayHelper.cs` | Court/title | — | — | M | M | — | M | — | TODO |
| P2 | `FeudalTitlePlayerActionService.cs` | Court/title | — | M | M | — | — | — | — | TODO |
| P2 | `GUI/Brushes/BellumParley.xml` | Other | A | — | — | — | — | — | — | TODO |
| P2 | `GUI/Prefabs/KingdomManagement/Factions/BellumFactionsPanel.xml` | Politics/war | M | — | — | — | — | — | — | TODO |
| P2 | `GUI/Prefabs/KingdomManagement/Hierarchy/BellumHierarchyPanel.xml` | Politics/war | — | — | M | — | — | — | — | TODO |
| P2 | `GUI/Prefabs/KingdomManagement/Hierarchy/BellumHierarchyTitleTreeNode.xml` | Politics/war | — | — | M | — | — | — | — | TODO |
| P2 | `GUI/Prefabs/Parley/BellumPeaceParley.xml` | Politics/war | M | — | — | — | — | — | — | TODO |
| P1 | `HostagePactRecord.cs` | Save/state | M | — | — | — | — | — | — | TODO |
| P2 | `HostagePactRules.cs` | Politics/war | M | — | — | — | — | — | — | TODO |
| P2 | `HouseholdMembership.cs` | Court/title | — | — | A | — | — | M | — | TODO |
| P2 | `IndependentKingdomProfile.cs` | Politics/war | M | — | — | — | — | — | — | TODO |
| P2 | `InternalInstabilityPresets.cs` | Other | M | — | — | — | — | — | — | TODO |
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
| P1 | `Patches/PlayerLandedSecessionPatch.cs` | Harmony | M | — | — | — | — | — | — | TODO |
| P1 | `Patches/ProtectedRealmLoadMigrationPatch.cs` | Harmony | A | — | — | — | — | — | — | TODO |
| P1 | `Patches/RealmLeadershipDiagnosticPatch.cs` | Harmony | A | — | — | — | — | — | — | TODO |
| P1 | `Patches/RecruitmentRankPatch.cs` | Harmony | A | — | — | — | — | — | — | TODO |
| P1 | `Patches/RegencyAdulthoodEventPatch.cs` | Harmony | A | — | — | — | — | — | — | TODO |
| P1 | `Patches/SeparateSpouseHouseholdPatch.cs` | Harmony | — | — | — | — | — | M | — | TODO |
| P1 | `Patches/TitleAcquisitionNotificationPatch.cs` | Harmony | — | — | A | — | — | — | — | TODO |
| P1 | `Patches/VassalLordshipPatches.cs` | Harmony | — | — | A | — | — | — | — | TODO |
| P2 | `PeaceReadiness.cs` | Politics/war | M | — | — | — | — | — | — | TODO |
| P2 | `PendingMarriageProspect.cs` | Court/title | — | — | — | — | — | M | — | TODO |
| P1 | `PersonalLordshipRecord.cs` | Save/state | — | — | A | — | M | M | — | MISSING |
| P2 | `PlayerMarriagePricing.cs` | Court/title | — | — | — | — | — | M | — | TODO |
| P2 | `README.md` | Other | M | M | M | M | M | — | — | TODO |
| P2 | `RealmLeadershipDiagnostics.cs` | Other | A | — | — | — | — | — | — | TODO |
| P2 | `RegencyAdulthoodEquipment.cs` | Other | A | — | — | — | — | — | — | TODO |
| P1 | `RegencyRecord.cs` | Save/state | M | — | — | — | — | — | — | TODO |
| P2 | `RelationMemoryService.cs` | Other | M | — | M | — | M | — | — | TODO |
| P0 | `RestoredRealmCreationRecord.cs` | Save/state | A | — | — | — | — | — | YES | TODO |
| P1 | `RetainerIndentureRecord.cs` | Save/state | — | — | — | — | — | A | — | MISSING |
| P2 | `SubModule.cs` | Other | — | — | M | — | M | — | — | PARTIAL |
| P2 | `Tests/AcceptedIndependence.Tests.ps1` | Tests | A | — | — | — | — | — | — | TODO |
| P2 | `Tests/AsylumAudience.Tests.ps1` | Tests | — | — | — | — | A | — | — | TODO |
| P2 | `Tests/AutomaticWhitePeaceFallback.Tests.ps1` | Tests | M | — | — | — | — | — | — | TODO |
| P2 | `Tests/BilateralMarriage.Tests.ps1` | Tests | — | — | — | — | — | M | — | TODO |
| P0 | `Tests/CivilWarGrace.Tests.ps1` | Tests | A | — | — | — | — | — | — | TODO |
| P2 | `Tests/ClaimFeudPlayerControl.Tests.ps1` | Tests | M | — | — | — | — | — | — | TODO |
| P2 | `Tests/CourtPlayerPicker.Tests.ps1` | Tests | M | — | — | — | — | — | — | TODO |
| P2 | `Tests/CourtRedesignHarness/CourtRedesignHarness.csproj` | Tests | — | — | — | — | — | M | — | TODO |
| P2 | `Tests/CourtRedesignHarness/Program.cs` | Tests | — | — | — | — | — | M | — | TODO |
| P2 | `Tests/CourtTitleGrant.Tests.ps1` | Tests | M | — | — | — | — | — | — | TODO |
| P2 | `Tests/CrownFavorCost.Tests.ps1` | Tests | M | — | — | — | — | — | — | TODO |
| P2 | `Tests/CrownPanelCleanup.Tests.ps1` | Tests | M | — | — | — | — | — | — | TODO |
| P2 | `Tests/CrownPlayerDeparture.Tests.ps1` | Tests | A | — | — | — | — | — | — | TODO |
| P2 | `Tests/EstateInheritanceDisplay.Tests.ps1` | Tests | — | — | M | — | — | — | — | TODO |
| P2 | `Tests/FactionInfluenceCostSizing.Tests.ps1` | Tests | A | — | — | — | — | — | — | TODO |
| P2 | `Tests/ForcedAbdication.Tests.ps1` | Tests | M | — | — | — | — | — | — | TODO |
| P2 | `Tests/HierarchyActionMenu.Tests.ps1` | Tests | — | M | M | — | — | — | — | TODO |
| P2 | `Tests/IndependenceRulerSaveRepair.Tests.ps1` | Tests | A | — | — | — | — | — | — | TODO |
| P2 | `Tests/InheritedPossession.Tests.ps1` | Tests | — | M | — | — | — | — | — | TODO |
| P2 | `Tests/InternalInstability.Tests.ps1` | Tests | M | — | — | — | — | — | — | TODO |
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
| P0 | `Tests/SuccessionEngineHarness/CadetHouseholdPreparationTests.cs` | Tests | M | — | — | — | — | — | — | TODO |
| P0 | `Tests/SuccessionEngineHarness/CampaignRunRecoveryTests.cs` | Tests | A | — | — | — | — | — | — | TODO |
| P0 | `Tests/SuccessionEngineHarness/CampaignUiStartupProbe.cs` | Tests | — | — | M | — | M | — | — | TODO |
| P0 | `Tests/SuccessionEngineHarness/CaptainTitleTests.cs` | Tests | — | — | — | — | — | A | — | TODO |
| P0 | `Tests/SuccessionEngineHarness/CivilWarGraceTests.cs` | Tests | A | — | — | — | — | — | — | TODO |
| P0 | `Tests/SuccessionEngineHarness/ClaimFeudCooldownTests.cs` | Tests | — | A | — | — | — | — | — | TODO |
| P0 | `Tests/SuccessionEngineHarness/CollapseClaimantRecoveryTests.cs` | Tests | A | — | — | — | — | — | — | TODO |
| P0 | `Tests/SuccessionEngineHarness/CompanionOffspringTests.cs` | Tests | — | — | — | — | — | A | — | TODO |
| P0 | `Tests/SuccessionEngineHarness/CourtClientGrantTests.cs` | Tests | — | — | — | — | M | — | — | TODO |
| P0 | `Tests/SuccessionEngineHarness/CourtTitleGrantEngineTests.cs` | Tests | M | — | — | — | — | — | — | TODO |
| P0 | `Tests/SuccessionEngineHarness/CrownPlayerDepartureTests.cs` | Tests | A | — | — | — | — | — | — | TODO |
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
| P0 | `Tests/SuccessionEngineHarness/InternalInstabilityPresetTests.cs` | Tests | M | — | — | — | — | — | — | TODO |
| P0 | `Tests/SuccessionEngineHarness/InternalInstabilityTests.cs` | Tests | M | — | — | — | — | — | — | TODO |
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
| P0 | `Tests/SuccessionEngineHarness/PeaceParleyBudgetRecoveryTests.cs` | Tests | A | — | — | — | — | — | — | TODO |
| P0 | `Tests/SuccessionEngineHarness/PeaceParleyCapitulationTests.cs` | Tests | A | — | — | — | — | — | — | TODO |
| P0 | `Tests/SuccessionEngineHarness/PeaceParleyExplanationTests.cs` | Tests | A | — | — | — | — | — | — | TODO |
| P0 | `Tests/SuccessionEngineHarness/PeaceParleyPresentationTests.cs` | Tests | A | — | — | — | — | — | — | TODO |
| P0 | `Tests/SuccessionEngineHarness/PeaceParleyVotingTests.cs` | Tests | A | — | — | — | — | — | — | TODO |
| P0 | `Tests/SuccessionEngineHarness/PeaceReadinessTests.cs` | Tests | M | — | — | — | — | — | — | TODO |
| P0 | `Tests/SuccessionEngineHarness/PlayerMarriageAgreementTests.cs` | Tests | — | — | — | — | — | M | — | TODO |
| P0 | `Tests/SuccessionEngineHarness/PrefabFinalizationCompatibilityTests.cs` | Tests | — | — | — | — | A | — | — | TODO |
| P0 | `Tests/SuccessionEngineHarness/PregnancyVisitGuardTests.cs` | Tests | — | — | — | — | — | A | — | TODO |
| P0 | `Tests/SuccessionEngineHarness/Program.cs` | Tests | M | M | M | M | M | M | — | TODO |
| P0 | `Tests/SuccessionEngineHarness/RealmLeadershipDiagnosticTests.cs` | Tests | A | — | — | — | — | — | — | TODO |
| P0 | `Tests/SuccessionEngineHarness/RealmNameTests.cs` | Tests | — | M | — | — | — | — | — | TODO |
| P0 | `Tests/SuccessionEngineHarness/RecruitmentRankTests.cs` | Tests | A | — | — | — | — | — | — | TODO |
| P0 | `Tests/SuccessionEngineHarness/RegencyAdulthoodTests.cs` | Tests | A | — | — | — | — | — | — | TODO |
| P0 | `Tests/SuccessionEngineHarness/RegencySettingsTests.cs` | Tests | M | — | — | — | — | — | — | TODO |
| P0 | `Tests/SuccessionEngineHarness/RestoredRealmRecoveryTests.cs` | Tests | A | — | — | — | — | — | — | TODO |
| P0 | `Tests/SuccessionEngineHarness/RetainerIndentureTests.cs` | Tests | — | — | — | — | — | A | — | TODO |
| P0 | `Tests/SuccessionEngineHarness/RetainerMarriageTests.cs` | Tests | — | — | A | — | — | M | — | TODO |
| P0 | `Tests/SuccessionEngineHarness/SuccessionEngineHarness.csproj` | Tests | M | — | M | — | M | — | — | TODO |
| P0 | `Tests/SuccessionEngineHarness/TitleAcquisitionTests.cs` | Tests | — | — | A | — | — | — | — | TODO |
| P0 | `Tests/SuccessionEngineHarness/TitleNameCacheTests.cs` | Tests | — | — | — | — | — | M | — | TODO |
| P0 | `Tests/SuccessionEngineHarness/TitlePresetLocalizationTests.cs` | Tests | — | — | M | M | — | M | — | TODO |
| P0 | `Tests/SuccessionEngineHarness/WhitePeaceFallbackTests.cs` | Tests | M | — | — | — | — | — | — | TODO |
| P2 | `Tests/TreatyDurationSettings.Tests.ps1` | Tests | A | — | — | — | — | — | — | TODO |
| P2 | `TitleAcquiredMapNotification.cs` | Court/title | — | — | A | — | — | — | — | MISSING |
| P2 | `TownPartyPositionHelper.cs` | Other | — | — | A | — | — | — | — | TODO |
| P2 | `TreatyAiDraftService.cs` | Politics/war | M | — | — | — | — | — | — | TODO |
| P2 | `TreatyCouncilAbstentionReason.cs` | Politics/war | A | — | — | — | — | — | — | TODO |
| P2 | `TreatyCouncilMemberEvaluation.cs` | Politics/war | M | — | — | — | — | — | — | TODO |
| P2 | `TreatyHostageTerms.cs` | Politics/war | M | — | — | — | — | — | — | TODO |
| P1 | `TreatyProposalRecord.cs` | Save/state | M | — | — | — | — | — | — | TODO |
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
| P2 | `UI/Parley/PeaceParleyInterface.cs` | UI | M | — | — | — | — | — | — | TODO |
| P2 | `UI/Parley/PeaceParleyVM.cs` | UI | M | — | — | M | — | — | — | TODO |
| P2 | `UI/Parley/TreatyCouncilExplanation.cs` | UI | A | — | — | — | — | — | — | TODO |
| P2 | `UI/Parley/TreatyCouncilMemberVM.cs` | UI | M | — | — | — | — | — | — | TODO |
| P2 | `UI/Parley/TreatyCouncilSummaryVM.cs` | UI | A | — | — | — | — | — | — | TODO |
| P2 | `UI/TitleAcquiredNotificationItemVM.cs` | UI | — | — | A | — | — | — | — | TODO |
| P2 | `UI/VanillaTabs/Kingdoms/Hierarchy/HierarchyBuildContext.cs` | UI | — | — | — | — | A | — | — | TODO |
| P2 | `UI/VanillaTabs/Kingdoms/Hierarchy/HierarchyTitleNodeVM.cs` | UI | — | M | M | M | M | — | — | TODO |
| P2 | `UI/VanillaTabs/Kingdoms/Hierarchy/HierarchyTitleTreeNodeWidget.cs` | UI | — | — | A | — | — | — | — | TODO |
| P2 | `UI/VanillaTabs/Kingdoms/Hierarchy/KingdomHierarchyTabVM.cs` | UI | — | — | M | — | M | — | — | TODO |

### First P0 read-only audit: save class registry (PARTIAL, not merged)

- **Native `main`** and **upstream candidate 1.4.5†** share the same file blob `ca7ce54894239d7132b3ab79c81bcf1fc3037402` — exact source parity for **this file alone**, not the whole fork or binary package.
- **Class registration counts / containers:** Native main 99 / 97; author candidate 1.4.5† 99 / 97; author 1.4.9 105 / 103; author 1.4.10 106 / 104; author 1.4.11 108 / 106; stacked Native PR #13 100 / 98.
- **PR #13 vs author 1.4.11:** all **100 shared class IDs and names match**; **no class ID collision** found. Eight classes remain absent in staged Native: `CivilWarGraceRecord=136`, `PersonalLordshipRecord=138`, `LordshipAppointmentRecord=139`, `LordshipIncomeCredit=140`, `TitleAcquiredMapNotification=141`, `AsylumVisitRecord=142`, `LordshipCommandTransferRecord=143`, `RetainerIndentureRecord=144`. `RestoredRealmCreationRecord=137` already exists in PR #13. These are **source registry findings**, NOT verified complete save compatibility.
- **Status rationale:** `BellumCivileSaveDefiner.cs` = **PARTIAL**, because baseline metadata aligns but many upstream feature types/containers are not yet present. **DO NOT COPY** these registrations without implementing and testing the owning features. Before marking MATCH, audit field IDs, all downstream save types, feature initialization, old-save defaults, Windows build/load and unmodified historical save.
- **Production change boundary:** **NONE** in this audit; no new fields, ID assignments, Harmony, migration, or save repair. Next P0 audit must inspect source-side callers of each missing class and its registration and preserve current AII foreign peace (Revamp OFF), original save IDs and Bridge ABI.

## P0-02 — eight absent save-class registrations: owner and dependency audit (2026-11-08)

**Evidence:** upstream Vonbalt/BellumCivile @ da426b23c64f3a66ae2b389d2db8f23489736bf9 (1.4.11), custom stacked Native PR #13 @ a7a7d39e3bacac4799dc2d301831b2926171ebea, GitHub file-content lookups, symbol/caller search and the original SaveDefiner declarations. **AUDIT ONLY — no class, schema, feature or production patch has been imported.**

All eight save classes are absent from our staged SaveDefiner. The exact missing declarations occupy **five source files**, not eight separate files. The twelve related author declaration/implementation paths in this matrix are confirmed absent from PR #13 and marked **MISSING** (literal absence, not a decision to import). Existing SubModule.cs, FactionManagerBehavior.cs, CivilWarResolutionBehavior.cs and ExiledClanRecoveryBehavior.cs are marked **PARTIAL** because specific new integration callers are not present, while the old behavior remains; complete method-by-method review is still pending.

| Class ID | Type / author declaration file | Author version first visible | Saved field IDs | Actual owner, collection and effect |
|---:|---|---|---|---|
| 136 | CivilWarGraceRecord — CivilWarGraceRecord.cs | 1.4.6 era | 1–6 | FactionManagerBehavior partial CivilWarGrace.cs, saved BC_CivilWarGrace list; new post-war grace limits creation/recruitment of rebels |
| 138 | PersonalLordshipRecord — PersonalLordshipRecord.cs | 1.4.8 era | 1–10 | LordshipBehavior._grants, BellumCivile_PersonalLordships; village personal/vassal grants, revenue and household authority |
| 139 | LordshipAppointmentRecord — PersonalLordshipRecord.cs | 1.4.8 era | 1–7 | LordshipBehavior._appointments, BellumCivile_LordshipAppointments; party/governor service and retirement |
| 140 | LordshipIncomeCredit — PersonalLordshipRecord.cs | 1.4.8 era | 1–4 | LordshipBehavior._incomeCredits in VassalLordships.cs, BellumCivile_LordshipIncomeCredits; treasury and village-income accounting |
| 141 | TitleAcquiredMapNotification — TitleAcquiredMapNotification.cs | 1.4.8 era | 10–15 | TitleAcquisitionBehavior._pending, BC_TitleAcquisitionNotices; InformationData map notice on new titles and new realms |
| 142 | AsylumVisitRecord — AsylumVisitRecord.cs | 1.4.10 era | 1–15 | ExiledClanRecoveryBehavior partial ExileAsylumVisits.cs, BellumCivile_AsylumVisits dictionary; guest in keep, audience and optional lordship |
| 143 | LordshipCommandTransferRecord — PersonalLordshipRecord.cs | 1.4.11 | 1–4 | LordshipBehavior._commandTransfers, BellumCivile_LordshipCommandTransfers; protected party commander replacement |
| 144 | RetainerIndentureRecord — RetainerIndentureRecord.cs | 1.4.11 | 1–4 | LordshipBehavior._indentures, BellumCivile_RetainerIndentures; time-limited paid retainer contracts and renewals |

**Container confirmation:** upstream 1.4.11 SaveDefiner registers the eight exact class ID/type pairs, seven list containers and the **Dictionary<string, AsylumVisitRecord>** container. The 100 class ID/type registrations shared with our Draft PR #13 remain consistent and show no numeric ID collision. Their presence alone would not establish save-load compatibility.

### Traced call chains and blast radius

**136 — grace:** In upstream FactionManagerBehavior, RegisterEvents adds new-game ArmInitialCivilWarGrace and hourly MaintainCivilWarGrace; SyncData invokes SyncCivilWarGrace; RegisterNewFaction invokes IsCivilWarGraceBlocked. CivilWarResolutionBehavior adds QueueCivilWarGrace and AddCivilWarGraceRealms after a civil settlement. These named integration seams are missing in our staged Native source. The new policy can suppress internal rebellion, directly impacting our controlled-chaos goal, even though Bellum foreign war/peace Revamp OFF remains separate. It also introduces initial-grace and configurable CivilWarGraceYears behavior.

**138–141 / 143–144 — lordship and notice family:** Upstream SubModule registers LordshipBehavior and TitleAcquisitionBehavior, absent in our staged SubModule. LordshipBehavior owns six saved lists, event listeners for clan/hero/settlement/ticks, party and governor status, several Harmony patches and HAP finance integration. VassalLordships can create a grant, generate income credits, and call TitleAcquisitionBehavior.Granted; TitleAcquisitionBehavior observes KingdomCreatedEvent and settlement ownership, and uses a separate map-notification Harmony/UI path. Its new notice is NOT itself the native OnKingdomCreated dispatcher call, nor Bellum Bridge kingdom_created. New contracts and party commander transfers depend on the entire lordship subsystem; they cannot be safely enabled with SaveDefiner alone.

**142 — asylum:** Our existing ExiledClanRecoveryBehavior has pending-clan ID dictionaries and immediate AcceptPlayerAsylum / DenyPlayerAsylum decisions. The official implementation adds SyncAsylumVisits, ProcessAsylumVisits, OnAsylumTick, RegisterAsylumDialogues and a saved keep-visit record. The new ExileAsylumVisits behavior can teleport the hero, hold a party, enter a settlement, resolve homage, join a kingdom and optionally use LordshipBehavior.TryGrantVassal for promised land. This directly changes an already working path. It requires an old-save pending-queue migration contract and an actual game test before consideration.

**143–144 — shared dependency:** LordshipCommandTransfers consults ExiledClanRecoveryBehavior.IsAwaitingAsylum, retirement/disbanding, leader teleport and optional gold payment; RetainerIndentures holds expiring contracts, deducts gold, unlocks command without estate, and schedules renewal. Both are invalid as standalone imports without the 138–140 owner records and LordshipBehavior. Inspect player clan and party/siege eligibility before any future change.

### Regression-first contract before any production import

- **ROOT CAUSE:** unported, feature-owned serialized types from successive upstream feature releases, not evidence that old saves are corrupted.
- **TOUCH:** only this file and the issue #96 backlog. **DO NOT TOUCH:** Native production/save schema, Bellum Bridge, Relay Bridge, Relay, Harmony, custom diplomacy, main, or historical save membership.
- **MUST FIX in this audit:** class-to-owner-to-caller mapping and missing-source facts. **MUST NOT CHANGE:** current working features or old-save on-disk data.
- [ ] Grace positive: settle rightful civil war once, then observe chosen grace period. Neighbor: already-committed claimant or civil war, unrelated kingdoms, controlled chaos frequency and gameplay settings must remain as intended; existing foreign AII war/peace with Revamp OFF unchanged. Expected author log: Civil-war grace settled; ... ; it is NOT currently expected from our build.
- [ ] Lordship positive: personal/vassal grant, income, party or governor service and expiry. Neighbor: original clan/household/court inheritance, titles, HAP taxes, no double income or illegal clan party, no Harmony conflict. Run save/load with missing new lists and existing normal campaigns.
- [ ] Title UI positive: one legitimate acquisition notice. Neighbor: partial restored kingdom, native KingdomCreatedEvent, Bellum Bridge observers, native title authority and old-save reload must not yield duplicate or premature notices.
- [ ] Asylum positive: visitor arrives and has the intended time-limited keep audience. Neighbor: existing immediate accept/refuse and old pending ID queue, exiles, siege/raid, party hold, ruler relationship and promised village grant must not regress. Save/load during a visit; no duplicate faction entry, party, allegiance or relation gain.
- [ ] Commander/retainer positive: contract, renewal, replacement, expired contract and paid role. Neighbor: original party disband, retiring governor, other clan service and blocked asylum guest must remain functional; no duplicate hero party or unintended gold debit.
- [ ] Schema checks: every class field ID (1–6, 1–10, 1–7, 1–4, 10–15, 1–15, 1–4, 1–4), all eight exact registered containers including asylum dictionary, behavior registration and null/legacy defaults, old save copied not mutated.
- [ ] Run real Native integration save tests, P101A–F, Windows native compile, Bellum Bridge ABI/loads, copied old-save and new campaign; compare real political state, title/party/finance data, Bellum Bridge and Relay events. No fictitious PASS from source inspection.

**Disposition:** P0-02 is **source-only classification, no code port**. All eight feature packages require explicitly planned scopes and tests; do not import save class IDs alone, refactor shared FactionManager or automatically rewrite old saves. Preserve the current unmerged Draft PR stack and custom Native source.

## P0-03 — Civil War Grace: gameplay and interoperability analysis before deciding to port (2026-11-08)

**Decision: OPEN; audit only. NO production code was imported.** Exact upstream source at `Vonbalt/BellumCivile@da426b23c64f3a66ae2b389d2db8f23489736bf9` (1.4.11); our custom stacked PR #13 at `AIRebelRelay/BellumCivile@a7a7d39e3bacac4799dc2d301831b2926171ebea`. The author's unit/harness source was **read, not executed**.

### Source-proven behaviors

1. **Initial year, independent of MCM:** `FactionManagerBehavior.RegisterEvents` hooks `OnNewGameCreatedEvent` and `OnAfterSessionLaunchedEvent`, `ArmInitialCivilWarGrace`/`ApplyInitialCivilWarGrace` set a nonrenewing one-`CampaignTime.DaysInYear` deadline for every *existing permanent kingdom*, including modded kingdoms, excluding eliminated kingdoms and temporary Bellum rebel shells. Kingdoms created after this snapshot receive NO initial grant. This occurs even with postwar setting `0`. A pre-existing old save with absent keys does **not** receive retroactive startup grace according to upstream tests.
2. **After actual civil war:** `CivilWarResolutionBehavior.CompleteCivilWarTracker` queues `CivilWarGraceRecord` only if the faction has really started civil war, not just peaceful ultimatum or ideology faction. It captures configured duration **once**, tracks parent and relevant permanent outcome realms; independence partitions include new successor realms. Real civil-war loyalist victory, rebel victory and white peace all can qualify; retry does not extend an earlier recorded deadline.
3. **Immediately blocks but clock starts after cleanup:** `HasCivilWarGrace` is true for an unsettled journal on a permanent realm if duration is positive. Hourly `MaintainCivilWarGrace` waits until the rebel shell is eliminated, the original active faction is removed, parent/successor transfer, Crown accession or deposition and hereditary war-restitution are resolved. Only then does it set `Settled=true` and `UntilDay=now+DurationDays`. Therefore a stuck pending state can cause **more than configured** protection, potentially indefinitely. This is especially relevant to our unbuilt staged native civil-war recovery PRs #9–#13.
4. **Duration and presets:** `BellumCivileSettings.CivilWarGraceYears` is integer 0–5, default **2 years**. Instability presets: Standard=2, Reduced=3, Increased=1. `0` disables new *postwar* protection but **does not disable initial year**. Years are multiplied by `CampaignTime.DaysInYear`, not a fixed calendar. With an actual game-reported 365-day year, standard 2 years = **730 game days** and startup = **365 days**. Changes to MCM affect the next newly queued war, not previously captured record durations.
5. **Hard-gated, not just probability:** `FactionManagerBehavior.RegisterNewFaction`, `FactionObject.AddMember/DailyTick/CanTriggerUltimatum/StartImmediateSecessionFromParentRealm`, `IdeologyBehavior` daily rebel planning and coalition launch, `CourtAgendaBehavior` armed crisis, `SuccessionChallengeBehavior.TryBegin`, `SuccessionChallengeInitiation` and `ElectiveContestBehavior.CompleteAccession` block new armed political conflicts during grace. `FactionObject.DailyTick` exits before BOTH growth and decay logic, so existing discontent is effectively **paused, not reset by this tick path**. Existing Court ideological factions and ordinary politics/meetings/votes remain possible.
6. **Exceptions are scoped per call site:** previously committed ultimatum/Crown challenge and marked judgment resistance can progress (specific `IsCommittedCrownChallenge` and `IsJudgmentResistance` exemptions), but a **new voluntary player pledge** to an issued-yet-unstarted ultimatum is still blocked by `CivilWarGraceJoinBlock`. Joining an **already active** civil war is not blocked by that specific UI helper. Private feuds and Enforce Peace have separate independent mechanisms, and an existing civil war is not simply cancelled.
7. **Save/log/UI:** author registers `CivilWarGraceRecord` class ID **136**, `SaveableField(1..6)`, `List<CivilWarGraceRecord>` container; keys `BC_CivilWarGrace`, `BC_InitialCivilWarGrace`, `BC_InitialCivilWarGracePending`, `BC_InitialCivilWarGraceUntil`. Settled record logs `Civil-war grace settled; faction=...; realms=...; until=...; duration=...`. UI uses remaining-day pacification message on disabled rebellion and title challenge controls. That line is **NOT expected from our current fork**, which lacks the feature.

### High-risk overlapping custom semantics (DO NOT PORT BLINDLY)

- **Revamp OFF landed-secession behavior would change.** Official `Patches/PlayerLandedSecessionPatch.cs` invokes `CivilWarGraceBlock(player.Kingdom)` and aborts the player's keep-holdings departure BEFORE testing `!WarPeaceRevampBehavior.IsRevampEnabled()`. Our staged fork's same patch currently early-returns to vanilla for `selectedOption != "keep" || !IsRevampEnabled()`. Therefore simply porting upstream grace intercept can block a currently working **Revamp OFF** landed player departure. This is a demonstrated source-level semantic difference, not a claim of live-game reproduction. Keep AII foreign diplomacy ownership and Bridge event consumers unchanged.
- **Controlled chaos freeze:** an initial one-year non-configurable pacification for all map-starting kingdoms, including custom-map states; a default two-year postwar ban for both surviving parent and permanent successors. This may reduce internal political turnover far more than intended, even if normal Court policy still executes.
- **Stalled handoff prolongs suppression:** while any authoritative record is unsettled, `HasCivilWarGrace` counts it active with positive `DurationDays`. Crosscheck our unverified staged successor creation and Crown claim resumes; test orphaned rebel shell, stale active faction, never-finished Crown / claim record, then ensure unrelated future rebellion isn't permanently frozen.
- **NPC/player mismatch to test:** `IdeologyBehavior.OnDailyTickClan_Rebellion` returns early on grace before `AttemptDefectToActiveCivilWar`, whereas `CivilWarGraceJoinBlock` permits joining a currently active war. Test contemporaneous distinct wars in same realm before drawing conclusions about real NPC/player fairness.
- **Court politics vs armed challenges:** `IsIdeology` exempts normal Court faction registration/membership, but `HasCivilWarGrace` independently blocks grand coalitions, player-led low-mood armed crisis, new hereditary and electoral armed challenges. Do not misrepresent this as fully disabling Court.

### Regression contract and decision gate

**ROOT CAUSE under analysis:** potential design mismatch between author pacification and our controlled-chaos target plus Revamp OFF ownership. **TOUCH:** only this audit matrix and issue #96, **DO NOT TOUCH:** any game source, SaveDefiner, Harmony patch, Native main, AI Influence, Bellum Bridge or Relay Bridge. **MUST FIX in this stage:** document full source-backed scope, exceptions and blast radius. **MUST NOT CHANGE:** current game, saves, features or draft PR behavior.

- [ ] Verify the actual installed `CampaignTime.DaysInYear` with the desired 365-day campaign and decide whether 365 start days / 730 postwar days are reasonable.
- [ ] Decide separately whether global startup pacification is desired and whether `0` should disable it (author's `0` currently does not); no unplanned fork semantics.
- [ ] Fresh/new and old/save: initial original kingdoms only; custom-map kingdoms; no later realms, no retroactive startup protection, repeated callback doesn't renew; stable saves / class ID 136 / list and dictionary defaults.
- [ ] All three civil-war outcomes, partitioned independence, restored parent and successor, no duplicate queue or reset from repeat callbacks, timer starts after lawful cleanup, not before; zero-duration retries don't become positive after MCM change.
- [ ] Regular rebels blocked from registering, receiving new members, gaining/decaying discontent, ultimatum, direct secession and new Court crisis; **existing** conflict/committed claimant/judgment resistance remains legal. Private feuds and Enforce Peace must remain unaffected.
- [ ] Correct player UI tooltip and backend authority, never charge for blocked Court votes; election winner installed but no new armed contest opened.
- [ ] Revamp OFF **player keep-fiefs departure** preserves existing vanilla forwarding unless explicitly planned otherwise; AII foreign war/peace decisions and Bellum Bridge political event capture never swallowed.
- [ ] Pending shell/Crown/deposition/challenge cannot accidentally block realm forever; check single expected settled log and absence of unjustified repeated notifications; NPC active-war defection compared with player active-war joining.
- [ ] Actual author CivilWarGrace source tests and `Tests/SuccessionEngineHarness/CivilWarGraceTests.cs`, custom P101A–F and native Windows build + copied save/new campaign, Bellum Bridge ABI and actual event/log checks BEFORE port/merge. **No tests/build/game executed in this analysis.**

**No decision to import or reject yet.** First obtain explicit campaign design choice between: upstream default as-is, a separately configurable shorter/scoped cooldown with optional initial grace, or intentionally excluding the mechanic. This analysis does NOT authorize code changes.

## Pending coverage blockers / separate checks

- [ ] Verify the **source-backed Oct 18 1.4.5† candidate** `b1d9a4e8...` against the actual author's 1.4.5 release archive/package; refine the checkpoint if actual packaged code differs. The first comparison has already been regenerated from this candidate, but this is not a binary-matched release provenance claim.
- [ ] Check inter-checkpoint **commit-by-commit paths** for any file changed and fully reverted within one interval. The matrix intentionally does not claim such transient history was exhaustively inspected.
- [ ] Compare independent Draft PR #2–#7 and PR #9–#13 against latest upstream, custom Native features, and each other. PR #7 (collapse ID reference guard) is **not** included in the #9→#13 stack; validate merge ordering, don't assume it is integrated.
- [ ] Compare upstream 1.4.10 → 1.4.11 new save classes `LordshipCommandTransferRecord` (ID 143), `RetainerIndentureRecord` (ID 144), dependencies and containers; they do not exist in our staged Native as part of this port. Never import those IDs without importing and testing the corresponding feature.
- [ ] Review changed public APIs/callers (Bellum Bridge compatibility, Native politics, titles, retainer/lordship/marriage, Dynasty, Kingdom, Court), all Harmony patches, tests and XML assets. Preserve custom war/peace Revamp OFF behavior and player ruler/court logic.
- [ ] Perform Windows P101A–F regression suite, upstream-derived restored realm and claimant harness tests, full Native compile, Bellum Bridge ABI/load, and in-game before/after logs on copied historical saves and fresh campaign. Explicitly record tests executed, outputs and failures; static matching is not behavioral proof.
- [ ] Do not auto-repair old saves; P1-01G concluded retroactive faction membership cannot be safely inferred without provenance.

**Update discipline:** mark each audited row only after inspecting its source and affected callers; maintain a small explicit audit/decision log and per-row source SHA. Do not automatically mark 1.4.10→1.4.11 core files as safe just because upstream blob hashes match. This file is an inventory checkpoint, **not a migration certificate**.
