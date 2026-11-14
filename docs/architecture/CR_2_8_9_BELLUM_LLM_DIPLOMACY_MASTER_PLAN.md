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
- CR upstream main [\`c49c01c7\`](https://github.com/LogRaam/calradia-remembers/commit/c49c01c7f00d674768c1824512d8cf683e3b2db0): author identifies 1.5.7 + War Sails 1.3.7 as tested, 1.4.x untested.
- Upstream Bellum [\`8a08e0c0\`](https://github.com/Vonbalt/BellumCivile/commit/8a08e0c038a60030813c56eae39a5fbee0b75cb6) (\`main\`, “Prepare main for Bannerlord 1.5.7”); customized Native Bellum [\`59b2aee8\`](https://github.com/AIRebelRelay/BellumCivile/commit/59b2aee8268cf1633e052e6b44e1cdba0e3c15fb) (\`main\`, 1.4.11.1). **Neither source HEAD alone proves which source snapshot exactly built 1.4.12b distributed DLL.** Demand binary/source fingerprint before porting.
- Old Bellum Bridge [\`f362a4f7\`](https://github.com/AIRebelRelay/Bannerlord2-AiInfluence-BellumCivile/commit/f362a4f70786896b4160489bc1e3f448fdd0578e) has a literal \`<DependedModule Id="AIInfluence"/>\`; it is **not** CR-ready and must **not** be shipped unchanged in a CR-only launcher.
- **Important source-delta finding:** upstream 1.5.7 source has extra foreign parley guards for [\`AlliancePeaceRestriction\`](https://github.com/Vonbalt/BellumCivile/blob/8a08e0c038a60030813c56eae39a5fbee0b75cb6/AlliancePeaceRestriction.cs) and newer revisions of \`ForeignTreatyBehavior\` / \`PeaceParleyEntryPointPatches\`; our custom Bellum does not. The upstream \`CivilWarMakePeacePatch\` and \`WarDeclarationCouncilPatches\` were **text-identical** to our main during this targeted check.
- Upstream also contains \`VoluntaryPactProposalBehavior\`, \`VoluntaryPactAiBehavior\`, \`VoluntaryPactDecision\` and durable staged proposals for **peacetime hostage pacts** (two realm votes, target selection, delivery/recovery). Our 1.4.11.1 does not include these. **Which portion shipped in the exact 1.4.12b beta is unverified; upstream main contains ongoing work.** Do not write a second peacetime-pact system before finishing this audit.
- Our custom \`BellumIntegration.cs\` has additional public Court and provenance methods, and \`BellumIntegrationNpcCouncil.cs\` has no upstream counterpart at current main. **Do not overwrite our fork with upstream**; map forward changes separately with save/API/feature parity.

### 12.2 CR direct PEACE — confirmed source-level false-success risk (P0)

**Call path A (LLM mediated peace):**

\`CR 1:1 prose/interpreter → BannerlordGameStateBridge.Execute(action) → ExecuteMediatePeace → PeaceMediationPolicy.Evaluate (rank / regard / faction) → MakePeaceAction.Apply(leaderFaction,target) → immediately displays successful peace and returns ActionOutcome(success=true)\`.

Source: [\`ExecuteMediatePeace\`](https://github.com/LogRaam/calradia-remembers/blob/c49c01c7f00d674768c1824512d8cf683e3b2db0/CalradiaRemembers/GameState/BannerlordGameStateBridge.cs#L3024-L3100), [\`PeaceMediationPolicy\`](https://github.com/LogRaam/calradia-remembers/blob/c49c01c7f00d674768c1824512d8cf683e3b2db0/CalradiaRemembers.Logic/PeaceMediationPolicy.cs).

**Bellum intercept:** [\`CivilWarMakePeacePatch.ShouldAllowPeaceCall\`](https://github.com/AIRebelRelay/BellumCivile/blob/59b2aee8268cf1633e052e6b44e1cdba0e3c15fb/Patches/CivilWarMakePeacePatch.cs#L19-L100) is a Harmony prefix on \`MakePeaceAction.Apply\`. If this is **ordinary permanent foreign kingdom-vs-kingdom peace**, Revamp **ON**, and \`BellumPeaceResolutionContext.IsBellumPeaceResolution == false\`, it logs \`Blocked non-Bellum international peace\` and returns **false** (blocks the original). CR's post-call success text does not re-read war state, so it can claim a peace that never happened. **This is a source-level bug candidate with a deterministic causal chain; actual game manifestation and Harmony ordering remain to be verified.**

**Bellum's legitimate path:** [\`ForeignTreatyBehavior.ApplyTreatyCore\`](https://github.com/AIRebelRelay/BellumCivile/blob/59b2aee8268cf1633e052e6b44e1cdba0e3c15fb/Behaviors/ForeignTreatyBehavior.cs#L1864-L1935) applies terms and calls \`BellumPeaceResolutionContext.RunBellumPeaceResolution(() => MakePeaceAction.Apply...)\`, then marks the **native proposal** \`Applied\`. **Do not expose or invoke \`RunBellumPeaceResolution\` as a bypass API from an external integration**; it is a narrow Bellum commit guard, not proof of validated agreement.

**Other CR direct peace consumers (different semantics):**

1. [\`CouncilLift.SettleMakePeace\`](https://github.com/LogRaam/calradia-remembers/blob/c49c01c7f00d674768c1824512d8cf683e3b2db0/CalradiaRemembers/Chat/CouncilLift.cs#L2437-L2502) → \`MakePeaceAction.Apply\` → \`ledger.MarkApplied\` **without post-action verification**. Ordinary permanent foreign peace can be vetoed by Bellum but CR marks the council's pledge applied.
2. [\`ScenarioConsequenceExecutor.MakePeace\`](https://github.com/LogRaam/calradia-remembers/blob/c49c01c7f00d674768c1824512d8cf683e3b2db0/CalradiaRemembers/Scenarios/ScenarioConsequenceExecutor.cs#L160-L171) → \`MakePeaceAction.Apply\` → logs \`[SCENARIO] MAKE_PEACE\` without final-state readback. Authored scripted outcome needs separate authority policy, not an implied treaty acceptance.
3. [\`ArrestBehavior.LiftBounty\`](https://github.com/LogRaam/calradia-remembers/blob/c49c01c7f00d674768c1824512d8cf683e3b2db0/CalradiaRemembers/Arrests/ArrestBehavior.cs#L550-L564) can also call \`MakePeaceAction.Apply\` for the player's **independent clan** vs the bounty realm. **Do not blanket-disable it**: Bellum's ordinary-permanent-kingdom guard explicitly distinguishes this case.
4. A \`MakePeaceAction.ApplyByKingdomDecision\` has its own [\`CivilWarMakePeaceByDecisionPatch\`](https://github.com/AIRebelRelay/BellumCivile/blob/59b2aee8268cf1633e052e6b44e1cdba0e3c15fb/Patches/CivilWarMakePeacePatch.cs#L133-L161). Both overloads must be included in the seam contract.

**Important exclusions:** Civil-war, feud, client kingdom, StoryMode quest-protected and temporary kingdom transitions have separate Bellum ownership; do not solve the ordinary-foreign case by changing any shared \`MakePeaceAction\` semantics.

### 12.3 CR direct WAR / kingdom decisions (P0/P1)

| CR source | Real call chain | Bellum interception / risk |
|---|---|---|
| [\`PressForWarBehavior.Daily\`](https://github.com/LogRaam/calradia-remembers/blob/c49c01c7f00d674768c1824512d8cf683e3b2db0/CalradiaRemembers/Verbs/PressForWarVerb.cs#L275-L324) | Eligible lord's delayed pressing → recheck → \`new DeclareWarDecision(house,target)\` → \`Kingdom.AddDecision\` | **Promising candidate for reuse**: Bellum \`WarDeclarationCouncilPatches\` govern voting, influencer cost, ruler override; CR does NOT unilaterally declare. Check Bellum readiness, proposer, extra front, duplicate proposal and client guard in live game. |
| [\`LordStrategyBehavior.Weekly\`](https://github.com/LogRaam/calradia-remembers/blob/c49c01c7f00d674768c1824512d8cf683e3b2db0/CalradiaRemembers/Strategy/LordStrategyBehavior.cs#L150-L335) | Deterministic counterweight → \`DeclareWarDecision\` / \`MakePeaceKingdomDecision\` / \`StartAllianceDecision\` / \`ProposeCallToWarAgreementDecision\` → \`Kingdom.AddDecision\` | War uses Bellum voting path; **peace is high risk**: Bellum \`Kingdom.AddDecision\` parley redirection is **player-kingdom scoped** and cannot be assumed for unrelated NPC↔NPC realm pairs. A normal NPC peace vote may reach \`ApplyByKingdomDecision\` and be blocked by Bellum, yet CR emits news describing only the proposed step. Verify exact game call path before claim. Preserve player-realm skip. |
| [\`CouncilLift.SettleDeclareWar\`](https://github.com/LogRaam/calradia-remembers/blob/c49c01c7f00d674768c1824512d8cf683e3b2db0/CalradiaRemembers/Chat/CouncilLift.cs#L2361-L2420) | Player-led council → \`DeclareWarAction.ApplyByDefault\` → immediately \`ledger.MarkApplied\` | Bypasses a new \`DeclareWarDecision\` and thus Bellum War Will/council consideration; client \`ApplyInternal\` veto may still block. Needs delegated proposal OR explicit sovereign exception contract, not a global override. |
| [\`ScenarioConsequenceExecutor\`](https://github.com/LogRaam/calradia-remembers/blob/c49c01c7f00d674768c1824512d8cf683e3b2db0/CalradiaRemembers/Scenarios/ScenarioConsequenceExecutor.cs#L117-L171) | \`PRESS_FOR_WAR\` may call direct \`DeclareWarAction.ApplyByDefault\` after pure ruler test; \`DECLARE_WAR\` directly calls war action. | May bypass Bellum's full foreign-war proposer/War Will path; distinguish intentional scripted scenario from an LLM request. No automatic global blocking of authored story consequences. |
| [\`GiveHerAllService\`](https://github.com/LogRaam/calradia-remembers/blob/c49c01c7f00d674768c1824512d8cf683e3b2db0/CalradiaRemembers/Marriage/GiveHerAllService.cs#L180-L191) | Marriage outcome rolls into \`DeclareWarAction.ApplyByDefault(rival,herRealm)\` for same-culture rival kingdoms. | Adjacent systemic scripted war, distinct from diplomacy conversations. Needs separate regression test; should not be accidentally disabled. |

Bellum's generic hooks are **not a complete new-verb arbitration API**: [\`WarDeclarationCouncilPatches\`](https://github.com/AIRebelRelay/BellumCivile/blob/59b2aee8268cf1633e052e6b44e1cdba0e3c15fb/Patches/WarDeclarationCouncilPatches.cs) apply to **\`DeclareWarDecision\`** votes; [\`BlockVanillaForeignPolicyProposalsPatch\`](https://github.com/AIRebelRelay/BellumCivile/blob/59b2aee8268cf1633e052e6b44e1cdba0e3c15fb/Patches/BlockVanillaForeignPolicyProposalsPatch.cs) replaces **random AI proposal factory** decisions; [\`ClientKingdomDeclareWarPatch\`](https://github.com/AIRebelRelay/BellumCivile/blob/59b2aee8268cf1633e052e6b44e1cdba0e3c15fb/Patches/ClientKingdomDiplomacyPatches.cs) only adds a client-vassal legality gate to the direct war action. Direct-war decisions **can** start without going through \`KingdomDecision\` voting; check actual game/quest rules before designing a global veto.

### 12.4 Baseline regression contract (test before a single executable patch)

**Test cases and expected evidence (hypotheses until run):**

| Case | Expected owner/behavior | Required logs and game state |
|---|---|---|
| Bellum Revamp **ON**, ordinary two permanent kingdoms, CR \`mediate_peace\` | Bellum vetoes raw \`Apply\`; **no peace**, while CR may falsely narrate success (reproduce before fix) | Bellum \`Blocked non-Bellum international peace\`; CR \`[ACTION] mediate_peace\`; war state still active. After integration CR must say **pending/denied** and Bellum own exact transaction. |
| CR council \`make_peace\` under same setup | No raw peace; CR current \`MarkApplied\` is suspect | \`[COUNCIL] lift: parley made peace\` without world-state peace is **unexpected**. |
| CR scripted \`MAKE_PEACE\` under same setup | Should not fabricate completed peace; authored scenarios require tailored contract | \`[SCENARIO] MAKE_PEACE\` + actual war remains: unexpected successful outcome claim. |
| Bellum native foreign treaty signed through legal \`ApplyTreatyCore\` | War ends exactly once; terms (fiefs/money/hostages/tribute) applied once | \`Foreign treaty applied; war=... proposal... status=Applied\` (check actual log format), exact proposal/war/terms before/after |
| Revamp **OFF** ordinary peace | Existing vanilla path preserved | No Bellum foreign veto, vanilla peace works when legal |
| CR independent-clan bounty cancellation | Existing criminal-law cleanup preserved | \`[ARREST] ... bounty lifted\`, correct criminal war state; **not** blocked merely by kingdom-vs-kingdom fence |
| CR \`press_for_war\` delayed | **One** \`DeclareWarDecision\`, Bellum support/votes/mandate decide | \`[WARPRESS] ... proposes war\`; any war start only after proper resolved decision; no illegal additional front |
| CR \`LordStrategy\` NPC war/peace/alliance | CR files at most one step, Bellum owns foreign results | \`[STRATEGY]\` must be **proposal** news; if NPC \`MakePeaceKingdomDecision\` is vetoed, no false actual peace; no duplicate treaty |
| CR war council/Scenario direct war | Only declared when **authoritatively permitted**; protect scripted routes | Actual war state equals announcement, Bellum client and quest rules respected |
| Civil war, feuds, secession, clientage, StoryMode protected war, call-to-arms, save/load | Existing distinct ownership and special guards unchanged | No ghost realm, double vote, erased treaty, double term, missing spouse/hostage or overwritten war score |

**No live game access in this stage.** Test matrix above is an **execution contract**, not a report of passing tests.

### 12.5 Upstream 1.4.12b migration: safety boundary

**DO NOT import current upstream main wholesale.** Target upstream 1.5.7 sources/binary fingerprint at **the exact shipped 1.4.12b**, then:
1. Compare full source tree to our 1.4.11.1 (not just version label): recent upstream \`AlliancePeaceRestriction\`, \`ForeignTreatyBehavior\`, \`PeaceParleyEntryPointPatches\`, new voluntary-pact and hostage save schema, dependency/ABI/War Sails diffs, and our unique \`BellumIntegration*\`/NPC Court APIs.
2. Keep 1.4.11.1's custom public APIs, vote/crown safety and save invariants explicitly. Record new-vs-local overlapping call sites and tests **before** any port. Source HEAD and release DLL may not be identical.
3. Once pinned, prepare **separate** 1.5.7 compatibility stage; build against the actual 1.5.7 TaleWorlds assemblies, not old stubs; exercise CR-only, upstream Bellum beta-only, **custom** Bellum-only, CR+custom Bellum in a **separate backup/test campaign**.
4. Do not launch old \`AIInfluenceBellumBridge2\` in the CR-only profile; it requires \`AIInfluence\`. No Relay Bridge or AI Influence code touched to work around this.

**Runtime smoke gates:** startup, game load/save/reload, 2 in-game weeks, one ordinary war vote, one Bellum AI peace parley, one player parley with treaty terms, one internal civil conflict (not combined with foreign war test), one CR 1:1 dialogue/letter/council, no duplicate political event, no \`HarmonyException\`/\`MissingMethodException\`/\`TypeLoadException\`/\`SerializationException\`. Startup success is **not** proof these pass.

### 12.6 API requests — updated priority / avoid premature broad intervention

**To LogRaam — P0 single priority:**
A narrowly scoped, backward-compatible **pre-commit diplomatic delegation** (e.g. \`TryHandleDiplomaticEffect(context)\`) for an external mod to return \`PassThrough | Rejected(reason) | Pending(txnId) | Applied(receipt)\` **before** CR's \`mediate_peace\` would call \`MakePeaceAction.Apply\`. CR must show "pending" on a merely queued treaty and not announce verified peace without a Bellum result. An action override cannot be registered using the current \`CrActions.Register\` because the builtin verb name is reserved by duplicate-registration checking. Discuss analogous safe hooks for CouncilLift and scenarios **after** identifying shared call sites and authored-script compatibility; do not change shared CR action semantics without author regression tests.

**To our Native Bellum — P0 minimum counterpart:**
A public **actor-scoped, thread-safe and idempotent** \`TryStartNegotiation\` / \`GetDiplomaticTransaction\` **on the existing ForeignTreatyBehavior owner**, returning a typed \`Pending/Rejected/Applied\` receipt and exact \`WarKey+ProposalId+DraftRevision+TermsFingerprint\`; it must delegate validation and ratification to Bellum and **never** simply set \`BellumPeaceResolutionContext\`. The current \`ForeignTreatyBehavior.TryQueueAiParley\` is real and useful, but takes a native \`WarScoreRecord\` and is **not** a documented stable NPC-specific CR adapter contract.

**To LogRaam — later P1:**
A sanctioned NPC↔NPC persona-turn/offer-reply API with provenance, recipient authority, budget, rate limiting and cancellation. Use CR memory/letters where supported; today's external \`CrLetters\` delivery is player-targeted. Do not request this until reliable one-off mediation is proven.

### 12.7 Stage acceptance + precise edit boundary

**ROOT CAUSE (source-backed):** CR's built-in diplomatic post-action success/ledger writers assume raw TaleWorlds \`MakePeaceAction.Apply\` commits, whereas Bellum's foreign-peace prefix can suppress the call unless it owns an active treaty commit. Distinct direct war actions bypass ordinary vote construction. This is an **ownership and acknowledgement contract mismatch**, not a reason to remove Bellum's protections.

**TOUCH NOW:** only this Markdown design/audit document on \`docs/cr289-llm-diplomacy-architecture-2026-11-14\`.

**DO NOT TOUCH:** upstream CR/LLM-service, Native Bellum \`*.cs\`, both bridges, Relay, AI Influence, live game and save files. Do not trigger CI for a docs-only stage.

**MUST FIX IN DESIGN:** exact traced call paths and neighboring consumers; upstream 1.5.7 vs local 1.4.11.1 delta and correct 1.4.12b release identity; minimum sanctioned API; positive and negative test contract.

**MUST NOT CHANGE:** vanilla fallback on Revamp OFF, Bellum treaty gate/ratification/War Score, independent criminal-law peace, authored scripts, KingdomDecision votes, clientage, story protections, internal/civil war, save formats, NPC memory, active model routing.

**Evidence standard:** source inspection passed for named paths above; **no actual executable bugfix is claimed**, no compile or gameplay tests run. Before gameplay changes, finish full caller inventory of shared Battle/Peace APIs (including other modules and 1.5.7 TaleWorlds overloads) and identify precise patch touch boundary on up-to-date target HEAD. Only then proceed with one narrow implementation stage.
