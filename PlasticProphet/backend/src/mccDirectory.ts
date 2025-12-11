// src/mccDirectory.ts

import fs from "fs";
import path from "path";

export interface McgreggleRecord {
  mcc: string;
  edited_description?: string;
  combined_description?: string;
  usda_description?: string;
  irs_description?: string;
  irs_reportable?: string;
  id?: number;
}

let mcgreggleData: McgreggleRecord[] = [];

export function loadMccDirectory() {
  if (mcgreggleData.length > 0) {
    return;
  }

  const filePath = path.join(__dirname, "data", "mcc_codes.json");
  const raw = fs.readFileSync(filePath, "utf8");
  const parsed = JSON.parse(raw) as McgreggleRecord[];

  mcgreggleData = parsed;

  console.log(`Loaded ${mcgreggleData.length} McGreggle MCC records.`);
}

export function getMccInfoByCode(mcc: string | null): McgreggleRecord | null {
  if (!mcc) return null;
  return mcgreggleData.find((rec) => rec.mcc === mcc) ?? null;
}

export function findMccForMerchantName(
  generalizedName: string
): { mcc: string | null; categoryKey: string | null } {
  const key = generalizedName.toUpperCase().trim();

  const match = mcgreggleData.find((rec) => {
    const edited = (rec.edited_description ?? "").toUpperCase().trim();
    const combined = (rec.combined_description ?? "").toUpperCase().trim();

    if (!edited && !combined) return false;

    if (edited === key || combined === key) return true;

    if (edited && (key.includes(edited) || edited.includes(key))) return true;
    if (combined && (key.includes(combined) || combined.includes(key)))
      return true;

    return false;
  });

  if (!match) {
    return { mcc: null, categoryKey: null };
  }

  const categoryKey = match.irs_description ?? match.usda_description ?? null;

  return {
    mcc: match.mcc,
    categoryKey,
  };
}
