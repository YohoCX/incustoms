-- Графа 2
CREATE TABLE IF NOT EXISTS fea_partners
(
    id               INT                      NOT NULL PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    created_at       TIMESTAMP WITH TIME ZONE NOT NULL,
    updated_at       TIMESTAMP WITH TIME ZONE,
    deleted_at       TIMESTAMP WITH TIME ZONE,
    status           VARCHAR(255), -- active | deleted | archived

    codes_country_id INT                      NOT NULL REFERENCES codes_countries (id),
    address          TEXT
);

-- Comments: fea_partners
COMMENT ON TABLE fea_partners IS 'Контрагенты ФЭД: страна и адрес. Используется как источник данных для сторон по графам 2 (экспортер/грузоотправитель), 8 (получатель), 9 (лицо, ответственное за финансовое урегулирование), 14 (декларант/брокер)';
COMMENT ON COLUMN fea_partners.id IS 'Первичный ключ';
COMMENT ON COLUMN fea_partners.created_at IS 'Дата/время создания записи';
COMMENT ON COLUMN fea_partners.updated_at IS 'Дата/время изменения записи';
COMMENT ON COLUMN fea_partners.deleted_at IS 'Дата/время удаления (soft delete)';
COMMENT ON COLUMN fea_partners.status IS 'Статус записи: active | deleted | archived';
COMMENT ON COLUMN fea_partners.codes_country_id IS 'FK на codes_countries; страна контрагента (используется в графах 2/8/9/14)';
COMMENT ON COLUMN fea_partners.address IS 'Почтовый адрес контрагента (используется в графах 2/8/9/14)';

CREATE TABLE IF NOT EXISTS fea_partners_additional
(
    id              INT                      NOT NULL PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    created_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    updated_at      TIMESTAMP WITH TIME ZONE,
    deleted_at      TIMESTAMP WITH TIME ZONE,
    status          VARCHAR(255), -- active | deleted | archived

    name            VARCHAR(255)             NOT NULL,
    address         VARCHAR(255)             NOT NULL,
    country_id      INT,
    additional_info TEXT
);

-- Comments: fea_partners_additional
COMMENT ON TABLE fea_partners_additional IS 'Дополнительные сведения по контрагентам (наименование, адрес, страна). Используется для уточнения/подтверждения данных сторон в графах 2/8/9/14 и для автозаполнения соответствующих полей в ccd_documents; также может хранить сведения по документам графы 44';
COMMENT ON COLUMN fea_partners_additional.id IS 'Первичный ключ';
COMMENT ON COLUMN fea_partners_additional.created_at IS 'Дата/время создания записи';
COMMENT ON COLUMN fea_partners_additional.updated_at IS 'Дата/время изменения записи';
COMMENT ON COLUMN fea_partners_additional.deleted_at IS 'Дата/время удаления (soft delete)';
COMMENT ON COLUMN fea_partners_additional.status IS 'Статус записи: active | deleted | archived';
COMMENT ON COLUMN fea_partners_additional.name IS 'Наименование контрагента (для печатных форм и подсказок в графах 2/8/9/14)';
COMMENT ON COLUMN fea_partners_additional.address IS 'Адрес контрагента';
COMMENT ON COLUMN fea_partners_additional.country_id IS 'FK на codes_countries (страна контрагента)';
COMMENT ON COLUMN fea_partners_additional.additional_info IS 'Прочая информация (телефоны, примечания)';

-- Графа 8
CREATE TABLE IF NOT EXISTS fea_legal_entities_short
(
    id         INT                      NOT NULL PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE,
    deleted_at TIMESTAMP WITH TIME ZONE,
    status     VARCHAR(255), -- active | deleted | archived

    okpo       VARCHAR(255)             NOT NULL,
    inn        VARCHAR(255)             NOT NULL,
    name       VARCHAR(255),
    address    VARCHAR(255)
);

-- Comments: fea_legal_entities_short
COMMENT ON TABLE fea_legal_entities_short IS 'Укороченный справочник юр.лиц (ИНН/ОКПО/адрес). Используется для автозаполнения граф 2/8/9/14 и быстрого выбора сторон при создании ccd_documents, когда достаточно базовых реквизитов';
COMMENT ON COLUMN fea_legal_entities_short.id IS 'Первичный ключ';
COMMENT ON COLUMN fea_legal_entities_short.created_at IS 'Дата/время создания записи';
COMMENT ON COLUMN fea_legal_entities_short.updated_at IS 'Дата/время изменения записи';
COMMENT ON COLUMN fea_legal_entities_short.deleted_at IS 'Дата/время удаления (soft delete)';
COMMENT ON COLUMN fea_legal_entities_short.status IS 'Статус записи: active | deleted | archived';
COMMENT ON COLUMN fea_legal_entities_short.okpo IS 'ОКПО организации';
COMMENT ON COLUMN fea_legal_entities_short.inn IS 'ИНН организации (используется в графах 2/8/9/14)';
COMMENT ON COLUMN fea_legal_entities_short.name IS 'Наименование организации';
COMMENT ON COLUMN fea_legal_entities_short.address IS 'Адрес организации';

-- Графа 8, 9
CREATE TABLE IF NOT EXISTS fea_legal_entities
(
    id                      INT                      NOT NULL PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    created_at              TIMESTAMP WITH TIME ZONE NOT NULL,
    updated_at              TIMESTAMP WITH TIME ZONE,
    deleted_at              TIMESTAMP WITH TIME ZONE,
    status                  VARCHAR(255), -- active | deleted | archived

    region_id               INT,

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
    current_account_bank_id INT,
    fx_account_number       VARCHAR(255),
    fx_account_bank_id      INT
);

-- Comments: fea_legal_entities
COMMENT ON TABLE fea_legal_entities IS 'Полные данные юр.лиц для ролей по графам 2/8/9/14; содержит банковские реквизиты для графы 28 при выборе плательщиком юр.лица';
COMMENT ON COLUMN fea_legal_entities.id IS 'Первичный ключ';
COMMENT ON COLUMN fea_legal_entities.created_at IS 'Дата/время создания записи';
COMMENT ON COLUMN fea_legal_entities.updated_at IS 'Дата/время изменения записи';
COMMENT ON COLUMN fea_legal_entities.deleted_at IS 'Дата/время удаления (soft delete)';
COMMENT ON COLUMN fea_legal_entities.status IS 'Статус записи: active | deleted | archived';
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

-- Графа 8, 9
CREATE TABLE IF NOT EXISTS fea_individual_entities
(
    id                      INT                      NOT NULL PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    created_at              TIMESTAMP WITH TIME ZONE NOT NULL,
    updated_at              TIMESTAMP WITH TIME ZONE,
    deleted_at              TIMESTAMP WITH TIME ZONE,
    status                  VARCHAR(255), -- active | deleted | archived

    region_id               INT,

    -- Required
    pinfl                   VARCHAR                  NOT NULL,
    full_name               TEXT                     NOT NULL,
    address                 TEXT                     NOT NULL,
    district_id             INTEGER                  NOT NULL,
    phone                   VARCHAR                  NOT NULL,
    passport_number         VARCHAR                  NOT NULL,
    passport_issued_at      DATE                     NOT NULL,
    passport_issued_by      TEXT                     NOT NULL,

    -- Optional
    patent_number           TEXT,
    extra_info              TEXT,

    -- Bank requisites (stored as text to keep leading zeros/format)
    current_account_number  TEXT,
    current_account_bank_id INTEGER,
    fx_account_number       TEXT,
    fx_account_bank_id      INTEGER
);

-- Comments: fea_individual_entities
COMMENT ON TABLE fea_individual_entities IS 'Данные физических лиц для ролей по графам 2/8/9/14 и плательщика по графе 28 (при участии физ.лица)';
COMMENT ON COLUMN fea_individual_entities.id IS 'Первичный ключ';
COMMENT ON COLUMN fea_individual_entities.created_at IS 'Дата/время создания записи';
COMMENT ON COLUMN fea_individual_entities.updated_at IS 'Дата/время изменения записи';
COMMENT ON COLUMN fea_individual_entities.deleted_at IS 'Дата/время удаления (soft delete)';
COMMENT ON COLUMN fea_individual_entities.status IS 'Статус записи: active | deleted | archived';
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
