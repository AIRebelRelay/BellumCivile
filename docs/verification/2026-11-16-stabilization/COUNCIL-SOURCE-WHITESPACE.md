# Council batch observer — test-only stage

ROOT CAUSE: SelectBatch and context are separated by a newline in the current
production source. The legacy exact Contains assertion mistakes whitespace for a
missing batch arbitrator. TOUCH: that single assertion in CouncilAgendaLifecycle.
Use a regex permitting only whitespace between the same method and first argument.
DO NOT TOUCH: selector, arguments, rules, other checks or game code.
MUST FIX: accept equivalent C# formatting. MUST NOT CHANGE: require the same batch
method and context argument. Whole source/XML suite passes 29 assertions; full
diff is one assertion expression, no bypass or fallback. No gameplay claim.
