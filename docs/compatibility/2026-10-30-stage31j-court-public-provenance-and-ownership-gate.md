# Stage 31J — Native Court publicity/provenance contract and duplicate-ownership gate

**2026-10-30 | ARCHITECTURE / regression contract only; do NOT publish events from this stage.** No gameplay production code changes, no native/Bridge/Relay DLL, build, CI, merge or release. Owner receives **one complete integrated alpha**, not a test request after each stage.

## Pinned source / correct repositories

- **Native Bellum** `AIRebelRelay/BellumCivile`: base HEAD `da786118d6a4c239c3fdc1f359b25f93b6ccda5e`, branch `feature/stage31g-court-terminal-readonly-inventory-2026-10-30`. Work: `audit/stage31j-court-public-provenance-ownership-2026-10-30`.
- **Bellum Bridge**, distinct repo `AIRebelRelay/Bannerlord2-AiInfluence-BellumCivile`: Stage31I HEAD `50ab265e598a452a038d4139258b7026504a1590`, unchanged.
- **Relay** `AIRebelRelay/ai-rebel-relay`: HEAD `97d10bfaee4eb2949e8d66be8b5107591513ed9b`, unchanged. Separate `ai-rebel-relay-bridge` untouched.
- Frozen foreign Court pressure #85; unrelated expulsion #88, war/peace #89 and integrated alpha gates Bridge #90/Relay #468 not included.

## ROOT CAUSE: player UI scope != in-world knowledge

Stage31F archives confirmed terminal outcomes in Native `BC_CourtTerminalEvictionReceipts_v1`, keyed by `CourtAgendaRecord.IntegrationId`. Stage31G returns realm-filtered opaque v1 payload (13 fields: 11 base64 strings + observation day), SourceAvailable/IsHealthy/InvalidCount/OverflowCount. Stage31I Bridge checks candidates only and always logs `public_authorized=0; sidecar_emitted=0`. Stage31H's fact-specific spool seam is intentionally inert. **None of these structures contains independently authored audience/visibility evidence.**

`BellumCivileNotifications.ShouldShow` uses `BellumNotificationScope.Disabled|KingdomOnly|Global` and `Clan.PlayerClan`. It determines whether **the human player sees a UI toast** via `InformationManager.DisplayMessage`; it does NOT establish which NPCs within a realm learned an event, whether rival courts know, or whether a secret was disclosed. `isPersonal:true` explicitly allows personal player toasts even when other UI notices are disabled.

Therefore **NEVER** infer `world_public` from `Global`, `realm_public` from `primaryKingdom:`, or `private` merely because the player's notifications are Disabled. No generic Harmony interception of `BellumCivileNotifications.Show` to mark authoritative public events. Native `CourtSessionEventReports.Narrative` creates localized narration, not visibility metadata.

Current Bridge notification postfix already suppresses `isPersonal` from generic sidecar records, but nonpersonal UI toasts may still be captured with text-hash IDs. Native NPC Crown has a dedicated canonical source-backed notice owner, and its generic notification is suppressed; that fence MUST remain. The Stage31I observer intentionally does not call Stage31H's write seam.

## Authored scope contract (proposed, NOT implemented)

**Two independent axes** are required for each source-backed receipt:

1. **Authoritative fact:** exact Native producer and terminal effect; source `IntegrationId`, realm, sponsor, agenda kind/action/target, final objective state/credit/reason and when **the source can safely assert completion**. An observation day from pre-eviction is not the historical occurrence timestamp.
2. **Knowledge audience and disclosure evidence:** an explicit source-authored visibility class, independent of UI option: `unknown` (default, no event), `internal_diagnostic` (never narrate), `actor_private` (explicit participant-only, no public sidecar), `realm_court` (only after Native producer proves it was a publicly concluded proceeding within that realm), `world_public` (only when separately verified as publicly disclosed world effect). A setting toggle or a completed state cannot upgrade the class. Source-local proof must include `origin_method` and `audience_reason` or an equivalently typed, reviewed code path. Do not produce a broad `public=true` flag.

Recommendation for future schema: separate versioned primitive receipt provenance map keyed by existing Native `IntegrationId` (or a carefully versioned immutable ledger extension) with explicit source, scope and duplicate-ownership fields. DO NOT alter existing Stage31F v1 13-field payload or shared `CourtObjectiveRecord.Finish` opportunistically; such changes invalidate Stage31G and Stage31I parsers and affect every producer. Unknown/legacy/corrupt schema remains held, never reconstructed from strings in toasts.

## Producer-specific ownership matrix (source-backed findings and proposed gating)

| Producer / exact source | What Native actually proves | Initial audience/ownership rule |
| --- | --- | --- |
| `CourtAgendaBehavior.Conclude(Kingdom,PolicyObject,Clan,bool,bool,...)` | Specific filed policy motion resolved `Passed` or `Defeated`, Native `GetObjective` normalizes policy `Succeeded|Failed`; `obsoleteMandate` may suppress praise/blame while preserving result; UI Show uses primaryKingdom | **Candidate for separate realm-court *vote-result* fact** once code-authored disclosure proven; default held. NEVER call a passed vote `law enacted` just from the receipt. Do not turn abolished mandate into faction endorsement |
| Existing Bellum Bridge W7 `BellumCourtTransitionShadowObserver.DiffPolicy` | World current policy state `policy_enacted` / `policy_repealed` and pending transition. Its `policy_vote_closed_without_law_change` is `drop_low_value` after Stage31C | **Canonical owner of actual law-state change.** Court receipt may later narrate independent parliamentary vote/defeat, but never duplicate W7 law enact/repeal; `vote closed` is NOT proof defeat |
| `CourtCouncilAgendas.ConcludeCouncilAppointment` | Verifies actual `decision.AppliedCandidate` equals actual office holder; then agenda passes only if preferred candidate was appointed; can be `Defeated` even though another candidate was successfully appointed | No global event from agenda `Passed|Defeated` alone. When independently authorized, office holder event must use actual candidate from Native outcome; Stage31F v1 lacks that field; **held** until richer source-authored proof |
| `CourtExecutiveAgendas.FinishExecutive` and `ConcludeExecutiveVote` | Can resolve treason, revocation, decrees or failed execution; policy-like `Passed` and `Decreed` are not interchangeable with real-world expulsion or fief transfer | Public only after exact legal effect and appropriate scope confirmed; existing expulsion / feudal / Crown owners retain authority; **held** |
| `CourtActivityAgendas.AdvanceActivity/FinishActivity` | `Completed` means **some** target changed, `activity_partial_execution` if interrupted; `CourtSessionEvents.Report` describes individual observed effects | Only verified affected targets may later be communicated. No false blanket success and no automatic global broadcast; **held** |
| `CourtPeaceAgendas`, `CourtCampaignAgendas`, `CourtRallyAgendas`, `CourtClaimAgendas`, `CourtSubjugationAgendas`, `CourtLiberationAgendas` | Deadline/success/expiry/cancellation about Court's stated foreign or feudal objective, sometimes `NotProposed` = `Expired`; objective `FulfilledElsewhere` is another actor's credit | Realm-court *aspiration/report* at most after proof. Actual war, peace, fief ownership, clientage or treaty effects owned by their existing exact state/treaty paths; **held** |
| `CourtDynasticAgendas`, `CourtTradeAgendas`, `CourtProtectionAgendas`, `CourtTitleGrantAgendas`, `CourtClientGrantAgendas`, `CourtMandateAgendas` | Independently authored execution, partial effects, scheduled/fulfilled elsewhere/technical outcomes | Do not equate goal completion with publicly known marriage, pact, title, treaty or law; verify exact producer, affected parties and published audience first; **held** |
| `CourtAgendaPlayerFlow`, personal mandate reminders and nomination expirations | Player-only messages explicitly use `isPersonal:true`; `NominationExpired` may be `ResultApplied=false` | **Private / not world-public**; no sidecar / no NPC world event |
| `CourtAgendaBehavior.Cancel`, destroyed-realm pruning, technical failures | Cancellation/refund or withdrawal; may have `ResultApplied=false`; no final vote or world effect implied | **Internal diagnostic only**; never global news |
| NPC Crown canonical `NotifyNpcCrownAgenda` / Bellum Bridge `BridgeV1NpcCrownCanonicalAnnouncement` | Separate exact Court/Crown notice with its own source ID and Bridge suppression of generic duplicate | Preserve **canonical NPC Crown owner**. Do not generate second Court terminal source fact |

**Important source-backed distinction:** Policy `FulfilledElsewhere` maps to `CourtObjectiveState.Succeeded` with `CourtObjectiveCredit.FulfilledElsewhere`. Do not credit sponsor or claim their motion won. `NotProposed` with `Expired` is not a defeated vote. `ResultApplied=true` and `ObjectiveTerminal=true` prove result handling, **not** public disclosure.

## Duplicate ownership contract: 4 canonical keys, not a single hash of message text

- `native_agenda_id` identifies an exact source Court business instance (persistent Native `IntegrationId`).
- `semantic_effect_id` identifies a law, office, fief, treaty, war, royal or civil change; W7 or the respective Native domain may be canonical.
- `disclosure_id` identifies *one* genuinely separate public announcement for that audience, if independently proved.
- `campaign_identity` scopes duplicates to a Bannerlord campaign; do not merge separate saves/campaigns by coincidentally reused IDs.

Future producer must dedupe across Native Court receipt, W7 `court_politics_transition`, generic `bellum_notification`, NPC Crown canonical facts, and source-backed direct actions. Do not simply call `TryPersistVerifiedPublicCourtFact` whenever Stage31I reports `policy_vote_candidates > 0`: that counter is deliberately **not** public authorization. Do not change the finite Relay allowlist or 3×12 event-bundle limits without isolated regression checks.

## Regression contract BEFORE any production implementation

**MUST FIX (future narrowly scoped proof first):**
- Native `Conclude` on real policy vote, `Passed`/ `Defeated`: exact action/realm/sponsor/credit, plus explicit reviewed `realm_court` disclosure only after source conclusion; independent of whether player UI notifications are Disabled/KingdomOnly/Global.
- Distinguish accepted law change (W7 canonical) from a separate defeated vote/no policy change; verify no duplicate `policy_enacted|repealed`. Repeated state/source polling after save/load produces same source ID with no new public event.
- Explicitly reject `FulfilledElsewhere`, `NominationExpired`, `Cancelled`, incomplete/unverified Court objective, obsolete faction endorsement, private/player-only reminders and unknown audience.
- Council preferred-vs-appointed outcome, activity partial effects, executive legal effects and foreign treaty/peace/war are still separate canonical owners; no opportunistic public fact.
- Missing provenance metadata, false/unknown audience, old save or mismatch between receipt and disclosure record -> fail closed; do not fabricate retroactive announcements.
- Cross-campaign identity and duplicate notification/W7 source resolution; Native journal 1024 overflow or invalid receipt blocks stage acceptance, not mistaken success.
- No gameplay mutation: original votes, influence/refund, mood, court sessions, faction reactions, Council, foreign actions and AII routes unchanged.

**DO NOT TOUCH in 31J:** all Native/Bridge/Relay production; Court objective shared helpers, UI notice semantics, W7, Bellum SidecarWriter, Stage31H spool, Stage31I diagnostics and Relay event filtering.

**TOUCH in 31J:** ONLY this architecture document plus `Tests/Stage31JCourtPublicProvenanceSourceAudit.Tests.ps1`. Audit asserts current source contracts and explicitly says provenance is NOT implemented. It must not be mistaken for a regression test of a nonexistent publisher.

## Stage results, evidence and next boundary

Source review at pinned current HEAD examined Native `BellumCivileNotifications.ShouldShow`, `CourtAgendaBehavior.Conclude`, `CourtPolicyObjectiveBridge.Refresh`, `CourtCouncilAgendas.ConcludeCouncilAppointment`, `CourtActivityAgendas.FinishActivity`, `CourtSessionEventReports`, Stage31F/G ledger and Bridge Stage31I, W7 `DiffPolicy`, `BellumNotificationCapture.CapturePostfix`. Existing 31J audit source assertions check the absence of audience metadata rather than inventing an authorization. **No PowerShell, .NET, live save/load, game/relay log or named NPC EventID proof.**

**Next proposed Stage31K (separate, source-first):** trace *all* callers of `CourtAgendaBehavior.Conclude` and the source-local vote-producer/notification ordering; establish exact fanout, W7/generic notification overlapping facts and an explicit **realm-court vote-result** disclosure source contract (one event family only) with tests. Only then consider a new versioned Native provenance map keyed by `IntegrationId`, without changing the v1 outcome ledger or shared `ShouldShow`. No automatic Bridge publication or Native ACK in this first provenance stage.

**Proposed future diagnostic log (NOT PRESENT YET):** `BC_COURT_PUBLIC_PROVENANCE status=recorded|held; agenda_id=...; audience=realm_court|internal_diagnostic; source=court_policy_conclude`; Bridge must later show `source_provenance_verified=true` before publishing; then spool Fact ID, Relay accepted ID, AII saved EventID and named NPC `DynamicEvents[]` in a single final-alpha game run. Public/privacy mismatch, duplicate enactment, or missing provenance blocks release.

**31J conclusion:** **STOP** generic publicization; design the first narrowly authored source proof. Do not introduce a cross-cutting helper or a new Harmony patch under the pretext of this stage.
