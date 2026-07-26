# Customer (brand) onboarding runbook

Target: under 1 hour from signed customer to installable branded APK.

## Architecture recap

- One codebase, one shared Firebase project (`ecommerceapp-auth-db-cleana`).
- Each customer = one **brand** (`brands/<brand>/`) = one Android flavor =
  one Firestore tenant (`stores/<storeId>/...`, storeId == brand id).
- Tenant isolation is enforced by `firestore.rules` via path + custom claims
  (`owner`+storeId for the customer, `super` for you).
- The admin web app (`lib/main_admin.dart`) is ONE shared deployment; owners
  see only their store because their claim carries the storeId.

## Prerequisites (once)

- `firebase login` with access to the project.
- Your own account granted `{role: 'super'}`:
  `cd functions && npx ts-node scripts/bootstrapSuperAdmin.ts <your-email>`
- Emulator note (this machine): global firebase-tools 15 needs Java 21; use
  `npx firebase-tools@13.35.1 emulators:exec ...` with the installed Java 17.

## Per-customer steps

1. **Scaffold + Firebase registration** (~5 min)

   ```bash
   dart run tool/add_brand.dart <brand> "<App Name>" [applicationId]
   ```

   applicationId defaults to `com.wstudios.<brand>`; pass the customer's own
   reverse-domain id if they have one. The script scaffolds
   `brands/<brand>/`, registers the Android/iOS apps in Firebase, and
   refreshes `android/app/google-services.json`.

2. **Art + palette** (~10 min): drop the customer's `icon.png` (1024×1024),
   `splash.png`, `logo.png`, optional `wordmark.png` into
   `brands/<brand>/assets/`; edit the `COLOR_*` keys in `brand.json`
   (`HAS_WORDMARK: true` if a wordmark exists).

3. **Materialize** (~2 min)

   ```bash
   dart run tool/activate_brand.dart <brand> --icons
   ```

4. **Signing + CI** (~10 min)

   ```bash
   keytool -genkeypair -v -keystore upload-<brand>.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```

   Create Codemagic env group `brand_<brand>` with: `CM_KEYSTORE`
   (base64 of the .jks), `CM_KEYSTORE_PASSWORD`, `CM_KEY_ALIAS`,
   `CM_KEY_PASSWORD`, `BRAND=<brand>`, `FIREBASE_ANDROID_APP_ID` (from
   brand.json), `FIREBASE_TESTER_GROUPS`. Keep the .jks in your password
   manager — losing it loses Play upload continuity.

5. **Tenant data + owner** (~10 min)
   - Firestore: create `stores/<brand>` doc
     (`{name, status: 'active', plan: 'free', branding: {...}}`).
   - Auth: create the owner's account (email/password).
   - As super admin call the `setStoreOwner` callable with
     `{uid, storeId: '<brand>'}` — this sets their claims and `ownerUid`.
   - Owner signs into the admin web app and loads products/categories.

6. **Dashboards** (~5 min): duplicate the Looker Studio template report, set
   a locked report-level filter `storeId = <brand>`, share view-only with
   the customer. (Upgrade path: BigQuery row-level access policies.)

7. **Build & distribute** (~10 min)
   - Local sanity: `flutter build apk --flavor <brand> --dart-define-from-file=brands/<brand>/brand.json`
   - CI release: run the `android_brand_release` Codemagic workflow with the
     `brand_<brand>` env group (or tag `release/<brand>/vX.Y.Z`).
   - iOS: run the iOS workflow on Codemagic (activation writes
     Brand.xcconfig; icons for iOS are generated on CI with
     `dart run flutter_launcher_icons` after flipping `ios: true` in the
     generated config — see codemagic.yaml).

## Store publishing (later)

Play Console / App Store Connect listings are created per brand under your
developer accounts; per-brand `google_play`/`app_store_connect` publishing
sections can be added to the brand workflow when ready. App transfers to a
customer-owned account keep the applicationId.
