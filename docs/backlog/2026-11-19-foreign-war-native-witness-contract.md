# CR diplomacy milestone — Native foreign-war provenance witness (candidate 1.4.12.11)

## ROOT CAUSE / demonstrated boundary
`WarScoreBehavior.RegisterConflict` reuses an active record keyed only by the unordered pair. The existing 6-case S26C characterization demonstrates that, if peace is missed and the two realms are hostile again, `ConflictInstanceId` can refer to the earlier record. S27 proves saved *record* continuity for five rows; it does not prove a Native war incarnation. Native `StanceLink.WarStartDate` is available, but is not proven unique or a durable war identity. A timestamp match alone MUST NEVER authorize diplomacy.

## TOUCH
- `WarScoreRecord`: append only fields 39–41 (native start day, witness present, ambiguous subsequent declaration); do not alter fields 1–38.
- `WarScoreBehavior.OnWarDeclared`: record a weak Native start timestamp **only on a newly created foreign record**; do not graft a new witness onto an existing active record; mark re-declaration uncertainty without ending/replacing it.
- New isolated observer / facade / snapshot: read actual Native hostility, source witness and timestamp; report **weak match**, unknown, ambiguity or mismatch; never provide authorization.
- Targeted self-contained harness/verification, version and package inventory.

## DO NOT TOUCH
`RegisterConflict`, `OnMakePeace`, `ReconcileExistingWars`, `SyncData`, internal/civil/feud registration, Native war/peace actions, AI Relay/CR Bridge, ordinary intent or crisis persistence, autonomous Bellum settlement, Naval DLL logic, current S27 dump fingerprint.

## MUST FIX
Future consumers can distinguish record continuity from an observed Native timestamp witness. An old/legacy/unwitnessed record, repeated declaration for the same active pair, invalid/non-hostile Native state or a changed Native start marker return non-affirmative observations. Even matching timestamps remain **weak evidence** and never prove a unique incarnation.

## MUST NOT CHANGE
No automatic peace, no war re-declaration, no record rotation/reset, no changes to old identity reader or current game UI. No witness creation on passive reads or during migration. Older saves remain loadable with fields 39–41 defaulting to unknown. ID/score/war-lifetime are unchanged.

## Regression contract BEFORE code
1. Fresh explicitly declared foreign record: one timestamp captured; repeated reads are passive; weak match only if same stamp and current mutual hostility.
2. Existing active foreign record when declaration callback arrives: never replace record, never claim new witness; mark provenance ambiguous. Same-timestamp callbacks also ambiguous (cannot distinguish duplicate from a same-day second war).
3. Missing peace callback + changed Native timestamp: mismatch, never weak match. Same stamp cannot be proven unique; expose weakness.
4. Reconciliation-created and legacy records, invalid timestamps, non-hostility, eliminated realm, wrong pair, corrupt/duplicate ID, ended/internal record: no affirmative provenance.
5. Capture and ambiguous markers survive serialized field-copy; no old save fields renumbered.
6. Existing S26A/S26B/S27 tests and Core+Naval package pass; output remains full mod and version updated once.

## Evidence gates
Static/diff/isolated regression first; Windows net472 build with actual Game+Workshop DLL next; game fresh declared war and save/load observation afterward. Even a clean build or weak timestamp match does NOT close the missed-peace/war-epoch gap. A separate durable Native event-source proof is required before any LLM outcome executor can use this data as a grant.
