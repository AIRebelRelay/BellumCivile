# Bellum module-local logging hotfix 1.4.12.2

Base: feature/cr-existing-recorded-names-2026-11-16 at 6bb75ba814d20c9423795ed3ec2372ebb372dd7e. No merge/release deployment.

ROOT CAUSE: BellumCivileLogger.LogDirectory hardcoded Documents/Configs/ModLogs. All 879 normal-log, 1 yearly-report and 7 flush call sites across 241 runtime caller files use this central logger. The complete runtime C# file-writer scan finds only BellumCivileLogger.cs (including optional companion sources).

TOUCH: BellumCivileLogger.cs directory resolution only; AssemblyInfo file/informational versions and module XML version 1.4.12.2; README identity/path; isolated logger tests and full-module Windows builder.
DO NOT TOUCH: existing logger append/format/buffering/flush/locking/5 MiB rotation/5-day cleanup/debugger fallback, political systems, settings, saves, integration APIs, CR or Bridge.
MUST FIX: daily logs and bellumcivile_yearlyreports.txt share the loaded module root/logs destination; no file fallback in Documents/AppData.
MUST NOT CHANGE: normal/yearly contents, pruning isolation, exception containment and all existing gameplay/API behavior.

Regression contract and evidence: Tests/ModuleLocalLogs.Tests.ps1 compiles the unmodified production logger against a TaleWorlds Debug double. 13 named cases PASS: module root with spaces, invalid layout, normal format/rotation, dated pruning retaining unrelated logs, blank normal/yearly handling, yearly location/general category, write failure/debug fallback, no external path, actual packaging block using fixture DLL, all assets/license byte copies, XML version. Windows script parses and rejects actual Linux entry without output. Full runtime diff: logger resolver plus version metadata only; all other production files and assets byte-identical to base.

Build: scripts/Build-CrBellumModuleWindows.ps1 builds core Bellum only with real exact project references and explicit Workshop properties, one SDK executable, new isolated output/artifact/intermediate directories, and no game deployment. Produces Modules/BellumCivile containing matching SubModule.xml, DLL, GUI, ModuleData, LICENSE.txt and logs. Optional Naval companion is not built by this core-only command. Package block fixture is not proof of a full game build.

Pending: actual Windows/net472 compilation and live gameplay/log validation. Previous base built successfully on user PC; hotfix still needs rebuild. Verify Modules/BellumCivile/logs/BellumCivileYYYYMMDD.log after campaign launch and yearly report when generated; old Documents files must not receive new writes. Old files are neither copied nor deleted. The output module folder replaces the matching installed module files after game exit; preserve user customization and separately managed optional companion.
