# Go-Live Audit

White-label e-commerce SaaS · Flutter + Firebase + BLoC clean architecture · last updated 2026-09-08.

**Keep this document current:** update it whenever a gap below is fixed, a new gap is found, or the architecture changes.

**Verdict: not ready for production, but the payment blocker is now code-complete.** The architecture is solid — clean layering, well-executed tenant isolation, good rules. The Mercado Pago Checkout Pro stack (CEP-zone freight, server-validated totals, webhook status updates) landed 2026-08-18 but is **not deployed**. The analytics embed still leaks revenue across tenants; backend CI now verifies functions and rules on every PR, but production deploys are still a deliberate manual step.

## How the system is put together

| Piece | Where | Notes |
|---|---|---|
| Shopper app | `lib/main.dart` | Mobile + web storefront. Requires `--dart-define-from-file=brands/<brand>/brand.json`; hard-fails without a storeId. |
| Admin console | `lib/main_admin.dart` | One shared web deployment for all tenants; go_router redirect guard; role from custom claims (`owner`/`super`). |
| Backend | `functions/src/index.ts`, `functions/src/payments.ts` | 6 functions (southamerica-east1): two Firestore→BigQuery ETL triggers on sale creation, `setStoreOwner` (onCall, super-only), `createPaymentPreference`, `setStorePaymentConfig`, `mpWebhook` (Mercado Pago). |
| Tenancy | `lib/core/tenant/` | Everything under `stores/{storeId}/…`; `TenantCollections` is the single gateway. Shopper storeId compile-time; admin storeId from auth claim. |
| Brands | `brands/{acme,buybuy}/` | Per-brand `brand.json` + assets; `tool/activate_brand.dart` materializes `brand.current.json`. Both share one Firebase project. |
| Analytics | `analytics/looker_studio/` | 4 BigQuery views over `sales_analytics`; per-store Looker embed URL; 12-stage setup wizard. |

**Genuinely strong:** tenant isolation consistent end-to-end (paths + claims + default-deny rules sealing legacy roots); 26 rules tests (`rules_tests/firestore.rules.test.mjs`, including `shipping` and the sealed `private/` docs); 255 Flutter test cases; Codemagic CI (analyze → tests → Test Lab → App Distribution); no secrets tracked in git.

## Go-live blockers

1. **Payment stack implemented but not live.** Mercado Pago Checkout Pro landed 2026-08-18 (fake card form removed; checkout registers a pending sale → `createPaymentPreference` → opens init_point; `mpWebhook` flips pending→paid/cancelled). Remaining to go live: deploy rules + functions, per-store MP tokens via the admin Payments section, sandbox E2E. Freight is real: CEP-range zones + free-shipping threshold + pickup from the store doc's `shipping` map.
2. **Prices now server-validated at payment time; creation still open.** `createPaymentPreference` recomputes subtotal from live product docs and freight from the shipping config, overwriting the sale totals before charging. The initially client-written sale doc and `sales_products` line items still have no rules-level field validation. (The `shipping`/`private` rules tests this used to list as missing do exist — 26 tests — and now run in CI.)
3. **Cross-tenant analytics leak.** Looker embed filtered only by a `storeId` URL parameter, so a curious owner can read another tenant's revenue. Needs BigQuery RLS / signed embedding. Its groundwork is further along than this file claimed: `analytics/looker_studio/add_store_id_column.sql` **has been applied** — both `sales` and `sales_products` carry a native `storeId` column (confirmed 2026-09-08 via `INFORMATION_SCHEMA`), though that file and the view comments still describe it as pending. Verify the backfill actually ran before building RLS on it. The reporting views keep deriving `store_id` from `firestoreCollection`, which works either way.
4. **Backend CI/CD, partly closed.** `.github/workflows/backend.yml` (added 2026-09-08) lints and builds the
   functions and runs the 26 rules tests against the Firestore emulator on every PR and master push that
   touches them — the CLAUDE.md "run the rules tests" directive is now enforced rather than remembered.
   `backend-deploy.yml` can deploy rules/storage/functions but is **opt-in**: it needs a
   `FIREBASE_SERVICE_ACCOUNT` secret, and the automatic push trigger additionally needs the
   `BACKEND_AUTO_DEPLOY` repository variable set to `true`. It is left off on purpose — these functions move
   money, there is no staging project, and a rules deploy hits every tenant at once. Run it by hand from the
   Actions tab until the sandbox E2E has passed. The BigQuery views are still applied by hand (different
   product, different credentials).

## High-priority before real customers

- **Single Firebase project** (`ecommerceapp-auth-db-cleana`) for all brands and environments; seed scripts default to prod unless `FIRESTORE_EMULATOR_HOST` is set.
- **Fragile, unmonitored ETL:** two triggers on the same sale doc (double cost, desync on partial failure); no retries/idempotency; `ignoreUnknownValues: true` silently drops fields (how `storeId` went missing). Zero function tests. No alerting.
- **Stale coverage:** `coverage/lcov.info` (71.9%) is from May, 89 of 162 files. Untested: all of `lib/presentation/admin/`, `lib/presentation/web/`, store feature, `TenantCollections`/`StoreContext`, `ThemeController`, admin-only use cases.
- ~~**`seedOrders.ts` bugs:** wrong collection (`salesProducts`) and invalid status `processing`~~ — fixed and committed 2026-08-23 (now writes `sales_products`, status whitelist only). It still defaults to prod without `FIRESTORE_EMULATOR_HOST`.

## Responsive + tooling gaps found during the 2026-08-23 screenshot pass

Evidence: `docs/screenshots/` (emulator run of both entrypoints, mobile 390×844 and desktop 1440×900).

- ~~**Web storefront header overflows by 94 px below ~420 px wide**, pushing the cart button off-screen~~ — fixed
  2026-09-08. Below 660 px the main bar keeps the logo, search and cart and folds the language picker, favourites
  and orders into the account menu (`WebScaffold.compactBarBreakpoint`).
- ~~**Cart table is not responsive** (three nested overflows at 390 px)~~ — fixed 2026-09-08: below 560 px the
  column headings are dropped and each line becomes a stacked card (`_kCartTableBreakpoint`).
- ~~**Order rows overflow at mobile width**, hiding the *Pagar agora* retry~~ — fixed 2026-09-08: below 520 px the
  footer stacks savings / freight+total / pay button (`_kOrderFooterBreakpoint`). The retry is now reachable on a
  phone.
- ~~The shopper web layer still has **no widget tests**~~ — first ones landed 2026-09-08:
  `test/presentation/web/web_responsive_test.dart` pumps `WebScaffold`, `WebCartPage` and `WebPurchasesPage`
  at 390×844 and 1440×900 and guards all three fixed breakpoints (each was verified to fail when its
  breakpoint is reverted). Note the header fix needed a behavioural assertion, not an overflow one: its
  search field is `Expanded`, so a bar that no longer fits squeezes the search box away and pushes the cart
  button off-screen **without throwing**. The rest of the layer — home, product, favorites — is still
  untested.
- ~~**`USE_EMULATORS` does not wire the Functions emulator.**~~ — fixed 2026-09-08: both entrypoints now call
  `useFunctionsEmulator` (`lib/core/configs/firebase/functions_config.dart`), which redirects the *regional*
  `southamerica-east1` instance the app actually resolves. Checkout can now be exercised locally.
- ~~**Sale analytics carry client-authored totals.**~~ — fixed 2026-09-08. Both ETL triggers were
  `onDocumentCreated`, so they exported the sale as the *client* wrote it; `createPaymentPreference`
  overwrites `discountedPrice` / `freight` / `totalPrice` with server-recomputed values only afterwards, and
  the create-only ETL never re-ran. Looker therefore reported unvalidated revenue. Both triggers are now
  `onDocumentWritten` and re-export whenever the exported content changes (writes that change nothing the
  table carries are skipped, so the payment-preference pin alone does not duplicate a row). The tables are
  now append-only revision history, and `reporting_views.sql` keeps only the newest revision per sale. The two
  tables need different revision keys, checked against `INFORMATION_SCHEMA` rather than assumed: `sales` has
  `saleDocumentId` and `exportEventId`, but `sales_products` has **neither** — it is keyed on
  `salesId` + `productIndex`, which is the row's identity across exports and also means a sale exported only
  once keeps all its lines. The whole file was validated with `bq query --dry_run` against the live schema.
  Before adding any column to these tables, confirm it exists there first: inserts use `ignoreUnknownValues`,
  so a field the functions write is silently dropped until the column is created. **`analytics/looker_studio/reporting_views.sql` must be re-run in BigQuery** for the
  dashboards to pick this up — until then the views double-count re-exported sales.
- **Sale prices are still client-authored at create.** Rules check only `userId` / `status` / `storeId`, so a
  crafted sale can carry any price. Nothing downstream trusts those numbers any more (the callable
  recomputes before charging; analytics now follow the callable), but the write itself is still unvalidated.
- **`functions/` has no test harness at all** — no runner, no tests. `isSameExport` and the freight/subtotal
  maths in `payments.ts` are pure functions and would be cheap to cover once one exists.
- ~~**Super-admin store selection is a free-text store-id field**~~ — fixed 2026-09-08: `SelectStorePage` now
  lists the real stores via a new `ListStoresUseCase` (the rules already allowed `list` for `super`), with a
  search box past six stores and non-active stores flagged. The free-text field survives as a fallback, and
  is what you get automatically if the listing fails — e.g. before the `super` claim has propagated.
  Covered by `test/presentation/admin/select_store_page_test.dart`.
- ~~**`seedCatalog.ts` never creates the `stores/{storeId}` doc**~~ — fixed 2026-09-08: it now creates the
  store document (`name`/`status`/`plan`/`branding`/`shipping` defaults) when absent, and leaves an existing
  one untouched so re-seeding cannot clobber an owner's edits.
- ~~**Admin product list renders no thumbnails**~~ — fixed 2026-09-08. The cause was the widget, not the
  URLs: the list used `CachedNetworkImage`, which fetches through an HTTP client, so on web the request is a
  cross-origin XHR that Cloud Storage rejects without CORS headers on the bucket. The edit form always
  worked because it uses `Image.network`, which goes through the browser's image loader. The list now does
  the same on web and keeps `CachedNetworkImage` (and its disk cache) on native. **The same trap applies to
  every other `CachedNetworkImage` on web** — the storefront uses it too; setting CORS on the bucket is the
  real fix.

## Worth fixing, not blocking

- Rules: owner read of `stores/{storeId}/users/{uid}` exposes shopper PII; favorites update allows any field but `userId`; Storage `stores/{storeId}/**` world-readable (deliberate, but all assets public).
- Legacy: migrated root collections still in Firestore (sealed); `app_urls.dart` hardcodes bucket + legacy image paths; profile images global at `profile/images/{uid}`.
- Dead dark theme (`themeMode` hardcoded light); only 3 of ~25 brand tokens runtime-overridable.
- `lookerEmbedUrl` stored inside `branding` map as a rules workaround; `AdminSession` errors English-only.
- `user_key` in views is unsalted SHA-256 of uid.
- Only one composite Firestore index defined.
- Hygiene: `.env` not gitignored (report wizard writes to it); committed logs/artifacts at root; untracked `STAGES-REFERENCE.md` (wizard-output transcript with unexpanded shell text — regenerate or drop, don't commit as-is). `build-report-wizard.sh.bak` deleted 2026-08-23; wizard script itself now committed.

## Suggested go-live order

1. ~~Server-side checkout function (price cart from catalog, create order + Mercado Pago preference, webhook sets `paid`)~~ — implemented 2026-08-18; `mpWebhook` export and the `shipping`/`private` rules tests both landed since. Remaining go-live hardening: deploy, sandbox E2E, retry-payment + live order-status streaming.
2. Apply `add_store_id_column.sql`, then BigQuery RLS + signed Looker embedding — closes the tenant leak.
3. GitHub Actions: rules tests + function tests on PR; deploy rules/functions/views on merge.
4. Second Firebase project as staging; point emulators/seeds there by default.
5. Harden ETL (single trigger, retries, idempotency key, alerting) + function tests.
6. Test admin/web/store layers; refresh coverage.
