# Unified agenda hint — test-only source/XML stage

ROOT CAUSE: the author layout replaces the old activity-only IsVisible wrapper
with BellumFactionAgendaHint around actual RivalsText agenda content. The current
XML is byte-identical to author 8a08e0c. Reinstating the old visibility wrapper
would risk hiding the shared agenda content; no production layout is changed.

TOUCH: one obsolete XML assertion in CourtActivityLifecycle.Tests.ps1. Require
the current named wrapper, both existing hover handlers, actual visible text child
and VM null-safe ExecuteBeginHint call. DO NOT TOUCH: UI XML, VM, activity selection,
text/localization or gameplay. MUST FIX: verify current nonempty/null-safe hint
composition. MUST NOT CHANGE: other source assertions. Whole source/XML suite PASS,
full diff audited. This does not establish rendered Gauntlet correctness.
