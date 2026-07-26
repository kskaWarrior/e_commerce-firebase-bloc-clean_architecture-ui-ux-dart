/**
 * One-time migration: copies the legacy single-tenant global collections
 * into the multi-tenant layout under stores/{storeId}/... and creates the
 * store document.
 *
 * Legacy source collections: users, products, categories, favorites,
 * sales, sales_products (all at the Firestore root).
 *
 * Usage (from functions/):
 *   npx ts-node scripts/migrateDefaultStore.ts [storeId]
 *   (storeId defaults to "buybuy" — must match brands/<brand>/brand.json)
 *
 * Credentials: GOOGLE_APPLICATION_CREDENTIALS service-account key, or run
 * against the emulator with FIRESTORE_EMULATOR_HOST set.
 *
 * Safety: the script only COPIES. Legacy collections are left in place;
 * delete them from the console after verifying the app against the new
 * paths. Re-running is idempotent (same doc ids, overwrites in place).
 *
 * Post-migration (analytics): the BigQuery tables sales_analytics.sales and
 * sales_analytics.sales_products need the new column once:
 *   ALTER TABLE sales_analytics.sales ADD COLUMN IF NOT EXISTS storeId STRING;
 *   ALTER TABLE sales_analytics.sales_products ADD COLUMN IF NOT EXISTS storeId STRING;
 */
import * as admin from "firebase-admin";

const COLLECTIONS = [
  "users",
  "products",
  "categories",
  "favorites",
  "sales",
  "sales_products",
];

const BATCH_LIMIT = 400; // Firestore max is 500 writes per batch.

async function main(): Promise<void> {
  const storeId = process.argv[2] ?? "buybuy";

  admin.initializeApp();
  const db = admin.firestore();

  console.log(`Migrating legacy collections into stores/${storeId}/...`);

  const storeRef = db.doc(`stores/${storeId}`);
  await storeRef.set(
    {
      name: "BuyBuy",
      slug: storeId,
      status: "active",
      plan: "free",
      createdDate: admin.firestore.FieldValue.serverTimestamp(),
      branding: {
        appTitle: "BuyBuy",
        primaryColorHex: "FFFEBD2E",
        secondaryColorHex: "FFE94B3C",
        backgroundColorHex: "FFFFF9F0",
      },
    },
    {merge: true},
  );
  console.log(`stores/${storeId} document ensured.`);

  for (const collectionName of COLLECTIONS) {
    const snapshot = await db.collection(collectionName).get();
    if (snapshot.empty) {
      console.log(`- ${collectionName}: empty, skipping.`);
      continue;
    }

    let batch = db.batch();
    let inBatch = 0;
    let copied = 0;

    for (const doc of snapshot.docs) {
      const targetRef = storeRef.collection(collectionName).doc(doc.id);
      const data = doc.data();
      // Denormalized tenant id for sales analytics parity with new writes.
      if (collectionName === "sales" || collectionName === "sales_products") {
        data.storeId = storeId;
        data.status = data.status ?? "pending";
      }
      batch.set(targetRef, data);
      inBatch++;
      copied++;

      if (inBatch >= BATCH_LIMIT) {
        await batch.commit();
        batch = db.batch();
        inBatch = 0;
      }
    }

    if (inBatch > 0) {
      await batch.commit();
    }
    console.log(`- ${collectionName}: copied ${copied} doc(s).`);
  }

  console.log("Done. Verify the app, then delete the legacy root collections manually.");
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
