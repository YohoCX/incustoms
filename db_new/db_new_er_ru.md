# Документация по сущностям и связям (ERD) — `db_new`

## Обзор
- Полностью нормализованная схема для системы ГТД (CCD) с разделением справочников и бизнес‑данных через связывающие (junction) таблицы.
- Центральные сущности: `ccd_documents` (шапка декларации) и `ccd_items` (позиции). Все связи со справочниками и контрагентами вынесены в отдельные таблицы `ccd_document_*` и `ccd_item_*`.
- Модули: базовые сущности (платформа), справочники (codes), ВЭД (FEA), документы (CCD), платежи/биллинг, аналитика/автодополнение/аудит.

## Архитектурные принципы
- Нормализация: `ccd_documents` не содержит прямых FK на справочники — только через `ccd_document_*`/`ccd_item_*`.
- Junction‑паттерн: каждая связывающая таблица хранит `id` (PK), `document_id` или `item_id` (FK с `ON DELETE CASCADE`), `{ref}_id` на справочник, опциональные поля роли/типа, и стандартные audit‑поля.
- Типобезопасность: широкое применение ENUM, валидируемых на уровне БД.

---

## Модульная структура и ключевые связи

### Платформа (0001_entities.sql)
- `users` → `roles`: многие‑к‑одному (роль пользователя).
- `users` → `organizations`: многие‑к‑одному (тенант/владелец данных).
- `legal_users` ↔ `users`: один‑к‑одному (юридический профиль пользователя).
- `individual_users` ↔ `users`: один‑к‑одному (физлицо профиль).
- `banks`: справочник банков, используется в ВЭД и связях документов.
- `files`: метаданные файлов (хранилище s3/minio/local).

### Справочники (0002_codes.sql)
- `codes_*`: таблицы кодов (режимы, посты, страны, районы, валюты, инкотермс, формы оплаты, типы сделок, транспорт, единицы, ТН ВЭД, т.п.).
- Пример связи: `available_units_for_hs` — допустимые единицы измерения для конкретного кода ТН ВЭД.

### ВЭД (0003_fea.sql)
- `fea_legal_entities`, `fea_individual_entities`, `fea_legal_entities_short`, `fea_partners`, `fea_partners_additional`.
- Связь с документами только через `ccd_document_*` (см. ниже).

### Документы (0004_documents.sql, 0005_document_joins.sql)
- `ccd_documents`: шапка декларации. Внутренние связи:
  - `created_by_user_id` → `users` (кто создал).
  - `organization_id` → `organizations` (владелец).
  - `main_item_id` → `ccd_items` (основная позиция; опционально).
- `ccd_items`: строки декларации, FK `document_id` → `ccd_documents` (многие‑к‑одному).
- Junction‑таблицы документа (выборки по графам):
  - `ccd_document_regimes` → `codes_regimes`.
  - `ccd_document_posts` → `codes_posts`.
  - `ccd_document_countries` → `codes_countries`.
  - `ccd_document_transport_types` → `codes_transport_types`.
  - `ccd_document_delivery_terms` → `codes_delivery_terms`.
  - `ccd_document_payment_forms` → `codes_payment_forms`.
  - `ccd_document_currencies` → `codes_currencies`.
  - `ccd_document_deal_types` → `codes_deal_types`.
  - `ccd_document_districts` → `codes_districts`.
  - `ccd_document_movement_types` → `codes_movement_types`.
  - `ccd_document_banks` → `banks`.
  - `ccd_document_vehicle_types` → `codes_vehicle_types`.
  - `ccd_document_shipment_forms` → `codes_shipment_forms`.
- Junction‑таблицы документа ↔ ВЭД:
  - `ccd_document_legal_entities` → `fea_legal_entities`.
  - `ccd_document_individual_entities` → `fea_individual_entities`.
  - `ccd_document_legal_entities_short` → `fea_legal_entities_short`.
  - `ccd_document_partners_additional` → `fea_partners_additional`.
- Junction‑таблицы позиции:
  - `ccd_item_hs_codes` → `codes_hs`.
  - `ccd_item_origin_countries` → `codes_countries`.
  - `ccd_item_units` → `codes_units`.
  - `ccd_item_districts` → `codes_districts`.
- Доп. сущности по позициям:
  - `ccd_item_previous_documents`, `ccd_item_accompanying_documents`, `ccd_item_imei_codes`, `ccd_item_vehicle_details` (детализация по позициям и документам‑основаниям).

### Платежи и биллинг (0006_payment.sql)
- `payment_providers`, `tariff_plans`, `traffic_limits`, `payment_invoices`, `payment_invoice_items`, `payment_sessions`, `payment_transactions`, `payment_refunds`, `webhook_events`, `idempotency_keys`, `payment_audit_log`, `ocr_jobs`.
- Как правило, привязаны к `organizations` и/или внешним идентификаторам провайдеров; операции логируются и идемпотентны.

### Аналитика, автодополнение, аудит (0007_analytics_autocomplete_audit.sql)
- `analytics_events`, `analytics_sessions`, `analytics_daily_metrics` — события и метрики.
- `autocomplete_*` — персональная и общая история подсказок/кеша.
- `audit_log`, `document_versions`, `security_events`, `data_access_log`, `dashboard_templates`, `saved_reports` — аудит, версии, доступ, сохраненные отчеты/дашборды.

---

## Карточки основных сущностей

### `ccd_documents` (шапка декларации)
- Назначение: контейнер всех сведений декларации через связи.
- Важные поля: `id`, `created_at`, `status`, `created_by_user_id` → `users`, `organization_id` → `organizations`, `main_item_id` → `ccd_items`.
- Связи: см. раздел junction‑таблиц выше; все связи «один документ — много значений» через отдельные таблицы.

### `ccd_items` (позиции)
- Назначение: строки с товаром/услугой.
- Поля: `id`, `document_id` → `ccd_documents`, статус/аудитные поля.
- Связи: `ccd_item_*` коды/страны/единицы/районы; доп. таблицы для документов‑оснований, приложений, IMEI и ТС.

### ВЭД‑сущности
- `fea_legal_entities`, `fea_individual_entities`, `fea_legal_entities_short`, `fea_partners`, `fea_partners_additional` — используются документами только через `ccd_document_*`.

### Платформа
- `users` ↔ `roles`/`organizations`; профили: `legal_users`, `individual_users` (1:1).
- `banks` — справочник; используется напрямую в `ccd_document_banks` и реквизитах ВЭД.
- `files` — общая таблица метаданных файлов (используется в документах, например для исходных счетов и приложений).

---

## ENUM (основные)
- `entity_status`: active | deleted | archived — статус записей (общесистемно).
- `storage_type`: s3 | minio | local — тип хранилища файлов.
- `vat_status_type`: payer | non-payer — НДС‑статус юр.лица.
- `document_status`: draft | pending | submitted | accepted | rejected | completed — статусы документа.
- `item_status`: draft | pending | completed — статусы позиции.
- `document_entity_role`: exporter | consignee | declarant | financial | payer | carrier — роль участника ВЭД в документе.
- `document_post_type`: processing | border | transit — тип таможенного поста.
- `document_country_type`: trade | dispatch | destination | vehicle_reg | border_vehicle_reg | transit_destination — роль страны в документе.
- `document_transport_role`: main | border | at_border | inside_country — роль транспорта.
- `document_currency_type`: contract | settlement — тип валюты.
- Платежи/биллинг: `payment_provider_type`, `client_type`, `payment_status`, `subscription_status`, `tariff_type`, `usage_type`.

---

## Списки таблиц по модулям
- Платформа: `banks`, `organizations`, `roles`, `users`, `legal_users`, `individual_users`, `files`.
- Справочники: `codes_regimes`, `codes_posts`, `codes_countries`, `codes_districts`, `codes_currencies`, `codes_delivery_terms`, `codes_payment_forms`, `codes_deal_types`, `codes_transport_types`, `codes_units`, `codes_hs`, `available_units_for_hs`, `codes_hs_tariff_rules`, `currency_exchange_rate`, `codes_movement_types`, `codes_brands`, `codes_energy_classes`, `codes_manufacturers`, `codes_package_types`, `codes_car_colors`, `codes_investment_programs`, `codes_accompanying_documents`, `codes_notes`, `codes_vehicle_types`, `codes_shipment_forms`.
- ВЭД: `fea_partners`, `fea_partners_additional`, `fea_legal_entities_short`, `fea_legal_entities`, `fea_individual_entities`.
- Документы: `ccd_documents`, `ccd_items`, `ccd_item_previous_documents`, `ccd_item_accompanying_documents`, `ccd_item_imei_codes`, `ccd_item_vehicle_details` и все `ccd_document_*`, `ccd_item_*` связки.
- Платежи: `payment_providers`, `tariff_plans`, `traffic_limits`, `ocr_jobs`, `payment_invoices`, `payment_invoice_items`, `payment_sessions`, `payment_transactions`, `payment_refunds`, `webhook_events`, `idempotency_keys`, `payment_audit_log`.
- Аналитика/Аудит/Автодоп.: `analytics_events`, `analytics_sessions`, `analytics_daily_metrics`, `autocomplete_user_history`, `autocomplete_popular_values`, `autocomplete_suggestions_cache`, `audit_log`, `document_versions`, `security_events`, `data_access_log`, `dashboard_templates`, `saved_reports`.

---

## Кардинальности и правила каскада
- Все `ccd_document_*` и `ccd_item_*` содержат FK на родитель (`document_id`/`item_id`) с `ON DELETE CASCADE` — удаление документа/позиции удаляет только связанные строки.
- Связи на справочники (`codes_*`, `banks`, ВЭД‑таблицы) не каскадируют удаление справочников на документы.
- Там, где применимо, junction‑таблицы содержат тип/роль (например, `document_entity_role`, `document_country_type`, `document_transport_role`).

---

## Примечания по эксплуатации
- Для выборок по документу используйте объединения через `ccd_document_*`/`ccd_item_*` по конкретной роли/типу, а не прямые FK.
- Для автозаполнения реквизитов ВЭД используйте `fea_*` таблицы через соответствующие junction‑таблицы документа.
- Справочники (`codes_*`) версионно‑независимы от документов; документ хранит «срез» через собственные custom‑поля в junction‑таблицах, где это предусмотрено.

---

Документ сгенерирован на основе SQL в `db_new/` и резюме схемы в `db_new/SCHEMA_SUMMARY.md`.

