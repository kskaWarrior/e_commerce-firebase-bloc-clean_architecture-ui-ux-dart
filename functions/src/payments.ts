/**
 * Mercado Pago Checkout Pro integration.
 *
 * Money flow is per-store: each store owner connects their own MP account by
 * saving an access token through setStorePaymentConfig. Tokens live in
 * stores/{storeId}/private/payment, which security rules keep unreadable from
 * clients; only these functions (Admin SDK) touch it.
 *
 * createPaymentPreference is the server-authoritative pricing step: it
 * recomputes the order subtotal from the live product docs and the freight
 * from the store shipping config, overwrites the sale totals, then creates
 * the Checkout Pro preference.
 */

import {HttpsError, onCall} from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";

const REGION = "southamerica-east1";
const MP_API = "https://api.mercadopago.com";

type ShippingZone = {
  label?: string;
  cepStart?: string;
  cepEnd?: string;
  fee?: number;
};

type ShippingConfig = {
  pickupEnabled?: boolean;
  freeShippingThreshold?: number | null;
  zones?: ShippingZone[];
};

/**
 * Strips non-digits from a CEP.
 * @param {unknown} raw Raw CEP value.
 * @return {string} Digits-only CEP.
 */
function normalizeCep(raw: unknown): string {
  return String(raw ?? "").replace(/\D/g, "");
}

/**
 * Mirrors ShippingConfig.feeFor in the Flutter app: first matching zone
 * wins; the threshold turns the fee into 0; no match means no delivery.
 * @param {ShippingConfig} config Store shipping config.
 * @param {string} cep Destination CEP (8 digits).
 * @param {number} subtotal Discounted cart subtotal.
 * @return {number | null} Freight fee, or null when unserviceable.
 */
export function freightFor(
  config: ShippingConfig,
  cep: string,
  subtotal: number,
): number | null {
  const normalized = normalizeCep(cep);
  if (normalized.length !== 8) {
    return null;
  }
  for (const zone of config.zones ?? []) {
    const start = normalizeCep(zone.cepStart);
    const end = normalizeCep(zone.cepEnd);
    if (start.length !== 8 || end.length !== 8) {
      continue;
    }
    if (start <= normalized && normalized <= end) {
      const threshold = config.freeShippingThreshold;
      if (typeof threshold === "number" && subtotal >= threshold) {
        return 0;
      }
      return typeof zone.fee === "number" ? zone.fee : 0;
    }
  }
  return null;
}

type SaleProduct = {
  productId?: string;
  title?: string;
  quantity?: number;
};

/**
 * Recomputes the discounted subtotal of a sale from live product docs so a
 * tampering client cannot set its own prices.
 * @param {string} storeId Tenant store id.
 * @param {SaleProduct[]} products Sale line items.
 * @return {Promise<{subtotal: number, items: object[]}>} Totals + MP items.
 */
async function recomputeSubtotal(
  storeId: string,
  products: SaleProduct[],
): Promise<{subtotal: number; items: Record<string, unknown>[]}> {
  const db = admin.firestore();
  let subtotal = 0;
  const items: Record<string, unknown>[] = [];

  for (const product of products) {
    const productId = String(product.productId ?? "").trim();
    const quantity = Math.max(1, Math.trunc(Number(product.quantity) || 1));
    if (!productId) {
      throw new HttpsError(
        "failed-precondition",
        "A cart item is missing its productId.",
      );
    }
    const doc = await db
      .doc(`stores/${storeId}/products/${productId}`)
      .get();
    if (!doc.exists) {
      throw new HttpsError(
        "failed-precondition",
        `Product ${productId} is no longer available.`,
      );
    }
    const data = doc.data() ?? {};
    const price = Number(data.price) || 0;
    const discounted = Number(data.discountedPrice) || 0;
    const unit = discounted > 0 && discounted < price ? discounted : price;
    subtotal += unit * quantity;
    items.push({
      id: productId,
      title: String(data.title ?? product.title ?? "Item"),
      quantity,
      unit_price: Number(unit.toFixed(2)),
      currency_id: "BRL",
    });
  }

  return {subtotal: Number(subtotal.toFixed(2)), items};
}

/**
 * Reads the store's private payment config doc.
 * @param {string} storeId Tenant store id.
 * @return {Promise<object>} Payment config with token and webhook secret.
 */
export async function getPaymentConfig(
  storeId: string,
): Promise<{mpAccessToken?: string; mpWebhookSecret?: string}> {
  const doc = await admin
    .firestore()
    .doc(`stores/${storeId}/private/payment`)
    .get();
  return (doc.data() ?? {}) as {
    mpAccessToken?: string;
    mpWebhookSecret?: string;
  };
}

type CreatePreferenceRequest = {
  storeId?: string;
  saleId?: string;
};

export const createPaymentPreference = onCall(
  {region: REGION},
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Sign in to pay for an order.");
    }
    const {storeId, saleId} = (request.data ?? {}) as CreatePreferenceRequest;
    if (!storeId || !saleId) {
      throw new HttpsError(
        "invalid-argument",
        "Both storeId and saleId are required.",
      );
    }

    const db = admin.firestore();
    const saleRef = db.doc(`stores/${storeId}/sales/${saleId}`);
    const saleDoc = await saleRef.get();
    if (!saleDoc.exists) {
      throw new HttpsError("not-found", "Order not found.");
    }
    const sale = saleDoc.data() ?? {};
    if (sale.userId !== request.auth.uid) {
      throw new HttpsError(
        "permission-denied",
        "You can only pay for your own orders.",
      );
    }
    if (sale.status !== "pending") {
      throw new HttpsError(
        "failed-precondition",
        "This order is no longer pending.",
      );
    }
    if (sale.payment?.preferenceId) {
      throw new HttpsError(
        "failed-precondition",
        "A payment was already started for this order.",
      );
    }

    // Server-authoritative totals.
    const products = Array.isArray(sale.productsList) ?
      (sale.productsList as SaleProduct[]) : [];
    if (products.length === 0) {
      throw new HttpsError("failed-precondition", "The order has no items.");
    }
    const {subtotal, items} = await recomputeSubtotal(storeId, products);

    const storeDoc = await db.doc(`stores/${storeId}`).get();
    const shipping = (storeDoc.data()?.shipping ?? {}) as ShippingConfig;

    let freight = 0;
    if (sale.deliveryMethod === "pickup") {
      if (shipping.pickupEnabled !== true) {
        throw new HttpsError(
          "failed-precondition",
          "Pickup is not enabled for this store.",
        );
      }
    } else {
      const cep = normalizeCep(sale.address?.cep);
      const fee = freightFor(shipping, cep, subtotal);
      if (fee === null) {
        throw new HttpsError(
          "failed-precondition",
          "Delivery is not available for this CEP.",
        );
      }
      freight = fee;
    }
    const total = Number((subtotal + freight).toFixed(2));

    const {mpAccessToken} = await getPaymentConfig(storeId);
    if (!mpAccessToken) {
      throw new HttpsError(
        "failed-precondition",
        "This store has not configured payments yet.",
      );
    }

    if (freight > 0) {
      items.push({
        id: "freight",
        title: "Frete",
        quantity: 1,
        unit_price: freight,
        currency_id: "BRL",
      });
    }

    const projectId =
      process.env.GCLOUD_PROJECT ?? admin.app().options.projectId;
    const notificationUrl =
      `https://${REGION}-${projectId}.cloudfunctions.net/mpWebhook` +
      `?storeId=${encodeURIComponent(storeId)}`;

    const response = await fetch(`${MP_API}/checkout/preferences`, {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${mpAccessToken}`,
        "Content-Type": "application/json",
        "X-Idempotency-Key": `${storeId}-${saleId}`,
      },
      body: JSON.stringify({
        items,
        external_reference: `${storeId}|${saleId}`,
        notification_url: notificationUrl,
        metadata: {storeId, saleId, uid: request.auth.uid},
      }),
    });
    if (!response.ok) {
      const body = await response.text();
      logger.error("Mercado Pago preference creation failed", {
        storeId,
        saleId,
        status: response.status,
        body,
      });
      throw new HttpsError(
        "internal",
        "Could not start the payment. Please try again.",
      );
    }
    const preference = (await response.json()) as {
      id: string;
      init_point?: string;
      sandbox_init_point?: string;
    };

    // Overwrite the client-computed money fields with the recomputed ones
    // and pin the preference (Admin SDK bypasses the status-only rule).
    await saleRef.set(
      {
        discountedPrice: subtotal,
        freight,
        totalPrice: total,
        payment: {
          provider: "mercadopago",
          preferenceId: preference.id,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
      },
      {merge: true},
    );

    logger.info("Payment preference created", {storeId, saleId, total});
    return {
      preferenceId: preference.id,
      initPoint: preference.init_point ?? null,
      sandboxInitPoint: preference.sandbox_init_point ?? null,
      total,
      freight,
    };
  },
);

type SetPaymentConfigRequest = {
  storeId?: string;
  mpAccessToken?: string;
  mpWebhookSecret?: string;
};

export const setStorePaymentConfig = onCall(
  {region: REGION},
  async (request) => {
    const token = request.auth?.token as
      | {role?: string; storeId?: string}
      | undefined;
    const {storeId, mpAccessToken, mpWebhookSecret} =
      (request.data ?? {}) as SetPaymentConfigRequest;

    if (!storeId || !mpAccessToken) {
      throw new HttpsError(
        "invalid-argument",
        "storeId and mpAccessToken are required.",
      );
    }
    const isSuper = token?.role === "super";
    const isOwner = token?.role === "owner" && token?.storeId === storeId;
    if (!isSuper && !isOwner) {
      throw new HttpsError(
        "permission-denied",
        "Only the store owner can configure payments.",
      );
    }

    // Reject tokens that MP itself does not accept.
    const meResponse = await fetch(`${MP_API}/users/me`, {
      headers: {Authorization: `Bearer ${mpAccessToken}`},
    });
    if (!meResponse.ok) {
      throw new HttpsError(
        "failed-precondition",
        "Mercado Pago rejected this access token.",
      );
    }

    await admin
      .firestore()
      .doc(`stores/${storeId}/private/payment`)
      .set(
        {
          mpAccessToken,
          ...(mpWebhookSecret ? {mpWebhookSecret} : {}),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedBy: request.auth?.uid ?? "",
        },
        {merge: true},
      );

    logger.info("Store payment config updated", {storeId});
    return {ok: true};
  },
);
