# Behavioral regression contract — ALL rows PLANNED / NOT_RUN

Source-evidence assertions do not satisfy any behavioral row below.

| ID | Scenario | Required result |
| --- | --- | --- |
| C01 | Mode disabled/no owner | Existing legacy foreign/internal behavior unchanged |
| C02 | Ordinary low War Will, score below terminal | No forced defeat/crisis fabricated |
| C03 | Terminal +/-100, eligible ordinary NPC war | One persisted episode; correct winning side/perspective |
| C04 | Same trigger from battle/occupation/daily tick | Same episode/deadline, no duplicate execution |
| C05 | Complete occupation/landless pressure | Native evidence retained; not an alternative hidden peace producer |
| C06 | Reversible score falls below100 before execution | Revalidate and close recovered episode; no stale enforced peace |
| C07 | Unfinished map/battle callback | Only enqueue; no immediate realm-wide cleanup |
| C08 | LLM refuses or malformed reply | No invented consent; original game floor and opportunity budget retained |
| C09 | Provider unavailable/timeout/disconnect | No legacy fallback, no reset of either clock, no duplicate operation |
| C10 | Campaign paused or API wall-time passes | Campaign floor does not advance on wall clock alone |
| C11 | Both timing gates close while still terminal/lawful | One Native forced-settlement assessment with terminal_defeat authority |
| C12 | Counteroffer/draft/ruler changes | Old response invalid; original deadline not reset |
| C13 | Same pair starts a later war | Old epoch/response/receipt cannot authorize new war |
| C14 | Both models voluntarily agree before deadline | Ordinary exact-consent + lawful council path, not forced override |
| C15 | Normal councils oppose / no forced authority | No ordinary execution or unauthorized paid override |
| C16 | Native terminal forced rule / budget blocked | Willed opposition may follow Native forced rule; budget block still prevents execution |
| C17 | Story/alliance restriction active or becomes active | Block/revalidate; no raw MakePeaceAction bypass |
| C18 | Civil war/claim feud/exhausted internal surrender | Current internal domain owner unaffected |
| C19 | Auxiliary client/linked principal war obligations | Principal/linked-war owner retained; no independent pair peace |
| C20 | Player ruler or vassal involved at admission | Excluded from first NPC-only scope; existing player path preserved |
| C21 | Player enters during await | Revoke NPC scope, hand off, reject stale callbacks; never auto-sign |
| C22 | Forced player parley already pending | Existing inquiry preserved, no crisis adoption without explicit handoff |
| C23 | New mode with pre-existing treaty/resolution | Activation refuses unknown adoption; no silent grandfathered execution |
| C24 | Save/load before grace expiry | Same epoch/episode/game floor/remaining opportunity budget; prior session callback refused |
| C25 | Save/load with accepted NativePending | Query/recover same operation, do not submit again |
| C26 | Safe no-effects transient rejection | At most once/day, max3 attempts; original deadline unchanged |
| C27 | Partial gold/land/tribute/hostage/structural effects | ReconciliationRequired; no blind economic replay |
| C28 | Retry cap/missing gateway/unknown ownership | Explicit Blocked, no false Applied or free peace |
| C29 | War ended or realm eliminated independently | Reconcile bookkeeping, no invented crisis treaty/news |
| C30 | Receipt says applied, actual postconditions disagree | Unknown/reconciliation, not advertised success |
| C31 | Duplicate receipt/callback/reload after Applied | One outcome; no repeated costs/news or resurrection |
| C32 | Public result vs private drafts/council context | Public confirmed enforced outcome only; no privacy leak/fake LLM agreement |
| C33 | Fast-forward campaign outruns slow LLM responses | Campaign floor alone never triggers forced assessment; reserved opportunity remains |
| C34 | Different routes/TPS/context/reasoning and serial rounds | Budget covers BOTH rulers and full planned cycle, not peak TPS or one call |
| C35 | Queue starvation / repeated technical errors | Included bounded opportunity budget; retries neither reset it nor claim a final ruler response |
| C36 | Pause with provider still working | Real opportunity may elapse; campaign floor/world execution remain paused |
| C37 | Save/close/reload during slow request | Reconcile same request and preserved remaining budget; offline UTC gap alone does not expire it |
| C38 | Missing route profile or impossible hard-cap fit | Conservative explicit configured budget or blocked readiness; no silent short timeout |

Future log semantics (PROPOSED, not emitted): crisis_opened, crisis_response_stale,
crisis_recovered, crisis_deadline_reached, native_settlement_pending,
crisis_reconciliation_required, crisis_blocked, crisis_native_applied.
Carry campaign/epoch/episode/operation/revision/reason, redact private text.

Expected game evidence: score/WarWill accounting still runs; no unauthorized ordinary
foreign proposal/ratification; terminal consequences follow Native law and correct
winner; private model dialogue alone has no world effects; save/load during each
phase preserves identity and produces no duplicate treaty term costs.

Unexpected for OWNED scope: failed parley admission immediately followed by raw
"War Score forced foreign peace"; stale callback ratifies new rulers' draft;
current low score ignored because of an old queue message; unknown partial operation
retried; text consent or a news entry treated as execution. Legacy/off-scope log
messages retain their existing meaning and are not globally banned.
