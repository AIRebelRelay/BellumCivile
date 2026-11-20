# Bellum 1.4.12.15 — CR diplomacy gateway (source candidate)

- Root cause: `TryQueueAiParley` is public but takes mutable `WarScoreRecord`, has no actor-revision contract and cannot yield an exact detached treaty receipt. Direct Bridge use risks stale war/pair reuse or confusing queued with applied.
- TOUCH: only one additive production file `BellumIntegrationCrDiplomacyGateway.cs`; module/Assembly versions, gate/test metadata. Existing foreign treaty logic not edited.
- DO NOT TOUCH: `WarScoreBehavior`, `ForeignTreatyBehavior`, native war/peace actions, voting, council support, player parley, hostage delivery, Naval logic, existing save fields.
- MUST FIX: read an exact foreign tracked war with independent unique `ConflictInstanceId` and current rulers; after LLM assent request only nonforced white peace; return detached proposal id; read exact terminal state even after war ends.
- MUST NOT CHANGE: normal NPC autonomous Bellum peace/wars, general drafting, players' political rights, original QA-only forced peace command, previous treaty lifecycle and Native Witness safeguards.

Regression: new war same pair, old instance rejected; player realm rejected; changed ruler rejected; ended/ambiguous/native witness not match rejected; concurrent pending refused; unknown after queue never blindly retried; `Applied` only from true Bellum status. Existing 27 treaty instance tests + native witness 21 + WarID 15 + WarIdentity31 + identity reader52 + mutation10 + QA15 preserved. New 10 source-contract checks do NOT substitute live tests. Compile Core + Naval with default `TreatyQa=false`; source package full module.

New log: `BELLUM_CR_DIPLOMACY status=queued|rejected|unknown_after_queue`; ordinary `Foreign treaty applied; ...` remains authoritative, not our log marker. No arbitrary LLM text/terms accepted by Bellum. Must run actual Windows gate; game NOT_RUN in this artifact.
