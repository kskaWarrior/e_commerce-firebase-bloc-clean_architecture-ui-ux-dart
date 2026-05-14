/**
 * Import function triggers from their respective submodules:
 *
 * import {onCall} from "firebase-functions/v2/https";
 * import {onDocumentWritten} from "firebase-functions/v2/firestore";
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

import {setGlobalOptions} from "firebase-functions";
import {onDocumentCreated} from "firebase-functions/v2/firestore";
import * as logger from "firebase-functions/logger";
import {BigQuery} from "@google-cloud/bigquery";
import { randomUUID } from "crypto";

// Start writing functions
// https://firebase.google.com/docs/functions/typescript

// For cost control, you can set the maximum number of containers that can be
// running at the same time. This helps mitigate the impact of unexpected
// traffic spikes by instead downgrading performance. This limit is a
// per-function limit. You can override the limit for each function using the
// `maxInstances` option in the function's options, e.g.
// `onRequest({ maxInstances: 5 }, (req, res) => { ... })`.
// NOTE: setGlobalOptions does not apply to functions using the v1 API. V1
// functions should each use functions.runWith({ maxInstances: 10 }) instead.
// In the v1 API, each function can only serve one request per container, so
// this will be the maximum concurrent request count.
setGlobalOptions({maxInstances: 10});

const REGION = "southamerica-east1";
const DATASET_ID = "sales_analytics";
const TABLE_ID = "sales_analytics.sales";
const SALES_PRODUCTS_TABLE_ID = "sales_analytics.sales_products";

type BigQueryTarget = {
  projectId?: string;
  datasetId: string;
  tableId: string;
};

type BigQuerySchemaField = {
  name: string;
  type: string;
  mode?: "NULLABLE" | "REQUIRED" | "REPEATED";
};

/**
 * Parses full or short BigQuery dataset/table identifiers.
 * @param {string} datasetId Dataset identifier from config.
 * @param {string} tableId Table identifier from config.
 * @return {BigQueryTarget} Parsed BigQuery project/dataset/table target.
 */
function parseBigQueryTarget(
  datasetId: string,
  tableId: string,
): BigQueryTarget {
  const datasetParts = datasetId.split(".").filter(Boolean);
  const tableParts = tableId.split(".").filter(Boolean);

  if (tableParts.length === 3) {
    return {
      projectId: tableParts[0],
      datasetId: tableParts[1],
      tableId: tableParts[2],
    };
  }

  if (datasetParts.length === 2 && tableParts.length === 1) {
    return {
      projectId: datasetParts[0],
      datasetId: datasetParts[1],
      tableId: tableParts[0],
    };
  }

  return {
    datasetId: datasetParts[datasetParts.length - 1],
    tableId: tableParts[tableParts.length - 1],
  };
}

/**
 * Converts Firestore values into BigQuery-friendly JSON values.
 * @param {unknown} value Value from Firestore document.
 * @return {unknown} Normalized JSON-safe value.
 */
function normalizeFirestoreValue(value: unknown): unknown {
  if (value === null || value === undefined) {
    return value;
  }

  if (Array.isArray(value)) {
    return value.map((item) => normalizeFirestoreValue(item));
  }

  if (value instanceof Date) {
    return value.toISOString();
  }

  if (typeof value === "object") {
    const timestampLike = value as {toDate?: () => Date};
    if (typeof timestampLike.toDate === "function") {
      return timestampLike.toDate().toISOString();
    }

    const objectValue = value as Record<string, unknown>;
    const normalizedEntries = Object.entries(objectValue).map(
      ([key, nestedValue]) => [key, normalizeFirestoreValue(nestedValue)]
    );

    return Object.fromEntries(normalizedEntries);
  }

  return value;
}

/**
 * Converts unknown values into numbers when possible.
 * @param {unknown} value Value to parse.
 * @return {number | null} Parsed number or null when invalid.
 */
function toNumberOrNull(value: unknown): number | null {
  if (typeof value === "number" && Number.isFinite(value)) {
    return value;
  }

  if (typeof value === "string") {
    const parsed = Number(value);
    return Number.isFinite(parsed) ? parsed : null;
  }

  return null;
}

const bigQueryTarget = parseBigQueryTarget(DATASET_ID, TABLE_ID);
const salesProductsBigQueryTarget = parseBigQueryTarget(
  DATASET_ID,
  SALES_PRODUCTS_TABLE_ID,
);
const bigQueryClient = new BigQuery({projectId: bigQueryTarget.projectId});

const salesSchema: BigQuerySchemaField[] = [
  { name: "id", type: "STRING" },
  { name: "userId", type: "STRING" },
  { name: "userName", type: "STRING" },
  { name: "userGender", type: "STRING" },
  { name: "products", type: "JSON" },
  { name: "createdDate", type: "TIMESTAMP" },
  { name: "price", type: "FLOAT" },
  { name: "discountedPrice", type: "FLOAT" },
  { name: "paymentMethod", type: "STRING" },
  { name: "installmentsNumber", type: "INTEGER" },
  { name: "freight", type: "FLOAT" },
  { name: "totalPrice", type: "FLOAT" },
  { name: "discount", type: "FLOAT" },
  { name: "userBirthDate", type: "TIMESTAMP" },
  { name: "exportEventId", type: "STRING" },
  { name: "saleDocumentId", type: "STRING" },
  { name: "exportedAt", type: "STRING" },
  { name: "firestoreCollection", type: "STRING" },
  { name: "payload", type: "JSON" },
];

const salesProductsSchema: BigQuerySchemaField[] = [
  { name: "id", type: "STRING" },
  { name: "orderId", type: "STRING" },
  { name: "salesId", type: "STRING" },
  { name: "saleDocumentId", type: "STRING" },
  { name: "productId", type: "STRING" },
  { name: "title", type: "STRING" },
  { name: "categoryName", type: "STRING" },
  { name: "color", type: "STRING" },
  { name: "colorHex", type: "STRING" },
  { name: "size", type: "STRING" },
  { name: "quantity", type: "FLOAT" },
  { name: "unitPrice", type: "FLOAT" },
  { name: "unitDiscounted", type: "FLOAT" },
  { name: "totalPrice", type: "FLOAT" },
  { name: "productIndex", type: "INTEGER" },
  { name: "createdDate", type: "TIMESTAMP" },
  { name: "userId", type: "STRING" },
  { name: "userName", type: "STRING" },
  { name: "exportedAt", type: "STRING" },
  { name: "exportEventId", type: "STRING" },
  { name: "firestoreCollection", type: "STRING" },
  { name: "payload", type: "JSON" },
];

/**
 * Identifies BigQuery not-found errors from API responses.
 * @param {unknown} error Thrown error value.
 * @return {boolean} True when table not found.
 */
function isBigQueryNotFoundError(error: unknown): boolean {
  const maybeError = error as {
    code?: number;
    errors?: Array<{ reason?: string }>;
  };

  if (maybeError?.code === 404) {
    return true;
  }

  return (maybeError?.errors ?? []).some((item) => item.reason === "notFound");
}

/**
 * Creates a table if it does not exist.
 * @param {BigQueryTarget} target BigQuery table target.
 * @param {BigQuerySchemaField[]} schema Table schema definition.
 * @return {Promise<void>} Promise resolved when table exists.
 */
async function ensureBigQueryTableExists(
  target: BigQueryTarget,
  schema: BigQuerySchemaField[],
): Promise<void> {
  const dataset = bigQueryClient.dataset(target.datasetId);
  const table = dataset.table(target.tableId);
  const [exists] = await table.exists();

  if (exists) {
    return;
  }

  await dataset.createTable(target.tableId, { schema });
  logger.warn("BigQuery table was missing and has been created", {
    datasetId: target.datasetId,
    tableId: target.tableId,
  });
}

/**
 * Inserts rows and auto-creates the destination table on not found.
 * @param {BigQueryTarget} target BigQuery table target.
 * @param {BigQuerySchemaField[]} schema Table schema definition.
 * @param {Record<string, unknown>[]} rows Rows to insert.
 * @return {Promise<void>} Promise resolved after insertion.
 */
async function insertRowsWithAutoCreate(
  target: BigQueryTarget,
  schema: BigQuerySchemaField[],
  rows: Record<string, unknown>[],
): Promise<void> {
  const insert = async () => {
    await bigQueryClient
      .dataset(target.datasetId)
      .table(target.tableId)
      .insert(rows, { ignoreUnknownValues: true });
  };

  try {
    await insert();
  } catch (error) {
    if (!isBigQueryNotFoundError(error)) {
      throw error;
    }

    await ensureBigQueryTableExists(target, schema);
    await insert();
  }
}

export const exportSaleToBigQuery = onDocumentCreated(
  {
    document: "sales/{saleId}",
    region: REGION,
  },
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) {
      logger.warn("No Firestore snapshot found for sales trigger", {
        eventId: event.id,
      });
      return;
    }

    const saleData = normalizeFirestoreValue(
      snapshot.data() as Record<string, unknown>
    );
    const saleFields = saleData as Record<string, unknown>;
    const price = toNumberOrNull(saleFields.price);
    const discountedPrice = toNumberOrNull(saleFields.discountedPrice);
    const products = JSON.stringify(saleFields.productsList ?? null);

    const saleRow = {
      exportEventId: event.id,
      saleDocumentId: event.params.saleId,
      exportedAt: new Date().toISOString(),
      firestoreCollection: "sales",
      createdDate: saleFields.createdDate,
      discountedPrice,
      freight: toNumberOrNull(saleFields.freight),
      id: String(saleFields.id ?? event.params.saleId),
      installmentsNumber: toNumberOrNull(saleFields.installmentsNumber),
      paymentMethod: saleFields.paymentMethod,
      price,
      products,
      totalPrice: toNumberOrNull(saleFields.totalPrice),
      discount: price !== null && discountedPrice !== null ?
        price - discountedPrice : null,
      userBirthDate: saleFields.userBirthDate,
      userGender: saleFields.userGender,
      userId: saleFields.userId,
      userName: saleFields.userName,
      payload: saleData,
    };

    try {
      await insertRowsWithAutoCreate(bigQueryTarget, salesSchema, [saleRow]);

      logger.info("Sale exported to BigQuery", {
        saleDocumentId: event.params.saleId,
        datasetId: bigQueryTarget.datasetId,
        tableId: bigQueryTarget.tableId,
        region: REGION,
      });
    } catch (error) {
      logger.error("Failed to export sale to BigQuery", {
        saleDocumentId: event.params.saleId,
        datasetId: bigQueryTarget.datasetId,
        tableId: bigQueryTarget.tableId,
        error,
      });
      throw error;
    }
  }
);

export const exportSaleProductsToBigQuery = onDocumentCreated(
  {
    document: "sales/{saleId}",
    region: REGION,
  },
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) {
      logger.warn("No Firestore snapshot found for sales products trigger", {
        eventId: event.id,
      });
      return;
    }

    const saleData = normalizeFirestoreValue(
      snapshot.data() as Record<string, unknown>
    );
    const saleFields = saleData as Record<string, unknown>;
    const orderId = String(saleFields.id ?? event.params.saleId);
    const productsRaw = saleFields.productsList;

    if (!Array.isArray(productsRaw) || productsRaw.length === 0) {
      logger.warn("Sale has no productsList to export", {
        orderId,
        saleDocumentId: event.params.saleId,
      });
      return;
    }

    const rows = productsRaw.map((item, index) => {
      const product = typeof item === "object" && item !== null ?
        item as Record<string, unknown> : {};

      return {
        id: randomUUID(),
        orderId,
        salesId: orderId,
        saleDocumentId: event.params.saleId,
        productId: String(product.productId ?? ""),
        title: product.title,
        categoryName: product.categoryName,
        color: product.color,
        colorHex: product.colorHex,
        size: product.size,
        quantity: toNumberOrNull(product.quantity),
        unitPrice: toNumberOrNull(product.unitPrice),
        unitDiscounted: toNumberOrNull(product.unitDiscounted),
        totalPrice: toNumberOrNull(product.totalPrice),
        productIndex: index,
        createdDate: saleFields.createdDate,
        userId: saleFields.userId,
        userName: saleFields.userName,
        exportedAt: new Date().toISOString(),
        exportEventId: event.id,
        firestoreCollection: "sales",
        payload: product,
      };
    });

    try {
      await insertRowsWithAutoCreate(
        salesProductsBigQueryTarget,
        salesProductsSchema,
        rows,
      );

      logger.info("Sale products exported to BigQuery", {
        orderId,
        rowsExported: rows.length,
        datasetId: salesProductsBigQueryTarget.datasetId,
        tableId: salesProductsBigQueryTarget.tableId,
        region: REGION,
      });
    } catch (error) {
      logger.error("Failed to export sale products to BigQuery", {
        orderId,
        saleDocumentId: event.params.saleId,
        datasetId: salesProductsBigQueryTarget.datasetId,
        tableId: salesProductsBigQueryTarget.tableId,
        error,
      });
      throw error;
    }
  }
);

// export const helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });
