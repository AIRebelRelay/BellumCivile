# Stage 31G — Native Court terminal receipt read-only inventory

**Date:** 2026-10-30. **Status:** isolated Native source patch, static contract verified; NO runtime/save-load/integrated-alpha PASS. One owner test only after complete alpha. No CI, releases or main merges.

## Verified repository + change boundary

- Native Bellum repo: `AIRebelRelay/BellumCivile`.
- Base branch: `feature/stage31f-native-court-eviction-receipts-2026-10-30`, HEAD `6f814713577f4fea2cc50cadea7d231e8dcff20d`.
- Working branch: `feature/stage31g-court-terminal-readonly-inventory-2026-10-30`.
- Test-first (source RED) commit: `1dc3846777599804f5ea23caffcd27b8f39f8e57`.
- Bellum Bridge `AIRebelRelay/Bannerlord2-AiInfluence-BellumCivile@f7ab2707` and Relay `AIRebelRelay/ai-rebel-relay@97d10bfa` remain **unchanged**. Distinct `ai-rebel-relay-bridge` untouched.

**ROOT CAUSE:** Stage31F Native saved terminal queue had neither supported campaign-thread read API nor a safe delivery hand-off. In Bridge `BellumSidecarWriter.RecordSourceBackedFact` only modifies the in-memory pending list and marks it dirty; the existing `FlushIfDirty` is **void**, may defer durable spool write, and does not return a fact-specific durable commit receipt. Calling Native ACK after mere `RecordSourceBackedFact` can destroy the only recoverable copy. The existing Relay `bellum_ack.json` acknowledges **Relay's sidecar accepted IDs**, NOT a Native terminal journal receipt.

**TOUCH:**
1. NEW `CourtTerminalEvictionInventorySnapshot.cs`: immutable read-only inventory and opaque receipt DTOs (`Id`, `RealmId`, `EncodedPayload`); `SourceAvailable`, `Pending`, `TotalStored`, `InvalidCount`, `OverflowCount`, conservative `IsHealthy`.
2. `Behaviors/CourtTerminalEvictionReceipts.cs`: append `GetTerminalEvictionInventory(Kingdom realm)` + strict `TryReadCourtTerminalPayload`; do not modify existing capture/packing, save keys, counting, or overflow behavior.
3. `BellumIntegration.cs`: append public `GetCourtTerminalEvictionInventory(Kingdom realm)` with existing `BellumIntegrationBehavior.RequireCampaignThread()`.
4. NEW test `Tests/Stage31GCourtReadOnlyInventory.Tests.ps1`, and this handoff.

**DO NOT TOUCH:** saved `CourtAgendaRecord` fields/IDs, `CourtObjectiveRecord`, Native `SyncData`/Court/Council/Claim/Rally mechanics and existing eviction markers, `BellumCivileSaveDefiner`, shared Bridge SidecarWriter/spool/ACK, Relay categories/filters, AII, Crown/Civil/War/hostages, separate Relay Bridge.

**MUST FIX:** trusted integration caller can read exact pending saved receipt IDs scoped by an explicitly supplied `Kingdom.StringId`, in stable order, without changing the queue. Malformed/unknown schema/v1/enum/UTF-8/GUID/day is skipped and increments `InvalidCount`; total saved overflow is visible. Missing campaign/behavior/realm => `SourceAvailable=false`. `IsHealthy=false` for missing source, ANY malformed saved receipt or overflow.

**MUST NOT CHANGE:** any existing Native record/eviction semantics, private/public event classification, FIFO semantics, rewards/payments/votes, persistence keys, or acknowledged delivery states (NONE exist yet). Calling the API does NOT remove an item or authorize a public event.

## Proven format and exposure boundaries

- Stage31F `PackTerminalReceipt` v1 has exactly **13** pipe-separated fields: `v1`; 11 base64-UTF8 fields (realm, faction, sponsor, kind, target, action, agenda state, objective state, credit, objective reason, cancellation reason); and invariant double **observation day**. Reading checks exact 13, v1, 32-nibble N-format GUID ID, bounded packed/decoded strings, strict UTF-8, known agenda/objective/credit enums, objective terminal (not Selected/Active), finite nonnegative day, nonempty exact realm.
- Reader enumerates the saved map deterministically sorted by ID, validates all entries and returns ONLY `RealmId == realm.StringId`. `InvalidCount` and `OverflowCount` are *global queue health*, not per-realm; conservative fail-closed is intentional.
- `EncodedPayload` contains **private diagnostic provenance**, including raw technical cancellation reasons. This DTO is NOT a world event or public knowledge. Bridge must apply a separate allowlist and public/private/secret check before generating any sidecar fact; `ObjectiveCredit=FulfilledElsewhere` never means sponsor achieved the result; observed day is not verified completion timestamp.
- Callbacks remain campaign-thread-only; no Harmony or new scheduler.

## Regression contract and evidence

**Positive tests to run later on Native .NET harness / saved Bannerlord campaign:** same-kingdom known v1 receipt returned, another-kingdom receipt excluded; read twice returns stable sorted IDs and same pending map count; save/load preserves ID/payload/overflow; valid finite observed day; real PASSED/DEFEATED/Expired/FulfilledElsewhere payloads pass; malformed base64 / ID / enum / wrong field count / future schema / NaN/Infinity are counted invalid and never exposed as fact. Missing behavior returns unavailable.

**Negative neighboring tests:** no modification to 31F eviction capture or saved schema; no Native ACK or queue removal on read; no scan crosses realm boundary; no private/technical result becomes public by reading; 1024 overflow remains a BLOCKER, not success; no changes to Council intent tombstones, Court reaction history, Claim/Rally eviction, or provider-side NanoGPT and AII routes. Existing Stage31D, 31E, 31F source tests must remain valid.

**Test-first RED:** on first test commit, reader and API were absent; explicit source checks showed RED. **Post-source GREEN:** 24/24 deterministic cross-file GitHub content assertions passed. Full diff vs Stage31F contains two modified C# files with additive lines, one new DTO, one new test. No deletions or edits to old methods in existing C#.
**NOT EXECUTED:** PowerShell test runtime, Native .NET build, gameplay, save/reload, Bridge spool write, Relay or AII NPC propagation. No CI triggered.

## Next Stage 31H: Bridge durable admission before any Native ACK

Review and regression-test a **fact-specific**, campaign-scoped Bridge durable spool commit API instead of relying on `void FlushIfDirty` or `RecordSourceBackedFact`. Require spool restore success, exact FactID/payload identity, atomic-write confirmation after the captured generation, correct campaign identity, and safe retry/crash behavior. Only after confirmed spooling should a *separate* Native receipt-ACK API be designed with persisted tombstones so already-archived records are not accidentally recreated on future passes. Do not call it on Relay `bellum_ack.json`; that ACK means a different operation.

**Expected current runtime logs:** existing Stage31F `BC_COURT_TERMINAL_EVICTION status=recorded|overflow`; **there is NO new Stage31G log** (pure read-only). Future Bridge: source-backed fact persisted and exact ACK evidence only when implemented. AII named NPC `DynamicEvents[]` evidence remains a separate end-to-end acceptance gate. Any overflow, malformed payload, leak or missing durable write prohibits full alpha PASS.

**Release blockers:** no ACK; no Bridge reader; no public/secret classification; Native 1024 bound; no runtime save-load/build; no AII NPC knowledge proof. Stage31G closes only the safe Native read path.
