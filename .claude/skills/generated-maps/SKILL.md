---
name: generated-maps
description: Architecture-first development guard for the AI Rebel Relay / Calradia Remembers / Bellum Civile / Bannerlord family. Read before adding rules, thresholds, event handlers, routes, public APIs, persistence keys, or integrations; compare source-generated maps and blocking contracts before accepting structural changes. Also use for SOLID, Tell Don't Ask, dependency direction and regression reviews.
---

# Generated Maps — architecture guard

## Installation status and honesty

This file is an **agent skill/instruction**, not an already implemented test harness. Its presence alone does NOT generate maps, enforce contracts, run tests, prove SOLID compliance, or validate Bannerlord gameplay. Until generators and checks actually exist, label that gate **NOT INSTALLED** and perform explicit manual source/caller audits. Do not claim MAPS_PASS without running a real map comparison.

Method inspiration: [LogRaam/My-Claude-Skills](https://github.com/LogRaam/My-Claude-Skills/tree/main/generated-maps) and [Keeping Control of Code You No Longer Write](https://scripting.pro/posts/keeping-control-of-code-you-no-longer-write/). This is a project-specific instruction, not a copy of upstream source or generators.

## Authority and source of truth

1. Identify the **actual repository, branch, HEAD, release/source candidate, and recent changes**. Do not replace newer source with a remembered or old ZIP baseline.
2. Read the **current agreed architecture and project-specific contracts**, not just this skill. For CR × Bellum work, start with the four canonical files below and the relevant contracts (links are repository-relative to the Bellum Bridge project):
   - `docs/cr-bellum/diplomacy/ARCHITECTURE.md`
   - `docs/cr-bellum/BACKLOG.md`
   - `docs/cr-bellum/diplomacy/DECISIONS-PENDING.md`
   - `docs/cr-bellum/diplomacy/ASPECT-COVERAGE.md`
   - Then inspect `docs/cr-bellum/diplomacy/` and `contracts/cr-bellum/` for the specific subsystem.
3. Current decisions supersede historic documents; documentation reflects agreed intent, while actual HEAD/source and tests determine what is implemented.
4. **Political authority is non-negotiable:** a correctly scoped LLM monarch decides sovereign foreign policy. CR and Bellum supply facts, actor-private knowledge, arguments, political machinery and legal execution. Bridge validates/routs and binds one executor; Relay sends independently configured NanoGPT routes. A deterministic scheduler may select a bounded opportunity, never a sovereign's preference. Do not recreate political decision-making in scripts or disable existing domestic Bellum politics without a separately approved migration.
5. Only source-confirmed *applied* game events become world facts/CR memory. Distinguish statement, intent, queued, accepted, applied, published, recipient-aware, persisted and gameplay-verified. Never silently promote a plan, LLM output or HTTP acknowledgement into an executed event.

## Surgical development: mandatory one-stage workflow

**Analysis:** establish root cause, real call chain, owners, all callers/consumers of shared infrastructure, affected save and wire formats, compatibility dependencies and blast radius. Examine source and existing implementations before adding a duplicate concept.

**Boundary:** write `ROOT CAUSE / TOUCH / DO NOT TOUCH / MUST FIX / MUST NOT CHANGE`. If the boundary expands unexpectedly, STOP and re-audit.

**Regression first:** define positive, negative and adjacent-function tests *before* implementation. Shared routing, scheduler, persistence, context assembly, event dispatch and Harmony are high risk.

**Minimal implementation:** avoid opportunistic refactors, accumulating exception patches, source overwrites, invented architecture and copied AI Influence code. Preserve current HEAD. Never change unrelated behavior just to make a test green.

**Evidence:** compare full diff; run targeted tests and build where available, then live game/log/save-load checks for runtime claims. `STATIC_PASS != BUILD_PASS != GAMEPLAY_PASS`. Do not equate test doubles, fixture acknowledgements or source parity with gameplay.

**Delivery:** users receive complete source ZIP archives and PowerShell build instructions, not Git CLI commands. Each functional change increments the appropriate version; a documentation-only skill addition does not claim a mod release.

## Generated map lifecycle (once generators are implemented)

A generated map consists of (1) deterministic source parser/generator, (2) generated, reviewed, committed Markdown under `docs/maps/`, and (3) a compare-only test that regenerates in memory and FAILS if the checked-in map differs. Keep generator/test sources with the repository.

- **Before coding:** inspect any matching existing maps and find the current owner of the concept. If no maps exist, search the source directly; do not infer absence from an empty map.
- **After coding:** run **COMPARE mode first, never UPDATE mode first**. Read the complete meaningful map diff. Ask whether dependencies, responsibilities, registrations, state and contracts moved as intended.
- **Only then** regenerate approved informing maps, review the generated diff, rerun tests and commit map plus code together. Never regenerate to hide an unexplained failure.
- **Informing maps** describe current source; change requires conscious review, not automatic refusal. **Blocking contracts** protect last *released* public API, save/import data (including new required fields), route/payload schemas and promised external behavior; they must not be overwritten by normal regeneration. **Ratchets** lock in improvements (e.g. namespaces in dependency cycles, hard-coded decisions outside the rules layer). Raising a ceiling, changing detectors or accepting a breaking contract needs explicit approval and reason.
- Prove each blocker catches an injected violation in an isolated copy. Protect the detector and released snapshot against silent weakening.
- Stable output: syntax-aware parsing rather than naive regex; sorted/no timestamps/absolute paths; identify by enclosing type/method, not line number; normalize line endings only; report blind spots and false positives. A missing source tree is not a green test.

## Minimal bootstrap; do not create ceremonial maps

Start with **one meaningful source inventory/dependency map and one compare test**, then a short update command. Next prioritize actual external **API, save/load and wire contracts**. Add a domain-specific map only for a repeated real regression (registrations, duplicate rules, event listeners, routing, ownership, persistence, thresholds). No map may pretend to cover a subsystem it cannot parse.

When asked to improve SOLID or Tell Don't Ask: first inventory what already exists, trace actual facts consumed and where decisions are made, then name a concrete violated boundary and a measurable regression. Separate *pure testable rule/legality logic* from game-engine/UI/network glue where practical; keep political *choices* with the LLM. Do not impose abstract layer refactors or new interfaces without evidence and approved scope. For a behavior-preserving refactor, decision tables over bounded pure-rule inputs should have **no output diff**.

## Mandatory report for each stage

State: repository/branch/HEAD; canonical documents checked; root cause and callers; exact files to touch/not touch; maps/contracts checked or NOT INSTALLED; regression cases and observed evidence; source diff; tests/build/gameplay/save-load status; remaining blockers and next single stage. Never claim a guard is active merely because this `SKILL.md` exists.

## Local scope — custom Bellum Civile

This is the custom fork, not upstream Vonbalt. Audit the upstream version chain and all intermediate changes before porting. Preserve custom integrations, court/inner-kingdom autonomy, title/realm/war/council mechanics, live source owners and the selected CR political boundary. Map behaviors, rules/models, policy thresholds, patches, event listeners, persistence keys and public extension APIs. Do not call a successful build proof of succession, war/peace, save/load, aging or other gameplay. A shared decision/policy refactor requires exact neighboring behavior tests and real source-state readback.
