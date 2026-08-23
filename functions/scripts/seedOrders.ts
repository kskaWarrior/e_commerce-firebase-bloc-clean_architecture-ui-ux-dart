/**
 * Seeds a store's order history: writes sale documents under
 * stores/{storeId}/sales, mirroring exactly what the storefront checkout
 * (SalesFirebaseServiceImpl.registerSale) writes, including the
 * stores/{storeId}/sales_products line-item mirror.
 *
 * Why this exists: a UI checkout stamps createdDate = now, so seeding through
 * the app would put every order on one day and the Looker revenue trend would
 * render as a single bar. This script spreads createdDate across the last
 * ~8 weeks and varies payment method, discount, basket size and customer
 * demographics so the "Payment & discounts" and "Customer breakdown" sections
 * have something to chart.
 *
 * Everything else is genuine: these are admin-SDK writes, which bypass
 * firestore.rules but still fire onDocumentCreated, so each order fans out
 * through the real Cloud Functions ETL into sales_analytics.sales and
 * sales_analytics.sales_products. Only the dates are authored.
 *
 * Usage (run from the functions/ folder):
 *
 *   # 1) Safe dry-run against the local emulators (nothing touches prod):
 *   FIRESTORE_EMULATOR_HOST=localhost:8085 \
 *   GCLOUD_PROJECT=ecommerceapp-auth-db-cleana \
 *   npx ts-node scripts/seedOrders.ts buybuy
 *
 *   # 2) Production (writes are permanent):
 *   npx ts-node scripts/seedOrders.ts buybuy
 *
 *   # 3) Re-seed from scratch, re-firing the BigQuery export:
 *   npx ts-node scripts/seedOrders.ts buybuy --fresh
 *
 * Env:
 *   ORDER_COUNT   how many orders to write (default 30).
 *   WEEKS_BACK    how far back createdDate is spread (default 8).
 *
 * Idempotent on fixed document ids (seed-order-001 ...), so re-running
 * overwrites in place rather than duplicating. NOTE: an overwrite is an
 * update, and onDocumentCreated does not fire on updates — so a plain re-run
 * will NOT produce new BigQuery rows. Pass --fresh to delete the previous
 * seed orders first, which makes the next write a genuine create.
 */
import * as admin from "firebase-admin";

const DEFAULT_ORDER_COUNT = 30;
const DEFAULT_WEEKS_BACK = 8;
const SEED_PREFIX = "seed-order-";

const PAYMENT_METHODS = [
  "credit_card",
  "credit_card",
  "credit_card",
  "pix",
  "pix",
  "boleto",
  "debit_card",
];

const STATUSES = [
  "delivered",
  "delivered",
  "delivered",
  "shipped",
  "paid",
  "pending",
];

const FIRST_NAMES = [
  "Ana", "Bruno", "Carla", "Diego", "Elisa", "Felipe", "Gabriela", "Henrique",
  "Isabela", "João", "Karina", "Lucas", "Mariana", "Nelson", "Olívia", "Paulo",
  "Renata", "Sérgio", "Tatiana", "Vitor",
];

const LAST_NAMES = [
  "Almeida", "Barbosa", "Cardoso", "Duarte", "Esteves", "Ferreira", "Gomes",
  "Henriques", "Ibrahim", "Jardim", "Klein", "Lima", "Moreira", "Nunes",
];

type ColorSeed = { title: string; hexCode: string };

type CatalogProduct = {
  id: string;
  productId: string;
  title: string;
  categoryName: string;
  price: number;
  discountedPrice: number;
  sizes: string[];
  colors: ColorSeed[];
};

/**
 * Deterministic 32-bit PRNG, so repeated runs produce the same catalogue of
 * orders instead of a different demo every time.
 * @param {number} seed Initial state.
 * @return {function(): number} Generator returning floats in [0, 1).
 */
function mulberry32(seed: number): () => number {
  let a = seed;
  return function random(): number {
    a |= 0;
    a = (a + 0x6d2b79f5) | 0;
    let t = Math.imul(a ^ (a >>> 15), 1 | a);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

/**
 * Picks one element of an array.
 * @param {function(): number} rnd Random source.
 * @param {Array<T>} items Candidates.
 * @return {T} The chosen element.
 * @template T
 */
function pick<T>(rnd: () => number, items: T[]): T {
  return items[Math.floor(rnd() * items.length)];
}

/**
 * Rounds to two decimals, so totals do not carry float noise into BigQuery.
 * @param {number} value Raw value.
 * @return {number} Value rounded to cents.
 */
function money(value: number): number {
  return Math.round(value * 100) / 100;
}

/**
 * Reads the seeded catalog back out of Firestore. Reading the live products
 * (rather than the manifest) guarantees the orders reference products that
 * actually exist in the store, and fails loudly if the catalog was never
 * seeded.
 * @param {FirebaseFirestore.Firestore} db Firestore handle.
 * @param {string} storeId Tenant id.
 * @return {Promise<Array<CatalogProduct>>} The store's products.
 */
async function loadCatalog(
  db: FirebaseFirestore.Firestore,
  storeId: string,
): Promise<CatalogProduct[]> {
  const snapshot = await db.collection(`stores/${storeId}/products`).get();
  if (snapshot.empty) {
    throw new Error(
      `No products under stores/${storeId}/products — run seedCatalog.ts first.`,
    );
  }

  return snapshot.docs.map((doc) => {
    const data = doc.data();
    const colors = Array.isArray(data.colors) ? data.colors : [];
    const sizes = Array.isArray(data.sizes) ? data.sizes : [];
    return {
      id: doc.id,
      productId: (data.productId ?? doc.id).toString(),
      title: (data.title ?? "").toString(),
      categoryName: (data.categoryName ?? "").toString(),
      price: Number(data.price ?? 0),
      discountedPrice: Number(data.discountedPrice ?? data.price ?? 0),
      sizes: sizes.length > 0 ? sizes.map(String) : ["One Size"],
      colors: colors.length > 0 ?
        colors.map((c: ColorSeed) => ({
          title: String(c.title ?? ""),
          hexCode: String(c.hexCode ?? ""),
        })) :
        [{title: "Default", hexCode: "1C1C1C"}],
    };
  });
}

/**
 * Deletes previously seeded orders and their line-item mirrors, so the next
 * write is a genuine document create and the BigQuery export re-fires.
 * @param {FirebaseFirestore.Firestore} db Firestore handle.
 * @param {string} storeId Tenant id.
 * @return {Promise<void>} Resolves when the delete batch commits.
 */
async function clearSeededOrders(
  db: FirebaseFirestore.Firestore,
  storeId: string,
): Promise<void> {
  const sales = await db.collection(`stores/${storeId}/sales`).get();
  const seeded = sales.docs.filter((doc) => doc.id.startsWith(SEED_PREFIX));

  const mirrors = await db
    .collection(`stores/${storeId}/sales_products`)
    .where("salesId", ">=", SEED_PREFIX)
    .where("salesId", "<", `${SEED_PREFIX}￿`)
    .get();

  if (seeded.length === 0 && mirrors.empty) {
    console.log("  nothing to clear");
    return;
  }

  const batch = db.batch();
  seeded.forEach((doc) => batch.delete(doc.ref));
  mirrors.docs.forEach((doc) => batch.delete(doc.ref));
  await batch.commit();

  console.log(
    `  cleared ${seeded.length} order(s) and ` +
      `${mirrors.size} line-item mirror(s)`,
  );
}

/**
 * Builds one order: 1-3 distinct line items, a freight charge, a payment
 * method and a customer, dated somewhere in the spread window.
 * @param {function(): number} rnd Random source.
 * @param {Array<CatalogProduct>} catalog Products to draw from.
 * @param {number} index Zero-based order number.
 * @param {number} weeksBack Size of the date window.
 * @param {number} total How many orders are being written in all.
 * @return {Record<string, unknown>} The sale document body, minus id/storeId.
 */
function buildOrder(
  rnd: () => number,
  catalog: CatalogProduct[],
  index: number,
  weeksBack: number,
  total: number,
): Record<string, unknown> {
  // Walk backwards through the window in even steps, then jitter, so the
  // trend line is populated on most days instead of clumping.
  const windowMs = weeksBack * 7 * 24 * 60 * 60 * 1000;
  const step = windowMs / total;
  const jitter = (rnd() - 0.5) * step;
  const createdAt = new Date(Date.now() - windowMs + index * step + jitter);
  // Spread across the working day rather than all landing at midnight.
  createdAt.setHours(9 + Math.floor(rnd() * 11), Math.floor(rnd() * 60), 0, 0);

  const basketSize = 1 + Math.floor(rnd() * 3);
  const chosen: CatalogProduct[] = [];
  const pool = [...catalog];
  for (let i = 0; i < basketSize && pool.length > 0; i++) {
    chosen.push(...pool.splice(Math.floor(rnd() * pool.length), 1));
  }

  const productsList = chosen.map((product) => {
    const quantity = 1 + Math.floor(rnd() * 2);
    const unitPrice = money(product.price);
    const unitDiscounted = money(product.discountedPrice);
    return {
      id: product.id,
      title: product.title,
      productId: product.productId,
      categoryName: product.categoryName,
      size: pick(rnd, product.sizes),
      color: pick(rnd, product.colors).title,
      colorHex: pick(rnd, product.colors).hexCode,
      unitPrice,
      unitDiscounted,
      quantity: quantity * 1.0,
      totalPrice: money(unitDiscounted * quantity),
    };
  });

  const gross = money(
    productsList.reduce((sum, p) => sum + p.unitPrice * p.quantity, 0),
  );
  const net = money(
    productsList.reduce((sum, p) => sum + p.unitDiscounted * p.quantity, 0),
  );
  // Free shipping over R$300 — gives the freight column two distinct values.
  const freight = net >= 300 ? 0 : money(19.9 + rnd() * 15);
  const paymentMethod = pick(rnd, PAYMENT_METHODS);
  const installments = paymentMethod === "credit_card" ?
    pick(rnd, [1, 1, 2, 3, 6, 12]) :
    1;

  const firstName = pick(rnd, FIRST_NAMES);
  const lastName = pick(rnd, LAST_NAMES);
  const birthYear = 1968 + Math.floor(rnd() * 40);

  return {
    createdDate: admin.firestore.Timestamp.fromDate(createdAt),
    price: gross,
    discountedPrice: net,
    freight,
    totalPrice: money(net + freight),
    paymentMethod,
    installmentsNumber: installments,
    productsList,
    userId: `seed-user-${String(1 + Math.floor(rnd() * 18)).padStart(3, "0")}`,
    userName: `${firstName} ${lastName}`,
    userGender: pick(rnd, ["female", "male", "unisex"]),
    userBirthDate: admin.firestore.Timestamp.fromDate(
      new Date(Date.UTC(birthYear, Math.floor(rnd() * 12), 1 + Math.floor(rnd() * 28))),
    ),
    status: pick(rnd, STATUSES),
  };
}

/**
 * Entry point.
 * @return {Promise<void>} Resolves when every order is written.
 */
async function main(): Promise<void> {
  const storeId = process.argv[2] ?? "buybuy";
  const fresh = process.argv.includes("--fresh");
  const orderCount = Number(process.env.ORDER_COUNT ?? DEFAULT_ORDER_COUNT);
  const weeksBack = Number(process.env.WEEKS_BACK ?? DEFAULT_WEEKS_BACK);

  admin.initializeApp({
    projectId: process.env.GCLOUD_PROJECT ?? "ecommerceapp-auth-db-cleana",
  });
  const db = admin.firestore();

  const target = process.env.FIRESTORE_EMULATOR_HOST ? "EMULATOR" : "PRODUCTION";
  console.log(`Seeding ${orderCount} orders into stores/${storeId} [${target}]`);
  console.log(`  date spread: last ${weeksBack} weeks`);

  if (fresh) {
    console.log("  --fresh: clearing previously seeded orders");
    await clearSeededOrders(db, storeId);
  }

  const catalog = await loadCatalog(db, storeId);
  console.log(`  catalog:     ${catalog.length} products`);

  const rnd = mulberry32(20260815);
  const storeRef = db.doc(`stores/${storeId}`);
  let lineItems = 0;

  for (let i = 0; i < orderCount; i++) {
    const saleId = `${SEED_PREFIX}${String(i + 1).padStart(3, "0")}`;
    const order = buildOrder(rnd, catalog, i, weeksBack, orderCount);
    const products = order.productsList as Record<string, unknown>[];

    const batch = db.batch();
    batch.set(storeRef.collection("sales").doc(saleId), {
      ...order,
      id: saleId,
      storeId,
    });

    products.forEach((product, index) => {
      const mirrorRef = storeRef
        .collection("sales_products")
        .doc(`${saleId}-${index}`);
      batch.set(mirrorRef, {
        id: `${saleId}-${index}`,
        salesId: saleId,
        orderId: saleId,
        saleDocumentId: saleId,
        productIndex: index,
        productId: product.productId,
        title: product.title,
        categoryName: product.categoryName,
        color: product.color,
        colorHex: product.colorHex,
        size: product.size,
        quantity: product.quantity,
        unitPrice: product.unitPrice,
        unitDiscounted: product.unitDiscounted,
        totalPrice: product.totalPrice,
        createdDate: order.createdDate,
        userId: order.userId,
        userName: order.userName,
        storeId,
        sourceCollection: "sales",
        payload: product,
      });
    });

    await batch.commit();
    lineItems += products.length;
  }

  console.log(
    `Done: ${orderCount} orders, ${lineItems} line items. ` +
      "Cloud Functions will export them to BigQuery within a minute.",
  );
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
