# Building the store analytics report in Looker Studio

This guide recreates the admin **Dashboard** report on the `sales_analytics`
BigQuery dataset. Looker Studio (formerly Data Studio) has no full
create-a-report API, so the build is manual — but the views in
[`reporting_views.sql`](./reporting_views.sql) plus the bootstrap link below make
it quick, and every chart maps to a concrete field.

> **Looker Studio ≠ Looker.** This is the free Google BI tool at
> `lookerstudio.google.com`, not the enterprise LookML "Looker" product.

---

## 0. Prerequisites

1. You can query the `sales_analytics` dataset (project
   `ecommerceapp-auth-db-cleana`, region `southamerica-east1`).
2. Run the reporting views once:
   ```bash
   bq query --use_legacy_sql=false --location=southamerica-east1 < analytics/looker_studio/reporting_views.sql
   ```
   (or paste each statement into BigQuery Studio). This creates `v_orders`,
   `v_line_items`, `v_sales_daily`, `v_product_performance`.

---

## 1. Bootstrap the report (one click)

Open this URL — it creates a **new** report with `v_orders` (alias *Orders*) and
`v_orders` already wired as the BigQuery source, in edit mode:

```
https://lookerstudio.google.com/reporting/create?c.mode=edit&r.reportName=Store%20Analytics&ds.connector=bigQuery&ds.type=TABLE&ds.projectId=ecommerceapp-auth-db-cleana&ds.datasetId=sales_analytics&ds.tableId=v_orders&ds.datasourceName=Orders
```

> **Why one data source, and no `ds0`/`ds1` alias?** For a from-scratch report
> the Linking API uses the default report's single embedded source, addressed as
> plain `ds.` (no alias). The aliased `ds.ds0.` / `ds.ds1.` form only works when
> a **template report** already defines those aliases — using it on a blank
> create fails with *"ds0 is not a valid data source alias for this report."*
> So we wire `v_orders` here and add `v_line_items` in the editor (next step).

Then add the **second** data source inside the editor: **Resource → Manage
added data sources → Add a data source → BigQuery →** project
`ecommerceapp-auth-db-cleana` → dataset `sales_analytics` → table
**`v_line_items`** → Add.

**Fully manual alternative** (no URL — always works): go to
[lookerstudio.google.com](https://lookerstudio.google.com) → **Create → Report**
→ pick **BigQuery** → `ecommerceapp-auth-db-cleana` → `sales_analytics` →
**`v_orders`** → Add; then **Add data** again for **`v_line_items`**. If you
haven't run the views yet, pick the raw `sales` / `sales_products` tables
instead.

On first open, Looker Studio asks you to authorize the BigQuery connection —
approve it. (Replace `ecommerceapp-auth-db-cleana` above if your project id
differs.)

---

## 2. Add a date-range control

Insert → **Date range control**, drop it at the top. It drives every chart with
a date dimension. The default date dimension is `order_date`.

---

## 3. Chart recipes

Each tile below: **chart type** — *data source* → dimension / metric. All money
metrics are plain `SUM`/`COUNT` so the date range and store filter stay live.

### Executive KPIs + revenue trend
| Tile | Chart | Source | Setup |
|---|---|---|---|
| Total revenue | Scorecard | Orders | Metric `SUM(revenue)` |
| Orders | Scorecard | Orders | Metric `CTD(order_id)` (Count) |
| Avg order value | Scorecard | Orders | Metric = create field `AOV = SUM(revenue)/COUNT(order_id)` |
| Units sold | Scorecard | Line items | Metric `SUM(quantity)` |
| Revenue over time | Time series | Orders | Dimension `order_date`, metric `SUM(revenue)` |

> Prefer the `v_sales_daily` source for the time series if the dataset grows —
> it's pre-aggregated (`revenue`, `orders`, `aov`, `units`, `customers` per day).

### Product & category performance
| Tile | Chart | Source | Setup |
|---|---|---|---|
| Top products | Table (or bar) | Line items | Dimension `title`, metrics `SUM(line_revenue)`, `SUM(quantity)`; sort by revenue desc |
| Sales by category | Bar / pie | Line items | Dimension `category_name`, metric `SUM(line_revenue)` |
| Color / size split | Bar | Line items | Dimension `color` (or `size`), metric `SUM(quantity)` |

> Or use `v_product_performance` (already per-product: `units`, `revenue`,
> `orders`) for the top-products table.

### Payment & discounts
| Tile | Chart | Source | Setup |
|---|---|---|---|
| Payment mix | Pie / bar | Orders | Dimension `payment_method`, metric `SUM(revenue)` |
| Installments | Bar | Orders | Dimension `installments`, metric `CTD(order_id)` |
| Discount rate | Scorecard | Orders | Field `Discount rate = SUM(discount)/NULLIF(SUM(gross),0)`, format % |
| Freight collected | Scorecard | Orders | Metric `SUM(freight)` |

### Customer breakdown
| Tile | Chart | Source | Setup |
|---|---|---|---|
| By gender | Pie | Orders | Dimension `user_gender`, metric `SUM(revenue)` |
| By age band | Bar | Orders | Dimension `age_band`, metric `CTD(order_id)` |
| New vs returning | Bar / scorecard | Orders | Dimension `is_returning`, metric `COUNT_DISTINCT(user_key)` |

> **Privacy:** the views deliberately expose **no** customer name or raw id —
> only aggregate gender / age band and a hashed `user_key`. Even so, showing
> demographics to every store owner is a product decision in a white-label
> platform. Drop this section if you'd rather not surface it per tenant.

---

## 4. Filter each report to one store (the `@storeId` parameter)

The admin app embeds the report as `…<embedUrl>?params={"storeId":"<storeId>"}`
(see `_urlForStore` in `admin_dashboard_page.dart`). To make that URL parameter
actually filter the data, back the report with **custom-query** sources that
accept a `storeId` parameter:

1. **Resource → Manage added data sources → Add a data source → BigQuery →
   Custom query**, project `ecommerceapp-auth-db-cleana`. Enter:
   ```sql
   SELECT * FROM `ecommerceapp-auth-db-cleana.sales_analytics.v_orders`
   WHERE store_id = @storeId
   ```
2. Looker Studio detects the `@storeId` parameter. Set its **default value** to
   your main store id (e.g. `buybuy`) and tick **"Allow 'storeId' to be
   modified in reports"**. Add the source.
3. Repeat for `v_line_items` (and any rollup views you used), same
   `WHERE store_id = @storeId`.
4. Point each chart at its custom-query source instead of the plain table
   source (Selected chart → Data source → switch).
5. The embed URL's `params={"storeId":"…"}` now overrides the default and
   filters the whole report to that store. The parameter name must be exactly
   `storeId` (matches the app).

> **Simpler alternative (not URL-driven):** skip custom queries and add a
> **filter control** on `store_id`. Fine for a single store, but it won't react
> to the app's embed URL.

> ⚠️ **Security:** the `storeId` URL param is a *default filter*, not a hard
> boundary — a viewer could edit the URL to another store's id. Acceptable for
> MVP/demo; for production multi-tenant data, enforce **BigQuery / Looker
> row-level security** keyed to the signed-in identity instead. (Same caveat is
> recorded against the admin Dashboard feature.)

---

## 5. Enable embedding & wire it into the admin

1. **File → Embed report → Enable embedding.** Copy the embed URL (or the
   report's share URL set to "anyone with the link can view").
2. In the store admin, go to **Settings → Analytics dashboard** and paste the
   URL into **Dashboard embed URL**, then **Save**.
3. Open the admin **Dashboard** page — the report renders, filtered to the
   current store via the `storeId` parameter.

---

## Field reference

`v_orders` (order grain): `store_id`, `order_date`, `order_ts`, `order_id`,
`revenue`, `gross`, `net`, `discount`, `freight`, `payment_method`,
`installments`, `user_gender`, `age`, `age_band`, `user_key`, `is_returning`.

`v_line_items` (line grain): `store_id`, `order_date`, `order_id`, `product_id`,
`title`, `category_name`, `color`, `size`, `quantity`, `unit_price`,
`unit_discounted`, `line_revenue`.

`v_sales_daily` (store/day): `store_id`, `order_date`, `orders`, `revenue`,
`discount`, `customers`, `aov`, `units`.

`v_product_performance` (store/product): `store_id`, `product_id`, `title`,
`category_name`, `units`, `revenue`, `orders`.
