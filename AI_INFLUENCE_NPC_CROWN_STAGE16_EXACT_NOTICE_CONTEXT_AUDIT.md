# Stage 16 — in-flight exact native NPC Crown notice provenance: result audit
Date: 2026-10-22 | **Source/mock CI PASS**, no native 1.4.8 DLL or gameplay test, no sidecar publish.

## Pinned scope and evidence
- Bellum source feature pre-code contract `f3392b207a047c2cb5916ff30419f79f44648f4e`; validated code HEAD `6c96ce44751b53f55eb5cd12f5840ad531f3cef3`; Bellum `main` remains unchanged.
- [**Bellum Stage16 CI success — 39742617688**](https://github.com/AIRebelRelay/BellumCivile/actions/runs/39742617688); compiled mock/source full feature workflow green. `STAGE16_NPC_CROWN_NOTICE_CONTEXT_PASS`, `STAGE7_NPC_CROWN_RUNTIME_PASS`, `STAGE7_NPC_CROWN_SOURCE_PASS`, `STAGE11_NPC_CROWN_INVENTORY_PASS` confirmed in runner logs.
- [Pre-code regression contract](./AI_INFLUENCE_NPC_CROWN_STAGE16_EXACT_NOTICE_CONTEXT_CONTRACT.md).
- The distinct Bellum Bridge `AIRebelRelay/Bannerlord2-AiInfluence-BellumCivile` Stage14 remains shadow-only, `Publish=false`. **NOT** `ai-rebel-relay-bridge`.
- Full diff from pre-code contract to validated code touches exactly FIVE paths (two production, one test stub, one new runtime test, one existing CI workflow). Bellum's shared `NotifyAgenda`, dedicated `NotifyNpcCrownAgenda` body, Bellum native notifications/filtering, agenda scheduling/priority/save and ordinary Court/UI remain untouched.

## ROOT CAUSE AND VERIFIED CHANGE
Bellum Stage15 made native `NotifyNpcCrownAgenda` a distinct caller, but its generic `BellumCivileNotifications.Show` parameters did not include `ExternalIntentId` or the exact `CourtAgendaId`. Realm/text/time lookups or choosing one of several `court_announced` saved tickets cannot prove same-docket ownership.

- `Behaviors/CourtNpcTreasonAssignment.cs`: after native `ExternalIntentId -> agenda.IntegrationId` has been saved, query the **existing** read-only ticket/status getter, attach its immutable snapshot to one **private** in-flight context scoped to the selected realm, invoke the unchanged dedicated `NotifyNpcCrownAgenda(agenda)`, clear snapshot+realm in `finally`. Getter rejects wrong realm reference, wrong realm ID, non-`court_announced` status and absent agenda ID. No new persistent saved field, polling, timers or world mutation.
- `BellumIntegrationNpcCrown.cs`: additive `GetActiveNpcCrownAnnouncement(Kingdom realm)`, strictly guarded by `BellumIntegrationBehavior.RequireCampaignThread`. Outside this **synchronous** dedicated notification returns null, including after exceptions; a **read-only in-flight token**, not proof that user actually saw the notification or that an expulsion happened.
- `Tests/AiInfluenceNpcCrownStage7.Stubs.cs`: test-only mock native notice captures the exact token; wrong-world-reference probe and injected UI throw, no shipping side effect.
- `Tests/AiInfluenceNpcCrownStage16.NoticeContext.Tests.ps1`: compiles the real Bellum integration+assignment with existing source stubs and tests pre-stage null; exact realm/ruler/target/ticket/agenda/status witness; wrong realm object with same StringId; after-return null; saved native ticket unchanged; replay no extra notice; throw cleanup without pretending an already-committed agenda was rolled back; off-thread guard; missing court. New step/path in existing feature workflow.
- Explicit native `CourtAgendaBehavior.OpenTerm` order source-checked: `_agendas.Add(agenda)` occurs before `TryAttachStagedNpcTreason(agenda,context)`; native `GetNpcTreasonIntent` therefore has a registered agenda to resolve the exact ID when notification begins.

## MUST NOT CHANGE verified
Player/localized native notice, original shared ordinary `NotifyAgenda`, UI scope filter, one NPC notice attempt, private staged requests, Court votes and political outcomes, SaveDefiner, `BC_CourtNpcTreason*` persistence keys, Royal Peace, Bridge queue/SidecarWriter/W7, Relay/ACK/Dynamic Events, foreign diplomacy.

## Regression / game-log proof contract
Positive source/mock: `STAGE16_NPC_CROWN_NOTICE_CONTEXT_PASS` and previous stages' CI. No added production log line: existing `AIInfluence NPC Crown intent attached; realm=...; id=...; agenda=...; status=court_announced` remains the native record. In eventual game with Bellum native notifications allowed, Bridge Harmony may see `caller=BellumCivile.Behaviors.CourtAgendaBehavior.NotifyNpcCrownAgenda`; its future **separate** source-backed adapter must fetch `GetActiveNpcCrownAnnouncement` **synchronously in postfix**, compare native realm/ruler/target and agenda and fail closed if token absent. It MUST NOT infer public announcement from missing player-scoped toast.

## Limitations and next stage
- Bellum feature CI uses isolated stubs and source tests. **Actual Bannerlord 1.4.8 game DLL compilation after Stage16 has NOT been performed.** No game/UI notification scope runtime, save roundtrip in actual Bannerlord, Bridge Harmony caller stack, duplicate native facts, Relay sidecar ACK, persisted AII EventId or NPC knowledge result is proved.
- This stage does not publish a new `court_politics_transition` and does not suppress any existing W7/native notification. Exactly one canonical source owner remains to be established and tested.
- Next stage (independent): Bellum Bridge 0.8.6 **log-only provenance verification** for this getter in its existing `BellumNotificationCapture.CapturePostfix` caller when `NotifyNpcCrownAgenda` is seen; compare exact native context to runtime ticket inventory; avoid editing generic writer/notification semantics. Only after the provenance and duplicate-ownership risk are tested may publication be assessed. No merge/release.
