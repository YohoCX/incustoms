-- Audit log for CCD documents and items
-- Captures who changed what, when, and how, for traceability and reviews.

CREATE TABLE IF NOT EXISTS ccd_audit_events
(
    id                 INT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    created_at         timestamptz NOT NULL DEFAULT NOW(),
    updated_at         timestamptz,
    deleted_at         timestamptz,
    status             TEXT        NOT NULL DEFAULT 'active', -- 'active' | 'deleted' | 'archived'

    -- Actor and scope
    organization_id    INT                 REFERENCES organizations (id),
    user_id            INT                 REFERENCES users (id),

    -- Targets
    document_id        INT         NOT NULL REFERENCES ccd_documents (id) ON DELETE CASCADE,
    item_id            INT                 REFERENCES ccd_items (id)      ON DELETE SET NULL,

    -- Per-field context (optional for coarse actions)
    graph_no           INT,                               -- e.g., 22, 23, 31...
    field_key          TEXT,                              -- canonical model field name

    -- Action and source
    action             TEXT        NOT NULL,              -- 'create' | 'update' | 'delete' | 'apply_template' | 'apply_ocr' | 'status_change' | 'system'
    source             TEXT        NOT NULL DEFAULT 'manual', -- 'manual' | 'ocr' | 'template' | 'api' | 'system'

    -- Values
    old_value          jsonb       NOT NULL DEFAULT 'null',
    new_value          jsonb       NOT NULL DEFAULT 'null',

    -- Extra context
    reason             TEXT,                              -- free text comment
    meta               jsonb       NOT NULL DEFAULT '{}'
);

COMMENT ON TABLE ccd_audit_events IS 'Аудит-лог изменений по CCD: кто/когда/что изменил, источник (ручной ввод/ОCR/шаблон), старое и новое значения';
COMMENT ON COLUMN ccd_audit_events.graph_no IS 'Номер графы (при поле-ориентированном событии)';
COMMENT ON COLUMN ccd_audit_events.field_key IS 'Каноническое имя поля модели (например, contract_currency_id, trade_name)';
COMMENT ON COLUMN ccd_audit_events.action IS 'Тип события: create | update | delete | apply_template | apply_ocr | status_change | system';
COMMENT ON COLUMN ccd_audit_events.source IS 'Источник изменения: manual | ocr | template | api | system';
COMMENT ON COLUMN ccd_audit_events.old_value IS 'Старое значение (JSON; может быть null)';
COMMENT ON COLUMN ccd_audit_events.new_value IS 'Новое значение (JSON; может быть null)';

CREATE INDEX IF NOT EXISTS idx_ccd_audit_created_at ON ccd_audit_events (created_at);
CREATE INDEX IF NOT EXISTS idx_ccd_audit_document ON ccd_audit_events (document_id);
CREATE INDEX IF NOT EXISTS idx_ccd_audit_item ON ccd_audit_events (item_id);
CREATE INDEX IF NOT EXISTS idx_ccd_audit_user ON ccd_audit_events (user_id);
CREATE INDEX IF NOT EXISTS idx_ccd_audit_field ON ccd_audit_events (graph_no, field_key);
CREATE INDEX IF NOT EXISTS idx_ccd_audit_action ON ccd_audit_events (action);
CREATE INDEX IF NOT EXISTS idx_ccd_audit_source ON ccd_audit_events (source);
CREATE INDEX IF NOT EXISTS idx_ccd_audit_meta_gin ON ccd_audit_events USING GIN (meta);
CREATE INDEX IF NOT EXISTS idx_ccd_audit_old_gin ON ccd_audit_events USING GIN (old_value);
CREATE INDEX IF NOT EXISTS idx_ccd_audit_new_gin ON ccd_audit_events USING GIN (new_value);

-- Optional: separate status history for quick queries and constraints
CREATE TABLE IF NOT EXISTS ccd_status_history
(
    id                 INT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    created_at         timestamptz NOT NULL DEFAULT NOW(),

    document_id        INT         NOT NULL REFERENCES ccd_documents (id) ON DELETE CASCADE,
    user_id            INT                 REFERENCES users (id),

    old_status         TEXT,
    new_status         TEXT        NOT NULL,

    reason             TEXT,
    meta               jsonb       NOT NULL DEFAULT '{}'
);

COMMENT ON TABLE ccd_status_history IS 'История смены статусов CCD (оперативные запросы по статусам)';
CREATE INDEX IF NOT EXISTS idx_ccd_status_history_doc ON ccd_status_history (document_id);
CREATE INDEX IF NOT EXISTS idx_ccd_status_history_created ON ccd_status_history (created_at);

