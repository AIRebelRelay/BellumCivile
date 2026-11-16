# Bellum -> Bellum Bridge -> CR: initial read-only coverage map

2026-11-16. Bellum base bf1e019. This is an initial inventory, NOT complete API
coverage, a Bridge implementation, or approval to begin the next production stage.
All Bridge consumers and Relay routes below are proposals; current end-to-end delivery
has not been audited. Bellum Bridge is Bannerlord2-AiInfluence-BellumCivile;
it is NOT ai-rebel-relay-bridge.

## Confirmed surfaces in Bellum

| Source | Data/current access | Remaining contract audit | Proposed destination |
|---|---|---|---|
| BellumIntegrationVotes.cs; Behaviors/IntegrationVotes.cs | GetPendingVotes; CouncilAppointmentDecided; GetRecentCouncilAppointments | Vote/result correlation exists; recent result limit is 100; persisted queues need replay/dedup tests; not every court notification | Bellum Bridge council feed -> relevant CR news/context |
| BellumIntegrationPartitions.cs; Behaviors/IntegrationPartitions.cs | PartitionCompleted; GetRecentPartitions | Confirm all completed land transfers, retention, save/load and stable receipt IDs | Bellum Bridge territorial feed -> CR event |
| BellumIntegration.cs; Behaviors/CourtIntegrationSnapshots.cs | GetCourtAgendas; terminal eviction inventory; policy provenance/audience joins | Technical/private provenance is explicitly NOT a public feed; audit public/secret projection | Bridge-selected private knowledge/current context |
| BellumIntegrationNpcCouncil.cs | Council appointment options and intent queries | Intent != applied appointment; verify lifecycle and outcome joining | Intent/current state separately from completed news |
| BellumIntegrationNpcCrown.cs | Treason intent queries and active announcement | Source explicitly warns announcement is not proof of expulsion; no intent-as-outcome conversion | Knowledge-gated current politics |
| BellumIntegration.cs | GetHostageStatus | Snapshot available; audit capture/release/transfer event coverage | Hostage state and confirmed changes |
| BellumIntegrationLegitimacy.cs | IsIllegitimate plus explicit mutation APIs | Read status separately; mutation APIs never exposed as automatic LLM facts/actions | Character status, authorized action confirmations |
| BellumIntegrationLordships.cs | IsPlayerNominalFief; GetPlayerNominalFiefIds | Player-focused access; audit all-clan ownership, obligations and income | Land/status context |
| Behaviors/FeudalDeJureDriftBehavior.cs | GetActiveDrifts; GetDriftForTitle; GetDisplayAssessment | Public behavior reads exist; not stable detached DTOs or a demonstrated event feed; distinguish pause/reverse/complete | Compact current legal/control context |
| Behaviors/RegencyBehavior.cs | TryGetRegency; GetWard; GetRegent; GetLegalClanHead | Behavior reads exist; audit start/end/death/replacement notifications and DTOs | Current authority and verified succession news |
| BellumIntegrationForeignPeacePreview.cs | GetForeignPeaceEligibility | Eligibility preview is not concluded peace; inspect all treaty/war authority before actions | Read-only diplomatic eligibility |
| BellumIntegrationElections.cs; BellumIntegrationPledges.cs | Election persuasion and vote pledge APIs | These include commands; do not mistake command admission for outcome or knowledge | Explicitly authorized actions, separate receipts |

bellum-facade-inventory.csv indexes 33 facade declarations. This is syntactic
inventory only; behavior-level APIs and domains beyond this table still need review.
Next uncompleted domains: all court_notification producers, faction reactions,
succession/dethronement, civil wars/private feuds, treaties/clientage/tribute,
settlement control, family events and Bellum-owned economic changes. For each,
trace producer -> persisted record -> API -> existing consumers -> missing fields.
Do not infer absence from the facade scan alone.

## CR source distinction — do not implement against the wrong layer

The supplied GitHub repository LogRaam/LLM-Roleplay-Service currently has master
756bc512420bf009ae49cca37c6275360cb2633e. Its README identifies it as engine-agnostic
NpcMemoryService SDK, netstandard2.0, NOT the complete Bannerlord host mod.
Extension/ExternalVerbContract.cs calls the Actions API a spike and explicitly says
the public registration pipeline is not implemented in that layer.

Drive CalradiaRemembers/CalradiaRemembers/Docs contains EXTENSION_API.md and
HOWTO_WorldEvents.md. Read on 2026-11-16. That package's SubModule.xml identifies
v2.8.11, whereas the user reports a newer v2.8.12 on GitHub. Do not silently call
these the same build. Verify the actual 2.8.12 host binary/source and its exported
contracts before compiling a Bellum Bridge integration. No assumption that the
SDK repository alone proves host feature/version availability.

## Confirmed in the inspected CR documentation, pending installed-version verification

- Feed.Record/Update/Retract accept typed ExternalWorldEvent and stable event ID.
  FactionIds are kingdom IDs, HeroIds identify subjects, ActorHeroIds identify actors.
  PlaceId carries locality. Keep actor/subject distinction to avoid false player deeds.
- Feed.List(sourceMod) supports reconstructing the retained view; documentation says
  Category is not kept. Retention/dedup are bounded, so preserve delivery state in the
  correct integration owner when required; do not invent exactly-once guarantees.
- Documented admission limit: 20 records per SourceMod per game day. Full Bellum
  coverage therefore cannot mean one blindly forwarded CR record per internal event.
  Plan prioritization, batching/coalescing and truthful delayed delivery separately.
- KnownOnlyToThoseInvolved, KnownToHeroIds and HiddenFromHeroIds gate knowledge;
  CrWorld.KnownEvents(heroId) inspects it. Verify exact installed signatures first.
- CrPrompt.RegisterVariable + cr_patch/heard_now.txt supplies per-reply live facts
  on the game thread, with PromptVarFacts.NpcId and Lean. Documentation suggests
  roughly 800-1000 characters, about 300 when Lean, in an uncached tail.
  Candidate place for compact Bellum state; do not bloat static/cached world text.
- CrNpcMemory.AddMemory/GetMemories and CrConversation.Started/Ended exist in
  host docs. Memory injection is a durable recollection, not the default transport
  for every changing state. Do not duplicate events CR already records natively.

Likely split for later design: confirmed world changes -> CR Feed; current filtered
state -> live prompt variable; private durable experiences -> targeted memory only
where warranted. This is a design inference, not an implemented data path. Relay's
routing/filter role must be checked against actual Bridge and CR request assembly.

## Future regressions to define before production API work

Event completion versus intent, stable IDs across reload, replay, bounded retention,
late subscribers, campaign isolation, thread affinity, dead/missing entities,
temporary kingdoms, privacy and visibility, stale state correction/retraction,
throttle/backlog behavior and coexistence with native CR news. Do not expose
technical/private provenance as public lore or let an LLM response finalize state.
