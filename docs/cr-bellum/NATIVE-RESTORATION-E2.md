# Stage E2 — Native Bellum completed restored-realm receipts
Base: `6bb75ba814d20c9423795ed3ec2372ebb372dd7e`, branch `feature/cr-existing-recorded-names-2026-11-16`. New branch only; no main/release.

**ROOT CAUSE**: `BC_RestoredRealmCreations` persists a terminal `Ready` flag but no exact completed day or source ID accessible through the supported integration facade. Native notifications can fire before `Ready` and are not an event completion guarantee.
**TOUCH**: only fields 18/19 of `RestoredRealmCreationRecord`, the single terminal Ready writer and a read-only getter in `Behaviors/RestoredRealmRecovery.cs`, 2 new source files, metadata/README and 1 isolated regression test.
**DO NOT TOUCH**: restoration mechanics and guards, `BellumCivileSaveDefiner` (class ID 137), crown union, clientage, diplomacy, CR, Bridge, Relay, legacy AII code, Harmony, Naval companion.
**MUST FIX**: on final postconditions, save `CompletionReceiptId="restored_realm|"+SuccessorId`, `CompletedDay=CampaignTime.Now.ToDays` before the existing Ready transition. Expose last 100 immutable scalar snapshots after completion on active campaign thread, never on `OnKingdomCreated`.
**MUST NOT CHANGE**: do not backfill legacy Ready records; optional new fields deserialize absent on older saves, and the read-only method filters missing IDs. Do not change public `BellumIntegration.ApiVersion=1`; additive APIs require feature detection.

Versions: Bellum module `v1.4.12.2`, DLL file version `1.4.12.2`, information `1.4.12b-cr-alpha.2`, assembly binding stays `1.0.0.0`; Naval companion remains `v1.0.33`. Bridge `0.1.1` and CR `2.8.13` untouched.

Offline test: `pwsh -NoProfile -ExecutionPolicy Bypass -File .\Tests\CRRestoredRealmReceipts.Tests.ps1`. It compiles actual production snapshot/getter against isolated fake records. Positive: ready stamp, IDs, day, saved-field copies, <=100 sorted. Negative: pre-completion, notified-only/legacy Ready, malformed records; source gate validates order and version.
Pending: actual Windows net472 build using correct Workshop dependency overrides; old/new save load, final Native log/state; Bridge collector/CR Feed acceptance/NPC heard validation in a *later stage*. No release claim.
