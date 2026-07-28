-- ============================================================================
-- Optional hardening: add a native `storeId` column to the analytics tables
-- ============================================================================
-- The live `sales` / `sales_products` tables were created before a top-level
-- `storeId` field existed, so today the reporting views derive `store_id` from
-- the `firestoreCollection` path. That works, but a native `storeId` column is
-- cleaner and is the foundation for real row-level security (RLS) keyed to the
-- tenant — the proper production fix for multi-tenant isolation.
--
-- After this runs:
--   * NEW rows from the Cloud Functions populate `storeId` automatically — the
--     column now exists, so the export's ignoreUnknownValues no longer drops
--     the `storeId` the code already writes (functions/src/index.ts).
--   * EXISTING rows are backfilled: `sales` from its `firestoreCollection`
--     path, `sales_products` by joining to its parent sale on `salesId`.
--
-- Safe to re-run: ADD COLUMN IF NOT EXISTS is a no-op if present, and the
-- backfills only touch rows where storeId IS NULL.
--
-- Run in project ecommerceapp-auth-db-cleana (dataset region southamerica-east1):
--   bq query --use_legacy_sql=false --location=southamerica-east1 \
--     < analytics/looker_studio/add_store_id_column.sql
--   (or paste every statement into the BigQuery Studio console)
--
-- NOTE: the reporting views in reporting_views.sql keep deriving store_id from
-- firestoreCollection, so they work whether or not this migration has run — this
-- is purely to make the canonical `storeId` column available (RLS, ad-hoc
-- queries, future exports). No view change is required.
-- ============================================================================

-- 1. Add the columns (no-op if they already exist).
ALTER TABLE `ecommerceapp-auth-db-cleana.sales_analytics.sales`
  ADD COLUMN IF NOT EXISTS storeId STRING;

ALTER TABLE `ecommerceapp-auth-db-cleana.sales_analytics.sales_products`
  ADD COLUMN IF NOT EXISTS storeId STRING;

-- 2. Backfill sales.storeId from the firestoreCollection path (stores/<id>/sales).
UPDATE `ecommerceapp-auth-db-cleana.sales_analytics.sales`
SET storeId = SPLIT(firestoreCollection, '/')[SAFE_OFFSET(1)]
WHERE storeId IS NULL AND firestoreCollection IS NOT NULL;

-- 3. Backfill sales_products.storeId from its parent sale (salesId -> sales.id).
UPDATE `ecommerceapp-auth-db-cleana.sales_analytics.sales_products` sp
SET storeId = SPLIT(s.firestoreCollection, '/')[SAFE_OFFSET(1)]
FROM `ecommerceapp-auth-db-cleana.sales_analytics.sales` s
WHERE s.id = sp.salesId AND sp.storeId IS NULL;
