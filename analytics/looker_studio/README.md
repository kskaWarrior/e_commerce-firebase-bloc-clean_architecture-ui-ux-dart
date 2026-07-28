# analytics/looker_studio

Everything needed to build the store analytics report that the admin
**Dashboard** page embeds. The report runs on the `sales_analytics` BigQuery
dataset that the Cloud Functions in [`functions/src/index.ts`](../../functions/src/index.ts)
populate from every order.

| File | What it is |
|---|---|
| [`reporting_views.sql`](./reporting_views.sql) | BigQuery views (`v_orders`, `v_line_items`, `v_sales_daily`, `v_product_performance`) that shape the raw export into clean, cost-efficient, `store_id`-filterable report sources. |
| [`BUILD_GUIDE.md`](./BUILD_GUIDE.md) | Step-by-step Looker Studio build: a one-click bootstrap URL, chart-by-chart recipes for all four sections, the `@storeId` parameter setup that matches the app's embed URL, and how to enable embedding + wire it into admin Settings. |

## Quick start

1. Create the views (region `southamerica-east1`):
   ```bash
   bq query --use_legacy_sql=false --location=southamerica-east1 < analytics/looker_studio/reporting_views.sql
   ```
2. Follow [`BUILD_GUIDE.md`](./BUILD_GUIDE.md) — open the bootstrap link, add the
   tiles, set up the `storeId` parameter, enable embedding.
3. Paste the embed URL into the admin **Settings → Analytics dashboard** field.

> The `storeId` URL parameter filters the default view but is not a hard
> security boundary; production multi-tenant use needs BigQuery/Looker
> row-level security. See the caveat in the build guide.
