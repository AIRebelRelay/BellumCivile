# S23A — Bellum foreign-admission policy candidate 1.4.12.4

This is a tested policy foundation, NOT an active LLM diplomacy implementation.
No existing gameplay method calls the new policy. No switch, authority registration,
engine interception, durable pending operation, consent verifier, crisis handler,
event/news injection or treaty execution is implemented in this stage.

## Provenance and scope

AIRebelRelay/BellumCivile, feature/cr-realm-preparation-receipts-2026-11-18,
903f6772a8bebab68b1296121d770b741ae1a232 (Draft PR 54). Branch/head rechecked
through GitHub during this stage; 1,607 extracted base files matched the pinned
inputs/bellum-current.zip byte for byte. The HEAD's recent CompleteReleaseNaval
test correction was inspected and preserved. This is an isolated ZIP candidate;
no remote branch, merge, release or CI run was created.

Candidate file version is 1.4.12.4 / informational 1.4.12b-cr-alpha.4. AssemblyVersion
remains 1.0.0.0. No claim of upstream port parity or Bannerlord 1.5.7 ABI compatibility.

## New executable rules

- Disabled/outside scope: existing owner retains its existing rules.
- Player, internal conflict, client obligations, existing treaty obligations,
  voluntary pacts and hostage choices: existing owner retains its rules.
- Scoped automatic foreign war/peace/parley: request LLM intent, no execution verdict.
- Scoped NPC ratification: exact-draft consent is necessary, then Native validation
  is still required. This rule does not validate consent or authorize spending.
- Terminal foreign conflict: separate bounded-crisis handler required. No raw peace
  fallback and no claim that a Hold verdict solves an indefinitely pending war.
- Lost/unready owner or unrecognized in-scope source: Hold.
- Activation: all eight capabilities plus known-zero legacy pending work required.
  These are trusted adapter facts, never LLM JSON or user configuration booleans.

Public/private news and NPC awareness are unchanged. Pacts/hostages are explicitly
excluded from LLM ownership for now; their future information feed is a separate stage.

## Callers and blast radius

There are ZERO production callers of ForeignDiplomacyAdmissionPolicy in this ZIP.
Future wiring must audit the following actual call chains before editing them:

| Source | Existing chain | Required future distinction |
| --- | --- | --- |
| Vanilla roll replacement | BlockVanillaForeignPolicyProposalsPatch.Prefix -> WarPeaceRevampBehavior.TryCreateWarDecision / TryCreatePeaceDecision | Keep vanilla fallback blocked only for actually owned ordinary foreign intent; preserve client liberation and player authority |
| AI parley | ForeignTreatyBehavior.TryQueueAiParley, three callers: WarPeaceRevamp, WarScore proposal, WarScore terminal | Classify producer; admission refusal must not trigger raw terminal fallback |
| Terminal resolution | WarScoreBehavior.ResolveQueuedTerminalWarScore -> TryQueueAiParley -> ResolveTerminalConflict | Gate foreign branch only; preserve reconciliation, internal conflicts, client/alliance/story protections; implement bounded crisis first |
| NPC ratification | ForeignTreatyBehavior.OnDailyTick -> ResolvePendingParley -> EvaluateRatification / spend / ApplyTreaty | Require actual operation-bound current consent BEFORE irreversible costs; NPC monarch with player vassal is not player ruler |
| Player signing | Shared TryQueueParley / ApplyTreaty callers | Do not blanket-gate shared executor |
| Voluntary pact / hostage | VoluntaryPactAiBehavior.Evaluate / AdvanceTargetChoices | Remain automatic in this scope; future news observes actual results |

The policy's source enum is NOT evidence that future runtime callers classify these
paths correctly. In particular, client liberation and internal-conflict resolution
must not accidentally be classified as ordinary foreign war.

## Validation

65 assertions compile and execute the actual standalone C# policy through PowerShell
Add-Type (/langversion:7.3). Five deliberate semantic mutations are required to fail
the assertions: owner fallback, ordinary terminal intent, consent bypass, pending
activation bypass, unknown-source fallback. See logs and MUTATION_RESULTS.json.
The initial RED was absence of the new policy file, not a reproduced game bug.

Six existing C# fixture suites passed: political pressure 49, war state 35,
claims 45, councils 20, recorded names 36, realm preparation receipts 37.
These use actual code/extracted methods plus engine doubles, not the game.
CompleteReleaseNaval source contract passed. Full diff/hash audit is included.

OPEN / BASELINE FAILURE: ModuleLocalLogs.Tests.ps1 completes its first 10 logger
checks then fails at Copy-Item $navalDll because the old fixture does not provide
that variable to the expanded packager. The identical failure was reproduced on
unmodified 903f6772. Only the test's two expected candidate-version literals were
updated here; fixture repair is deliberately not bundled into the policy stage.
Therefore the complete packaging test suite is NOT green.

Windows full net472/game-DLL build: NOT_RUN. Actual builder was invoked and rejected
Linux with 'Windows and actual installed game references required.' Game, Harmony
binding, TaleWorlds serialization, save/load and end-to-end diplomacy: NOT_RUN.
No shipping DLL is included or claimed.

## What to replace and check

In-game replacements: NONE. No new gameplay log lines are emitted by this stage.
Policy test expected output: TOTAL PASS 65. No new policy gameplay effect should be
claimed. All S22 end-to-end/Bridge gates remain open; no earlier unexecuted Bridge
check is reclassified as passing.

Next runtime stage requires durable ownership/save recovery, a real pending-state
inventory and bounded terminal-crisis behavior. Do not enable a partial global gate
while those prerequisites are absent. Production adapters and activation remain open.
