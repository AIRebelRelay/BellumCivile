# Stage 30C — Native Bellum hostage-pact read-only per-realm observations

**2026-10-29 | Test-first source patch completed; no local .NET test, no game DLL build, no CI, no runtime/game validation. Do NOT merge/release.**

## Correct repositories and branches

- **This is Native Bellum** `AIRebelRelay/BellumCivile`, branch `feature/stage30c-hostage-readonly-realm-snapshot-2026-10-29`. Baseline: existing active development `feature/stage29f1-ai-owned-foreign-ledger-native-2026-10-29@37fb6db864771d208177f2fc1959d93b34876c98`. Keep prior Stage29F1 untested changes and newer civil-war fixes; never reset to older `main`.
- **Bellum Bridge** `AIRebelRelay/Bannerlord2-AiInfluence-BellumCivile` Stage30B audit [source routing/visibility report](https://github.com/AIRebelRelay/Bannerlord2-AiInfluence-BellumCivile/blob/audit/stage30b-hostage-knowledge-readonly-routing-2026-10-29/docs/compatibility/bellum-145/2026-10-29-stage30b-hostage-knowledge-readonly-routing.md) parent `b1b893d00c9cac832458b2e9e87447a6c0a26aa3`.
- **Relay** `AIRebelRelay/ai-rebel-relay@4f8dd72cf85d947c1e5f198de9546f43bbdda5f8`. Bhelogan 5.1.9 provider/session/TTS untouched. `ai-rebel-relay-bridge` is NOT Bellum Bridge.
- Outstanding [P0 #89](https://github.com/AIRebelRelay/Bannerlord2-AiInfluence-BellumCivile/issues/89) Native foreign WarScore 29F1/F2 integration build+game validation still OPEN; this read-only work is independent.

## ROOT CAUSE

`HostagePactBehavior` persists `BellumCivile_HostagePacts` private `_pacts`, but public read-only per-realm current-fact API is absent. Its original `GetActivePacts(Kingdom)` returns empty with `EnableWarPeaceLogicRevamp OFF` even if a saved `HostagePactRecord` still says `Phase=Active` pending Native maintenance and safety cleanup. `GetStatusSnapshot(Hero)` derives status from that OFF-gated list, so simply publishing "active" or "not in pact" would be misleading; `HostageCustodyGuard.IsProtected` also uses a different source predicate.

The separate original `RetainedTreatyPrisonerBehavior.IsRetained(Hero)` should NOT be confused with a protected hostage, and its existing OFF cleanup must remain.

## Change boundary

**TOUCH only:**
1. `Tests/SuccessionEngineHarness/HostageReadOnlySnapshotTests.cs`: committed FIRST, source contract for strict kingdom participant scope, invalid/ended exclusion, saved Active OFF vs confirmed ON vs unlisted ON, Preparing/Resolving, no fabricated captive, saved duration and proposal identity unchanged, nonmutating source, immutable DTO/list, no new SaveableFields, original Native APIs intact. Tests include original `HostagePactRecordTests` and `HostagePactDurationTests`. Full harness also runs these original neighbors.
2. `Behaviors/HostagePactReadOnlySnapshot.cs`: NEW `sealed partial class HostagePactBehavior` additive **public** method `IReadOnlyList<HostagePactReadOnlyObservation> GetReadOnlyPactObservations(Kingdom realm)`. Current-game, participant-realm-scoped, non-ended and nonblank PactId rows; results sorted by PactId. Reads `GetActivePacts(realm)` for actual Native legal/operative status when Revamp ON, but DOES NOT MODIFY that function's semantics. Under Revamp OFF, returns saved current pact state with explicit `active_revamp_off_pending_termination`, NEVER reports an operative peace pledge. Includes `SavedPhase`, `EndReason`, source `TreatyProposalId`, participants/ruling houses, agreed duration, dates, a two-slot **immutable** `HostageCustodyReadOnlyObservation` with `HeroIsPrisoner` and exact original treaty custody match. **Does NOT export holding/dungeon location** to remote consumers, any `HostagePactRecord` live mutable references, or action permissions. It does NOT enumerate ordinary non-hostage prisoners (separate later design); must not be falsely advertised as global prisoner context.
3. `Tests/SuccessionEngineHarness/Program.cs`: targeted `--hostage-snapshot` and default full-suite test calls.
4. This document (handoff only).

**DO NOT TOUCH:** `HostagePactRecord.cs`, `HostagePactLifecycleRules.cs`, `HostagePactMaintenance.cs`, `HostagePactWar.cs`, `RetainedTreatyPrisonerBehavior.cs`, Native prisoner/custody Harmony, Native `WarPeaceRevampBehavior.cs` or settings, save definer/fields, ForeignTreatyBehavior, AII W1, civil/claim-feud outcome, player hostage dialogues, current Bridge/Relay code, both main branches, GitHub Actions/deployment, sidecar schema and provider routes.

**MUST FIX (Stage30C):** the Native side exposes only its already persisted present-tense, correctly scoped participant-realm pact fact with separate phase/mechanical status/real custody and cannot write gameplay state.

**MUST NOT CHANGE:** Native custody, release/ransom, treaty enforcement/settlement, betrayal, rescue, player choices, expiry/maintenance timing and OFF cleanup; no hidden default changes, no new arbitrary prisoner/hostage claim, and no live dynamic-event memory modifications.

## Source-backed implementation semantics

- `GetReadOnlyPactObservations(realm)` returns immutable DTO rows, never a mutable list of `HostagePactRecord`. A null or nonparticipant realm sees no pacts; malformed no-ID and completed historical pacts excluded, Preparing/Resolving retained with accurate labels.
- The only `active_confirmed` is `SavedPhase=Active AND RevampEnabled=true AND Native GetActivePacts(realm).Contains(pact)`. `Active` with OFF is `active_revamp_off_pending_termination`. `Active` under ON but not currently listed is `active_unverified`. Explicitly preserves original Native verdict rather than silently overriding it. Reporting 'confirmed' is still a mechanical view for real participants, NOT an NPC-visibility grant.
- For each pledged hero the DTO differentiates `CustodyEstablished`, `HeroIsAlive`, `HeroIsPrisoner`, `OriginalTreatyCustodyVerified` (same original CaptivityStartDay, same dungeon roster, live hero), `ProtectedBySavedPact` (existing `pact.Protects`), `SavedOutcome` and `ActionCompleted`; an unrelated new imprisonment is NEVER presumed the old pledge. No hold settlement ID is exposed in the snapshot.
- This is a **read-only observation API only**, not a treaty offer or an executable `hostage_peace`/prisoner release command. Under OFF no HostagePeace legal executor is enabled. Use only on game/campaign thread, then copy primitive values into eventual Bridge sidecar with actor visibility rules.

## Regression contract and proof status

- [x] Regression tests **written and committed before production**. Test-first commit `e410cfb69a9d92858788b171179603e77c47d7d8`. Fixture uses existing Native harness conventions with `FormatterServices.GetUninitializedObject` for participant realm identities. Source tests later enhanced to avoid ambiguous overloaded `MaintainCustody` reflection and assert readonly collection.
- [x] Static code/diff audit of only bounded paths (see full comparison of branch to `37fb6db`); no Native save class/global policy/mutation changed.
- [ ] Native .NET 4.7.2 build using `-p:GameFolder="<actual Bannerlord 1.4.8 folder>"`. Tool host lacks dotnet/msbuild/pwsh and Bannerlord DLL; do NOT claim compiled.
- [ ] `dotnet run --project Tests/SuccessionEngineHarness/SuccessionEngineHarness.csproj -p:GameFolder="<actual Bannerlord 1.4.8 folder>" -- --hostage-snapshot`. Confirm one realm sees exactly one pact, nonparticipant sees none, OFF doesn't advertise active, ON requires Native list, no save mutation or new executable action.
- [ ] Neighbors: `--hostage-pacts`, `--hostage-adulthood`, `--civil-war-settlement`, `--client-liberation` and correct Native DLL build, complete post-build diff.
- [ ] Game: create or load a Native hostage pact in controlled test save; inspect OFF/ON snapshot states before/after daily tick, war breach, save/load, release/rescue and unchanged actual custody; preserve original court, prisoner and player paths.
- [ ] Future Bridge Stage30D and Relay Stage30E, each separate, implement correct TTL/campaign save reset, actor-scoped knowledge and bounded token injection; full end-to-end game alpha only then.

**Expected future log** (NOT present yet): `BELLUM_HOSTAGE_CONTEXT status=written; state_changes=false; pacts=...` for snapshot publication. **Forbidden side effects**: `Hostage judgment queued`, `Treaty prisoner released by negotiated term`, `War Score forced foreign peace` triggered by merely reading. Native F1/F2 #89 and Court foreign pressure #85 remain unchanged.

**STATUS:** Native production source is committed on a separate branch but is **not validated/tested/built/deployed** and no real NPC receives these observations yet. Do not merge or release based on static source inspection.
