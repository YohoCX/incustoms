-- ============================================================================
-- Reference Code Tables (Справочники)
-- ============================================================================
-- Dictionary/reference tables used throughout CCD documents:
-- - codes_regimes: Customs regimes/Declaration forms (Graph 1)
-- - codes_posts: Customs posts (Graphs 7, 29, 53)
-- - codes_countries: Countries (Graphs 2, 11, 15, 17, 34, etc.)
-- - codes_districts: Districts/regions (Graphs 8, 30, 31)
-- - codes_currencies: Currencies (Graphs 13, 22, 24)
-- - codes_delivery_terms: Incoterms (Graph 20)
-- - codes_payment_forms: Payment forms (Graph 20)
-- - codes_deal_types: Deal characteristics (Graph 24)
-- - codes_transport_types: Transport types (Graphs 18, 21, 25, 26)
-- - codes_units: Units of measurement (Graphs 33, 41)
-- - codes_hs: HS codes/товарная номенклатура (Graph 33)
-- - codes_hs_tariff_rules: Tariff calculation rules
-- - codes_movement_types: Movement/procedure types (Graph 37)
-- - codes_brands: Brands/Trade marks (Graph 31)
-- - codes_energy_classes: Energy efficiency classes (Graph 31)
-- - codes_manufacturers: Manufacturers (Graph 31)
-- - codes_package_types: Package types (Graph 31)
-- - codes_car_colors: Car colors (Graph 31)
-- - codes_investment_programs: Investment programs (Graph 31)
-- - codes_accompanying_documents: Accompanying document types (Graph 44)
-- - codes_notes: Notes/remarks (Graph 44)
-- - currency_exchange_rate: Exchange rates (Graph 13)
-- ============================================================================

-- Графа 1: Customs regimes (Declaration forms)
CREATE TABLE IF NOT EXISTS codes_regimes
(
    id         INT                      NOT NULL PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE,
    deleted_at TIMESTAMP WITH TIME ZONE,
    status     entity_status            NOT NULL DEFAULT 'active',

    code       VARCHAR UNIQUE           NOT NULL,
    type       TEXT,
    name       TEXT                     NOT NULL,
    npa        TEXT                     NOT NULL,
    npa_url    TEXT
);

COMMENT ON TABLE codes_regimes IS 'Справочник таможенных режимов/форм декларации (Графа 1)';
COMMENT ON COLUMN codes_regimes.id IS 'Первичный ключ';
COMMENT ON COLUMN codes_regimes.code IS 'Код режима (уникальный)';
COMMENT ON COLUMN codes_regimes.type IS 'Тип режима';
COMMENT ON COLUMN codes_regimes.name IS 'Наименование режима';
COMMENT ON COLUMN codes_regimes.npa IS 'Нормативно-правовой акт (реквизиты)';
COMMENT ON COLUMN codes_regimes.npa_url IS 'Ссылка на НПА (гиперссылка на АИС Инфо)';

-- ============================================================================

-- Графа 7, 29, 53: Customs posts
CREATE TABLE IF NOT EXISTS codes_posts
(
    id           INT                      NOT NULL PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    created_at   TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at   TIMESTAMP WITH TIME ZONE,
    deleted_at   TIMESTAMP WITH TIME ZONE,
    status       entity_status            NOT NULL DEFAULT 'active',

    code         VARCHAR UNIQUE           NOT NULL,
    name         TEXT,
    phone_number VARCHAR(255),
    location_url TEXT
);

COMMENT ON TABLE codes_posts IS 'Справочник таможенных постов (Графы 7, 29, 53)';
COMMENT ON COLUMN codes_posts.id IS 'Первичный ключ';
COMMENT ON COLUMN codes_posts.code IS 'Код поста (обычно 5 цифр), уникальный';
COMMENT ON COLUMN codes_posts.name IS 'Наименование таможенного поста';
COMMENT ON COLUMN codes_posts.phone_number IS 'Контактный телефон поста';
COMMENT ON COLUMN codes_posts.location_url IS 'Ссылка на местоположение (карта/координаты)';

-- ============================================================================

-- Графы 2, 11, 15, 17, 18, 21, 34, 53: Countries
CREATE TABLE IF NOT EXISTS codes_countries
(
    id         INT                      NOT NULL PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE,
    deleted_at TIMESTAMP WITH TIME ZONE,
    status     entity_status            NOT NULL DEFAULT 'active',

    code       VARCHAR UNIQUE           NOT NULL,
    alpha_code VARCHAR UNIQUE           NOT NULL,
    name       VARCHAR(255)             NOT NULL,
    offshore   VARCHAR(255)             NOT NULL
);

COMMENT ON TABLE codes_countries IS 'Справочник стран (Графы 2, 11, 15, 15a, 17, 18, 21, 34, 53)';
COMMENT ON COLUMN codes_countries.id IS 'Первичный ключ';
COMMENT ON COLUMN codes_countries.code IS 'Цифровой код страны (обычно 3 цифры), уникальный';
COMMENT ON COLUMN codes_countries.alpha_code IS 'Двухбуквенный alpha-2 код страны (ISO 3166-1), уникальный';
COMMENT ON COLUMN codes_countries.name IS 'Наименование страны';
COMMENT ON COLUMN codes_countries.offshore IS 'Признак офшорной юрисдикции (если ведется список)';

-- ============================================================================

-- Графы 8, 30, 31: Districts/Regions
CREATE TABLE IF NOT EXISTS codes_districts
(
    id         INT                      NOT NULL PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE,
    deleted_at TIMESTAMP WITH TIME ZONE,
    status     entity_status            NOT NULL DEFAULT 'active',

    code       VARCHAR UNIQUE           NOT NULL,
    name       TEXT                     NOT NULL
);

COMMENT ON TABLE codes_districts IS 'Справочник регионов/районов/городов (Графы 8, 30, 31)';
COMMENT ON COLUMN codes_districts.id IS 'Первичный ключ';
COMMENT ON COLUMN codes_districts.code IS 'Код района/города (обычно 7 цифр), уникальный';
COMMENT ON COLUMN codes_districts.name IS 'Наименование района/города';

-- ============================================================================

-- Графы 13, 22, 24: Currencies
CREATE TABLE IF NOT EXISTS codes_currencies
(
    id         INT                      NOT NULL PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE,
    deleted_at TIMESTAMP WITH TIME ZONE,
    status     entity_status            NOT NULL DEFAULT 'active',

    code       VARCHAR UNIQUE           NOT NULL,
    alpha_code VARCHAR UNIQUE           NOT NULL,
    name       VARCHAR(255)             NOT NULL
);

COMMENT ON TABLE codes_currencies IS 'Справочник валют (Графы 13, 22, 24)';
COMMENT ON COLUMN codes_currencies.id IS 'Первичный ключ';
COMMENT ON COLUMN codes_currencies.code IS 'Цифровой код валюты (обычно 3 цифры), уникальный';
COMMENT ON COLUMN codes_currencies.alpha_code IS 'Буквенный alpha-3 код валюты (ISO 4217), уникальный';
COMMENT ON COLUMN codes_currencies.name IS 'Наименование валюты';

-- ============================================================================

-- Графа 20: Delivery terms (Incoterms)
CREATE TABLE IF NOT EXISTS codes_delivery_terms
(
    id         INT                      NOT NULL PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE,
    deleted_at TIMESTAMP WITH TIME ZONE,
    status     entity_status            NOT NULL DEFAULT 'active',

    code       VARCHAR UNIQUE           NOT NULL,
    alpha_code VARCHAR                  NOT NULL,
    name       VARCHAR                  NOT NULL
);

COMMENT ON TABLE codes_delivery_terms IS 'Базисы поставки Incoterms/условия поставки (Графа 20)';
COMMENT ON COLUMN codes_delivery_terms.id IS 'Первичный ключ';
COMMENT ON COLUMN codes_delivery_terms.code IS 'Цифровой код по приложению (уникальный)';
COMMENT ON COLUMN codes_delivery_terms.alpha_code IS 'Буквенный код Incoterms (например, EXW, FOB)';
COMMENT ON COLUMN codes_delivery_terms.name IS 'Наименование условия поставки';

-- ============================================================================

-- Графа 20: Payment forms
CREATE TABLE IF NOT EXISTS codes_payment_forms
(
    id         INT                      NOT NULL PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE,
    deleted_at TIMESTAMP WITH TIME ZONE,
    status     entity_status            NOT NULL DEFAULT 'active',

    code       VARCHAR UNIQUE           NOT NULL,
    name       VARCHAR                  NOT NULL
);

COMMENT ON TABLE codes_payment_forms IS 'Коды формы оплаты (Графа 20)';
COMMENT ON COLUMN codes_payment_forms.id IS 'Первичный ключ';
COMMENT ON COLUMN codes_payment_forms.code IS 'Код формы оплаты (уникальный)';
COMMENT ON COLUMN codes_payment_forms.name IS 'Наименование формы оплаты';

-- ============================================================================

-- Графа 24: Deal types
CREATE TABLE IF NOT EXISTS codes_deal_types
(
    id         INT                      NOT NULL PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE,
    deleted_at TIMESTAMP WITH TIME ZONE,
    status     entity_status            NOT NULL DEFAULT 'active',

    code       VARCHAR UNIQUE           NOT NULL,
    alpha_code VARCHAR                  NOT NULL,
    name       VARCHAR                  NOT NULL
);

COMMENT ON TABLE codes_deal_types IS 'Характер сделки (Графа 24)';
COMMENT ON COLUMN codes_deal_types.id IS 'Первичный ключ';
COMMENT ON COLUMN codes_deal_types.code IS 'Цифровой код характера сделки (уникальный)';
COMMENT ON COLUMN codes_deal_types.alpha_code IS 'Альтернативный/буквенный код';
COMMENT ON COLUMN codes_deal_types.name IS 'Наименование характера сделки';

-- ============================================================================

-- Графы 18, 21, 25, 26: Transport types
CREATE TABLE IF NOT EXISTS codes_transport_types
(
    id         INT                      NOT NULL PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE,
    deleted_at TIMESTAMP WITH TIME ZONE,
    status     entity_status            NOT NULL DEFAULT 'active',

    code       VARCHAR UNIQUE           NOT NULL,
    name       VARCHAR                  NOT NULL,
    short_name VARCHAR                  NOT NULL
);

COMMENT ON TABLE codes_transport_types IS 'Виды транспорта (Графы 18, 21, 25, 26)';
COMMENT ON COLUMN codes_transport_types.id IS 'Первичный ключ';
COMMENT ON COLUMN codes_transport_types.code IS 'Код вида транспорта (уникальный)';
COMMENT ON COLUMN codes_transport_types.name IS 'Наименование вида транспорта';
COMMENT ON COLUMN codes_transport_types.short_name IS 'Краткое обозначение (аббревиатура)';

-- ============================================================================

-- Графы 33, 41: Units of measurement
CREATE TABLE IF NOT EXISTS codes_units
(
    id         INT                      NOT NULL PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE,
    deleted_at TIMESTAMP WITH TIME ZONE,
    status     entity_status            NOT NULL DEFAULT 'active',

    code       VARCHAR UNIQUE           NOT NULL,
    alpha_code VARCHAR                  NOT NULL,
    name       VARCHAR                  NOT NULL
);

COMMENT ON TABLE codes_units IS 'Единицы измерения (Графы 33, 41 и правый нижний блок графы 31)';
COMMENT ON COLUMN codes_units.id IS 'Первичный ключ';
COMMENT ON COLUMN codes_units.code IS 'Цифровой код единицы измерения (уникальный)';
COMMENT ON COLUMN codes_units.alpha_code IS 'Буквенный код/сокращение единицы (например, L, M3)';
COMMENT ON COLUMN codes_units.name IS 'Наименование единицы измерения';

-- ============================================================================

-- Графа 33: HS codes (товарная номенклатура внешнеэкономической деятельности)
CREATE TABLE IF NOT EXISTS codes_hs
(
    id                            INT                      NOT NULL PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    created_at                    TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at                    TIMESTAMP WITH TIME ZONE,
    deleted_at                    TIMESTAMP WITH TIME ZONE,
    status                        entity_status            NOT NULL DEFAULT 'active',

    code                          VARCHAR UNIQUE           NOT NULL,
    description                   TEXT                     NOT NULL,

    -- Measurement requirements for calculations and validations
    requires_net_mass             BOOLEAN                  NOT NULL DEFAULT TRUE,
    requires_additional_unit      BOOLEAN                  NOT NULL DEFAULT FALSE,
    specific_rate_default_unit_id INT REFERENCES codes_units (id),

    notes                         TEXT
);

COMMENT ON TABLE codes_hs IS 'ТН ВЭД (Графа 33): коды товаров, флаги измерений и единица по умолчанию для специфических ставок';
COMMENT ON COLUMN codes_hs.id IS 'Первичный ключ';
COMMENT ON COLUMN codes_hs.code IS 'Код ТН ВЭД (обычно 10 цифр), уникальный';
COMMENT ON COLUMN codes_hs.description IS 'Описание товарной позиции';
COMMENT ON COLUMN codes_hs.requires_net_mass IS 'Требуется ли заполнение нетто-массы (кг) для расчёта';
COMMENT ON COLUMN codes_hs.requires_additional_unit IS 'Требуется ли доп. единица измерения для расчёта/учёта';
COMMENT ON COLUMN codes_hs.specific_rate_default_unit_id IS 'Единица измерения по умолчанию для специфических ставок (если не переопределено в правиле)';
COMMENT ON COLUMN codes_hs.notes IS 'Примечания/особенности расчётов и контроля';

-- ============================================================================

-- Junction table: HS codes <-> Units (available units per HS code)
CREATE TABLE IF NOT EXISTS available_units_for_hs
(
    id             INT                      NOT NULL PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    created_at     TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at     TIMESTAMP WITH TIME ZONE,
    deleted_at     TIMESTAMP WITH TIME ZONE,
    status         entity_status            NOT NULL DEFAULT 'active',

    codes_hs_id    INT REFERENCES codes_hs (id),
    codes_units_id INT REFERENCES codes_units (id)
);

COMMENT ON TABLE available_units_for_hs IS 'Допустимые единицы измерения для конкретных кодов ТН ВЭД (Графа 33), связь HS↔Unit';
COMMENT ON COLUMN available_units_for_hs.codes_hs_id IS 'FK на codes_hs (код ТН ВЭД)';
COMMENT ON COLUMN available_units_for_hs.codes_units_id IS 'FK на codes_units (единица измерения)';

-- ============================================================================

-- ENUMS for tariff rules
CREATE TYPE direction_code AS ENUM ('ИМ', 'ЭК', 'ТР');
CREATE TYPE tax_type AS ENUM ('duty', 'vat', 'excise', 'fee');
CREATE TYPE calculation_method AS ENUM ('ad_valorem', 'specific', 'mixed', 'exempt');
CREATE TYPE calculation_base AS ENUM ('customs_value', 'quantity', 'weight', 'custom');

COMMENT ON TYPE direction_code IS 'Направление: ИМ (импорт) | ЭК (экспорт) | ТР (транзит)';
COMMENT ON TYPE tax_type IS 'Тип налога/платежа: duty (пошлина) | vat (НДС) | excise (акциз) | fee (сбор)';
COMMENT ON TYPE calculation_method IS 'Метод расчёта: ad_valorem (адвалорная) | specific (специфическая) | mixed (комбинированная) | exempt (освобождение)';
COMMENT ON TYPE calculation_base IS 'База расчёта: customs_value (таможенная стоимость) | quantity (количество) | weight (вес) | custom (особая)';

-- ============================================================================

-- Tariff rules for duty/VAT/excise/fee calculations per HS code
CREATE TABLE IF NOT EXISTS codes_hs_tariff_rules
(
    id                 INT                      NOT NULL PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    created_at         TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at         TIMESTAMP WITH TIME ZONE,
    deleted_at         TIMESTAMP WITH TIME ZONE,
    status             entity_status            NOT NULL DEFAULT 'active',

    codes_hs_id        INT                      NOT NULL REFERENCES codes_hs (id),

    -- Applicability conditions
    direction          direction_code,                              -- NULL = applies to all directions
    regime_code        VARCHAR(8),                                  -- NULL = default
    origin_country_id  INT REFERENCES codes_countries (id),         -- NULL = any origin
    preference_code    VARCHAR(16),                                 -- preference/benefit code if applicable

    -- Tax type and calculation method
    tax_type           tax_type                 NOT NULL,
    method             calculation_method       NOT NULL,

    -- Calculation parameters
    ad_valorem_rate    NUMERIC(7, 3),                               -- % of base (for ad_valorem/mixed)
    specific_amount    NUMERIC(18, 6),                              -- amount per unit (for specific/mixed)
    specific_unit_id   INT REFERENCES codes_units (id),             -- unit for specific rate
    base               calculation_base         NOT NULL DEFAULT 'customs_value',
    min_amount         NUMERIC(18, 6),                              -- minimum amount if set
    max_amount         NUMERIC(18, 6),                              -- maximum amount if set

    -- Validity period and priority
    valid_from         DATE,
    valid_to           DATE,
    priority           INT                               DEFAULT 100, -- lower = higher priority on conflict

    legal_basis        TEXT,                                        -- NPA/legal reference
    notes              TEXT
);

CREATE INDEX IF NOT EXISTS idx_hs_rules_hs ON codes_hs_tariff_rules (codes_hs_id);
CREATE INDEX IF NOT EXISTS idx_hs_rules_kind ON codes_hs_tariff_rules (tax_type, method);
CREATE INDEX IF NOT EXISTS idx_hs_rules_valid ON codes_hs_tariff_rules (valid_from, valid_to);
CREATE INDEX IF NOT EXISTS idx_hs_rules_origin ON codes_hs_tariff_rules (origin_country_id);
CREATE INDEX IF NOT EXISTS idx_hs_rules_regime ON codes_hs_tariff_rules (regime_code);

COMMENT ON TABLE codes_hs_tariff_rules IS 'Правила расчёта пошлин/НДС/акцизов/сборов по коду ТН ВЭД с учётом направления, режима, происхождения и преференций';
COMMENT ON COLUMN codes_hs_tariff_rules.codes_hs_id IS 'FK на codes_hs (товарный код)';
COMMENT ON COLUMN codes_hs_tariff_rules.direction IS 'Направление: ИМ/ЭК/ТР; NULL = любое';
COMMENT ON COLUMN codes_hs_tariff_rules.regime_code IS 'Код таможенного режима; NULL = по умолчанию';
COMMENT ON COLUMN codes_hs_tariff_rules.origin_country_id IS 'Страна происхождения для дифференциации ставок; NULL = любая';
COMMENT ON COLUMN codes_hs_tariff_rules.preference_code IS 'Код льготы/преференции (при наличии)';
COMMENT ON COLUMN codes_hs_tariff_rules.tax_type IS 'Тип платежа: duty | vat | excise | fee';
COMMENT ON COLUMN codes_hs_tariff_rules.method IS 'Метод расчёта: ad_valorem | specific | mixed | exempt';
COMMENT ON COLUMN codes_hs_tariff_rules.ad_valorem_rate IS '% ставка (для ad valorem/mixed)';
COMMENT ON COLUMN codes_hs_tariff_rules.specific_amount IS 'Сумма за единицу (для specific/mixed)';
COMMENT ON COLUMN codes_hs_tariff_rules.specific_unit_id IS 'Единица для специфической ставки';
COMMENT ON COLUMN codes_hs_tariff_rules.base IS 'База расчёта: customs_value | quantity | weight | custom';
COMMENT ON COLUMN codes_hs_tariff_rules.min_amount IS 'Минимальный размер платежа (если установлен)';
COMMENT ON COLUMN codes_hs_tariff_rules.max_amount IS 'Максимальный размер платежа (если установлен)';
COMMENT ON COLUMN codes_hs_tariff_rules.valid_from IS 'Дата начала действия правила';
COMMENT ON COLUMN codes_hs_tariff_rules.valid_to IS 'Дата окончания действия правила';
COMMENT ON COLUMN codes_hs_tariff_rules.priority IS 'Приоритет применения (меньше = выше)';
COMMENT ON COLUMN codes_hs_tariff_rules.legal_basis IS 'НПА/основание для ставки';

-- ============================================================================

-- Графа 37: Movement types (procedure peculiarities)
CREATE TABLE IF NOT EXISTS codes_movement_types
(
    id         INT                      NOT NULL PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE,
    deleted_at TIMESTAMP WITH TIME ZONE,
    status     entity_status            NOT NULL DEFAULT 'active',

    code       VARCHAR UNIQUE           NOT NULL,
    name       TEXT                     NOT NULL
);

COMMENT ON TABLE codes_movement_types IS 'Особенности перемещения/процедуры (Графы 37 и/или 41)';
COMMENT ON COLUMN codes_movement_types.id IS 'Первичный ключ';
COMMENT ON COLUMN codes_movement_types.code IS 'Код особенности/процедуры (уникальный)';
COMMENT ON COLUMN codes_movement_types.name IS 'Наименование особенности/процедуры';

-- ============================================================================

-- Графа 13: Currency exchange rates
CREATE TABLE IF NOT EXISTS currency_exchange_rate
(
    id                INT                      NOT NULL PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    created_at        TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at        TIMESTAMP WITH TIME ZONE,
    deleted_at        TIMESTAMP WITH TIME ZONE,
    status            entity_status            NOT NULL DEFAULT 'active',

    codes_currency_id INT                      NOT NULL REFERENCES codes_currencies (id),
    rate              DECIMAL                  NOT NULL,
    effective_date    DATE                     NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_currency_rate_currency ON currency_exchange_rate (codes_currency_id);
CREATE INDEX IF NOT EXISTS idx_currency_rate_date ON currency_exchange_rate (effective_date);

COMMENT ON TABLE currency_exchange_rate IS 'Курсы валют к UZS (Графа 13)';
COMMENT ON COLUMN currency_exchange_rate.codes_currency_id IS 'FK на codes_currencies';
COMMENT ON COLUMN currency_exchange_rate.rate IS 'Курс валюты к UZS';
COMMENT ON COLUMN currency_exchange_rate.effective_date IS 'Дата действия курса';

-- ============================================================================
-- EXTENDED REFERENCE TABLES (from graphs.md)
-- ============================================================================

-- Графа 31: Brands/Trade marks
CREATE TABLE IF NOT EXISTS codes_brands
(
    id         INT                      NOT NULL PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE,
    deleted_at TIMESTAMP WITH TIME ZONE,
    status     entity_status            NOT NULL DEFAULT 'active',

    name       TEXT                     NOT NULL
);

COMMENT ON TABLE codes_brands IS 'Справочник брендов/торговых марок (Графа 31)';
COMMENT ON COLUMN codes_brands.id IS 'Первичный ключ';
COMMENT ON COLUMN codes_brands.name IS 'Наименование бренда/торговой марки';

CREATE INDEX IF NOT EXISTS idx_codes_brands_name ON codes_brands (name);

-- ============================================================================

-- Графа 31: Energy efficiency classes
CREATE TABLE IF NOT EXISTS codes_energy_classes
(
    id         INT                      NOT NULL PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE,
    deleted_at TIMESTAMP WITH TIME ZONE,
    status     entity_status            NOT NULL DEFAULT 'active',

    class_code VARCHAR                  NOT NULL UNIQUE
);

COMMENT ON TABLE codes_energy_classes IS 'Справочник классов энергоэффективности (Графа 31)';
COMMENT ON COLUMN codes_energy_classes.id IS 'Первичный ключ';
COMMENT ON COLUMN codes_energy_classes.class_code IS 'Класс энергоэффективности (например, A+, A++, B, C)';

-- ============================================================================

-- Графа 31: Manufacturers
CREATE TABLE IF NOT EXISTS codes_manufacturers
(
    id                INT                      NOT NULL PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    created_at        TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at        TIMESTAMP WITH TIME ZONE,
    deleted_at        TIMESTAMP WITH TIME ZONE,
    status            entity_status            NOT NULL DEFAULT 'active',

    name              TEXT                     NOT NULL,
    country_id        INT REFERENCES codes_countries (id)
);

COMMENT ON TABLE codes_manufacturers IS 'Справочник производителей (Графа 31)';
COMMENT ON COLUMN codes_manufacturers.id IS 'Первичный ключ';
COMMENT ON COLUMN codes_manufacturers.name IS 'Наименование производителя';
COMMENT ON COLUMN codes_manufacturers.country_id IS 'FK на codes_countries (код страны производителя)';

CREATE INDEX IF NOT EXISTS idx_codes_manufacturers_country ON codes_manufacturers (country_id);
CREATE INDEX IF NOT EXISTS idx_codes_manufacturers_name ON codes_manufacturers (name);

-- ============================================================================

-- Графа 31: Package types
CREATE TABLE IF NOT EXISTS codes_package_types
(
    id         INT                      NOT NULL PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE,
    deleted_at TIMESTAMP WITH TIME ZONE,
    status     entity_status            NOT NULL DEFAULT 'active',

    type_name  TEXT                     NOT NULL
);

COMMENT ON TABLE codes_package_types IS 'Справочник видов упаковок (Графа 31)';
COMMENT ON COLUMN codes_package_types.id IS 'Первичный ключ';
COMMENT ON COLUMN codes_package_types.type_name IS 'Тип упаковки';

-- ============================================================================

-- Графа 31: Car colors
CREATE TABLE IF NOT EXISTS codes_car_colors
(
    id         INT                      NOT NULL PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE,
    deleted_at TIMESTAMP WITH TIME ZONE,
    status     entity_status            NOT NULL DEFAULT 'active',

    code       VARCHAR UNIQUE           NOT NULL,
    name       TEXT                     NOT NULL
);

COMMENT ON TABLE codes_car_colors IS 'Справочник цветов автомобилей (Графа 31)';
COMMENT ON COLUMN codes_car_colors.id IS 'Первичный ключ';
COMMENT ON COLUMN codes_car_colors.code IS 'Код цвета';
COMMENT ON COLUMN codes_car_colors.name IS 'Название цвета';

-- ============================================================================

-- Графа 31: Investment programs
CREATE TABLE IF NOT EXISTS codes_investment_programs
(
    id         INT                      NOT NULL PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE,
    deleted_at TIMESTAMP WITH TIME ZONE,
    status     entity_status            NOT NULL DEFAULT 'active',

    code       VARCHAR UNIQUE           NOT NULL,
    name       TEXT                     NOT NULL,
    description TEXT
);

COMMENT ON TABLE codes_investment_programs IS 'Справочник инвестиционных программ (Графа 31)';
COMMENT ON COLUMN codes_investment_programs.id IS 'Первичный ключ';
COMMENT ON COLUMN codes_investment_programs.code IS 'Код инвестиционной программы';
COMMENT ON COLUMN codes_investment_programs.name IS 'Наименование программы';
COMMENT ON COLUMN codes_investment_programs.description IS 'Описание программы';

-- ============================================================================

-- Графа 44: Accompanying document types
CREATE TABLE IF NOT EXISTS codes_accompanying_documents
(
    id            INT                      NOT NULL PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    created_at    TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMP WITH TIME ZONE,
    deleted_at    TIMESTAMP WITH TIME ZONE,
    status        entity_status            NOT NULL DEFAULT 'active',

    document_code VARCHAR                  NOT NULL,
    document_name TEXT                     NOT NULL
);

COMMENT ON TABLE codes_accompanying_documents IS 'Справочник товаро-сопроводительных документов (Графа 44)';
COMMENT ON COLUMN codes_accompanying_documents.id IS 'Первичный ключ';
COMMENT ON COLUMN codes_accompanying_documents.document_code IS 'Код документа';
COMMENT ON COLUMN codes_accompanying_documents.document_name IS 'Наименование документа';

-- ============================================================================

-- Графа 44: Notes/Remarks
CREATE TABLE IF NOT EXISTS codes_notes
(
    id          INT                      NOT NULL PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    created_at  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMP WITH TIME ZONE,
    deleted_at  TIMESTAMP WITH TIME ZONE,
    status      entity_status            NOT NULL DEFAULT 'active',

    note        TEXT                     NOT NULL,
    description TEXT
);

COMMENT ON TABLE codes_notes IS 'Справочник примечаний (Графа 44)';
COMMENT ON COLUMN codes_notes.id IS 'Первичный ключ';
COMMENT ON COLUMN codes_notes.note IS 'Примечание';
COMMENT ON COLUMN codes_notes.description IS 'Описание примечания';

-- ============================================================================

-- Графа 18: Vehicle type codes
CREATE TABLE IF NOT EXISTS codes_vehicle_types
(
    id         INT                      NOT NULL PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE,
    deleted_at TIMESTAMP WITH TIME ZONE,
    status     entity_status            NOT NULL DEFAULT 'active',

    code       VARCHAR(2) UNIQUE        NOT NULL,
    name       TEXT                     NOT NULL
);

COMMENT ON TABLE codes_vehicle_types IS 'Справочник типов транспортных средств (Графа 18): 2-значные коды';
COMMENT ON COLUMN codes_vehicle_types.id IS 'Первичный ключ';
COMMENT ON COLUMN codes_vehicle_types.code IS '2-значный код типа ТС';
COMMENT ON COLUMN codes_vehicle_types.name IS 'Наименование типа транспортного средства';

-- ============================================================================

-- Графа 20: Shipment form codes
CREATE TABLE IF NOT EXISTS codes_shipment_forms
(
    id         INT                      NOT NULL PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE,
    deleted_at TIMESTAMP WITH TIME ZONE,
    status     entity_status            NOT NULL DEFAULT 'active',

    code       VARCHAR(10) UNIQUE       NOT NULL,
    name       TEXT                     NOT NULL
);

COMMENT ON TABLE codes_shipment_forms IS 'Справочник форм отгрузки (Графа 20)';
COMMENT ON COLUMN codes_shipment_forms.id IS 'Первичный ключ';
COMMENT ON COLUMN codes_shipment_forms.code IS 'Код формы отгрузки';
COMMENT ON COLUMN codes_shipment_forms.name IS 'Наименование формы отгрузки';
