# Rivalry white-peace source contract — test-only stage

ROOT CAUSE: rivalry rejection was folded into the first compound condition of
ResolveInternalWhitePeace, together with null/BeginResolution checks. The old test
requires a separate one-line return, so it falsely reports absent protection.

TOUCH: one assertion in CivilWarRivalry.Tests.ps1. DO NOT TOUCH: game code, war
resolution, rival absorption, score, claimant/legal Crown or persistence.
MUST FIX: require both current rejection points: the compound commit guard with
IsRivalryScore first (short-circuit before BeginResolution), and the winner-less
negotiation refusal in CanNegotiateInternalOutcome. MUST NOT CHANGE: any other
assertion. Full source script PASS. Full diff audited: one assertion strengthened
to require both gates. Native rival campaign/tribunal/save evidence still pending.
