# BellumCivile 1.4.12.12 — live foreign identity read precision

## ROOT CAUSE
The 1.4.12.11 console test declared a real foreign war and logged `Native foreign war-start witness captured; native_start=396062.74737220025`. `WarScoreRecord._startedDay` is persisted as a `float` (`SaveableField(4)`) from `WarScoreBehavior.CurrentDay=(float)CampaignTime.Now.ToDays`. Binary32 stores the same instant as `396062.75`. The read-only `GetExistingForeignConflictByInstance(..., double day)` rejected records when `StartedDay > day`, so an unchanged fresh record appeared `InvalidRecords`.

## TOUCH
Only `Behaviors/WarScoreConflictIdentityReader.cs` future-date comparison, its existing two test scenario harnesses, `SubModule.xml` version, own Windows verification script version gate, source README, hash manifest and this audit. No other program code.

## DO NOT TOUCH
Native peace veto, `MakePeaceAction`, Bellum foreign treaty commit, `RegisterConflict`, `OnWarDeclared`, `OnMakePeace`, save fields 1–41, old S27 dump, Bridge/Relay/CR integration, or scoring.

## MUST FIX / MUST NOT CHANGE
A new recorded war whose float-start rounded up from the current double instant is not corrupt. A genuinely future start, malformed/duplicate ID, wrong pair, not-at-war world, ended war and ambiguous Native witness remain rejected. Weak timestamp match NEVER authorizes action.

## REGRESSION CONTRACT (existing suites)
- `ForeignConflictIdentity.Tests`: actual reader + facade accepts `StartedDay=(float)396062.74737220025` at identical double day, rejects same record if capture day is a full day earlier.
- `WarNativeWitness.Tests`: a valid captured Native witness with that time produces `RecordedActive` + `WeakTimestampMatchNotProof`, `AuthorizesAction=false`; passive read never changes saved data.
- Existing old/corrupt/duplicate/reversed/war-ended/mutation tests continue to pass.
- User's prior live 5-record IDs and 1.4.12.11 6-record log remain observational baseline; do not change historical war records.

## RELEVANT LIVE EVIDENCE
`BellumCivile20261119(3).log`: new war `nord|vlandia` started 10:13:29 with record ID `1725b5db1a55469e851eaa11181049a4`, Native start `396062.74737220025`; at 10:17:11 its detached read returned `identity=InvalidRecords`, while older war records read correctly.
`Blocked non-Bellum international peace` at 10:16:51 is a SEPARATE, INTENDED rule with WarPeaceRevamp ON. The vanilla `campaign.declare_peace` command may claim success although the Bellum Harmony prefix vetoes the action. Do not weaken the veto or fake an external treaty.

## VALIDATION
- Package and source inventory: verify SHA-256 and ZIP integrity before user build.
- Actual Windows net472 Core+Naval build and all six test groups: NOT_RUN here; test on Windows with game+Workshop dependencies.
- Game: fresh war witnessed and read as weak match (not `InvalidRecords`), no unexpected new ID; save/load optional after fresh result.
- Only a Bellum-owned treaty pipeline may conclude permanent-kingdom war with Revamp on. Native peace command is not an adequate foreign peace test.
- No merge/release before game tests.
