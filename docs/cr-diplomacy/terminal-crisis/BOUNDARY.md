# S24 — terminal foreign-war crisis, analysis and proposed contract only

ROOT CAUSE: terminal WarScore, forced treaty drafting/acceptance and raw peace fallback
currently belong to Bellum's automatic path. S23A exposes an inert crisis verdict;
S23B persists ordinary intents but explicitly rejects TerminalForeignWar. Safe ownership
cannot be enabled by adding one false-return gate: the caller can fall through to raw peace.

TOUCH: new crisis ownership/call-chain audit, proposed state/authority contract, planned
behavioral regressions, source-evidence checks, provenance/hash inventory and latest README.
DO NOT TOUCH: ALL existing files, production code, save schema/IDs, version1.4.12.5,
existing tests/runners, DLLs, MCM, installed game, remote branches/CI/releases.
MUST FIX in this contract: separate negotiated consent from enforced defeat; preserve
Native authority, reversible-score revalidation, dual campaign/real-opportunity bounds including both routes TPS/latency/full cycles, player and linked-war
protections, and reconciliation after unknown/partial application.
MUST NOT CHANGE: accounting, council/player authority, forced budget checks, internal
resolution, principal/client obligations, currently functioning core+Naval packager.

All new behavioral scenarios are PLANNED / NOT_RUN. Executable source assertions only
verify current-source facts, NOT an implemented crisis policy. Implementation remains a
separate stage after its runtime prerequisites and accumulated build/save-load evidence.
