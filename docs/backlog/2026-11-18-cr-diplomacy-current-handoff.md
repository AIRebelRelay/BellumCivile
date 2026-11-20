> Update 19.11.2026: S27 1.4.12.10 **PASS** on Windows: 24/24 selected tests, Core+Naval 0 warnings/errors, read-only dump of five historical wars retained the same IDs and `8accfa2bbb3056d051e6dad4605eff5fca86cfa67daf6760a78d684e36ae4bf7` fingerprint across save/load. This proves recorded ID persistence **only**. New 1.4.12.11 Native witness candidate is described in `README_CR_NATIVE_WAR_PROVENANCE_UK.md`; Windows/game not yet tested, cannot claim missed-peace lifecycle fixed. The remainder of this document is historical baseline.

# Поточний беклог CR × Bellum —18.11.2026

Пріоритетний стан для поточної CR-гілки роботи. Старі backlog-записи зберігаються
як історія, зокрема AII-specific alpha stack за30.10. Поточна ціль — Calradia
Remembers, AI Influence лише як натхнення без копіювання коду. Вимога мінімізувати
навантаження ручними owner-тестами зберігається. Користувач виконав наведені нижче
перевірки добровільно сьогодні; це не постійна доступність для кожного етапу.

## Доведено

- Native candidate1.4.12.9 із test-only S26E.
- Windows:22/23 групи початкового загального запуску PASS; після виправлення
  file-lock cleanup —24/24 ModuleLocalLogs + CLEANUP_PASS окремим запуском.
- Фактичний Windows/net472 Core+Naval build успішний,0 warnings/errors.
- Повна папка мода та ZIP сформовані в C:\CR_Builds\Bellum_14129_01.
- Користувач підтвердив запуск, нове збереження й повторне завантаження без крашу.
- Фактичний BellumCivile20261118.log не містить явних exceptions/errors;
  logger/War Sails реєстрація спостерігаються. Це обмежений30-рядковий лог.

## Відкриті етапи в порядку залежностей

| Пріоритет | Робота | Поточний статус / критерій |
| --- | --- | --- |
|NEXT — S27 candidate|Пасивна команда dump war record identities|1.4.12.10 source candidate: `civilwars.dump_war_ids` з read-only fingerprint; Windows/ігровий build і до/після save/load **NOT_RUN**. Не вважати ID persistence доведеною до runtime порівняння|
|P0|Native war lifecycle/provenance|RecordID не гарантує окреме Native war declaration. S26C6 cases відтворюють reuse при missed peace. Не виправлено; архітектурний review перед shared змінами|
|P0|Застарілі LLM відповіді|Execution має відхиляти old war/ruler/session/terms/history; RecordedActive не є authority/consent|
|P0|Кризова персистентність|Окремі episode, clock budget, revisions, revalidation; ordinary intent journal не приймає TerminalForeignWar|
|P0|Native-owned treaty executor/receipt|НЕ реалізований для CR protocol; partial/deferred hostage effects не replay; unknown receipt не Applied|
|P0|Єдиний owner зовнішньої дипломатії|CR direct mediate_peace, deterministic strategy та Bellum fallbacks — узгодити без double peace/war, збереження internal consumers|
|P1|Bridge0.2.0 source checkpoint|Окремо build+runtime validate; Native успіх не є доказом Bridge. Не встановлювати source archive як готовий runtime|
|P1|Реальна calibration LLM/TPS|Calculator і dual-clock policy є, runtime/calibration/persistence ще не підключені. Не вигадувати latency/default thinking|
|P1|Добровільні пакти/заручники через новини|Обговорений простіший напрям; конкретний контракт/visibility/Feed/memory не реалізовані цими стадіями|

## Межі

Не переходити до execution лише через compile/smoke PASS. ID continuity, новий
journal persistence, restoration receipts у реальному сейві, Native epoch та
late reply invalidation — окремі докази. До наступної production-правки знову
перевірити repository/branch/HEAD і порівняти remote з локальними накопичувальними
сорсами. Поточні S23–S26 файли не замінювати старішим remote snapshot.

Root cause/call chain, exact TOUCH/DO NOT TOUCH/MUST FIX/MUST NOT CHANGE,
regression contract -> minimum diff -> full audit -> targeted tests -> build ->
доречний Native/game gate. Production bump; docs/test-only версія незмінна.
Повний стан та наступна boundary-підготовка — HANDOFF_UK.md у корені handoff ZIP.
