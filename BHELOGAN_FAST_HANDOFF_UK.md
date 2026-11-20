# Bellum Civile — короткий хендовер для Bhelogan (19.11.2026)

**Поточна тестова база:** 1.4.12.13. Windows gate 7/7 (Core + Naval), gameplay save/load: 6 війн, 4 активні, 2 завершені; усі ConflictInstanceId і Native Witness стабільні. Стара застосована treaty proposal є історичною. **Не доведено:** живе виконання нового договору, повторна війна після Bellum-миру, відхилення живого stale Pending, відновлення після пропущеного Native peace callback.

**Новий кандидат:** 1.4.12.14 — тільки QA-інструмент, НЕ публічний реліз. Виробничі `ForeignTreatyBehavior`, `WarScoreBehavior`, `HostageTreatyRecovery`, збереження і відповідні модулі не змінені проти 1.4.12.13. Консольний QA-метод компілюється тільки при `BellumTreatyQa=true`; звичайний білд не включає його. Форсовані white-peace переговори використовують штатний `TryQueueAiParley` та звичайне щоденне settlement. Це **не** перевірка органічної згоди рад.

**Як зібрати на Windows:** див. `CR_TREATY_QA_STAGE.md`; окремі шляхи D: (казарма) і F: (вдома). Командний runner `scripts/Verify-CrBellumNativeWitnessWindows.ps1` перевіряє SHA inventory, 8 тестових груп, потім повний Core+Naval package. Продуктову збірку з QA-флагом не випускати.

**Що тестувати сьогодні:** на копії сейву оголошена війна Вландії—Нордів; 1) dump ID і witness; 2) `civilwars.qa_force_white_peace Vlandia | Nords | CONFIRM_TEST_SAVE`; 3) ігрова доба; 4) звірити `Applied`, завершення старого ID, відсутність війни Native; 5) save/load; 6) повторне `campaign.declare_war Vlandia | Nords`; 7) новий ID, old Applied не впливає на нову війну. Якщо консоль повернула REJECTED — НЕ обходити guard, забрати Bellum logs.

**Наступні реальні пріоритети:** (P0) live treaty lifecycle; (P0) native missed peace / war epoch authority invariant; (P0) back-to-back war + stale Pending protection; (P1) інтеграція дипломатичних рішень у CR Bridge після доказового lifecycle. Немає дозволу підключати LLM peace executor. Не копіювати код AI Influence. Не зливати в main без регресій/гри.
