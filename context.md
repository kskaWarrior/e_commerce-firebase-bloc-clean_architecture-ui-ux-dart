# Project Context

White-label multi-tenant e-commerce SaaS. Flutter (Cubits, clean architecture) + Firebase, one codebase serving branded shopper apps and a shared admin console. Audit snapshot: 2026-08-18.

## Architecture

- **Entrypoints:** `lib/main.dart` (shopper, mobile + web; requires `--dart-define-from-file=brands/<brand>/brand.json`) and `lib/main_admin.dart` (admin web console, one deployment for all tenants, go_router + claim-guarded).
- **Layers:** `lib/core` / `lib/domain` / `lib/data` / `lib/presentation` per feature (auth, categories, favorites, products, sales, store). DI via `get_it` in `lib/service_locator.dart`.
- **State:** flutter_bloc Cubits only. Outside BLoC by design: `ThemeController`, `AppLocaleController`, `CartDraftStore` (ChangeNotifier singletons).
- **Tenancy:** all data under `stores/{storeId}/...` via `lib/core/tenant/tenant_collections.dart` — the single gateway; never use raw `FirebaseFirestore.instance.collection()`. Shopper storeId is compile-time (brand.json); admin storeId comes from the `owner`/`super` custom claim (`AdminSession`), granted only by the `setStoreOwner` callable (super-only), bootstrapped via `functions/scripts/bootstrapSuperAdmin.ts`.
- **Branding:** `brands/{acme,buybuy}/` + `tool/activate_brand.dart` → `brand.current.json` (gitignored). Runtime theme override: store doc `branding` map → `ThemeController.applyBranding` (only primary/secondary/background of ~25 tokens). Dark theme exists but `themeMode` is hardcoded light.
- **Backend:** `functions/src/index.ts` + `functions/src/payments.ts` — 6 functions (region `southamerica-east1`): two Firestore→BigQuery ETL triggers on sale create (`sales_analytics.sales` / `.sales_products`), `setStoreOwner`, `createPaymentPreference` (server-authoritative totals + Mercado Pago Checkout Pro preference), `setStorePaymentConfig` (owner-only, validates the MP token, writes `stores/{id}/private/payment`), `mpWebhook` (HMAC-validated payment notifications → order status). Ops scripts in `functions/scripts/` (ts-node, hit PROD unless `FIRESTORE_EMULATOR_HOST` set).
- **Payments/freight:** per-store MP access token in `stores/{id}/private/payment` (rules seal `private/*` to functions-only); freight from the store doc's `shipping` map (CEP-range zones, free-shipping threshold, pickup toggle — admin settings UI) computed client-side as estimate and recomputed in `createPaymentPreference`; structured `addressData` on user profile (ViaCEP autofill) copied onto orders with `deliveryMethod`.
- **Analytics:** BigQuery views in `analytics/looker_studio/reporting_views.sql`; per-store Looker Studio embed URL stored in the store doc's `branding.lookerEmbedUrl` (rules workaround — owner may only update `branding`/`name`).
- **i18n:** hand-rolled en/pt-BR `lib/core/i18n/app_strings.dart` (no ARB/gen-l10n).
- **CI:** Codemagic only (`codemagic.yaml`): analyze → tests → Firebase Test Lab → App Distribution. No backend CI; rules tests (`rules_tests/firestore.rules.test.mjs`) run manually.

## Current state / known gaps

Full audit: `docs/go-live-audit.md` (keep it and this file updated as the project changes).

- **Payments implemented but NOT deployed** — Mercado Pago Checkout Pro (freight zones, callable, webhook) landed 2026-08-18; needs `firebase deploy --only firestore:rules,functions`, per-store MP tokens via the admin Payments section, and a sandbox E2E pass.
- **Bug: `mpWebhook` not re-exported from `functions/src/index.ts`** — it will not deploy as-is; the preference's `notification_url` would 404. One-line fix pending.
- **Rules tests stale** — firestore.rules gained the owner-editable `shipping` key and the sealed `private/{docId}` block, but `rules_tests/firestore.rules.test.mjs` has no coverage for either (CLAUDE.md directive violated; fix with the go-live hardening pass).
- **Sale prices partially server-validated** — `createPaymentPreference` recomputes subtotal from live product docs + freight from the shipping config and overwrites the sale totals; but the initial client-written sale doc and `sales_products` line items still have no rules-level field validation.
- **Analytics tenant leak** — Looker embed filtered only by `storeId` URL param; needs BigQuery RLS + applying `analytics/looker_studio/add_store_id_column.sql` (written, unapplied).
- **Single Firebase project** `ecommerceapp-auth-db-cleana` for everything — no staging.
- **ETL fragile** — two triggers on same doc, no retries/idempotency, `ignoreUnknownValues` drops fields (how `storeId` went missing). Zero function tests.
- **Coverage stale** — `coverage/lcov.info` is from May; `lib/presentation/admin/`, `lib/presentation/web/`, store feature, tenant core all untested.
- **`seedOrders.ts` (uncommitted) bugs** — writes `salesProducts` (app uses `sales_products`) and status `processing` (not in rules whitelist).
- Sale status enum (rules-enforced): `pending|paid|shipped|delivered|cancelled`.
