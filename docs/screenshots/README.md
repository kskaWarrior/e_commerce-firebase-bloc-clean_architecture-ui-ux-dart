# Platform screenshots

Captured 2026-08-23 against the **local Firebase emulators** (auth 9099, firestore 8085, storage 9199) with the
`buybuy` brand active. Nothing here touched production. The red *"Running in emulator mode"* banner at the foot of
every frame is the app's own emulator warning, and is the proof of that.

Both apps ran as debug web builds:

```bash
flutter run -d web-server -t lib/main.dart --dart-define-from-file=brands/buybuy/brand.json --dart-define=USE_EMULATORS=true --web-port=5233
```

```bash
flutter run -d web-server -t lib/main_admin.dart --dart-define=USE_EMULATORS=true --web-port=5232
```

Emulator data came from `functions/scripts/seedCatalog.ts` (6 categories, 10 products) and
`functions/scripts/seedOrders.ts` (24 orders spread over 8 weeks), plus four emulator-only accounts
(`shopper@buybuy.test`, `owner@buybuy.test`, `owner@acme.test`, `super@platform.test`) with the `owner`/`super`
custom claims, two store docs (`buybuy`, `acme`) with CEP-zone shipping, and four orders belonging to the shopper —
one per status.

## shopper-mobile — storefront at 390×844

| File | What it shows |
|---|---|
| `01-signin-email.png` | Brand splash + e-mail step of sign-in |
| `02-signup.png` | Sign-up, step 1 of 2 (name, phone, e-mail, password) |
| `03-signin-password.png` | Password step |
| `04-home.png` | Home hero + category rail |
| `05-home-categories.png` | Category grid |
| `06-home-bestsellers.png` | Best sellers + footer navigation |
| `07-home-newin.png` | New-in carousel |
| `08-category-browse.png` | Category filter applied |
| `09-product-detail.png` | Product detail: gallery, breadcrumb, price |
| `10-product-options.png` | Size/colour pickers, quantity, add to cart |
| `11-added-to-cart.png` | Item added, favourite toggled |
| `12a-cart-empty.png` | Empty-cart state |
| `12b-cart-filled.png` | Cart with one line item |
| `13-checkout-summary.png` | Order summary + Mercado Pago payment notice |
| `14-favorites.png` | Favourites |
| `15-orders.png` | Orders with live status chips |
| `16-orders-statuses.png` | Remaining statuses |
| `17-profile.png` | Profile |
| `18-profile-address.png` | Structured delivery address (ViaCEP fields) |

## shopper-desktop — storefront at 1440×900

| File | What it shows |
|---|---|
| `01-home.png` | Desktop home: search, category bar, hero |
| `02-home-categories.png` | Category cards |
| `02-home-newin.png` | New-in carousel + footer |
| `03-product.png` | Product detail with sticky buy box |
| `03b-product-zoom.png` | Full-screen image viewer |
| `04-cart-checkout.png` | Cart, order summary, Mercado Pago section, *Confirmar compra* |
| `05-orders.png` | Orders across all four statuses |
| `05b-orders-pay-now.png` | *Pagar agora* retry appearing on the pending order |
| `05c-orders-live-paid.png` | Same order flipping to **PAGO** live |
| `06-profile.png` | Profile |
| `07-favorites.png` | Favourites |

`05b`/`05c` were produced by writing to the sale doc from the Admin SDK while the page stayed open — no reload
happened between the three frames, so they demonstrate the `watchSalesByUserId` stream, not a refresh.

## owner-admin — admin console as `owner@buybuy.test`

| File | What it shows |
|---|---|
| `01-orders.png` | Orders table, 28 orders, status chips |
| `02-order-status-menu.png` | Status transition menu (the five rules-enforced values) |
| `03-products.png` | Product list |
| `04-product-form.png` | Product edit: fields, colours, image manager |
| `05-categories.png` | Category management |
| `06-settings-branding.png` | Store identity + brand colours |
| `07-color-picker.png` | Brand colour picker |
| `08-settings-dashboard-url.png` | Looker embed URL + freight config |
| `09-settings-shipping-zones.png` | CEP-range zones, fees, free-shipping threshold, pickup |
| `10-settings-payments.png` | Mercado Pago access token / webhook secret (left empty deliberately) |
| `11-dashboard-empty.png` | Dashboard empty state (no Looker URL configured) |

## super-admin — platform owner

| File | What it shows |
|---|---|
| `01-admin-login.png` | Admin sign-in |
| `02-select-store.png` | Store selection shown to a `super` claim |
| `03-store-id-entered.png` | Store id entered |
| `04-console-as-super.png` | The same console, scoped to the chosen store |

## Issues these captures surfaced

Recorded in `docs/go-live-audit.md`; visible in the frames themselves:

- **Storefront header overflows by 94 px below ~420 px wide** — the cart button is pushed off-screen and Flutter's
  overflow stripe is visible in every `shopper-mobile` frame. The footer links are the only way to reach the cart.
- **Cart table is not responsive** — three nested overflows at 390 px (`12b-cart-filled.png`); the column headings
  render one letter per line.
- **Order rows overflow at mobile width**, hiding the *Pagar agora* button that `05b-orders-pay-now.png` shows on
  desktop.
- **Admin product list renders no thumbnails** (`03-products.png`), though the edit form loads the same images fine.
