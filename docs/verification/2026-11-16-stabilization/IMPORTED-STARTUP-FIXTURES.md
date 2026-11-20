# Startup fixture inventory — test-only stage

ROOT CAUSE: P014A's legacy source gate requires Lordship/retainer/Clan Household
fixture dependencies to be absent, predating their port. Current startup probe
executes real imported initialization hooks and has specific deferred-install,
no-early-GameTexts and no-early-optional-VM checks.
TOUCH: one assertion in P014AHeroFamilyHarness.Tests.ps1. DO NOT TOUCH: startup
probe C#, type registration, dependencies, production hooks or any other assertion.
MUST FIX: require imported-feature startup safety cases. MUST NOT CHANGE: family,
optional adapters, hostage history and CampaignUIHelper fixture requirements.
Whole source suite PASS. Full diff audited. This inventories the existing native
fixtures; it does NOT execute them or claim their net472/game result. The script's
old generic footer remains historical text; actual PowerShell execution occurred.
