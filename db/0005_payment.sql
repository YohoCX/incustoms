CREATE TABLE IF NOT EXISTS price_plans
(
    id                INT                      NOT NULL PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    created_at        TIMESTAMP WITH TIME ZONE NOT NULL,
    updated_at        TIMESTAMP WITH TIME ZONE,
    deleted_at        TIMESTAMP WITH TIME ZONE,
    status            VARCHAR(255),                      -- active | deleted | archived

    type              VARCHAR                  NOT NULL, -- individual, enterprise-per-user, enterprise
    tokens            BIGINT                   NOT NULL,
    price             INT                      NOT NULL,
    codes_currency_id INT REFERENCES codes_currencies (id)
);

-- Comments: price_plans
COMMENT ON TABLE price_plans IS 'Тарифные планы/квоты (токены, стоимость). Используются для биллинга сервиса; не относятся напрямую к графам ГТД';
COMMENT ON COLUMN price_plans.id IS 'Первичный ключ';
COMMENT ON COLUMN price_plans.created_at IS 'Дата/время создания записи';
COMMENT ON COLUMN price_plans.updated_at IS 'Дата/время изменения записи';
COMMENT ON COLUMN price_plans.deleted_at IS 'Дата/время удаления (soft delete)';
COMMENT ON COLUMN price_plans.status IS 'Статус записи: active | deleted | archived';
COMMENT ON COLUMN price_plans.type IS 'Тип тарифа: individual | enterprise-per-user | enterprise';
COMMENT ON COLUMN price_plans.tokens IS 'Лимит токенов/квота использования';
COMMENT ON COLUMN price_plans.price IS 'Цена в минорных единицах указанной валюты';
COMMENT ON COLUMN price_plans.codes_currency_id IS 'FK на codes_currencies (валюта тарифа)';

CREATE TABLE IF NOT EXISTS payment_providers
(
    id           INT                      NOT NULL PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    created_at   TIMESTAMP WITH TIME ZONE NOT NULL,
    updated_at   TIMESTAMP WITH TIME ZONE,
    deleted_at   TIMESTAMP WITH TIME ZONE,
    status       VARCHAR(255), -- active | deleted | archived
    code         VARCHAR UNIQUE           NOT NULL,
    display_name TEXT                     NOT NULL
);

-- Comments: payment_providers
COMMENT ON TABLE payment_providers IS 'Платежные провайдеры (Payme, Click и т.п.). Используются в платежных сессиях';
COMMENT ON COLUMN payment_providers.id IS 'Первичный ключ';
COMMENT ON COLUMN payment_providers.created_at IS 'Дата/время создания записи';
COMMENT ON COLUMN payment_providers.updated_at IS 'Дата/время изменения записи';
COMMENT ON COLUMN payment_providers.deleted_at IS 'Дата/время удаления (soft delete)';
COMMENT ON COLUMN payment_providers.status IS 'Статус записи: active | deleted | archived';
COMMENT ON COLUMN payment_providers.code IS 'Системный код провайдера (уникальный)';
COMMENT ON COLUMN payment_providers.display_name IS 'Отображаемое имя провайдера';

CREATE TABLE IF NOT EXISTS payment_invoices
(
    id              INT                      NOT NULL PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    created_at      TIMESTAMP WITH TIME ZONE NOT NULL,
    updated_at      TIMESTAMP WITH TIME ZONE,
    deleted_at      TIMESTAMP WITH TIME ZONE,
    status          VARCHAR(255),                      -- active | deleted | archived

    organization_id INT REFERENCES organizations (id),
    user_id         INT REFERENCES users (id),         -- плательщик-физлицо
    title           TEXT,
    description     TEXT,
    amount_total    BIGINT                   NOT NULL, -- минорные единицы
    currency        TEXT                     NOT NULL, -- держим в коде: 'UZS','USD','EUR',...
    due_at          timestamptz,
    meta            jsonb                    NOT NULL DEFAULT '{}'
);

-- Comments: payment_invoices
COMMENT ON TABLE payment_invoices IS 'Счета на оплату (организация или пользователь). Используются для оплаты тарифов/услуг (например, подача CCD). Не являются графами ГТД';
COMMENT ON COLUMN payment_invoices.id IS 'Первичный ключ';
COMMENT ON COLUMN payment_invoices.created_at IS 'Дата/время создания записи';
COMMENT ON COLUMN payment_invoices.updated_at IS 'Дата/время изменения записи';
COMMENT ON COLUMN payment_invoices.deleted_at IS 'Дата/время удаления (soft delete)';
COMMENT ON COLUMN payment_invoices.status IS 'Статус записи: active | deleted | archived';
COMMENT ON COLUMN payment_invoices.organization_id IS 'FK на organizations (счет на юр.лицо)';
COMMENT ON COLUMN payment_invoices.user_id IS 'FK на users (счет на физ.лицо)';
COMMENT ON COLUMN payment_invoices.title IS 'Заголовок счета';
COMMENT ON COLUMN payment_invoices.description IS 'Описание счета';
COMMENT ON COLUMN payment_invoices.amount_total IS 'Итоговая сумма в минорных единицах';
COMMENT ON COLUMN payment_invoices.currency IS 'Буквенный код валюты (например, UZS, USD)';
COMMENT ON COLUMN payment_invoices.due_at IS 'Срок оплаты';
COMMENT ON COLUMN payment_invoices.meta IS 'Служебные поля/JSON (может содержать ссылку на CCD)';

ALTER TABLE payment_invoices
    ADD CONSTRAINT invoices_actor_ck
        CHECK (user_id IS NOT NULL OR organization_id IS NOT NULL);

CREATE TABLE IF NOT EXISTS payment_invoice_items
(
    id         INT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    invoice_id INT            NOT NULL REFERENCES payment_invoices (id),
    name       TEXT           NOT NULL,
    quantity   NUMERIC(18, 4) NOT NULL DEFAULT 1,
    unit_price BIGINT         NOT NULL,
    meta       jsonb          NOT NULL DEFAULT '{}'
);

-- Comments: payment_invoice_items
COMMENT ON TABLE payment_invoice_items IS 'Позиции счета';
COMMENT ON COLUMN payment_invoice_items.id IS 'Первичный ключ';
COMMENT ON COLUMN payment_invoice_items.invoice_id IS 'FK на payment_invoices';
COMMENT ON COLUMN payment_invoice_items.name IS 'Наименование позиции';
COMMENT ON COLUMN payment_invoice_items.quantity IS 'Количество';
COMMENT ON COLUMN payment_invoice_items.unit_price IS 'Цена за единицу в минорных единицах';
COMMENT ON COLUMN payment_invoice_items.meta IS 'Служебные поля (JSON)';

CREATE TABLE IF NOT EXISTS payment_sessions
(
    id               INT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    provider_id      INT         NOT NULL REFERENCES payment_providers (id),
    invoice_id       INT REFERENCES payment_invoices (id),
    user_id          INT REFERENCES users (id),
    organization_id  INT REFERENCES organizations (id),
    amount           BIGINT      NOT NULL,
    currency         TEXT        NOT NULL,
    client_reference TEXT,                                   -- ваш orderId
    return_url       TEXT,
    status           TEXT        NOT NULL DEFAULT 'created', -- 'created','processing','succeeded','failed','canceled'
    meta             jsonb       NOT NULL DEFAULT '{}',
    created_at       timestamptz NOT NULL DEFAULT NOW(),
    updated_at       timestamptz
);

-- Comments: payment_sessions
COMMENT ON TABLE payment_sessions IS 'Платежные сессии с провайдером (редирект/SDK). Используются для оплаты счетов';
COMMENT ON COLUMN payment_sessions.id IS 'Первичный ключ';
COMMENT ON COLUMN payment_sessions.provider_id IS 'FK на payment_providers';
COMMENT ON COLUMN payment_sessions.invoice_id IS 'FK на payment_invoices (может быть NULL при предсоздании)';
COMMENT ON COLUMN payment_sessions.user_id IS 'FK на users (инициатор платежа-физлицо)';
COMMENT ON COLUMN payment_sessions.organization_id IS 'FK на organizations (инициатор-предприятие)';
COMMENT ON COLUMN payment_sessions.amount IS 'Сумма в минорных единицах';
COMMENT ON COLUMN payment_sessions.currency IS 'Код валюты';
COMMENT ON COLUMN payment_sessions.client_reference IS 'Внешний client/order ID';
COMMENT ON COLUMN payment_sessions.return_url IS 'URL возврата после оплаты';
COMMENT ON COLUMN payment_sessions.status IS 'Статус: created | processing | succeeded | failed | canceled';
COMMENT ON COLUMN payment_sessions.meta IS 'Служебные поля провайдера/клиента (JSON)';
COMMENT ON COLUMN payment_sessions.created_at IS 'Дата/время создания';
COMMENT ON COLUMN payment_sessions.updated_at IS 'Дата/время обновления';

ALTER TABLE payment_sessions
    ADD CONSTRAINT payment_sessions_actor_ck
        CHECK (user_id IS NOT NULL OR organization_id IS NOT NULL);

CREATE TABLE IF NOT EXISTS payment_transactions
(
    id              INT                      NOT NULL PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    created_at      TIMESTAMP WITH TIME ZONE NOT NULL,
    updated_at      TIMESTAMP WITH TIME ZONE,
    deleted_at      TIMESTAMP WITH TIME ZONE,
    status          VARCHAR(255),                                  -- active | deleted | archived

    price_plan_id   INT REFERENCES price_plans (id),               -- если это оплата тарифа
    organization_id INT REFERENCES organizations (id),
    user_id         INT REFERENCES users (id),

    provider_id     INT REFERENCES payment_providers (id),
    session_id      INT REFERENCES payment_sessions (id),
    invoice_id      INT REFERENCES payment_invoices (id),

    amount          BIGINT                   NOT NULL,             -- минорные
    currency        TEXT                     NOT NULL,
    external_id     TEXT,                                          -- id у провайдера
    method          TEXT,                                          -- 'PAYME','CLICK','OTHER'
    meta            jsonb                    NOT NULL DEFAULT '{}' -- тех.поля/пэйлоад (без ПД)
);

-- Comments: payment_transactions
COMMENT ON TABLE payment_transactions IS 'Факт транзакций оплаты (успешных/неуспешных). Используются для начисления токенов/разрешений на подачу CCD';
COMMENT ON COLUMN payment_transactions.id IS 'Первичный ключ';
COMMENT ON COLUMN payment_transactions.created_at IS 'Дата/время создания записи';
COMMENT ON COLUMN payment_transactions.updated_at IS 'Дата/время изменения записи';
COMMENT ON COLUMN payment_transactions.deleted_at IS 'Дата/время удаления (soft delete)';
COMMENT ON COLUMN payment_transactions.status IS 'Статус записи: active | deleted | archived';
COMMENT ON COLUMN payment_transactions.price_plan_id IS 'FK на price_plans (если транзакция по тарифу)';
COMMENT ON COLUMN payment_transactions.organization_id IS 'FK на organizations';
COMMENT ON COLUMN payment_transactions.user_id IS 'FK на users';
COMMENT ON COLUMN payment_transactions.provider_id IS 'FK на payment_providers';
COMMENT ON COLUMN payment_transactions.session_id IS 'FK на payment_sessions';
COMMENT ON COLUMN payment_transactions.invoice_id IS 'FK на payment_invoices';
COMMENT ON COLUMN payment_transactions.amount IS 'Сумма в минорных единицах';
COMMENT ON COLUMN payment_transactions.currency IS 'Код валюты';
COMMENT ON COLUMN payment_transactions.external_id IS 'Идентификатор транзакции у провайдера';
COMMENT ON COLUMN payment_transactions.method IS 'Метод оплаты (PAYME|CLICK|OTHER)';
COMMENT ON COLUMN payment_transactions.meta IS 'Служебные поля/сырые payload (без ПД)';

ALTER TABLE payment_transactions
    ADD CONSTRAINT transactions_actor_ck
        CHECK (user_id IS NOT NULL OR organization_id IS NOT NULL);


CREATE TABLE IF NOT EXISTS refunds
(
    id                 INT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    transaction_id     INT         NOT NULL REFERENCES payment_transactions (id) ON DELETE RESTRICT,
    provider_id        INT         NOT NULL REFERENCES payment_providers (id),
    amount             BIGINT      NOT NULL,
    status             TEXT        NOT NULL DEFAULT 'pending', -- 'pending','succeeded','failed','canceled'
    provider_refund_id TEXT,
    meta               jsonb       NOT NULL DEFAULT '{}',
    created_at         timestamptz NOT NULL DEFAULT NOW()
);

-- Comments: refunds
COMMENT ON TABLE refunds IS 'Возвраты по платежам';
COMMENT ON COLUMN refunds.id IS 'Первичный ключ';
COMMENT ON COLUMN refunds.transaction_id IS 'FK на payment_transactions';
COMMENT ON COLUMN refunds.provider_id IS 'FK на payment_providers';
COMMENT ON COLUMN refunds.amount IS 'Сумма возврата (минорные единицы)';
COMMENT ON COLUMN refunds.status IS 'Статус: pending | succeeded | failed | canceled';
COMMENT ON COLUMN refunds.provider_refund_id IS 'ID возврата у провайдера';
COMMENT ON COLUMN refunds.meta IS 'Служебные поля (JSON)';
COMMENT ON COLUMN refunds.created_at IS 'Дата/время создания записи';

CREATE TABLE IF NOT EXISTS webhook_events
(
    id           BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    provider_id  INT REFERENCES payment_providers (id),
    event_type   TEXT        NOT NULL,
    signature_ok BOOLEAN     NOT NULL DEFAULT FALSE,
    payload      jsonb       NOT NULL, -- сырой JSON провайдера
    received_at  timestamptz NOT NULL DEFAULT NOW(),
    processed_at timestamptz
);

-- Comments: webhook_events
COMMENT ON TABLE webhook_events IS 'События вебхуков от провайдеров (сырые payloads)';
COMMENT ON COLUMN webhook_events.id IS 'Первичный ключ';
COMMENT ON COLUMN webhook_events.provider_id IS 'FK на payment_providers';
COMMENT ON COLUMN webhook_events.event_type IS 'Тип события';
COMMENT ON COLUMN webhook_events.signature_ok IS 'Проверка подписи вебхука пройдена';
COMMENT ON COLUMN webhook_events.payload IS 'Сырой JSON от провайдера';
COMMENT ON COLUMN webhook_events.received_at IS 'Время получения';
COMMENT ON COLUMN webhook_events.processed_at IS 'Время обработки';

CREATE TABLE IF NOT EXISTS idempotency_keys
(
    key           TEXT PRIMARY KEY,
    created_at    timestamptz NOT NULL DEFAULT NOW(),
    response_hash TEXT
);

-- Comments: idempotency_keys
COMMENT ON TABLE idempotency_keys IS 'Ключи идемпотентности для безопасного повторения платежных запросов';
COMMENT ON COLUMN idempotency_keys.key IS 'Уникальный ключ идемпотентности';
COMMENT ON COLUMN idempotency_keys.created_at IS 'Когда создан ключ';
COMMENT ON COLUMN idempotency_keys.response_hash IS 'Хеш ответа для сравнения';
