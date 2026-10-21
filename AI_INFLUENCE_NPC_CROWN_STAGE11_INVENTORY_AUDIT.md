# Stage 11 — Bellum read-only NPC Crown inventory: implementation audit
2026-10-21 | target Bannerlord 1.4.8, Bellum Civile 1.4.5 stable + AI Influence feature.

## Outcome
**PASS — isolated compiled mock runtime + all Stage 5–9 regression CI. No live-game test, no new native game-assembly compile, no Bridge consumer yet.**
- Final tested Bellum feature HEAD: `3a587f05154d44cb708fdf8a3ec8284e3b6e2759`.
- Official Bellum 1.4.5 baseline and fork `main`: `b1d9a4e8fb74d4f9dd045793c156abeac6f9f4eb` (**unchanged**).
- Pre-production audited source: `9a69fe33913a9e45640f60bde798142428eeba2e`.
- [Regression contract written before edits](./AI_INFLUENCE_NPC_CROWN_STAGE11_INVENTORY_CONTRACT.md).
- [**Final Stage 11 CI success — run 39663330118**](https://github.com/AIRebelRelay/BellumCivile/actions/runs/39663330118). Recorded `STAGE11_NPC_CROWN_INVENTORY_PASS`, all 15 workflow steps green.

## Source-backed root cause / surgical fix
After Bellum Bridge Stage 10 accepts and consumes one `indict_clan` intent, a restart loses Bridge's ephemeral knowledge of external ticket IDs. Bellum alone persistently owns tickets and existing `GetNpcTreasonIntent(realm,id)` readback; no public enumerable snapshot existed. Polling Bridge memory alone would silently omit old attached/closed tickets after reload.

**Implementation (only 28 new production lines):**
1. `BellumIntegrationNpcCrown.cs`: additive public `IReadOnlyList<NpcCrownTreasonIntentSnapshot> GetNpcTreasonIntents(Kingdom realm)`, with existing `RequireCampaignThread()` and a safe empty result when Court is absent.
2. `Behaviors/CourtNpcTreasonIntents.cs`: returns a new list of realm-scoped snapshots ordered by exact external ID; delegates every ID to **unchanged** `GetNpcTreasonIntent` to retain its corrupted-payload filtering, terminal closure handling and native `court_* / court_missing / court_superseded` status semantics.
3. NEW `Tests/AiInfluenceNpcCrownStage11.Inventory.Tests.ps1` compiled against actual Bellum feature source plus existing TaleWorlds test stubs: exact realm, stable ordering, no foreign info, old exact readback, attached Court transition, terminal tombstone, malformed persisted ticket ignored without mutation, save/reload through mock data store, wrong-target/agenda supersession, `court_passed` still only a docket state, missing agenda, campaign-thread guard, absent court.
4. `.github/workflows/ai-influence-npc-crown-baseline.yml`: one new test trigger and one new test execution step. No extra workflows or paid CI reruns beyond stage diagnostics.
5. Documentation only: contract and audit.

**DO NOT TOUCH / invariants verified by full diff:** `CourtAgendaBehavior.OpenTerm`, `CourtExecutiveAgendas`, `CourtNpcTreasonAssignment`, `CourtNpcTreasonLifecycle`, SaveDefiner, existing 3 persisted dictionary keys, existing ticket codec, native decree/peace/council priority, player Crown, expulsion vote, ideology, foreign diplomacy and Bellum Bridge/Relay/Relay Bridge. No new save schema or Harmony; no status-based mutation; the Bridge 0.8.6 `main` remains unchanged.

## CI incident analysis (no production patch chain)
- [Run 39662844724](https://github.com/AIRebelRelay/BellumCivile/actions/runs/39662844724) failed only the new test's terminal-tombstone expectation: mock Kingdom was not registered in `Kingdom.All`; Bellum correctly returned `cancelled_realm_invalid`.
- [Run 39663129600](https://github.com/AIRebelRelay/BellumCivile/actions/runs/39663129600) added temporary test-only status evidence: `closed=cancelled_realm_invalid; attached=court_deliberating`. Confirms native lifecycle, not inventory API, was working as written.
- Corrected **only fixture setup** by adding `Kingdom.All.Add(kingdom)`, removed temporary diagnostic text. Final run `39663330118` success, no production revision after initial code commit.

## Evidence standard / next stage
There is deliberately **no log emitted by enumeration itself**. Running `GetNpcTreasonIntents` never schedules, votes, closes or invents tickets. Native saved-data status is read-only and present on demand after reload. All currently known ticket status strings are native Bellum strings; do not infer successful expulsion from `court_passed` without separate native outcome evidence.

**Next independent stage:** build a narrowly scoped, rate-limited Bellum Bridge observer that calls this enumerable API and records meaningful **status transitions**, including after reload. Explicitly audit whether the Relay can ingest such events before adding any cross-app publication or changing shared polling. Do not merge/release, replace game DLL, or declare full runtime compatibility without real-game corroboration. The previous user-side Bellum source DLL compile was for an earlier HEAD and does **not** validate the Stage 11 binary.
