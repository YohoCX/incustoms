-- ============================================================================
-- Document Junction Tables
-- ============================================================================
-- This migration creates junction tables for all ccd_documents relationships
-- to codes and FEA tables, allowing document-specific customization.
--
-- Pattern: ccd_document_{reference_table}
-- Each junction table includes:
-- - id, document_id, {reference}_id
-- - role/type discriminator (where multiple uses exist)
-- - Nullable custom fields for document-specific overrides
-- - Standard audit fields
-- ============================================================================

-- ENUMS for junction tables
CREATE TYPE document_entity_role AS ENUM ('exporter', 'consignee', 'declarant', 'financial', 'payer', 'carrier');
CREATE TYPE document_post_type AS ENUM ('processing', 'border', 'transit');
CREATE TYPE document_country_type AS ENUM ('trade', 'dispatch', 'destination', 'vehicle_reg', 'border_vehicle_reg', 'transit_destination');
CREATE TYPE document_transport_role AS ENUM ('main', 'border', 'at_border', 'inside_country');
CREATE TYPE document_currency_type AS ENUM ('contract', 'settlement');

COMMENT ON TYPE document_entity_role IS 'Роль стороны: exporter (Г.2) | consignee (Г.8) | declarant (Г.14) | financial (Г.9) | payer (Г.28) | carrier (Г.18)';
COMMENT ON TYPE document_post_type IS 'Тип поста: processing (Г.7) | border (Г.29) | transit (Г.53)';
COMMENT ON TYPE document_country_type IS 'Тип страны: trade (Г.11) | dispatch (Г.15) | destination (Г.17) | vehicle_reg (Г.18) | border_vehicle_reg (Г.21) | transit_destination (Г.53)';
COMMENT ON TYPE document_transport_role IS 'Роль транспорта: main (Г.18) | border (Г.21) | at_border (Г.25) | inside_country (Г.26)';
COMMENT ON TYPE document_currency_type IS 'Тип валюты: contract (Г.22) | settlement (Г.24)';

-- ============================================================================
-- CODES REFERENCE TABLES JOINS
-- ============================================================================

-- Graph 1: Customs regimes
CREATE TABLE IF NOT EXISTS ccd_document_regimes
(
    id                 INT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    created_at         timestamptz NOT NULL DEFAULT NOW(),
    updated_at         timestamptz,
    deleted_at         timestamptz,
    status             entity_status NOT NULL DEFAULT 'active',

    document_id        INT NOT NULL REFERENCES ccd_documents (id) ON DELETE CASCADE,
    codes_regimes_id   INT NOT NULL REFERENCES codes_regimes (id),

    -- Customizable fields
    custom_type        TEXT,
    custom_name        TEXT,
    custom_npa         TEXT,
    custom_npa_url     TEXT,
    notes              TEXT
);

CREATE INDEX IF NOT EXISTS idx_ccd_document_regimes_document ON ccd_document_regimes (document_id);
CREATE INDEX IF NOT EXISTS idx_ccd_document_regimes_code ON ccd_document_regimes (codes_regimes_id);

COMMENT ON TABLE ccd_document_regimes IS 'Связь CCD документа с таможенными режимами (Графа 1)';
COMMENT ON COLUMN ccd_document_regimes.document_id IS 'FK на ccd_documents (CASCADE DELETE)';
COMMENT ON COLUMN ccd_document_regimes.codes_regimes_id IS 'FK на codes_regimes';

-- ============================================================================

-- Graphs 7, 29, 53: Customs posts
CREATE TABLE IF NOT EXISTS ccd_document_posts
(
    id                  INT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    created_at          timestamptz NOT NULL DEFAULT NOW(),
    updated_at          timestamptz,
    deleted_at          timestamptz,
    status              entity_status NOT NULL DEFAULT 'active',

    document_id         INT NOT NULL REFERENCES ccd_documents (id) ON DELETE CASCADE,
    codes_posts_id      INT NOT NULL REFERENCES codes_posts (id),
    post_type           document_post_type NOT NULL,

    -- Customizable fields
    custom_name         TEXT,
    custom_phone_number VARCHAR(255),
    custom_location_url TEXT,
    notes               TEXT
);

CREATE INDEX IF NOT EXISTS idx_ccd_document_posts_document ON ccd_document_posts (document_id);
CREATE INDEX IF NOT EXISTS idx_ccd_document_posts_code ON ccd_document_posts (codes_posts_id);
CREATE INDEX IF NOT EXISTS idx_ccd_document_posts_type ON ccd_document_posts (post_type);

COMMENT ON TABLE ccd_document_posts IS 'Связь CCD документа с таможенными постами (Графы 7, 29, 53)';
COMMENT ON COLUMN ccd_document_posts.post_type IS 'Тип поста: processing (Г.7), border (Г.29), transit (Г.53)';

-- ============================================================================

-- Graphs 11, 15, 17, 18, 21, 53: Countries
CREATE TABLE IF NOT EXISTS ccd_document_countries
(
    id                   INT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    created_at           timestamptz NOT NULL DEFAULT NOW(),
    updated_at           timestamptz,
    deleted_at           timestamptz,
    status               entity_status NOT NULL DEFAULT 'active',

    document_id          INT NOT NULL REFERENCES ccd_documents (id) ON DELETE CASCADE,
    codes_countries_id   INT NOT NULL REFERENCES codes_countries (id),
    country_type         document_country_type NOT NULL,

    -- Customizable fields
    custom_name          VARCHAR(255),
    custom_offshore      VARCHAR(255),
    notes                TEXT
);

CREATE INDEX IF NOT EXISTS idx_ccd_document_countries_document ON ccd_document_countries (document_id);
CREATE INDEX IF NOT EXISTS idx_ccd_document_countries_code ON ccd_document_countries (codes_countries_id);
CREATE INDEX IF NOT EXISTS idx_ccd_document_countries_type ON ccd_document_countries (country_type);

COMMENT ON TABLE ccd_document_countries IS 'Связь CCD документа со странами (Графы 11, 15, 17, 18, 21, 53)';
COMMENT ON COLUMN ccd_document_countries.country_type IS 'Тип: trade (Г.11), dispatch (Г.15), destination (Г.17), vehicle_reg (Г.18), border_vehicle_reg (Г.21), transit_destination (Г.53)';

-- ============================================================================

-- Graphs 18, 21, 25, 26: Transport types
CREATE TABLE IF NOT EXISTS ccd_document_transport_types
(
    id                        INT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    created_at                timestamptz NOT NULL DEFAULT NOW(),
    updated_at                timestamptz,
    deleted_at                timestamptz,
    status                    entity_status NOT NULL DEFAULT 'active',

    document_id               INT NOT NULL REFERENCES ccd_documents (id) ON DELETE CASCADE,
    codes_transport_types_id  INT NOT NULL REFERENCES codes_transport_types (id),
    transport_role            document_transport_role NOT NULL,

    -- Customizable fields
    custom_name               VARCHAR(255),
    custom_short_name         VARCHAR(255),
    notes                     TEXT
);

CREATE INDEX IF NOT EXISTS idx_ccd_document_transport_types_document ON ccd_document_transport_types (document_id);
CREATE INDEX IF NOT EXISTS idx_ccd_document_transport_types_code ON ccd_document_transport_types (codes_transport_types_id);
CREATE INDEX IF NOT EXISTS idx_ccd_document_transport_types_role ON ccd_document_transport_types (transport_role);

COMMENT ON TABLE ccd_document_transport_types IS 'Связь CCD документа с видами транспорта (Графы 18, 21, 25, 26)';
COMMENT ON COLUMN ccd_document_transport_types.transport_role IS 'Роль: main (Г.18), border (Г.21), at_border (Г.25), inside_country (Г.26)';

-- ============================================================================

-- Graph 20: Delivery terms
CREATE TABLE IF NOT EXISTS ccd_document_delivery_terms
(
    id                        INT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    created_at                timestamptz NOT NULL DEFAULT NOW(),
    updated_at                timestamptz,
    deleted_at                timestamptz,
    status                    entity_status NOT NULL DEFAULT 'active',

    document_id               INT NOT NULL REFERENCES ccd_documents (id) ON DELETE CASCADE,
    codes_delivery_terms_id   INT NOT NULL REFERENCES codes_delivery_terms (id),

    -- Customizable fields
    custom_alpha_code         VARCHAR(255),
    custom_name               VARCHAR(255),
    delivery_place            TEXT,
    notes                     TEXT
);

CREATE INDEX IF NOT EXISTS idx_ccd_document_delivery_terms_document ON ccd_document_delivery_terms (document_id);
CREATE INDEX IF NOT EXISTS idx_ccd_document_delivery_terms_code ON ccd_document_delivery_terms (codes_delivery_terms_id);

COMMENT ON TABLE ccd_document_delivery_terms IS 'Связь CCD документа с условиями поставки (Графа 20)';
COMMENT ON COLUMN ccd_document_delivery_terms.delivery_place IS 'Место по условиям поставки (из Г.20)';

-- ============================================================================

-- Graph 20: Payment forms
CREATE TABLE IF NOT EXISTS ccd_document_payment_forms
(
    id                       INT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    created_at               timestamptz NOT NULL DEFAULT NOW(),
    updated_at               timestamptz,
    deleted_at               timestamptz,
    status                   entity_status NOT NULL DEFAULT 'active',

    document_id              INT NOT NULL REFERENCES ccd_documents (id) ON DELETE CASCADE,
    codes_payment_forms_id   INT NOT NULL REFERENCES codes_payment_forms (id),

    -- Customizable fields
    custom_name              VARCHAR(255),
    notes                    TEXT
);

CREATE INDEX IF NOT EXISTS idx_ccd_document_payment_forms_document ON ccd_document_payment_forms (document_id);
CREATE INDEX IF NOT EXISTS idx_ccd_document_payment_forms_code ON ccd_document_payment_forms (codes_payment_forms_id);

COMMENT ON TABLE ccd_document_payment_forms IS 'Связь CCD документа с формами оплаты (Графа 20)';

-- ============================================================================

-- Graphs 22, 24: Currencies
CREATE TABLE IF NOT EXISTS ccd_document_currencies
(
    id                    INT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    created_at            timestamptz NOT NULL DEFAULT NOW(),
    updated_at            timestamptz,
    deleted_at            timestamptz,
    status                entity_status NOT NULL DEFAULT 'active',

    document_id           INT NOT NULL REFERENCES ccd_documents (id) ON DELETE CASCADE,
    codes_currencies_id   INT NOT NULL REFERENCES codes_currencies (id),
    currency_type         document_currency_type NOT NULL,

    -- Customizable fields
    custom_name           VARCHAR(255),
    exchange_rate         NUMERIC(18, 6),
    notes                 TEXT
);

CREATE INDEX IF NOT EXISTS idx_ccd_document_currencies_document ON ccd_document_currencies (document_id);
CREATE INDEX IF NOT EXISTS idx_ccd_document_currencies_code ON ccd_document_currencies (codes_currencies_id);
CREATE INDEX IF NOT EXISTS idx_ccd_document_currencies_type ON ccd_document_currencies (currency_type);

COMMENT ON TABLE ccd_document_currencies IS 'Связь CCD документа с валютами (Графы 22, 24)';
COMMENT ON COLUMN ccd_document_currencies.currency_type IS 'Тип: contract (Г.22), settlement (Г.24)';
COMMENT ON COLUMN ccd_document_currencies.exchange_rate IS 'Курс валюты к UZS (для документа)';

-- ============================================================================

-- Graph 24: Deal types
CREATE TABLE IF NOT EXISTS ccd_document_deal_types
(
    id                    INT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    created_at            timestamptz NOT NULL DEFAULT NOW(),
    updated_at            timestamptz,
    deleted_at            timestamptz,
    status                entity_status NOT NULL DEFAULT 'active',

    document_id           INT NOT NULL REFERENCES ccd_documents (id) ON DELETE CASCADE,
    codes_deal_types_id   INT NOT NULL REFERENCES codes_deal_types (id),

    -- Customizable fields
    custom_alpha_code     VARCHAR(255),
    custom_name           VARCHAR(255),
    notes                 TEXT
);

CREATE INDEX IF NOT EXISTS idx_ccd_document_deal_types_document ON ccd_document_deal_types (document_id);
CREATE INDEX IF NOT EXISTS idx_ccd_document_deal_types_code ON ccd_document_deal_types (codes_deal_types_id);

COMMENT ON TABLE ccd_document_deal_types IS 'Связь CCD документа с характером сделки (Графа 24)';

-- ============================================================================

-- Graph 30: Districts
CREATE TABLE IF NOT EXISTS ccd_document_districts
(
    id                   INT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    created_at           timestamptz NOT NULL DEFAULT NOW(),
    updated_at           timestamptz,
    deleted_at           timestamptz,
    status               entity_status NOT NULL DEFAULT 'active',

    document_id          INT NOT NULL REFERENCES ccd_documents (id) ON DELETE CASCADE,
    codes_districts_id   INT NOT NULL REFERENCES codes_districts (id),

    -- Customizable fields
    custom_name          TEXT,
    notes                TEXT
);

CREATE INDEX IF NOT EXISTS idx_ccd_document_districts_document ON ccd_document_districts (document_id);
CREATE INDEX IF NOT EXISTS idx_ccd_document_districts_code ON ccd_document_districts (codes_districts_id);

COMMENT ON TABLE ccd_document_districts IS 'Связь CCD документа с районами/городами (Графа 30 - местонахождение товаров)';

-- ============================================================================

-- Graph 37: Movement types
CREATE TABLE IF NOT EXISTS ccd_document_movement_types
(
    id                        INT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    created_at                timestamptz NOT NULL DEFAULT NOW(),
    updated_at                timestamptz,
    deleted_at                timestamptz,
    status                    entity_status NOT NULL DEFAULT 'active',

    document_id               INT NOT NULL REFERENCES ccd_documents (id) ON DELETE CASCADE,
    codes_movement_types_id   INT NOT NULL REFERENCES codes_movement_types (id),

    -- Customizable fields
    custom_name               TEXT,
    notes                     TEXT
);

CREATE INDEX IF NOT EXISTS idx_ccd_document_movement_types_document ON ccd_document_movement_types (document_id);
CREATE INDEX IF NOT EXISTS idx_ccd_document_movement_types_code ON ccd_document_movement_types (codes_movement_types_id);

COMMENT ON TABLE ccd_document_movement_types IS 'Связь CCD документа с особенностями перемещения (Графа 37)';

-- ============================================================================

-- Graph 28: Banks
CREATE TABLE IF NOT EXISTS ccd_document_banks
(
    id                INT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    created_at        timestamptz NOT NULL DEFAULT NOW(),
    updated_at        timestamptz,
    deleted_at        timestamptz,
    status            entity_status NOT NULL DEFAULT 'active',

    document_id       INT NOT NULL REFERENCES ccd_documents (id) ON DELETE CASCADE,
    banks_id          INT NOT NULL REFERENCES banks (id),

    -- Customizable fields
    custom_name       VARCHAR(255),
    custom_mfo        VARCHAR(255),
    custom_address    VARCHAR(255),
    account_number    TEXT,
    notes             TEXT
);

CREATE INDEX IF NOT EXISTS idx_ccd_document_banks_document ON ccd_document_banks (document_id);
CREATE INDEX IF NOT EXISTS idx_ccd_document_banks_code ON ccd_document_banks (banks_id);

COMMENT ON TABLE ccd_document_banks IS 'Связь CCD документа с банками (Графа 28 - банк плательщика)';
COMMENT ON COLUMN ccd_document_banks.account_number IS 'Номер счета плательщика';

-- ============================================================================
-- FEA ENTITY TABLES JOINS
-- ============================================================================

-- Graphs 2, 8, 9, 14, 18, 28: Legal entities
CREATE TABLE IF NOT EXISTS ccd_document_legal_entities
(
    id                      INT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    created_at              timestamptz NOT NULL DEFAULT NOW(),
    updated_at              timestamptz,
    deleted_at              timestamptz,
    status                  entity_status NOT NULL DEFAULT 'active',

    document_id             INT NOT NULL REFERENCES ccd_documents (id) ON DELETE CASCADE,
    fea_legal_entities_id   INT NOT NULL REFERENCES fea_legal_entities (id),
    entity_role             document_entity_role NOT NULL,

    -- Customizable fields
    custom_inn              VARCHAR(255),
    custom_name             VARCHAR(255),
    custom_address          VARCHAR(255),
    custom_phone_number     VARCHAR(255),
    custom_okpo             VARCHAR(255),
    custom_oked             INT,
    notes                   TEXT
);

CREATE INDEX IF NOT EXISTS idx_ccd_document_legal_entities_document ON ccd_document_legal_entities (document_id);
CREATE INDEX IF NOT EXISTS idx_ccd_document_legal_entities_entity ON ccd_document_legal_entities (fea_legal_entities_id);
CREATE INDEX IF NOT EXISTS idx_ccd_document_legal_entities_role ON ccd_document_legal_entities (entity_role);

COMMENT ON TABLE ccd_document_legal_entities IS 'Связь CCD документа с юридическими лицами (Графы 2, 8, 9, 14, 18, 28)';
COMMENT ON COLUMN ccd_document_legal_entities.entity_role IS 'Роль: exporter (Г.2), consignee (Г.8), declarant (Г.14), financial (Г.9), payer (Г.28), carrier (Г.18)';

-- ============================================================================

-- Graphs 2, 8, 9, 14, 18, 28: Individual entities
CREATE TABLE IF NOT EXISTS ccd_document_individual_entities
(
    id                          INT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    created_at                  timestamptz NOT NULL DEFAULT NOW(),
    updated_at                  timestamptz,
    deleted_at                  timestamptz,
    status                      entity_status NOT NULL DEFAULT 'active',

    document_id                 INT NOT NULL REFERENCES ccd_documents (id) ON DELETE CASCADE,
    fea_individual_entities_id  INT NOT NULL REFERENCES fea_individual_entities (id),
    entity_role                 document_entity_role NOT NULL,

    -- Customizable fields
    custom_pinfl                VARCHAR(255),
    custom_full_name            TEXT,
    custom_address              TEXT,
    custom_phone                VARCHAR(255),
    custom_passport_number      VARCHAR(255),
    notes                       TEXT
);

CREATE INDEX IF NOT EXISTS idx_ccd_document_individual_entities_document ON ccd_document_individual_entities (document_id);
CREATE INDEX IF NOT EXISTS idx_ccd_document_individual_entities_entity ON ccd_document_individual_entities (fea_individual_entities_id);
CREATE INDEX IF NOT EXISTS idx_ccd_document_individual_entities_role ON ccd_document_individual_entities (entity_role);

COMMENT ON TABLE ccd_document_individual_entities IS 'Связь CCD документа с физическими лицами (Графы 2, 8, 9, 14, 18, 28)';
COMMENT ON COLUMN ccd_document_individual_entities.entity_role IS 'Роль: exporter (Г.2), consignee (Г.8), declarant (Г.14), financial (Г.9), payer (Г.28), carrier (Г.18)';

-- ============================================================================

-- Graphs 2, 8, 9, 14: Legal entities short
CREATE TABLE IF NOT EXISTS ccd_document_legal_entities_short
(
    id                              INT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    created_at                      timestamptz NOT NULL DEFAULT NOW(),
    updated_at                      timestamptz,
    deleted_at                      timestamptz,
    status                          entity_status NOT NULL DEFAULT 'active',

    document_id                     INT NOT NULL REFERENCES ccd_documents (id) ON DELETE CASCADE,
    fea_legal_entities_short_id     INT NOT NULL REFERENCES fea_legal_entities_short (id),
    entity_role                     document_entity_role NOT NULL,

    -- Customizable fields
    custom_okpo                     VARCHAR(255),
    custom_inn                      VARCHAR(255),
    custom_name                     VARCHAR(255),
    custom_address                  VARCHAR(255),
    notes                           TEXT,

    CONSTRAINT ccd_document_legal_entities_short_role_ck CHECK (entity_role IN ('exporter', 'consignee', 'declarant', 'financial'))
);

CREATE INDEX IF NOT EXISTS idx_ccd_document_legal_entities_short_document ON ccd_document_legal_entities_short (document_id);
CREATE INDEX IF NOT EXISTS idx_ccd_document_legal_entities_short_entity ON ccd_document_legal_entities_short (fea_legal_entities_short_id);
CREATE INDEX IF NOT EXISTS idx_ccd_document_legal_entities_short_role ON ccd_document_legal_entities_short (entity_role);

COMMENT ON TABLE ccd_document_legal_entities_short IS 'Связь CCD документа с укороченными данными юр.лиц (Графы 2, 8, 9, 14)';
COMMENT ON COLUMN ccd_document_legal_entities_short.entity_role IS 'Роль: exporter (Г.2), consignee (Г.8), declarant (Г.14), financial (Г.9)';

-- ============================================================================

-- Graphs 2, 8, 9, 14: Partners additional
CREATE TABLE IF NOT EXISTS ccd_document_partners_additional
(
    id                          INT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    created_at                  timestamptz NOT NULL DEFAULT NOW(),
    updated_at                  timestamptz,
    deleted_at                  timestamptz,
    status                      entity_status NOT NULL DEFAULT 'active',

    document_id                 INT NOT NULL REFERENCES ccd_documents (id) ON DELETE CASCADE,
    fea_partners_additional_id  INT NOT NULL REFERENCES fea_partners_additional (id),
    entity_role                 document_entity_role NOT NULL,

    -- Customizable fields
    custom_name                 VARCHAR(255),
    custom_address              VARCHAR(255),
    custom_additional_info      TEXT,
    notes                       TEXT,

    CONSTRAINT ccd_document_partners_additional_role_ck CHECK (entity_role IN ('exporter', 'consignee', 'declarant', 'financial'))
);

CREATE INDEX IF NOT EXISTS idx_ccd_document_partners_additional_document ON ccd_document_partners_additional (document_id);
CREATE INDEX IF NOT EXISTS idx_ccd_document_partners_additional_entity ON ccd_document_partners_additional (fea_partners_additional_id);
CREATE INDEX IF NOT EXISTS idx_ccd_document_partners_additional_role ON ccd_document_partners_additional (entity_role);

COMMENT ON TABLE ccd_document_partners_additional IS 'Связь CCD документа с дополнительными сведениями по контрагентам (Графы 2, 8, 9, 14)';
COMMENT ON COLUMN ccd_document_partners_additional.entity_role IS 'Роль: exporter (Г.2), consignee (Г.8), declarant (Г.14), financial (Г.9)';

-- ============================================================================
-- CCD_ITEMS REFERENCE TABLES JOINS
-- ============================================================================

-- Graph 33: HS codes for items
CREATE TABLE IF NOT EXISTS ccd_item_hs_codes
(
    id              INT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    created_at      timestamptz NOT NULL DEFAULT NOW(),
    updated_at      timestamptz,
    deleted_at      timestamptz,
    status          entity_status NOT NULL DEFAULT 'active',

    item_id         INT NOT NULL REFERENCES ccd_items (id) ON DELETE CASCADE,
    codes_hs_id     INT NOT NULL REFERENCES codes_hs (id),

    -- Customizable fields
    custom_description TEXT,
    notes           TEXT
);

CREATE INDEX IF NOT EXISTS idx_ccd_item_hs_codes_item ON ccd_item_hs_codes (item_id);
CREATE INDEX IF NOT EXISTS idx_ccd_item_hs_codes_code ON ccd_item_hs_codes (codes_hs_id);

COMMENT ON TABLE ccd_item_hs_codes IS 'Связь товарной позиции с кодом ТН ВЭД (Графа 33)';

-- ============================================================================

-- Graph 34: Origin countries for items
CREATE TABLE IF NOT EXISTS ccd_item_origin_countries
(
    id                   INT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    created_at           timestamptz NOT NULL DEFAULT NOW(),
    updated_at           timestamptz,
    deleted_at           timestamptz,
    status               entity_status NOT NULL DEFAULT 'active',

    item_id              INT NOT NULL REFERENCES ccd_items (id) ON DELETE CASCADE,
    codes_countries_id   INT NOT NULL REFERENCES codes_countries (id),

    -- Customizable fields
    custom_name          VARCHAR(255),
    notes                TEXT
);

CREATE INDEX IF NOT EXISTS idx_ccd_item_origin_countries_item ON ccd_item_origin_countries (item_id);
CREATE INDEX IF NOT EXISTS idx_ccd_item_origin_countries_code ON ccd_item_origin_countries (codes_countries_id);

COMMENT ON TABLE ccd_item_origin_countries IS 'Связь товарной позиции со страной происхождения (Графа 34)';

-- ============================================================================

-- Graph 31, 41: Units for items
CREATE TABLE IF NOT EXISTS ccd_item_units
(
    id              INT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    created_at      timestamptz NOT NULL DEFAULT NOW(),
    updated_at      timestamptz,
    deleted_at      timestamptz,
    status          entity_status NOT NULL DEFAULT 'active',

    item_id         INT NOT NULL REFERENCES ccd_items (id) ON DELETE CASCADE,
    codes_units_id  INT NOT NULL REFERENCES codes_units (id),
    unit_type       VARCHAR(20) NOT NULL, -- 'additional' | 'quota'

    -- Customizable fields
    custom_name     VARCHAR(255),
    quantity        NUMERIC(18, 6),
    notes           TEXT,

    CONSTRAINT ccd_item_units_type_ck CHECK (unit_type IN ('additional', 'quota'))
);

CREATE INDEX IF NOT EXISTS idx_ccd_item_units_item ON ccd_item_units (item_id);
CREATE INDEX IF NOT EXISTS idx_ccd_item_units_code ON ccd_item_units (codes_units_id);
CREATE INDEX IF NOT EXISTS idx_ccd_item_units_type ON ccd_item_units (unit_type);

COMMENT ON TABLE ccd_item_units IS 'Связь товарной позиции с единицами измерения (Графы 31, 41)';
COMMENT ON COLUMN ccd_item_units.unit_type IS 'Тип единицы: additional (Г.41 доп. единица) | quota (Г.39 единица квоты)';

-- ============================================================================

-- Graph 31: Districts for items (producer/consumer)
CREATE TABLE IF NOT EXISTS ccd_item_districts
(
    id                   INT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    created_at           timestamptz NOT NULL DEFAULT NOW(),
    updated_at           timestamptz,
    deleted_at           timestamptz,
    status               entity_status NOT NULL DEFAULT 'active',

    item_id              INT NOT NULL REFERENCES ccd_items (id) ON DELETE CASCADE,
    codes_districts_id   INT NOT NULL REFERENCES codes_districts (id),
    district_role        VARCHAR(20) NOT NULL, -- 'producer' | 'consumer'

    -- Customizable fields
    custom_name          TEXT,
    notes                TEXT,

    CONSTRAINT ccd_item_districts_role_ck CHECK (district_role IN ('producer', 'consumer'))
);

CREATE INDEX IF NOT EXISTS idx_ccd_item_districts_item ON ccd_item_districts (item_id);
CREATE INDEX IF NOT EXISTS idx_ccd_item_districts_code ON ccd_item_districts (codes_districts_id);
CREATE INDEX IF NOT EXISTS idx_ccd_item_districts_role ON ccd_item_districts (district_role);

COMMENT ON TABLE ccd_item_districts IS 'Связь товарной позиции с районами (Графа 31 - производитель/потребитель)';
COMMENT ON COLUMN ccd_item_districts.district_role IS 'Роль района: producer (производитель) | consumer (потребитель)';

-- ============================================================================

-- Graph 18: Vehicle types
CREATE TABLE IF NOT EXISTS ccd_document_vehicle_types
(
    id                      INT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    created_at              timestamptz NOT NULL DEFAULT NOW(),
    updated_at              timestamptz,
    deleted_at              timestamptz,
    status                  entity_status NOT NULL DEFAULT 'active',

    document_id             INT NOT NULL REFERENCES ccd_documents (id) ON DELETE CASCADE,
    codes_vehicle_types_id  INT NOT NULL REFERENCES codes_vehicle_types (id),

    -- Customizable fields
    custom_name             VARCHAR(255),
    notes                   TEXT
);

CREATE INDEX IF NOT EXISTS idx_ccd_document_vehicle_types_doc ON ccd_document_vehicle_types (document_id);
CREATE INDEX IF NOT EXISTS idx_ccd_document_vehicle_types_code ON ccd_document_vehicle_types (codes_vehicle_types_id);

COMMENT ON TABLE ccd_document_vehicle_types IS 'Связь декларации с видом транспортного средства (Графа 18)';

-- ============================================================================

-- Graph 20: Shipment forms
CREATE TABLE IF NOT EXISTS ccd_document_shipment_forms
(
    id                        INT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    created_at                timestamptz NOT NULL DEFAULT NOW(),
    updated_at                timestamptz,
    deleted_at                timestamptz,
    status                    entity_status NOT NULL DEFAULT 'active',

    document_id               INT NOT NULL REFERENCES ccd_documents (id) ON DELETE CASCADE,
    codes_shipment_forms_id   INT NOT NULL REFERENCES codes_shipment_forms (id),

    -- Customizable fields
    custom_name               VARCHAR(255),
    notes                     TEXT
);

CREATE INDEX IF NOT EXISTS idx_ccd_document_shipment_forms_doc ON ccd_document_shipment_forms (document_id);
CREATE INDEX IF NOT EXISTS idx_ccd_document_shipment_forms_code ON ccd_document_shipment_forms (codes_shipment_forms_id);

COMMENT ON TABLE ccd_document_shipment_forms IS 'Связь декларации с формой отгрузки (Графа 20)';
