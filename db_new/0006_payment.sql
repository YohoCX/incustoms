-- ============================================================================
-- Payment System Schema
-- ============================================================================
-- This migration creates a comprehensive payment system with:
-- - Multiple payment providers (PayMe, Click, Didox, etc.)
-- - Tariff plans and subscriptions
-- - Usage tracking and limits
-- - OCR service tracking
-- - Transaction history and reconciliation
-- ============================================================================

-- ============================================================================
-- ENUMS
-- ============================================================================

CREATE TYPE payment_provider_type AS ENUM ('payme', 'click', 'didox');
CREATE TYPE client_type AS ENUM ('individual', 'legal');
CREATE TYPE payment_status AS ENUM ('pending', 'processing', 'succeeded', 'failed', 'canceled', 'refunded');
CREATE TYPE subscription_status AS ENUM ('active', 'suspended', 'canceled', 'expired');
CREATE TYPE tariff_type AS ENUM ('free', 'basic', 'professional', 'enterprise');
CREATE TYPE usage_type AS ENUM ('ccd_declaration', 'ocr_page', 'api_call', 'storage_mb', 'export');

COMMENT ON TYPE payment_provider_type IS 'Тип платежного провайдера';
COMMENT ON TYPE client_type IS 'Тип клиента: individual (физлицо/B2C) | legal (юрлицо/B2B)';
COMMENT ON TYPE payment_status IS 'Статус платежа/транзакции';
COMMENT ON TYPE subscription_status IS 'Статус подписки';
COMMENT ON TYPE tariff_type IS 'Тип тарифа';
COMMENT ON TYPE usage_type IS 'Тип использования ресурса';

-- ============================================================================
-- PAYMENT PROVIDERS
-- ============================================================================

CREATE TABLE IF NOT EXISTS payment_providers
(
    id                 INT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    created_at         TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at         TIMESTAMP WITH TIME ZONE,
    deleted_at         TIMESTAMP WITH TIME ZONE,
    status             entity_status NOT NULL DEFAULT 'active',

    provider_type      payment_provider_type NOT NULL,
    code               VARCHAR(50) UNIQUE NOT NULL,
    display_name       TEXT NOT NULL,

    -- Provider configuration
    supported_client_types client_type[] NOT NULL DEFAULT '{individual,legal}',
    supported_currencies   VARCHAR(3)[] NOT NULL DEFAULT '{UZS}',
    min_amount             BIGINT,  -- minimum amount in minor units
    max_amount             BIGINT,  -- maximum amount in minor units

    -- API credentials (encrypted in application)
    api_endpoint           TEXT,
    webhook_url            TEXT,
    is_active              BOOLEAN NOT NULL DEFAULT TRUE,

    config                 jsonb NOT NULL DEFAULT '{}',
    meta                   jsonb NOT NULL DEFAULT '{}'
);

CREATE INDEX IF NOT EXISTS idx_payment_providers_type ON payment_providers (provider_type);
CREATE INDEX IF NOT EXISTS idx_payment_providers_active ON payment_providers (is_active) WHERE is_active = TRUE;

COMMENT ON TABLE payment_providers IS 'Платежные провайдеры (PayMe, Click, Didox и др.)';
COMMENT ON COLUMN payment_providers.provider_type IS 'Тип провайдера';
COMMENT ON COLUMN payment_providers.code IS 'Уникальный код провайдера в системе';
COMMENT ON COLUMN payment_providers.supported_client_types IS 'Поддерживаемые типы клиентов';
COMMENT ON COLUMN payment_providers.supported_currencies IS 'Поддерживаемые валюты';
COMMENT ON COLUMN payment_providers.config IS 'Конфигурация провайдера (API keys, merchant IDs)';

-- ============================================================================
-- TARIFF PLANS (TOKEN-BASED)
-- ============================================================================

CREATE TABLE IF NOT EXISTS tariff_plans
(
    id                    INT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    created_at            TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at            TIMESTAMP WITH TIME ZONE,
    deleted_at            TIMESTAMP WITH TIME ZONE,
    status                entity_status NOT NULL DEFAULT 'active',

    tariff_type           tariff_type NOT NULL,
    name                  VARCHAR(255) NOT NULL,
    description           TEXT,
    client_type           client_type NOT NULL,

    -- Pricing
    price                 BIGINT NOT NULL,  -- price in minor units
    currency              VARCHAR(3) NOT NULL DEFAULT 'UZS',
    billing_period_days   INT NOT NULL DEFAULT 30,  -- subscription period

    -- Token-based limits (primary model from old schema)
    tokens_limit          BIGINT NOT NULL,  -- total tokens per billing period
    tokens_carryover      BOOLEAN NOT NULL DEFAULT FALSE,  -- allow unused tokens to carry over
    overage_allowed       BOOLEAN NOT NULL DEFAULT FALSE,  -- allow usage beyond limit (will be billed)

    -- Additional resource limits (optional, NULL = no specific limit)
    ccd_limit             INT,  -- max CCD declarations per period
    ocr_page_limit        INT,  -- max OCR pages per period
    api_call_limit        INT,  -- max API calls per period
    storage_limit_mb      INT,  -- max storage in MB
    export_limit          INT,  -- max exports per period
    user_seats            INT DEFAULT 1,  -- for enterprise plans

    -- Features
    features              jsonb NOT NULL DEFAULT '{}',  -- {"advanced_reports": true, "priority_support": true}
    is_public             BOOLEAN NOT NULL DEFAULT TRUE,
    is_active             BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE INDEX IF NOT EXISTS idx_tariff_plans_type ON tariff_plans (tariff_type);
CREATE INDEX IF NOT EXISTS idx_tariff_plans_client_type ON tariff_plans (client_type);
CREATE INDEX IF NOT EXISTS idx_tariff_plans_active ON tariff_plans (is_active) WHERE is_active = TRUE;

COMMENT ON TABLE tariff_plans IS 'Тарифные планы с токен-основанными лимитами использования';
COMMENT ON COLUMN tariff_plans.tariff_type IS 'Тип тарифа: free | basic | professional | enterprise';
COMMENT ON COLUMN tariff_plans.client_type IS 'Для кого тариф: individual (B2C) | legal (B2B)';
COMMENT ON COLUMN tariff_plans.billing_period_days IS 'Период биллинга в днях (обычно 30)';
COMMENT ON COLUMN tariff_plans.tokens_limit IS 'Месячный лимит токенов (основная единица учета)';
COMMENT ON COLUMN tariff_plans.tokens_carryover IS 'Переносить ли неиспользованные токены на следующий месяц';
COMMENT ON COLUMN tariff_plans.overage_allowed IS 'Разрешен ли перерасход (с последующим биллингом)';
COMMENT ON COLUMN tariff_plans.ccd_limit IS 'Лимит CCD деклараций за период (NULL = без ограничений)';
COMMENT ON COLUMN tariff_plans.ocr_page_limit IS 'Лимит OCR страниц за период';
COMMENT ON COLUMN tariff_plans.user_seats IS 'Количество пользовательских мест (для корпоративных)';
COMMENT ON COLUMN tariff_plans.features IS 'JSON с дополнительными фичами тарифа';

-- ============================================================================
-- TRAFFIC LIMITS (MONTHLY TOKEN LIMITS)
-- ============================================================================
-- Based on old schema: ocr_traffic_limits pattern
-- Tracks monthly token limits per user OR organization (mutually exclusive)

CREATE TABLE IF NOT EXISTS traffic_limits
(
    id                        INT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    created_at                TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at                TIMESTAMP WITH TIME ZONE,
    deleted_at                TIMESTAMP WITH TIME ZONE,
    status                    entity_status NOT NULL DEFAULT 'active',

    user_id                   INT REFERENCES users (id),
    organization_id           INT REFERENCES organizations (id),

    -- Monthly period (first day of month in UTC, e.g., 2025-10-01)
    period_month              DATE NOT NULL,

    tariff_plan_id            INT NOT NULL REFERENCES tariff_plans (id),

    -- Token accounting (primary model)
    tokens_limit              BIGINT NOT NULL,  -- monthly cap
    tokens_used               BIGINT NOT NULL DEFAULT 0,  -- consumed within month
    tokens_carryover          BIGINT NOT NULL DEFAULT 0,  -- carried over from prev month
    overage_allowed           BOOLEAN NOT NULL DEFAULT FALSE,  -- allow overage (billable)

    -- Blocking
    blocked_at                TIMESTAMP WITH TIME ZONE,  -- when blocked due to exceeding limit

    -- Additional resource usage (optional tracking)
    ccd_used                  INT NOT NULL DEFAULT 0,
    ocr_pages_used            INT NOT NULL DEFAULT 0,
    api_calls_used            INT NOT NULL DEFAULT 0,
    storage_used_mb           INT NOT NULL DEFAULT 0,
    exports_used              INT NOT NULL DEFAULT 0,

    meta                      jsonb NOT NULL DEFAULT '{}',

    CONSTRAINT traffic_limits_actor_xor_ck CHECK ((user_id IS NOT NULL) <> (organization_id IS NOT NULL)),
    CONSTRAINT traffic_limits_tokens_ck CHECK (tokens_limit >= 0 AND tokens_used >= 0 AND tokens_carryover >= 0)
);

-- Unique per month per scope
CREATE UNIQUE INDEX IF NOT EXISTS uq_traffic_limits_user_month
    ON traffic_limits (user_id, period_month)
    WHERE organization_id IS NULL;

CREATE UNIQUE INDEX IF NOT EXISTS uq_traffic_limits_org_month
    ON traffic_limits (organization_id, period_month)
    WHERE user_id IS NULL;

CREATE INDEX IF NOT EXISTS idx_traffic_limits_period ON traffic_limits (period_month);
CREATE INDEX IF NOT EXISTS idx_traffic_limits_status ON traffic_limits (status);
CREATE INDEX IF NOT EXISTS idx_traffic_limits_user ON traffic_limits (user_id);
CREATE INDEX IF NOT EXISTS idx_traffic_limits_org ON traffic_limits (organization_id);
CREATE INDEX IF NOT EXISTS idx_traffic_limits_tariff ON traffic_limits (tariff_plan_id);

COMMENT ON TABLE traffic_limits IS 'Месячные лимиты токенов и ресурсов. Применяются либо к пользователю, либо к организации (взаимоисключающе)';
COMMENT ON COLUMN traffic_limits.period_month IS 'Месяц лимита (первый день месяца UTC)';
COMMENT ON COLUMN traffic_limits.tokens_limit IS 'Месячный лимит токенов';
COMMENT ON COLUMN traffic_limits.tokens_used IS 'Использовано токенов за месяц';
COMMENT ON COLUMN traffic_limits.tokens_carryover IS 'Перенос остатка токенов с прошлого месяца';
COMMENT ON COLUMN traffic_limits.overage_allowed IS 'Разрешен ли перерасход (с последующим биллингом)';
COMMENT ON COLUMN traffic_limits.blocked_at IS 'Момент блокировки при превышении лимита';


-- ============================================================================
-- OCR SERVICE (TOKEN-BASED)
-- ============================================================================
-- Based on old schema: ocr_jobs with token accounting
-- Used to prefill CCD headers and items from invoices/contracts/CMR

CREATE TABLE IF NOT EXISTS ocr_jobs
(
    id                    BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    created_at            TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at            TIMESTAMP WITH TIME ZONE,
    deleted_at            TIMESTAMP WITH TIME ZONE,
    status                VARCHAR(50) NOT NULL DEFAULT 'created',  -- created | running | succeeded | failed | canceled

    -- Scope (user OR organization)
    user_id               INT REFERENCES users (id),
    organization_id       INT REFERENCES organizations (id),

    -- Optional linkage to CCD and files
    ccd_document_id       INT REFERENCES ccd_documents (id) ON DELETE SET NULL,
    input_file_id         INT REFERENCES files (id) ON DELETE SET NULL,

    -- Job type
    job_type              VARCHAR(50) NOT NULL,  -- invoice | contract | cmr | other
    model                 VARCHAR(100),  -- e.g., 'gpt-4.1-mini', 'tesseract', 'google-vision'
    mode                  VARCHAR(50),  -- e.g., 'ocr' | 'vision' | 'layout'
    language_hint         VARCHAR(10),  -- e.g., 'ru' | 'uz' | 'en'
    page_count            INT,

    -- Token accounting (primary cost model)
    tokens_prompt         BIGINT NOT NULL DEFAULT 0,  -- input/context tokens
    tokens_output         BIGINT NOT NULL DEFAULT 0,  -- completion/output tokens
    tokens_total          BIGINT NOT NULL DEFAULT 0,  -- total tokens charged

    -- OCR result payload
    output_data           jsonb NOT NULL DEFAULT '{}',  -- parsed fields for CCD autofill
    confidence_score      NUMERIC(5, 2),  -- 0-100%
    processing_time_ms    INT,
    error_message         TEXT,

    meta                  jsonb NOT NULL DEFAULT '{}',

    CONSTRAINT ocr_jobs_actor_ck CHECK (user_id IS NOT NULL OR organization_id IS NOT NULL),
    CONSTRAINT ocr_jobs_tokens_ck CHECK (tokens_prompt >= 0 AND tokens_output >= 0 AND tokens_total >= 0),
    CONSTRAINT ocr_jobs_type_ck CHECK (job_type IN ('invoice', 'contract', 'cmr', 'other'))
);

CREATE INDEX IF NOT EXISTS idx_ocr_jobs_created ON ocr_jobs (created_at);
CREATE INDEX IF NOT EXISTS idx_ocr_jobs_status ON ocr_jobs (status);
CREATE INDEX IF NOT EXISTS idx_ocr_jobs_user ON ocr_jobs (user_id);
CREATE INDEX IF NOT EXISTS idx_ocr_jobs_org ON ocr_jobs (organization_id);
CREATE INDEX IF NOT EXISTS idx_ocr_jobs_document ON ocr_jobs (ccd_document_id);
CREATE INDEX IF NOT EXISTS idx_ocr_jobs_file ON ocr_jobs (input_file_id);

COMMENT ON TABLE ocr_jobs IS 'OCR/vision задания с учетом токенов. Используются для автозаполнения CCD из счетов/контрактов/CMR';
COMMENT ON COLUMN ocr_jobs.user_id IS 'FK на users: лимит на уровне пользователя';
COMMENT ON COLUMN ocr_jobs.organization_id IS 'FK на organizations: лимит на уровне организации';
COMMENT ON COLUMN ocr_jobs.ccd_document_id IS 'FK на ccd_documents: связь с декларацией (опционально)';
COMMENT ON COLUMN ocr_jobs.input_file_id IS 'Входной файл (скан/фото первичного документа)';
COMMENT ON COLUMN ocr_jobs.job_type IS 'Тип задания: invoice | contract | cmr | other';
COMMENT ON COLUMN ocr_jobs.model IS 'Модель провайдера (gpt-4, tesseract, google-vision)';
COMMENT ON COLUMN ocr_jobs.mode IS 'Режим: ocr | vision | layout';
COMMENT ON COLUMN ocr_jobs.tokens_prompt IS 'Затраты токенов на вход (prompt/context)';
COMMENT ON COLUMN ocr_jobs.tokens_output IS 'Затраты токенов на выход (completion)';
COMMENT ON COLUMN ocr_jobs.tokens_total IS 'Итого токенов за задание';
COMMENT ON COLUMN ocr_jobs.output_data IS 'Результат OCR в JSON (распознанные поля для автозаполнения CCD)';

-- ============================================================================
-- PAYMENT INVOICES
-- ============================================================================

CREATE TABLE IF NOT EXISTS payment_invoices
(
    id                    INT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    created_at            TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at            TIMESTAMP WITH TIME ZONE,
    deleted_at            TIMESTAMP WITH TIME ZONE,
    status                entity_status NOT NULL DEFAULT 'active',

    user_id               INT REFERENCES users (id),
    organization_id       INT REFERENCES organizations (id),
    traffic_limit_id      INT REFERENCES traffic_limits (id),

    invoice_number        VARCHAR(100) UNIQUE,
    title                 TEXT NOT NULL,
    description           TEXT,

    -- Amount
    amount_subtotal       BIGINT NOT NULL,  -- minor units
    amount_tax            BIGINT NOT NULL DEFAULT 0,
    amount_total          BIGINT NOT NULL,
    currency              VARCHAR(3) NOT NULL DEFAULT 'UZS',

    -- Payment
    payment_status        payment_status NOT NULL DEFAULT 'pending',
    due_at                TIMESTAMP WITH TIME ZONE,
    paid_at               TIMESTAMP WITH TIME ZONE,

    meta                  jsonb NOT NULL DEFAULT '{}',

    CONSTRAINT invoices_actor_ck CHECK (user_id IS NOT NULL OR organization_id IS NOT NULL)
);

CREATE INDEX IF NOT EXISTS idx_invoices_user ON payment_invoices (user_id);
CREATE INDEX IF NOT EXISTS idx_invoices_org ON payment_invoices (organization_id);
CREATE INDEX IF NOT EXISTS idx_invoices_traffic_limit ON payment_invoices (traffic_limit_id);
CREATE INDEX IF NOT EXISTS idx_invoices_status ON payment_invoices (payment_status);
CREATE INDEX IF NOT EXISTS idx_invoices_number ON payment_invoices (invoice_number);

COMMENT ON TABLE payment_invoices IS 'Счета на оплату для пользователей и организаций';
COMMENT ON COLUMN payment_invoices.invoice_number IS 'Уникальный номер счета';
COMMENT ON COLUMN payment_invoices.payment_status IS 'Статус оплаты счета';

-- ============================================================================
-- INVOICE ITEMS
-- ============================================================================

CREATE TABLE IF NOT EXISTS payment_invoice_items
(
    id                    INT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    created_at            TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),

    invoice_id            INT NOT NULL REFERENCES payment_invoices (id) ON DELETE CASCADE,

    name                  TEXT NOT NULL,
    description           TEXT,
    quantity              NUMERIC(18, 4) NOT NULL DEFAULT 1,
    unit_price            BIGINT NOT NULL,  -- minor units
    total_price           BIGINT NOT NULL,  -- quantity * unit_price

    tariff_plan_id        INT REFERENCES tariff_plans (id),
    meta                  jsonb NOT NULL DEFAULT '{}'
);

CREATE INDEX IF NOT EXISTS idx_invoice_items_invoice ON payment_invoice_items (invoice_id);

COMMENT ON TABLE payment_invoice_items IS 'Позиции счета (строки)';
COMMENT ON COLUMN payment_invoice_items.total_price IS 'Итого за позицию (quantity * unit_price)';

-- ============================================================================
-- PAYMENT SESSIONS
-- ============================================================================

CREATE TABLE IF NOT EXISTS payment_sessions
(
    id                    BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    created_at            TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at            TIMESTAMP WITH TIME ZONE,

    provider_id           INT NOT NULL REFERENCES payment_providers (id),
    invoice_id            INT REFERENCES payment_invoices (id),
    user_id               INT REFERENCES users (id),
    organization_id       INT REFERENCES organizations (id),

    -- Session details
    session_id            VARCHAR(255) UNIQUE,  -- provider's session ID
    amount                BIGINT NOT NULL,
    currency              VARCHAR(3) NOT NULL DEFAULT 'UZS',

    -- URLs
    return_url            TEXT,
    cancel_url            TEXT,

    -- Status
    payment_status        payment_status NOT NULL DEFAULT 'pending',

    -- Provider response
    provider_payment_id   TEXT,
    provider_response     jsonb NOT NULL DEFAULT '{}',

    expires_at            TIMESTAMP WITH TIME ZONE,
    completed_at          TIMESTAMP WITH TIME ZONE,

    meta                  jsonb NOT NULL DEFAULT '{}',

    CONSTRAINT sessions_actor_ck CHECK (user_id IS NOT NULL OR organization_id IS NOT NULL)
);

CREATE INDEX IF NOT EXISTS idx_sessions_provider ON payment_sessions (provider_id);
CREATE INDEX IF NOT EXISTS idx_sessions_invoice ON payment_sessions (invoice_id);
CREATE INDEX IF NOT EXISTS idx_sessions_user ON payment_sessions (user_id);
CREATE INDEX IF NOT EXISTS idx_sessions_org ON payment_sessions (organization_id);
CREATE INDEX IF NOT EXISTS idx_sessions_status ON payment_sessions (payment_status);
CREATE INDEX IF NOT EXISTS idx_sessions_session_id ON payment_sessions (session_id);

COMMENT ON TABLE payment_sessions IS 'Платежные сессии с провайдерами';
COMMENT ON COLUMN payment_sessions.session_id IS 'ID сессии от провайдера';
COMMENT ON COLUMN payment_sessions.provider_payment_id IS 'ID платежа от провайдера';

-- ============================================================================
-- PAYMENT TRANSACTIONS
-- ============================================================================

CREATE TABLE IF NOT EXISTS payment_transactions
(
    id                    BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    created_at            TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at            TIMESTAMP WITH TIME ZONE,
    deleted_at            TIMESTAMP WITH TIME ZONE,
    status                entity_status NOT NULL DEFAULT 'active',

    provider_id           INT NOT NULL REFERENCES payment_providers (id),
    session_id            BIGINT REFERENCES payment_sessions (id),
    invoice_id            INT REFERENCES payment_invoices (id),
    tariff_plan_id        INT REFERENCES tariff_plans (id),
    traffic_limit_id      INT REFERENCES traffic_limits (id),
    user_id               INT REFERENCES users (id),
    organization_id       INT REFERENCES organizations (id),

    -- Transaction details
    transaction_id        VARCHAR(255),  -- provider's transaction ID
    amount                BIGINT NOT NULL,
    currency              VARCHAR(3) NOT NULL DEFAULT 'UZS',

    payment_status        payment_status NOT NULL DEFAULT 'pending',
    payment_method        VARCHAR(100),  -- card | wallet | bank_transfer

    -- Provider data
    provider_fee          BIGINT,
    provider_response     jsonb NOT NULL DEFAULT '{}',

    -- Reconciliation
    reconciled            BOOLEAN NOT NULL DEFAULT FALSE,
    reconciled_at         TIMESTAMP WITH TIME ZONE,

    completed_at          TIMESTAMP WITH TIME ZONE,
    failed_reason         TEXT,

    meta                  jsonb NOT NULL DEFAULT '{}',

    CONSTRAINT transactions_actor_ck CHECK (user_id IS NOT NULL OR organization_id IS NOT NULL)
);

CREATE INDEX IF NOT EXISTS idx_transactions_provider ON payment_transactions (provider_id);
CREATE INDEX IF NOT EXISTS idx_transactions_session ON payment_transactions (session_id);
CREATE INDEX IF NOT EXISTS idx_transactions_invoice ON payment_transactions (invoice_id);
CREATE INDEX IF NOT EXISTS idx_transactions_tariff_plan ON payment_transactions (tariff_plan_id);
CREATE INDEX IF NOT EXISTS idx_transactions_traffic_limit ON payment_transactions (traffic_limit_id);
CREATE INDEX IF NOT EXISTS idx_transactions_user ON payment_transactions (user_id);
CREATE INDEX IF NOT EXISTS idx_transactions_org ON payment_transactions (organization_id);
CREATE INDEX IF NOT EXISTS idx_transactions_status ON payment_transactions (payment_status);
CREATE INDEX IF NOT EXISTS idx_transactions_transaction_id ON payment_transactions (transaction_id);
CREATE INDEX IF NOT EXISTS idx_transactions_reconciled ON payment_transactions (reconciled) WHERE reconciled = FALSE;

COMMENT ON TABLE payment_transactions IS 'Платежные транзакции (успешные и неуспешные)';
COMMENT ON COLUMN payment_transactions.transaction_id IS 'ID транзакции от провайдера';
COMMENT ON COLUMN payment_transactions.reconciled IS 'Флаг сверки транзакции';
COMMENT ON COLUMN payment_transactions.provider_fee IS 'Комиссия провайдера';
COMMENT ON COLUMN payment_transactions.tariff_plan_id IS 'FK на tariff_plans: если покупка тарифа, по нему начисляются токены/лимиты';

-- ============================================================================
-- REFUNDS
-- ============================================================================

CREATE TABLE IF NOT EXISTS payment_refunds
(
    id                    BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    created_at            TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at            TIMESTAMP WITH TIME ZONE,

    transaction_id        BIGINT NOT NULL REFERENCES payment_transactions (id),
    provider_id           INT NOT NULL REFERENCES payment_providers (id),

    refund_id             VARCHAR(255),  -- provider's refund ID
    amount                BIGINT NOT NULL,
    currency              VARCHAR(3) NOT NULL DEFAULT 'UZS',

    refund_status         payment_status NOT NULL DEFAULT 'pending',
    reason                TEXT,

    provider_response     jsonb NOT NULL DEFAULT '{}',
    completed_at          TIMESTAMP WITH TIME ZONE,

    meta                  jsonb NOT NULL DEFAULT '{}'
);

CREATE INDEX IF NOT EXISTS idx_refunds_transaction ON payment_refunds (transaction_id);
CREATE INDEX IF NOT EXISTS idx_refunds_provider ON payment_refunds (provider_id);
CREATE INDEX IF NOT EXISTS idx_refunds_status ON payment_refunds (refund_status);

COMMENT ON TABLE payment_refunds IS 'Возвраты средств по транзакциям';
COMMENT ON COLUMN payment_refunds.refund_id IS 'ID возврата от провайдера';

-- ============================================================================
-- WEBHOOKS
-- ============================================================================

CREATE TABLE IF NOT EXISTS webhook_events
(
    id                    BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    created_at            TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),

    provider_id           INT REFERENCES payment_providers (id),
    event_type            VARCHAR(100) NOT NULL,
    event_id              VARCHAR(255),  -- provider's event ID

    -- Security
    signature             TEXT,
    signature_verified    BOOLEAN NOT NULL DEFAULT FALSE,

    -- Payload
    payload               jsonb NOT NULL,

    -- Processing
    processed             BOOLEAN NOT NULL DEFAULT FALSE,
    processed_at          TIMESTAMP WITH TIME ZONE,
    processing_error      TEXT,

    -- Linking
    transaction_id        BIGINT REFERENCES payment_transactions (id),
    session_id            BIGINT REFERENCES payment_sessions (id)
);

CREATE INDEX IF NOT EXISTS idx_webhooks_provider ON webhook_events (provider_id);
CREATE INDEX IF NOT EXISTS idx_webhooks_event_type ON webhook_events (event_type);
CREATE INDEX IF NOT EXISTS idx_webhooks_event_id ON webhook_events (event_id);
CREATE INDEX IF NOT EXISTS idx_webhooks_processed ON webhook_events (processed) WHERE processed = FALSE;
CREATE INDEX IF NOT EXISTS idx_webhooks_created ON webhook_events (created_at);

COMMENT ON TABLE webhook_events IS 'События вебхуков от платежных провайдеров';
COMMENT ON COLUMN webhook_events.signature_verified IS 'Подпись вебхука проверена';
COMMENT ON COLUMN webhook_events.processed IS 'Событие обработано';

-- ============================================================================
-- IDEMPOTENCY
-- ============================================================================

CREATE TABLE IF NOT EXISTS idempotency_keys
(
    key                   VARCHAR(255) PRIMARY KEY,
    created_at            TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    expires_at            TIMESTAMP WITH TIME ZONE NOT NULL,

    user_id               INT REFERENCES users (id),

    request_hash          TEXT,
    response_status       INT,
    response_body         jsonb
);

CREATE INDEX IF NOT EXISTS idx_idempotency_expires ON idempotency_keys (expires_at);
CREATE INDEX IF NOT EXISTS idx_idempotency_user ON idempotency_keys (user_id);

COMMENT ON TABLE idempotency_keys IS 'Ключи идемпотентности для предотвращения дублирования платежей';
COMMENT ON COLUMN idempotency_keys.expires_at IS 'Ключ истекает и может быть удален';

-- ============================================================================
-- AUDIT LOG
-- ============================================================================

CREATE TABLE IF NOT EXISTS payment_audit_log
(
    id                    BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    created_at            TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),

    user_id               INT REFERENCES users (id),
    organization_id       INT REFERENCES organizations (id),

    action                VARCHAR(100) NOT NULL,  -- subscription_created, payment_succeeded, refund_issued, etc.
    entity_type           VARCHAR(50),  -- subscription, transaction, invoice
    entity_id             BIGINT,

    old_data              jsonb,
    new_data              jsonb,

    ip_address            INET,
    user_agent            TEXT
);

CREATE INDEX IF NOT EXISTS idx_audit_user ON payment_audit_log (user_id);
CREATE INDEX IF NOT EXISTS idx_audit_org ON payment_audit_log (organization_id);
CREATE INDEX IF NOT EXISTS idx_audit_action ON payment_audit_log (action);
CREATE INDEX IF NOT EXISTS idx_audit_created ON payment_audit_log (created_at);

COMMENT ON TABLE payment_audit_log IS 'Аудит всех действий в платежной системе';
COMMENT ON COLUMN payment_audit_log.action IS 'Тип действия';
COMMENT ON COLUMN payment_audit_log.entity_type IS 'Тип сущности';
