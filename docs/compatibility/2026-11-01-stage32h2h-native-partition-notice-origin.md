# Stage32H2H — Native exact inheritance notice provenance (nonterminal, read-only)

Date: 2026-11-01. **One Native-only stage.** Source code has been committed on a separate feature branch, NOT integrated into release/main. No Bridge/Relay/API transport, Harmony, player UI, inheritance executor, save keys, model settings, or sidecar ACK changed. Static source review is not a compile/game PASS.

## Repository identity / baseline

- **Native source owner:** `AIRebelRelay/BellumCivile`
- Branch: `feature/stage32h2h-native-partition-notice-origin-2026-11-01`
- Starting integrated Native HEAD: `03ad4f90902daa7fde3d45cb54a59fa013cd1d09` (do not overwrite with old main `b1d9a4e8`).
- Upstream audit only: **Bellum Bridge**, distinct repository `AIRebelRelay/Bannerlord2-AiInfluence-BellumCivile`, Stage32H2F `6f01ce73609ff95b88fff325d25840875861f7dc`.
- **Relay Bridge** `AIRebelRelay/ai-rebel-relay-bridge` is unrelated to this patch and was not edited.

## ROOT CAUSE

The Native partition helper methods emit already-real heir-specific inheritance notifications **before** the source's later aggregate `RecordPartition()` can prove >=2 beneficiary houses. Those helpers do not carry the deceased/estate identifier in the public `BellumCivileNotifications.Show(string,...)` parameters. A later getter for pending records would not prove which particular `Show` belongs to which deceased estate and heir.

A source-only caller inventory of 30 partition/Crown-related behavior files identified seven concrete calls across four flows:

| Flow | Exact Native caller | Count | Source identity available at caller |
|---|---|---:|---|
| Ordinary | `TryApplyPartition` → `ShowPartitionMessage` or `ShowSovereignPartitionMessage` | 2 | `record.DeadLeaderId`, `parentClan`, `heir`, `cadetClan` |
| Crown | `FinishCrownBatchSteps` → either helper inside `TryAnnounce("heir:"+id)` | 2 | `pending.DeadLeaderId`, retained house, heir, recipient |
| Cross-clan | `SettleCrossClanShare` → `ShowEstateInheritanceMessage` | 1 | `record.Deceased`, source house, share heir/recipient |
| Mixed | `TryFinishMixedEstateBatch` → sovereign or estate helper inside `TryAnnounce("mixed-share:"+i)` | 2 | `pending.DeadLeaderId` from saved mixed estate, exact existing share index |

The inventory is scoped to the 30 relevant owner files, not a claim of exhaustive reflection/dynamic calls across the entire repository.

## CHANGE BOUNDARY

**TOUCH (production only):**
1. NEW `PartitionNoticeOrigin.cs`: immutable `PartitionNoticeOriginSnapshot` and thread-static, campaign-object-scoped `IDisposable` claim, restored even for nested calls/exceptions. Fields: `EpisodeId`, `DeceasedId`, `OriginHouseId`, `HeirId`, `RecipientHouseId`, `Executor`, `NoticeKey`.
2. `BellumIntegrationPartitions.cs`: a single campaign-thread-guarded `GetCurrentPartitionNoticeOrigin()` returning the snapshot **only during the exact synchronous Show invocation**, null otherwise.
3. `Behaviors/PartitionSuccessionBehavior.cs`: both ordinary call sites pass the deceased ID; both existing private Show helpers place ONLY their existing `BellumCivileNotifications.Show` call inside the scope. Original parameters are retained; added optional parameters preserve unreviewed legacy private callers as unchanged/no provenance.
4. `Behaviors/CrownPartitionCompletion.cs`: both notice calls pass saved deceased ID and unchanged `heir:` marker.
5. `Behaviors/PartitionCrossClanInheritance.cs`: existing estate helper scopes its own exact `record.Deceased` and share recipient; normal caller remains unchanged.
6. `Behaviors/PartitionMixedEstateCompletion.cs`: both exact notices pass the existing `mixed-share:` index and saved deceased ID.

**TEST/QA:** RED-first `Tests/Stage32H2HPartitionNoticeOrigin.Tests.ps1` committed before production; follow-up `Tests/Stage32H2HPartitionNoticeScopeHarness.ps1` runs real helper code with an isolated Campaign stub to exercise nested restoration, throw/cleanup, invalid input and campaign switch. This document.

**DO NOT TOUCH:** `BellumCivileNotifications.cs`, `TryAnnounce`, `TryComplete`, `RecordPartition`, `PendingPartitionSuccessionRecord`, `CrossClanEstateRecord`, Native `SyncData`/SaveDefiner, the inheritance transfer/claim/payout operations, the two Bridges, Relay, Sidecar/ACK, AII NPC JSON, public W7/Court and model routes. No new Harmony patch.

**MUST FIX in this stage:** expose the EXACT event-invocation `partition|deceased|source house` plus heir/recipient/flow marker at the existing `Show(string,...)` hook, without text-based guesswork or synthetic terminal result.

**MUST NOT CHANGE:** whether an individual inheritance succeeds, messages are shown/filtered, their translated text, old-save compatibility, or how/when aggregate completion is recorded. Outside the notification scope, getter must return null; it MUST NOT become a durable or globally unique notice ledger.

## Semantic limits — important future Bridge stop-line

- `EpisodeId` intentionally matches `RecordPartition` within a current Native save episode, **not a save-branch epoch**; `S1 → S2 → S1` can reuse it. No save field was added.
- An active notice context means **the Native Show was invoked**, NOT that the player actually saw the UI, the entire inheritance completed, a post-crash notice returned, or the sidecar/Relay/AII accepted it.
- Crown `TryAnnounce` marks `AnnouncementsStarted` before Show and `AnnouncementsReturned` after; no terminal outcome can be inferred during the Show postfix. Cross-clan `Failure` can be retryable. Ordinary `IntegrationPublished` may be true even where `RecordPartition` returned without saving a >=2-house aggregate.
- The future Bridge may read this getter from its **existing** `BellumNotificationCapture.CapturePostfix` during Native's synchronous `Show(TextObject) → Show(string)` chain. This stage does **not** read it yet, nor emit `partition_completed` or suppress existing individual `notify|` facts.
- Publishing one canonical DynamicEvent instead of old per-heir events still needs a separately reviewed, durable, epoch-aware ACK/ownership protocol. **Do not treat H2H as H2D architecture GO.**

## Regression contract and validation required

Positive: ordinary cadet/sovereign, crown heir/sovereign, cross-clan delivered share, mixed ordinary/sovereign; exact episode source, original heir and recipient, `Executor` and `NoticeKey`; existing UI and seven calls unaffected. Neighbor negative: no heirs/fiefs, completed 1-house (no aggregate), interrupted `TryAnnounce`, cross-clan deferred `Failure`, mixed interruption, disabled/not visible UI, null IDs, unrelated Bellum notice (getter null), nested re-entrance, exception unwind, different Campaign, save/load S1→S2→S1, no persistent/ACK source fact.

- **Executed source audit:** independent token/invariant review of 12 source guards passed 12/12 on feature branch; this was NOT PowerShell execution.
- **Still PENDING:** `pwsh -NoProfile -File ./Tests/Stage32H2HPartitionNoticeOrigin.Tests.ps1`, `pwsh -NoProfile -File ./Tests/Stage32H2HPartitionNoticeScopeHarness.ps1`; existing succession/estate tests, Native `dotnet build BellumCivile.csproj -c Release -p:GameFolder=<installed Bannerlord folder>`, game runtime and save/reload.
- **Live observation before GO:** Native `created ...`, `Cross-clan death estate delivered`, `partition completed with fewer cadets than planned`; Bridge `BELLUM_NOTIFY_CAPTURE`/`BELLUM_SIDECAR_NOTIFY` should remain unchanged for the old build. There is intentionally **no new H2H game log**, and the current Bridge does not yet consume the new getter. Next separately reviewed Bridge read-only diagnostics should compare exact per-notice ID against Native completed receipt without changing source writer or ACK.

**Release status:** Native-only candidate / no release GO / game and compiled API not validated.
