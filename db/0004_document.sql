-- CCD Document header table derived from document_gtd.md
-- Each row represents one CCD (declaration). Item-level fields (31..35,37..47, per-item 44)
-- will live in a separate items table.

CREATE TABLE IF NOT EXISTS ccd_documents
(
    id                                 INT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    created_at                         timestamptz NOT NULL DEFAULT NOW(),
    updated_at                         timestamptz,
    deleted_at                         timestamptz,
    status                             TEXT,
    created_by_user_id                 INT REFERENCES users (id),
    organization_id                    INT REFERENCES organizations (id),

    -- Graph 1: Тип декларации
    form_id                            INT REFERENCES codes_forms (id),
    direction_code                     VARCHAR(3)   NOT NULL, -- 'ИМ','ЭК','ТР','НД'
    regime_code                        VARCHAR(8)   NOT NULL, -- режим (справочник режимов; пока строкой)
    third_subdivision                  VARCHAR(3),            -- напр. 'ПНД'

    -- Graph 3 / 5
    total_sheets                       INT,                  -- всего листов (авто)
    items_count                        INT        NOT NULL DEFAULT 0, -- всего позиций (авто)

    -- Graph 7: Таможенный пост оформления
    post_id                            INT REFERENCES codes_posts (id),

    -- Parties (Graphs 2, 8, 9, 14)
    exporter_legal_id                  INT REFERENCES fea_legal_entities (id),
    exporter_individual_id             INT REFERENCES fea_individual_entities (id),
    consignee_legal_id                 INT REFERENCES fea_legal_entities (id),
    consignee_individual_id            INT REFERENCES fea_individual_entities (id),
    declarant_legal_id                 INT REFERENCES fea_legal_entities (id),
    declarant_individual_id            INT REFERENCES fea_individual_entities (id),
    financial_legal_id                 INT REFERENCES fea_legal_entities (id),
    financial_individual_id            INT REFERENCES fea_individual_entities (id),

    -- Optional links to short/legal info sources for quick selection and provenance
    exporter_legal_short_id            INT REFERENCES fea_legal_entities_short (id),
    consignee_legal_short_id           INT REFERENCES fea_legal_entities_short (id),
    declarant_legal_short_id           INT REFERENCES fea_legal_entities_short (id),
    financial_legal_short_id           INT REFERENCES fea_legal_entities_short (id),

    exporter_partner_info_id           INT REFERENCES fea_partners_additional (id),
    consignee_partner_info_id          INT REFERENCES fea_partners_additional (id),
    declarant_partner_info_id          INT REFERENCES fea_partners_additional (id),
    financial_partner_info_id          INT REFERENCES fea_partners_additional (id),

    -- Graph 11: Страна торговли (с офшорным признаком при наличии)
    trade_country_id                   INT REFERENCES codes_countries (id),
    trade_country_offshore             BOOLEAN,

    -- Graph 12: Общая таможенная стоимость (авто)
    customs_value_total                NUMERIC(18, 2),

    -- Graph 13: Курс USD/UZS на дату принятия
    usd_uzs_rate                       NUMERIC(18, 6),

    -- Graph 15/15a: Страна отправления
    dispatch_country_id                INT REFERENCES codes_countries (id),

    -- Graph 17/17a: Страна назначения
    destination_country_id             INT REFERENCES codes_countries (id),

    -- Graph 18: Транспорт (основной)
    transport_main_type_id             INT REFERENCES codes_transport_types (id),
    vehicle_type_code                  VARCHAR(2),          -- спец. 2-значный код типа ТС
    vehicle_vin                        VARCHAR(32),
    vehicle_reg_country_id             INT REFERENCES codes_countries (id),
    carrier_legal_id                   INT REFERENCES fea_legal_entities (id),
    carrier_individual_id              INT REFERENCES fea_individual_entities (id),
    driver_name                        TEXT,

    -- Graph 19: Признак контейнера
    is_container                       BOOLEAN,

    -- Graph 20: Условия поставки / форма оплаты / форма отгрузки
    delivery_terms_id                  INT REFERENCES codes_delivery_terms (id),
    delivery_terms_place               TEXT,
    payment_form_id                    INT REFERENCES codes_payment_forms (id),
    shipment_form_code                 VARCHAR(10),

    -- Graph 21: Транспорт на границе (идентификация)
    border_transport_type_id           INT REFERENCES codes_transport_types (id),
    border_vehicle_reg_country_id      INT REFERENCES codes_countries (id),

    -- Graph 22: Валюта договора и общая фактура
    contract_currency_id               INT REFERENCES codes_currencies (id),
    invoice_total                      NUMERIC(18, 2),

    -- Graph 23: Курс валюты договора к UZS
    contract_currency_rate             NUMERIC(18, 6),

    -- Graph 24: Характер сделки и валюта расчетов
    deal_type_id                       INT REFERENCES codes_deal_types (id),
    settlement_currency_id             INT REFERENCES codes_currencies (id),

    -- Graph 25/26: Виды транспорта
    transport_at_border_id             INT REFERENCES codes_transport_types (id),
    transport_inside_country_id        INT REFERENCES codes_transport_types (id),

    -- Graph 28: Плательщик + банковские реквизиты (для транзита/при необходимости)
    payer_legal_id                     INT REFERENCES fea_legal_entities (id),
    payer_individual_id                INT REFERENCES fea_individual_entities (id),
    payer_bank_id                      INT REFERENCES banks (id),
    payer_bank_account                 TEXT,
    payer_mfo                          VARCHAR(20),

    -- Graph 29: Таможня на границе
    border_post_id                     INT REFERENCES codes_posts (id),

    -- Graph 30: Местонахождение товаров
    location_license_number            TEXT,
    location_license_date              DATE,
    location_address                   TEXT,
    location_station_name              TEXT,
    location_district_id               INT REFERENCES codes_districts (id),

    -- Graph 37: Сводный код процедуры (7 знаков)
    procedure_code                     VARCHAR(7),
    movement_type_id                   INT REFERENCES codes_movement_types (id), -- особенность перемещения (3 знака)

    -- Graph 40: Краткое резюме до создания отдельных таблиц (не обязательно)
    previous_docs_summary              TEXT,

    -- Graph 48/49: Отсрочки/склады
    deferments                         jsonb       NOT NULL DEFAULT '{}',
    warehouse_license_number           TEXT,
    warehouse_license_date             DATE,

    -- Graph 50: Ответственное лицо и обязательства
    responsible_full_name              TEXT,
    responsible_pinfl                  VARCHAR(14),
    responsible_authority              TEXT,
    obligation_due_date                DATE,

    -- Graph 53: Таможня и страна назначения (транзит)
    transit_customs_post_id            INT REFERENCES codes_posts (id),
    transit_destination_country_id     INT REFERENCES codes_countries (id),

    -- Graph 54: Место/дата, контакты, договор с брокером, номер ГТД декларанта
    declaration_place                  TEXT,
    declaration_date                   DATE,
    contact_full_name                  TEXT,
    contact_email                      TEXT,
    contact_phone                      TEXT,
    broker_contract_number             TEXT,
    broker_contract_date               DATE,
    declarant_reference                TEXT,

    -- “C”: специальные поля по режиму
    external_contract_id               TEXT,
    regime_dates                       jsonb       NOT NULL DEFAULT '{}',

    -- “B”/“D”: системные итоги и решения таможни
    totals_b                           jsonb       NOT NULL DEFAULT '{}',
    customs_decisions                  jsonb       NOT NULL DEFAULT '{}',

    -- Basic checks
    CONSTRAINT ccd_direction_ck CHECK (direction_code IN ('ИМ', 'ЭК', 'ТР', 'НД')),
    CONSTRAINT ccd_items_count_ck CHECK (items_count >= 0),
    CONSTRAINT ccd_procedure_len_ck CHECK (procedure_code IS NULL OR length(procedure_code) = 7)
);

-- Helpful indexes
CREATE INDEX IF NOT EXISTS idx_ccd_documents_created_at ON ccd_documents (created_at);
CREATE INDEX IF NOT EXISTS idx_ccd_documents_post_id ON ccd_documents (post_id);
CREATE INDEX IF NOT EXISTS idx_ccd_documents_declarant_legal ON ccd_documents (declarant_legal_id);
CREATE INDEX IF NOT EXISTS idx_ccd_documents_contract_currency ON ccd_documents (contract_currency_id);
CREATE INDEX IF NOT EXISTS idx_ccd_documents_direction ON ccd_documents (direction_code);
CREATE INDEX IF NOT EXISTS idx_ccd_documents_form_id ON ccd_documents (form_id);
CREATE INDEX IF NOT EXISTS idx_ccd_documents_created_by ON ccd_documents (created_by_user_id);
CREATE INDEX IF NOT EXISTS idx_ccd_documents_organization ON ccd_documents (organization_id);
CREATE INDEX IF NOT EXISTS idx_ccd_documents_movement_type ON ccd_documents (movement_type_id);
CREATE INDEX IF NOT EXISTS idx_ccd_documents_short_exporter ON ccd_documents (exporter_legal_short_id);
CREATE INDEX IF NOT EXISTS idx_ccd_documents_short_consignee ON ccd_documents (consignee_legal_short_id);
CREATE INDEX IF NOT EXISTS idx_ccd_documents_short_declarant ON ccd_documents (declarant_legal_short_id);
CREATE INDEX IF NOT EXISTS idx_ccd_documents_short_financial ON ccd_documents (financial_legal_short_id);
CREATE INDEX IF NOT EXISTS idx_ccd_documents_info_exporter ON ccd_documents (exporter_partner_info_id);
CREATE INDEX IF NOT EXISTS idx_ccd_documents_info_consignee ON ccd_documents (consignee_partner_info_id);
CREATE INDEX IF NOT EXISTS idx_ccd_documents_info_declarant ON ccd_documents (declarant_partner_info_id);
CREATE INDEX IF NOT EXISTS idx_ccd_documents_info_financial ON ccd_documents (financial_partner_info_id);

-- Comments: ccd_documents
COMMENT ON TABLE ccd_documents IS 'CCD (декларация) — заголовок. Содержит поля по графам: 1,3,5,7,11–13,15,17,18–26,28–30,37,48–50,53–54, а также спецполя “C”, итоги “B” и решения “D”. Содержит ссылки на стороны и справочники';
COMMENT ON COLUMN ccd_documents.form_id IS 'FK на codes_forms (Графа 1: форма/тип декларации)';
COMMENT ON COLUMN ccd_documents.direction_code IS 'Графа 1: код направления (ИМ/ЭК/ТР/НД)';
COMMENT ON COLUMN ccd_documents.regime_code IS 'Графа 1: код режима (двухзначный), хранится строкой до ввода справочника режимов';
COMMENT ON COLUMN ccd_documents.created_by_user_id IS 'Автор CCD (пользователь платформы) для аналитики и аудита';
COMMENT ON COLUMN ccd_documents.organization_id IS 'Организация-владелец CCD (для аналитики по организациям)';
COMMENT ON COLUMN ccd_documents.post_id IS 'FK на codes_posts (Графа 7: таможенный пост оформления)';
COMMENT ON COLUMN ccd_documents.exporter_legal_id IS 'FK на fea_legal_entities (Графа 2: экспортер/отправитель юр.лицо); может автозаполняться из fea_legal_entities_short/fea_partners_additional';
COMMENT ON COLUMN ccd_documents.exporter_individual_id IS 'FK на fea_individual_entities (Графа 2: экспортер/отправитель физ.лицо)';
COMMENT ON COLUMN ccd_documents.consignee_legal_id IS 'FK на fea_legal_entities (Графа 8: получатель юр.лицо); может автозаполняться из fea_legal_entities_short/fea_partners_additional';
COMMENT ON COLUMN ccd_documents.consignee_individual_id IS 'FK на fea_individual_entities (Графа 8: получатель физ.лицо)';
COMMENT ON COLUMN ccd_documents.declarant_legal_id IS 'FK на fea_legal_entities (Графа 14: декларант/брокер юр.лицо); автозаполнение возможно из fea_legal_entities_short';
COMMENT ON COLUMN ccd_documents.declarant_individual_id IS 'FK на fea_individual_entities (Графа 14: декларант/брокер физ.лицо)';
COMMENT ON COLUMN ccd_documents.financial_legal_id IS 'FK на fea_legal_entities (Графа 9: лицо, ответственное за фин.урегулирование юр.лицо); источники: fea_legal_entities_short/fea_partners_additional';
COMMENT ON COLUMN ccd_documents.financial_individual_id IS 'FK на fea_individual_entities (Графа 9: лицо, ответственное за фин.урегулирование физ.лицо)';
COMMENT ON COLUMN ccd_documents.exporter_legal_short_id IS 'FK на fea_legal_entities_short: быстрый выбор экспортера/отправителя (графа 2)';
COMMENT ON COLUMN ccd_documents.consignee_legal_short_id IS 'FK на fea_legal_entities_short: быстрый выбор получателя (графа 8)';
COMMENT ON COLUMN ccd_documents.declarant_legal_short_id IS 'FK на fea_legal_entities_short: быстрый выбор декларанта/брокера (графа 14)';
COMMENT ON COLUMN ccd_documents.financial_legal_short_id IS 'FK на fea_legal_entities_short: быстрый выбор фин.ответственного (графа 9)';
COMMENT ON COLUMN ccd_documents.exporter_partner_info_id IS 'FK на fea_partners_additional: доп.сведения по экспортеру (графа 2)';
COMMENT ON COLUMN ccd_documents.consignee_partner_info_id IS 'FK на fea_partners_additional: доп.сведения по получателю (графа 8)';
COMMENT ON COLUMN ccd_documents.declarant_partner_info_id IS 'FK на fea_partners_additional: доп.сведения по декларанту/брокеру (графа 14)';
COMMENT ON COLUMN ccd_documents.financial_partner_info_id IS 'FK на fea_partners_additional: доп.сведения по фин.ответственному (графа 9)';
COMMENT ON COLUMN ccd_documents.trade_country_id IS 'FK на codes_countries (Графа 11: страна торговли)';
COMMENT ON COLUMN ccd_documents.customs_value_total IS 'Графа 12: общая таможенная стоимость (сумма по графе 45 позиций)';
COMMENT ON COLUMN ccd_documents.usd_uzs_rate IS 'Графа 13: курс USD/UZS на дату принятия к оформлению';
COMMENT ON COLUMN ccd_documents.dispatch_country_id IS 'FK на codes_countries (Графа 15/15a: страна отправления)';
COMMENT ON COLUMN ccd_documents.destination_country_id IS 'FK на codes_countries (Графа 17/17a: страна назначения)';
COMMENT ON COLUMN ccd_documents.transport_main_type_id IS 'FK на codes_transport_types (Графа 18: вид транспорта)';
COMMENT ON COLUMN ccd_documents.is_container IS 'Графа 19: признак использования контейнера';
COMMENT ON COLUMN ccd_documents.delivery_terms_id IS 'FK на codes_delivery_terms (Графа 20: условия поставки)';
COMMENT ON COLUMN ccd_documents.payment_form_id IS 'FK на codes_payment_forms (Графа 20: код формы оплаты)';
COMMENT ON COLUMN ccd_documents.border_transport_type_id IS 'FK на codes_transport_types (Графа 21: транспорт на границе)';
COMMENT ON COLUMN ccd_documents.contract_currency_id IS 'FK на codes_currencies (Графа 22: валюта договора)';
COMMENT ON COLUMN ccd_documents.invoice_total IS 'Графа 22: общая фактурная стоимость';
COMMENT ON COLUMN ccd_documents.contract_currency_rate IS 'Графа 23: курс валюты договора к UZS';
COMMENT ON COLUMN ccd_documents.deal_type_id IS 'FK на codes_deal_types (Графа 24: характер сделки)';
COMMENT ON COLUMN ccd_documents.transport_at_border_id IS 'FK на codes_transport_types (Графа 25: вид транспорта на границе)';
COMMENT ON COLUMN ccd_documents.transport_inside_country_id IS 'FK на codes_transport_types (Графа 26: вид транспорта внутри страны)';
COMMENT ON COLUMN ccd_documents.payer_legal_id IS 'FK на fea_legal_entities (Графа 28: плательщик — юр.лицо); автозаполнение возможно из fea_legal_entities_short';
COMMENT ON COLUMN ccd_documents.payer_individual_id IS 'FK на fea_individual_entities (Графа 28: плательщик — физ.лицо)';
COMMENT ON COLUMN ccd_documents.border_post_id IS 'FK на codes_posts (Графа 29: пост на границе)';
COMMENT ON COLUMN ccd_documents.location_district_id IS 'FK на codes_districts (Графа 30: район/город местонахождения)';
COMMENT ON COLUMN ccd_documents.procedure_code IS 'Графа 37: код процедуры (режим/предыдущий/особенность)';
COMMENT ON COLUMN ccd_documents.movement_type_id IS 'FK на codes_movement_types: особенность перемещения (3-значный код для графы 37)';
COMMENT ON COLUMN ccd_documents.totals_b IS '“B”: системные итоги по платежам/льготам (только чтение)';
COMMENT ON COLUMN ccd_documents.customs_decisions IS '“D”: отметки/решения таможни (только чтение)';

-- System/service columns
COMMENT ON COLUMN ccd_documents.id IS 'Служебное поле: первичный ключ (не графа)';
COMMENT ON COLUMN ccd_documents.created_at IS 'Служебное поле: дата/время создания записи (не графа)';
COMMENT ON COLUMN ccd_documents.updated_at IS 'Служебное поле: дата/время изменения (не графа)';
COMMENT ON COLUMN ccd_documents.deleted_at IS 'Служебное поле: дата/время удаления (soft delete; не графа)';
COMMENT ON COLUMN ccd_documents.status IS 'Служебное поле статуса CCD (completed/pending/failed и т.п.; используется в аналитике)';

-- Graph 1 details
COMMENT ON COLUMN ccd_documents.third_subdivision IS 'Графа 1: третий подраздел (например, ПНД)';

-- Graph 3 / 5
COMMENT ON COLUMN ccd_documents.total_sheets IS 'Графа 3: всего листов (авто)';
COMMENT ON COLUMN ccd_documents.items_count IS 'Графа 5: всего позиций (авто)';

-- Graph 11
COMMENT ON COLUMN ccd_documents.trade_country_offshore IS 'Графа 11: признак офшорной страны (если ведется)';

-- Graph 18 (transport main) details
COMMENT ON COLUMN ccd_documents.vehicle_type_code IS 'Графа 18: код типа транспортного средства (спец. двузначный)';
COMMENT ON COLUMN ccd_documents.vehicle_vin IS 'Графа 18: VIN/идентификатор ТС';
COMMENT ON COLUMN ccd_documents.vehicle_reg_country_id IS 'Графа 18: страна регистрации ТС (FK на codes_countries)';
COMMENT ON COLUMN ccd_documents.carrier_legal_id IS 'Графа 18: перевозчик (юр.лицо; FK на fea_legal_entities)';
COMMENT ON COLUMN ccd_documents.carrier_individual_id IS 'Графа 18: перевозчик (физ.лицо; FK на fea_individual_entities)';
COMMENT ON COLUMN ccd_documents.driver_name IS 'Графа 18: водитель/ответственное лицо по ТС';

-- Graph 20 details
COMMENT ON COLUMN ccd_documents.delivery_terms_place IS 'Графа 20: пункт по условиям поставки (место)';
COMMENT ON COLUMN ccd_documents.shipment_form_code IS 'Графа 20: код формы отгрузки';

-- Graph 21 details
COMMENT ON COLUMN ccd_documents.border_vehicle_reg_country_id IS 'Графа 21: страна регистрации ТС на границе (FK на codes_countries)';

-- Graph 24 details
COMMENT ON COLUMN ccd_documents.settlement_currency_id IS 'Графа 24: валюта расчетов (FK на codes_currencies)';

-- Graph 28 details
COMMENT ON COLUMN ccd_documents.payer_bank_id IS 'Графа 28: банк плательщика (FK на banks)';
COMMENT ON COLUMN ccd_documents.payer_bank_account IS 'Графа 28: счет плательщика (как введено)';
COMMENT ON COLUMN ccd_documents.payer_mfo IS 'Графа 28: МФО банка плательщика';

-- Graph 30 details
COMMENT ON COLUMN ccd_documents.location_license_number IS 'Графа 30: номер лицензии склада/СТЗ/магазина (если применимо)';
COMMENT ON COLUMN ccd_documents.location_license_date IS 'Графа 30: дата лицензии склада/СТЗ/магазина (если применимо)';
COMMENT ON COLUMN ccd_documents.location_address IS 'Графа 30: адрес местонахождения товаров';
COMMENT ON COLUMN ccd_documents.location_station_name IS 'Графа 30: наименование ЖД станции (если применимо)';

-- Graph 40 summary
COMMENT ON COLUMN ccd_documents.previous_docs_summary IS 'Графа 40: краткое резюме/список предшествующих документов (до нормализации в отдельные таблицы)';

-- Graph 48/49 details
COMMENT ON COLUMN ccd_documents.deferments IS 'Графа 48: отсрочки/рассрочки по платежам (JSON)';
COMMENT ON COLUMN ccd_documents.warehouse_license_number IS 'Графа 49: номер лицензии склада/режима (если применимо)';
COMMENT ON COLUMN ccd_documents.warehouse_license_date IS 'Графа 49: дата лицензии склада/режима (если применимо)';

-- Graph 50 details
COMMENT ON COLUMN ccd_documents.responsible_full_name IS 'Графа 50: ответственное лицо — ФИО';
COMMENT ON COLUMN ccd_documents.responsible_pinfl IS 'Графа 50: ПИНФЛ ответственного лица';
COMMENT ON COLUMN ccd_documents.responsible_authority IS 'Графа 50: полномочия/основание';
COMMENT ON COLUMN ccd_documents.obligation_due_date IS 'Графа 50: срок обязательства';

-- Graph 53 details
COMMENT ON COLUMN ccd_documents.transit_customs_post_id IS 'Графа 53: таможенный орган назначения (FK на codes_posts)';
COMMENT ON COLUMN ccd_documents.transit_destination_country_id IS 'Графа 53: страна назначения по транзиту (FK на codes_countries)';

-- Graph 54 details
COMMENT ON COLUMN ccd_documents.declaration_place IS 'Графа 54: место составления декларации';
COMMENT ON COLUMN ccd_documents.declaration_date IS 'Графа 54: дата составления декларации';
COMMENT ON COLUMN ccd_documents.contact_full_name IS 'Графа 54: ФИО контактного лица';
COMMENT ON COLUMN ccd_documents.contact_email IS 'Графа 54: email контактного лица';
COMMENT ON COLUMN ccd_documents.contact_phone IS 'Графа 54: телефон контактного лица';
COMMENT ON COLUMN ccd_documents.broker_contract_number IS 'Графа 54: номер договора с брокером';
COMMENT ON COLUMN ccd_documents.broker_contract_date IS 'Графа 54: дата договора с брокером';
COMMENT ON COLUMN ccd_documents.declarant_reference IS 'Графа 54: номер ГТД декларанта (ПИНФЛ/дата/последовательность)';

-- Special fields
COMMENT ON COLUMN ccd_documents.external_contract_id IS '“C”: внешний идентификатор контракта (при наличии интеграций)';
COMMENT ON COLUMN ccd_documents.regime_dates IS '“C”: даты/сроки по режиму (JSON)';

-- CCD Items ("добавочные листы"): one row per goods position for a document
CREATE TABLE IF NOT EXISTS ccd_items
(
    id                               INT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    created_at                        timestamptz NOT NULL DEFAULT NOW(),
    updated_at                        timestamptz,
    deleted_at                        timestamptz,
    status                            TEXT,

    document_id                       INT         NOT NULL REFERENCES ccd_documents (id) ON DELETE CASCADE,

    -- Graph 32: Порядковый номер позиции
    position_no                       INT         NOT NULL,

    -- Graph 31: Описание и детали
    trade_name                        TEXT        NOT NULL,  -- торговое/коммерческое наименование
    brand                             TEXT,                  -- бренд/марка/модель/артикул/сорт
    model                             TEXT,
    article                           TEXT,
    grade                             TEXT,
    specification                     TEXT,
    composition                       TEXT,                  -- состав/параметры (многострочный)
    energy_class                      TEXT,                  -- класс энергоэффективности (импорт по перечню)
    manufacture_date                  DATE,                  -- дата производства (при необходимости)

    -- Packaging / places
    is_packed                         BOOLEAN,
    packages_total                    INT,                   -- всего мест
    package_type                      TEXT,                  -- тип упаковки
    package_count                     INT,                   -- число упаковок
    bulk_code                         VARCHAR(2),            -- '01','02','03' для навал/насыпь/налив

    -- Containers (numbers ISO 6346) stored as JSON for flexibility with partial flags
    containers                        jsonb       NOT NULL DEFAULT '[]', -- [{number, partial:boolean, owner_flag:boolean}]

    -- Excise marks for excisable goods
    excise_marks                      jsonb       NOT NULL DEFAULT '[]', -- [{series, from, to}] or list of numbers

    -- Pipeline/LEP period
    supply_period_from                DATE,
    supply_period_to                  DATE,

    -- Additional import-specific attributes
    aggregated_import_code            TEXT,
    expiry_date                       DATE,
    investment_project_code           VARCHAR(3),            -- 101/102/.../000
    tech_equipment_area_code          TEXT,                  -- per Appendix 16 or '000'
    tech_equipment_year               INT,
    tech_equipment_params             TEXT,
    gov_procurement_code              VARCHAR(2),            -- '01'|'02'

    -- Producer/consumer (lower-left block) with district
    producer_id_code                  TEXT,                  -- ИНН/ПИНФЛ
    producer_district_id              INT REFERENCES codes_districts (id),
    consumer_id_code                  TEXT,                  -- ИНН/ПИНФЛ
    consumer_district_id              INT REFERENCES codes_districts (id),

    -- Lower-right block: additional unit
    additional_unit_id                INT REFERENCES codes_units (id),
    additional_unit_qty               NUMERIC(18, 6),

    -- Graph 33: HS code
    codes_hs_id                       INT REFERENCES codes_hs (id),

    -- Graph 34: Origin
    origin_country_id                 INT REFERENCES codes_countries (id),
    origin_alpha2                     VARCHAR(2),            -- optional display-only (e.g., 'EU')

    -- Graph 35/38: Weights
    gross_weight_kg                   NUMERIC(18, 6),
    net_weight_kg                     NUMERIC(18, 6),

    -- Graph 37: Procedure at item (optional; may mirror header)
    procedure_code                    VARCHAR(7),

    -- Graph 39: Quota (optional)
    quota_amount                      NUMERIC(18, 6),
    quota_unit_id                     INT REFERENCES codes_units (id),

    -- Graph 40: Previous docs for this item (optional JSON summary; detailed table can be added later)
    previous_docs                     jsonb       NOT NULL DEFAULT '[]',

    -- Graph 41 handled by additional_unit_* fields above

    -- Graph 42: Invoiced/factura value for the item (currency is from document Graph 22)
    invoiced_value                    NUMERIC(18, 2),

    -- Graph 43: Own production/needs indicator
    own_needs_flag                    BOOLEAN,               -- TRUE if for own needs/own production

    -- Graph 44: Documents list for the item
    documents                         jsonb       NOT NULL DEFAULT '[]',

    -- Graph 45/46: Customs and statistical values (auto-calculated typically)
    customs_value                     NUMERIC(18, 2),
    statistical_value_thousand_usd    NUMERIC(18, 3),

    -- Graph 47: Payments per item (structured JSON until normalized)
    payments                          jsonb       NOT NULL DEFAULT '[]',

    -- Source traceability: link to uploaded invoice and row number if available
    source_invoice_file_id            INT REFERENCES files (id),
    source_invoice_row_ref            TEXT,

    -- Checks
    CONSTRAINT ccd_items_pos_ck CHECK (position_no >= 1),
    CONSTRAINT ccd_items_bulk_ck CHECK (bulk_code IS NULL OR bulk_code IN ('01','02','03')),
    CONSTRAINT ccd_items_govproc_ck CHECK (gov_procurement_code IS NULL OR gov_procurement_code IN ('01','02')),
    CONSTRAINT ccd_items_proc_len_ck CHECK (procedure_code IS NULL OR length(procedure_code) = 7)
);

-- Uniqueness of position within a document
CREATE UNIQUE INDEX IF NOT EXISTS uq_ccd_items_doc_pos ON ccd_items (document_id, position_no);

-- Helpful indexes
CREATE INDEX IF NOT EXISTS idx_ccd_items_document_id ON ccd_items (document_id);
CREATE INDEX IF NOT EXISTS idx_ccd_items_hs ON ccd_items (codes_hs_id);
CREATE INDEX IF NOT EXISTS idx_ccd_items_origin ON ccd_items (origin_country_id);
