-- ============================================================================
-- Looker Studio reporting views for the sales_analytics dataset
-- ============================================================================
-- These views shape the raw BigQuery export (written by the Cloud Functions in
-- functions/src/index.ts) into clean, report-ready sources for Looker Studio.
--
-- IMPORTANT — schema reality:
--   The live `sales` / `sales_products` tables were created before a top-level
--   `storeId` column existed, and inserts use ignoreUnknownValues, so there is
--   NO `storeId` column in either table. We recover the tenant id from the
--   `firestoreCollection` path (`stores/<storeId>/sales`) on `sales`, and let
--   `sales_products` inherit it by joining on `salesId`. `sales_products` also
--   uses `salesId` (not `orderId`). No table migration is required.
--
-- IMPORTANT — append-only history:
--   The export triggers are `onDocumentWritten` (functions/src/index.ts), so a
--   sale is re-exported whenever its exported content changes — notably when
--   `createPaymentPreference` replaces the client-authored money fields with
--   server-recomputed ones. The tables are therefore append-only revision
--   history: several rows can share one sale. Every view below keeps only the
--   newest revision per sale (`exportedAt` is an ISO-8601 UTC string, so it
--   sorts lexicographically; `exportEventId` identifies one export run and
--   breaks ties). Query the raw tables directly only if you want history.
--   The two tables need different revision keys, because their live schemas
--   differ (verified against INFORMATION_SCHEMA, not assumed):
--     sales           saleDocumentId              (exportEventId breaks ties)
--     sales_products  salesId + productIndex      (it has NEITHER
--                     saleDocumentId NOR exportEventId, so there is no batch
--                     identity to rank by; one row per productIndex per
--                     export makes this pair the row identity instead)
--   Before adding a column to either table, check it exists there: inserts
--   use ignoreUnknownValues, so a field the functions write is silently
--   dropped unless the column was created first.
--
-- Why views:
--   * Keep business logic (store_id derivation, date bucketing, age bands) in
--     one version-controlled place instead of scattered Looker fields.
--   * Control query cost — charts scan narrow, typed columns.
--   * Expose `store_id` so a Looker `@storeId` parameter can filter to one
--     tenant (see BUILD_GUIDE.md). Privacy: raw userId / userName are NOT
--     exposed — customers appear only as an unsalted SHA256 `user_key` plus
--     aggregate gender / age band.
--
-- Grain:
--   v_orders              one row per order         (from `sales`)
--   v_line_items          one row per line item     (from `sales_products`)
--   v_sales_daily         one row per store/day      (rollup, cheap time series)
--   v_product_performance one row per store/product  (rollup, cheap top-N)
--
-- Region: the dataset lives in southamerica-east1; run these there.
-- Timezone: days are bucketed in America/Sao_Paulo so "today" matches local
--   store hours rather than UTC.
--
-- Before running: replace the project id below if your BigQuery billing
-- project differs from `ecommerceapp-auth-db-cleana`.
--
-- Run:  bq query --use_legacy_sql=false --location=southamerica-east1 \
--         < analytics/looker_studio/reporting_views.sql
--       (or paste every statement into the BigQuery Studio console)
-- ============================================================================

-- ---------------------------------------------------------------- v_orders ---
CREATE OR REPLACE VIEW `ecommerceapp-auth-db-cleana.sales_analytics.v_orders` AS
WITH orders AS (
  SELECT
    -- `stores/<storeId>/sales` -> element [1] is the storeId.
    SPLIT(firestoreCollection, '/')[SAFE_OFFSET(1)] AS store_id,
    id AS order_id,
    createdDate,
    totalPrice,
    price,
    discountedPrice,
    discount,
    freight,
    paymentMethod,
    installmentsNumber,
    userGender,
    userId,
    CASE
      WHEN userBirthDate IS NULL THEN NULL
      ELSE DATE_DIFF(
        CURRENT_DATE('America/Sao_Paulo'),
        DATE(userBirthDate, 'America/Sao_Paulo'),
        YEAR)
    END AS age,
    ROW_NUMBER() OVER (
      PARTITION BY SPLIT(firestoreCollection, '/')[SAFE_OFFSET(1)], userId
      ORDER BY createdDate
    ) AS customer_order_seq
  FROM `ecommerceapp-auth-db-cleana.sales_analytics.sales`
  -- Keep only the newest revision of each sale.
  QUALIFY ROW_NUMBER() OVER (
    PARTITION BY saleDocumentId
    ORDER BY exportedAt DESC, exportEventId DESC
  ) = 1
)
SELECT
  store_id,
  DATE(createdDate, 'America/Sao_Paulo')             AS order_date,
  createdDate                                        AS order_ts,
  order_id,
  totalPrice                                         AS revenue,
  price                                              AS gross,
  discountedPrice                                    AS net,
  discount,
  freight,
  paymentMethod                                      AS payment_method,
  installmentsNumber                                 AS installments,
  userGender                                         AS user_gender,
  age,
  CASE
    WHEN age IS NULL THEN 'Unknown'
    WHEN age < 18 THEN '<18'
    WHEN age < 25 THEN '18-24'
    WHEN age < 35 THEN '25-34'
    WHEN age < 45 THEN '35-44'
    WHEN age < 55 THEN '45-54'
    ELSE '55+'
  END                                                AS age_band,
  -- Pseudonymous customer key: lets you COUNT_DISTINCT customers and split
  -- new vs returning without exposing the real user id or name.
  TO_HEX(SHA256(COALESCE(userId, '')))               AS user_key,
  (customer_order_seq > 1)                           AS is_returning
FROM orders;

-- ------------------------------------------------------------ v_line_items ---
-- sales_products has no storeId column; inherit it from the parent sale
-- (sp.salesId -> sales.id) via its firestoreCollection path.
CREATE OR REPLACE VIEW `ecommerceapp-auth-db-cleana.sales_analytics.v_line_items` AS
SELECT
  SPLIT(s.firestoreCollection, '/')[SAFE_OFFSET(1)]  AS store_id,
  DATE(sp.createdDate, 'America/Sao_Paulo')          AS order_date,
  sp.salesId                                         AS order_id,
  sp.productId                                       AS product_id,
  sp.title,
  sp.categoryName                                    AS category_name,
  sp.color,
  sp.size,
  sp.quantity,
  sp.unitPrice                                       AS unit_price,
  sp.unitDiscounted                                  AS unit_discounted,
  sp.totalPrice                                      AS line_revenue
FROM (
  -- Keep only the newest revision of each line item. This table has neither
  -- `saleDocumentId` nor `exportEventId`, so there is no batch identity to
  -- rank by — but every export of a sale writes exactly one row per
  -- `productIndex`, which makes (salesId, productIndex) the row's identity
  -- across revisions. Keying on that rather than on a batch also means a
  -- sale exported only once keeps all of its lines, whatever their
  -- individual timestamps.
  SELECT *
  FROM `ecommerceapp-auth-db-cleana.sales_analytics.sales_products`
  QUALIFY ROW_NUMBER() OVER (
    PARTITION BY salesId, productIndex
    ORDER BY exportedAt DESC
  ) = 1
) sp
LEFT JOIN (
  SELECT *
  FROM `ecommerceapp-auth-db-cleana.sales_analytics.sales`
  QUALIFY ROW_NUMBER() OVER (
    PARTITION BY saleDocumentId
    ORDER BY exportedAt DESC, exportEventId DESC
  ) = 1
) s
  ON s.id = sp.salesId;

-- ------------------------------------------------------------ v_sales_daily --
-- Per store/day rollup. Cheap backing source for the revenue time series.
CREATE OR REPLACE VIEW `ecommerceapp-auth-db-cleana.sales_analytics.v_sales_daily` AS
WITH ord AS (
  SELECT
    store_id,
    order_date,
    COUNT(order_id)          AS orders,
    SUM(revenue)             AS revenue,
    SUM(discount)            AS discount,
    COUNT(DISTINCT user_key) AS customers
  FROM `ecommerceapp-auth-db-cleana.sales_analytics.v_orders`
  GROUP BY store_id, order_date
),
units AS (
  SELECT
    store_id,
    order_date,
    SUM(quantity) AS units
  FROM `ecommerceapp-auth-db-cleana.sales_analytics.v_line_items`
  GROUP BY store_id, order_date
)
SELECT
  ord.store_id,
  ord.order_date,
  ord.orders,
  ord.revenue,
  ord.discount,
  ord.customers,
  SAFE_DIVIDE(ord.revenue, ord.orders) AS aov,
  units.units
FROM ord
LEFT JOIN units USING (store_id, order_date);

-- -------------------------------------------------- v_product_performance ---
-- Per store/product rollup. Cheap backing source for top-products tables.
CREATE OR REPLACE VIEW `ecommerceapp-auth-db-cleana.sales_analytics.v_product_performance` AS
SELECT
  store_id,
  product_id,
  ANY_VALUE(title)         AS title,
  ANY_VALUE(category_name) AS category_name,
  SUM(quantity)            AS units,
  SUM(line_revenue)        AS revenue,
  COUNT(DISTINCT order_id) AS orders
FROM `ecommerceapp-auth-db-cleana.sales_analytics.v_line_items`
GROUP BY store_id, product_id;
