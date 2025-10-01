-- ============================================================================
-- Analytics, Autocomplete & Audit System
-- ============================================================================
-- This migration creates:
-- - Analytics: user behavior tracking, dashboards, reports
-- - Autocomplete: smart suggestions based on user history and patterns
-- - Audit: comprehensive audit trail for compliance and security
-- ============================================================================

-- ============================================================================
-- ENUMS
-- ============================================================================

CREATE TYPE event_type AS ENUM (
    'page_view', 'button_click', 'form_submit', 'document_create', 'document_edit',
    'document_delete', 'document_export', 'file_upload', 'ocr_request', 'payment',
    'login', 'logout', 'search', 'filter', 'api_call'
);

CREATE TYPE audit_action AS ENUM (
    'create', 'read', 'update', 'delete', 'export', 'import', 'approve', 'reject',
    'submit', 'cancel', 'restore', 'login', 'logout', 'permission_change'
);

CREATE TYPE suggestion_type AS ENUM (
    'hs_code', 'country', 'partner', 'currency', 'transport', 'regime',
    'text_field', 'numeric_value', 'recent_value', 'popular_value'
);

COMMENT ON TYPE event_type IS 'Типы событий для аналитики';
COMMENT ON TYPE audit_action IS 'Типы действий для аудита';
COMMENT ON TYPE suggestion_type IS 'Типы автоподсказок';

-- ============================================================================
-- ANALYTICS: EVENT TRACKING
-- ============================================================================

CREATE TABLE IF NOT EXISTS analytics_events
(
    id                    BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    created_at            TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),

    -- Who
    user_id               INT REFERENCES users (id),
    organization_id       INT REFERENCES organizations (id),
    session_id            VARCHAR(255),  -- frontend session ID

    -- What
    event_type            event_type NOT NULL,
    event_name            VARCHAR(255) NOT NULL,  -- e.g., "ccd_created", "export_pdf_clicked"
    event_category        VARCHAR(100),  -- e.g., "navigation", "document", "payment"

    -- Where
    page_url              TEXT,
    page_title            VARCHAR(500),
    referrer_url          TEXT,

    -- Context
    entity_type           VARCHAR(100),  -- e.g., "ccd_document", "payment_invoice"
    entity_id             BIGINT,

    -- Properties (flexible JSON)
    properties            jsonb NOT NULL DEFAULT '{}',

    -- Technical
    user_agent            TEXT,
    ip_address            INET,
    country_code          VARCHAR(2),
    device_type           VARCHAR(50),  -- desktop | mobile | tablet
    browser               VARCHAR(100),
    os                    VARCHAR(100),

    -- Performance
    load_time_ms          INT,

    meta                  jsonb NOT NULL DEFAULT '{}'
);

CREATE INDEX IF NOT EXISTS idx_analytics_events_created ON analytics_events (created_at);
CREATE INDEX IF NOT EXISTS idx_analytics_events_user ON analytics_events (user_id);
CREATE INDEX IF NOT EXISTS idx_analytics_events_org ON analytics_events (organization_id);
CREATE INDEX IF NOT EXISTS idx_analytics_events_type ON analytics_events (event_type);
CREATE INDEX IF NOT EXISTS idx_analytics_events_name ON analytics_events (event_name);
CREATE INDEX IF NOT EXISTS idx_analytics_events_session ON analytics_events (session_id);
CREATE INDEX IF NOT EXISTS idx_analytics_events_entity ON analytics_events (entity_type, entity_id);
CREATE INDEX IF NOT EXISTS idx_analytics_events_properties ON analytics_events USING gin (properties);

COMMENT ON TABLE analytics_events IS 'События пользователей для аналитики и отслеживания поведения';
COMMENT ON COLUMN analytics_events.event_type IS 'Тип события (категория)';
COMMENT ON COLUMN analytics_events.event_name IS 'Название события (детальное)';
COMMENT ON COLUMN analytics_events.properties IS 'Дополнительные свойства события (JSON)';
COMMENT ON COLUMN analytics_events.entity_type IS 'Тип сущности, с которой связано событие';
COMMENT ON COLUMN analytics_events.entity_id IS 'ID сущности';

-- ============================================================================
-- ANALYTICS: USER SESSIONS
-- ============================================================================

CREATE TABLE IF NOT EXISTS analytics_sessions
(
    id                    BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    session_id            VARCHAR(255) UNIQUE NOT NULL,

    user_id               INT REFERENCES users (id),
    organization_id       INT REFERENCES organizations (id),

    started_at            TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    last_activity_at      TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    ended_at              TIMESTAMP WITH TIME ZONE,
    duration_seconds      INT,

    -- Entry/Exit
    entry_page            TEXT,
    exit_page             TEXT,

    -- Activity metrics
    page_views            INT NOT NULL DEFAULT 0,
    events_count          INT NOT NULL DEFAULT 0,

    -- Technical
    ip_address            INET,
    user_agent            TEXT,
    device_type           VARCHAR(50),
    browser               VARCHAR(100),
    os                    VARCHAR(100),
    country_code          VARCHAR(2),

    meta                  jsonb NOT NULL DEFAULT '{}'
);

CREATE INDEX IF NOT EXISTS idx_analytics_sessions_session_id ON analytics_sessions (session_id);
CREATE INDEX IF NOT EXISTS idx_analytics_sessions_user ON analytics_sessions (user_id);
CREATE INDEX IF NOT EXISTS idx_analytics_sessions_org ON analytics_sessions (organization_id);
CREATE INDEX IF NOT EXISTS idx_analytics_sessions_started ON analytics_sessions (started_at);

COMMENT ON TABLE analytics_sessions IS 'Пользовательские сессии для аналитики';
COMMENT ON COLUMN analytics_sessions.duration_seconds IS 'Длительность сессии в секундах';

-- ============================================================================
-- ANALYTICS: AGGREGATED METRICS (MATERIALIZED VIEW PATTERN)
-- ============================================================================

CREATE TABLE IF NOT EXISTS analytics_daily_metrics
(
    id                    BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    metric_date           DATE NOT NULL,
    organization_id       INT REFERENCES organizations (id),

    -- User metrics
    active_users          INT NOT NULL DEFAULT 0,
    new_users             INT NOT NULL DEFAULT 0,
    sessions_count        INT NOT NULL DEFAULT 0,
    avg_session_duration  INT,  -- seconds

    -- Document metrics
    ccd_created           INT NOT NULL DEFAULT 0,
    ccd_submitted         INT NOT NULL DEFAULT 0,
    ccd_approved          INT NOT NULL DEFAULT 0,
    ccd_rejected          INT NOT NULL DEFAULT 0,

    -- OCR metrics
    ocr_jobs_total        INT NOT NULL DEFAULT 0,
    ocr_pages_total       INT NOT NULL DEFAULT 0,
    ocr_tokens_used       BIGINT NOT NULL DEFAULT 0,

    -- Payment metrics
    revenue_total         BIGINT NOT NULL DEFAULT 0,  -- minor units
    transactions_count    INT NOT NULL DEFAULT 0,

    -- Engagement
    page_views            INT NOT NULL DEFAULT 0,
    events_count          INT NOT NULL DEFAULT 0,

    created_at            TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at            TIMESTAMP WITH TIME ZONE
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_daily_metrics_date_org
    ON analytics_daily_metrics (metric_date, organization_id);
CREATE INDEX IF NOT EXISTS idx_daily_metrics_date ON analytics_daily_metrics (metric_date);
CREATE INDEX IF NOT EXISTS idx_daily_metrics_org ON analytics_daily_metrics (organization_id);

COMMENT ON TABLE analytics_daily_metrics IS 'Агрегированные ежедневные метрики (обновляется периодически)';
COMMENT ON COLUMN analytics_daily_metrics.active_users IS 'Количество активных пользователей за день';
COMMENT ON COLUMN analytics_daily_metrics.avg_session_duration IS 'Средняя длительность сессии в секундах';

-- ============================================================================
-- AUTOCOMPLETE: USER PREFERENCES & HISTORY
-- ============================================================================

CREATE TABLE IF NOT EXISTS autocomplete_user_history
(
    id                    BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    created_at            TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    last_used_at          TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),

    user_id               INT NOT NULL REFERENCES users (id),
    organization_id       INT REFERENCES organizations (id),

    -- What field
    field_name            VARCHAR(255) NOT NULL,  -- e.g., 'trade_country', 'hs_code', 'exporter_name'
    field_type            suggestion_type NOT NULL,

    -- Value
    value_text            TEXT,
    value_id              INT,  -- FK to reference table if applicable
    reference_table       VARCHAR(100),  -- e.g., 'codes_countries', 'codes_hs'

    -- Frequency tracking
    use_count             INT NOT NULL DEFAULT 1,

    -- Context (for better suggestions)
    context               jsonb NOT NULL DEFAULT '{}',  -- e.g., {"direction": "IM", "regime": "40"}

    meta                  jsonb NOT NULL DEFAULT '{}'
);

CREATE INDEX IF NOT EXISTS idx_autocomplete_history_user ON autocomplete_user_history (user_id);
CREATE INDEX IF NOT EXISTS idx_autocomplete_history_org ON autocomplete_user_history (organization_id);
CREATE INDEX IF NOT EXISTS idx_autocomplete_history_field ON autocomplete_user_history (field_name);
CREATE INDEX IF NOT EXISTS idx_autocomplete_history_last_used ON autocomplete_user_history (last_used_at);
CREATE INDEX IF NOT EXISTS idx_autocomplete_history_context ON autocomplete_user_history USING gin (context);

COMMENT ON TABLE autocomplete_user_history IS 'История использования значений для автоподсказок';
COMMENT ON COLUMN autocomplete_user_history.field_name IS 'Название поля (например, trade_country)';
COMMENT ON COLUMN autocomplete_user_history.use_count IS 'Количество использований';
COMMENT ON COLUMN autocomplete_user_history.context IS 'Контекст использования (JSON)';

-- ============================================================================
-- AUTOCOMPLETE: POPULAR VALUES (GLOBAL)
-- ============================================================================

CREATE TABLE IF NOT EXISTS autocomplete_popular_values
(
    id                    BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    updated_at            TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),

    field_name            VARCHAR(255) NOT NULL,
    field_type            suggestion_type NOT NULL,

    -- Value
    value_text            TEXT,
    value_id              INT,
    reference_table       VARCHAR(100),

    -- Popularity metrics
    use_count_total       BIGINT NOT NULL DEFAULT 0,
    use_count_last_30d    INT NOT NULL DEFAULT 0,
    unique_users          INT NOT NULL DEFAULT 0,

    -- Ranking
    rank_global           INT,
    rank_by_context       jsonb NOT NULL DEFAULT '{}',  -- {"IM": 1, "EK": 5}

    meta                  jsonb NOT NULL DEFAULT '{}'
);

CREATE INDEX IF NOT EXISTS idx_popular_values_field ON autocomplete_popular_values (field_name);
CREATE INDEX IF NOT EXISTS idx_popular_values_rank ON autocomplete_popular_values (rank_global);
CREATE INDEX IF NOT EXISTS idx_popular_values_context ON autocomplete_popular_values USING gin (rank_by_context);

COMMENT ON TABLE autocomplete_popular_values IS 'Популярные значения для автоподсказок (глобальная статистика)';
COMMENT ON COLUMN autocomplete_popular_values.use_count_last_30d IS 'Количество использований за последние 30 дней';
COMMENT ON COLUMN autocomplete_popular_values.rank_by_context IS 'Ранг по контексту (JSON)';

-- ============================================================================
-- AUTOCOMPLETE: SMART SUGGESTIONS CACHE
-- ============================================================================

CREATE TABLE IF NOT EXISTS autocomplete_suggestions_cache
(
    id                    BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    created_at            TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    expires_at            TIMESTAMP WITH TIME ZONE NOT NULL,

    cache_key             VARCHAR(500) UNIQUE NOT NULL,  -- hash of user_id + field + context

    user_id               INT REFERENCES users (id),
    organization_id       INT REFERENCES organizations (id),
    field_name            VARCHAR(255) NOT NULL,

    -- Cached suggestions
    suggestions           jsonb NOT NULL,  -- [{value, label, score, meta}, ...]

    context               jsonb NOT NULL DEFAULT '{}'
);

CREATE INDEX IF NOT EXISTS idx_suggestions_cache_key ON autocomplete_suggestions_cache (cache_key);
CREATE INDEX IF NOT EXISTS idx_suggestions_cache_user ON autocomplete_suggestions_cache (user_id);
CREATE INDEX IF NOT EXISTS idx_suggestions_cache_expires ON autocomplete_suggestions_cache (expires_at);

COMMENT ON TABLE autocomplete_suggestions_cache IS 'Кэш автоподсказок для быстрой выдачи';
COMMENT ON COLUMN autocomplete_suggestions_cache.cache_key IS 'Ключ кэша (хеш параметров)';
COMMENT ON COLUMN autocomplete_suggestions_cache.suggestions IS 'Закэшированные подсказки (JSON array)';

-- ============================================================================
-- AUDIT: COMPREHENSIVE AUDIT TRAIL
-- ============================================================================

CREATE TABLE IF NOT EXISTS audit_log
(
    id                    BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    created_at            TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),

    -- Who
    user_id               INT REFERENCES users (id),
    organization_id       INT REFERENCES organizations (id),
    impersonator_id       INT REFERENCES users (id),  -- if acting on behalf of another user

    -- What
    action                audit_action NOT NULL,
    entity_type           VARCHAR(100) NOT NULL,  -- e.g., 'ccd_document', 'user', 'organization'
    entity_id             BIGINT,

    -- Description
    description           TEXT,

    -- Changes (before/after snapshots)
    old_values            jsonb,
    new_values            jsonb,
    changes               jsonb,  -- diff: [{field, old, new}, ...]

    -- Context
    request_id            VARCHAR(255),  -- for request tracing
    session_id            VARCHAR(255),

    -- Technical
    ip_address            INET,
    user_agent            TEXT,
    api_endpoint          VARCHAR(500),
    http_method           VARCHAR(10),

    -- Result
    success               BOOLEAN NOT NULL DEFAULT TRUE,
    error_message         TEXT,

    meta                  jsonb NOT NULL DEFAULT '{}'
);

CREATE INDEX IF NOT EXISTS idx_audit_log_created ON audit_log (created_at);
CREATE INDEX IF NOT EXISTS idx_audit_log_user ON audit_log (user_id);
CREATE INDEX IF NOT EXISTS idx_audit_log_org ON audit_log (organization_id);
CREATE INDEX IF NOT EXISTS idx_audit_log_action ON audit_log (action);
CREATE INDEX IF NOT EXISTS idx_audit_log_entity ON audit_log (entity_type, entity_id);
CREATE INDEX IF NOT EXISTS idx_audit_log_request ON audit_log (request_id);
CREATE INDEX IF NOT EXISTS idx_audit_log_changes ON audit_log USING gin (changes);

COMMENT ON TABLE audit_log IS 'Комплексный аудит всех действий в системе';
COMMENT ON COLUMN audit_log.impersonator_id IS 'ID пользователя, действующего от имени другого';
COMMENT ON COLUMN audit_log.changes IS 'Изменения в виде diff (JSON)';
COMMENT ON COLUMN audit_log.request_id IS 'ID запроса для трассировки';

-- ============================================================================
-- AUDIT: DOCUMENT HISTORY (VERSIONING)
-- ============================================================================

CREATE TABLE IF NOT EXISTS document_versions
(
    id                    BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    created_at            TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),

    document_id           INT NOT NULL REFERENCES ccd_documents (id),
    version_number        INT NOT NULL,

    -- Who made the change
    created_by_user_id    INT REFERENCES users (id),

    -- Change type
    change_type           audit_action NOT NULL,
    change_description    TEXT,

    -- Snapshot (full document state at this version)
    document_snapshot     jsonb NOT NULL,

    -- Changes from previous version
    changes_diff          jsonb,

    -- Metadata
    is_major_version      BOOLEAN NOT NULL DEFAULT FALSE,
    tags                  TEXT[],

    meta                  jsonb NOT NULL DEFAULT '{}'
);

CREATE INDEX IF NOT EXISTS idx_document_versions_document ON document_versions (document_id);
CREATE INDEX IF NOT EXISTS idx_document_versions_version ON document_versions (document_id, version_number);
CREATE INDEX IF NOT EXISTS idx_document_versions_created ON document_versions (created_at);
CREATE INDEX IF NOT EXISTS idx_document_versions_user ON document_versions (created_by_user_id);

COMMENT ON TABLE document_versions IS 'История версий CCD документов';
COMMENT ON COLUMN document_versions.version_number IS 'Номер версии документа';
COMMENT ON COLUMN document_versions.document_snapshot IS 'Полный снимок документа на момент версии';
COMMENT ON COLUMN document_versions.changes_diff IS 'Изменения относительно предыдущей версии';
COMMENT ON COLUMN document_versions.is_major_version IS 'Является ли мажорной версией';

-- ============================================================================
-- AUDIT: LOGIN/SECURITY EVENTS
-- ============================================================================

CREATE TABLE IF NOT EXISTS security_events
(
    id                    BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    created_at            TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),

    user_id               INT REFERENCES users (id),
    organization_id       INT REFERENCES organizations (id),

    event_type            VARCHAR(100) NOT NULL,  -- login_success, login_failed, password_change, etc.
    severity              VARCHAR(50) NOT NULL,  -- info, warning, critical

    -- Details
    description           TEXT,

    -- Authentication
    auth_method           VARCHAR(50),  -- password, sso, api_key, etc.
    mfa_used              BOOLEAN,

    -- Technical
    ip_address            INET NOT NULL,
    user_agent            TEXT,
    country_code          VARCHAR(2),

    -- Result
    success               BOOLEAN NOT NULL,
    failure_reason        TEXT,

    -- Risk scoring
    risk_score            INT,  -- 0-100
    is_suspicious         BOOLEAN NOT NULL DEFAULT FALSE,

    meta                  jsonb NOT NULL DEFAULT '{}'
);

CREATE INDEX IF NOT EXISTS idx_security_events_created ON security_events (created_at);
CREATE INDEX IF NOT EXISTS idx_security_events_user ON security_events (user_id);
CREATE INDEX IF NOT EXISTS idx_security_events_org ON security_events (organization_id);
CREATE INDEX IF NOT EXISTS idx_security_events_type ON security_events (event_type);
CREATE INDEX IF NOT EXISTS idx_security_events_severity ON security_events (severity);
CREATE INDEX IF NOT EXISTS idx_security_events_suspicious ON security_events (is_suspicious) WHERE is_suspicious = TRUE;
CREATE INDEX IF NOT EXISTS idx_security_events_ip ON security_events (ip_address);

COMMENT ON TABLE security_events IS 'События безопасности (логины, изменения паролей, подозрительная активность)';
COMMENT ON COLUMN security_events.severity IS 'Уровень важности: info | warning | critical';
COMMENT ON COLUMN security_events.risk_score IS 'Оценка риска события (0-100)';
COMMENT ON COLUMN security_events.is_suspicious IS 'Флаг подозрительной активности';

-- ============================================================================
-- AUDIT: DATA ACCESS LOG (for sensitive data)
-- ============================================================================

CREATE TABLE IF NOT EXISTS data_access_log
(
    id                    BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    created_at            TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),

    user_id               INT NOT NULL REFERENCES users (id),
    organization_id       INT REFERENCES organizations (id),

    -- What was accessed
    entity_type           VARCHAR(100) NOT NULL,
    entity_id             BIGINT NOT NULL,

    -- How
    access_type           VARCHAR(50) NOT NULL,  -- read, export, print, api

    -- Sensitive fields accessed
    fields_accessed       TEXT[],

    -- Context
    reason                TEXT,  -- why was it accessed
    request_id            VARCHAR(255),

    -- Technical
    ip_address            INET,
    user_agent            TEXT,

    meta                  jsonb NOT NULL DEFAULT '{}'
);

CREATE INDEX IF NOT EXISTS idx_data_access_log_created ON data_access_log (created_at);
CREATE INDEX IF NOT EXISTS idx_data_access_log_user ON data_access_log (user_id);
CREATE INDEX IF NOT EXISTS idx_data_access_log_entity ON data_access_log (entity_type, entity_id);
CREATE INDEX IF NOT EXISTS idx_data_access_log_type ON data_access_log (access_type);

COMMENT ON TABLE data_access_log IS 'Лог доступа к конфиденциальным данным (для compliance)';
COMMENT ON COLUMN data_access_log.access_type IS 'Тип доступа: read | export | print | api';
COMMENT ON COLUMN data_access_log.fields_accessed IS 'Список полей, к которым был доступ';
COMMENT ON COLUMN data_access_log.reason IS 'Причина доступа к данным';

-- ============================================================================
-- ANALYTICS: DASHBOARD TEMPLATES
-- ============================================================================

CREATE TABLE IF NOT EXISTS dashboard_templates
(
    id                    INT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    created_at            TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at            TIMESTAMP WITH TIME ZONE,
    deleted_at            TIMESTAMP WITH TIME ZONE,
    status                entity_status NOT NULL DEFAULT 'active',

    name                  VARCHAR(255) NOT NULL,
    description           TEXT,

    -- Access control
    is_public             BOOLEAN NOT NULL DEFAULT FALSE,
    created_by_user_id    INT REFERENCES users (id),
    organization_id       INT REFERENCES organizations (id),

    -- Dashboard config
    layout                jsonb NOT NULL,  -- grid layout, widget positions
    widgets               jsonb NOT NULL,  -- widget configurations

    -- Filters/params
    default_filters       jsonb NOT NULL DEFAULT '{}',

    meta                  jsonb NOT NULL DEFAULT '{}'
);

CREATE INDEX IF NOT EXISTS idx_dashboards_org ON dashboard_templates (organization_id);
CREATE INDEX IF NOT EXISTS idx_dashboards_created_by ON dashboard_templates (created_by_user_id);
CREATE INDEX IF NOT EXISTS idx_dashboards_public ON dashboard_templates (is_public) WHERE is_public = TRUE;

COMMENT ON TABLE dashboard_templates IS 'Шаблоны дашбордов для аналитики';
COMMENT ON COLUMN dashboard_templates.layout IS 'Конфигурация расположения виджетов';
COMMENT ON COLUMN dashboard_templates.widgets IS 'Конфигурация виджетов дашборда';

-- ============================================================================
-- ANALYTICS: SAVED REPORTS
-- ============================================================================

CREATE TABLE IF NOT EXISTS saved_reports
(
    id                    BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    created_at            TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at            TIMESTAMP WITH TIME ZONE,
    deleted_at            TIMESTAMP WITH TIME ZONE,
    status                entity_status NOT NULL DEFAULT 'active',

    name                  VARCHAR(255) NOT NULL,
    description           TEXT,

    user_id               INT NOT NULL REFERENCES users (id),
    organization_id       INT REFERENCES organizations (id),

    -- Report config
    report_type           VARCHAR(100) NOT NULL,  -- ccd_summary, payment_report, ocr_usage, etc.
    parameters            jsonb NOT NULL DEFAULT '{}',
    filters               jsonb NOT NULL DEFAULT '{}',

    -- Scheduling
    is_scheduled          BOOLEAN NOT NULL DEFAULT FALSE,
    schedule_cron         VARCHAR(100),  -- cron expression

    -- Export format
    export_format         VARCHAR(50),  -- pdf, xlsx, csv

    -- Sharing
    is_shared             BOOLEAN NOT NULL DEFAULT FALSE,
    shared_with_user_ids  INT[],

    last_generated_at     TIMESTAMP WITH TIME ZONE,

    meta                  jsonb NOT NULL DEFAULT '{}'
);

CREATE INDEX IF NOT EXISTS idx_saved_reports_user ON saved_reports (user_id);
CREATE INDEX IF NOT EXISTS idx_saved_reports_org ON saved_reports (organization_id);
CREATE INDEX IF NOT EXISTS idx_saved_reports_type ON saved_reports (report_type);
CREATE INDEX IF NOT EXISTS idx_saved_reports_scheduled ON saved_reports (is_scheduled) WHERE is_scheduled = TRUE;

COMMENT ON TABLE saved_reports IS 'Сохраненные отчеты с возможностью планирования';
COMMENT ON COLUMN saved_reports.schedule_cron IS 'Расписание в формате cron';
COMMENT ON COLUMN saved_reports.shared_with_user_ids IS 'Пользователи, с которыми отчет расшарен';
