-- ============================================================================
-- Foreign Economic Activity (FEA) Entities
-- ============================================================================
-- Tables for parties involved in foreign trade:
-- - fea_partners: Basic partner info (country + address)
-- - fea_partners_additional: Additional partner details (name, address, etc.)
-- - fea_legal_entities_short: Quick reference legal entities (INN/OKPO)
-- - fea_legal_entities: Full legal entity data
-- - fea_individual_entities: Individual (physical person) data
--
-- These tables are used for Graphs 2, 8, 9, 14, 18, 28, 44
-- ============================================================================

-- Графа 2, 8, 9, 14: Basic FEA partners (country + address)
CREATE TABLE IF NOT EXISTS fea_partners
(
    id               INT                      NOT NULL PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    created_at       TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at       TIMESTAMP WITH TIME ZONE,
    deleted_at       TIMESTAMP WITH TIME ZONE,
    status           entity_status            NOT NULL DEFAULT 'active',

    codes_country_id INT                      NOT NULL REFERENCES codes_countries (id),
    address          TEXT
);

COMMENT ON TABLE fea_partners IS 'Контрагенты ФЭД: страна и адрес. Используется как источник данных для сторон по графам 2 (экспортер/грузоотправитель), 8 (получатель), 9 (лицо, ответственное за финансовое урегулирование), 14 (декларант/брокер)';
COMMENT ON COLUMN fea_partners.id IS 'Первичный ключ';
COMMENT ON COLUMN fea_partners.codes_country_id IS 'FK на codes_countries; страна контрагента (используется в графах 2/8/9/14)';
COMMENT ON COLUMN fea_partners.address IS 'Почтовый адрес контрагента (используется в графах 2/8/9/14)';

CREATE INDEX IF NOT EXISTS idx_fea_partners_country ON fea_partners (codes_country_id);

-- ============================================================================

-- Графа 2, 8, 9, 14, 44: Additional partner information
CREATE TABLE IF NOT EXISTS fea_partners_additional
(
    id              INT                      NOT NULL PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    created_at      TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMP WITH TIME ZONE,
    deleted_at      TIMESTAMP WITH TIME ZONE,
    status          entity_status            NOT NULL DEFAULT 'active',

    name            VARCHAR(255)             NOT NULL,
    address         VARCHAR(255)             NOT NULL,
    country_id      INT REFERENCES codes_countries (id),
    additional_info TEXT
);

COMMENT ON TABLE fea_partners_additional IS 'Дополнительные сведения по контрагентам (наименование, адрес, страна). Используется для уточнения/подтверждения данных сторон в графах 2/8/9/14 и для автозаполнения соответствующих полей в ccd_documents; также может хранить сведения по документам графы 44';
COMMENT ON COLUMN fea_partners_additional.id IS 'Первичный ключ';
COMMENT ON COLUMN fea_partners_additional.name IS 'Наименование контрагента (для печатных форм и подсказок в графах 2/8/9/14)';
COMMENT ON COLUMN fea_partners_additional.address IS 'Адрес контрагента';
COMMENT ON COLUMN fea_partners_additional.country_id IS 'FK на codes_countries (страна контрагента)';
COMMENT ON COLUMN fea_partners_additional.additional_info IS 'Прочая информация (телефоны, примечания)';

CREATE INDEX IF NOT EXISTS idx_fea_partners_additional_country ON fea_partners_additional (country_id);

-- ============================================================================

-- Графа 2, 8, 9, 14: Short legal entities (quick reference)
CREATE TABLE IF NOT EXISTS fea_legal_entities_short
(
    id         INT                      NOT NULL PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE,
    deleted_at TIMESTAMP WITH TIME ZONE,
    status     entity_status            NOT NULL DEFAULT 'active',

    okpo       VARCHAR(255)             NOT NULL,
    inn        VARCHAR(255)             NOT NULL,
    name       VARCHAR(255),
    address    VARCHAR(255)
);

COMMENT ON TABLE fea_legal_entities_short IS 'Укороченный справочник юр.лиц (ИНН/ОКПО/адрес). Используется для автозаполнения граф 2/8/9/14 и быстрого выбора сторон при создании ccd_documents, когда достаточно базовых реквизитов';
COMMENT ON COLUMN fea_legal_entities_short.id IS 'Первичный ключ';
COMMENT ON COLUMN fea_legal_entities_short.okpo IS 'ОКПО организации';
COMMENT ON COLUMN fea_legal_entities_short.inn IS 'ИНН организации (используется в графах 2/8/9/14)';
COMMENT ON COLUMN fea_legal_entities_short.name IS 'Наименование организации';
COMMENT ON COLUMN fea_legal_entities_short.address IS 'Адрес организации';

CREATE INDEX IF NOT EXISTS idx_fea_legal_entities_short_inn ON fea_legal_entities_short (inn);
CREATE INDEX IF NOT EXISTS idx_fea_legal_entities_short_okpo ON fea_legal_entities_short (okpo);

-- ============================================================================

-- Графа 2, 8, 9, 14, 18, 28: Full legal entities
CREATE TABLE IF NOT EXISTS fea_legal_entities
(
    id                      INT                      NOT NULL PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    created_at              TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at              TIMESTAMP WITH TIME ZONE,
    deleted_at              TIMESTAMP WITH TIME ZONE,
    status                  entity_status            NOT NULL DEFAULT 'active',

    region_id               INT REFERENCES codes_districts (id),

    okpo                    VARCHAR(255),
    inn                     VARCHAR(255)             NOT NULL,
    name                    VARCHAR(255),
    address                 VARCHAR(255)             NOT NULL,
    additional_information  VARCHAR(255),
    supervisor              VARCHAR(255),
    oked                    INT,
    oked_code               INT,
    phone_number            VARCHAR(255)             NOT NULL,
    registration_number     VARCHAR(255),
    registration_date       VARCHAR(255),

    current_account_number  VARCHAR(255),
    current_account_bank_id INT REFERENCES banks (id),
    fx_account_number       VARCHAR(255),
    fx_account_bank_id      INT REFERENCES banks (id)
);

COMMENT ON TABLE fea_legal_entities IS 'Полные данные юр.лиц для ролей по графам 2/8/9/14/18/28; содержит банковские реквизиты для графы 28 при выборе плательщиком юр.лица';
COMMENT ON COLUMN fea_legal_entities.id IS 'Первичный ключ';
COMMENT ON COLUMN fea_legal_entities.region_id IS 'FK на codes_districts (юридический адрес/район), используется в графах 8/31';
COMMENT ON COLUMN fea_legal_entities.okpo IS 'ОКПО организации';
COMMENT ON COLUMN fea_legal_entities.inn IS 'ИНН организации (ключевой реквизит для граф 2/8/9/14)';
COMMENT ON COLUMN fea_legal_entities.name IS 'Полное наименование организации';
COMMENT ON COLUMN fea_legal_entities.address IS 'Юридический/почтовый адрес';
COMMENT ON COLUMN fea_legal_entities.additional_information IS 'Доп. сведения';
COMMENT ON COLUMN fea_legal_entities.supervisor IS 'Руководитель/контактное лицо';
COMMENT ON COLUMN fea_legal_entities.oked IS 'ОКЭД (числовое значение)';
COMMENT ON COLUMN fea_legal_entities.oked_code IS 'ОКЭД (код)';
COMMENT ON COLUMN fea_legal_entities.phone_number IS 'Контактный телефон';
COMMENT ON COLUMN fea_legal_entities.registration_number IS 'Номер регистрации';
COMMENT ON COLUMN fea_legal_entities.registration_date IS 'Дата регистрации';
COMMENT ON COLUMN fea_legal_entities.current_account_number IS 'Расчетный счет (используется при заполнении графы 28)';
COMMENT ON COLUMN fea_legal_entities.current_account_bank_id IS 'FK на banks (банк расчетного счета)';
COMMENT ON COLUMN fea_legal_entities.fx_account_number IS 'Валютный счет (при наличии)';
COMMENT ON COLUMN fea_legal_entities.fx_account_bank_id IS 'FK на banks (банк валютного счета)';

CREATE INDEX IF NOT EXISTS idx_fea_legal_entities_inn ON fea_legal_entities (inn);
CREATE INDEX IF NOT EXISTS idx_fea_legal_entities_region ON fea_legal_entities (region_id);
CREATE INDEX IF NOT EXISTS idx_fea_legal_entities_current_bank ON fea_legal_entities (current_account_bank_id);
CREATE INDEX IF NOT EXISTS idx_fea_legal_entities_fx_bank ON fea_legal_entities (fx_account_bank_id);

-- ============================================================================

-- Графа 2, 8, 9, 14, 18, 28: Individual (physical person) entities
CREATE TABLE IF NOT EXISTS fea_individual_entities
(
    id                      INT                      NOT NULL PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    created_at              TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at              TIMESTAMP WITH TIME ZONE,
    deleted_at              TIMESTAMP WITH TIME ZONE,
    status                  entity_status            NOT NULL DEFAULT 'active',

    region_id               INT REFERENCES codes_districts (id),

    -- Required fields
    pinfl                   VARCHAR                  NOT NULL,
    full_name               TEXT                     NOT NULL,
    address                 TEXT                     NOT NULL,
    district_id             INT                      NOT NULL REFERENCES codes_districts (id),
    phone                   VARCHAR                  NOT NULL,
    passport_number         VARCHAR                  NOT NULL,
    passport_issued_at      DATE                     NOT NULL,
    passport_issued_by      TEXT                     NOT NULL,

    -- Optional fields
    patent_number           TEXT,
    extra_info              TEXT,

    -- Bank requisites (stored as text to keep leading zeros/format)
    current_account_number  TEXT,
    current_account_bank_id INT REFERENCES banks (id),
    fx_account_number       TEXT,
    fx_account_bank_id      INT REFERENCES banks (id)
);

COMMENT ON TABLE fea_individual_entities IS 'Данные физических лиц для ролей по графам 2/8/9/14/18 и плательщика по графе 28 (при участии физ.лица)';
COMMENT ON COLUMN fea_individual_entities.id IS 'Первичный ключ';
COMMENT ON COLUMN fea_individual_entities.region_id IS 'FK на codes_districts (место жительства/район)';
COMMENT ON COLUMN fea_individual_entities.pinfl IS 'ПИНФЛ физического лица (используется в графах 2/8/9/14 и 50)';
COMMENT ON COLUMN fea_individual_entities.full_name IS 'ФИО';
COMMENT ON COLUMN fea_individual_entities.address IS 'Адрес проживания';
COMMENT ON COLUMN fea_individual_entities.district_id IS 'FK на codes_districts (район)';
COMMENT ON COLUMN fea_individual_entities.phone IS 'Контактный телефон';
COMMENT ON COLUMN fea_individual_entities.passport_number IS 'Серия/номер паспорта';
COMMENT ON COLUMN fea_individual_entities.passport_issued_at IS 'Дата выдачи паспорта';
COMMENT ON COLUMN fea_individual_entities.passport_issued_by IS 'Кем выдан паспорт';
COMMENT ON COLUMN fea_individual_entities.patent_number IS 'Номер патента (при наличии)';
COMMENT ON COLUMN fea_individual_entities.extra_info IS 'Дополнительные сведения';
COMMENT ON COLUMN fea_individual_entities.current_account_number IS 'Расчетный счет (для графы 28 при участии физ.лица)';
COMMENT ON COLUMN fea_individual_entities.current_account_bank_id IS 'FK на banks (банк расчетного счета)';
COMMENT ON COLUMN fea_individual_entities.fx_account_number IS 'Валютный счет';
COMMENT ON COLUMN fea_individual_entities.fx_account_bank_id IS 'FK на banks (банк валютного счета)';

CREATE INDEX IF NOT EXISTS idx_fea_individual_entities_pinfl ON fea_individual_entities (pinfl);
CREATE INDEX IF NOT EXISTS idx_fea_individual_entities_region ON fea_individual_entities (region_id);
CREATE INDEX IF NOT EXISTS idx_fea_individual_entities_district ON fea_individual_entities (district_id);
CREATE INDEX IF NOT EXISTS idx_fea_individual_entities_current_bank ON fea_individual_entities (current_account_bank_id);
CREATE INDEX IF NOT EXISTS idx_fea_individual_entities_fx_bank ON fea_individual_entities (fx_account_bank_id);
