# Existing war state — stage S05 (source candidate only)

Repository: AIRebelRelay/BellumCivile. Base branch: feature/cr-existing-council-state-2026-11-16, HEAD b7b03265a1ec98922b3f16812d3aee0f1044e539 (PR #48). Additive draft; no merge, release or runtime activation. This is the war slice of the authorized wars/claims/political-pressure block. Claims and pressure remain later stages.

## Analysis and boundary fixed before implementation

ROOT CAUSE: integration lacks a detached, non-materializing war-state read. GetActiveWars/GetTrackedWars invoke EnsureCollectionsInitialized, and copy only the outer list, leaving mutable saved WarScoreRecord objects exposed. This is an API gap, not evidence that current gameplay getters are broken.

Call chain: new BellumIntegration.GetExistingWarState -> existing RequireCampaignThread -> campaign WarScoreBehavior -> new GetExistingWarStateSnapshot -> existing GetOpposingKingdom -> ResolveKingdom -> Kingdom.All; IsAtWarWith reads current Native hostility. Raw score is from AttackerKingdomId (primary side) even for CivilWar/ClaimFeud. GetDisplayableWars additionally filters current hostility; the new snapshot deliberately preserves a saved active row and reports hostility separately.

Existing consumers inspected: WarScoreBehavior scoring/tick/resolution/recovery/peace paths use GetActiveWars and realm resolution; UI/Map/WarScoreMapWidgetVM uses GetDisplayableWars. Neither helper semantics nor callers change. No preexisting production file is edited. Full baseline Git blob audit verifies all 1,532 tracked files unchanged (three existing council evidence files are supplied from their exact office-stage bytes when packaging).

TOUCH (production additions only):
- WarStateSnapshot.cs: detached immutable DTOs/status, raw kind and explicit score perspective.
- BellumIntegrationWarState.cs: campaign-thread-only facade, no registration.
- Behaviors/WarScoreIntegrationState.cs: existing-record projection in partial WarScoreBehavior.

DO NOT TOUCH: existing WarScoreRecord/Behavior methods, score calculation, war/client/rivalry ownership, resolution, peace/parley, claims, war will, Native save schema, council feed/context reader, CR, Relay, prompts or actions.

MUST FIX: distinguish missing collection/service from recorded empty; scope to requested realm; copy scalar values; make viewing-side sign explicit; distinguish recorded active from Native hostility (unknown if opponent unresolved); fail closed on corrupt selected rows, null unscopable rows or over 64 selected records. No silent truncation.

MUST NOT CHANGE: source state and initialization, active gameplay paths, save bytes, council behavior, or NPC knowledge. Technical API accepts a realm; actor authorization and CR knowledge remain the caller's separate future responsibility. It is not an actor-scoped prompt provider.

Regression contract established before code: both score perspectives, all three raw conflict kinds, scope exclusions, stale active records, absent services/collections, malformed records, capacity, snapshot immutability, source preservation, campaign thread guard; adjacent existing council and civil-war source contracts.

## Results

- 35 named war-state cases PASS. C# 7.3 Add-Type compiles the three production files, actual WarScoreRecord and its peace-reconsideration partial, actual event/fief/treaty records and enums. Actual GetOpposingKingdom/ResolveKingdom bodies and two exact source constants are extracted with checked boundaries. Campaign/thread/Kingdom/SaveableField are boundary doubles. The fixture models hostility, not the real engine's diplomacy.
- 20 existing council-state named cases PASS, unchanged suite.
- CivilWarRivalry: 14 source assertions PASS; SuccessionWar: 18 source assertions PASS. These check source contracts, not live behavior.
- Full baseline audit: zero modified/missing tracked files in candidate. Only the three declared production additions. Fixtures use .cs.txt so the Native default compile glob does not ship doubles. No temporary debug hooks or workflows added.
- Native net472/Windows build and live game validation PENDING. Offline tests are not DLL/game proof. Existing prior stage native/live gates remain open. No GitHub Actions run requested.

Run from full source ZIP with PowerShell 7.2+: `pwsh -NoProfile -File .\Tests\ExistingWarState.Tests.ps1`. This is an isolated test, not the shipping build.

## Runtime acceptance (future explicit diagnostic consumer; no automatic logger added)

Expected diagnostic state: ApiVersion=1, exact RealmId/CapturedDay; Recorded and immutable rows; defender ViewingRealmScore=-PrimaryScore. A saved active row after peace may legitimately report NativeHostility=false. Unresolved realm reports null hostility, not false. Empty Recorded is no matching saved row, not peace.

Unexpected: changed source count/score/private flags after reading, new war/council/claim records, invented initial war will, an overflow returned as complete, actor learning private context, diplomacy action triggered, or score sign unchanged for a nonzero defending score.

Game checks: compare read-only snapshot with War Score UI for both sides, foreign/civil/feud and save/reload. Read repeatedly and verify no change to state. Verify existing scoring, rivalry, parley and council appointment feed still function. There is deliberately no new automatic log line: this API is unregistered and must not be reported as running in-game.

## Next gates

S05A: Windows shipping build against installed game references and actual Workshop dependencies; pending.
S05B: Runtime snapshot/UI/sign/hostility/no-mutation/save-load checks above; pending.
S05C: Later actor/knowledge projection must join CR awareness and enforce scope before any prompt/news. Do not expose this technical snapshot directly to every NPC.
S05D: Auxiliary foreign-war and civil rivalry ownership need separate source classification. Raw ConflictType is not permission to choose an executor.
S05E: Claims and political pressure not implemented here. GetWarWill materializes an initial value; PeekWarWill's default is not a recorded value. Future read must distinguish missing. Claims expiry zero is expired, pressure expiry zero is non-expiring; hereditary barred-carrier filtering must be preserved. LandlessPressureScore is a signed score component, not clan political pressure.
