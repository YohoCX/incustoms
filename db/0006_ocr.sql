-- OCR token accounting: jobs and monthly traffic limits
-- This module counts OCR tokens per job and enforces monthly limits
-- (either per individual user or per organization). Flow: user uploads
-- an invoice/contract/CMR, we run OCR, store parsed output JSON, and use it
-- to prefill CCD headers and items.

-- Jobs submitted to OCR/vision backends.
CREATE TABLE IF NOT EXISTS ocr_jobs
(
    id                   INT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    created_at           timestamptz NOT NULL DEFAULT NOW(),
    updated_at           timestamptz,
    deleted_at           timestamptz,
    status               TEXT        NOT NULL DEFAULT 'created', -- 'created','running','succeeded','failed','canceled'

    -- Scope actor
    organization_id      INT REFERENCES organizations (id),
    user_id              INT REFERENCES users (id),

    -- Optional linkage to CCD and files
    document_id          INT REFERENCES ccd_documents (id) ON DELETE SET NULL,
    input_file_id        INT REFERENCES files (id) ON DELETE SET NULL,

    -- Provider/model info
    job_type             TEXT        NOT NULL,                -- 'invoice','contract','cmr','other'
    model                TEXT,                                -- e.g., 'gpt-4.1-mini'
    mode                 TEXT,                                -- e.g., 'ocr','vision','layout'
    language_hint        TEXT,                                -- e.g., 'ru','uz','en'
    page_count           INT,

    -- Token accounting
    tokens_prompt        BIGINT      NOT NULL DEFAULT 0,
    tokens_output        BIGINT      NOT NULL DEFAULT 0,
    tokens_total         BIGINT      NOT NULL DEFAULT 0,

    -- OCR result payload
    output_data          jsonb       NOT NULL DEFAULT '{}',   -- parsed fields extracted from OCR
    meta                 jsonb       NOT NULL DEFAULT '{}',

    CONSTRAINT ocr_jobs_actor_ck CHECK (user_id IS NOT NULL OR organization_id IS NOT NULL),
    CONSTRAINT ocr_jobs_tokens_ck CHECK (tokens_prompt >= 0 AND tokens_output >= 0 AND tokens_total >= 0),
    CONSTRAINT ocr_jobs_type_ck CHECK (job_type IN ('invoice','contract','cmr','other'))
);

-- Comments for ocr_jobs
COMMENT ON TABLE ocr_jobs IS 'OCR/vision задания с учетом токенов. Привязаны к пользователю или организации; связываются с файлом-источником и при необходимости с CCD';
COMMENT ON COLUMN ocr_jobs.organization_id IS 'FK на organizations: лимит на уровне организации';
COMMENT ON COLUMN ocr_jobs.user_id IS 'FK на users: лимит на уровне пользователя';
COMMENT ON COLUMN ocr_jobs.document_id IS 'FK на ccd_documents: опционально связывает OCR с конкретной декларацией';
COMMENT ON COLUMN ocr_jobs.input_file_id IS 'Входной файл (скан/фото первичного документа)';
COMMENT ON COLUMN ocr_jobs.job_type IS 'Тип задания: invoice | contract | cmr | other';
COMMENT ON COLUMN ocr_jobs.model IS 'Модель провайдера';
COMMENT ON COLUMN ocr_jobs.mode IS 'Режим: ocr/vision/layout и т.п.';
COMMENT ON COLUMN ocr_jobs.language_hint IS 'Подсказка языка для OCR';
COMMENT ON COLUMN ocr_jobs.tokens_prompt IS 'Затраты токенов на вход (prompt/context)';
COMMENT ON COLUMN ocr_jobs.tokens_output IS 'Затраты токенов на выход (completion/вывод)';
COMMENT ON COLUMN ocr_jobs.tokens_total IS 'Итого токенов за задание';
COMMENT ON COLUMN ocr_jobs.output_data IS 'Результат OCR в JSON (распознанные поля для автозаполнения CCD)';

CREATE INDEX IF NOT EXISTS idx_ocr_jobs_created_at ON ocr_jobs (created_at);
CREATE INDEX IF NOT EXISTS idx_ocr_jobs_status ON ocr_jobs (status);
CREATE INDEX IF NOT EXISTS idx_ocr_jobs_user ON ocr_jobs (user_id);
CREATE INDEX IF NOT EXISTS idx_ocr_jobs_org ON ocr_jobs (organization_id);
CREATE INDEX IF NOT EXISTS idx_ocr_jobs_document ON ocr_jobs (document_id);

-- Monthly token limits per user OR per organization (mutually exclusive)
CREATE TABLE IF NOT EXISTS ocr_traffic_limits
(
    id                        INT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    created_at                timestamptz NOT NULL DEFAULT NOW(),
    updated_at                timestamptz,
    deleted_at                timestamptz,
    status                    TEXT        NOT NULL DEFAULT 'active', -- 'active','disabled','archived'

    organization_id           INT REFERENCES organizations (id),
    user_id                   INT REFERENCES users (id),

    -- Month represented by the first day of month in UTC (e.g., 2025-09-01)
    period_month              DATE        NOT NULL,

    price_plan_id             INT REFERENCES price_plans (id),

    limit_tokens              BIGINT      NOT NULL, -- monthly cap
    used_tokens               BIGINT      NOT NULL DEFAULT 0, -- consumed within month
    carryover_from_prev_month BIGINT      NOT NULL DEFAULT 0, -- перенесенные остатки
    overage_allowed           BOOLEAN     NOT NULL DEFAULT FALSE, -- разрешить перерасход (с оплатой)
    blocked_at                timestamptz, -- когда заблокировано из-за превышения

    meta                      jsonb       NOT NULL DEFAULT '{}',

    CONSTRAINT ocr_limits_actor_xor_ck CHECK ((user_id IS NOT NULL) <> (organization_id IS NOT NULL)),
    CONSTRAINT ocr_limits_tokens_ck CHECK (limit_tokens >= 0 AND used_tokens >= 0 AND carryover_from_prev_month >= 0)
);

-- Comments for ocr_traffic_limits
COMMENT ON TABLE ocr_traffic_limits IS 'Месячные лимиты токенов OCR. Применяются либо к пользователю, либо к организации (взаимоисключительно)';
COMMENT ON COLUMN ocr_traffic_limits.organization_id IS 'FK на organizations: лимит на организацию';
COMMENT ON COLUMN ocr_traffic_limits.user_id IS 'FK на users: лимит на пользователя';
COMMENT ON COLUMN ocr_traffic_limits.period_month IS 'Месяц лимита (первый день месяца)';
COMMENT ON COLUMN ocr_traffic_limits.price_plan_id IS 'FK на price_plans: тариф, по которому установлен лимит';
COMMENT ON COLUMN ocr_traffic_limits.limit_tokens IS 'Месячный лимит токенов';
COMMENT ON COLUMN ocr_traffic_limits.used_tokens IS 'Использовано токенов за месяц';
COMMENT ON COLUMN ocr_traffic_limits.carryover_from_prev_month IS 'Перенос остатка токенов с прошлого месяца';
COMMENT ON COLUMN ocr_traffic_limits.overage_allowed IS 'Разрешен ли перерасход (с последующим биллингом)';
COMMENT ON COLUMN ocr_traffic_limits.blocked_at IS 'Момент блокировки при превышении лимита';

-- Uniqueness per month per scope (partial unique indexes)
CREATE UNIQUE INDEX IF NOT EXISTS uq_ocr_limits_user_month
    ON ocr_traffic_limits (user_id, period_month)
    WHERE organization_id IS NULL;

CREATE UNIQUE INDEX IF NOT EXISTS uq_ocr_limits_org_month
    ON ocr_traffic_limits (organization_id, period_month)
    WHERE user_id IS NULL;

-- Frequent filters
CREATE INDEX IF NOT EXISTS idx_ocr_limits_period ON ocr_traffic_limits (period_month);
CREATE INDEX IF NOT EXISTS idx_ocr_limits_status ON ocr_traffic_limits (status);
