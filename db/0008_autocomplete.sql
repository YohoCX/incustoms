-- Lean autocomplete store for manual inputs
-- Single table, per-field suggestions with dedupe, usage ranking, and starring.

CREATE TABLE IF NOT EXISTS user_field_suggestions
(
    id                 INT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    created_at         timestamptz NOT NULL DEFAULT NOW(),
    updated_at         timestamptz,
    deleted_at         timestamptz,
    status             TEXT        NOT NULL DEFAULT 'active', -- 'active' | 'deleted' | 'archived'

    user_id            INT         NOT NULL REFERENCES users (id),
    organization_id    INT                 REFERENCES organizations (id), -- optional tenant scope

    graph_no           INT         NOT NULL,                -- e.g., 22, 31, 32
    field_key          TEXT        NOT NULL,                -- e.g., 'contract_currency_id', 'trade_name'

    value_text         TEXT,                                -- normalized string form (for prefix search)
    value_json         jsonb       NOT NULL DEFAULT '{}',   -- normalized structured value (ids/codes/amount)

    value_fingerprint  TEXT        NOT NULL,                -- dedupe key; computed by backend canonicalization
    language           TEXT,                                -- optional: 'ru' | 'uz' | 'en'

    starred            BOOLEAN     NOT NULL DEFAULT FALSE,  -- user favorite
    usage_count        INT         NOT NULL DEFAULT 0,      -- increment when user selects from suggestions
    last_used_at       timestamptz,                         -- when selected from suggestions
    last_entered_at    timestamptz,                         -- when typed manually (source event)

    meta               jsonb       NOT NULL DEFAULT '{}'    -- optional context (post_id, regime, etc.)
);

COMMENT ON TABLE user_field_suggestions IS 'Персональные подсказки для автодополнения: значения, введенные вручную, со звездочкой и статистикой использования';
COMMENT ON COLUMN user_field_suggestions.value_fingerprint IS 'Канонический хеш значения для дедупликации на уровне user/graph/field';
COMMENT ON COLUMN user_field_suggestions.starred IS 'Отметка избранного пользователем';
COMMENT ON COLUMN user_field_suggestions.usage_count IS 'Счетчик применений подсказки (для ранжирования)';
COMMENT ON COLUMN user_field_suggestions.last_entered_at IS 'Последний ввод вручную (источник подсказки)';

-- Dedupe per user/graph/field/value
CREATE UNIQUE INDEX IF NOT EXISTS uq_user_field_suggestions_identity
  ON user_field_suggestions (user_id, graph_no, field_key, value_fingerprint)
  WHERE deleted_at IS NULL;

-- Search and ranking helpers
CREATE INDEX IF NOT EXISTS idx_user_field_suggestions_user ON user_field_suggestions (user_id);
CREATE INDEX IF NOT EXISTS idx_user_field_suggestions_org ON user_field_suggestions (organization_id);
CREATE INDEX IF NOT EXISTS idx_user_field_suggestions_field ON user_field_suggestions (graph_no, field_key);
CREATE INDEX IF NOT EXISTS idx_user_field_suggestions_starred ON user_field_suggestions (starred);
CREATE INDEX IF NOT EXISTS idx_user_field_suggestions_usage ON user_field_suggestions (usage_count DESC NULLS LAST);
CREATE INDEX IF NOT EXISTS idx_user_field_suggestions_last_used ON user_field_suggestions (last_used_at DESC NULLS LAST);
CREATE INDEX IF NOT EXISTS idx_user_field_suggestions_last_entered ON user_field_suggestions (last_entered_at DESC NULLS LAST);
CREATE INDEX IF NOT EXISTS idx_user_field_suggestions_text ON user_field_suggestions (lower(value_text));
CREATE INDEX IF NOT EXISTS idx_user_field_suggestions_value_json_gin ON user_field_suggestions USING GIN (value_json);

-- Upsert on manual input (example):
-- INSERT INTO user_field_suggestions (user_id, organization_id, graph_no, field_key, value_text, value_json, value_fingerprint, last_entered_at)
-- VALUES ($user_id, $org_id, $graph_no, $field_key, $value_text_norm, $value_json_norm, $fingerprint, NOW())
-- ON CONFLICT (user_id, graph_no, field_key, value_fingerprint)
-- DO UPDATE SET last_entered_at = NOW(), value_text = EXCLUDED.value_text, value_json = EXCLUDED.value_json, updated_at = NOW();

-- Bump on selection (example):
-- UPDATE user_field_suggestions
-- SET usage_count = usage_count + 1, last_used_at = NOW(), updated_at = NOW()
-- WHERE user_id = $user_id AND graph_no = $graph_no AND field_key = $field_key AND value_fingerprint = $fingerprint;

