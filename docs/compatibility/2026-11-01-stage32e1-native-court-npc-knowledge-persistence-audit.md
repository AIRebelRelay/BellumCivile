# Stage32E1 — NPC Court knowledge already persists in the Native save

2026-11-01. **Surgical source-backed audit and regression contract only. No production changes.** This stage explicitly avoids a second Relay ledger and any AI Influence 6.0.2 NPC JSON edits. Release backlog [Bellum Bridge #91](https://github.com/AIRebelRelay/Bannerlord2-AiInfluence-BellumCivile/issues/91).

## Exact repositories and HEADs
- **Native Bellum** \`AIRebelRelay/BellumCivile\`, audit branch \`audit/stage32e1-native-court-npc-knowledge-persistence-2026-11-01\` from Stage32C HEAD \`cb9cf0912c9e4af84f6af1ea4217877092d1bc71\`. Only new test and this document.
- **Bellum Bridge** \`AIRebelRelay/Bannerlord2-AiInfluence-BellumCivile\`, Stage32D-C \`8b82799629c4d6881690a5032e778a80f975f8c8\`. Owns private snapshot export after source+audience cross-check every 15 sec; **not** Relay Bridge.
- **Relay Bridge** \`AIRebelRelay/ai-rebel-relay-bridge\`, Stage32D-E1 \`b746cc54c6999e5a360ff7e299b704695370bf76\`. Owns exact live speaker probe and HTTP interception.
- **Relay** \`AIRebelRelay/ai-rebel-relay\`, Stage32D-E4 \`d394dabba8269b7afaddc3a8e300fff82de71c75\`. Explicit-L1-opt-in, dialogue-only historical Court vote overlay, default OFF, no persisted sidecar.
- No main merge, DLL, CI/Actions, released build or AII save modification.

## ROOT CAUSE / discovery
The proposed independent Relay NPC memory ledger would duplicate **existing, save-native historical evidence** and introduce an avoidable second source of truth. AI Influence 6.0.2's provided technical guide says NPC files are \`save_data/[Campaign.UniqueGameId]/Name (string_id).json\`, with \`KnownSecrets\`, \`ConversationHistory\` and \`DynamicEvents\`; the latter is automatically managed and world/role scoped rather than exact private-Court source scoped. AII JSON should not be externally written speculatively.

Crucially, \`campaign_epoch\` from Bellum Bridge \`BellumSessionManifestWriter\` is a fresh runtime UUID4, **not** the stable \`Campaign.UniqueGameId\` used by AII. Any Relay disk cache keyed only by epoch cannot be restored after restart; a cache keyed only by NPC name, kingdom or global path may leak between save branches. This is an architectural reason **not** to create a second ledger.

We found that Native Bellum **already** writes each source-specific historical component into the *game save*:
1. \`CourtAgendaBehavior.SyncData(IDataStore)\` invokes \`SyncCourtTerminalEvictionReceipts(dataStore)\`, \`SyncCourtPolicyVotePublicProvenance(dataStore)\`, \`SyncCourtPolicyVoteAudience(dataStore)\`.
2. \`CourtTerminalEvictionReceipts.cs\`: \`BC_CourtTerminalEvictionReceipts_v1\` and overflow counter.
3. \`CourtPolicyVotePublicProvenance.cs\`: \`BC_CourtPolicyVotePublicProvenance_v1\` and overflow counter, keyed by exact \`CourtAgendaRecord.IntegrationId\` and retaining action/result/obsolete mandate. (The legacy term "PublicProvenance" in the C# source is **not** permission to publish these private votes.)
4. \`CourtPolicyVoteAudience.cs\`: \`BC_CourtPolicyVoteAudience_v1\` and overflow counter; historical \`Hero.StringId[]\` from \`KingdomVoteAlignmentTracker.TryGetRecordedParticipants\`, not inferred by closeness, clan or role.
5. Read path: \`GetPolicyVoteProvenanceJoin(realm)\` joins terminal receipt + provenance by exact IntegrationId and semantics; \`GetPolicyVoteAudienceJoin(realm)\` joins only matching receipt/proof to historical voter IDs. If there is no audience entry in an older save: \`missingAudience++\`, skip that record — **never retroactively guess**. On invalid/corrupt/conflicted/overflowed maps, join returns no admissible records.
6. Bellum Bridge Stage32D-C reconstructs private snapshot on live native ticks after ALL realms pass health/dual join, then stamps with new **runtime** epoch. Relay Stage32D-D validates manifest→private snapshot→manifest; E4 queries the CURRENT source history on each eligible conversation. Thus on legitimate reloaded save the Native saved record is the persistent source; the Relay file is only an ephemeral view, not another owner.
7. **Scope of "memory":** this is *source-backed historical knowledge at each eligible NPC dialogue*, NOT a write to AII \`ConversationHistory\`/\`KnownSecrets\`/\`DynamicEvents\` or any autonomous memory-generation feature. For an NPC who did not appear in Native ballot, E4 must never invent knowledge. This design persists only as long as Native history is retained and Bridge/Relay source joins are healthy.

## CHANGE BOUNDARY
**TOUCH:** NEW \`Tests/Stage32E1NativeCourtNpcKnowledgePersistence.Tests.ps1\` (11 source contract checks) and this audit record.

**DO NOT TOUCH:** Native Court \`SyncData\` or enums/save definer, shared persistence, vote mechanics, legacy save migrations, Bridge session manifest/epoch, Bellum Bridge exporter, Relay Bridge probe, Relay provider adapter/settings, AII 6.0.2 save_data/JSON/DynamicEvents, any existing W7/public notification.

**MUST FIX (architectural decision):** choose one authoritative persistence source: saved Native vote receipt+provenance+exact audience; do not duplicate per-NPC private data into a second file. Ensure future release has save/load and save-rollback regression evidence.

**MUST NOT CHANGE:** once a Court vote is stored, joining should not mutate save data or infer missing recipients. Preexisting public events, regular conversations, existing AII NPC state and all player policy mechanics must keep working.

## Regression contract (before live execution)
Positive:
- In new-save test: record a policy vote witnessed by exact NPC A and not NPC B, including \`IntegrationId\`, realm, action \`enact|repeal\`, outcome \`passed|defeated\`, vote+receipt day, obsolete flag. Save S1; exit game; reload S1; verify native \`SyncData\` reconstructs all three maps with same IDs, and Stage31L+32C join yields A's exact roster. E4 L1 ON, after new manifest/Bridge export: only NPC A's dialogue gets the private vote, with one provider call, no AII NPC JSON save write. NPC B never sees it.
- After game restart the Bridge \`campaign_epoch\` must change yet saved Native \`IntegrationId\` and its roster must remain intact. New manifest and snapshot must match *current* epoch/start; old exporter files rejected.
- Save S1 before vote X; save S2 after X; reload S1: X must not be delivered, even if a stale S2 sidecar or Relay process still exists. Reload S2: X may be delivered again to the exact historically recorded NPC. No Relay ledger resurrecting facts from discarded future.
- Multiple eligible NPC voters can independently know the exact same historical vote; each may be queried without emitting an AII DynamicEvent or globally publishing any world-wide Court news.

Negative:
- Old save missing \`BC_CourtPolicyVoteAudience_v1\` while having provenance/receipt: do not infer audiences, do not retroactively inform anyone; unrelated valid records may remain eligible if join healthy. Invalid/overflow/conflicted maps: fail closed on that snapshot, never guess clan/vassal role. Wrong NPC, namesake, foreign realm, group/background/event/world_state route: no private knowledge.
- Game save-load during active dialogue/HTTP probe, missing native source or exporter not ready, corrupted/stale epoch/start/receipt, duplicate IntegrationId: no private block. Source must refresh after load, **not** use the old private file. Verify Bridge log \`BRIDGE_V1_PRIVATE_COURT_EXPORT status=exported\` in the new session.
- AII 6.0.2 user-provided technical guide: \`KnownSecrets\` are world-secrets with probabilistic first-contact roll, \`DynamicEvents\` are automatically managed shared events, \`ConversationHistory\` is automatic. No direct JSON edits or \`applicable_npcs\` role-based global dissemination to fake an exact recipient.

## Evidence / current result
Source audit: the three \`SyncData\` calls/keys, exact IntegrationId maps and independent per-Hero audience join are present. New 11-check PowerShell source regression script is committed. **This does not demonstrate actual save/load working:** no \`pwsh\`, .NET build, Bannerlord or saved-game binary roundtrip was executed in this authoring environment. All live verification remains **PENDING** in #91. The E4 overlay itself also has unexecuted Python tests and must not be called production-ready.

Recommended next stage: **Stage32E2 integrated save/load & rollback validation**, not another storage patch. If S1/S2 tests reveal an actual Native \`SyncData\` problem, then define a surgical code boundary around that proven failure, with RED before change. Do not introduce a Relay ledger without evidence of missing native persistence, a stable per-save provenance key and a comprehensive cross-save contract.
