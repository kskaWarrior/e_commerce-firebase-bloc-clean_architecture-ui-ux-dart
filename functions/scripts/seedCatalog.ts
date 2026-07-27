/**
 * Seeds a store's catalog (categories + products) from a manifest and local
 * image files: uploads each image to Cloud Storage and writes the Firestore
 * documents under stores/{storeId}/categories and stores/{storeId}/products.
 *
 * The manifest (scripts/catalog.seed.json) maps the source image files to
 * catalog entries; edit it to change titles, prices, colors, etc.
 *
 * Usage (run from the functions/ folder):
 *
 *   # 1) Safe dry-run against the local emulators (nothing touches prod):
 *   ASSETS_DIR="C:/Users/you/DevRepositories/ASSETS/ecommerce_app/firebase" \
 *   FIRESTORE_EMULATOR_HOST=localhost:8085 \
 *   FIREBASE_STORAGE_EMULATOR_HOST=localhost:9199 \
 *   GCLOUD_PROJECT=ecommerceapp-auth-db-cleana \
 *   npx ts-node scripts/seedCatalog.ts buybuy
 *
 *   # 2) Production (writes are permanent):
 *   ASSETS_DIR="C:/Users/you/DevRepositories/ASSETS/ecommerce_app/firebase" \
 *   GOOGLE_APPLICATION_CREDENTIALS="./service-account.json" \
 *   npx ts-node scripts/seedCatalog.ts buybuy
 *
 * Env:
 *   ASSETS_DIR       root folder that contains categories/ and products/
 *                    (required; the images live outside the repo).
 *   STORAGE_BUCKET   defaults to the project's firebasestorage.app bucket.
 *   MANIFEST         manifest path (default scripts/catalog.seed.json).
 *
 * Idempotent: fixed document ids and deterministic storage paths, so
 * re-running overwrites in place rather than duplicating.
 */
import * as admin from "firebase-admin";
import * as fs from "fs";
import * as path from "path";
import {randomUUID} from "crypto";

const DEFAULT_BUCKET = "ecommerceapp-auth-db-cleana.firebasestorage.app";
const BUCKET = process.env.STORAGE_BUCKET ?? DEFAULT_BUCKET;

const CONTENT_TYPES: Record<string, string> = {
  ".png": "image/png",
  ".jpg": "image/jpeg",
  ".jpeg": "image/jpeg",
  ".webp": "image/webp",
};

interface CategorySeed {
  id: string;
  title: string;
  file: string;
}

interface ColorSeed {
  title: string;
  hexCode: string;
}

interface ProductSeed {
  id: string;
  title: string;
  description: string;
  categoryId: string;
  categoryName: string;
  gender: string;
  price: number;
  discountedPrice: number;
  currentDiscount: number;
  salesNumber: number;
  createdDate: string;
  sizes: string[];
  colors: ColorSeed[];
  images: string[];
}

interface Manifest {
  categories: CategorySeed[];
  products: ProductSeed[];
}

const emulatorStorageHost =
  process.env.FIREBASE_STORAGE_EMULATOR_HOST ||
  process.env.STORAGE_EMULATOR_HOST ||
  "";

/** Builds the canonical (tokenized) download URL for an uploaded object. */
function downloadUrl(objectPath: string, token: string): string {
  const encoded = encodeURIComponent(objectPath);
  const query = `?alt=media&token=${token}`;
  if (emulatorStorageHost) {
    const host = emulatorStorageHost.startsWith("http") ?
      emulatorStorageHost :
      `http://${emulatorStorageHost}`;
    return `${host}/v0/b/${BUCKET}/o/${encoded}${query}`;
  }
  return `https://firebasestorage.googleapis.com/v0/b/${BUCKET}/o/${encoded}` +
    query;
}

/** Uploads one local file to Storage and returns its download URL. */
async function uploadImage(
  bucket: ReturnType<admin.storage.Storage["bucket"]>,
  assetsDir: string,
  relativeFile: string,
  destination: string,
): Promise<string> {
  const localPath = path.join(assetsDir, relativeFile);
  if (!fs.existsSync(localPath)) {
    throw new Error(`Missing image file: ${localPath}`);
  }
  const ext = path.extname(localPath).toLowerCase();
  const contentType = CONTENT_TYPES[ext] ?? "application/octet-stream";
  const token = randomUUID();

  await bucket.upload(localPath, {
    destination,
    metadata: {
      contentType,
      metadata: {firebaseStorageDownloadTokens: token},
    },
  });

  return downloadUrl(destination, token);
}

async function main(): Promise<void> {
  const storeId = process.argv[2] ?? "buybuy";
  const assetsDir = process.env.ASSETS_DIR;
  if (!assetsDir) {
    throw new Error(
      "ASSETS_DIR is required (folder holding categories/ and products/).",
    );
  }

  const manifestPath =
    process.env.MANIFEST ?? path.join(__dirname, "catalog.seed.json");
  const manifest = JSON.parse(
    fs.readFileSync(manifestPath, "utf8"),
  ) as Manifest;

  admin.initializeApp({
    projectId: process.env.GCLOUD_PROJECT ?? "ecommerceapp-auth-db-cleana",
    storageBucket: BUCKET,
  });
  const db = admin.firestore();
  const bucket = admin.storage().bucket();

  const target = emulatorStorageHost ? "EMULATOR" : "PRODUCTION";
  console.log(`Seeding catalog into stores/${storeId} [${target}]`);
  console.log(`  bucket:    ${BUCKET}`);
  console.log(`  assets:    ${assetsDir}`);

  const storeRef = db.doc(`stores/${storeId}`);

  // Categories.
  for (const category of manifest.categories) {
    const ext = path.extname(category.file).toLowerCase();
    const dest = `stores/${storeId}/categories/images/${category.id}${ext}`;
    const url = await uploadImage(bucket, assetsDir, category.file, dest);
    await storeRef.collection("categories").doc(category.id).set({
      id: category.id,
      title: category.title,
      image: url,
    });
    console.log(`  category ${category.id} -> ${category.title}`);
  }

  // Products.
  for (const product of manifest.products) {
    const imageUrls: string[] = [];
    for (const relativeFile of product.images) {
      const base = path.basename(relativeFile);
      const dest = `stores/${storeId}/products/images/${product.id}/${base}`;
      imageUrls.push(await uploadImage(bucket, assetsDir, relativeFile, dest));
    }

    await storeRef.collection("products").doc(product.id).set({
      id: product.id,
      productId: product.id,
      title: product.title,
      description: product.description,
      categoryId: product.categoryId,
      categoryName: product.categoryName,
      gender: product.gender,
      price: product.price,
      discountedPrice: product.discountedPrice,
      currentDiscount: product.currentDiscount,
      salesNumber: product.salesNumber,
      createdDate: admin.firestore.Timestamp.fromDate(
        new Date(product.createdDate),
      ),
      sizes: product.sizes,
      colors: product.colors.map((c) => ({title: c.title, hexCode: c.hexCode})),
      images: imageUrls,
    });
    console.log(
      `  product  ${product.id} -> ${product.title} ` +
        `(${imageUrls.length} image(s))`,
    );
  }

  console.log(
    `Done: ${manifest.categories.length} categories, ` +
      `${manifest.products.length} products.`,
  );
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
