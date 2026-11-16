# Verified CR 2.8.12 host contract — 2026-11-16, read-only

Source: LogRaam/calradia-remembers main ab539bb66fac59fc6b68d2c027cdaa9e6fd58b9d.
SubModule.xml says v2.8.12; CrApi.Version is 2. This repository was located from
the existing architecture master plan. It is separate from the engine-agnostic SDK
LogRaam/LLM-Roleplay-Service master 756bc512420bf009ae49cca37c6275360cb2633e.
Drive's inspected v2.8.11 package is older reference material, not this source.

## Already available — do not rebuild these doors

| Need | Actual host source | Contract and limitation |
|---|---|---|
| NPC persona for ruler/NPC calls | Extension/CrPrompt.cs Persona, PersonaText; Logic/Extension/PersonaSectionPolicy.cs | Read on game thread for current hero. Character-only section allowlist; no player conversation instructions, action parser or other mod's mod_private section. Treat as text, not a schema. May be empty before connection setup. |
| Optional completion through CR | Extension/CrLlm.cs CompleteAsync, IsReady, Unavailable | Plain completion, no gameplay/memory/action execution. Captures campaign identity; rejects result after campaign replacement. Caller marshals completion back to game thread. |
| Own route-specific NanoGPT/Relay calls | Persona APIs + our own future transport | CrLlmRequest has no route/model/endpoint field; CompleteAsync uses CR's configured LlmClient. Therefore CrLlm is not proof of per-route model support. The project requirement remains separate models through AI Rebel Relay; verify routing before choosing this optional transport. |
| External world facts | Extension/Feed.cs Record/Update/Retract/List | Stable source ID, bounded store and 20 new records/source/day. Counter is in-memory, while dedup uses persisted events. Record acceptance is not proof a particular NPC heard it. |
| Knowledge/privacy | Extension/CrWorld.cs KnownEvents; ExternalWorldEvent secrecy fields | Public by default; use explicit audience fields for private facts. Actor/subject distinction matters. Preserve private provenance restrictions. |
| Per-reply current facts | Extension/CrPrompt.cs RegisterVariable, heard_now | Game-thread callback with NPC id/Lean; live compact context, not durable event history. |
| CR-originated diplomatic effects | Extension/CrDiplomacy.cs RegisterAuthority | Source-mod authority may PassThrough/Reject/Pending/Applied. It does NOT intercept the game's own kingdom votes or every other mod; cannot replace Bellum's own execution ownership. |

CrLlm defaults output to 600 tokens (cap 4000), clamps creativity 0..2, honours the
player's external-mod setting and cancellation, and accounts usage. No external LLM
completion was invoked in this audit. Persona contains CR-private memories legitimately
known to the speaker: later Bridge prompts must distinguish personal knowledge from
what the speaker is permitted to disclose to an audience.

## Tests actually run

SDK full suite: 2331 passed, 0 failed; one further real-LLM integration test not executed.
CR host/Logic suite: 7414 passed, 43 failed, 148 skipped in console summary. TRX has
7617 registered, 7457 executed; explicit counters and results retained in local logs.
Of 43 failures, 34 reference absent optional Adult Tales assets, 3 require compiled
host DLL, and 6 are path/profile assertions requiring cross-platform review. These
are not a blanket host PASS or six confirmed host bugs. No CR source was patched.
A source-name-selected set of 242 knowledge/persona/feed/diplomacy/private-related
results has zero failures; name selection is supplemental, not a coverage guarantee.
SDK and Logic compilation/tests do not validate native game integration or host ABI.

## Bellum Bridge legacy transport — verified current source

Bellum Bridge main f362a4f70786896b4160489bc1e3f448fdd0578e remains an AII/Relay
integration. Relay Bridge main c48d08033d0dd509e551be738f9d9ae677971304 is separate.
Public source archives of these repos were unavailable to anonymous download;
authenticated source reads were used for this targeted inspection.

BellumCourtEventFeedSubModule reads court transition shadow envelopes, excludes
merge_existing_civil and drop_low_value, and publishes court_politics_transition
through BellumSidecarWriter.RecordSourceBackedFact. Source IDs combine observed UTC,
sequence, ordinal and before/after; this is not automatically a durable Native event ID.
BellumCouncilAppointmentOutcomePublisher polls GetRecentCouncilAppointments and
baselines historical receipts without replay. It has exact completed-receipt ownership
for principal appointment announcements; generic faction reactions remain separate.
BellumNotificationCapture hooks only Show(string,...) in the inspected file. Native
notification helpers often short-circuit ShouldPrepare before calling Show; native
TextObject Show renders directly rather than calling the string overload. A global
feed built only on that patch cannot establish complete Bellum domain coverage.

Native IntegrationVotes/Partitions mark records Dispatched before invoking each
subscriber and catch subscriber exceptions; recent lists retain up to 100 results.
A callback is not an acknowledged durable delivery queue. A new Bridge needs explicit
recovery/backfill/retention semantics and source-based reconciliation. Existing Native
private terminal inventory/audience joins must never be promoted to public facts just
because a record is terminal.

Next independent read-only audit: join each producer/state to actual typed Native API,
visibility, retention, existing consumer and proposed CR context. No Bridge production
port or foreign-policy execution changes are included here.
