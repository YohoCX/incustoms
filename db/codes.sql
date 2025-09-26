-- Графа 1
CREATE TABLE IF NOT EXISTS codes_forms
(
    id         INT                      NOT NULL PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE,
    deleted_at TIMESTAMP WITH TIME ZONE,
    status     VARCHAR(255), -- active | deleted | archived
    code       VARCHAR UNIQUE           NOT NULL,

    name       TEXT                     NOT NULL,
    npa        TEXT                     NOT NULL,
    npa_url    TEXT                     NOT NULL
);
-- Comments for codes_forms
COMMENT ON TABLE codes_forms IS 'Справочник форм/типов декларации (Графа 1)';
COMMENT ON COLUMN codes_forms.id IS 'Первичный ключ';
COMMENT ON COLUMN codes_forms.created_at IS 'Дата/время создания записи';
COMMENT ON COLUMN codes_forms.updated_at IS 'Дата/время изменения записи';
COMMENT ON COLUMN codes_forms.deleted_at IS 'Дата/время удаления (мягкое удаление)';
COMMENT ON COLUMN codes_forms.status IS 'Статус записи: active | deleted | archived';
COMMENT ON COLUMN codes_forms.code IS 'Код формы (уникальный)';
COMMENT ON COLUMN codes_forms.name IS 'Наименование формы';
COMMENT ON COLUMN codes_forms.npa IS 'Нормативно-правовой акт (реквизиты)';
COMMENT ON COLUMN codes_forms.npa_url IS 'Ссылка на НПА (URL)';

-- Графа 7, 9, 29
CREATE TABLE IF NOT EXISTS codes_posts
(
    id           INT                      NOT NULL PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    created_at   TIMESTAMP WITH TIME ZONE NOT NULL,
    updated_at   TIMESTAMP WITH TIME ZONE,
    deleted_at   TIMESTAMP WITH TIME ZONE,
    status       VARCHAR(255), -- active | deleted | archived
    code         VARCHAR UNIQUE           NOT NULL,

    name         TEXT,
    phone_number VARCHAR(255),
    location_url TEXT
);
-- Comments for codes_posts
COMMENT ON TABLE codes_posts IS 'Справочник таможенных постов (Графы 7 и 29)';
COMMENT ON COLUMN codes_posts.id IS 'Первичный ключ';
COMMENT ON COLUMN codes_posts.created_at IS 'Дата/время создания записи';
COMMENT ON COLUMN codes_posts.updated_at IS 'Дата/время изменения записи';
COMMENT ON COLUMN codes_posts.deleted_at IS 'Дата/время удаления (мягкое удаление)';
COMMENT ON COLUMN codes_posts.status IS 'Статус записи: active | deleted | archived';
COMMENT ON COLUMN codes_posts.code IS 'Код поста (обычно 5 цифр), уникальный';
COMMENT ON COLUMN codes_posts.name IS 'Наименование таможенного поста';
COMMENT ON COLUMN codes_posts.phone_number IS 'Контактный телефон поста';
COMMENT ON COLUMN codes_posts.location_url IS 'Ссылка на местоположение (карта/координаты)';

-- Графа 2, 11, 15, 15a, 34
CREATE TABLE IF NOT EXISTS codes_countries
(
    id         INT                      NOT NULL PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE,
    deleted_at TIMESTAMP WITH TIME ZONE,
    status     VARCHAR(255), -- active | deleted | archived
    code       VARCHAR UNIQUE           NOT NULL,
    alpha_code VARCHAR UNIQUE           NOT NULL,

    name       VARCHAR(255)             NOT NULL,
    offshore   VARCHAR(255)             NOT NULL
);
-- Comments for codes_countries
COMMENT ON TABLE codes_countries IS 'Справочник стран (Графы 2, 11, 15, 15a, 34)';
COMMENT ON COLUMN codes_countries.id IS 'Первичный ключ';
COMMENT ON COLUMN codes_countries.created_at IS 'Дата/время создания записи';
COMMENT ON COLUMN codes_countries.updated_at IS 'Дата/время изменения записи';
COMMENT ON COLUMN codes_countries.deleted_at IS 'Дата/время удаления (мягкое удаление)';
COMMENT ON COLUMN codes_countries.status IS 'Статус записи: active | deleted | archived';
COMMENT ON COLUMN codes_countries.code IS 'Цифровой код страны (обычно 3 цифры), уникальный';
COMMENT ON COLUMN codes_countries.alpha_code IS 'Двухбуквенный alpha-2 код страны (ISO 3166-1), уникальный';
COMMENT ON COLUMN codes_countries.name IS 'Наименование страны';
COMMENT ON COLUMN codes_countries.offshore IS 'Признак офшорной юрисдикции (если ведется список)';

-- Графа 8, 30, 31
CREATE TABLE IF NOT EXISTS codes_districts
(
    id         INT                      NOT NULL PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE,
    deleted_at TIMESTAMP WITH TIME ZONE,
    status     VARCHAR(255), -- active | deleted | archived
    code       VARCHAR UNIQUE           NOT NULL,

    name       TEXT                     NOT NULL
);
-- Comments for codes_districts
COMMENT ON TABLE codes_districts IS 'Справочник регионов/районов/городов (Графы 8, 30, 31)';
COMMENT ON COLUMN codes_districts.id IS 'Первичный ключ';
COMMENT ON COLUMN codes_districts.created_at IS 'Дата/время создания записи';
COMMENT ON COLUMN codes_districts.updated_at IS 'Дата/время изменения записи';
COMMENT ON COLUMN codes_districts.deleted_at IS 'Дата/время удаления (мягкое удаление)';
COMMENT ON COLUMN codes_districts.status IS 'Статус записи: active | deleted | archived';
COMMENT ON COLUMN codes_districts.code IS 'Код района/города (обычно 7 цифр), уникальный';
COMMENT ON COLUMN codes_districts.name IS 'Наименование района/города';

-- Графа 13, 24
CREATE TABLE IF NOT EXISTS codes_currencies
(
    id         INT                      NOT NULL PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE,
    deleted_at TIMESTAMP WITH TIME ZONE,
    status     VARCHAR(255), -- active | deleted | archived
    code       VARCHAR UNIQUE           NOT NULL,
    alpha_code VARCHAR UNIQUE           NOT NULL,

    name       VARCHAR(255)             NOT NULL
);
-- Comments for codes_currencies
COMMENT ON TABLE codes_currencies IS 'Справочник валют (Графы 13 и 24)';
COMMENT ON COLUMN codes_currencies.id IS 'Первичный ключ';
COMMENT ON COLUMN codes_currencies.created_at IS 'Дата/время создания записи';
COMMENT ON COLUMN codes_currencies.updated_at IS 'Дата/время изменения записи';
COMMENT ON COLUMN codes_currencies.deleted_at IS 'Дата/время удаления (мягкое удаление)';
COMMENT ON COLUMN codes_currencies.status IS 'Статус записи: active | deleted | archived';
COMMENT ON COLUMN codes_currencies.code IS 'Цифровой код валюты (обычно 3 цифры), уникальный';
COMMENT ON COLUMN codes_currencies.alpha_code IS 'Буквенный alpha-3 код валюты (ISO 4217), уникальный';
COMMENT ON COLUMN codes_currencies.name IS 'Наименование валюты';

--Графа 20
CREATE TABLE IF NOT EXISTS codes_delivery_terms
(
    id         INT                      NOT NULL PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE,
    deleted_at TIMESTAMP WITH TIME ZONE,
    status     VARCHAR(255), -- active | deleted | archived
    code       VARCHAR UNIQUE           NOT NULL,

    alpha_code VARCHAR                  NOT NULL,
    name       VARCHAR                  NOT NULL
);
-- Comments for codes_delivery_terms
COMMENT ON TABLE codes_delivery_terms IS 'Базисы поставки Incoterms/условия поставки (Графа 20)';
COMMENT ON COLUMN codes_delivery_terms.id IS 'Первичный ключ';
COMMENT ON COLUMN codes_delivery_terms.created_at IS 'Дата/время создания записи';
COMMENT ON COLUMN codes_delivery_terms.updated_at IS 'Дата/время изменения записи';
COMMENT ON COLUMN codes_delivery_terms.deleted_at IS 'Дата/время удаления (мягкое удаление)';
COMMENT ON COLUMN codes_delivery_terms.status IS 'Статус записи: active | deleted | archived';
COMMENT ON COLUMN codes_delivery_terms.code IS 'Цифровой код по приложению (уникальный)';
COMMENT ON COLUMN codes_delivery_terms.alpha_code IS 'Буквенный код Incoterms (например, EXW, FOB)';
COMMENT ON COLUMN codes_delivery_terms.name IS 'Наименование условия поставки';

--Графа 20
CREATE TABLE IF NOT EXISTS codes_payment_forms
(
    id         INT                      NOT NULL PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE,
    deleted_at TIMESTAMP WITH TIME ZONE,
    status     VARCHAR(255), -- active | deleted | archived
    code       VARCHAR UNIQUE           NOT NULL,

    name       VARCHAR                  NOT NULL
);
-- Comments for codes_payment_forms
COMMENT ON TABLE codes_payment_forms IS 'Коды формы оплаты (Графа 20)';
COMMENT ON COLUMN codes_payment_forms.id IS 'Первичный ключ';
COMMENT ON COLUMN codes_payment_forms.created_at IS 'Дата/время создания записи';
COMMENT ON COLUMN codes_payment_forms.updated_at IS 'Дата/время изменения записи';
COMMENT ON COLUMN codes_payment_forms.deleted_at IS 'Дата/время удаления (мягкое удаление)';
COMMENT ON COLUMN codes_payment_forms.status IS 'Статус записи: active | deleted | archived';
COMMENT ON COLUMN codes_payment_forms.code IS 'Код формы оплаты (уникальный)';
COMMENT ON COLUMN codes_payment_forms.name IS 'Наименование формы оплаты';

-- Графа 24
CREATE TABLE IF NOT EXISTS codes_deal_types
(
    id         INT                      NOT NULL PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE,
    deleted_at TIMESTAMP WITH TIME ZONE,
    status     VARCHAR(255), -- active | deleted | archived
    code       VARCHAR UNIQUE           NOT NULL,

    alpha_code VARCHAR                  NOT NULL,
    name       VARCHAR                  NOT NULL
);
-- Comments for codes_deal_types
COMMENT ON TABLE codes_deal_types IS 'Характер сделки (Графа 24)';
COMMENT ON COLUMN codes_deal_types.id IS 'Первичный ключ';
COMMENT ON COLUMN codes_deal_types.created_at IS 'Дата/время создания записи';
COMMENT ON COLUMN codes_deal_types.updated_at IS 'Дата/время изменения записи';
COMMENT ON COLUMN codes_deal_types.deleted_at IS 'Дата/время удаления (мягкое удаление)';
COMMENT ON COLUMN codes_deal_types.status IS 'Статус записи: active | deleted | archived';
COMMENT ON COLUMN codes_deal_types.code IS 'Цифровой код характера сделки (уникальный)';
COMMENT ON COLUMN codes_deal_types.alpha_code IS 'Альтернативный/буквенный код';
COMMENT ON COLUMN codes_deal_types.name IS 'Наименование характера сделки';

-- Графа 25
CREATE TABLE IF NOT EXISTS codes_transport_types
(
    id         INT                      NOT NULL PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE,
    deleted_at TIMESTAMP WITH TIME ZONE,
    status     VARCHAR(255), -- active | deleted | archived
    code       VARCHAR UNIQUE           NOT NULL,

    name       VARCHAR                  NOT NULL,
    short_name VARCHAR                  NOT NULL
);
-- Comments for codes_transport_types
COMMENT ON TABLE codes_transport_types IS 'Виды транспорта (Графы 25/26 и для 18/21)';
COMMENT ON COLUMN codes_transport_types.id IS 'Первичный ключ';
COMMENT ON COLUMN codes_transport_types.created_at IS 'Дата/время создания записи';
COMMENT ON COLUMN codes_transport_types.updated_at IS 'Дата/время изменения записи';
COMMENT ON COLUMN codes_transport_types.deleted_at IS 'Дата/время удаления (мягкое удаление)';
COMMENT ON COLUMN codes_transport_types.status IS 'Статус записи: active | deleted | archived';
COMMENT ON COLUMN codes_transport_types.code IS 'Код вида транспорта (уникальный)';
COMMENT ON COLUMN codes_transport_types.name IS 'Наименование вида транспорта';
COMMENT ON COLUMN codes_transport_types.short_name IS 'Краткое обозначение (аббревиатура)';

-- Графа 33
CREATE TABLE IF NOT EXISTS codes_hs
(
    id          INT                      NOT NULL PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    created_at  TIMESTAMP WITH TIME ZONE NOT NULL,
    updated_at  TIMESTAMP WITH TIME ZONE,
    deleted_at  TIMESTAMP WITH TIME ZONE,
    status      VARCHAR(255), -- active | deleted | archived
    code        VARCHAR UNIQUE           NOT NULL,

    description TEXT                     NOT NULL
);
-- Comments for codes_hs
COMMENT ON TABLE codes_hs IS 'ТН ВЭД (Графа 33): коды товаров';
COMMENT ON COLUMN codes_hs.id IS 'Первичный ключ';
COMMENT ON COLUMN codes_hs.created_at IS 'Дата/время создания записи';
COMMENT ON COLUMN codes_hs.updated_at IS 'Дата/время изменения записи';
COMMENT ON COLUMN codes_hs.deleted_at IS 'Дата/время удаления (мягкое удаление)';
COMMENT ON COLUMN codes_hs.status IS 'Статус записи: active | deleted | archived';
COMMENT ON COLUMN codes_hs.code IS 'Код ТН ВЭД (обычно 10 цифр), уникальный';
COMMENT ON COLUMN codes_hs.description IS 'Описание товарной позиции';

-- Графа 33, 31
CREATE TABLE IF NOT EXISTS codes_units
(
    id         INT                      NOT NULL PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE,
    deleted_at TIMESTAMP WITH TIME ZONE,
    status     VARCHAR(255), -- active | deleted | archived
    code       VARCHAR UNIQUE           NOT NULL,
    alpha_code VARCHAR                  NOT NULL,
    name       VARCHAR                  NOT NULL
);
-- Comments for codes_units
COMMENT ON TABLE codes_units IS 'Единицы измерения (Графа 33 и правый нижний блок графы 31)';
COMMENT ON COLUMN codes_units.id IS 'Первичный ключ';
COMMENT ON COLUMN codes_units.created_at IS 'Дата/время создания записи';
COMMENT ON COLUMN codes_units.updated_at IS 'Дата/время изменения записи';
COMMENT ON COLUMN codes_units.deleted_at IS 'Дата/время удаления (мягкое удаление)';
COMMENT ON COLUMN codes_units.status IS 'Статус записи: active | deleted | archived';
COMMENT ON COLUMN codes_units.code IS 'Цифровой код единицы измерения (уникальный)';
COMMENT ON COLUMN codes_units.alpha_code IS 'Буквенный код/сокращение единицы (например, L, M3)';
COMMENT ON COLUMN codes_units.name IS 'Наименование единицы измерения';

-- Графа 33
CREATE TABLE IF NOT EXISTS available_units_for_hs
(
    id             INT                      NOT NULL PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    created_at     TIMESTAMP WITH TIME ZONE NOT NULL,
    updated_at     TIMESTAMP WITH TIME ZONE,
    deleted_at     TIMESTAMP WITH TIME ZONE,
    status         VARCHAR(255), -- active | deleted | archived

    codes_hs_id    INT REFERENCES codes_hs (id),
    codes_units_id INT REFERENCES codes_units (id)
);
-- Comments for available_units_for_hs
COMMENT ON TABLE available_units_for_hs IS 'Допустимые единицы измерения для конкретных кодов ТН ВЭД (Графа 33), связь HS↔Unit';
COMMENT ON COLUMN available_units_for_hs.id IS 'Первичный ключ';
COMMENT ON COLUMN available_units_for_hs.created_at IS 'Дата/время создания записи';
COMMENT ON COLUMN available_units_for_hs.updated_at IS 'Дата/время изменения записи';
COMMENT ON COLUMN available_units_for_hs.deleted_at IS 'Дата/время удаления (мягкое удаление)';
COMMENT ON COLUMN available_units_for_hs.status IS 'Статус записи: active | deleted | archived';
COMMENT ON COLUMN available_units_for_hs.codes_hs_id IS 'FK на codes_hs (код ТН ВЭД)';
COMMENT ON COLUMN available_units_for_hs.codes_units_id IS 'FK на codes_units (единица измерения)';

-- Графа 37, 41
CREATE TABLE IF NOT EXISTS codes_movement_types
(
    id         INT                      NOT NULL PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE,
    deleted_at TIMESTAMP WITH TIME ZONE,
    status     VARCHAR(255), -- active | deleted | archived
    code       VARCHAR UNIQUE           NOT NULL,
    name       TEXT                     NOT NULL
);
-- Comments for codes_movement_types
COMMENT ON TABLE codes_movement_types IS 'Особенности перемещения/процедуры (Графы 37 и/или 41)';
COMMENT ON COLUMN codes_movement_types.id IS 'Первичный ключ';
COMMENT ON COLUMN codes_movement_types.created_at IS 'Дата/время создания записи';
COMMENT ON COLUMN codes_movement_types.updated_at IS 'Дата/время изменения записи';
COMMENT ON COLUMN codes_movement_types.deleted_at IS 'Дата/время удаления (мягкое удаление)';
COMMENT ON COLUMN codes_movement_types.status IS 'Статус записи: active | deleted | archived';
COMMENT ON COLUMN codes_movement_types.code IS 'Код особенности/процедуры (уникальный)';
COMMENT ON COLUMN codes_movement_types.name IS 'Наименование особенности/процедуры';

-- Графа 13
CREATE TABLE IF NOT EXISTS currency_exchange_rate
(
    id                INT                      NOT NULL PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    created_at        TIMESTAMP WITH TIME ZONE NOT NULL,
    updated_at        TIMESTAMP WITH TIME ZONE,
    deleted_at        TIMESTAMP WITH TIME ZONE,
    status            VARCHAR(255), -- active | deleted | archived

    codes_currency_id INT                      NOT NULL REFERENCES codes_currencies (id),
    rate              DECIMAL                  NOT NULL
);
