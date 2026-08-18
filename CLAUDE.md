# CLAUDE.md

Read `context.md` for architecture and the current gap list; full audit in `docs/go-live-audit.md`.

## Directives

- **Living docs:** `context.md` and `docs/go-live-audit.md` are local to the repo (no external artifacts). Whenever you make or notice a change that affects architecture or the gap list — a gap fixed, a new gap found, a structural change — update these files in the same commit.

- **Tenancy:** never call `FirebaseFirestore.instance.collection()` directly — go through `TenantCollections` (`lib/core/tenant/tenant_collections.dart`). All data lives under `stores/{storeId}/`. Line-item collection is `sales_products` (snake_case).
- **Sale status values** (rules-enforced): `pending|paid|shipped|delivered|cancelled` — nothing else.
- **Rules:** any Firestore/Storage rules change must update `rules_tests/firestore.rules.test.mjs` and be run locally (`npm test` in `rules_tests/` against emulators) — there is no CI for it.
- **Scripts in `functions/scripts/` hit PRODUCTION** unless `FIRESTORE_EMULATOR_HOST` is set — confirm target before running.
- **Theming:** use `context.brand.<token>` (BrandTokens), never literal colors. Runtime overrides come from the store doc via `ThemeController`.
- **i18n:** every user-facing string goes in `lib/core/i18n/app_strings.dart` with both en and pt-BR.
- **Cubits:** constructor-inject use cases (don't resolve from `sl` inside the cubit) so they stay testable.
- **Owner store-doc updates** may only touch `branding` and `name` (rules) — that's why `lookerEmbedUrl` lives inside `branding`.
- **Run with a brand:** `--dart-define-from-file=brands/<brand>/brand.json`; activate via `dart run tool/activate_brand.dart <brand>`.
- **Commits:** max ~7 files each, split by responsibility; commit to the current branch and push.
