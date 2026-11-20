# Bellum1.4.12.8 — S26A, ID запису конкретного конфлікту

Актуальний опис накопичувального ZIP; інвентар — `S26A_PACKAGE_FILES_SHA256.json`.
Попередні README/інвентарі збережені як історія.

Додано збережуваний ConflictInstanceId до WarScoreRecord: нові записи отримують
різні GUID навіть для тієї самої пари держав і дати. Старі записи з відсутнім ID
ініціалізуються через SyncData; просте читання нічого не створює. Чинні37 полів
сейву, рахунок і політичні механіки не змінені. Невалідні наявні ID не переписуються.

ID стосується життєвого циклу запису, а не гарантує незмінність учасників або
повноту ігрових callback. Майбутній шлюз мусить перевіряти актуальний світ та
відхиляти неоднозначні дублікати. Жодні відповіді LLM/таймери ще не прив’язані
до цього поля автоматично.

31 фінальна перевірка ID та перевірка незмінності старих полів PASS.
Накопичувальний запуск16 наборів PASS; після нього додатково пройшли2 нові
перевірки завантаження/першого збереження старого сейву на підставному IDataStore.
П’ять навмисних помилок виявлені. Реальний serializer Bannerlord НЕ перевірений.

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\scripts\Test-ForeignDiplomacyCheckpoint.ps1
```

Додаткова перевірка чутливості тестів:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\Tests\WarConflictIdentity.Mutations.ps1
```

Щоб ID старого сейву закріпився, потрібне наступне збереження новою версією.
Повторне завантаження незміненого старого файлу не доводить тяглість нового ID.
Зараз на ПК нічого робити не потрібно. Windows-білд і реальний game/save-load
залишаються NOT_RUN. Збережений повний білдер обох DLL:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\scripts\Build-CrBellumModuleWindows.ps1 -OutputRoot C:\CR_Builds\Bellum_14128_01 -GameFolder "F:\Steam\steamapps\common\Mount & Blade II Bannerlord" -WorkshopFolder "F:\Steam\steamapps\workshop\content\261550"
```

Межі, call chain, докази й обмеження: `docs/verification/2026-11-18-war-identity/`.
