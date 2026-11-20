# Bellum 1.4.12.4 — S23A, правила допуску зовнішньої дипломатії

Повні сорси на базі перевіреного кандидата 1.4.12.3 / HEAD 903f6772.
Додано незалежний C# модуль правил і виконувані регресії. Модуль поки не
підключений до ігрових викликів: LLM-керування дипломатією ще НЕ ввімкнене.
Пакти, заручники, внутрішня політика, гравецькі рішення та облік не змінені.

Перевірка лише нового модуля з кореня розпакованих сорсів:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\Tests\ForeignDiplomacyAdmission.Tests.ps1
```

Очікувано: `TOTAL PASS 65`.

Перевірка чутливості тестів до п’яти помилкових змін (лише тимчасові копії):

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\Tests\ForeignDiplomacyAdmission.Mutations.ps1
```

Очікувано: `TOTAL MUTATIONS REJECTED 5`.

Повний Windows-білдер з формуванням обох DLL і структури `Modules\BellumCivile`
збережений. Команда для окремого нового каталогу результату:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\scripts\Build-CrBellumModuleWindows.ps1 -OutputRoot C:\CR_Builds\Bellum_14124_01 -GameFolder "F:\Steam\steamapps\common\Mount & Blade II Bannerlord" -WorkshopFolder "F:\Steam\steamapps\workshop\content\261550"
```

Компіляція з реальними DLL гри та ігрові перевірки не виконані. Встановлювати
цей кандидат у гру зараз не потрібно. Тест ModuleLocalLogs має підтверджену
стару помилку Naval-фікстури; вона не виправлена в цьому етапі. Повний статус,
межі змін, журнали тестів і незакриті перевірки — у
`docs/verification/2026-11-18-foreign-admission/STAGE.md`.
