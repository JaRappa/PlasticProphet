// src/handlers/getMerchants.ts

import { APIGatewayProxyHandler } from "aws-lambda";
import { getMerchantsForGeneration } from "../services/merchantService";
import { getMccInfoByCode, loadMccDirectory } from "../mccDirectory";

loadMccDirectory();

export const handler: APIGatewayProxyHandler = async (event) => {
  try {
    const userIdRaw = event.queryStringParameters?.userId;
    const generationId = event.queryStringParameters?.generationId || "";

    const userId = userIdRaw ? Number(userIdRaw) : NaN;

    if (!userIdRaw || Number.isNaN(userId) || !generationId) {
      return {
        statusCode: 400,
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ error: "userId and generationId are required query params." })
      };
    }

    const rows = await getMerchantsForGeneration(userId, generationId);

    const enriched = rows.map((row) => {
      const info = getMccInfoByCode(row.mcc);
      return {
        ...row,
        mcc_label: info?.edited_description ?? info?.combined_description ?? null,
        mcc_irs_category: info?.irs_description ?? null
      };
    });

    return {
      statusCode: 200,
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        userId,
        generationId,
        count: enriched.length,
        merchants: enriched
      })
    };
  } catch (err: any) {
    console.error("Error in getMerchants handler:", err);

    return {
      statusCode: 500,
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ error: err.message || "Internal server error" })
    };
  }
};
