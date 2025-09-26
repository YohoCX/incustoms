-- Analytics materialized views for CCD creation stats
-- Breakdowns by period (daily/weekly/monthly/yearly), by actor scope
-- (individual user, user within organization, organization aggregate),
-- grouped into statuses: completed, pending, failed.

-- Helper: normalize free-text status into 3 buckets
-- We keep logic inline in views via CASE expression.

-- Daily analytics
CREATE MATERIALIZED VIEW IF NOT EXISTS ccd_analytics_daily AS
SELECT
  date_trunc('day', d.created_at)::date                  AS period_start,
  'daily'::text                                          AS period_type,
  s.actor_scope,
  s.organization_id,
  s.user_id,
  CASE
    WHEN lower(coalesce(d.status, '')) IN ('completed','succeeded','done','approved','accepted') THEN 'completed'
    WHEN lower(coalesce(d.status, '')) IN ('failed','rejected','canceled','cancelled','error') THEN 'failed'
    ELSE 'pending'
  END AS status_group,
  count(*) AS ccd_count
FROM ccd_documents d
JOIN (
  -- individuals (by user, no org)
  SELECT id AS doc_id, 'user'::text AS actor_scope, NULL::int AS organization_id, created_by_user_id AS user_id
  FROM ccd_documents
  WHERE created_by_user_id IS NOT NULL AND organization_id IS NULL
  UNION ALL
  -- organization users (by user within org)
  SELECT id, 'org_user'::text, organization_id, created_by_user_id
  FROM ccd_documents
  WHERE organization_id IS NOT NULL AND created_by_user_id IS NOT NULL
  UNION ALL
  -- organization aggregate (by org only)
  SELECT id, 'organization'::text, organization_id, NULL::int
  FROM ccd_documents
  WHERE organization_id IS NOT NULL
) s ON s.doc_id = d.id
GROUP BY 1,2,3,4,5,6;

-- Comments: ccd_analytics_daily
COMMENT ON MATERIALIZED VIEW ccd_analytics_daily IS 'Ежедневная аналитика по созданным CCD: разбивка по статусам и акторскому скоупу (пользователь, пользователь в орг., организация)';
COMMENT ON COLUMN ccd_analytics_daily.period_start IS 'Начало периода (день)';
COMMENT ON COLUMN ccd_analytics_daily.period_type IS 'Тип периода: daily';
COMMENT ON COLUMN ccd_analytics_daily.actor_scope IS 'Скоуп актора: user | org_user | organization';
COMMENT ON COLUMN ccd_analytics_daily.organization_id IS 'Идентификатор организации (если применимо)';
COMMENT ON COLUMN ccd_analytics_daily.user_id IS 'Идентификатор пользователя (если применимо)';
COMMENT ON COLUMN ccd_analytics_daily.status_group IS 'Группа статусов: completed | pending | failed';
COMMENT ON COLUMN ccd_analytics_daily.ccd_count IS 'Количество CCD за период/скоуп/статус';

CREATE INDEX IF NOT EXISTS idx_ccd_analytics_daily_period ON ccd_analytics_daily (period_start);
CREATE INDEX IF NOT EXISTS idx_ccd_analytics_daily_scope ON ccd_analytics_daily (actor_scope);
CREATE INDEX IF NOT EXISTS idx_ccd_analytics_daily_org ON ccd_analytics_daily (organization_id);
CREATE INDEX IF NOT EXISTS idx_ccd_analytics_daily_user ON ccd_analytics_daily (user_id);
CREATE INDEX IF NOT EXISTS idx_ccd_analytics_daily_status ON ccd_analytics_daily (status_group);

-- Weekly analytics
CREATE MATERIALIZED VIEW IF NOT EXISTS ccd_analytics_weekly AS
SELECT
  date_trunc('week', d.created_at)::date                 AS period_start,
  'weekly'::text                                         AS period_type,
  s.actor_scope,
  s.organization_id,
  s.user_id,
  CASE
    WHEN lower(coalesce(d.status, '')) IN ('completed','succeeded','done','approved','accepted') THEN 'completed'
    WHEN lower(coalesce(d.status, '')) IN ('failed','rejected','canceled','cancelled','error') THEN 'failed'
    ELSE 'pending'
  END AS status_group,
  count(*) AS ccd_count
FROM ccd_documents d
JOIN (
  SELECT id AS doc_id, 'user'::text AS actor_scope, NULL::int AS organization_id, created_by_user_id AS user_id
  FROM ccd_documents
  WHERE created_by_user_id IS NOT NULL AND organization_id IS NULL
  UNION ALL
  SELECT id, 'org_user'::text, organization_id, created_by_user_id
  FROM ccd_documents
  WHERE organization_id IS NOT NULL AND created_by_user_id IS NOT NULL
  UNION ALL
  SELECT id, 'organization'::text, organization_id, NULL::int
  FROM ccd_documents
  WHERE organization_id IS NOT NULL
) s ON s.doc_id = d.id
GROUP BY 1,2,3,4,5,6;

-- Comments: ccd_analytics_weekly
COMMENT ON MATERIALIZED VIEW ccd_analytics_weekly IS 'Еженедельная аналитика по созданным CCD: разбивка по статусам и акторскому скоупу (пользователь, пользователь в орг., организация)';
COMMENT ON COLUMN ccd_analytics_weekly.period_start IS 'Начало периода (неделя)';
COMMENT ON COLUMN ccd_analytics_weekly.period_type IS 'Тип периода: weekly';
COMMENT ON COLUMN ccd_analytics_weekly.actor_scope IS 'Скоуп актора: user | org_user | organization';
COMMENT ON COLUMN ccd_analytics_weekly.organization_id IS 'Идентификатор организации (если применимо)';
COMMENT ON COLUMN ccd_analytics_weekly.user_id IS 'Идентификатор пользователя (если применимо)';
COMMENT ON COLUMN ccd_analytics_weekly.status_group IS 'Группа статусов: completed | pending | failed';
COMMENT ON COLUMN ccd_analytics_weekly.ccd_count IS 'Количество CCD за период/скоуп/статус';

CREATE INDEX IF NOT EXISTS idx_ccd_analytics_weekly_period ON ccd_analytics_weekly (period_start);
CREATE INDEX IF NOT EXISTS idx_ccd_analytics_weekly_scope ON ccd_analytics_weekly (actor_scope);
CREATE INDEX IF NOT EXISTS idx_ccd_analytics_weekly_org ON ccd_analytics_weekly (organization_id);
CREATE INDEX IF NOT EXISTS idx_ccd_analytics_weekly_user ON ccd_analytics_weekly (user_id);
CREATE INDEX IF NOT EXISTS idx_ccd_analytics_weekly_status ON ccd_analytics_weekly (status_group);

-- Monthly analytics
CREATE MATERIALIZED VIEW IF NOT EXISTS ccd_analytics_monthly AS
SELECT
  date_trunc('month', d.created_at)::date                AS period_start,
  'monthly'::text                                        AS period_type,
  s.actor_scope,
  s.organization_id,
  s.user_id,
  CASE
    WHEN lower(coalesce(d.status, '')) IN ('completed','succeeded','done','approved','accepted') THEN 'completed'
    WHEN lower(coalesce(d.status, '')) IN ('failed','rejected','canceled','cancelled','error') THEN 'failed'
    ELSE 'pending'
  END AS status_group,
  count(*) AS ccd_count
FROM ccd_documents d
JOIN (
  SELECT id AS doc_id, 'user'::text AS actor_scope, NULL::int AS organization_id, created_by_user_id AS user_id
  FROM ccd_documents
  WHERE created_by_user_id IS NOT NULL AND organization_id IS NULL
  UNION ALL
  SELECT id, 'org_user'::text, organization_id, created_by_user_id
  FROM ccd_documents
  WHERE organization_id IS NOT NULL AND created_by_user_id IS NOT NULL
  UNION ALL
  SELECT id, 'organization'::text, organization_id, NULL::int
  FROM ccd_documents
  WHERE organization_id IS NOT NULL
) s ON s.doc_id = d.id
GROUP BY 1,2,3,4,5,6;

-- Comments: ccd_analytics_monthly
COMMENT ON MATERIALIZED VIEW ccd_analytics_monthly IS 'Ежемесячная аналитика по созданным CCD: разбивка по статусам и акторскому скоупу (пользователь, пользователь в орг., организация)';
COMMENT ON COLUMN ccd_analytics_monthly.period_start IS 'Начало периода (месяц)';
COMMENT ON COLUMN ccd_analytics_monthly.period_type IS 'Тип периода: monthly';
COMMENT ON COLUMN ccd_analytics_monthly.actor_scope IS 'Скоуп актора: user | org_user | organization';
COMMENT ON COLUMN ccd_analytics_monthly.organization_id IS 'Идентификатор организации (если применимо)';
COMMENT ON COLUMN ccd_analytics_monthly.user_id IS 'Идентификатор пользователя (если применимо)';
COMMENT ON COLUMN ccd_analytics_monthly.status_group IS 'Группа статусов: completed | pending | failed';
COMMENT ON COLUMN ccd_analytics_monthly.ccd_count IS 'Количество CCD за период/скоуп/статус';

CREATE INDEX IF NOT EXISTS idx_ccd_analytics_monthly_period ON ccd_analytics_monthly (period_start);
CREATE INDEX IF NOT EXISTS idx_ccd_analytics_monthly_scope ON ccd_analytics_monthly (actor_scope);
CREATE INDEX IF NOT EXISTS idx_ccd_analytics_monthly_org ON ccd_analytics_monthly (organization_id);
CREATE INDEX IF NOT EXISTS idx_ccd_analytics_monthly_user ON ccd_analytics_monthly (user_id);
CREATE INDEX IF NOT EXISTS idx_ccd_analytics_monthly_status ON ccd_analytics_monthly (status_group);

-- Yearly analytics
CREATE MATERIALIZED VIEW IF NOT EXISTS ccd_analytics_yearly AS
SELECT
  date_trunc('year', d.created_at)::date                 AS period_start,
  'yearly'::text                                         AS period_type,
  s.actor_scope,
  s.organization_id,
  s.user_id,
  CASE
    WHEN lower(coalesce(d.status, '')) IN ('completed','succeeded','done','approved','accepted') THEN 'completed'
    WHEN lower(coalesce(d.status, '')) IN ('failed','rejected','canceled','cancelled','error') THEN 'failed'
    ELSE 'pending'
  END AS status_group,
  count(*) AS ccd_count
FROM ccd_documents d
JOIN (
  SELECT id AS doc_id, 'user'::text AS actor_scope, NULL::int AS organization_id, created_by_user_id AS user_id
  FROM ccd_documents
  WHERE created_by_user_id IS NOT NULL AND organization_id IS NULL
  UNION ALL
  SELECT id, 'org_user'::text, organization_id, created_by_user_id
  FROM ccd_documents
  WHERE organization_id IS NOT NULL AND created_by_user_id IS NOT NULL
  UNION ALL
  SELECT id, 'organization'::text, organization_id, NULL::int
  FROM ccd_documents
  WHERE organization_id IS NOT NULL
) s ON s.doc_id = d.id
GROUP BY 1,2,3,4,5,6;

-- Comments: ccd_analytics_yearly
COMMENT ON MATERIALIZED VIEW ccd_analytics_yearly IS 'Годовая аналитика по созданным CCD: разбивка по статусам и акторскому скоупу (пользователь, пользователь в орг., организация)';
COMMENT ON COLUMN ccd_analytics_yearly.period_start IS 'Начало периода (год)';
COMMENT ON COLUMN ccd_analytics_yearly.period_type IS 'Тип периода: yearly';
COMMENT ON COLUMN ccd_analytics_yearly.actor_scope IS 'Скоуп актора: user | org_user | organization';
COMMENT ON COLUMN ccd_analytics_yearly.organization_id IS 'Идентификатор организации (если применимо)';
COMMENT ON COLUMN ccd_analytics_yearly.user_id IS 'Идентификатор пользователя (если применимо)';
COMMENT ON COLUMN ccd_analytics_yearly.status_group IS 'Группа статусов: completed | pending | failed';
COMMENT ON COLUMN ccd_analytics_yearly.ccd_count IS 'Количество CCD за период/скоуп/статус';

CREATE INDEX IF NOT EXISTS idx_ccd_analytics_yearly_period ON ccd_analytics_yearly (period_start);
CREATE INDEX IF NOT EXISTS idx_ccd_analytics_yearly_scope ON ccd_analytics_yearly (actor_scope);
CREATE INDEX IF NOT EXISTS idx_ccd_analytics_yearly_org ON ccd_analytics_yearly (organization_id);
CREATE INDEX IF NOT EXISTS idx_ccd_analytics_yearly_user ON ccd_analytics_yearly (user_id);
CREATE INDEX IF NOT EXISTS idx_ccd_analytics_yearly_status ON ccd_analytics_yearly (status_group);

-- Note: refresh strategy should be scheduled in the app (REFRESH MATERIALIZED VIEW CONCURRENTLY ...)
-- Optionally add unique indexes if needed for upsert-like refreshes.
