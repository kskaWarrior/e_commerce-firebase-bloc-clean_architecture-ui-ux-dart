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

import {HttpsError, onCall, onRequest} from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";
import {createHmac, timingSafeEqual} from "crypto";

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

/**
 * Validates Mercado Pago's x-signature header (ts=...,v1=...) against the
 * per-store webhook secret using the documented manifest format.
 * @param {string} signatureHeader Raw x-signature header.
 * @param {string} requestId x-request-id header value.
 * @param {string} dataId Payment id from the notification.
 * @param {string} secret Store's webhook secret.
 * @return {boolean} True when the signature is authentic.
 */
export function isValidMpSignature(
  signatureHeader: string,
  requestId: string,
  dataId: string,
  secret: string,
): boolean {
  const parts = new Map<string, string>();
  for (const piece of signatureHeader.split(",")) {
    const [key, ...rest] = piece.split("=");
    if (key && rest.length > 0) {
      parts.set(key.trim(), rest.join("=").trim());
    }
  }
  const ts = parts.get("ts");
  const v1 = parts.get("v1");
  if (!ts || !v1) {
    return false;
  }
  const manifest =
    `id:${dataId.toLowerCase()};request-id:${requestId};ts:${ts};`;
  const expected = createHmac("sha256", secret)
    .update(manifest)
    .digest("hex");
  try {
    return timingSafeEqual(Buffer.from(expected), Buffer.from(v1));
  } catch {
    return false;
  }
}

/**
 * Maps a Mercado Pago payment status onto the order lifecycle.
 * @param {string} mpStatus Mercado Pago payment status.
 * @return {string | null} Sale status, or null to leave it untouched.
 */
export function saleStatusForPayment(mpStatus: string): string | null {
  switch (mpStatus) {
  case "approved":
    return "paid";
  case "rejected":
  case "cancelled":
  case "expired":
    return "cancelled";
  default:
    // pending / in_process / authorized keep the order pending.
    return null;
  }
}

export const mpWebhook = onRequest({region: REGION}, async (req, res) => {
  // Always answer 2xx for handled-but-ignored events; MP retries anything
  // else aggressively.
  if (req.method !== "POST") {
    res.status(200).send("ignored");
    return;
  }

  const storeId = String(req.query.storeId ?? "");
  const body = (req.body ?? {}) as {
    type?: string;
    action?: string;
    data?: {id?: string | number};
  };
  const dataId = String(body.data?.id ?? "");

  if (!storeId || body.type !== "payment" || !dataId) {
    res.status(200).send("ignored");
    return;
  }

  const {mpAccessToken, mpWebhookSecret} = await getPaymentConfig(storeId);
  if (!mpAccessToken) {
    logger.warn("Webhook for store without payment config", {storeId});
    res.status(200).send("ignored");
    return;
  }

  // Signature check (only enforceable when the store configured a secret).
  if (mpWebhookSecret) {
    const signature = String(req.headers["x-signature"] ?? "");
    const requestId = String(req.headers["x-request-id"] ?? "");
    if (!isValidMpSignature(signature, requestId, dataId, mpWebhookSecret)) {
      logger.warn("Webhook signature mismatch", {storeId, dataId});
      res.status(401).send("invalid signature");
      return;
    }
  }

  // Never trust the notification body: fetch the payment from MP.
  const response = await fetch(`${MP_API}/v1/payments/${dataId}`, {
    headers: {Authorization: `Bearer ${mpAccessToken}`},
  });
  if (!response.ok) {
    logger.error("Failed to fetch payment from Mercado Pago", {
      storeId,
      dataId,
      status: response.status,
    });
    // 500 so MP retries later (the payment may not be queryable yet).
    res.status(500).send("payment fetch failed");
    return;
  }
  const payment = (await response.json()) as {
    id: string | number;
    status?: string;
    status_detail?: string;
    external_reference?: string;
  };

  const [refStoreId, saleId] =
    String(payment.external_reference ?? "").split("|");
  if (refStoreId !== storeId || !saleId) {
    logger.warn("Webhook external_reference mismatch", {
      storeId,
      dataId,
      externalReference: payment.external_reference,
    });
    res.status(200).send("ignored");
    return;
  }

  const saleRef = admin
    .firestore()
    .doc(`stores/${storeId}/sales/${saleId}`);
  const mpStatus = String(payment.status ?? "");
  const nextStatus = saleStatusForPayment(mpStatus);

  await admin.firestore().runTransaction(async (tx) => {
    const saleDoc = await tx.get(saleRef);
    if (!saleDoc.exists) {
      logger.warn("Webhook for unknown sale", {storeId, saleId});
      return;
    }
    const sale = saleDoc.data() ?? {};

    // Idempotency: same payment id + same MP status already recorded.
    if (
      sale.payment?.paymentId === String(payment.id) &&
      sale.payment?.mpStatus === mpStatus
    ) {
      return;
    }

    // Never regress terminal states (shipped/delivered stay put).
    const currentStatus = String(sale.status ?? "pending");
    const canTransition =
      currentStatus === "pending" ||
      (currentStatus === "paid" && nextStatus === "cancelled");

    tx.set(
      saleRef,
      {
        ...(nextStatus && canTransition ? {status: nextStatus} : {}),
        payment: {
          provider: "mercadopago",
          preferenceId: sale.payment?.preferenceId ?? null,
          paymentId: String(payment.id),
          mpStatus,
          statusDetail: String(payment.status_detail ?? ""),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
      },
      {merge: true},
    );
  });

  logger.info("Webhook processed", {storeId, saleId, mpStatus, nextStatus});
  res.status(200).send("ok");
});
