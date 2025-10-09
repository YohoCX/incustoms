**Цель**
- Только DataGrip: подключение к БД, запуск SQL‑миграций из папки с миграциями, показ полной ER‑диаграммы схемы.

**Требования**
- DataGrip установлен, есть доступ к PostgreSQL (host/port/user/password).
- SQL‑файлы миграций `0001...0007` доступны локально (откройте репозиторий в DataGrip через `File → Open...`).

**1) Подключение к PostgreSQL в DataGrip**
- Нажмите `+` в панели Database → `PostgreSQL`.
- Укажите `Host`, `Port`, `User`, `Password` → `Test Connection` → `OK`.
- Если нужной базы нет: откройте Query Console (иконка консоли на подключении к серверной БД, например `postgres`) и выполните:
  - `CREATE DATABASE incustoms;`
- В свойствах источника данных выберите базу `incustoms` как Default (или создайте отдельный Data Source, указывая Database = `incustoms`).

**2) Импорт SQL‑файлов миграций в DataGrip**
- `File → Open...` и укажите корень репозитория (папка с миграциями).
- Убедитесь, что в Project/File View видны файлы:
  - `0001_entities.sql`
  - `0002_codes.sql`
  - `0003_fea.sql`
  - `0004_documents.sql`
  - `0005_document_joins.sql`
  - `0006_payment.sql`
  - `0007_analytics_autocomplete_audit.sql`

**3) Запуск миграций внутри DataGrip (весь пакет)**
- Меню `Run → Edit Configurations...` → `+` → выберите `SQL Script`.
- `Data Source`: укажите подключение к базе `incustoms`.
- `Scripts`: добавьте все файлы миграций в порядке 0001 → 0007.
- Опции запуска:
  - `Stop on error`: включить,
  - `Transaction control`: Off (или Per statement),
  - `DDL Transaction`: выключено.
- Нажмите `Run`. Дождитесь завершения без ошибок.

**4) Альтернатива: запуск по одному файлу**
- Откройте `0001_entities.sql`, выберите в верхней панели нужный `Data Source` (`incustoms`).
- Нажмите `Run` (Ctrl/Cmd+Enter). Повторите для `0002` … `0007` по порядку.

**5) Обновить интроспекцию и проверить объекты**
- В Database Explorer кликните `Sync` (двойная стрелка) на источнике `incustoms`.
- Проверьте, что в `Schemas → public` появились таблицы (например, `banks`, `ccd_documents`, `ccd_items`, `payment_*`).

**6) Показ ER‑диаграммы всей схемы**
- В Database Explorer: правая кнопка на схеме `public` → `Diagrams` → `Show Visualization`.
- В окне диаграммы:
  - Включите авто‑размещение (`Layout → Orthogonal/Hierarchical`) для удобного вида.
  - Откройте настройки (шестерёнка): включите отображение внешних ключей/индексов по желанию.
  - Для очень большой схемы используйте фильтр (лупа/поиск) или масштабирование (Ctrl/Cmd + колесо).
- Экспорт: иконка дискета/экспорт → `Save Diagram...` (PNG/SVG/PDF).