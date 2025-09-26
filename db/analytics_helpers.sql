-- Helper functions for analytics maintenance

-- Function: refresh all CCD analytics materialized views
-- Usage: SELECT refresh_ccd_analytics_all();
--        SELECT refresh_ccd_analytics_all(TRUE); -- attempts CONCURRENTLY
-- Note: CONCURRENTLY requires a unique index on the materialized view;
-- since views here do not define such indexes, use use_concurrently=FALSE.

CREATE OR REPLACE FUNCTION refresh_ccd_analytics_all(use_concurrently boolean DEFAULT FALSE)
RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN
  IF use_concurrently THEN
    -- Requires unique indexes on MVs; may fail if not present
    EXECUTE 'REFRESH MATERIALIZED VIEW CONCURRENTLY ccd_analytics_daily';
    EXECUTE 'REFRESH MATERIALIZED VIEW CONCURRENTLY ccd_analytics_weekly';
    EXECUTE 'REFRESH MATERIALIZED VIEW CONCURRENTLY ccd_analytics_monthly';
    EXECUTE 'REFRESH MATERIALIZED VIEW CONCURRENTLY ccd_analytics_yearly';
  ELSE
    EXECUTE 'REFRESH MATERIALIZED VIEW ccd_analytics_daily';
    EXECUTE 'REFRESH MATERIALIZED VIEW ccd_analytics_weekly';
    EXECUTE 'REFRESH MATERIALIZED VIEW ccd_analytics_monthly';
    EXECUTE 'REFRESH MATERIALIZED VIEW ccd_analytics_yearly';
  END IF;
END;
$$;

COMMENT ON FUNCTION refresh_ccd_analytics_all(boolean) IS 'Обновляет все мат. представления аналитики CCD (daily/weekly/monthly/yearly). Параметр use_concurrently включает CONCURRENTLY при наличии уникальных индексов.';

