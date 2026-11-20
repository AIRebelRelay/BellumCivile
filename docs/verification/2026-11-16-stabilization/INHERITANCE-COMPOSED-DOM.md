# Inheritance UI oracle — test-only stage

ROOT CAUSE: P012C parses the constructor's raw LoadXml string and expects the Family
section that the next constructor statement actually adds via InsertSection. The
missing raw element is not evidence of a production layout loss.

TOUCH: P012CInheritanceHover.Tests.ps1, run the exact pure XML builder/helpers from
EncyclopediaHeroFamilyPrefabPatch before checking the composed DOM. DO NOT TOUCH:
production XML, builder, inheritance model, hover styles or shared game code.
MUST FIX: test the actual composed structure. MUST NOT CHANGE: all original
inheritance/grid/hint/title/claim/family/Allies and localization assertions.

Test extracts the existing InsertSection-to-class-end pure XML methods, compiles
them with a public test wrapper, and executes them on the real prefab literal.
No game types are stubbed or constructors manually rewritten. The exact current
helper tail was reviewed to contain XML-only builders. Added named scenarios:
composition preserves Family-before-Allies ordering; reapplication is idempotent;
missing Allies leaves the document unchanged. Entire original suite plus these
scenarios PASS. Full diff audited: only test setup and new checks, all old assertions
unchanged. This compiles the extracted XML helper, not the native game assembly;
actual Gauntlet rendering, native UI compatibility and save/load remain pending.
