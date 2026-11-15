# Calradia Remembers 2.8.9 + Native Bellum Civile: LLM diplomacy architecture & living audit

> **Дата:** 2026-11-14 · **Статус:** source-backed discovery / working design, **НЕ реалізація, НЕ дозвіл на патч**.
>
> Мета: дипломатія, в якій NPC самі ініціюють, обговорюють, узгоджують і виконують рішення, із пам'яттю про причини/наслідки й політичною правдоподібністю. Зберегти «controlled chaos» без вигаданих механічних фактів, подвійних війн/миру й обходу правил Bellum. AI Influence більше не є цільовим runtime.

## 0. Pinned inputs / provenance

| Система | Фіксація стану | Джерело |
|---|---|---|
| **Calradia Remembers (CR)** | v2.8.9, `main` @ `c49c01c7f00d674768c1824512d8cf683e3b2db0` | [LogRaam/calradia-remembers](https://github.com/LogRaam/calradia-remembers), [2.8.9 changelog](https://github.com/LogRaam/calradia-remembers/blob/c49c01c7f00d674768c1824512d8cf683e3b2db0/NEXUS_CHANGELOG_v2.8.9.txt) |
| **CR binaries / mod folder** | 2.8.9 uploaded 2026-11-14; `SubModule.xml` / code v2.8.9 | [User Drive / CalradiaRemembers](https://drive.google.com/drive/u/0/folders/1bbLC2lc5BqO4CxWBj6oowMkOsZfCR6Eu) |
| **LLM Roleplay Service** | `master` @ `1852e78b20efb9bbaa5446c3e00edbf7bb9e2157` | [LogRaam/LLM-Roleplay-Service](https://github.com/LogRaam/LLM-Roleplay-Service) |
| **Native Bellum — OWNER / target repo** | customized 1.4.11.1 QA source; `main` @ `59b2aee8268cf1633e052e6b44e1cdba0e3c15fb` | [AIRebelRelay/BellumCivile](https://github.com/AIRebelRelay/BellumCivile) |
| **Old Bellum Bridge — NOT native Bellum** | AII-dependent Bridge v0.8.8; `main` @ `f362a4f70786896b4160489bc1e3f448fdd0578e` | [AIRebelRelay/Bannerlord2-AiInfluence-BellumCivile](https://github.com/AIRebelRelay/Bannerlord2-AiInfluence-BellumCivile) |
| **Relay Bridge — separate** | not examined for diplomatic ownership in this stage | [AIRebelRelay/ai-rebel-relay-bridge](https://github.com/AIRebelRelay/ai-rebel-relay-bridge) |

**Version gate (P0).** CR 2.8.9 is stated by its upstream main commit to be built/tested on **Bannerlord 1.5.7 + War Sails 1.3.7**; backward compatibility with Bannerlord 1.4.x was explicitly **not tested**. Native Bellum 1.4.11.1's compatibility with this exact game build and CR 2.8.9 **is not established by this audit**. Before a runtime integration, pin exact game/DLC/mod DLL matrix, check full source/referenced TaleWorlds ABI and perform a separate sandboxed campaign run. Never infer compatibility from either mod starting alone.

**Evidence levels:** `SOURCE` = observed in pinned source; `DOC` = author's documented public API; `PROPOSAL` = design, not shipped; `UNKNOWN` = requires real call-chain/game validation. Today's work did not compile, modify production code or validate gameplay.

## 1. What CR 2.8.9 ALREADY does — and what it does not

| Surface | Confirmed source-backed behavior | Integration assessment |
|---|---|---|
| `press_for_war` conversation verb | Persuaded lord queues a delayed petition, later `DeclareWarDecision` enters the realm's kingdom vote (`PressForWarVerb` / `PressForWarBehavior`), influence and authority checked. Conversation stores only *intent*; eventual vote decides war. | Reuse the fiction/agency, but test Bellum's war support/vote ownership. **Do not claim "war declared" at petition time.** |
| `mediate_peace` | A player with sufficient rank/trust can persuade an enemy ruler in 1:1; executor calls `MakePeaceAction.Apply(leaderFaction, target)` directly. Counterparty assent is abstracted, not a bilateral parley. | **P0 conflict** with Bellum's treaty/parley and its terms; requires a mediated execution seam/guard, not a second direct peace path. |
| `LordStrategyBehavior` | MCM-gated **deterministic**, weekly anti-hegemon strategy; one foreign realm step per week globally, at most one per month per realm. Chooses among a war vote, peace vote, alliance proposal, call-to-war. Skips own player's realm and some player-facing offers. | Not an LLM planner; its native `KingdomDecision` actions can overlap Bellum War & Peace Revamp. Treat as independent scheduler until ownership proven. |
| `WarCouncilOfferBehavior` | Offers player a council after major army action but static `Enabled` is **false by default**, because auto-offer UI still under validation. Council has a separate session/pledge lift. | Manual council and auto-offer are different features; do not describe auto-offer as production default. |
| `CouncilLift` | Council/parley pledges may directly call `DeclareWarAction.ApplyByDefault` or `MakePeaceAction.Apply` after CR-specific checks. | Another **P0 war/peace execution seam**, independent of `mediate_peace`. |
| `ScenarioConsequenceExecutor` | Scripted `DECLARE_WAR`, `MAKE_PEACE`, `PRESS_FOR_WAR`; direct TaleWorlds war/peace mutation for former two, with scenario guards. | Distinguish authored scripted outcomes from AI diplomatic transactions. Can bypass Bellum treaty pipeline if left ungoverned. |
| `EdictBehavior` / `EnactEdictVerb` | Local/realm edicts with cost, expiry, contest/repeal, model effects, autonomous NPC edicts (setting-gated). | Real internal-law simulation, not a foreign treaty engine. Avoid overlapping Bellum laws/policies unless dedup/ownership is explicit. |
| `CrActions.Register` | Public extension registry: catalog/interpreter, 1:1 teaching, dispatch to outside `Execute`. `IsEligible`, `TeachingText`, `Guidance` and `WhenNotToEmit`; duplicate builtin action names rejected. | Excellent for **new** Bellum verbs. **Cannot override built-in `mediate_peace` simply by registering the same name**. Always re-check permissions/state in Execute. |
| `CrAims.Register` | External NPC aim, with provenance/expiry; CR chooses when it surfaces; as of source, external aims surface in **conversation** (letters/audiences future), one active aim per lord. | Useful for meaningful NPC initiative **toward player**; not proof of autonomous cross-realm NPC↔NPC diplomacy. |
| `CrLetters.DeliverWithId` | Courier letter/replies with external IDs, can track `Replied` and `GetStatus/GetReply`. | Reuse for player-targeted offers and pending decisions; no assumption that one recipient can sign for another realm. |
| `Feed.Record/Update/Retract` | External events with identity, actors, factions, places and rumour/deed lifetime. Docs: 20 new records per source per game day; top six news surface normally, others by relevance. | Reuse for factual political news, but **only after mechanical receipt**. Event is not an executable deed. |
| `CrPrompt.RegisterVariable` / `CrNpcMemory` / `CrConversation` | Supported provider-grounded context, memory and session events. | Use CR as sole NPC-memory owner; Bellum is source of political/game truth. Limit feed noise; track provenance. |

**Critical distinction:** CR's deterministic `LordStrategyBehavior` may initiate diplomatic decisions, but we found no evidence of a general LLM-governed, bilateral, multi-turn foreign-treaty planner with coherent persistent negotiations in CR 2.8.9. This is **not** a claim that none of its other subsystems have partial abilities; inventory remains open until complete call-chain/runtime audit.

## 2. What native Bellum already owns (do not reinvent)

From [Bellum maintainer guide `War and Peace](https://github.com/AIRebelRelay/BellumCivile/blob/59b2aee8268cf1633e052e6b44e1cdba0e3c15fb/README.md):

- **War & Peace Revamp** (default on): clan War Will, legal targets, multiple fronts, diplomatic/territorial motives, inherited/special-case wars, ruler and clan decisions.
- **War Score** (signed -100…100), peace readiness, exhaustion, protected plot wars, civil vs foreign terminal outcomes.
- **ForeignTreatyBehavior** owns foreign **Parley → draft → two court evaluations → ruler/house ratification → ApplyTreaty/Core → cleanup**; supports UI and AI peace packages.
- Treaty terms: **fiefs, prisoners, reparations, ongoing tribute, political humiliations, alliance/trade severance, royal marriage, vassal/client release, clientage, hostage pacts** and related structural cases. Legal war-score budget and solvency are authoritative, never LLM prose.
- **BellumIntegration** has read-only `GetCourtAgendas`, `GetPendingVotes` and specific NPC council/pledge APIs. Those APIs are **not** a blanket public foreign-treaty executor; audit exact external semantics before exposing any new command.
- Outside foreign politics, Bellum owns **court factions, civil wars, dynastic succession, titles, policy/council deliberation, internal wars**. Integration must preserve these and save/load.

**KNOWN P0 collision:** [CR mediate_peace executor](https://github.com/LogRaam/calradia-remembers/blob/c49c01c7f00d674768c1824512d8cf683e3b2db0/CalradiaRemembers/GameState/BannerlordGameStateBridge.cs) calls `MakePeaceAction.Apply` directly, while [Bellum ForeignTreatyBehavior](https://github.com/AIRebelRelay/BellumCivile/blob/59b2aee8268cf1633e052e6b44e1cdba0e3c15fb/Behaviors/ForeignTreatyBehavior.cs) has a separate whole-treaty transaction. The CR `CouncilLift` and scripted `ScenarioConsequenceExecutor` have additional direct war/peace calls. **No code changes until mapping the exact TaleWorlds/Harmony interceptors and every affected caller.** A direct CR peace may be **blocked** by Bellum's ordinary-foreign-peace guard while CR still reports success; the specific path is proven by source review below and the live outcome remains to be tested.

**Legacy Bridge is not drop-in CR support:** [Bridge SubModule.xml](https://github.com/AIRebelRelay/Bannerlord2-AiInfluence-BellumCivile/blob/f362a4f70786896b4160489bc1e3f448fdd0578e/module/SubModule.xml) explicitly requires `AIInfluence`. Do not relabel it CR Bridge or transplant old Harmony/sidecar semantics. Relay Bridge is an entirely different project.

## 3. Proposed single-owner design (PROPOSAL, not settled)

**Game truth / execution:** Native **Bellum** (plus native TaleWorlds execution when Bellum explicitly delegates) is sole owner of *foreign* war eligibility, treaty lifecycle, score budget, ratification, territorial/money/hostage consequences, and the actual peace transition. All Bellum domestic governance remains Bellum-owned.

**NPC mind / dialogue / narrative:** **CR** owns character voice/personality, private regard/memory, conversations, interpreter, courier letters, aims, and delivery of source-attributed facts into the prompt. CR may initiate and *describe* proposals; it must not independently finalize Bellum-owned transactions.

**Diplomatic orchestration:** A **new, narrowly scoped integration component** (module ownership/location TBD, not the old AII Bridge) maps verified intents to Bellum public transaction APIs, handles immutable IDs/state transitions, publishes *terminal* receipts to CR, respects player UI/consent, and never mutates CR's private memory store. Prefer sanctioned APIs from both maintainers instead of Harmony patches.

**Relay/NanoGPT:** solely transport, separate model roles, provider-bound integrity and diagnostics. No second diplomatic ledger, no persistent NPC memory or arbitrary keyword-to-action routing in Relay.

**Ownership invariant:** Exactly one component may commit a war/peace/treaty; other layers may request, vote, observe or narrate but never replay the mechanical mutation.

## 4. Diplomatic action lifecycle (PROPOSAL)

`Grounded current state → NPC motive → Intent (nonbinding) → Candidate / offer → legality preflight → durable proposal (owner + terms + version) → counterparty delivery → response → both councils / authorized rulers → strict final validation → ONE Bellum commit → authoritative outcome receipt → CR Feed + memory/update`.

- Every proposal has `CampaignId / ProposalId / WarKey / Revision / ActorHeroId / Source / Target / IssueKind / TermsFingerprint / CreatedDay / Expiry / Status`; re-resolution from IDs at execution, no cached Hero reference. Precise schema TBD with Bellum author.
- States distinguish `Thought/Intent`, `Offered`, `AwaitingReply`, `Countered`, `Ratifying`, `AcceptedNotApplied`, `Applied`, `Rejected`, `Withdrawn`, `Invalidated`, `Expired`. A plan/letter/agreement is **not** world-state change.
- **No silent term repair:** if Bellum revises terms (`DraftRevision` / changed fingerprint), prior acceptance is invalid and requires new consent. Overbudget/unknown faction/foreign vassal/stale war/denied terms fail closed.
- **Negotiation:** bilateral/mediated, asynchronous game time, deadline/cooldown, evidence of delivery, multiple proposals per realm without replays, explicit player agency and safe unresolved-state recovery on reload.
- NPC policy comes from personality, diplomacy stakes, political factions and known facts; no global "everyone maximizes war" rule. Different responses: negotiate, delay, refuse, bluff (claim labeled as claim), counter, court pressure.
- **Controlled chaos:** unpredictability in motive/framing and *which legal move is proposed*, not randomized bypass of legal guards. Bounded initiative/cadence/LLM budgets; cost/fail-open behavior for provider outage; avoid endless war/peace oscillation.
- **AI models** may weigh interests or draft plausible text, but *cannot* authorize actions, invent concessions, bypass votes, infer an agreement from dialogue, or make their own unverified claims canon.
- Ordinary player decision and AI-to-AI transactions need equal legal contracts; special UI/authority paths remain distinct.

## 5. Capability/ownership matrix (WIP)

| Feature | Today | Intended authoritative owner | Gap / required research |
|---|---|---|---|
| War proposals and voting | CR `press_for_war` + `LordStrategy` use kingdom decisions; Bellum War Will and votes | Bellum/native kingdom election | Trace all decision hooks; prevent duplicate filing and illegal force-war, preserve normal vanilla proposals |
| War declaration | CR council/scenarios direct TaleWorlds; Bellum native | Bellum/vetted engine pipeline | Add sanctioned CR action veto/delegation and unique execution receipt, ensure StoryMode protection |
| Peace readiness | CR direct peace gate is rank+regard+war; Bellum has War Score/Readiness | Bellum | CR cannot call raw `MakePeaceAction.Apply` for Bellum-owned conflict |
| Third-party mediation | CR `mediate_peace` direct immediate peace; one side's assent | Bellum treaty + CR negotiation surface | Replace **behavior only through author-approved hook**, preserve CR's trust/rank gate where relevant |
| Foreign treaty packages | Bellum: terms, two councils, final strict commit | Bellum | Expose read-only proposal snapshot / strict action API, actor-specific scope, revision fingerprint |
| Alliance/call-to-arms | CR `LordStrategy` kingdom decision; Bellum treaties/alliances | Decide per relationship type; Bellum for treaties | Inspect native alliance ownership/interceptors and role of TaleWorlds alliance decisions |
| Trade agreements | Bellum treaty term can end trade; other treaty/relationship systems require inventory | Bellum/native existing owner | Do not invent standalone contract without exact mechanics |
| Territory/prisoners/hostages | Bellum full settlement term; CR other independent verbs | Bellum for treaty transfers; CR for non-treaty personal deeds | Prevent duplicate transfers, empty custody, title desync |
| Tribute, reparations, wealth | Bellum War Score-priced values, 100-day tribute default | Bellum for war settlement | Do not silently map arbitrary LLM amount/duration to legal Bellum terms |
| Internal court pressure | Bellum Court Agendas, CR Aims/Feed | Bellum state, CR perspective | Promises ≠ vote; private pressure ≠ public event; exact provenance |
| NPC-to-NPC foreign diplomacy | Deterministic CR strategy but no verified LLM bilateral workflow | New orchestration around Bellum | Actor/recipient sessions, delivery, deadlines, retention; needs explicit CR hook |
| Player diplomacy | CR conversations, couriers, aims + Bellum UI | Bellum commit, CR UX | Consent and reconciling letters with current treaty/vote status |
| Political news / memory | CR Feed + own world events; Bellum court notices | Bellum facts → CR hearsay/records | Stable IDs, ownership map, duplicate producers and 20/day feed throttle |
| Kingdom/client changes/succession | Native Bellum | Bellum | No new generic clan movement or kingdom creation via LLM until source-backed invariants |
| Compatibility | CR 2.8.9 tested 1.5.7; Bellum current 1.4.11.1 not jointly tested | Build/release gate | ABI, War Sails, native module order, vanilla mods, save/rollback evidence |

## 6. API discussion with LogRaam (requests, NOT claims)

Existing tools should be exhausted first: `CrActions.Register`, `CrAims.Register`, `CrLetters.DeliverWithId` and `Replied`, `Feed.Record/Update/Retract`, `CrPrompt.RegisterVariable`, `CrConversation`, `CrNpcMemory`. Stable released API is promised by author; avoid private reflection.

### CR-API-01 (P0): sanctioned **native diplomatic action mediation**
A public handler to **preflight/delegate/refuse** selected *built-in* effectful CR actions **before** CR calls raw TaleWorlds mutation: minimum `mediate_peace`, CouncilLift war/peace, authored scenario war/peace, `press_for_war` and LordStrategy decisions if appropriate. Must identify `source/action kind`, actor/target, authority, current scene/session, intent-vs-commit, campaign and source id. External handler returns an explicit `Handled/PassThrough/Rejected/Pending` receipt; no success narration on failure. Preserve built-in behavior when no integration is installed. **Do not hijack names using `CrActions.Register`** (duplicate rejected).

### CR-API-02 (P0): source-backed **event after action resolution**
Structured before/after state and success/failure/attempt identifiers; no direct memory injection from a mere LLM plan. At-most-once callback or idempotency on load/retry. New events must not turn a rejected/queued case into "peace happened".

### CR-API-03 (P1): bounded autonomous **NPC-to-NPC request/response** channel
A sanctioned way for an external political system to ask an eligible ruler/council's CR persona to deliberate/respond, carrying current authoritative data and an explicit actor/recipient/issue, with no player conversation spoofing. Deadline, cancellation, separate LLM route, token policy, rate limit, privacy/source attribution. Use existing prompts/session identity where possible; **no background LLM side effects without authoritative returned intent**. Feasibility to be discussed with author.

### CR-API-04 (P1): public **read-only status/context** bridge
Expose reliable structured action availability/current talks, ruler/NPC political audience/scope, and safe current-state prompt variables without scraping UI or deriving authority from free text. Prefer owner-provided facts over schema guesses.

### CR-API-05 (P1): integrated delivery + reply for **realm-to-realm** diplomacy
Existing `CrLetters` is player-targeted. Discuss supported external NPC↔NPC courier/decision delivery, exact IDs and callbacks, preserving game-time delay. This could be a new API or Bellum-owned orchestrator; do **not** assert CR supports it today.

### CR-API-06 (P2): scenario / initiative arbitration
When a Bellum-owned conflict is about to be changed by CR's `LordStrategy`, council or authored scenario, allow precise delegation or safe native default if not managed. No global disable by default. Ask LogRaam which hooks are already available in 2.8.9 and which should land upstream.

**Open question:** who supplies the LLM-planned **worldwide** diplomatic cadence? `LordStrategyBehavior` is a deterministic scheduler, not an LLM decision cycle. Do not schedule a second universal war/peace AI until both owners agree on arbitration and cadence.

## 7. Bellum public API candidates (NO production edits yet)

1. **Read-only:** current foreign wars, War Score, legality, available treaty terms/budgets, current proposal `ProposalId+WarKey+DraftRevision+TermsFingerprint`, both councils/ratification, active treaty/tribute status, read-only consequences/terminal receipts.
2. **Intent / propose:** validated typed request for *starting* lawful war pressure/parley and drafting **exact** terms, no immediate world mutation. Confirm actor's clan/ruler/voter role, no fake king.
3. **Response / commit:** accept, reject, revise or withdraw exact draft using Bellum transaction owner; result contains semantic outcome and proof of application.
4. **Event surface:** source IDs for proposals, votes, failures, terminal outcomes; distinguish public court notice from private deliberation. Support dedup and mark after commit.
5. **Side-effect safety:** campaign-thread required, scenario-specific veto, native protected war, StoryMode, civil conflict partition, escrow/prisoners, economic solvency, stale save reconciliation.
6. **Existing consumers:** inspect every call to any proposed `BellumIntegration`/`ForeignTreatyBehavior` seam before changing it. Never alter shared method defaults to fix only CR.

## 8. Regression contract BEFORE implementation

**Positive (must work):**
- Successful CR `press_for_war` creates *one* legal pending vote with house sponsor and truthful rumour; only final vote can begin war.
- Authorized CR mediation creates a **pending exact Bellum parley** (not direct peace); both sovereign sides/courts follow real legal rules. Only one applied treaty ends the war.
- Legal white peace, fief, tribute, reparations, hostage and mixed packages follow strict Bellum validation and one terminal effect; successful save/reload retains identity.
- AI↔AI proposals can occur without the player, and player-targeted requests respect agency and actual information available to recipient.
- Factual Bellum court outcome reaches a relevant CR NPC as **one** sourced event; CR remembers accurately and separates hearsay from firsthand knowledge.

**Negative/neighbor protections (must NOT regress):**
- Pure roleplay discussion/promise/letter, intention to declare war, and failed/expired proposal NEVER mutate a war state.
- Existing CR `CouncilLift`, `ScenarioConsequenceExecutor`, `LordStrategy` and `mediate_peace` must not become a shadow path around Bellum; no unconditional blanket block of unrelated vanilla or scripted acts.
- No duplicated `MakePeaceAction.Apply`, territory transfer, payouts, hostage delivery, or repeat-on-HTTP-retry / load / replay. No silent treaty draft repair accepted without new consent.
- War declaration rejected when proposal invalid, already at war, just at peace/protected by storyline, target disappeared, sponsor left clan, influence insufficient or law disallows.
- Civil war, claim feud, independence, succession, council appointment, policy voting, royal edicts, court pressure, trading/clientage and AI companion actions unchanged.
- Bellum Revamp OFF: correct vanilla fallback, no ghost Bellum transaction; ON: Bellum owns it. *Neither* setting may produce duplicate peaces.
- Player's faction not autonomously signed into terms without player authority/consent; quiet/non-player realms still progress.
- CR 2.8.9 ordinary dialogue, group councils, letters, memories, external verb registration, saved games and rate limits unaffected.
- CR 1.5.7 + War Sails 1.3.7 / Bellum runtime compatibility separately verified, not inferred from build-only success.
- All new API calls fail closed on unavailable/old versions, with version/feature negotiation; no historical AII Bridge starts without AI Influence installed.

**Required observations when implementation eventually exists** (these are *proposed log keys*, NOT current log output):
- `CR_BELLUM_DIP_INTENT id=... actor=... target=... status=queued`
- `CR_BELLUM_DIP_PREFLIGHT id=... owner=bellum lawful=true|false reason=...`
- `CR_BELLUM_DIP_TREATY proposal=... revision=... status=pending|applied|rejected|invalidated`
- `CR_BELLUM_DIP_FEED id=... outcome=... recorded|duplicate|throttled`
- Unexpected: any CR-owned direct `MakePeaceAction.Apply` on a Bellum-owned live parley; duplicate terminal event, replay after reload, "succeeded" without native receipt.

Existing diagnostic anchors: CR `[WARPRESS]`, `[STRATEGY]`, `[SCENARIO]`, `[ACTION] mediate_peace`, `[FEED]` and Bellum native treaty logs. During live testing correlate game-day, source actor, war pair, proposal id and before/after war/tribute/fief state. Use `cr.heard <npc> <event-id>` for news delivery.

## 9. Stage-by-stage rollout (one stage at a time)

**Stage 0 — compatibility + ownership audit ONLY (current boundary).** Pin fresh game, War Sails, CR DLL, Bellum native/Bridge HEADs. Build call graph: CR `mediate_peace` / CouncilLift / ScenarioExecutor / PressForWar / LordStrategy → TaleWorlds / Bellum Harmony; Bellum normal war vote → Parley → treaty commit; register all callers and touch points. Prepare offline fixtures, no code changes. Confirm baseline CR-only, Bellum-only, and CR+Bellum at same Bannerlord version.

**Stage 1 — read-only observations.** If Stage 0 passes, add a *new* integration module only to observe and project owner-verified Bellum current context / events into CR via public APIs; no mechanical actions yet. Test provenance, privacy, throttle, de-dupe, save/load.

**Stage 2 — authority-safe actor intent.** One strictly typed CR action (choose narrowest, e.g. sponsor a Bellum court war proposal) with preflight, idempotent state, tested neighbors. CR's existing `press_for_war` remains working via a planned upstream delegation hook or explicit nonconflicting ownership decision.

**Stage 3 — one exact peace transaction.** CR-mediated **white peace** → Bellum Parley → councils → commit → CR outcome. No territory/tribute until this survives full audit, save/load and live logs.

**Stage 4 — structured treaty terms.** Legal fiefs/prisoners/hostages/tribute/reparations + counteroffers, stale revision and exact economic constraints. Only one independently proven term family per iteration.

**Stage 5 — bounded AI-to-AI agency and diplomacy.** If sanctioned CR persona-request + reply mechanism exists, add one sovereign-to-sovereign offer type, formal delivery, rate limits, rival motives and political context; expand to alliances/trade, ultimatums, demands after parity evidence.

**Stage 6 — optional broader simulation.** Propaganda, mediators, guarantees, third-party pressure, reputation, intergenerational treaties, deliberate misinformation **as claims**; only if earlier gates pass and performance/controlled-chaos quality improves.

For **every** stage: Analysis → ROOT CAUSE / TOUCH / DO NOT TOUCH / MUST FIX / MUST NOT CHANGE → positive + neighbor tests → minimal diff → full diff audit → targeted regression → build → **live game/log evidence** → next stage. No GitHub Actions spam; no merge/release on compile alone.

## 10. Immediate next research tasks / unanswered questions

- Verify **game version overlap**. CR 2.8.9 is on 1.5.7; will our customized Bellum 1.4.11.1 load and behave there, especially War Sails decision APIs?
- Source and test every CR native war/peace mutation against Bellum's active Harmony interception and WarPeaceRevamp; establish whether Bellum already captures CR's direct `MakePeaceAction` or only reacts after-the-fact.
- Enumerate native `BellumIntegration` public *foreign* treaty capabilities and internal callers; add an API only after designing exact transaction semantics.
- Inventory every CR use of `DeclareWarDecision`, `MakePeaceKingdomDecision`, `MakePeaceAction.Apply`, `DeclareWarAction.ApplyByDefault`, scripted consequences and council finalization. Current examples are not an exhaustive caller inventory.
- Check actual `EnableLordStrategy` setting, war council default, per-role model routing, and source-backed world event dedup under live 2.8.9.
- Request LogRaam's preferred approach for **non-Harmony, backward-compatible interception/delegation** of built-in CR war/peace effects; distinguish (a) built-in verb override, (b) scenario rule effects, (c) deterministic strategy scheduler, (d) LLM NPC-to-NPC turn.
- Determine who owns **non-war alliance/trade agreements**, before implementing generic `sign_treaty`.
- Capture before/after save evidence for one mundane vanilla war/peace and one Bellum term-rich treaty; retain original political state and logs.

## 11. Explicit change boundary of THIS doc-only commit

**ROOT CAUSE:** architecture not yet safely mapped; CR can reach raw war/peace APIs while Bellum owns a richer treaty transaction. This is a source-backed collision of *execution paths*, not yet a proven live bug.

**TOUCH:** this new Markdown specification **only**.

**DO NOT TOUCH:** native Bellum gameplay code, CR source/DLL, old Bellum Bridge, Relay Bridge, Relay provider routing, AI Influence, game files/saves.

**MUST FIX (in planning):** inventory real capabilities and identify authoritative diplomatic owner, safe API gaps, exact regression requirements before any patch.

**MUST NOT CHANGE:** any existing gameplay behavior, default settings, treaty/legal semantics, public API promises, save formats, or module dependencies in this documentation stage.

**Verification:** diff must contain only this new file. No build/game tests were executed for a documentation-only stage; **no functional fix is claimed**.

---

### Direct source anchors
- CR: [`PressForWarVerb.cs`](https://github.com/LogRaam/calradia-remembers/blob/c49c01c7f00d674768c1824512d8cf683e3b2db0/CalradiaRemembers/Verbs/PressForWarVerb.cs), [`LordStrategyBehavior.cs`](https://github.com/LogRaam/calradia-remembers/blob/c49c01c7f00d674768c1824512d8cf683e3b2db0/CalradiaRemembers/Strategy/LordStrategyBehavior.cs), [`WarCouncilOfferBehavior.cs`](https://github.com/LogRaam/calradia-remembers/blob/c49c01c7f00d674768c1824512d8cf683e3b2db0/CalradiaRemembers/WarCouncil/WarCouncilOfferBehavior.cs), [`PeaceMediationPolicy.cs`](https://github.com/LogRaam/calradia-remembers/blob/c49c01c7f00d674768c1824512d8cf683e3b2db0/CalradiaRemembers.Logic/PeaceMediationPolicy.cs), [`CouncilLift.cs`](https://github.com/LogRaam/calradia-remembers/blob/c49c01c7f00d674768c1824512d8cf683e3b2db0/CalradiaRemembers/Chat/CouncilLift.cs), [`ScenarioConsequenceExecutor.cs`](https://github.com/LogRaam/calradia-remembers/blob/c49c01c7f00d674768c1824512d8cf683e3b2db0/CalradiaRemembers/Scenarios/ScenarioConsequenceExecutor.cs), [`CrActions.cs`](https://github.com/LogRaam/calradia-remembers/blob/c49c01c7f00d674768c1824512d8cf683e3b2db0/CalradiaRemembers/Extension/CrActions.cs), [`CrAims.cs`](https://github.com/LogRaam/calradia-remembers/blob/c49c01c7f00d674768c1824512d8cf683e3b2db0/CalradiaRemembers/Extension/CrAims.cs), [`CrLetters.cs`](https://github.com/LogRaam/calradia-remembers/blob/c49c01c7f00d674768c1824512d8cf683e3b2db0/CalradiaRemembers/Extension/CrLetters.cs).
- Native Bellum: [`ForeignTreatyBehavior.cs`](https://github.com/AIRebelRelay/BellumCivile/blob/59b2aee8268cf1633e052e6b44e1cdba0e3c15fb/Behaviors/ForeignTreatyBehavior.cs), [`WarPeaceRevampBehavior.cs`](https://github.com/AIRebelRelay/BellumCivile/blob/59b2aee8268cf1633e052e6b44e1cdba0e3c15fb/Behaviors/WarPeaceRevampBehavior.cs), [`BellumIntegration.cs`](https://github.com/AIRebelRelay/BellumCivile/blob/59b2aee8268cf1633e052e6b44e1cdba0e3c15fb/BellumIntegration.cs), [`BellumIntegrationNpcCouncil.cs`](https://github.com/AIRebelRelay/BellumCivile/blob/59b2aee8268cf1633e052e6b44e1cdba0e3c15fb/BellumIntegrationNpcCouncil.cs), [README `War and Peace](https://github.com/AIRebelRelay/BellumCivile/blob/59b2aee8268cf1633e052e6b44e1cdba0e3c15fb/README.md).


## 12. Stage 0B source call-chain audit — 2026-11-14 (NO production edits)

**Scope:** First regression-first inspection of CR 2.8.9 → TaleWorlds → customized Native Bellum 1.4.11.1 plus the current upstream Vonbalt 1.5.7 branch. The earlier ownership map remains a design proposal; this section supersedes vague claims about *actual* direct-peace behavior. **No gameplay execution, ABI compilation, binary parity or live logs yet.**

### 12.1 Runtime target and repo baseline

- Author statement (Discord, 2026-11-14): **Bellum 1.4.12b** is the **specific** final beta build for **Bannerlord 1.5.7**; ordinary **1.4.12** can crash at startup if mistaken for the beta; future Bellum releases will target 1.5.x. This is author's compatibility statement **for the upstream beta**, not a validation of our customized DLL or of CR+Bellum running together.
- CR upstream main [`c49c01c7`](https://github.com/LogRaam/calradia-remembers/commit/c49c01c7f00d674768c1824512d8cf683e3b2db0): author identifies 1.5.7 + War Sails 1.3.7 as tested, 1.4.x untested.
- Upstream Bellum [`8a08e0c0`](https://github.com/Vonbalt/BellumCivile/commit/8a08e0c038a60030813c56eae39a5fbee0b75cb6) (`main`, “Prepare main for Bannerlord 1.5.7”); customized Native Bellum [`59b2aee8`](https://github.com/AIRebelRelay/BellumCivile/commit/59b2aee8268cf1633e052e6b44e1cdba0e3c15fb) (`main`, 1.4.11.1). **Neither source HEAD alone proves which source snapshot exactly built 1.4.12b distributed DLL.** Demand binary/source fingerprint before porting.
- Old Bellum Bridge [`f362a4f7`](https://github.com/AIRebelRelay/Bannerlord2-AiInfluence-BellumCivile/commit/f362a4f70786896b4160489bc1e3f448fdd0578e) has a literal `<DependedModule Id="AIInfluence"/>`; it is **not** CR-ready and must **not** be shipped unchanged in a CR-only launcher.
- **Important source-delta finding:** upstream 1.5.7 source has extra foreign parley guards for [`AlliancePeaceRestriction`](https://github.com/Vonbalt/BellumCivile/blob/8a08e0c038a60030813c56eae39a5fbee0b75cb6/AlliancePeaceRestriction.cs) and newer revisions of `ForeignTreatyBehavior` / `PeaceParleyEntryPointPatches`; our custom Bellum does not. The upstream `CivilWarMakePeacePatch` and `WarDeclarationCouncilPatches` were **text-identical** to our main during this targeted check.
- Upstream also contains `VoluntaryPactProposalBehavior`, `VoluntaryPactAiBehavior`, `VoluntaryPactDecision` and durable staged proposals for **peacetime hostage pacts** (two realm votes, target selection, delivery/recovery). Our 1.4.11.1 does not include these. **Which portion shipped in the exact 1.4.12b beta is unverified; upstream main contains ongoing work.** Do not write a second peacetime-pact system before finishing this audit.
- Our custom `BellumIntegration.cs` has additional public Court and provenance methods, and `BellumIntegrationNpcCouncil.cs` has no upstream counterpart at current main. **Do not overwrite our fork with upstream**; map forward changes separately with save/API/feature parity.

### 12.2 CR direct PEACE — confirmed source-level false-success risk (P0)

**Call path A (LLM mediated peace):**

`CR 1:1 prose/interpreter → BannerlordGameStateBridge.Execute(action) → ExecuteMediatePeace → PeaceMediationPolicy.Evaluate (rank / regard / faction) → MakePeaceAction.Apply(leaderFaction,target) → immediately displays successful peace and returns ActionOutcome(success=true)`.

Source: [`ExecuteMediatePeace`](https://github.com/LogRaam/calradia-remembers/blob/c49c01c7f00d674768c1824512d8cf683e3b2db0/CalradiaRemembers/GameState/BannerlordGameStateBridge.cs#L3024-L3100), [`PeaceMediationPolicy`](https://github.com/LogRaam/calradia-remembers/blob/c49c01c7f00d674768c1824512d8cf683e3b2db0/CalradiaRemembers.Logic/PeaceMediationPolicy.cs).

**Bellum intercept:** [`CivilWarMakePeacePatch.ShouldAllowPeaceCall`](https://github.com/AIRebelRelay/BellumCivile/blob/59b2aee8268cf1633e052e6b44e1cdba0e3c15fb/Patches/CivilWarMakePeacePatch.cs#L19-L100) is a Harmony prefix on `MakePeaceAction.Apply`. If this is **ordinary permanent foreign kingdom-vs-kingdom peace**, Revamp **ON**, and `BellumPeaceResolutionContext.IsBellumPeaceResolution == false`, it logs `Blocked non-Bellum international peace` and returns **false** (blocks the original). CR's post-call success text does not re-read war state, so it can claim a peace that never happened. **This is a source-level bug candidate with a deterministic causal chain; actual game manifestation and Harmony ordering remain to be verified.**

**Bellum's legitimate path:** [`ForeignTreatyBehavior.ApplyTreatyCore`](https://github.com/AIRebelRelay/BellumCivile/blob/59b2aee8268cf1633e052e6b44e1cdba0e3c15fb/Behaviors/ForeignTreatyBehavior.cs#L1864-L1935) applies terms and calls `BellumPeaceResolutionContext.RunBellumPeaceResolution(() => MakePeaceAction.Apply...)`, then marks the **native proposal** `Applied`. **Do not expose or invoke `RunBellumPeaceResolution` as a bypass API from an external integration**; it is a narrow Bellum commit guard, not proof of validated agreement.

**Other CR direct peace consumers (different semantics):**

1. [`CouncilLift.SettleMakePeace`](https://github.com/LogRaam/calradia-remembers/blob/c49c01c7f00d674768c1824512d8cf683e3b2db0/CalradiaRemembers/Chat/CouncilLift.cs#L2437-L2502) → `MakePeaceAction.Apply` → `ledger.MarkApplied` **without post-action verification**. Ordinary permanent foreign peace can be vetoed by Bellum but CR marks the council's pledge applied.
2. [`ScenarioConsequenceExecutor.MakePeace`](https://github.com/LogRaam/calradia-remembers/blob/c49c01c7f00d674768c1824512d8cf683e3b2db0/CalradiaRemembers/Scenarios/ScenarioConsequenceExecutor.cs#L160-L171) → `MakePeaceAction.Apply` → logs `[SCENARIO] MAKE_PEACE` without final-state readback. Authored scripted outcome needs separate authority policy, not an implied treaty acceptance.
3. [`ArrestBehavior.LiftBounty`](https://github.com/LogRaam/calradia-remembers/blob/c49c01c7f00d674768c1824512d8cf683e3b2db0/CalradiaRemembers/Arrests/ArrestBehavior.cs#L550-L564) can also call `MakePeaceAction.Apply` for the player's **independent clan** vs the bounty realm. **Do not blanket-disable it**: Bellum's ordinary-permanent-kingdom guard explicitly distinguishes this case.
4. A `MakePeaceAction.ApplyByKingdomDecision` has its own [`CivilWarMakePeaceByDecisionPatch`](https://github.com/AIRebelRelay/BellumCivile/blob/59b2aee8268cf1633e052e6b44e1cdba0e3c15fb/Patches/CivilWarMakePeacePatch.cs#L133-L161). Both overloads must be included in the seam contract.

**Important exclusions:** Civil-war, feud, client kingdom, StoryMode quest-protected and temporary kingdom transitions have separate Bellum ownership; do not solve the ordinary-foreign case by changing any shared `MakePeaceAction` semantics.

### 12.3 CR direct WAR / kingdom decisions (P0/P1)

| CR source | Real call chain | Bellum interception / risk |
|---|---|---|
| [`PressForWarBehavior.Daily`](https://github.com/LogRaam/calradia-remembers/blob/c49c01c7f00d674768c1824512d8cf683e3b2db0/CalradiaRemembers/Verbs/PressForWarVerb.cs#L275-L324) | Eligible lord's delayed pressing → recheck → `new DeclareWarDecision(house,target)` → `Kingdom.AddDecision` | **Promising candidate for reuse**: Bellum `WarDeclarationCouncilPatches` govern voting, influencer cost, ruler override; CR does NOT unilaterally declare. Check Bellum readiness, proposer, extra front, duplicate proposal and client guard in live game. |
| [`LordStrategyBehavior.Weekly`](https://github.com/LogRaam/calradia-remembers/blob/c49c01c7f00d674768c1824512d8cf683e3b2db0/CalradiaRemembers/Strategy/LordStrategyBehavior.cs#L150-L335) | Deterministic counterweight → `DeclareWarDecision` / `MakePeaceKingdomDecision` / `StartAllianceDecision` / `ProposeCallToWarAgreementDecision` → `Kingdom.AddDecision` | War uses Bellum voting path; **peace is high risk**: Bellum `Kingdom.AddDecision` parley redirection is **player-kingdom scoped** and cannot be assumed for unrelated NPC↔NPC realm pairs. A normal NPC peace vote may reach `ApplyByKingdomDecision` and be blocked by Bellum, yet CR emits news describing only the proposed step. Verify exact game call path before claim. Preserve player-realm skip. |
| [`CouncilLift.SettleDeclareWar`](https://github.com/LogRaam/calradia-remembers/blob/c49c01c7f00d674768c1824512d8cf683e3b2db0/CalradiaRemembers/Chat/CouncilLift.cs#L2361-L2420) | Player-led council → `DeclareWarAction.ApplyByDefault` → immediately `ledger.MarkApplied` | Bypasses a new `DeclareWarDecision` and thus Bellum War Will/council consideration; client `ApplyInternal` veto may still block. Needs delegated proposal OR explicit sovereign exception contract, not a global override. |
| [`ScenarioConsequenceExecutor`](https://github.com/LogRaam/calradia-remembers/blob/c49c01c7f00d674768c1824512d8cf683e3b2db0/CalradiaRemembers/Scenarios/ScenarioConsequenceExecutor.cs#L117-L171) | `PRESS_FOR_WAR` may call direct `DeclareWarAction.ApplyByDefault` after pure ruler test; `DECLARE_WAR` directly calls war action. | May bypass Bellum's full foreign-war proposer/War Will path; distinguish intentional scripted scenario from an LLM request. No automatic global blocking of authored story consequences. |
| [`GiveHerAllService`](https://github.com/LogRaam/calradia-remembers/blob/c49c01c7f00d674768c1824512d8cf683e3b2db0/CalradiaRemembers/Marriage/GiveHerAllService.cs#L180-L191) | Marriage outcome rolls into `DeclareWarAction.ApplyByDefault(rival,herRealm)` for same-culture rival kingdoms. | Adjacent systemic scripted war, distinct from diplomacy conversations. Needs separate regression test; should not be accidentally disabled. |

Bellum's generic hooks are **not a complete new-verb arbitration API**: [`WarDeclarationCouncilPatches`](https://github.com/AIRebelRelay/BellumCivile/blob/59b2aee8268cf1633e052e6b44e1cdba0e3c15fb/Patches/WarDeclarationCouncilPatches.cs) apply to **`DeclareWarDecision`** votes; [`BlockVanillaForeignPolicyProposalsPatch`](https://github.com/AIRebelRelay/BellumCivile/blob/59b2aee8268cf1633e052e6b44e1cdba0e3c15fb/Patches/BlockVanillaForeignPolicyProposalsPatch.cs) replaces **random AI proposal factory** decisions; [`ClientKingdomDeclareWarPatch`](https://github.com/AIRebelRelay/BellumCivile/blob/59b2aee8268cf1633e052e6b44e1cdba0e3c15fb/Patches/ClientKingdomDiplomacyPatches.cs) only adds a client-vassal legality gate to the direct war action. Direct-war decisions **can** start without going through `KingdomDecision` voting; check actual game/quest rules before designing a global veto.

### 12.4 Baseline regression contract (test before a single executable patch)

**Test cases and expected evidence (hypotheses until run):**

| Case | Expected owner/behavior | Required logs and game state |
|---|---|---|
| Bellum Revamp **ON**, ordinary two permanent kingdoms, CR `mediate_peace` | Bellum vetoes raw `Apply`; **no peace**, while CR may falsely narrate success (reproduce before fix) | Bellum `Blocked non-Bellum international peace`; CR `[ACTION] mediate_peace`; war state still active. After integration CR must say **pending/denied** and Bellum own exact transaction. |
| CR council `make_peace` under same setup | No raw peace; CR current `MarkApplied` is suspect | `[COUNCIL] lift: parley made peace` without world-state peace is **unexpected**. |
| CR scripted `MAKE_PEACE` under same setup | Should not fabricate completed peace; authored scenarios require tailored contract | `[SCENARIO] MAKE_PEACE` + actual war remains: unexpected successful outcome claim. |
| Bellum native foreign treaty signed through legal `ApplyTreatyCore` | War ends exactly once; terms (fiefs/money/hostages/tribute) applied once | `Foreign treaty applied; war=... proposal... status=Applied` (check actual log format), exact proposal/war/terms before/after |
| Revamp **OFF** ordinary peace | Existing vanilla path preserved | No Bellum foreign veto, vanilla peace works when legal |
| CR independent-clan bounty cancellation | Existing criminal-law cleanup preserved | `[ARREST] ... bounty lifted`, correct criminal war state; **not** blocked merely by kingdom-vs-kingdom fence |
| CR `press_for_war` delayed | **One** `DeclareWarDecision`, Bellum support/votes/mandate decide | `[WARPRESS] ... proposes war`; any war start only after proper resolved decision; no illegal additional front |
| CR `LordStrategy` NPC war/peace/alliance | CR files at most one step, Bellum owns foreign results | `[STRATEGY]` must be **proposal** news; if NPC `MakePeaceKingdomDecision` is vetoed, no false actual peace; no duplicate treaty |
| CR war council/Scenario direct war | Only declared when **authoritatively permitted**; protect scripted routes | Actual war state equals announcement, Bellum client and quest rules respected |
| Civil war, feuds, secession, clientage, StoryMode protected war, call-to-arms, save/load | Existing distinct ownership and special guards unchanged | No ghost realm, double vote, erased treaty, double term, missing spouse/hostage or overwritten war score |

**No live game access in this stage.** Test matrix above is an **execution contract**, not a report of passing tests.

### 12.5 Upstream 1.4.12b migration: safety boundary

**DO NOT import current upstream main wholesale.** Target upstream 1.5.7 sources/binary fingerprint at **the exact shipped 1.4.12b**, then:
1. Compare full source tree to our 1.4.11.1 (not just version label): recent upstream `AlliancePeaceRestriction`, `ForeignTreatyBehavior`, `PeaceParleyEntryPointPatches`, new voluntary-pact and hostage save schema, dependency/ABI/War Sails diffs, and our unique `BellumIntegration*`/NPC Court APIs.
2. Keep 1.4.11.1's custom public APIs, vote/crown safety and save invariants explicitly. Record new-vs-local overlapping call sites and tests **before** any port. Source HEAD and release DLL may not be identical.
3. Once pinned, prepare **separate** 1.5.7 compatibility stage; build against the actual 1.5.7 TaleWorlds assemblies, not old stubs; exercise CR-only, upstream Bellum beta-only, **custom** Bellum-only, CR+custom Bellum in a **separate backup/test campaign**.
4. Do not launch old `AIInfluenceBellumBridge2` in the CR-only profile; it requires `AIInfluence`. No Relay Bridge or AI Influence code touched to work around this.

**Runtime smoke gates:** startup, game load/save/reload, 2 in-game weeks, one ordinary war vote, one Bellum AI peace parley, one player parley with treaty terms, one internal civil conflict (not combined with foreign war test), one CR 1:1 dialogue/letter/council, no duplicate political event, no `HarmonyException`/`MissingMethodException`/`TypeLoadException`/`SerializationException`. Startup success is **not** proof these pass.

### 12.6 API requests — updated priority / avoid premature broad intervention

**To LogRaam — P0 single priority:**
A narrowly scoped, backward-compatible **pre-commit diplomatic delegation** (e.g. `TryHandleDiplomaticEffect(context)`) for an external mod to return `PassThrough | Rejected(reason) | Pending(txnId) | Applied(receipt)` **before** CR's `mediate_peace` would call `MakePeaceAction.Apply`. CR must show "pending" on a merely queued treaty and not announce verified peace without a Bellum result. An action override cannot be registered using the current `CrActions.Register` because the builtin verb name is reserved by duplicate-registration checking. Discuss analogous safe hooks for CouncilLift and scenarios **after** identifying shared call sites and authored-script compatibility; do not change shared CR action semantics without author regression tests.

**To our Native Bellum — P0 minimum counterpart:**
A public **actor-scoped, thread-safe and idempotent** `TryStartNegotiation` / `GetDiplomaticTransaction` **on the existing ForeignTreatyBehavior owner**, returning a typed `Pending/Rejected/Applied` receipt and exact `WarKey+ProposalId+DraftRevision+TermsFingerprint`; it must delegate validation and ratification to Bellum and **never** simply set `BellumPeaceResolutionContext`. The current `ForeignTreatyBehavior.TryQueueAiParley` is real and useful, but takes a native `WarScoreRecord` and is **not** a documented stable NPC-specific CR adapter contract.

**To LogRaam — later P1:**
A sanctioned NPC↔NPC persona-turn/offer-reply API with provenance, recipient authority, budget, rate limiting and cancellation. Use CR memory/letters where supported; today's external `CrLetters` delivery is player-targeted. Do not request this until reliable one-off mediation is proven.

### 12.7 Stage acceptance + precise edit boundary

**ROOT CAUSE (source-backed):** CR's built-in diplomatic post-action success/ledger writers assume raw TaleWorlds `MakePeaceAction.Apply` commits, whereas Bellum's foreign-peace prefix can suppress the call unless it owns an active treaty commit. Distinct direct war actions bypass ordinary vote construction. This is an **ownership and acknowledgement contract mismatch**, not a reason to remove Bellum's protections.

**TOUCH NOW:** only this Markdown design/audit document on `docs/cr289-llm-diplomacy-architecture-2026-11-14`.

**DO NOT TOUCH:** upstream CR/LLM-service, Native Bellum `*.cs`, both bridges, Relay, AI Influence, live game and save files. Do not trigger CI for a docs-only stage.

**MUST FIX IN DESIGN:** exact traced call paths and neighboring consumers; upstream 1.5.7 vs local 1.4.11.1 delta and correct 1.4.12b release identity; minimum sanctioned API; positive and negative test contract.

**MUST NOT CHANGE:** vanilla fallback on Revamp OFF, Bellum treaty gate/ratification/War Score, independent criminal-law peace, authored scripts, KingdomDecision votes, clientage, story protections, internal/civil war, save formats, NPC memory, active model routing.

**Evidence standard:** source inspection passed for named paths above; **no actual executable bugfix is claimed**, no compile or gameplay tests run. Before gameplay changes, finish full caller inventory of shared Battle/Peace APIs (including other modules and 1.5.7 TaleWorlds overloads) and identify precise patch touch boundary on up-to-date target HEAD. Only then proceed with one narrow implementation stage.


## 13. Stage 1A migration inventory — 2026-11-14 (NO-GO production patch yet)

**Purpose:** Prepare a regression-safe port of our customized **Native Bellum** 1.4.11.1 to **Bannerlord 1.5.7** without replacing our APIs or mistaking author main for the exact 1.4.12b binary. This stage is documentation-only. It does **not** migrate code, establish combined runtime compatibility or create a release.

### 13.1 Immutable baselines and provenance

- Native target: `AIRebelRelay/BellumCivile` `main` @ `59b2aee8268cf1633e052e6b44e1cdba0e3c15fb` (custom 1.4.11.1, manifest `_Module/SubModule.xml` = `v1.4.11.1`).
- Upstream candidate: `Vonbalt/BellumCivile` `main` @ `8a08e0c038a60030813c56eae39a5fbee0b75cb6` ("Prepare main for Bannerlord 1.5.7", 2026-11-11). Its manifest still says `v1.4.12`.
- Author's Discord (2026-11-14): use the **specific 1.4.12b beta** for 1.5.7; ordinary 1.4.12 crashes during startup on 1.5.7. Nexus mod page lists ordinary 1.4.12 as its headline version.
- **BLOCKER P0:** the public upstream GitHub repository returned **zero GitHub Releases** and no available immutable tag mapping `1.4.12b → source SHA → DLL/hash`. `main` is **not sufficient proof** that a source file was in the shipped 1.4.12b binary. This is a release-provenance gap, not a code failure.
- CR 2.8.9 independently supports 1.5.7, but CR+our customized Bellum **has not** been booted or tested together.
- Git inspection: 2026-11-14; compares full recursive Git trees at the two pinned SHAs, not a cherry-picked file list. Upstream tree **1,299 files**, our tree **1,272 files**; **926 blob-identical**, **225 same-path different**, **148 upstream-only**, **121 local-only**. Includes docs/tests/assets; counts are **not** all gameplay diffs.
- C# subclass: **191 shared `.cs` paths differ**, **131 upstream-only `.cs`** (includes tests), **24 local-only `.cs`** (includes tests). This is much larger than a surgical file replacement. Do **not** merge upstream master wholesale.

### 13.2 Exact safety landmarks

| Boundary | Evidence | Port rule |
|---|---|---|
| **Save schema** | `BellumCivileSaveDefiner.cs`: our 137 registered class/enum definitions, upstream **149**; all existing registered names and numeric IDs are unchanged in this direct textual comparison; new IDs **138–149** | Preserve every existing ID, serializer/container, and local save owner; test load/save/reload before approving any adoption |
| **New upstream persisted types** | `PersonalLordshipRecord` 138; `LordshipAppointmentRecord` 139; `LordshipIncomeCredit` 140; `TitleAcquiredMapNotification` 141; `AsylumVisitRecord` 142; `LordshipCommandTransferRecord` 143; `RetainerIndentureRecord` 144; `CourtTermPreparationRecord` 145; `VoluntaryPactProposalRecord` 146; `VoluntaryPactProposalPhase` 147; `VoluntaryPactDecision` 148; `VoluntaryPactDecision.PactOutcome` 149 | These names/IDs are not permission to add them piecemeal; audit writer/reader behaviors, `SyncData` and lifecycle first |
| **Our unique integration APIs** | `BellumIntegrationNpcCouncil.cs`, `BellumIntegrationNpcCrown.cs`, `Behaviors/CourtNpc*`, `Behaviors/CourtPolicyVote*`, `Behaviors/CourtTerminalEvictionReceipts.cs`, `BellumNativeLeaveProvenance.cs`, `HostagePactReadOnlySnapshot.cs` | Must stay intact; identify all consumers incl. old Bridge, no downgrade to older upstream |
| **Author's new foreign diplomacy** | `AlliancePeaceRestriction.cs`; upstream changes in `Patches/PeaceParleyEntryPointPatches.cs` and `Behaviors/ForeignTreatyBehavior.cs`; peacetime hostage pacts via `VoluntaryPactProposalBehavior` + `VoluntaryPactAiBehavior` | Audit exact source snapshot, call-to-arms restrictions, budget/court rules, save schema and rollback together. No port from `main` until 1.4.12b provenance is pinned |
| **Some unchanged high-risk gates** | `Patches/CivilWarMakePeacePatch.cs` and `Patches/WarDeclarationCouncilPatches.cs` were blob-text equivalent across the pinned SHAs | **Leave untouched** unless actual 1.5.7 ABI/behavioral test proves a mismatch |
| **Our local release build gate** | `scripts/Verify-Bellum148Build.ps1` checks canonical game manifests and **requires exactly 1.4.8** at lines 138–145; `Tests/P014FGameVersionManifest.Tests.ps1` asserts 1.4.8 | Do **not** weaken the existing 1.4.8 gate. Later add a separate, fail-closed **1.5.7** build/preflight with analogous positive/negative fixture tests and distinct build identity |
| **Upstream ABI evidence** | New `Tests/SuccessionEngineHarness/GameVersionCompatibilityTests.cs` probes 1.5.7 reflected members, party-size signature, naval class loading and campaign UI/runtime members | Treat as reference for ABI verification against actual game/DLC DLLs; not proof our customized source compiles |
| **Reference policy** | Our csprojs have explicit Harmony/UIExtenderEx Workshop path handling; upstream uses direct module paths and adds more references; `Directory.Build.props` upstream has resolver safeguards | Preserve local fallback/override behavior and MCM path protections, add only proven 1.5.7 build requirements |

**Main integration hazard carried over from Stage 0B:** CR ``mediate_peace`/`CouncilLift`/`ScenarioConsequenceExecutor` can claim success after direct `MakePeaceAction.Apply`, even when Bellum's ordinary foreign peace guard suppresses execution. This is **separate** from the 1.5.7 source-port task. Do not try to solve it by disabling Bellum's shared prefix.

### 13.3 Proposed next surgical implementation boundary (PENDING prerequisites)

**ROOT CAUSE:** The current local 1.4.11.1 distribution/build gate is pinned to Bannerlord **1.4.8**, and its compiled compatibility with 1.5.7 has not been demonstrated. The upstream 1.4.12b beta release-source identity is unpinned; the latest upstream `main` contains a significant, ongoing feature delta.

**TOUCH — only after source and game DLL baseline verified:** a **new** 1.5.7-specific build/preflight script + corresponding narrowly scoped tests, then only exact native source files shown to fail at the 1.5.7 ABI contract. Never touch gameplay before the failure is demonstrated. Separate each independent source fix.

**DO NOT TOUCH:** older 1.4.8 build script/tests, `BellumIntegration*` public contract, extra local NPC Council/Crown APIs, save IDs, external war/peace semantics, Bellum Bridge, Relay Bridge, Relay, AI Influence, CR source, native `main`, campaign saves.

**MUST FIX:** exact beta provenance, isolated 1.5.7 build with canonical version verification and correct real game DLL references, retaining our local features. **MUST NOT CHANGE:** 1.4.8 shipping behavior, all AII historical compatibility safeguards that remain relevant for current saves, native War Score/treaty owner, CR's own independently working paths.

**Required positive and negative regression tests before code:** valid four base manifests 1.5.7 → pass; mixed 1.5.7/1.4.8, absent/invalid manifest, random DLL, wrong path, absent Harmony/UIExtenderEx/MCM → **fail closed**; override precedence/Workshop path unchanged; naval DLC optional (if enabled, explicit DLL ABI check); new source still has each existing `BellumIntegration` symbol and all old save IDs. Include no duplicate `MakePeaceAction`, no double elections, no lost NPC court receipt and no expensive CI on every exploratory commit.

**Evidence gates:** local 1.5.7 Windows build against true `TaleWorlds.*`, naval companion build where applicable, relevant targeted harnesses, full diff audit, live startup + fresh campaign + backup save/load + Bellum peace treaty + CR council/mediation + 2 game weeks. Check `HarmonyException`, `MissingMethodException`, `TypeLoadException`, `SerializationException`, `Blocked non-Bellum international peace` and actual war/treaty state. **Do not claim pass until observed.**

### 13.4 Unresolved prerequisites

1. Identify exact shipped upstream `1.4.12b` DLL/source fingerprint or ask Vonbalt for its commit SHA; exclude later `main` work unless explicitly planned.
2. Obtain installed Bannerlord **1.5.7** / War Sails 1.3.7 assemblies and original beta DLL; do an initial ABI/manifest comparison before compiling our fork. Do not infer from an author screenshot that the customized fork loads.
3. Preserve and compare the upstream ``BellumCivileSaveDefiner` + all writer behaviors` against our custom owner/IDs, not only the registry.
4. Only then define **one** concrete failing source method for a surgical fix. Until those gates, **NO-GO production changes**; doc-only stage passes without claiming build/game validation.

**Git diff contract for Stage 1A:** exactly this design document updated in the separate docs branch, no `*.cs` or shipping asset modifications, no CI, no merge/release.


## 14. Stage 1B — Beta provenance and AII→CR API triage (2026-11-14, docs-only)

**Stage decision: NO-GO production port, NOT a failed build.** This stage examines one blocker (what exact 1.4.12b source was shipped) and one newly clarified requirement (our public Native APIs were originally built for AI Influence). No executable files, launcher config, save schema, or deployed binaries changed.

### 14.1 Release provenance: narrow evidence vs speculation

| Source | Confirmed | Not confirmed |
|---|---|---|
| Author Vonbalt, Discord screenshot supplied 2026-11-14 | Bellum **1.4.12b** is the last special **Bannerlord 1.5.7** beta; ordinary 1.4.12 will crash at startup in 1.5.7; future Bellum updates focus 1.5.x | Exact source commit, release binary hash, whether all current main features are in the beta |
| GitHub commit [`b9def48e9d12`](https://github.com/Vonbalt/BellumCivile/commit/b9def48e9d12b6989bfa7050087261265b8db75e) (2026-11-10 23:40Z) | "updated beta build to 1.5.7" changes **CouncilAssignmentRuntimePatches.cs** from two-argument party-size call to 3-argument `GetPartyMemberSizeLimit(PartyBase,bool,bool)`, adds `MobileParty.IsCurrentlyAtSea` argument and matching compatibility tests; README target changes to 1.5.7 | Not proven to be **the exact 1.4.12b release commit**; it is a dated ABI migration anchor |
| GitHub [`75d8f773ac56`](https://github.com/Vonbalt/BellumCivile/commit/75d8f773ac56148452e41372b30b808ad54e2590) (2026-11-11 02:40Z) | Module manifest changes from `v1.4.11` to `v1.4.12`; this is **not** `1.4.12b` as a unique identity | Cannot identify beta using module's numeric version alone |
| GitHub [`e738eff996ba`](https://github.com/Vonbalt/BellumCivile/commit/e738eff996baa84ed8deceb4ff6d0810f2e18eb4) (2026-11-11 22:44Z) | Later merge `bug-fixes` into `1.5-beta`; includes **voluntary hostage pacts** and added SaveDefiner IDs | Cannot infer that this later feature merge was included in the downloaded beta |
| GitHub [`8a08e0c038a6`](https://github.com/Vonbalt/BellumCivile/commit/8a08e0c038a60030813c56eae39a5fbee0b75cb6) (2026-11-11 23:37Z) | Current upstream `main` at audit, titled “Prepare main for Bannerlord 1.5.7” | **Not** a release fingerprint or guaranteed exact source of 1.4.12b |
| Public Nexus [Bellum Civile](https://www.nexusmods.com/mountandblade2bannerlord/mods/10609?tab=files), upstream repository | Headline Nexus version 1.4.12; GitHub Releases API returned empty; no verified immutable `1.4.12b` tag/hash found | Nexus page/search snippets and a third-party mod's 1.4.12b support mention are **not** a cryptographic binary↔source mapping |
| User's accessible Google Drive search, 2026-11-14 | No file named 1.4.12b was found in search; an earlier Bellum source folder exists | This does **not** mean the beta binary does not exist on Nexus or elsewhere |

**Do not cherry-pick `b9def48` on its own.** The 3-arg party-size ABI change is a real named 1.5.7 migration seam, but its real callers, other patch targets, naval companion, tests, and the exact binary/source relationship must be compared before any integration. The full source is available, the **specific shipped beta source identification** is still missing.

**Exact one-line author request (can be sent on Discord):**

> Could you share the exact commit SHA (or source tag) used to build Bellum Civile 1.4.12b for Bannerlord 1.5.7? Our team is porting a customized Native Bellum 1.4.11.1 with additional integration APIs, and we want to preserve all upstream compatibility fixes without mixing in later unreleased features. If there's no commit tag, the 1.4.12b ZIP/DLL and its build date/hash would also let us fingerprint it. Thanks!

### 14.2 The AII-era API is **not** one indivisible integration

Target runtime changes to **CR 2.8.9 + Native Bellum**, not an adapted AII Bellum Bridge. The existing API members are first-party Bellum behavior surfaces; their original *consumer* (AII Bridge) should not be assumed to remain installed.

| Bucket | Exact Native source | Treatment for CR | Regression boundary |
|---|---|---|---|
| **A — owner-verified read-only facts** | `BellumIntegration.GetCourtAgendas`, `GetPendingVotes`, `GetHostageStatus`, `GetCourtPolicyVoteProvenanceJoin`, `GetCourtPolicyVoteAudienceJoin`, `GetCourtTerminalEvictionInventory`; `GetRecentPartitions`, `PartitionCompleted` | Retain as Native domain API. A CR-specific adapter can consume carefully selected **public/relevant** political facts. Do not leak `CourtTerminalEvictionInventory` or private vote audience as a global news feed. | Existing API shapes, campaign-thread precondition, listener lifecycle and actor visibility must survive. Snapshot != action receipt. |
| **B — Bellum-hosted staged political *intents*** | `BellumIntegrationNpcCouncil.TryStageNpcCouncilAppointmentIntent` / status+options; `BellumIntegrationNpcCrown.TryStageNpcTreasonIntent` / inventory / active announcement | Their types are **not inherently tied to AII's backend**: `externalIntentId` is a caller-provided id, Bellum owns persistence/preflight and eventual court attachment. Later create **new CR action adapters** with strict actor/realm/sponsor/role proof; do **not** reuse AII conversation/request IDs without a namespace/authority contract. | Intention is **staged, not filed**, not voted, not executed. No falsely narrated appointment/expulsion; source-specific logs still say “AIInfluence” and must not be treated as proof of CR ownership. Historical saved ticket records need decoding intact. |
| **C — other generic effectful API** | `BellumIntegrationLegitimacy.MarkIllegitimate`/`Legitimize`, `BellumIntegrationElections.TryBeginElectionPersuasion`/`CompleteElectionPersuasion`, `BellumIntegrationPledges.TryPledge*Vote` | **Retain unchanged** until callers/authority are audited; a generic CR registration must not grant any NPC blanket mutation permission. | Existing player/gamerules, costs, role gating, one-time effects remain. |
| **D — AII-specific foreign war accounting (legacy only)** | `Behaviors/WarScoreAiInfluenceForeignLedger.cs`: `TryRegisterAiInfluenceForeignWar`, `aii_foreign_ledger:v1:` `WarScoreRecord.ContextId`, reconciliation; multiple consumers in `WarScoreBehavior.cs` | **Do not invoke from CR**, do not rename to “CR ledger.” Only valid under Bellum Revamp **OFF** with **AII authoritative event proof** from original Bridge; explicitly accounting-only and Bellum autonomous foreign peace disabled. With Bellum Revamp **ON**, new CR-controlled diplomacy must use Bellum's ordinary foreign-war owner, not a second ledger. | Keep historic `ContextId` decoder, daily reconciliation, save schema and war-score non-auto-settlement for old campaigns. Deleting/renaming would alter persistent behavior and multiple event handlers. |
| **E — AII conditional compatibility code** | `ModIntegrationHelper.IsAIInfluenceDiplomacyActive`, `ExecuteWithAIInfluenceDiplomacyBypass`, `AIInfluence.ModSettings` reflection; `Patches/CivilWarMakePeacePatch.ShouldBlockEarlyAIInfluencePeace` | Leave dormant when AII is absent; do not generalize AII's bypass/rebellion guard to CR. The current reflection property returns false if the AII assembly is unavailable; that is not a CR feature toggle. | Preserve existing 3-day fresh civil-war protection only where AII was actually the diplomacy owner, and keep normal Bellum civil-war paths intact. |
| **F — old AII Bellum Bridge (separate repository)** | `AIRebelRelay/Bannerlord2-AiInfluence-BellumCivile` Bridge `module/SubModule.xml` depends on `AIInfluence`; contains `BridgeV1SourceBackedForeignWar.AiiLedger.cs` and `BellumInternalDialogueContextWriter.cs` consumers | **Not** CR bridge; keep out of new CR-only load order. Extract **requirements** from old bridge, not a drop-in implementation. Relay Bridge is unrelated. | No accidental AII dependency, no old LLM event replay, no duplicate ownership or Harmony. |

**Source proof:** Native `BellumIntegration.cs`, `BellumIntegrationNpcCouncil.cs`, `BellumIntegrationNpcCrown.cs`, `BellumIntegrationVotes.cs`, `BellumIntegrationLegitimacy.cs`, `BellumIntegrationElections.cs`, `BellumIntegrationPledges.cs`, `Behaviors/WarScoreAiInfluenceForeignLedger.cs`, `Behaviors/WarScoreBehavior.cs`, `ModIntegrationHelper.cs`, `Patches/CivilWarMakePeacePatch.cs` at [our pinned main](https://github.com/AIRebelRelay/BellumCivile/tree/59b2aee8268cf1633e052e6b44e1cdba0e3c15fb); original caller evidence in [old Bellum Bridge](https://github.com/AIRebelRelay/Bannerlord2-AiInfluence-BellumCivile/tree/f362a4f70786896b4160489bc1e3f448fdd0578e/src/AIInfluenceBellumBridge2). No claims that all external callers were exhaustively enumerated.

### 14.3 Regression-first boundary / next stage

**ROOT CAUSE:** two independent gaps: (1) unpinned `1.4.12b` binary-to-source provenance; (2) misleading assumption that all old Native APIs should be copied into a CR backend because their initial consumers were AII.

**TOUCH (current):** only this documentation file on its existing isolated documentation branch. **DO NOT TOUCH:** `*.cs`, native `main`, CR/LLM Service, either Bridge, Relay, 1.4.8 build preflight, DLLs or save data.

**MUST FIX:** pin exact 1.4.12b source commit or independently fingerprint shipped DLL, then create **separate** `scripts/Verify-Bellum157Build.ps1` and a 1.5.7-specific positive/negative manifest fixture (path/name provisional) without altering `Verify-Bellum148Build.ps1`. **MUST NOT CHANGE:** 1.4.8 tooling, past AII foreign ledgers' read/reconcile behavior, native political receipts, clan authority, private/public news separation, save type IDs, War/Peace Revamp ownership.

**Build-gate test contract (future, not executed):** four native manifests all 1.5.7 **pass** with true TaleWorlds 1.5.7 DLLs; mixed/unknown/missing versions, missing mandatory references, wrong override or outdated 1.4.x ABI **fail closed**; documented Windows `net472` compile; optional Naval DLC assembly checks; public Bellum API signature retention. Then full diff, targeted regressions and **live** game logs/backup-save validation; never promote on compilation alone.

**First CR integration contract (future):** read-only political feed using CR public `Feed.Record/Update/Retract` with exact sources, distinct public vs private court data and dedup; only after safe combined Bellum+CR runtime gate. Then one authorized intent and an owner-issued outcome receipt. Old AII's direct foreign-war handshake is **not** a substitute.

**Stop condition:** Without 1.4.12b source provenance **and** real Bannerlord 1.5.7 game assemblies, no justified production diff can be defined yet. Don't invent test passes, silently import 1.5.7 main or strip AII-era code to make the project compile.


## 15. Stage 1C — User-supplied Bellum binary fingerprint (2026-11-14, DOC ONLY)

This section **supersedes Stage 1B's previous absence-of-binary blocker**. The user supplied an actual module tree on Google Drive: [BellumCivile folder](https://drive.google.com/drive/u/0/folders/1WcSRIdaIuRdNXMtZe2Qf-L6IFTNSTKI0). The binary is now available for source fingerprinting. **It is not yet proven to be the exact author-labeled 1.4.12b release** by a tag or compile record.

### 15.1 Acquired binary identity (read-only)

| File (Drive) | Size | SHA-256 (verified against downloaded bytes) | Google Drive preserved modified time |
|---|---:|---|---|
| [BellumCivile.dll](https://drive.google.com/file/d/1daVTFUhT_7iFtdeNSAqmmANz1QNyvkmT/view) | 5,434,368 bytes | `096ca56b7eb012018b1e16f0aeb9406748cab18f56bb39ead93b253ae5f6e898` | 2026-11-11 01:12:37 UTC |
| [BellumCivile.NavalDLCPatch.dll](https://drive.google.com/file/d/1zQtcg8LS03fjvxLY7FtselUhQ7KNksq5/view) | 13,312 bytes | `ab6658859944e1eadad6da5a7cec2f537b6fc660135c915bf1cba874e76a2dbb` | 2026-11-11 01:12:37 UTC |
| [SubModule.xml](https://drive.google.com/file/d/1rbSbQntnsDaU4mdgp8EiBDYR6qDoFPXp/view) | 1,403 bytes | Not hashed in this pass | 2026-11-11 01:11:22 UTC |

The exact supplied XML reads `<Id value="BellumCivile"/>`, `<Version value="v1.4.12"/>`; it does **not** identify `1.4.12b` separately. Two PE binaries were recognized as Windows .NET assemblies. The PE header timestamps decode to nonsensical future dates (2075/2086); **do not use PE TimeDateStamp as a compile or release date**, consistent with reproducible/deterministic .NET build patterns. The Google Drive modified timestamps are provenance hints, **not cryptographic compile proof**.

### 15.2 Source consistency checks (not a reconstructed commit)

**Direct bytes inspection** (`strings` against the DLL's metadata/string heaps) shows:

- Present: `get_IsCurrentlyAtSea`, `GetPartyMemberSizeLimit`, `AlliancePeaceRestriction`, `CourtTermPreparationRecord`, `TitleAcquisitionBehavior`, `LordshipBehavior`.
- Absent from binary strings: `VoluntaryPactProposalBehavior`, `VoluntaryPactAiBehavior`, `VoluntaryPactDecision`, `PeacetimeHostagePactRules`.
- Source commit [`b9def48e`](https://github.com/Vonbalt/BellumCivile/commit/b9def48e9d12b6989bfa7050087261265b8db75e) on 2026-11-10 explicitly adapts a party-size code path to **Bannerlord 1.5.7** by passing `party.IsCurrentlyAtSea`. The above binary symbol **fits** this change; its mere presence does not prove the call signature or runtime ABI by itself.
- In upstream Git trees, pre-merge commits [`b9def48e`](https://github.com/Vonbalt/BellumCivile/commit/b9def48e9d12b6989bfa7050087261265b8db75e) and [`75d8f773`](https://github.com/Vonbalt/BellumCivile/commit/75d8f773ac56148452e41372b30b808ad54e2590) include `AlliancePeaceRestriction.cs`, `CourtTermPreparationRecord.cs` and lordship classes, **but do not** contain `Behaviors/VoluntaryPactProposalBehavior.cs` or `Behaviors/VoluntaryPactAiBehavior.cs`. The later [`e738eff9`](https://github.com/Vonbalt/BellumCivile/commit/e738eff996baa84ed8deceb4ff6d0810f2e18eb4) merge and current [`8a08e0c0`](https://github.com/Vonbalt/BellumCivile/commit/8a08e0c038a60030813c56eae39a5fbee0b75cb6) **do** contain those files.
- **Interpretation: supplied binary is consistent with a pre-voluntary-pact 1.5.7 beta code snapshot**, and is not equivalent to the current upstream `main`. This is a source/binary **feature-set match**, not an exact SHA match, a guarantee of 1.5.7 startup or proof that the file is from Nexus' specifically labeled `1.4.12b`.
- Public GitHub still has no observed immutable tag/release linking these DLL checksums to a source commit. Source-built DLL comparison or author's explicit SHA is needed to close exact provenance.

### 15.3 Change boundary / regression contract

**ROOT CAUSE:** Previously only author statements and upstream commits were known; the missing compiled beta binary prevented a binary-level feature/provenance check. The user-supplied DLLs close the **artifact availability** gap, not the **exact commit/ABI validation** gap.

**TOUCH:** this living architecture document only.

**DO NOT TOUCH:** main, production Bellum/CR files, both Bridges, AII legacy save decoders, 1.4.8 build script, active mod folder or saves.

**MUST FIX (evidence):** freeze both hashes, distinguish XML module identity from beta label, map present/absent source features, flag remaining author commit / 1.5.7 ABI and combined runtime verification. **MUST NOT CHANGE:** foreign treaty and WarScore ownership or historic AII ledger handling.

**Positive checks recorded:** raw DLL byte download/size, verified SHA-256, PE/.NET format, manifest XML, exact named binary symbol presence/absence, upstream tree comparisons. **No build, IL semantic validation or live-game test was run.**

**Next single stage (after a documented decision):** introduce a **new, parallel, fail-closed 1.5.7 build-preflight script with isolated fixture tests**, preserving 1.4.8 build tooling. Before altering any gameplay C#, compile against the user's **actual** 1.5.7 TaleWorlds DLLs and the correct Naval DLC; use the binary marker above only as reference. If exact source parity is mandatory for upstream feature import, get the author's 1.4.12b SHA or reproducible build provenance first.

**Live log / game gates later:** Harmony resolution errors and game startup; verify War & Peace Revamp ON/OFF, lawful Bellum peace, CR `mediate_peace` attempted raw peace, current war state, old AII ledger save handling and save/reload. **Do not conclude that startup is safe just because the binary is labeled v1.4.12.**


## 16. Stage 1D — Bridge 0.8.8 → CR 2.8.9 reuse-versus-adapter audit (2026-11-14, documentation only)

**Scope/HEAD:** Old **Bellum Bridge** repository `AIRebelRelay/Bannerlord2-AiInfluence-BellumCivile` @ `f362a4f70786896b4160489bc1e3f448fdd0578e` (main, 0.8.8); our **Native Bellum** `AIRebelRelay/BellumCivile` @ `59b2aee8268cf1633e052e6b44e1cdba0e3c15fb` (main, custom 1.4.11.1); upstream **Calradia Remembers 2.8.9** source baseline @ `c49c01c7f00d674768c1824512d8cf683e3b2db0` (not the subsequently advancing CR main). Separate **Relay Bridge** `AIRebelRelay/ai-rebel-relay-bridge` @ `79c2926219a8dfb1b11c6a3fa24a27fcccf4a3ad` (main) is not this Bellum Bridge and was not inspected for code reuse.

**Evidence:** source-inspected [old Bridge SubModule.xml](https://github.com/AIRebelRelay/Bannerlord2-AiInfluence-BellumCivile/blob/f362a4f70786896b4160489bc1e3f448fdd0578e/module/SubModule.xml), [main tick host](https://github.com/AIRebelRelay/Bannerlord2-AiInfluence-BellumCivile/blob/f362a4f70786896b4160489bc1e3f448fdd0578e/src/AIInfluenceBellumBridge2/SubModule.cs), AII statement routers, Native data observers, sidecar/event publishers and CR public extension source files. This is a **targeted call-chain/source inventory**, **not** exhaustive tests of every legacy Bridge file.

### 16.1 Source-backed current call chains

1. **Old module load/host:** `module/SubModule.xml` has *mandatory* `<DependedModule Id="AIInfluence"/>` plus `BellumCivile`; it registers many `AIInfluenceBellumBridge2` submodules. The [host's `OnApplicationTick`](https://github.com/AIRebelRelay/Bannerlord2-AiInfluence-BellumCivile/blob/f362a4f70786896b4160489bc1e3f448fdd0578e/src/AIInfluenceBellumBridge2/SubModule.cs) polls AII statement activity, Bellum ACK and Relay-owned treaty intents each second, followed by event/outcome pollers, sidecar flush and sliced campaign scans. **Removing one XML dependency cannot make these paths CR-aware.**
2. **Old AII action → Bellum:** [`BridgeV1ActionSeamActiveRouter`](https://github.com/AIRebelRelay/Bannerlord2-AiInfluence-BellumCivile/blob/f362a4f70786896b4160489bc1e3f448fdd0578e/src/AIInfluenceBellumBridge2/BridgeV1ActionSeamActiveRouter.cs), [`BridgeV1SourceBackedForeignTreaty.Core`](https://github.com/AIRebelRelay/Bannerlord2-AiInfluence-BellumCivile/blob/f362a4f70786896b4160489bc1e3f448fdd0578e/src/AIInfluenceBellumBridge2/BridgeV1SourceBackedForeignTreaty.Core.cs), [`BridgeV1ActiveForeignPeaceRouter`](https://github.com/AIRebelRelay/Bannerlord2-AiInfluence-BellumCivile/blob/f362a4f70786896b4160489bc1e3f448fdd0578e/src/AIInfluenceBellumBridge2/BridgeV1ActiveForeignPeaceRouter.cs) extract and correlate **AII** `Statement`/`EventId`/accepted action semantics and reflectively invoke Bellum's treaty/war seams. They are **not** CR `ExternalActionSpec` implementations.
3. **Legacy AII foreign-war owner:** [`BridgeV1SourceBackedForeignWar.AiiLedger`](https://github.com/AIRebelRelay/Bannerlord2-AiInfluence-BellumCivile/blob/f362a4f70786896b4160489bc1e3f448fdd0578e/src/AIInfluenceBellumBridge2/BridgeV1SourceBackedForeignWar.AiiLedger.cs) calls Native `TryRegisterAiInfluenceForeignWar` only after proving the AII event/war pair. This is **AII-specific accounting when Revamp is OFF**, **not** a reusable CR war executor.
4. **Native facts → old AII/Relay transport:** [`BellumInternalDialogueContextWriter`](https://github.com/AIRebelRelay/Bannerlord2-AiInfluence-BellumCivile/blob/f362a4f70786896b4160489bc1e3f448fdd0578e/src/AIInfluenceBellumBridge2/BellumInternalDialogueContextWriter.cs) snapshots domain facts to an AII Bridge JSON folder; [`BellumCourtTransitionShadowObserver`](https://github.com/AIRebelRelay/Bannerlord2-AiInfluence-BellumCivile/blob/f362a4f70786896b4160489bc1e3f448fdd0578e/src/AIInfluenceBellumBridge2/BellumCourtTransitionShadowObserver.cs) compares snapshots, then [`BellumCourtEventFeedSubModule`](https://github.com/AIRebelRelay/Bannerlord2-AiInfluence-BellumCivile/blob/f362a4f70786896b4160489bc1e3f448fdd0578e/src/AIInfluenceBellumBridge2/BellumCourtEventFeedSubModule.cs) publishes `court_politics_transition` into [`BellumSidecarWriter`](https://github.com/AIRebelRelay/Bannerlord2-AiInfluence-BellumCivile/blob/f362a4f70786896b4160489bc1e3f448fdd0578e/src/AIInfluenceBellumBridge2/BellumSidecarWriter.cs), with explicit **Relay** semantic grouping. This pipeline observes facts but its **delivery protocol and retention/ACK** are for AII/Relay, **not CR memory**.
5. **Private court evidence must stay private:** [`BellumCourtPolicyVoteJoinObserver`](https://github.com/AIRebelRelay/Bannerlord2-AiInfluence-BellumCivile/blob/f362a4f70786896b4160489bc1e3f448fdd0578e/src/AIInfluenceBellumBridge2/BellumCourtPolicyVoteJoinObserver.cs) marks joined provenance `held_for_transport` and does **not** publish global facts. [`BellumCourtPolicyVoteAudienceObserver`](https://github.com/AIRebelRelay/Bannerlord2-AiInfluence-BellumCivile/blob/f362a4f70786896b4160489bc1e3f448fdd0578e/src/AIInfluenceBellumBridge2/BellumCourtPolicyVoteAudienceObserver.cs) explicitly prohibits sending private vote audience into generic notifications, Relay or AII NPC memory. CR integration must honor this distinction instead of feeding all snapshots to every NPC.
6. **Scheduling:** [`BridgeV1HeavyPollScheduler`](https://github.com/AIRebelRelay/Bannerlord2-AiInfluence-BellumCivile/blob/f362a4f70786896b4160489bc1e3f448fdd0578e/src/AIInfluenceBellumBridge2/BridgeV1HeavyPollScheduler.cs) uses event/dirty changes with bounded ~1.5ms slices and a 60-second fallback. The **algorithm** is useful; copying the scheduler and its callbacks verbatim would import AII/sidecar/lifecycle coupling. Design CR scheduling only after measuring its own event and prompt cost.
7. **Outcome proof:** [`BellumForeignTreatyOutcomePoller`](https://github.com/AIRebelRelay/Bannerlord2-AiInfluence-BellumCivile/blob/f362a4f70786896b4160489bc1e3f448fdd0578e/src/AIInfluenceBellumBridge2/BellumForeignTreatyOutcomePoller.cs) distinguishes `Applied` and `Rejected` proposal outcomes and emits source-backed fact envelopes to the sidecar. Keep the **terminal-receipt principle**, but reconcile Bellum's latest proposal IDs, expiry, save-load and delivery guarantees before using it as a CR `Feed` source.

### 16.2 Reuse / adapt / keep-legacy matrix — DECISION FOR PLANNING ONLY

| Old feature / source | Classification | CR-compatible route |
|---|---|---|
| Native read-only `BellumIntegration.GetCourtAgendas`, `GetPendingVotes`, proven public outcome snapshots | **REUSE DOMAIN API** | CR-specific typed/reflected reader, correct active campaign thread and API version, source-verified actor-level visibility |
| `BellumInternalDialogueContextWriter`, political state/court/claim snapshots | **ADAPT FACT MODEL** | Build **scoped** CR `CrPrompt.RegisterVariable` providers from Bellum game truth; do not write old AII JSON as a CR prompt or leak other realms' secrets |
| `BellumCourtTransitionShadowObserver`, `BellumForeignTreatyOutcomePoller`, `BellumForeignWarOutcomePoller` | **ADAPT EVENT LOGIC** | Prefer exact Native terminal receipts; otherwise bounded diff/event observer → source-stable id → CR `Feed.Record/Update/Retract`; do not report `Pending` as completed |
| `BellumCourtPolicyVoteJoinObserver`, `BellumCourtPolicyVoteAudienceObserver` | **REUSE PRIVATE CONTRACT** | Audience-scoped context only after proof of what individual NPC knows; no global CR news. No automatic direct `CrNpcMemory.AddMemory` from a technical receipt |
| `BridgeV1HeavyPollScheduler`, bounded dedup and campaign identity guards | **ADAPT ALGORITHM** | Use dirty events and bounded budgets if needed; new host/lifecycle. Test campaign switch, reload, idempotent delivery, no per-frame heavy scan |
| `BellumSidecarWriter`, `BellumAckConsumer`, `BridgeV1RelayTreatyIntentShadowConsumer` | **KEEP AS AII/RELAY LEGACY** | CR has native feed/memory APIs; no duplicate sidecar/ACK transport for CR by default. Only reintroduce a transport after a demonstrated missing capability |
| `BridgeV1ActionSeamActiveRouter`, AII IL/metadata/statement probes, `BridgeV1SourceBackedForeignWar.*`, AII Shadow Pending Peace ledger | **KEEP LEGACY; DO NOT PORT VERBATIM** | New explicit CR `CrActions.Register(new ExternalActionSpec)` action/CR-approved delegation; Bellum owns real war/treaty commits. Do not rename AII event ID as CR consent |
| Old `BridgeV1SourceBackedInternalPolitics.*` intent executor | **REVIEW ACTION BY ACTION** | Translate *requirements* and proven role checks into typed CR requests; reuse Native `TryStageNpcCouncilAppointmentIntent`/`TryStageNpcTreasonIntent` only with sponsor proof and namespace; never replay AII JSON queue |
| Old module `AIInfluenceBellumBridge2.dll` and `module/SubModule.xml` | **PRESERVE AS LEGACY, NOT CR RUNTIME** | New independently loadable CR↔Bellum module with its own ID, dependency contract and lifecycle; avoid overloading legacy ModuleId or changing its requirements |

### 16.3 New CR surface is already supported (verified at CR pinned v2.8.9 source)

- [`CrActions.Register`](https://github.com/LogRaam/calradia-remembers/blob/c49c01c7f00d674768c1824512d8cf683e3b2db0/CalradiaRemembers/Extension/CrActions.cs) registers **new** external actions into catalog, verb registry and dispatcher, with `ExternalActionSpec.IsEligible`, `Guidance`, `WhenNotToEmit`, `Execute`; cannot simply replace a built-in name. Check actor authority and current Bellum legality **again inside Execute**.
- [`Feed.Record/Update/Retract`](https://github.com/LogRaam/calradia-remembers/blob/c49c01c7f00d674768c1824512d8cf683e3b2db0/CalradiaRemembers/Extension/Feed.cs) records source-identified world events; dedups source IDs through CR's persistent event store, `Record` quotas at most **20 new events/source/game day**, and prompt scoring typically surfaces **six relevant news**. Not every internal state transition should become world news.
- [`CrPrompt.RegisterVariable`](https://github.com/LogRaam/calradia-remembers/blob/c49c01c7f00d674768c1824512d8cf683e3b2db0/CalradiaRemembers/Extension/CrPrompt.cs) contributes live prompt variables from authoritative current-state providers. Do not make an all-seeing NPC.
- [`CrConversation`](https://github.com/LogRaam/calradia-remembers/blob/c49c01c7f00d674768c1824512d8cf683e3b2db0/CalradiaRemembers/Extension/CrConversation.cs), [`CrAims`](https://github.com/LogRaam/calradia-remembers/blob/c49c01c7f00d674768c1824512d8cf683e3b2db0/CalradiaRemembers/Extension/CrAims.cs), [`CrLetters.DeliverWithId`](https://github.com/LogRaam/calradia-remembers/blob/c49c01c7f00d674768c1824512d8cf683e3b2db0/CalradiaRemembers/Extension/CrLetters.cs) support conversation hooks, player-facing character aims and courier letters. This is **not** evidence of autonomous NPC↔NPC treaty correspondence; request LogRaam's preferred hook when needed.
- [`CrNpcMemory`](https://github.com/LogRaam/calradia-remembers/blob/c49c01c7f00d674768c1824512d8cf683e3b2db0/CalradiaRemembers/Extension/CrNpcMemory.cs) supports selectively sourced NPC private memories. Do not use mass `AddMemory` as replacement for world `Feed`.

### 16.4 Architecture choice, code boundary and next regression gate

**Preferred path (PROPOSAL):** **retain the existing Bellum Bridge repository and all legacy code**, but author an **independent CR-specific module/project** within it (exact module ID/path/version pending full caller/build inventory). Reuse Bellum-owned public API **contracts** and selected observer algorithms **selectively**, not by changing old `SubModule.xml` or copying its whole AII-specific runtime. This is smaller in *runtime coupling* than renaming 0.8.8 and pretending CR emits AII statements. Keeping the project within the existing Bellum Bridge repo retains our history/tests while making the new module independently packageable. This is an architectural proposal only; check full build tooling and game ABI before committing to the folder layout.

**Root cause:** Two incompatible plugin contracts: the old Bridge loads **only when AII is installed** and expects AII statement/Relay sidecar protocols; CR exposes a different, supported extension API. Merely removing XML dependencies or retargeting a class name would silently change diplomacy ownership.

**TOUCH NOW:** only this new planning section of `docs/architecture/CR_2_8_9_BELLUM_LLM_DIPLOMACY_MASTER_PLAN.md` on the isolated **Native Bellum docs branch**. **DO NOT TOUCH:** Native Bellum code, old Bellum Bridge 0.8.8, Relay Bridge, Relay models, CR code, game DLLs/saves, production branches, 1.4.8 build gate. **MUST FIX IN PLANNING:** exact preserve/adapt/reimplement choices and first read-only proof. **MUST NOT CHANGE:** AII bridge's behavior, foreign war/peace ownership, original AII ledger save decoder, special civil-war rules, private-court visibility, Bellum's treaty ratification or any save IDs.

**First proposed CR↔Bellum executable stage (NOT STARTED):** register **zero effectful actions**. Read one source-backed Bellum public court/peace outcome, verify its terminal status, actor/realm visibility and campaign/proposal ID; send at most one event to CR `Feed.Record` via a distinct stable `SourceMod`, recheck after save/load and after retries. Separate read-only current-state prompt variable only if grounded visibility and source freshness are proven.

**Pre-code regression contract:**

- Positive: one legal **final** Native court/treaty outcome creates exactly one appropriately attributed CR world event, visible only to eligible hearers; factual state (war, treaty, houses) agrees; one scoped prompt variable reflects current Bellum state, not speculation.
- Negative: `Pending`/`Proposed`/`Cancelled` never becomes a completed deed; failed native vote stays failed; zero duplicated delivery after reload or polling; unknown/private audience never leaks to foreign NPC; CR absent/unsupported version fails safely without changing Bellum; old AII bridge installed alone remains unchanged; no AII assembly, DLL, event queue, Relay Bridge or `aii_foreign_ledger` needed in the CR-only profile.
- Follow-up gates: check target Bannerlord 1.5.7 and War Sails ABI; validate `BellumIntegration` behavior on our ported Native; run source-level regression, build, 2-week campaign and save/load, and compare `[FEED]` with actual Native terminal receipt. **No current compilation, game tests or passing-runtime claims.**

**Runtime log checks planned (new bridge's exact log format not yet implemented):** expected `[CR_BELLUM] source=bellum status=terminal event_id=…`, CR `[FEED] <SourceMod> recorded…` once; unexpected `[FEED]` for a pending proposal, duplicated ID, invisible/private state, or a completed peace announcement while TaleWorlds still reports war. Exact log prefix is **proposed**, not observed.


## 17. Non-negotiable AII-style diplomatic statements + informed world NPCs (requirement reaffirmed 2026-11-14)

**User requirement, not optional backlog:** The replacement of AI Influence must retain **(A) diplomatic statements** and **(B) autonomous world-event awareness** as first-class pillars. The goal is **controlled chaos**: NPCs originate political intentions, learn relevant developments, and act within Bellum's legitimate campaign rules, rather than needing the player to trigger every conversation.

### 17.1 Two different systems, not a single "feed" feature

| Pillar | Required behavior | Verified CR 2.8.9 surface | Missing / not established |
|---|---|---|---|
| **A. Diplomatic statements / negotiations** | NPC A independently issues a consequential, source-identified declaration or proposal to NPC B, a clan, or a realm (war threat, peace terms, alliance, ultimatum, vassal/court demand). The addressee can respond, reject, counteroffer, escalate; pending, accepted, refused, expired, committed all have distinct states. Participant memories and later actions follow **actual** Bellum receipts. | CR \`CrActions.Register\` adds actions to an **active CR conversation**; \`CrAims\` surfaces a lord's aim **when a player opens a conversation**; \`CrLetters.DeliverWithId\` sends from NPC **to player**. CR \`Strategy/LordStrategyBehavior\` may periodically submit rule-based war/peace/alliance/call-to-arms decisions and emits news, but does **not** establish a public autonomous LLM NPC↔NPC statement/response API. | Source-backed public hooks for **autonomous NPC↔NPC initiated LLM proposals and replies**, asynchronous delivery, participant/actor proof, counteroffers, structured receipts. Cannot call the existing player-facing \`CrLetters\` or \`CrAims\` an NPC↔NPC diplomacy API. |
| **B. World events and who hears them** | Bellum court/foreign affairs/hostages/rebellions/ruler succession/war/peace/treaty changes provide facts to **plausibly informed** NPCs with fresh chronology, realm reach, privacy/rumor constraints, identity/source and dedup. NPCs may then incorporate these facts into statements and plans without omniscience or phantom outcomes. | CR \`Feed.Record/Update/Retract\` accepts externally sourced world events and dedups stable IDs; \`CrNpcMemory\` can attach *specific* memories; \`CrPrompt.RegisterVariable\` gives live scoped context. \`HOWTO_WorldEvents.md\` documents hearing scores (realm/hero/place/recency), max **20 new events per SourceMod per game-day**, the **six** top-scoring world news items visible in a prompt, \`cr.heard\` diagnostics. | Feed availability in a **player↔NPC prompt** is **not** proof of independent background NPC reasoning or NPC↔NPC rumor exchange. Need to validate event category coverage, priority/quotas, private audience, rumor propagation and how/when stored knowledge can influence NPC↔NPC diplomatic decisions. |

**Precise source links (CR pinned \`c49c01c...\`, manifest 2.8.9):** [Feed.cs](https://github.com/LogRaam/calradia-remembers/blob/c49c01c7f00d674768c1824512d8cf683e3b2db0/CalradiaRemembers/Extension/Feed.cs), [HOWTO_WorldEvents.md](https://github.com/LogRaam/calradia-remembers/blob/c49c01c7f00d674768c1824512d8cf683e3b2db0/CalradiaRemembers/Extension/HOWTO_WorldEvents.md), [CrActions.cs](https://github.com/LogRaam/calradia-remembers/blob/c49c01c7f00d674768c1824512d8cf683e3b2db0/CalradiaRemembers/Extension/CrActions.cs), [CrAims.cs](https://github.com/LogRaam/calradia-remembers/blob/c49c01c7f00d674768c1824512d8cf683e3b2db0/CalradiaRemembers/Extension/CrAims.cs), [CrLetters.cs](https://github.com/LogRaam/calradia-remembers/blob/c49c01c7f00d674768c1824512d8cf683e3b2db0/CalradiaRemembers/Extension/CrLetters.cs), [LordStrategyBehavior.cs](https://github.com/LogRaam/calradia-remembers/blob/c49c01c7f00d674768c1824512d8cf683e3b2db0/CalradiaRemembers/Strategy/LordStrategyBehavior.cs). This is an API-surface finding, **not a claim to have exhaustively disproved every private CR mechanism**.

### 17.2 P0 request to LogRaam — minimum contract, not implementation prescription

1. **Autonomous, externally triggerable NPC↔NPC interaction seam.** Can a third-party mod request a private or public LLM-authored diplomatic message from \`speakerHeroId\` to \`targetHeroId\` / target realm **without opening a player chat**? If not, can CR expose a supported proposal/response API that reuses CR personality, memories, political context and lifecycle? We need a response/counteroffer/rejection callback, \`conversation/statementId\`, provenance, save-safe pending/expired statuses, turn budget and explicit actor-vs-target authorization. Do **not** require that CR directly mutates Bellum gameplay state.
2. **Bellum precommit mediation / generic action handoff.** A public veto/delegation hook for CR's **built-in** \`mediate_peace\` and other conflicting native diplomacy verbs before any TaleWorlds action is applied. The hook must distinguish \`Rejected\`, \`Pending\` (e.g., awaiting Bellum parley), \`Applied\` with true Bellum receipt, and \`PassThrough\`. \`CrActions.Register\` cannot override a built-in verb. A successful LLM text response is not evidence a war has ended.
3. **Background awareness integration.** Confirm whether external \`Feed\` facts already enter the NPC's decision context when CR executes autonomous strategy/background actions; if not, ask for an opt-in, actor-scoped, bounded "known events/context" accessor or injection seam. Do **not** ask to rebuild the existing \`Feed\` unless a demonstrated gap prevents NPC knowledge from influencing independent decisions.

**LogRaam owns CR's LLM context/runtime and supported public extension contract. Bellum owns the actual treaty/war/court transaction and its receipts. The new CR↔Bellum Bridge owns source-backed mapping, authorization, visibility and dedup. Relay owns backend/model routing only.**

### 17.3 P1 asks or Bridge-owned fallback if upstream declines

- **Event coverage and prioritization:** Capture relevant Native Bellum notifications with event IDs/owner receipts: international treaties/war/peace, alliances, ultimatums, rebellion and court, ruler changes, appointments, hostages, private audience, factions. Add source-specific filters/priority/summarization so 20/day cap and six prompt news slots do not bury high-value diplomacy. If appropriate, request documented scoped batches or priority handling from CR only after measuring missing coverage.
- **Social rumor propagation:** An NPC who legitimately knows a court secret may tell another NPC through a recorded encounter/letter, with explicit source, likelihood, delays, provenance and secrecy; no auto-broadcast of private court audience. This can be Bridge-owned **only if** the CR memory/feed interfaces suffice and no unsupported CR runtime hook is needed.
- **Long-lived diplomatic thread:** saved exchanges between named actors, structured terms, responses, escalations and expiry, idempotent handling across reload and relevant hearing/memory. Requires either supported CR autonomous LLM actor API or explicit agreement to implement an isolated Bridge-side orchestration service that asks CR for model/character context without duplicating private prompt logic.
- **Decision relevance:** only sourced known facts may influence NPC planning. Log causal chain: Bellum receipt → CR accepted event → NPC X heard it → statement Y cites it → Bellum preflight → terminal applied/rejected receipt. No "everyone knows everything" setting as default.

### 17.4 Regression contract and development stop condition

**Positive:** autonomous NPC A can initiate and receive an LLM-driven political response from NPC B without player chat; CR recalls lawful context; Bellum executes or queues only lawful actions, and the actual outcome is reported. A grounded public Bellum war/peace/court event reaches eligible NPCs and may influence later diplomacy.

**Negative:** no direct TaleWorlds MakePeace bypass; \`Pending\` cannot be narrated as an ended war; secret voting and intrigue do not leak globally; player is not a required intermediary; no infinite LLM NPC↔NPC loops or unbounded tokens; event-feed quotas do not silently starve all international news; save/reload does not double-apply actions or replay historical rumors; AII legacy Bridge and Native save definitions remain untouched.

**Stop:** Do **not** expand the experimental \`feature/crbellum-first-council-feed-2026-11-14\` to more events/actions until (a) the API questions above are answered or an explicitly scoped Bridge fallback is approved and (b) Native Bellum 1.5.7 source/ABI compatibility is established. The council-feed experiment is **not** the architectural target: a one-way event by itself cannot deliver AII-style political statements or autonomous NPC world behavior.

**Exact file boundary for this documentation stage:** only this Markdown file on the existing docs branch. No code, builds, merges, save changes or runtime result claimed.


## 18. LLM Bellum 1.5.7 port — source-level decision ownership and minimal ABI audit (2026-11-14)

**Provenance pinned for this stage:** custom Native [AIRebelRelay/BellumCivile @ 59b2aee](https://github.com/AIRebelRelay/BellumCivile/commit/59b2aee8268cf1633e052e6b44e1cdba0e3c15fb) (1.4.11.1; Bannerlord 1.4.8 baseline), upstream [Vonbalt/BellumCivile @ 8a08e0c](https://github.com/Vonbalt/BellumCivile/commit/8a08e0c038a60030813c56eae39a5fbee0b75cb6) (manifest 1.4.12; target game 1.5.7). Recursive blob SHA comparison: **494 paths differ** (225 common paths have different blobs; 121 only custom; 148 only upstream). These counts are an *inventory*, not a claim that all paths need merging. Neither tree has been compiled here for 1.5.7.

### 18.1 Core identity: LLM Bellum, not vanilla Bellum with a newer game version

| Responsibility | Authoritative owner | Guard against regression |
|---|---|---|
| Combat outcomes, war score, war will, economic state, claims, court memberships, legality checks, influence costs, eligibility, voting/decision resolution, save migration, and maintenance/recovery | **Native Bellum + TaleWorlds** | Preserve these as factual state and legal constraints available to the LLM; do not disable internal processing to suppress competing suggestions |
| **Political intention/initiative**: a ruler or NPC wants to threaten, sue for peace, propose an alliance, negotiate hostages, demand territory, etc., especially bilateral **international** affairs | **LLM diplomacy service via CR↔Bellum Bridge** is the desired new primary source of proposal content and target selection | No Native routine should silently originate a parallel equivalent AI foreign-policy proposal while LLM authority is active; behavior while LLM is disabled must be **explicitly designed**, not changed incidentally |
| Authority to act: which person/clan may initiate, what votes are required, whether a treaty is possible, and whether an outcome really committed | **Native Bellum** | The LLM may submit a proposal, NEVER directly finalize a war, peace, treaty, marriage, hostage transaction, or kingdom change without a native terminal receipt |
| Character personality, memory, known events, and public/private context | **Calradia Remembers** (APIs) + Bridge's own private negotiation ledger | No global leakage of confidential council discussions; public Feed events are not proof that all NPCs know them |
| LLM routes, model selection, budgets, scheduling, background NPC↔NPC exchanges and diplomacy thread persistence | **AI Rebel Relay + CR↔Bellum Bridge** | Distinct from Relay Bridge; no mixed DLL or copied \`NpcMemoryService.Core.dll\` |
| Domestic deliberation and internal Bellum motions | **Not globally reassigned** at port stage | Inspect every class of domestic decision separately. Retain existing working councils, succession, civil-war, spontaneous reactions and voting; LLM might propose particular domestic motions later, but do not disable whole subsystems by default |

**Source-backed conflict inventory (not yet patched):**

1. **Already present in custom Native:** \`Behaviors/WarPeaceRevampBehavior.cs::TryCreateWarDecision\` uses Bellum's war-will/target scoring to build a \`DeclareWarDecision\`; \`TryCreatePeaceDecision\` can invoke \`ForeignTreatyBehavior.TryQueueAiParley\` for a non-player bilateral peace opportunity. These represent *intent/origination* paths, not just economic/world-state calculation. Callers and actual enablement must be traced before changing anything. \`OnDailyTickClan\` also computes war will and refreshes ranked targets, which must **not** be confused with autonomous decision commits.
2. **New upstream only:** \`Behaviors/VoluntaryPactAiBehavior.cs\` runs on \`CampaignEvents.DailyTickEvent\`; \`Evaluate\` may call \`VoluntaryPactProposalBehavior.TryCreateAndFile\`. It is a concrete background **AI proposal initiator**, while \`VoluntaryPactProposalBehavior\` is a *transaction/validation/recovery* system. Do **not** indiscriminately import the upstream AI initiator as a background foreign-policy competitor in the LLM-enabled profile, and do **not** disable its proposal validation/delivery just because the initiator overlaps.
3. **Custom LLM-specific safety:** \`Behaviors/WarScoreAiInfluenceForeignLedger.cs\` preserves accounting-only foreign-war records linked to accepted AI Influence event IDs, and \`Patches/CivilWarMakePeacePatch.cs\` contains protection from premature AI Influence peace on new civil wars. Do not repurpose those AII-specific receipts as CR's own receipts or remove protections in the name of a new LLM source. Analyze reuse/migration as a separate stage.
4. **New upstream systems:** lordships, voluntary peacetime hostage pacts, court term preparation and a substantial save/type expansion. These are **not** mere 1.5.7 ABI fixes; each has independent save/gameplay/LLM-authority blast radius. Explicit separate design review required.

### 18.2 Verified narrow Bannerlord 1.5.7 compatibility seam

Source comparison of \`CouncilAssignmentRuntimePatches.cs\`: custom and upstream files are **identical except three source lines** in the target version:
- Harmony target \`GetPartyMemberSizeLimit\` changed from argument types \`(PartyBase, bool)\` to \`(PartyBase, bool, bool)\`.
- Both \`TryGetPatrolAssignmentLimits\` invocations now pass \`party.IsCurrentlyAtSea\` into \`model.GetPartyMemberSizeLimit(party.Party, party.IsCurrentlyAtSea)\`.

This matches upstream commit \`b9def48e9d12b6989bfa7050087261265b8db75e\` (2026-11-10, "updated beta build to 1.5.7"). Its own \`Tests/SuccessionEngineHarness/GameVersionCompatibilityTests.cs\` added regression assertions for the method signature, both land/sea calls and hook registration. These are specific *source* facts; actual compatibility with the installed 1.5.7 game DLLs remains unverified.

**Call chain/blast radius:** \`SubModule.OnGameStart\` → \`CouncilAssignmentRuntimePatches.Initialize\` → \`PatchActiveModelMethod(GetPartyMemberSizeLimit)\` → \`ApplyPatrolSizeAssignment\` / \`TryGetPatrolAssignmentLimits\`. Shared \`Initialize\` installs four model hooks; a signature mismatch could silently drop a hook, while changing the helper could disturb the other three. Its callers are currently limited by identified source entrypoints; any wider consumer must be checked before patching.

**Candidate next production stage (not authorized by this audit):**
- **ROOT CAUSE:** Native 1.4.11.1 still binds the older party-size ABI, which no longer matches TaleWorlds 1.5.7. Separately, existing and incoming autonomous foreign-policy proposal sources risk bypassing the intended LLM authority. Treat the ABI regression and policy ownership as **different bugs/stages**.
- **TOUCH (ABI candidate):** \`CouncilAssignmentRuntimePatches.cs\` — precisely the three source lines above; a new **1.5.7** regression test/build gate in its own file(s), after confirming real SDK references and installed game DLLs.
- **DO NOT TOUCH:** \`WarPeaceRevampBehavior\`, \`ForeignTreatyBehavior\`, \`VoluntaryPactAiBehavior\`, court/succession/war-vote rules, save types, CR/Relay Bridge, legacy AII Bellum Bridge, legacy \`Verify-Bellum148Build.ps1\` and its \`P014FGameVersionManifest.Tests.ps1\` tests.
- **MUST FIX:** compatible Harmony method lookup and party-size calculation using correct sea state, retaining patrol size bonuses.
- **MUST NOT CHANGE:** other three hooks, regular non-patrol party-size calculations, land behavior, native political outcome rules, old 1.4.8 shipping gate semantics, saved data.
- **POSITIVE REGRESSIONS (future):** binding against real 1.5.7 \`PartySizeLimitModel\`; both calls use \`IsCurrentlyAtSea\`; all four hooks install; patrol bonuses work on land and at sea.
- **NEGATIVE REGRESSIONS (future):** no hook against obsolete two-parameter method, no non-patrol bonus, no save/seed regression, no altered foreign-policy initiator or war/peace result, old 1.4.8 gate remains available on its old baseline.
- **VALIDATION:** static diff audit → runnable targeted PowerShell and C# test harness against 1.5.7 DLLs → actual \`dotnet build --no-incremental\` on 1.5.7 dependency tree → fresh campaign, existing save and War Sails/land patrol with logs. Compile alone is **not** a game pass.

### 18.3 Action policy

**Do not merge upstream into our 1.4.11.1 main, overwrite newer custom source, port all new upstream save types, disable all NPC AI, or remove any Harmony patches without proving their exact call chains and regression consumers.** First port narrow game-version ABI fixes; then separately design a **foreign-policy initiation authority seam** with explicit LLM-enabled / LLM-unavailable behavior and public Bellum preflight/terminal receipts.

**LogRaam agreement (from direct discussion 2026-11-14):** CR will work on (1) optional common diplomacy authority delegation and (2) per-NPC public knowledge + Feed secrecy. CR does *not* provide NPC↔NPC orchestration; that belongs to our Bridge, using own LLM routing and budgets. This external API work does not block source-only Bellum ABI auditing.

**This stage changed documentation only.** No Native build, test run, gameplay result, code patch, or claim that international policies are already fully under LLM authority.


## 19. OFFER_PEACE v0.1 — LLM Bellum negotiated treaty contract, read-only design (2026-11-15)

**Stage status:** CONTRACT ONLY. No production edits, external LLM calls, dry-run execution, game validation, builds, or release. This is not a promise that the API below already exists.

**Provenance:** custom Native Bellum main `59b2aee8268cf1633e052e6b44e1cdba0e3c15fb` (1.4.11.1), CR main `e076086424a0d8c6ac25f68e88ae06cd8fa4a9cf` (CR 2.8.10 extension API). Reviewed AII 7.0.0 decompiled `DiplomaticAction`, `DiplomaticStatementResponse`, `DiplomaticStatementWorkRegistry`, `KingdomStatementGenerator` for **requirements and regression lessons only**; NO AII code copied and several decompiled bodies are not complete. Existing working AII Bridge and Relay Bridge stay separate.

### 19.1 SOURCE-BACKED ROOT CAUSE / BOUNDARY

- In custom Native, `ForeignTreatyBehavior.TryQueueAiParley` → `TryQueueParley` → `DraftAiTerms` / `CanSubmitAutomaticDraft` may synthesize treaty terms and check both sides' automatic council acceptance. `OnDailyTick` → `ResolvePendingParley` → `EvaluateRatification` → `ApplyTreaty` → `ApplyTreatyCore` can finish an NPC-only parley after a campaign day. **This is not a pure "submit externally negotiated draft" API**. Reusing it blindly would give Native its own negotiating authority.
- `TryQueueParley`, the player sign/reject/vote paths, and `ForeignTreatyBehavior.OnDailyTick` have broad `WarPeaceRevampBehavior.IsRevampEnabled()` gates. With Revamp **OFF**, they are not ready-made LLM treaty execution services. Conversely, simply enabling Revamp also enables unrelated policy-initiative paths; do not do that as a workaround.
- `WarScoreBehavior.CanRegisterConflict` rejects regular foreign-war tracking with Revamp OFF. Custom `TryRegisterAiInfluenceForeignWar` is an **accounting-only**, AII-source-proofed exception; it has its own event-id invariants and must not be renamed/reused as a CR authoritative receipt. Its `ShouldPreventAutonomousForeignResolution` suppresses automatic foreign-war end states, including terminal resolution, while Revamp OFF.
- `Patches/CivilWarMakePeacePatch.ShouldAllowOrdinaryKingdomPeace` passes vanilla international peace with Revamp OFF; thus the absence of Native autonomous parley does **not** mean all external vanilla or CR peace execution is prevented.
- CR 2.8.10 `CrDiplomacy.RegisterAuthority` applies to CR-originated explicit actions (e.g., `mediate_peace`, council/scenario), **not** TaleWorlds game votes, ordinary AI decisions, or all other mods. It cannot be the only foreign-peace fence. CR `CrWorld.KnownEvents(heroId)` provides actor-specific knowledge and secret Feed events; CR does not generate autonomous NPC↔NPC diplomacy for us.
- Identified known *candidate* callers/consumers for future review: `WarPeaceRevampBehavior.TryCreatePeaceDecision`, `WarScoreBehavior.TryResolveForeignWhitePeaceFromProposal`, `ForeignTreatyBehavior.TryQueueAiParley`, its player parley entrypoints and UI, `ForeignTreatyBehavior.OnDailyTick`, the war-score terminal resolver, `CivilWarMakePeacePatch`, and `CrDiplomacy` integration. This list is **not a complete call-graph guarantee**.

### 19.2 PRODUCT CONTRACT — OFFER_PEACE

**Initiation:** during an existing ruler rotation, the Bridge chooses an eligible, living ruler, obtains truthful game facts and `CrWorld.KnownEvents(rulerHeroId)`, then presents a **dynamic** `OFFER_PEACE` capability card when an actual foreign hostile pair exists. The card is distinct from `PUBLIC_STATEMENT` and `NO_ACTION`. The LLM can decline to propose peace; no forced positive choice.

**Illustrative LLM-facing card (designed, not an existing API):**

```yaml
id: OFFER_PEACE
intent: Open negotiations with an enemy realm; this does NOT end the war.
target: one currently hostile foreign kingdom (exact Kingdom.StringId)
availability: generated from current campaign facts, actor authority and political restrictions
terms: white_peace OR a typed draft using only Bellum-supported negotiable clauses
expected_response: ACCEPT_IN_PRINCIPLE | REJECT | COUNTEROFFER | SILENCE
limitations: ruler acceptance is not treaty ratification; Bellum councils, treaty budgets,
             Story Mode protections, influence costs and current state still apply
alternative: NO_ACTION | PUBLIC_STATEMENT
```

**Candidate Bridge request** (all keys conceptual): `saveId`, `requestId`, `initiatingHeroId`, `initiatingKingdomId`, `targetKingdomId`, `warKey`, `warStateRevision`, `statement`, `proposalId`, `termItems[]`, `expiryGameDay`, `privacy`, `knownEventIds[]`. The Bridge's private negotiation ledger persists identifiers, structured terms, prior replies and their provenance. Use stable IDs, not displayed hero/kingdom names.

**Two independent stages of agreement:**

1. **Political agreement in principle:** sender LLM proposes; target ruler LLM reacts or player decides if player is the actual ruler. Counteroffers create new immutable revisions under the same negotiation thread. Merely saying "I accept" must not trigger `MakePeaceAction`.
2. **Authoritative application:** after the agreed terms are prepared, Bellum independently validates active war, proposer authority, player involvement, storyline restrictions, auxiliary-client war status, clause validity, War Score budget, council/ruler ratification, influence payment and relevant treaty-specific effects. Only the committed Native receipt permits announcing "peace signed". Bellum **may reject** a verbally accepted agreement.

**Canonical conceptual state machine:**

`ELIGIBLE` → `DRAFTED` → `OFFERED` → `COUNTERED` (repeat bounded) / `REJECTED` / `EXPIRED` → `ACCEPTED_IN_PRINCIPLE` → `SUBMITTED_TO_BELLUM` → `RATIFICATION_PENDING` → `APPLIED` or `DENIED` / `CANCELLED`.

There is no unconditional transition from `OFFERED` or `ACCEPTED_IN_PRINCIPLE` to `APPLIED`. A pending or failed Native operation must not emit signed-treaty news, alter the hostility state, pay reparations or transfer fiefs.

**Intent preflight vs commit:** preflight must be **read-only** and return eligibility plus legal/reasonable term bands *as data*, rather than choosing the treaty policy. The final submission uses a campaign-thread, versioned, idempotent, CR-independent Native Bellum gateway accepting **exact negotiated terms**, not `DraftAiTerms`. Possible future API boundary (names subject to review): `PreviewForeignPeace`, `SubmitNegotiatedForeignTreaty`, `GetForeignTreatyReceipt`. Do NOT implement these names before tracing all existing treaty and vote callers and agreeing on ownership. The Bridge must not invoke `MakePeaceAction.Apply` directly.

**Revamp mode:** treat `EnableWarPeaceLogicRevamp=false` as the currently preferred player profile, **not** as a final dependency design. A future separable "Bellum simulation/treaty execution ON, Native foreign-policy initiative OFF" profile needs separate review. Do not flip the old switch under the hood and do not re-enable broad autonomous foreign-war/peace resolution to obtain treaty services.

**World knowledge:** CR 2.8.10 `CrWorld.KnownEvents` is the source for what each ruler plausibly knows. Confidential offers become Bridge-owned private diplomatic threads and/or CR secret events / `CrNpcMemory.AddMemory(Private=true)`; confirmed public outcomes alone become public Feed news. Ensure character-scoped facts are read on campaign thread, not from async provider threads. CR's `Feed.Record` per-source/day quota means event aggregation should remain an explicit Bridge concern.

**LLM-unavailable policy:** avoid covert Native acceptance or forced peace as a fallback. Preserve a pending diplomatic request, fail it or expire it by a separately specified rule; make a distinct explicit product decision for storyline-mandated or terminal-conflict exceptions before changing any emergency resolver.

### 19.3 REGRESSION CONTRACT DEFINED BEFORE IMPLEMENTATION

| Scenario | Required dry-run / later live outcome |
|---|---|
| Two AI kingdoms at war; ruler makes offer; target considers it | Valid offer and response thread; `Applied=false` until Native signed receipt |
| Counteroffer changes tribute/fief/prisoners | Immutable new revision and fresh term normalization; never share stale term amounts across multiple actions |
| Ruler accepts but council rejects or budget insufficient | `DENIED`; war continues, no gold/fief/custody mutation; reasons preserved |
| War already ended, target eliminated, signer dethroned, or save changed | Reject stale request; no game mutation or wrong-campaign reply |
| Player rules recipient or sender realm | Only actual player decides their political reply; no LLM impersonation of player |
| Story Mode war, auxiliary client war, internal civil war/claim feud | Appropriate rejection or delegated internal path; never convert into ordinary foreign peace |
| Zero/weak War Score and voluntary white peace | Preflight reports Bellum legality rather than assuming `TryGetForeignParleyProposal`'s AI heuristic is binding law; no silent fallbacks |
| Duplicate requestId, duplicate response, save/reload mid-ratification | One at-most-once final commit and one public outcome receipt |
| CR `mediate_peace` requested while Bridge authority active | `CrDiplomacy` reports `Pending`/`Rejected` truthfully, not automatic `Applied`; Native diplomacy still needs its own guard |
| No CR or absent authority; legacy baseline | Existing CR behavior without registration unaffected; Native old 1.4.8 shipping / AII Bridge protected; no new global defaults |
| Bellum automatic settlement reaches terminal War Score | Never auto-apply foreign peace while LLM ownership active; log required human/LLM diplomatic escalation, preserve actual internal-war resolution |

**Dry-run harness design (future, not executed):** feed 30–50 deterministic scenario fixtures spanning 3–5 ruler personalities. Stub Native preflight/receipt; do not mutate Bannerlord game objects or saves. Compare LLM choices against player/realm permissions, real knowledge, optional no-action, repetition cooldown, term schema, offer → counteroffer → council rejection flow. Record false positive actions, invented knowledge, invalid terms, duplicate requests and token/cost. Treat any `Applied` without receipt as hard failure.

**Desired future logs** (names illustrative, NOT existing log lines):

```text
[LLM_DIPLO] offer_peace draft request_id=... save=... actor=... target=... war_key=... mode=dry_run
[LLM_DIPLO] offer_peace preflight request_id=... eligible=true|false reason=... state_revision=...
[LLM_DIPLO] offer_peace response proposal_id=... revision=... verdict=accept|reject|counter|silence
[LLM_DIPLO] offer_peace bellum_submit proposal_id=... verdict=pending|denied|applied receipt=...
[LLM_DIPLO] offer_peace public_event proposal_id=... published=true receipt=...
```

**Unexpected log/state to eliminate in later live tests:** `Foreign treaty applied` without an accepted and ratified linked LLM proposal; unrequested `Foreign treaty parley queued` from Native autonomy; `War Score forced foreign peace` in LLM-owned normal foreign wars; `MakePeaceAction.Apply` with no authorized receipt; duplicate applied treaty / public event; CR "peace signed" for a pending proposal.

### 19.4 CHANGE BOUNDARY AND NEXT DECISION

**ROOT CAUSE:** current Native diplomacy combines automatic offer drafting, ratification, execution and Revamp feature gating; a simple prompt action cannot safely target the existing automatic path.

**TOUCH NOW:** this architecture Markdown section ONLY, on the docs branch.

**DO NOT TOUCH NOW:** Native production code, public Bellum API, old 1.4.8 build gates, CR source, Relay backend/Relay Bridge, AI Influence Bellum Bridge, CRBellumBridge prototype branch, save types, `main`, releases.

**MUST FIX IN FUTURE:** expose legal treaty **preview** and idempotent **submission/receipt** while preserving Bellum's gameplay validation; ensure LLM controls initiation, responses and proposed terms; define autonomous foreign-peace fences separately from internal civil-war mechanics and mandatory emergency paths.

**MUST NOT CHANGE:** council ratification semantics, player choice, lawful term validation, existing hostage/tribute/territory/prisoner effects, old save compatibility, ordinary non-LLM behavior when no authority is registered.

**Next isolated stage:** inspect all direct and indirect callers of `TryQueueParley` / `ApplyTreaty(Core)`, save fields and treaty term validation before defining exact production file/function touch set. No implementation in this stage; first finish the pending Bannerlord 1.5.7 compatibility build and game tests before claiming combined integration ready.

**Documentation diff only.** Test cases are defined but **not run**; no build/live log evidence exists for this new LLM negotiation contract.


## 20. OFFER_PEACE ownership call-chain and save-boundary audit — 2026-11-15 (ANALYSIS ONLY)

**Repository checked:** `AIRebelRelay/BellumCivile`, Native main HEAD `59b2aee8268cf1633e052e6b44e1cdba0e3c15fb`. **Docs branch only**; production untouched. These are source-inspected call sites in named files, not a claim that every foreign-policy path in all 999 C# files has been verified. CR 2.8.10 `CrDiplomacy` affects only explicit CR-originated actions, not all TaleWorlds AI decisions.

### 20.1 Verified call chain and consumers

```text
Native autonomous proposal source:
  WarPeaceRevampBehavior.TryCreatePeaceDecision
      -> ForeignTreatyBehavior.TryQueueAiParley
  WarScoreBehavior.TryResolveForeignWhitePeaceFromProposal
      -> ForeignTreatyBehavior.TryQueueAiParley
  WarScoreBehavior.ResolveQueuedTerminalWarScore (forced)
      -> ForeignTreatyBehavior.TryQueueAiParley
      -> (if failed) foreign terminal fallback may enter ResolveTerminalConflict
         -> BellumPeaceResolutionContext -> MakePeaceAction.Apply

Player/other-mod-integration entrypoints:
  PeaceParleyEntryPointPatches (courier, diplomacy tab, vote notification,
      post-notification retirement; multiple paths)
      -> TryQueuePlayerParley or TryOpenPlayerParley or TryQueueDeferredPlayerParleyOpen
  DiplomacyRuntimeCompatibilityPatches (Diplomacy mod peace entry)
      -> TryOpenPlayerParley
  PeaceParleyVM -> TryReplacePlayerDraft / TrySignPlayerParley / TryRejectPlayerParley
                  / TrySetPlayerVote

Shared queue and draft logic — all within ForeignTreatyBehavior:
  TryQueueAiParley              -> TryQueueParley(automaticRequest=true)
  TryQueuePlayerParley          -> TryQueueParley(automaticRequest=false)
  TryOpenPlayerParley           -> TryQueuePlayerParley [if missing] -> EnsureProposalHasDraft
                                  -> TryPreparePendingProposalDraft
  TryQueueDeferredPlayerParleyOpen -> TryQueuePlayerParley
  TryQueueParley                -> DraftAiTerms [unless white peace]
                                  -> TryValidateCouncilControlledWhitePeace [automatic only]
                                  -> CanSubmitAutomaticDraft [automatic only]
                                  -> war.BeginParley, _proposals.Add
  ForeignTreatyBehavior.OnDailyTick
      -> ProcessTributes
      -> ResolvePendingParley (NPC-only or unattended player-vassal) 
          -> TryPreparePendingProposalDraft
          -> TryValidateCouncilControlledWhitePeace
          -> EvaluateRatification / SpendCouncilCommitments / SpendRulerOverride
          -> ApplyTreaty
  ForeignTreatyBehavior.TrySignPlayerParley
      -> TryPreparePendingProposalDraft (twice)
      -> EvaluateCouncil / WouldCouncilAccept / SpendCouncilCommitments
      -> ApplyTreaty
  ApplyTreaty -> ApplyTreatyCore (direct or through HostagePactBehavior.DeliverTreaty)
      -> royalty/marriage/territorial, gold, tribute, prisoner, claim,
         diplomatic and political term effects
      -> BellumPeaceResolutionContext -> MakePeaceAction.Apply / ApplyByKingdomDecision
      -> Accepted/Applied status + news, court consequences, rebel-resolution queue
  ForeignTreatyBehavior.OnHourlyTick (not gated by Revamp)
      -> HostagePactBehavior.RecoverTreatyDeliveries
      -> PendingTreatyRebelResolutionRecord processing
```

**Exact implementation-local call sites:** `TryQueueParley` is `private` and invoked only by `TryQueuePlayerParley` and `TryQueueAiParley` inside inspected `ForeignTreatyBehavior.cs`; `ApplyTreaty` is `private`, called by `TrySignPlayerParley` and `ResolvePendingParley`; `ApplyTreatyCore` is `private`, called by `ApplyTreaty` directly or through the hostage delivery callback. The named *public* entrypoints have the observed external consumers above, but should be rechecked against a complete call-graph/assembly scan before editing shared behavior.

### 20.2 Why reusing current code directly is unsafe

1. **Native still originates the draft:** `TryQueueParley` constructs `TreatyProposalRecord` with a new GUID, derives winner/loser from War Score, and either creates `WhitePeace` or calls `DraftAiTerms`. An existing pending proposal returns `true` without proving the caller's request identity or accepting its desired terms. Therefore its success bool is **not** an LLM request receipt.
2. **Silent semantic substitution:** `EnsureProposalHasDraft` populates an empty proposal from Native AI. `TryPreparePendingProposalDraft` can normalize with `repairStateDrift:true` and `allowOverBudget:true`; on failed repair it **replaces the draft with white peace**. `TreatyDraftService.TryValidateAndNormalize` itself treats an empty terms list as white peace. LLM submission must require explicit typed terms and a strict *no-substitution/no-white-peace-fallback* mode, with clear `DENIED_STALE_TERMS` and a chance to renegotiate.
3. **Voluntary white peace restriction:** `TryValidateCouncilControlledWhitePeace` currently requires a Bellum mutual-eligibility rule for NPC-only non-forced cases. It does not treat bilateral LLM acceptance as sufficient. Whether genuinely agreed voluntary white peace may override that heuristic is a **game-rule decision requiring a separate regression design**; never bypass by marking a request `forced=true`.
4. **Revamp disabled disables unrelated services:** `ForeignTreatyBehavior.OnDailyTick` returns before `ProcessTributes`, and before pending-parley progression. `WarScoreBehavior.CanRegisterConflict` cannot register standard foreign wars when Revamp OFF, and the AII integration ledger is accounting-only. Setting Revamp ON to gain these services also revives competing autonomous initiative. Distinguish world-state simulation, payment maintenance, lawful validation, proposal/origination, and commit.
5. **Not a single atomic operation:** `ApplyTreatyCore` effects occur around `MakePeaceAction`, and `HostagePactBehavior.RecoverTreatyDelivery` states there is **no generic rollback** for already-transferred gold/land. Existing `TreatyProposalRecord.State` is `ParleyPending|Accepted|Rejected|Applied|Cancelled`; it is not a full persisted Bridge negotiation/transaction ledger.
6. **Save compatibility/high-risk state:** `ForeignTreatyBehavior.SyncData` stores `BellumCivile_ForeignTreaty_Proposals`, `_Tributes`, and `_RebelResolutions`; `WarScoreBehavior.SyncData` stores `BellumCivile_WarScore_Wars`. `BellumCivileSaveDefiner` has stable type IDs: `TreatyTermRecord=34`, `TreatyProposalRecord=35`, `TreatyTermType=38`, `TreatyProposalState=39`, plus list containers. `TreatyProposalRecord` already has 23 SaveableField IDs, internal `DraftRevision`, influence flags, ratification support and a terminal consequences guard. Never reorder/repurpose fields or enum ordinal values.
7. **Player and mods share treaty infrastructure:** Harmony redirects in `PeaceParleyEntryPointPatches` and `DiplomacyRuntimeCompatibilityPatches` preserve player decisions/UI and retire mirrored vanilla votes when Revamp owns a war; `PeaceParleyVM` edits/signs/rejects drafts. No blanket disabling or changing semantics of `TryQueuePlayerParley` or `TrySignPlayerParley`.
8. **CR gateway is not universal:** CR 2.8.10 `CrDiplomacy.RegisterAuthority` can hold a CR-originated `MakePeace` as `Pending`, but Native, TaleWorlds and other mods can still have other action paths. Any new enforcement must be explicit about scope, fail-open/fail-closed, emergency story exceptions and true terminal receipts.

### 20.3 Proposed minimal architecture (NOT implemented)

**Split the orchestration from Native settlement, not the gameplay implementation:** 

- **Bridge private ledger:** `saveId`, `threadId`, `requestId`, speaker/target Hero/Kingdom StringIds, target `warKey` and baseline revision, offered term revisions, each side's LLM/player replies, expiry, source, exact Native receipt. Store this in the Bridge (separate from Native treaty save types). Replayed or stale requests must resolve idempotently, never re-run settlement effects.
- **Native legal preview:** an explicit campaign-thread snapshot of allowed action families, valid targets, war score and proposed term validity. Preview must be demonstrated side-effect-free and not call Native AI drafting or spend influence. A potentially mutable normalizer is **not automatically a read-only preflight**.
- **Native negotiated-draft entry:** separate from current `TryQueueAiParley`; consume exact explicitly approved term list and external provenance, validate current hostility/campaign/authority, create or resume a tracked treaty proposal, then use the **existing** council/ratification/settlement system after a full diff/caller audit. Do not add another implementation of treaty payouts or prisoner/fief transfer.
- **Native outcome receipt:** return `Pending|Denied|Applied` (with exact proposal/request/war identity and reason), based on observed post-commit state and applied-clause evidence. Do not treat a successful queueing bool, `Accepted` before actual hostility change, or CR `PassThrough` as proof of signed peace. Save/recovery must reconcile partial side effects and avoid replay.
- **Separate foreign-policy ownership seam:** suppress only *unrequested normal foreign-policy initiative/automatic foreign resolution* under LLM mode; keep internal civil-war settlement, existing courts, player parley and gameplay maintenance. Terminal War Score and unavoidable story/realm collapse are separate policy questions; do not silently override.

**Implementation boundary must be re-approved after the outstanding 1.5.7 ABI/build work:** candidate file/function seams in `ForeignTreatyBehavior.cs` (new explicit path + reuse settlement internals, scoped gates), `WarScoreBehavior.cs`/`WarScoreAiInfluenceForeignLedger.cs` (foreign-war tracking and initiative fences), `BellumIntegration*.cs` (new versioned public contract), **new Bridge-owned persistence**. These are hypotheses, not a license to edit all these files in one patch.

### 20.4 Stage regression contract

- **Positive:** LLM-created valid treaty `OFFERED` → target `ACCEPTED_IN_PRINCIPLE` → Native `ParleyPending` → councils ratify → exactly one `Applied` with actual peace, actual term effects and one public announcement.
- **Negative:** target rejects/silent/counteroffers, council rejects, insufficient influence/WS, changed ruler or war state, stale prisoner/fief, quest-blocked peace, duplicate `requestId`, duplicate callback or save-load replay: no phantom peace, no double cash/fief/custody transfer, no duplicate public news.
- **Neighbor:** vanilla player peace UI, Diplomacy mod peace entry, council vote redirects, old AII accounting-only war ledger, forced terminal mechanics until explicitly revised, internal feud/civil-war resolution, existing tribute maintenance, hostage delivery/recovery, migrated saves.
- **Strict terms:** do not silently convert negotiated treaty into `WhitePeace`, do not automatically re-draft or add clauses, and do not treat `TryQueueParley=true` as signed receipt.
- **Suggested future logs** (not currently implemented): `[LLM_DIPLO] treaty_prepare`, `draft_validation`, `ratification_pending`, `receipt_applied|receipt_denied`, `recovery_reconciled` with stable `save_id/request_id/proposal_id/war_key`. Unexpected: `Pending treaty draft could not be repaired and was replaced by white peace` on LLM-owned proposals, `Foreign treaty applied` with no authorized request, `War Score forced foreign peace` in LLM-owned normal international war, accidental second `MakePeaceAction.Apply`.
- **Live game gate (not run):** verify no signed treaty without CR-relevant/public receipt, both ruler personalities and private knowledge, player-ruler consent, real council influence spending, payments/hostages/territory, load/save during pending, game log comparison.

### 20.5 Stage boundary / verdict

**ROOT CAUSE:** direct LLM reuse would cross the Native's blended autonomous-draft, validation, ratification and commit path; Revamp OFF disables unrelated treaty maintenance and ordinary war-score tracking. **TOUCH NOW:** only this Markdown architecture document. **DO NOT TOUCH NOW:** any production C#, CR, Relay, either bridge, MCM defaults, Native save metadata, main or shipping branches. **MUST FIX LATER:** proof of explicit term acceptance and correct Native settlement receipts without Native deciding diplomacy. **MUST NOT CHANGE:** player choice, civil wars, client state rules, term legality, quest protections, influence/council semantics, current save compatibility.

**Next bounded stage recommendation:** specification/fixture design for a Native **read-only `OFFER_PEACE` eligibility + draft preview**, after separating what is strict law from what is merely a Native NPC willingness heuristic. Do not yet build a direct treaty commit adapter; this audit has demonstrated several important consumers and non-atomic recovery paths requiring standalone validation.

**Evidence:** source-level inspection + docs diff audit only; no test execution, game logs or compile in this stage.

## 21. OFFER_PEACE read-only preflight — capability versus legality (2026-11-15)

**Status:** architecture/fixture contract ONLY, not production implementation. Source audited at `AIRebelRelay/BellumCivile` main `59b2aee8268cf1633e052e6b44e1cdba0e3c15fb`; CR API remains 2.8.10. Keep Bannerlord 1.5.7 ABI work and this diplomacy work separate. No executable API, unit tests, compilation, model request or in-game test produced.

### 21.1 ROOT CAUSE: existing “eligibility” checks encode unrelated decisions

The current Native design does not offer a side-effect-free, LLM-owned `OFFER_PEACE` preview. Several different meanings are conflated:

| Existing source | Directly observed semantics | Preflight classification |
|---|---|---|
| `ClientKingdomBehavior.CanMakePeace` | Checks suzerain restrictions, but returns **true** if realm inputs are null or `IsSynchronizingDiplomacy`; cannot alone prove valid parties | HARD RULE only **after** explicit input/state validation; a true result is not complete authorization |
| `StorylineWarProtectionHelper.IsPeaceBlocked` | Protects third-phase Story Mode wars; uses optional reflection and may fail/disable its detection with a one-time log | HARD STORY restriction when established; treat ambiguous unavailable/reflection failure explicitly, not proof of unprotected peace |
| `ClientKingdomBehavior.IsAuxiliaryClientWar`, permanent-realm/foreign-war classification, `Kingdom.IsAtWarWith` | Current hostility and realm authority constraints | HARD WORLD/OWNERSHIP checks |
| `WarScoreBehavior.GetActiveWar` | Returns an existing tracked record, not arbitrary vanilla war data; `CanRegisterConflict` refuses ordinary foreign registration when Revamp OFF | EXECUTION READINESS. Missing record is **UNKNOWN/NOT_READY**, not automatically “peace illegal” |
| `WarScoreBehavior.IsMutualWhitePeaceEligible` | Depends on `ShouldProcessWar` / Revamp, cooldown, War Will and exhaustion | Native autonomous **WILLINGNESS/automatic white-peace heuristic**, not a universal legal veto on two LLM sovereigns negotiating |
| `WarPeaceRevampBehavior.GetWarWill`, `GetRankedTargets` | Lazily writes cached initial Will / ranked target state; `PeekWarWill` is the non-inserting alternative | ADVISORY political context, not allowed in a strictly read-only preview unless proven non-mutating |
| `ForeignTreatyBehavior.EvaluateCouncil` | Calls `GetOrCreateCouncilSnapshot` which populates `_councilSnapshots`; ratification service calls `GetWarWill` | FUTURE RATIFICATION forecast only, **not** part of the first pure preflight |
| `TreatyDraftService.TryValidateAndNormalize` | Validates typed clauses and recalculates costs; empty input becomes `WhitePeace`, and generated `TreatyTermRecord` may differ from input even without `repairStateDrift` | Useful candidate legal checker **only after** strict input guard, semantic-diff check, side-effect audit and tests; never pass repaired terms to execution without a new agreement |
| `TryQueueAiParley` / `TryQueueParley`, `CanSubmitAutomaticDraft` | Generates proposal, native terms, possible council decisions, changes war/proposal state | **FORBIDDEN during preflight** |

`TreatyWarScoreAccounting.Calculate` is suitable for a pure numeric term-cost calculation **when** terms and a real Bellum War Score budget are available. Do not invent zero score/budget or pretend a foreign war is untracked because the political situation is tranquil.

**Important follow-on risk:** `ForeignTreatyBehavior.OnDailyTick` returns before `ProcessTributes` when Revamp OFF. Preview must not toggle Revamp just to obtain treaty services, and cannot claim that future installment payments will run until maintenance is separately enabled and tested.

### 21.2 Conceptual public API contract (NOT PRESENT IN CODE)

```yaml
operation: PreviewForeignPeace                # proposed name, NOT an existing BellumIntegration API
input:
  saveId: "actual campaign identifier"
  actorHeroId: "actual ruler/authorized speaker id"
  fromKingdomId: "speaker's kingdom StringId"
  toKingdomId: "other kingdom StringId"
  draftTerms: null                            # null = no draft yet; [] = INVALID, never implicit white peace
  expectedWarKey: null                        # optional revision guard for second request
output:
  legality: allowed_to_propose | blocked | unknown
  executionReadiness: ready | not_ready | unknown
  politicalAssessment: advisory_only         # war score, exhaustion, council risk; NEVER a commit
  hardReasons: ["coded reason key", "..."]   # known hard blocks, not speculative LLM advice
  readinessReasons: ["war_score_tracker_missing", "..."]
  verifiedActorAndTargetIds: ["hero", "realm", "realm"]
  currentWarKey: null                        # only if real tracked war exists
  trackedConflictType: null                  # never manufacture ForeignWar on missing record
  draftReview: not_requested | valid | invalid | unknown
  normalizedTermsForDisplay: null            # no silent replacement into a signed treaty
  observedGameDay: 0
  observedStateRevision: null                # design goal; must map to actual Native revision source
  mayExecuteImmediately: false               # preview never applies anything
```

Only return `legality=allowed_to_propose` when an active campaign, authoritative actor, two existing suitable realms, genuine ongoing hostility and required quest/client constraints have been positively established. `legality=allowed_to_propose` means the LLM **may ask**, not that the other ruler, court, or game has consented.

- `executionReadiness=not_ready` with Revamp OFF and no ordinary foreign `WarScoreRecord` is a separate **integration blocker**, not diplomatic illegality. Do **not** call the old AII-specific `TryRegisterAiInfluenceForeignWar` to paper over it. The Bridge can still produce a narrative `PUBLIC_STATEMENT`; it cannot promise settlement execution.
- `blocked` on active Story Mode restriction, client suzerain restriction, invalid/nonparticipating actor, non-hostile pair, eliminated/rebel/temporary realm or internal civil-war/claim feud when the operation is defined for ordinary international peace only. The correct internal-war handler remains untouched.
- `unknown` for stale/unavailable campaign data, unclear authority, or an unverified mandatory safety check. No permissive execution from unknown.
- The **LLM-facing capability card** must keep `NO_ACTION` and nonbinding `PUBLIC_STATEMENT` available; voluntary peace and a complex treaty are separate selectable intentions and require explicit terms. With no draft, the model may ask for a *discussion*; `[]` is invalid, and `WhitePeace` must be an explicit sole clause.
- Bellum's `War Will`, relative strength, exhaustion, current council politics and `IsMutualWhitePeaceEligible` can be supplied as **advisory factors**, with unavailable fields honestly omitted. They must not be hardcoded into LLM policy choices or silently override the political intent of either ruler.

**Draft preview (separate, after an actual proposal exists):** require exact structured `TreatyTermType` and target IDs; no implicit no-terms-to-white-peace; no implicit `forced=true`; no `DraftAiTerms` and no `CanSubmitAutomaticDraft`. Invoke clause legality/availability only in a demonstrated non-mutating mode; derive legal recalculated costs with `TreatyTermCostModel` and `TreatyWarScoreAccounting`, compare material terms against the submitted revision. A meaningful discrepancy must return `invalid/needs_counteroffer` rather than silently change gold, prisoner, holding, duration, or territory. Any accepted narrative must have a matching exact validated draft at submission time.

### 21.3 Side-effect and caller boundary

**Read-only invariant:** on campaign/main thread the preview may read immutable snapshots or proven-pure calculations; it must not queue `WarScoreRecord`, call `BeginParley` / `BeginResolution`, add `TreatyProposalRecord`, modify `_proposals`, `_councilSnapshots`, `_warWillByClanId`, save-type metadata, gold, influence, fiefs, prisoners, relations or CR memory/feed. Existing lazy cache initialization and reflection one-time logs are to be identified explicitly; “does not call MakePeace” alone is not enough to establish purity.

**Known consumer risk:** `GetWarWill` also feeds ratification; `GetOrCreateCouncilSnapshot` stabilizes council assessments for a given proposal; `TreatyDraftService` also serves the player UI and existing automatic draft flow. Do **not** change their shared semantics to satisfy preflight. A new narrow read-only wrapper/snapshot path, if needed, is safer than a global helper modification. Keep actual Bellum ratification unchanged at commit time.

**Campaign freshness:** capture source campaign, actor/target identities, live hostile pair, actual war key/side, relevant revision and timestamp. This output is **never a commit permission**; recheck every hard condition and exact terms in the later Native submit path on campaign thread. RPC/LLM completion may arrive after death, throne transfer, occupation, save switch, or a newly blocked quest.

### 21.4 Positive and neighboring regression contract (BEFORE ANY CODE)

| Fixture | Expected result / unchanged behavior |
|---|---|
| Two real rulers, valid ordinary foreign hostility, real tracked record | `allowed_to_propose`, capabilities+factual pressure; still `mayExecuteImmediately=false` |
| Same hostility with Revamp OFF, no tracked record | Legality evaluated separately; `executionReadiness=not_ready`, no invented `warKey`/War Score |
| Eligible ruler asks for talks, no terms yet | `draftReview=not_requested`; no automatic white peace |
| Model explicitly selects sole `WhitePeace` clause | `draftReview` can be checked as an explicit request; no automatic permission to conclude |
| Empty `[]` or invalid/duplicate target/terms, stale fief or prisoner | `invalid`, no fallback or replacement and no state mutation |
| Terms exceed factual War Score budget | `invalid` or `not_ready` (missing budget), not invented affordability |
| Non-hostile, temporary/rebel realm, internal feud/civil war, dead or dethroned ruler | Excluded from ordinary foreign-peace path without touching the internal/feud settlement |
| Story quest block / client-suzerain restriction | `blocked` with exact reason; no generic Native pass-through |
| Player-ruled side | No AI impersonation of the player; preview does not pre-approve player's response |
| Repeated preflight, before/after campaign save, concurrent LLM response | Same observed facts → same decision; no additions to saved war/proposal/council or Will dictionaries, no duplicated CR Feed, no cross-save context |
| Existing player parley, influence vote, old AII ledger, internal-war resolution | Existing paths and outcomes unchanged; this API remains opt-in and read-only |

**Target test instrumentation (NOT implemented):** compare before/after snapshots of `_wars`, `_proposals`, `_councilSnapshots`, `_warWillByClanId`, finances, influence, realm hostility and related save data. Verify fixture assertions without loading arbitrary player saves. A future controlled game test should emit `[LLM_DIPLO] peace_preview actor=... target=... legality=... execution=... war_key=... reason=...` and must **not** emit `Foreign treaty parley queued`, `Foreign treaty applied`, `War Score forced foreign peace`, `MakePeaceAction.Apply` because of *preview alone*.

### 21.5 Surgical stage decision

**ROOT CAUSE:** mixed legal/AI-willingness/revamp gates and mutating lookups prevent truthfully advertising Bellum capabilities to LLM.

**TOUCH NOW:** only `docs/architecture/CR_2_8_9_BELLUM_LLM_DIPLOMACY_MASTER_PLAN.md` on `docs/cr289-llm-diplomacy-architecture-2026-11-14`.

**DO NOT TOUCH NOW:** `TreatyDraftService.cs`, `TreatyRatificationService.cs`, `ForeignTreatyBehavior.cs`, `WarScoreBehavior.cs`, `WarPeaceRevampBehavior.cs`, `ClientKingdomBehavior.cs`, `BellumIntegration*.cs`, all Bridge/Relay/CR code, Native save types, MCM defaults, `main`.

**MUST FIX LATER:** legally meaningful status independent of technical readiness and AI willingness; strict and idempotent typed draft preview; read-only purity under test; safe missing-score behavior with Revamp OFF.

**MUST NOT CHANGE:** political initiative ownership, all working player diplomacy, legal restrictions, Native council outcomes and influence, treaty effects, War Score, client/civil-war/quest protections, old AII bridge ledger and save compatibility.

**NEXT ISOLATED STAGE:** build **pure fixture contracts / test harness for eligibility** using a deterministic snapshot, not a production Bellum integration. Only after positive+neighbor regression proof should a game-thread Native preview API implementation be proposed. No production patch has been attempted here.


## 22. OFFER_PEACE preflight contract fixtures — Stage 4 (2026-11-15)

**Status:** implemented **test-only**, not a Native Bellum feature. The runnable independent Python 3 standard-library contract oracle and a fixed 32-case JSON matrix now exist on this docs branch:

- `Tests/LLMOfferPeacePreflight/contract.py` — deterministic, pure **illustrative contract oracle**. It does **not** call TaleWorlds, CR, Bellum code, model/Relay, or a real game. It asserts immutable fixture inputs, repeat determinism, fixed input schema, and `mayExecuteImmediately=false`.
- `Tests/LLMOfferPeacePreflight/fixtures.json` — fixed source-independent input/expected-output scenarios. Its `nativeGatewayAvailable=true` examples deliberately describe a **hypothetical future Native integration**; **such an API does not yet exist** in main.

Run locally from the repository root: `python Tests/LLMOfferPeacePreflight/contract.py` (or `py -3 Tests\LLMOfferPeacePreflight\contract.py` on Windows). No game installation, .NET SDK, modules, network or additional Python packages are required.

### 22.1 Contract and explicit boundaries

Three intentionally **independent** dimensions:

- `legality = allowed_to_propose | blocked | unknown` — whether an NPC ruler may **offer** ordinary foreign peace, given verified actor authority, active hostility and hard world/story/client constraints. No LLM impersonation of a player.
- `executionReadiness = ready | not_ready | unknown` — whether a **separate** hypothetical negotiated-treaty gateway and an actual `ForeignWar` record would be available. Revamp flag alone must neither grant nor deny legality/readiness; current Native has no new gateway, so the real integration remains `not_ready`.
- `draftReview = not_requested | valid | invalid | unknown` — `terms=null` is *not requested*; `terms=[]` is invalid; explicit sole `WhitePeace` is unambiguous; a pending native verifier can supply `nativeDraftValidation` as a fact, but **this test oracle does not implement Bellum's clause law**. Matched actual War Score budget and a semantic-diff check are necessary before considering a structured draft valid.

`responseAuthority = npc | player | unknown` is additionally exposed. Unknown player/AI ownership **blocks the automatic path** (`legality=unknown`) until resolved; a player-ruled *recipient* must answer as a player, not a synthetic LLM ruler. Actual acceptance, council ratification and settlement are never invoked by preview.

**Scenarios:** 32 fixed cases including ordinary foreign war with Revamp OFF and no tracker, hypothetical future gateway, Revamp ON without a gateway, invalid/nonhostile/temporary/internal realms, Story Mode, client suzerain, dethroned/dead/player actor, player recipient and unknown recipient authority, stale/unknown quest or campaign information, no terms vs explicit WhitePeace vs mixed WhitePeace, stale fief/prisoner verifier, changed normalization, missing/overrun WS budget, mismatched tracked conflict, and a valid but **nonexecuting** treaty draft.

**ROOT CAUSE/Why tests exist:** Native `TryQueueAiParley`, `TryPreparePendingProposalDraft`, `IsMutualWhitePeaceEligible`, `GetWarWill` and Revamp guards mingle AI policy, game legality, mutable data and treaty execution. These fixtures establish **expected request classification without reusing or cloning AI Influence code**. They are a design gate, **not** evidence that Native game behavior passes.

### 22.2 Evidence and regressions

**Observed locally:** Python 3.13 test run on the authored equivalent oracle/fixture matrix: `LLM_OFFER_PEACE_CONTRACT fixtures=32 passed=32 failed=0`; Python compilation check passed. One intentionally corrupted fixture (`allowed_to_propose` replaced with `blocked`) exited with status 1 and correctly reported a failure. The **committed** GitHub files were read back and checked for the same fixture count and key invariants; actual game, .NET harness and CI workflow were **not** run. CI not triggered to avoid unnecessary Actions spending.

**Protect adjacent features (future binding):**
- Ordinary Native player parley/vote and Diplomacy mod redirects still use their existing paths.
- Client realms, internal war/claim feud, storyline protection and terminal war score remain untouched.
- `TreatyProposalRecord` save field IDs, war/tribute data, hostage recovery, council influence and existing AII accounting-only war ledger unchanged.
- A missing war tracker, unknown ruler authority or unknown quest state may **never** be interpreted as success.
- `terms=[]` must **never** trigger auto white peace; preflight must never call Native `DraftAiTerms`, `TryQueueParley`, `BeginParley` or `MakePeaceAction.Apply`.

**MUST NOT CHANGE:** current Revamp defaults, treaty validation semantics shared with player UI, existing kingdom decision handlers, settlement effects, public Feed/CR ownership, save compatibility or Native deployment identity.

**TOUCH:** only the two new files under `Tests/LLMOfferPeacePreflight/` and this architecture document **on the docs branch**. **DO NOT TOUCH:** all production C#, either Bellum/Relay Bridge, Relay, CR, `main`, release branch, workflows and existing tests.

**Expected later log when bound to Native:** `[LLM_DIPLO] peace_preview legality=... execution=... draft=... reason=... actor=... target=... save_id=...`. There must be **no** `Foreign treaty parley queued`, `Foreign treaty applied`, influence change or public signed-peace event from preview alone. At this stage no such runtime line exists; the only result is the contract-test PASS/FAIL summary.

**Next bounded stage:** review the bridge-facing Native snapshot data sources and identify the **smallest read-only API/DTO change** capable of satisfying these fixtures, together with an explicit nonmutating-per-method call audit. Only then implement against the **current checked HEAD** in a separate production stage after regression tests and game-version build gates; never copy the test oracle into game code.
