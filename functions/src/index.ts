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
const DATASET_ID = "ecommerceapp-auth-db-cleana.sales_analytics";
const TABLE_ID = "ecommerceapp-auth-db-cleana.sales_analytics.sales";

type BigQueryTarget = {
  projectId?: string;
  datasetId: string;
  tableId: string;
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

const bigQueryTarget = parseBigQueryTarget(DATASET_ID, TABLE_ID);
const bigQueryClient = new BigQuery({projectId: bigQueryTarget.projectId});

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

    const saleRow = {
      exportEventId: event.id,
      saleDocumentId: event.params.saleId,
      exportedAt: new Date().toISOString(),
      firestoreCollection: "sales",
      payload: saleData,
    };

    try {
      await bigQueryClient
        .dataset(bigQueryTarget.datasetId)
        .table(bigQueryTarget.tableId)
        .insert([saleRow], {ignoreUnknownValues: true});

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

// export const helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });
