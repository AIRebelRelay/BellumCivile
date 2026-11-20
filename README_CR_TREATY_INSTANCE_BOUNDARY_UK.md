# CR Bellum 1.4.12.13 — Treaty instance binding (candidate)

## EVIDENCE / ROOT CAUSE

`TreatyProposalRecord` 1.4.12.12 persists only `WarKey`, not the specific `ConflictInstanceId`. `ForeignTreatyBehavior` resolves active wars by `GetActiveWar(proposal.WarKey)` in pending, player, and automatic paths. A stale pending proposal can therefore be rebound to a later recorded war of the same realm pair. The observed `state=Applied` entry is historical, **not** proof of a live replay. This stage is preventive; live exploit was not demonstrated.

## TOUCH

* `TreatyProposalRecord`: append ONLY save field 24, bind new proposals to canonical `ConflictInstanceId`.
* `Behaviors/ForeignTreatyBehavior`: identity-aware validation at intake, pending/AI/player and apply boundaries; stale cancellation must NOT invoke `EndParley` on a later war.
* `Behaviors/HostageTreatyRecovery`: avoid clearing a later war parley when recovering an older treaty hostage pledge.
* Focused tests, version metadata, self-contained Windows gate and source inventory.

## DO NOT TOUCH

WarScore `RegisterConflict`, `OnMakePeace`, Native Witness fields 38–41, foreign diplomacy Bridge/Relay, treaty term economy/transfer rules, council vote math, Naval DLC, native peace Harmony, existing save fields 1–23, WarScore fields 1–41.

## MUST FIX

1. A new proposal is bound to one exact recorded active foreign conflict, not an unordered pair alone.
2. A previously pending/legacy or mismatching proposal must not be ratified, modify terms/treasury, or end the *new* war's parley.
3. An already Applied historical proposal is retained unchanged, with no automatic reinterpretation or reapplication.
4. Unknown, corrupt, duplicated, non-hostile, retired or ambiguous records fail closed; recovery cleanup never binds an older hostage pact to a newer war by unordered pair.

## MUST NOT CHANGE

A valid same-instance pending proposal continues through the existing councils, terms, hostage delivery, and Bellum MakePeaceAction context. Legacy historical Applied entries stay as history. Legacy *pending* proposals without saved conflict identity become Cancelled (no silent ID backfill); their hostage recovery stays independent and must not clear a new war parley. No external console peace bypass is introduced.

## LIMITATIONS / STOP GATE

`ConflictInstanceId` is identity of a **Bellum record**, not proof of a unique Native war epoch. A missed peace followed by redeclaration while the same Bellum record stayed active remains fundamentally ambiguous. This stage refuses explicitly ambiguous callbacks, but does NOT claim full Native-epoch proof. No CR/LLM execution authority is granted. Live tests required after successful Windows compilation.

## REGRESSION CONTRACT (before implementation)

Positive: exact new ID is saved; same active ID can continue existing parley; stale proposal from prior war cancelled; legacy pending without ID cannot attach to a new war; historical Applied stays visible; no rerouting by WarKey; mismatched cancellation does not call new-war `EndParley`; repeated tests have no UID allocation or state mutation during read.

Neighbors: player ruler/vassal + AI-only, forced/nonforced, valid white peace, nonwhite terms, hostages, council cost, internal wars, old save load, Native ambiguity, S27/S28 read-only dumps and WarScore identity tests.

### Windows evidence needed

`BELLUM_TREATY_BINDING_GATE_PASS` after focused tests and Core+Naval build. This is NOT game validation. In a disposable test save, inspect Bellum log for treaty-id binding, rejected stale proposal, native wars retained, and unchanged S27/S28 diagnostics. Never test directly on a campaign without backup.
