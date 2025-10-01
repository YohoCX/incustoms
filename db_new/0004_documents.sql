-- ============================================================================
-- CCD Documents and Items
-- ============================================================================
-- Main document tables WITHOUT direct foreign key joins to reference tables.
-- All relationships to codes/FEA tables are managed via junction tables (0005)
--
-- Tables:
-- - ccd_documents: Declaration header (one per declaration)
-- - ccd_items: Declaration line items (goods positions)
-- ============================================================================

-- ENUMS for documents
CREATE TYPE document_status AS ENUM ('draft', 'pending', 'submitted', 'accepted', 'rejected', 'completed');
CREATE TYPE item_status AS ENUM ('draft', 'pending', 'completed');

COMMENT ON TYPE document_status IS 'Статус документа: draft (черновик) | pending (ожидает) | submitted (подан) | accepted (принят) | rejected (отклонен) | completed (завершен)';
COMMENT ON TYPE item_status IS 'Статус позиции: draft (черновик) | pending (ожидает) | completed (завершена)';

-- ============================================================================

-- CCD Document header
CREATE TABLE IF NOT EXISTS ccd_documents
(
    id                     INT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    created_at             timestamptz       NOT NULL DEFAULT NOW(),
    updated_at             timestamptz,
    deleted_at             timestamptz,
    status                 document_status   NOT NULL DEFAULT 'draft',

    created_by_user_id     INT REFERENCES users (id),
    organization_id        INT REFERENCES organizations (id),
    main_item_id           INT REFERENCES ccd_items (id),

    -- Graph 1: Declaration type
    direction_code         direction_code    NOT NULL,
    third_subdivision      VARCHAR(3),

    -- Graph 3/5: Counts (auto-calculated)
    total_sheets           INT,
    items_count            INT               NOT NULL DEFAULT 0,

    -- Graph 11: Trade country offshore flag
    trade_country_offshore BOOLEAN,

    -- Graph 12: Total customs value (auto-calculated)
    customs_value_total    NUMERIC(18, 2),

    -- Graph 13: USD/UZS exchange rate
    usd_uzs_rate           NUMERIC(18, 6),

    -- Graph 18: Vehicle details
    vehicle_vin            VARCHAR(32),
    driver_name            TEXT,

    -- Graph 19: Container flag
    is_container           BOOLEAN,

    -- Graph 20: Delivery/payment details
    delivery_terms_place   TEXT,

    -- Graph 22: Invoice total
    invoice_total          NUMERIC(18, 2),

    -- Graph 23: Contract currency rate to UZS
    contract_currency_rate NUMERIC(18, 6),

    -- Graph 28: Payer bank details
    payer_bank_account     TEXT,
    payer_mfo              VARCHAR(20),

    -- Graph 30: Goods location
    location_license_number TEXT,
    location_license_date   DATE,
    location_address        TEXT,
    location_station_name   TEXT,

    -- Graph 37: Procedure code
    procedure_code         VARCHAR(7),

    -- Graph 40: Previous documents summary (until separate table created)
    previous_docs_summary  TEXT,

    -- Graph 49: Warehouse license
    warehouse_license_number TEXT,
    warehouse_license_date DATE,

    -- Graph 50: Responsible person and obligations
    responsible_full_name  TEXT,
    responsible_pinfl      VARCHAR(14),
    responsible_authority  TEXT,
    obligation_due_date    DATE,

    -- Graph 54: Declaration place/date, contacts, broker contract
    declaration_place      TEXT,
    declaration_date       DATE,
    contact_full_name      TEXT,
    contact_email          TEXT,
    contact_phone          TEXT,
    broker_contract_number TEXT,
    broker_contract_date   DATE,
    declarant_reference    TEXT,

    -- "C": Special regime fields
    external_contract_id   TEXT,
    regime_dates           jsonb             NOT NULL DEFAULT '{}',

    -- "B"/"D": System totals and customs decisions
    totals_b               jsonb             NOT NULL DEFAULT '{}',
    customs_decisions      jsonb             NOT NULL DEFAULT '{}',

    -- Constraints
    CONSTRAINT ccd_items_count_ck CHECK (items_count >= 0),
    CONSTRAINT ccd_procedure_len_ck CHECK (procedure_code IS NULL OR length(procedure_code) = 7)
);

CREATE INDEX IF NOT EXISTS idx_ccd_documents_created_at ON ccd_documents (created_at);
CREATE INDEX IF NOT EXISTS idx_ccd_documents_direction ON ccd_documents (direction_code);
CREATE INDEX IF NOT EXISTS idx_ccd_documents_status ON ccd_documents (status);
CREATE INDEX IF NOT EXISTS idx_ccd_documents_created_by ON ccd_documents (created_by_user_id);
CREATE INDEX IF NOT EXISTS idx_ccd_documents_organization ON ccd_documents (organization_id);
CREATE INDEX IF NOT EXISTS idx_ccd_documents_declaration_date ON ccd_documents (declaration_date);

COMMENT ON TABLE ccd_documents IS 'CCD (декларация) — заголовок. Содержит скалярные поля по графам: 1,3,5,11–13,18–20,22–23,28–30,37,48–50,54, а также спецполя "C", итоги "B" и решения "D". Все ссылки на справочники и стороны вынесены в отдельные таблицы (0005)';
COMMENT ON COLUMN ccd_documents.id IS 'Первичный ключ';
COMMENT ON COLUMN ccd_documents.created_at IS 'Дата/время создания записи';
COMMENT ON COLUMN ccd_documents.updated_at IS 'Дата/время изменения';
COMMENT ON COLUMN ccd_documents.deleted_at IS 'Дата/время удаления (soft delete)';
COMMENT ON COLUMN ccd_documents.status IS 'Статус CCD (draft/pending/submitted/accepted/rejected/completed)';
COMMENT ON COLUMN ccd_documents.created_by_user_id IS 'Автор CCD (пользователь платформы)';
COMMENT ON COLUMN ccd_documents.organization_id IS 'Организация-владелец CCD';
COMMENT ON COLUMN ccd_documents.main_item_id IS 'Основная товарная позиция декларации (FK на ccd_items)';
COMMENT ON COLUMN ccd_documents.direction_code IS 'Графа 1: код направления (ИМ/ЭК/ТР)';
COMMENT ON COLUMN ccd_documents.third_subdivision IS 'Графа 1: третий подраздел (например, ПНД)';
COMMENT ON COLUMN ccd_documents.total_sheets IS 'Графа 3: всего листов (авто)';
COMMENT ON COLUMN ccd_documents.items_count IS 'Графа 5: всего позиций (авто)';
COMMENT ON COLUMN ccd_documents.trade_country_offshore IS 'Графа 11: признак офшорной страны';
COMMENT ON COLUMN ccd_documents.customs_value_total IS 'Графа 12: общая таможенная стоимость (сумма по позициям)';
COMMENT ON COLUMN ccd_documents.usd_uzs_rate IS 'Графа 13: курс USD/UZS на дату принятия';
COMMENT ON COLUMN ccd_documents.vehicle_vin IS 'Графа 18: VIN/идентификатор ТС';
COMMENT ON COLUMN ccd_documents.driver_name IS 'Графа 18: водитель/ответственное лицо';
COMMENT ON COLUMN ccd_documents.is_container IS 'Графа 19: признак использования контейнера';
COMMENT ON COLUMN ccd_documents.delivery_terms_place IS 'Графа 20: место по условиям поставки';
COMMENT ON COLUMN ccd_documents.invoice_total IS 'Графа 22: общая фактурная стоимость';
COMMENT ON COLUMN ccd_documents.contract_currency_rate IS 'Графа 23: курс валюты договора к UZS';
COMMENT ON COLUMN ccd_documents.payer_bank_account IS 'Графа 28: счет плательщика';
COMMENT ON COLUMN ccd_documents.payer_mfo IS 'Графа 28: МФО банка плательщика';
COMMENT ON COLUMN ccd_documents.location_license_number IS 'Графа 30: номер лицензии склада/СТЗ';
COMMENT ON COLUMN ccd_documents.location_license_date IS 'Графа 30: дата лицензии';
COMMENT ON COLUMN ccd_documents.location_address IS 'Графа 30: адрес местонахождения товаров';
COMMENT ON COLUMN ccd_documents.location_station_name IS 'Графа 30: наименование ЖД станции';
COMMENT ON COLUMN ccd_documents.procedure_code IS 'Графа 37: код процедуры (7 знаков)';
COMMENT ON COLUMN ccd_documents.previous_docs_summary IS 'Графа 40: краткое резюме предшествующих документов';
COMMENT ON COLUMN ccd_documents.warehouse_license_number IS 'Графа 49: номер лицензии склада';
COMMENT ON COLUMN ccd_documents.warehouse_license_date IS 'Графа 49: дата лицензии склада';
COMMENT ON COLUMN ccd_documents.responsible_full_name IS 'Графа 50: ответственное лицо — ФИО';
COMMENT ON COLUMN ccd_documents.responsible_pinfl IS 'Графа 50: ПИНФЛ ответственного лица';
COMMENT ON COLUMN ccd_documents.responsible_authority IS 'Графа 50: полномочия/основание';
COMMENT ON COLUMN ccd_documents.obligation_due_date IS 'Графа 50: срок обязательства';
COMMENT ON COLUMN ccd_documents.declaration_place IS 'Графа 54: место составления декларации';
COMMENT ON COLUMN ccd_documents.declaration_date IS 'Графа 54: дата составления декларации';
COMMENT ON COLUMN ccd_documents.contact_full_name IS 'Графа 54: ФИО контактного лица';
COMMENT ON COLUMN ccd_documents.contact_email IS 'Графа 54: email';
COMMENT ON COLUMN ccd_documents.contact_phone IS 'Графа 54: телефон';
COMMENT ON COLUMN ccd_documents.broker_contract_number IS 'Графа 54: номер договора с брокером';
COMMENT ON COLUMN ccd_documents.broker_contract_date IS 'Графа 54: дата договора с брокером';
COMMENT ON COLUMN ccd_documents.declarant_reference IS 'Графа 54: номер ГТД декларанта';
COMMENT ON COLUMN ccd_documents.external_contract_id IS '"C": внешний идентификатор контракта';
COMMENT ON COLUMN ccd_documents.regime_dates IS '"C": даты/сроки по режиму (JSON)';
COMMENT ON COLUMN ccd_documents.totals_b IS '"B": системные итоги по платежам/льготам';
COMMENT ON COLUMN ccd_documents.customs_decisions IS '"D": отметки/решения таможни';

-- ============================================================================

-- CCD Items (goods positions / добавочные листы)
CREATE TABLE IF NOT EXISTS ccd_items
(
    id                            INT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    created_at                    timestamptz    NOT NULL DEFAULT NOW(),
    updated_at                    timestamptz,
    deleted_at                    timestamptz,
    status                        item_status    NOT NULL DEFAULT 'draft',

    document_id                   INT            NOT NULL REFERENCES ccd_documents (id) ON DELETE CASCADE,

    -- Graph 32: Position number
    position_no                   INT            NOT NULL,

    -- Graph 31: Description and details
    trade_name                    TEXT           NOT NULL,  -- торговое/коммерческое наименование
    brand                         TEXT,                     -- бренд/марка
    model                         TEXT,                     -- модель
    article                       TEXT,                     -- артикул
    grade                         TEXT,                     -- сорт/вид
    specification                 TEXT,                     -- спецификация
    composition                   TEXT,                     -- состав/параметры
    energy_class                  TEXT,                     -- класс энергоэффективности
    manufacture_date              DATE,                     -- дата производства

    -- Graph 31: Extended detail fields (from graphs.md)
    manufacturer_name             TEXT,                     -- производитель
    trade_mark                    TEXT,                     -- торговая марка/название
    primary_package_qty           INT,                      -- кол-во первичной (розничной) упаковки в шт
    primary_package_type          TEXT,                     -- тип первичной упаковки
    packaging_volume              TEXT,                     -- фасовка
    item_qty_pieces               INT,                      -- кол-во товара в шт
    non_proprietary_name          TEXT,                     -- непатентованное название
    scientific_name               TEXT,                     -- научное наименование вида
    volume_cc                     INT,                      -- объем (см3)
    power                         TEXT,                     -- мощность
    dimensions                    TEXT,                     -- размерность
    diagonal                      NUMERIC(10, 2),           -- диагональ
    volume_capacity               NUMERIC(10, 2),           -- объем/ёмкость
    thickness_mm                  NUMERIC(10, 2),           -- толщина в мм
    fat_content_percent           NUMERIC(5, 2),            -- массовая доля жира (%)
    dosage_form                   TEXT,                     -- лекарственная форма
    dosage                        TEXT,                     -- дозировка
    concentration                 TEXT,                     -- концентрация
    technical_characteristics     TEXT,                     -- технические характеристики
    octane_number                 INT,                      -- октановое число

    -- Packaging/places
    is_packed                     BOOLEAN,
    packages_total                INT,
    package_type                  TEXT,
    package_count                 INT,
    bulk_code                     VARCHAR(2),    -- '01','02','03' for bulk/loose/liquid

    -- Containers (JSON for flexibility)
    containers                    jsonb          NOT NULL DEFAULT '[]',

    -- Excise marks
    excise_marks                  jsonb          NOT NULL DEFAULT '[]',

    -- Pipeline/LEP period
    supply_period_from            DATE,
    supply_period_to              DATE,

    -- Import-specific attributes
    aggregated_import_code        TEXT,
    expiry_date                   DATE,
    investment_project_code       VARCHAR(3),
    tech_equipment_area_code      TEXT,
    tech_equipment_year           INT,
    tech_equipment_params         TEXT,
    gov_procurement_code          VARCHAR(2),

    -- Producer/consumer (lower-left block)
    producer_id_code              TEXT,
    consumer_id_code              TEXT,

    -- Lower-right block: additional unit
    additional_unit_qty           NUMERIC(18, 6),

    -- Graph 34: Origin alpha2 (display only, e.g., 'EU')
    origin_alpha2                 VARCHAR(2),

    -- Graph 35/38: Weights
    gross_weight_kg               NUMERIC(18, 6),
    net_weight_kg                 NUMERIC(18, 6),

    -- Graph 37: Procedure at item level (may mirror header)
    procedure_code                VARCHAR(7),

    -- Graph 39: Quota
    quota_amount                  NUMERIC(18, 6),

    -- Graph 40: Previous documents for this item (JSON until detailed table)
    previous_docs                 jsonb          NOT NULL DEFAULT '[]',

    -- Graph 42: Invoiced value
    invoiced_value                NUMERIC(18, 2),

    -- Graph 43: Own production/needs indicator
    own_needs_flag                BOOLEAN,

    -- Graph 44: Documents list for the item (JSON)
    documents                     jsonb          NOT NULL DEFAULT '[]',

    -- Graph 45/46: Customs and statistical values (auto-calculated)
    customs_value                 NUMERIC(18, 2),
    statistical_value_thousand_usd NUMERIC(18, 3),

    -- Graph 47: Payments per item (JSON until normalized)
    payments                      jsonb          NOT NULL DEFAULT '[]',

    -- Source traceability
    source_invoice_file_id        INT REFERENCES files (id),
    source_invoice_row_ref        TEXT,

    -- Constraints
    CONSTRAINT ccd_items_pos_ck CHECK (position_no >= 1),
    CONSTRAINT ccd_items_bulk_ck CHECK (bulk_code IS NULL OR bulk_code IN ('01', '02', '03')),
    CONSTRAINT ccd_items_govproc_ck CHECK (gov_procurement_code IS NULL OR gov_procurement_code IN ('01', '02')),
    CONSTRAINT ccd_items_proc_len_ck CHECK (procedure_code IS NULL OR length(procedure_code) = 7),
    CONSTRAINT ccd_items_invest_ck CHECK (investment_project_code IS NULL OR investment_project_code IN ('101', '102', '000'))
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_ccd_items_doc_pos ON ccd_items (document_id, position_no);
CREATE INDEX IF NOT EXISTS idx_ccd_items_document_id ON ccd_items (document_id);
CREATE INDEX IF NOT EXISTS idx_ccd_items_status ON ccd_items (status);
CREATE INDEX IF NOT EXISTS idx_ccd_items_source_file ON ccd_items (source_invoice_file_id);

COMMENT ON TABLE ccd_items IS 'Позиции CCD (добавочные листы): одна строка на товарную позицию декларации. Содержит данные графы 31-47';
COMMENT ON COLUMN ccd_items.id IS 'Первичный ключ';
COMMENT ON COLUMN ccd_items.document_id IS 'FK на ccd_documents (CASCADE DELETE)';
COMMENT ON COLUMN ccd_items.position_no IS 'Графа 32: порядковый номер позиции';
COMMENT ON COLUMN ccd_items.trade_name IS 'Графа 31: торговое/коммерческое наименование';
COMMENT ON COLUMN ccd_items.brand IS 'Графа 31: бренд/марка';
COMMENT ON COLUMN ccd_items.model IS 'Графа 31: модель';
COMMENT ON COLUMN ccd_items.article IS 'Графа 31: артикул';
COMMENT ON COLUMN ccd_items.grade IS 'Графа 31: сорт';
COMMENT ON COLUMN ccd_items.specification IS 'Графа 31: спецификация';
COMMENT ON COLUMN ccd_items.composition IS 'Графа 31: состав/параметры';
COMMENT ON COLUMN ccd_items.energy_class IS 'Графа 31: класс энергоэффективности';
COMMENT ON COLUMN ccd_items.manufacture_date IS 'Графа 31: дата производства';
COMMENT ON COLUMN ccd_items.is_packed IS 'Наличие упаковки';
COMMENT ON COLUMN ccd_items.packages_total IS 'Всего мест';
COMMENT ON COLUMN ccd_items.package_type IS 'Тип упаковки';
COMMENT ON COLUMN ccd_items.package_count IS 'Число упаковок';
COMMENT ON COLUMN ccd_items.bulk_code IS 'Код навал/насыпь/налив (01/02/03)';
COMMENT ON COLUMN ccd_items.containers IS 'Контейнеры ISO 6346 (JSON)';
COMMENT ON COLUMN ccd_items.excise_marks IS 'Акцизные марки (JSON)';
COMMENT ON COLUMN ccd_items.supply_period_from IS 'Период поставки: с';
COMMENT ON COLUMN ccd_items.supply_period_to IS 'Период поставки: по';
COMMENT ON COLUMN ccd_items.aggregated_import_code IS 'Код агрегированного импорта';
COMMENT ON COLUMN ccd_items.expiry_date IS 'Срок годности';
COMMENT ON COLUMN ccd_items.investment_project_code IS 'Код инвестиционного проекта (101/102/000)';
COMMENT ON COLUMN ccd_items.tech_equipment_area_code IS 'Код зоны техоснащения (Приложение 16)';
COMMENT ON COLUMN ccd_items.tech_equipment_year IS 'Год техоснащения';
COMMENT ON COLUMN ccd_items.tech_equipment_params IS 'Параметры техоснащения';
COMMENT ON COLUMN ccd_items.gov_procurement_code IS 'Код госзакупки (01/02)';
COMMENT ON COLUMN ccd_items.producer_id_code IS 'ИНН/ПИНФЛ производителя';
COMMENT ON COLUMN ccd_items.consumer_id_code IS 'ИНН/ПИНФЛ потребителя';
COMMENT ON COLUMN ccd_items.additional_unit_qty IS 'Количество в доп. единице';
COMMENT ON COLUMN ccd_items.origin_alpha2 IS 'Графа 34: буквенный код происхождения (например, EU)';
COMMENT ON COLUMN ccd_items.gross_weight_kg IS 'Графа 35: вес брутто (кг)';
COMMENT ON COLUMN ccd_items.net_weight_kg IS 'Графа 38: вес нетто (кг)';
COMMENT ON COLUMN ccd_items.procedure_code IS 'Графа 37: код процедуры на уровне позиции';
COMMENT ON COLUMN ccd_items.quota_amount IS 'Графа 39: квота';
COMMENT ON COLUMN ccd_items.previous_docs IS 'Графа 40: предшествующие документы (JSON)';
COMMENT ON COLUMN ccd_items.invoiced_value IS 'Графа 42: фактурная стоимость позиции';
COMMENT ON COLUMN ccd_items.own_needs_flag IS 'Графа 43: признак собственных нужд/собственного производства';
COMMENT ON COLUMN ccd_items.documents IS 'Графа 44: список документов (JSON)';
COMMENT ON COLUMN ccd_items.customs_value IS 'Графа 45: таможенная стоимость';
COMMENT ON COLUMN ccd_items.statistical_value_thousand_usd IS 'Графа 46: стат. стоимость (тыс. USD)';
COMMENT ON COLUMN ccd_items.payments IS 'Графа 47: платежи по позиции (JSON)';
COMMENT ON COLUMN ccd_items.source_invoice_file_id IS 'FK на files (исходный счет-фактура)';
COMMENT ON COLUMN ccd_items.source_invoice_row_ref IS 'Ссылка на строку в исходном счете';

-- ============================================================================
-- EXTENDED DOCUMENT TABLES (from graphs.md)
-- ============================================================================

-- Graph 40: Previous documents per item
CREATE TABLE IF NOT EXISTS ccd_item_previous_documents
(
    id                       INT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    created_at               timestamptz NOT NULL DEFAULT NOW(),
    updated_at               timestamptz,
    deleted_at               timestamptz,
    status                   entity_status NOT NULL DEFAULT 'active',

    item_id                  INT NOT NULL REFERENCES ccd_items (id) ON DELETE CASCADE,

    -- Previous document details
    post_code                VARCHAR,                              -- код таможенного поста
    gtd_number               VARCHAR,                              -- номер ГТД
    gtd_date                 DATE,                                 -- дата ГТД
    item_number              INT,                                  -- номер товара в предыдущей ГТД
    gross_weight_kg          NUMERIC(18, 6),                       -- вес брутто
    net_weight_kg            NUMERIC(18, 6),                       -- вес нетто
    additional_unit_qty      NUMERIC(18, 6),                       -- количество в доп. единице
    additional_unit_code     VARCHAR                               -- код доп. единицы измерения
);

CREATE INDEX IF NOT EXISTS idx_ccd_item_previous_docs_item ON ccd_item_previous_documents (item_id);
CREATE INDEX IF NOT EXISTS idx_ccd_item_previous_docs_gtd ON ccd_item_previous_documents (gtd_number);

COMMENT ON TABLE ccd_item_previous_documents IS 'Предшествующие документы по товару (Графа 40): индивидуальный справочник для декларанта';
COMMENT ON COLUMN ccd_item_previous_documents.item_id IS 'FK на ccd_items (CASCADE DELETE)';
COMMENT ON COLUMN ccd_item_previous_documents.post_code IS 'Код таможенного поста (из справочника кодов постов)';
COMMENT ON COLUMN ccd_item_previous_documents.gtd_number IS 'Номер ГТД';
COMMENT ON COLUMN ccd_item_previous_documents.gtd_date IS 'Дата ГТД';
COMMENT ON COLUMN ccd_item_previous_documents.item_number IS 'Номер товара в предыдущей ГТД';
COMMENT ON COLUMN ccd_item_previous_documents.gross_weight_kg IS 'Вес брутто (кг)';
COMMENT ON COLUMN ccd_item_previous_documents.net_weight_kg IS 'Вес нетто (кг)';
COMMENT ON COLUMN ccd_item_previous_documents.additional_unit_qty IS 'Количество в доп. единице измерения';
COMMENT ON COLUMN ccd_item_previous_documents.additional_unit_code IS 'Код доп. единицы измерения';

-- ============================================================================

-- Graph 44: Accompanying documents per item
CREATE TABLE IF NOT EXISTS ccd_item_accompanying_documents
(
    id                       INT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    created_at               timestamptz NOT NULL DEFAULT NOW(),
    updated_at               timestamptz,
    deleted_at               timestamptz,
    status                   entity_status NOT NULL DEFAULT 'active',

    item_id                  INT NOT NULL REFERENCES ccd_items (id) ON DELETE CASCADE,

    -- Document details
    item_number              NUMERIC(10, 2),                       -- № пункта
    document_type            TEXT,                                 -- тип документа
    document_number          TEXT,                                 -- номер документа
    document_date            DATE,                                 -- дата документа
    amount                   NUMERIC(18, 2),                       -- сумма по документам
    currency_id              INT REFERENCES codes_currencies (id), -- валюта
    deadline_date            DATE,                                 -- оформить срок до
    note                     TEXT                                  -- примечание
);

CREATE INDEX IF NOT EXISTS idx_ccd_item_accompanying_docs_item ON ccd_item_accompanying_documents (item_id);
CREATE INDEX IF NOT EXISTS idx_ccd_item_accompanying_docs_currency ON ccd_item_accompanying_documents (currency_id);

COMMENT ON TABLE ccd_item_accompanying_documents IS 'Товаро-сопроводительные документы (Графа 44): список документов по каждой товарной позиции';
COMMENT ON COLUMN ccd_item_accompanying_documents.item_id IS 'FK на ccd_items (CASCADE DELETE)';
COMMENT ON COLUMN ccd_item_accompanying_documents.item_number IS '№ пункта (ручное или автозаполнение из справочника)';
COMMENT ON COLUMN ccd_item_accompanying_documents.document_type IS 'Тип документа (ручное или автозаполнение из справочника)';
COMMENT ON COLUMN ccd_item_accompanying_documents.document_number IS '№ документа';
COMMENT ON COLUMN ccd_item_accompanying_documents.document_date IS 'Дата документа';
COMMENT ON COLUMN ccd_item_accompanying_documents.amount IS 'Сумма по документам';
COMMENT ON COLUMN ccd_item_accompanying_documents.currency_id IS 'FK на codes_currencies (валюта)';
COMMENT ON COLUMN ccd_item_accompanying_documents.deadline_date IS 'Оформить срок до';
COMMENT ON COLUMN ccd_item_accompanying_documents.note IS 'Примечание';

-- ============================================================================

-- Graph 31: IMEI codes for devices
CREATE TABLE IF NOT EXISTS ccd_item_imei_codes
(
    id         INT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    created_at timestamptz NOT NULL DEFAULT NOW(),
    updated_at timestamptz,
    deleted_at timestamptz,
    status     entity_status NOT NULL DEFAULT 'active',

    item_id    INT NOT NULL REFERENCES ccd_items (id) ON DELETE CASCADE,
    imei_code  VARCHAR NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_ccd_item_imei_item ON ccd_item_imei_codes (item_id);
CREATE INDEX IF NOT EXISTS idx_ccd_item_imei_code ON ccd_item_imei_codes (imei_code);

COMMENT ON TABLE ccd_item_imei_codes IS 'IMEI коды устройств (Графа 31): агрегированные номера для товаров';
COMMENT ON COLUMN ccd_item_imei_codes.item_id IS 'FK на ccd_items (CASCADE DELETE)';
COMMENT ON COLUMN ccd_item_imei_codes.imei_code IS 'IMEI код устройства';

-- ============================================================================

-- ENUMS for vehicle details
CREATE TYPE eco_standard AS ENUM ('EURO1', 'EURO2', 'EURO3', 'EURO4', 'EURO5', 'EURO6');
CREATE TYPE engine_type AS ENUM ('petrol', 'diesel', 'electric', 'gas', 'hybrid');

COMMENT ON TYPE eco_standard IS 'Экологический стандарт: EURO1-EURO6';
COMMENT ON TYPE engine_type IS 'Тип двигателя: petrol (бензин) | diesel (дизель) | electric (электро) | gas (газ) | hybrid (гибрид)';

-- ============================================================================

-- Graph 31: Vehicle-specific details for automobiles
CREATE TABLE IF NOT EXISTS ccd_item_vehicle_details
(
    id                 INT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    created_at         timestamptz NOT NULL DEFAULT NOW(),
    updated_at         timestamptz,
    deleted_at         timestamptz,
    status             entity_status NOT NULL DEFAULT 'active',

    item_id            INT NOT NULL UNIQUE REFERENCES ccd_items (id) ON DELETE CASCADE,

    -- Vehicle identification
    engine_number      VARCHAR,
    body_number        VARCHAR,
    manufacture_year   INT,
    engine_volume_cc   NUMERIC(10, 2),                           -- объем двигателя в см3
    vin_code           VARCHAR,
    chassis_number     VARCHAR,

    -- Vehicle characteristics
    eco_standard       eco_standard,                             -- экологический стандарт
    engine_type        engine_type,                              -- тип двигателя
    color              VARCHAR                                   -- цвет (ручное или из справочника)
);

CREATE INDEX IF NOT EXISTS idx_ccd_item_vehicle_item ON ccd_item_vehicle_details (item_id);
CREATE INDEX IF NOT EXISTS idx_ccd_item_vehicle_vin ON ccd_item_vehicle_details (vin_code);

COMMENT ON TABLE ccd_item_vehicle_details IS 'Детали автомобиля (Графа 31): специфические поля для товаров категории "автомобили"';
COMMENT ON COLUMN ccd_item_vehicle_details.item_id IS 'FK на ccd_items (CASCADE DELETE, UNIQUE - one vehicle per item)';
COMMENT ON COLUMN ccd_item_vehicle_details.engine_number IS 'Номер двигателя';
COMMENT ON COLUMN ccd_item_vehicle_details.body_number IS 'Номер кузова';
COMMENT ON COLUMN ccd_item_vehicle_details.manufacture_year IS 'Год выпуска';
COMMENT ON COLUMN ccd_item_vehicle_details.engine_volume_cc IS 'Объем двигателя в см3';
COMMENT ON COLUMN ccd_item_vehicle_details.vin_code IS 'VIN код';
COMMENT ON COLUMN ccd_item_vehicle_details.chassis_number IS 'Номер шасси';
COMMENT ON COLUMN ccd_item_vehicle_details.eco_standard IS 'Экологический стандарт (EURO1-EURO6)';
COMMENT ON COLUMN ccd_item_vehicle_details.engine_type IS 'Тип двигателя (бензин/дизель/электро/газ/гибрид)';
COMMENT ON COLUMN ccd_item_vehicle_details.color IS 'Цвет (ручное или автозаполнение из справочника цветов)';

-- ============================================================================

-- Graph 48: Deferments and installments
CREATE TABLE IF NOT EXISTS ccd_document_deferments
(
    id                   INT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    created_at           TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at           TIMESTAMP WITH TIME ZONE,
    deleted_at           TIMESTAMP WITH TIME ZONE,
    status               entity_status NOT NULL DEFAULT 'active',

    document_id          INT NOT NULL REFERENCES ccd_documents (id) ON DELETE CASCADE,

    -- Deferment details
    payment_type         VARCHAR(10) NOT NULL,           -- 'duty' | 'vat' | 'excise' | 'fee' | 'other'
    deferment_type       VARCHAR(20) NOT NULL,           -- 'deferment' (отсрочка) | 'installment' (рассрочка)
    amount               NUMERIC(18, 2) NOT NULL,
    currency_code        VARCHAR(3),
    due_date             DATE,
    installment_plan     jsonb,                          -- для рассрочки: [{date, amount}, ...]
    notes                TEXT,

    CONSTRAINT ccd_deferments_payment_type_ck CHECK (payment_type IN ('duty', 'vat', 'excise', 'fee', 'other')),
    CONSTRAINT ccd_deferments_type_ck CHECK (deferment_type IN ('deferment', 'installment'))
);

CREATE INDEX IF NOT EXISTS idx_ccd_deferments_document ON ccd_document_deferments (document_id);
CREATE INDEX IF NOT EXISTS idx_ccd_deferments_type ON ccd_document_deferments (deferment_type);
CREATE INDEX IF NOT EXISTS idx_ccd_deferments_due_date ON ccd_document_deferments (due_date);

COMMENT ON TABLE ccd_document_deferments IS 'Графа 48: отсрочки/рассрочки уплаты таможенных платежей';
COMMENT ON COLUMN ccd_document_deferments.document_id IS 'FK на ccd_documents (CASCADE DELETE)';
COMMENT ON COLUMN ccd_document_deferments.payment_type IS 'Тип платежа: duty (пошлина) | vat (НДС) | excise (акциз) | fee (сбор) | other';
COMMENT ON COLUMN ccd_document_deferments.deferment_type IS 'Тип: deferment (отсрочка - один срок) | installment (рассрочка - график)';
COMMENT ON COLUMN ccd_document_deferments.amount IS 'Сумма отсрочки/рассрочки';
COMMENT ON COLUMN ccd_document_deferments.currency_code IS 'Код валюты';
COMMENT ON COLUMN ccd_document_deferments.due_date IS 'Срок уплаты (для отсрочки)';
COMMENT ON COLUMN ccd_document_deferments.installment_plan IS 'График рассрочки (JSON): [{date, amount}, ...]';
COMMENT ON COLUMN ccd_document_deferments.notes IS 'Примечания';
