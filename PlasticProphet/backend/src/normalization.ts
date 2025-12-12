// src/normalization.ts

// Optional manual overrides for specific messy names
const MANUAL_OVERRIDES: Record<string, string> = {
  "DUNKIN DONUTS": "DUNKIN",
  "DUNKIN D": "DUNKIN",
  "STARBUCKS COFFEE": "STARBUCKS"
  // Add more as you discover them
};

/**
 * Normalize a raw POI name from MapKit into a "generalized" name.
 */
export function normalizePoiName(raw: string): string {
  if (!raw) return "";

  let cleaned = raw
    .toUpperCase()
    .replace(/[^A-Z0-9& ]+/g, " ")
    .replace(/\s+/g, " ")
    .trim();

  if (MANUAL_OVERRIDES[cleaned]) {
    cleaned = MANUAL_OVERRIDES[cleaned];
  }

  return cleaned;
}
