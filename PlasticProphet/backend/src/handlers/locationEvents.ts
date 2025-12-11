// src/handlers/locationEvents.ts

import { APIGatewayProxyHandler } from "aws-lambda";
import { insertLocationEvent, LocationEventPayload } from "../services/merchantService";
import { loadMccDirectory } from "../mccDirectory";

loadMccDirectory();

export const handler: APIGatewayProxyHandler = async (event) => {
  try {
    const body = JSON.parse(event.body || "{}") as Partial<LocationEventPayload>;

    if (
      !body.userId ||
      !body.generationId ||
      !body.merchantHash ||
      !body.rawPoiName ||
      typeof body.lat !== "number" ||
      typeof body.lon !== "number"
    ) {
      return {
        statusCode: 400,
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ error: "Missing or invalid fields in request body." })
      };
    }

    const payload: LocationEventPayload = {
      userId: body.userId,
      generationId: body.generationId,
      merchantHash: body.merchantHash,
      rawPoiName: body.rawPoiName,
      lat: body.lat,
      lon: body.lon,
      radiusMeters: body.radiusMeters,
      distanceMeters: body.distanceMeters,
      regionIdentifier: body.regionIdentifier,
      detectedAtIso: body.detectedAtIso
    };

    const inserted = await insertLocationEvent(payload);

    return {
      statusCode: 200,
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        message: "Location event stored",
        merchant: inserted
      })
    };
  } catch (err: any) {
    console.error("Error in locationEvents handler:", err);

    return {
      statusCode: 500,
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ error: err.message || "Internal server error" })
    };
  }
};
