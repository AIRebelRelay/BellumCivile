# Current source findings — Bellum candidate1.4.12.5

Base: S23C cumulative ZIP; remote base AIRebelRelay/BellumCivile,
feature/cr-realm-preparation-receipts-2026-11-18,
903f6772a8bebab68b1296121d770b741ae1a232 / Draft PR54 rechecked unchanged.
No upstream port, branch mutation or interpretation of AI Influence code is involved.

## Relevant call chain

| Entry / caller | Chain and current responsibility |
| --- | --- |
| OnDailyTick | ReconcileExistingWars -> ReconcileInternalConflicts -> ReconcileReversibleScores -> ReconcileAiInfluenceForeignLedgers -> ProcessQueuedTerminalResolutions -> ProcessActiveWars -> ProcessInternalWhitePeaceOpportunities |
| Score-changing callbacks | SetFeudObjectiveControl, OnSettlementOwnerChanged, OnMapEventEnded, OnVillageLooted, OnHeroPrisonerTaken -> QueueTerminalWarScoreResolution |
| Daily accounting | ProcessActiveWars -> occupation, full occupation, landless pressure, ticking score -> terminal queue |
| Internal recovery | ReconcileInternalConflicts can queue a civil-war terminal outcome; shared queue must not become foreign-only |
| Full occupation | TryForceFullOccupation -> ForceWarScore(+/-100) -> queue |
| Landless pressure | ApplyLandlessRealmPressure -> force decisive score -> queue |
| Terminal scheduler | ProcessQueuedTerminalResolutions -> ResolveQueuedTerminalWarScore, outside battle/ownership callback cleanup |
| Foreign terminal | current protections/reconciliation -> ClearTerminalResolution -> TryQueueAiParley(forced:true) -> if false, BeginResolution -> ResolveTerminalConflict -> MakePeaceAction |
| Internal exhaustion | TryResolveInternalExhaustedVictory -> ResolveTerminalConflict too; do not alter this consumer |
| Ordinary AI parley | TryQueueAiParley also has WarPeaceRevamp.TryCreatePeaceDecision and WarScore.TryResolveForeignWhitePeaceFromProposal callers |
| Shared parley admission | TryQueueParley also serves player-facing queue; do not blanket-disable it |
| Later treaty resolution | ForeignTreatyBehavior.OnDailyTick -> ResolvePendingParley -> prepare/revalidate draft -> budget -> councils/commitments/override -> ApplyTreaty |
| Hostage delivery | ApplyTreaty may defer through HostagePactBehavior.DeliverTreaty/RecoverTreatyDelivery; false is not universally no-effects failure |

## Findings that change the design

1. BellumCivileConstants.WarScoreForcePeaceThreshold is100f. Ordinary low War Will
   or a failed API call is not proof of terminal defeat.
2. QueueTerminalWarScoreResolution latches threshold score and queues cleanup for
   a later daily tick. But reversible custody/objective recalculation can clear
   the terminal flag when score falls below100. The queue is NOT an irrevocable
   historical decree of defeat. Most ordinary score mutators use IsScoreLocked;
   reversible paths do not all use that identical guard. A long LLM window must
   re-read the actual post-reconciliation state, not trust a stale queue log.
3. A refusal from TryQueueAiParley can lead to bare MakePeaceAction via
   ResolveTerminalConflict. This fallback does not run ApplyTreatyCore's term loop.
   It must not be the silent result of ownership admission failure in a future mode.
4. Forced acceptance is already a distinct Native rule: WouldCouncilAccept first
   returns false for IsBudgetBlocked, then true for forcedAcceptance, then ordinary
   council logic. Thus forced terms can override ordinary council willingness,
   while budget blockage still matters. Do not claim councils always have a veto
   or that forced mode skips every validation.
5. Forced player parley uses a dedicated inquiry; daily treaty tick routes forced
   player involvement there instead of its unattended non-forced vassal path.
   The first proposed crisis scope excludes ALL player political participation.
6. ApplyTreatyCore applies terms before peace and additional structural terms after
   peace, then records Applied. It is not a new atomic execution/receipt protocol.
   An exception, hostages deferred or a false return is not permission to replay costs.
7. TryCloseOrphanedForeignWarTracker can legitimately close accounting for an
   eliminated/missing realm or independently ended war. This is not proof the
   Bridge crisis imposed its own treaty or may announce its own success.
8. WarScoreRecord.WarKey is derived from an unordered pair and is reusable;
   StartedDay is a float. Neither a pair key nor a timestamp tuple is asserted to
   be a universally unique durable war incarnation. The current S23B ConflictEpoch
   is a caller-supplied value; no authoritative allocator is implemented yet.
9. S23A RequestCrisisResolution is only an unconsumed verdict; S23B's ValidRequest
   excludes TerminalForeignWar. Do not disguise a crisis as AutomaticForeignPeace
   to slip it into the ordinary journal.

## Blast radius / minimum future boundaries

WarScore queue/resolver, record score flags, ForeignTreaty admission/ratification,
player UI, custody/hostage continuations, internal conflicts and linked client/alliance
war owners overlap. A global MakePeaceAction/ApplyTreaty veto is outside the intended
boundary. A full tick disable would stop accounting and tribute as well as intent.

This stage changes NONE of these methods. The Native gateway, authoritative epoch,
crisis persistence and receipt reconciliation require separately bounded work;
there is no honest one-line activation patch on the current contracts.
