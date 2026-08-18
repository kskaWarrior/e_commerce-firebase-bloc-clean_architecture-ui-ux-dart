# Project Context

White-label multi-tenant e-commerce SaaS. Flutter (Cubits, clean architecture) + Firebase, one codebase serving branded shopper apps and a shared admin console. Audit snapshot: 2026-08-18.

## Architecture

- **Entrypoints:** `lib/main.dart` (shopper, mobile + web; requires `--dart-define-from-file=brands/<brand>/brand.json`) and `lib/main_admin.dart` (admin web console, one deployment for all tenants, go_router + claim-guarded).
- **Layers:** `lib/core` / `lib/domain` / `lib/data` / `lib/presentation` per feature (auth, categories, favorites, products, sales, store). DI via `get_it` in `lib/service_locator.dart`.
- **State:** flutter_bloc Cubits only. Outside BLoC by design: `ThemeController`, `AppLocaleController`, `CartDraftStore` (ChangeNotifier singletons).
- **Tenancy:** all data under `stores/{storeId}/...` via `lib/core/tenant/tenant_collections.dart` — the single gateway; never use raw `FirebaseFirestore.instance.collection()`. Shopper storeId is compile-time (brand.json); admin storeId comes from the `owner`/`super` custom claim (`AdminSession`), granted only by the `setStoreOwner` callable (super-only), bootstrapped via `functions/scripts/bootstrapSuperAdmin.ts`.
- **Branding:** `brands/{acme,buybuy}/` + `tool/activate_brand.dart` → `brand.current.json` (gitignored). Runtime theme override: store doc `branding` map → `ThemeController.applyBranding` (only primary/secondary/background of ~25 tokens). Dark theme exists but `themeMode` is hardcoded light.
- **Backend:** `functions/src/index.ts` — 3 functions (region `southamerica-east1`): two Firestore→BigQuery ETL triggers on sale create (`sales_analytics.sales` / `.sales_products`) + `setStoreOwner`. Ops scripts in `functions/scripts/` (ts-node, hit PROD unless `FIRESTORE_EMULATOR_HOST` set).
- **Analytics:** BigQuery views in `analytics/looker_studio/reporting_views.sql`; per-store Looker Studio embed URL stored in the store doc's `branding.lookerEmbedUrl` (rules workaround — owner may only update `branding`/`name`).
- **i18n:** hand-rolled en/pt-BR `lib/core/i18n/app_strings.dart` (no ARB/gen-l10n).
- **CI:** Codemagic only (`codemagic.yaml`): analyze → tests → Firebase Test Lab → App Distribution. No backend CI; rules tests (`rules_tests/firestore.rules.test.mjs`) run manually.

## Current state / known gaps (see full audit artifact)

Full audit: https://claude.ai/code/artifact/3c16449a-6720-4278-9471-dd5a9d4d8c16

- **No payment integration** — checkout is simulated (`cart_page.dart`); Mercado Pago planned but no code exists. Owners manually set status `paid`.
- **Prices never server-validated** — totals/freight/line items are client-written; `sales_products` create rule has no field validation.
- **Analytics tenant leak** — Looker embed filtered only by `storeId` URL param; needs BigQuery RLS + applying `analytics/looker_studio/add_store_id_column.sql` (written, unapplied).
- **Single Firebase project** `ecommerceapp-auth-db-cleana` for everything — no staging.
- **ETL fragile** — two triggers on same doc, no retries/idempotency, `ignoreUnknownValues` drops fields (how `storeId` went missing). Zero function tests.
- **Coverage stale** — `coverage/lcov.info` is from May; `lib/presentation/admin/`, `lib/presentation/web/`, store feature, tenant core all untested.
- **`seedOrders.ts` (uncommitted) bugs** — writes `salesProducts` (app uses `sales_products`) and status `processing` (not in rules whitelist).
- Sale status enum (rules-enforced): `pending|paid|shipped|delivered|cancelled`.
