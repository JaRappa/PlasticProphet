// src/services/merchantService.ts

import { query } from "./db";
import { normalizePoiName } from "../normalization";
import { findMccForMerchantName } from "../mccDirectory";

export interface RollingMerchantRow {
  user_id: number;
  generation_id: string;
  merchant_hash: string;
  raw_poi_name: string | null;
  generalized_name: string | null;
  category_key: string | null;
  mcc: string | null;
  lat: number | null;
  lon: number | null;
  radius_meters: number | null;
  region_identifier: string | null;
  distance_meters: number | null;
  detected_at: string;
  expires_at: string | null;
}

export interface LocationEventPayload {
  userId: number;
  generationId: string;
  merchantHash: string;
  rawPoiName: string;
  lat: number;
  lon: number;
  radiusMeters?: number;
  distanceMeters?: number;
  regionIdentifier?: string;
  detectedAtIso?: string;
}

export async function insertLocationEvent(body: LocationEventPayload): Promise<RollingMerchantRow> {
  const normalized = normalizePoiName(body.rawPoiName);
  const { mcc, categoryKey } = findMccForMerchantName(normalized);

  const rows = await query<RollingMerchantRow>(
    `
    INSERT INTO rolling_merchant (
      user_id,
      generation_id,
      merchant_hash,
      raw_poi_name,
      generalized_name,
      mcc,
      category_key,
      lat,
      lon,
      radius_meters,
      distance_meters,
      region_identifier,
      detected_at
    )
    VALUES (
      $1, $2, $3,
      $4, $5, $6, $7,
      $8, $9,
      $10, $11, $12,
      COALESCE($13::timestamptz, now())
    )
    RETURNING *;
    `,
    [
      body.userId,
      body.generationId,
      body.merchantHash,
      body.rawPoiName,
      normalized,
      mcc,
      categoryKey,
      body.lat,
      body.lon,
      body.radiusMeters ?? null,
      body.distanceMeters ?? null,
      body.regionIdentifier ?? null,
      body.detectedAtIso ?? null
    ]
  );

  return rows[0];
}

export async function getMerchantsForGeneration(userId: number, generationId: string) {
  const rows = await query<RollingMerchantRow>(
    `
    SELECT *
    FROM rolling_merchant
    WHERE user_id = $1
      AND generation_id = $2
    ORDER BY detected_at DESC
    LIMIT 20;
    `,
    [userId, generationId]
  );

  return rows;
}
