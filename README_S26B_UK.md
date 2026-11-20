# Bellum 1.4.12.9 — S26B, пасивний пошук конфлікту за ID

Актуальний накопичувальний ZIP; інвентар `S26B_PACKAGE_FILES_SHA256.json`.
Попередні README та інвентарі — історичні.

Новий API `BellumIntegration.GetExistingForeignConflictByInstance` повертає
незмінний знімок лише для унікального запису зовнішньої війни, з точним порядком
сторін, чинними державами й поточною взаємною ворожістю. Дублікати, завершені
записи, невідомі/пошкоджені ID та невідповідні сторони відхиляються.
Читання не ініціалізує й не ремонтує записи; потрібен потік кампанії.

Три нові production-файли: `ForeignConflictIdentitySnapshot.cs`,
`BellumIntegrationConflictIdentity.cs`, `Behaviors/WarScoreConflictIdentityReader.cs`.
Решта змін: версія, приклад команди білду, підключення тесту до checkpoint.
Сейв-схема, старі API, механіки й повний білдер Core + Naval збережені.

Це спостереження, а не дозвіл на мир чи іншу дію. ID позначає життя запису:
пропущений callback миру може залишити старий активний запис; API не доводить
ідентичність фактичного нового оголошення війни. Згода, повноваження, видимість
і законність перевіряються окремо. Жоден LLM-маршрут або таймер не підключений.

49 перевірок нового API PASS; 17 наборів checkpoint PASS; 5 навмисних поломок
відловлено. Компілювався тестовий зріз реальних нових класів і guard з підставним
світом. Повний Windows/net472-білд, ABI гри, serializer і game/save-load — NOT_RUN.
Зараз на ПК нічого робити не потрібно.

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\scripts\Test-ForeignDiplomacyCheckpoint.ps1
pwsh -NoProfile -ExecutionPolicy Bypass -File .\Tests\ForeignConflictIdentity.Mutations.ps1
```

Пізніше повна збірка з кореня сорсів (новий OutputRoot):

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\scripts\Build-CrBellumModuleWindows.ps1 -OutputRoot C:\CR_Builds\Bellum_14129_01 -GameFolder "F:\Steam\steamapps\common\Mount & Blade II Bannerlord" -WorkshopFolder "F:\Steam\steamapps\workshop\content\261550"
```

У грі окремо перевірити: точний активний ID дає RecordedActive; завершений —
Ended; переставлені сторони — ParticipantMismatch; після миру немає RecordedActive.
Це статуси API, автоматичних нових лог-рядків цей етап не додає.
Докази, межі та повний diff: `docs/verification/2026-11-18-identity-reader/`.
