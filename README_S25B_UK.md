# Bellum1.4.12.7 — S25B, політика двох годинників

Поточний опис накопичувального ZIP. Інвентар — `S25B_PACKAGE_FILES_SHA256.json`;
попередні README/аудити збережені як історія.

Додано `ForeignCrisisWindowPolicy.cs`: одночасна перевірка мінімуму ігрових днів
та наданого LLM бюджету реального часу. Пауза забороняє перехід до оцінки поразки;
технічна помилка не є фінальною відповіддю; повторні перевірки не скидають і не
подвоюють час. Повернення годинників назад дає явну відмову.

59 нових перевірок і всі15 накопичувальних наборів PASS. П’ять навмисних помилок
нової політики також виявлені.

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\scripts\Test-ForeignDiplomacyCheckpoint.ps1
```

Додаткова перевірка чутливості тестів:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\Tests\ForeignCrisisWindow.Mutations.ps1
```

Це лише політика над переданими значеннями часу, без активного ігрового таймера.
Вона не вимірює час/TPS, не зберігається автоматично в сейві й не виконує мир.
Результат ReadyForNativeAssessment — дозвіл перевірити актуальний стан засобами
Bellum, а не згода монархів і не дозвіл застосувати договір.

На ПК зараз нічого робити не потрібно. Windows-білд і game/save-load NOT_RUN.
Збережений білдер обох DLL та повної структури мода:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\scripts\Build-CrBellumModuleWindows.ps1 -OutputRoot C:\CR_Builds\Bellum_14127_01 -GameFolder "F:\Steam\steamapps\common\Mount & Blade II Bannerlord" -WorkshopFolder "F:\Steam\steamapps\workshop\content\261550"
```

Точні межі й докази: `docs/verification/2026-11-18-crisis-window/`.
