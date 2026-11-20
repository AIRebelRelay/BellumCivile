# Bellum1.4.12.6 — S25A, розрахунок часу на повний цикл LLM

Актуальний опис цього накопичувального ZIP; попередні README/аудити — історія.
Поточний інвентар — `S25A_PACKAGE_FILES_SHA256.json`.

Додано `ForeignCrisisBudgetEstimator.cs`: обидва монархи, усі послідовні раунди,
дозволені повтори, черга Relay, затримка провайдера або оцінка через TTFT/TPS,
окремий запас для thinking, загальний запас та мінімум часу.
Якщо весь цикл не вкладається у верхню межу, результат — відмова, без обрізання
часу повільній моделі. Профілі й фактичні швидкості NanoGPT тут не вигадані.

64 перевірки калькулятора PASS; п’ять навмисних помилок виявлені. Всі14 наборів
накопичувального запуску PASS, включно з пакуванням двох DLL.

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\scripts\Test-ForeignDiplomacyCheckpoint.ps1
```

Додаткова перевірка чутливості нових тестів:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\Tests\ForeignCrisisBudget.Mutations.ps1
```

Це лише калькулятор: жоден ігровий обробник його поки не викликає. Таймер,
збереження його стану, вимірювання провайдера й примусове врегулювання ще
не підключені. Нічого встановлювати або тестувати на ПК зараз не потрібно.

Windows-компіляція з реальними DLL гри та гра/save-load залишаються NOT_RUN.
Повний білдер двох DLL і структури `Modules\BellumCivile` збережений:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\scripts\Build-CrBellumModuleWindows.ps1 -OutputRoot C:\CR_Builds\Bellum_14126_01 -GameFolder "F:\Steam\steamapps\common\Mount & Blade II Bannerlord" -WorkshopFolder "F:\Steam\steamapps\workshop\content\261550"
```

Докази, формула, межі й відкриті перевірки:
`docs/verification/2026-11-18-crisis-budget/`.
