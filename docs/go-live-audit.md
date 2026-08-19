# Go-Live Audit

White-label e-commerce SaaS · Flutter + Firebase + BLoC clean architecture · last updated 2026-08-18.

**Keep this document current:** update it whenever a gap below is fixed, a new gap is found, or the architecture changes.

**Verdict: not ready for production, but the payment blocker is now code-complete.** The architecture is solid — clean layering, well-executed tenant isolation, good rules. The Mercado Pago Checkout Pro stack (CEP-zone freight, server-validated totals, webhook status updates) landed 2026-08-18 but is **not deployed** (and `mpWebhook` has an export bug — see blocker 1). The analytics embed still leaks revenue across tenants, and there is still zero backend CI.

## How the system is put together

| Piece | Where | Notes |
|---|---|---|
| Shopper app | `lib/main.dart` | Mobile + web storefront. Requires `--dart-define-from-file=brands/<brand>/brand.json`; hard-fails without a storeId. |
| Admin console | `lib/main_admin.dart` | One shared web deployment for all tenants; go_router redirect guard; role from custom claims (`owner`/`super`). |
| Backend | `functions/src/index.ts`, `functions/src/payments.ts` | 6 functions (southamerica-east1): two Firestore→BigQuery ETL triggers on sale creation, `setStoreOwner` (onCall, super-only), `createPaymentPreference`, `setStorePaymentConfig`, `mpWebhook` (Mercado Pago). |
| Tenancy | `lib/core/tenant/` | Everything under `stores/{storeId}/…`; `TenantCollections` is the single gateway. Shopper storeId compile-time; admin storeId from auth claim. |
| Brands | `brands/{acme,buybuy}/` | Per-brand `brand.json` + assets; `tool/activate_brand.dart` materializes `brand.current.json`. Both share one Firebase project. |
| Analytics | `analytics/looker_studio/` | 4 BigQuery views over `sales_analytics`; per-store Looker embed URL; 12-stage setup wizard. |

**Genuinely strong:** tenant isolation consistent end-to-end (paths + claims + default-deny rules sealing legacy roots); 18 rules tests (`rules_tests/firestore.rules.test.mjs`); ~250 Flutter test cases; Codemagic CI (analyze → tests → Test Lab → App Distribution); no secrets tracked in git.

## Go-live blockers

1. **Payment stack implemented but not live.** Mercado Pago Checkout Pro landed 2026-08-18 (fake card form removed; checkout registers a pending sale → `createPaymentPreference` → opens init_point; `mpWebhook` flips pending→paid/cancelled). Remaining to go live: fix **`mpWebhook` missing from the `functions/src/index.ts` re-export** (it won't deploy as-is), deploy rules + functions, per-store MP tokens via the admin Payments section, sandbox E2E. Freight is real: CEP-range zones + free-shipping threshold + pickup from the store doc's `shipping` map.
2. **Prices now server-validated at payment time; creation still open.** `createPaymentPreference` recomputes subtotal from live product docs and freight from the shipping config, overwriting the sale totals before charging. The initially client-written sale doc and `sales_products` line items still have no rules-level field validation, and rules tests for the new `shipping`/`private` rules are missing (CLAUDE.md directive).
3. **Cross-tenant analytics leak.** Looker embed filtered only by a `storeId` URL parameter. Needs BigQuery RLS / signed embedding; `analytics/looker_studio/add_store_id_column.sql` is written but unapplied.
4. **No backend CI/CD.** `.github/workflows/` empty; rules tests never run in CI; functions/rules/indexes/views deployed by hand.

## High-priority before real customers

- **Single Firebase project** (`ecommerceapp-auth-db-cleana`) for all brands and environments; seed scripts default to prod unless `FIRESTORE_EMULATOR_HOST` is set.
- **Fragile, unmonitored ETL:** two triggers on the same sale doc (double cost, desync on partial failure); no retries/idempotency; `ignoreUnknownValues: true` silently drops fields (how `storeId` went missing). Zero function tests. No alerting.
- **Stale coverage:** `coverage/lcov.info` (71.9%) is from May, 89 of 162 files. Untested: all of `lib/presentation/admin/`, `lib/presentation/web/`, store feature, `TenantCollections`/`StoreContext`, `ThemeController`, admin-only use cases.
- **`seedOrders.ts` bugs (uncommitted):** writes `salesProducts` (app/rules use `sales_products`); emits status `processing`, not in the rules whitelist `pending|paid|shipped|delivered|cancelled`.

## Worth fixing, not blocking

- Rules: owner read of `stores/{storeId}/users/{uid}` exposes shopper PII; favorites update allows any field but `userId`; Storage `stores/{storeId}/**` world-readable (deliberate, but all assets public).
- Legacy: migrated root collections still in Firestore (sealed); `app_urls.dart` hardcodes bucket + legacy image paths; profile images global at `profile/images/{uid}`.
- Dead dark theme (`themeMode` hardcoded light); only 3 of ~25 brand tokens runtime-overridable.
- `lookerEmbedUrl` stored inside `branding` map as a rules workaround; `AdminSession` errors English-only.
- `user_key` in views is unsalted SHA-256 of uid.
- Only one composite Firestore index defined.
- Hygiene: `.env` not gitignored (report wizard writes to it); committed logs/artifacts at root; untracked `build-report-wizard.sh.bak` and `STAGES-REFERENCE.md`.

## Suggested go-live order

1. ~~Server-side checkout function (price cart from catalog, create order + Mercado Pago preference, webhook sets `paid`)~~ — implemented 2026-08-18; finish go-live hardening: export `mpWebhook`, rules tests for `shipping`/`private`, deploy, sandbox E2E, retry-payment + live order-status streaming.
2. Apply `add_store_id_column.sql`, then BigQuery RLS + signed Looker embedding — closes the tenant leak.
3. GitHub Actions: rules tests + function tests on PR; deploy rules/functions/views on merge.
4. Second Firebase project as staging; point emulators/seeds there by default.
5. Harden ETL (single trigger, retries, idempotency key, alerting) + function tests.
6. Test admin/web/store layers; refresh coverage.
