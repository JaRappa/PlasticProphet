# ================================
# test_rewards_local.py  (Final Integrated Version)
# ================================
import os
import json
import requests
import sys
import re
from datetime import datetime, UTC

# --------------------------------
# Load MCC codes
# --------------------------------
MCC_PATH = os.path.join(os.path.dirname(__file__), "mcc_codes.json")

with open(MCC_PATH, "r", encoding="utf-8") as f:
    raw_mcc_data = json.load(f)

if isinstance(raw_mcc_data, dict):
    MCC_CODES = {str(k): v for k, v in raw_mcc_data.items()}
elif isinstance(raw_mcc_data, list):
    MCC_CODES = {}
    for e in raw_mcc_data:
        if "mcc" in e:
            category = (
                e.get("category")
                or e.get("edited_description")
                or e.get("combined_description")
                or e.get("usda_description")
                or e.get("irs_description")
            )
            if category:
                MCC_CODES[str(e["mcc"])] = category
else:
    raise ValueError("Unsupported MCC JSON format.")

# --------------------------------
# Config
# --------------------------------
REWARDSCC_BASE_URL = "https://rewards-credit-card-api.p.rapidapi.com"
RAPIDAPI_KEY = os.getenv("RAPIDAPI_KEY", "YOUR_RAPIDAPI_KEY_HERE")

# --------------------------------
# Synonyms (Amex Gold–inspired, expanded)
# --------------------------------
SYNONYMS = {
    "airfare": ["airfare", "airline", "airlines", "flight", "travel", "plane", "air travel", "air"],
    "amextravel": ["amextravel", "amex travel", "amextravel.com", "american express travel"],
    "dining": ["dining", "restaurant", "restaurants", "food", "resy", "grubhub",
               "cheesecake factory", "shake shack", "eats"],
    "grocery": ["grocery", "groceries", "supermarket", "supermarkets", "market", "food store"],
    "uber": ["uber", "uber eats", "rideshare", "ride share", "taxi", "transportation"],
    "dunkin": ["dunkin", "coffee", "donuts"],
    "hotel": ["hotel", "hotels", "lodging", "the hotel collection", "stay"],
    "car_rental": ["car rental", "rental car", "auto rental", "vehicle rental"],
    "baggage": ["baggage", "luggage", "travel insurance", "trip insurance"],
    "entertainment": ["entertainment", "concert", "theater", "events", "preferred access"],
    "gas": ["gas", "fuel", "service station", "gas station"],
    "transit": ["transit", "train", "bus", "subway", "metro", "rideshare"],
    "streaming": ["streaming", "subscription", "tv", "video", "music", "service"],
    "insurance": ["insurance", "coverage", "protection", "assist", "plan"],
}

# --------------------------------
# Utility
# --------------------------------
def words(s):
    return set(re.findall(r"[a-zA-Z]+", s.lower()))

# --------------------------------
# Main testing function
# --------------------------------
def test_rewards_local(merchant_name: str, mcc: str, card_name: str):
    print(f"[INFO] Testing {merchant_name} (MCC {mcc}) on card {card_name}")

    endpoint = f"{REWARDSCC_BASE_URL}/creditcard-detail-bycard/{card_name}"
    headers = {
        "X-RapidAPI-Host": "rewards-credit-card-api.p.rapidapi.com",
        "X-RapidAPI-Key": RAPIDAPI_KEY
    }

    try:
        resp = requests.get(endpoint, headers=headers, timeout=10)
        resp.raise_for_status()
        data = resp.json()
    except requests.exceptions.RequestException as e:
        print(f"[ERROR] API request failed: {e}")
        return None

    if isinstance(data, list):
        data = data[0] if data else None
    if not data:
        print("[ERROR] Empty API response.")
        return None

    bonus_categories = data.get("spendBonusCategory", [])
    benefits = data.get("benefit", [])

    # === Discovery output ===
    if bonus_categories:
        print("[DISCOVERY] === SPEND BONUS CATEGORIES ===")
        for c in bonus_categories:
            print(f" • {c['spendBonusCategoryName']} → multiplier {c['earnMultiplier']} , "
                  f"description: {c['spendBonusDesc']}")
    else:
        print("[DISCOVERY] No spend bonus categories found.")

    if benefits:
        print("[DISCOVERY] === ISSUER BENEFITS ===")
        for b in benefits:
            print(f" • {b['benefitTitle']}: {b['benefitDesc']}")
    else:
        print("[DISCOVERY] No issuer benefits found.")

    # === Reward Logic ===
    normalized = merchant_name.lower()
    matched_benefits = []

    # 1️⃣ Match issuer benefits (Dunkin, Uber, Dining, etc.)
    if isinstance(benefits, list):
        for benefit in benefits:
            title = benefit.get("benefitTitle", "").lower()
            desc = benefit.get("benefitDesc", "").lower()
            if any(term in title or term in desc for term in normalized.split()):
                matched_benefits.append({
                    "benefitTitle": benefit.get("benefitTitle"),
                    "benefitDesc": benefit.get("benefitDesc")
                })

    # 2️⃣ MCC + Synonym semantic matching
    category = MCC_CODES.get(mcc, "Unknown Merchant Category").lower()
    print(f"[DEBUG] MCC {mcc} maps to category: '{category}'")

    match = None
    best_score = 0

    for cat in bonus_categories:
        cat_name = cat.get("spendBonusCategoryName", "").lower()
        cat_words = words(cat_name)
        mcc_words = words(category)
        score = len(cat_words & mcc_words)

        for terms in SYNONYMS.values():
            if any(t in category for t in terms) and any(t in cat_name for t in terms):
                score += 2

        if score > best_score:
            best_score = score
            match = cat

    # 3️⃣ Result assembly
    if match and best_score > 0:
        result = {
            "source": "mcc_match",
            "card_name": data.get("cardName", card_name),
            "reward_rate": match.get("earnMultiplier", 1.0),
            "category": match.get("spendBonusCategoryName"),
            "description": match.get("spendBonusDesc"),
        }
        if matched_benefits:
            result["related_benefits"] = matched_benefits
        print(json.dumps(result, indent=2))
        return result

    # 4️⃣ Fallback
    base = data.get("baseSpendAmount", 1.0)
    result = {
        "source": "base_rate",
        "card_name": data.get("cardName", card_name),
        "reward_rate": base,
        "description": "Default base rate (no category or benefit match)"
    }
    if matched_benefits:
        result["related_benefits"] = matched_benefits
    print(json.dumps(result, indent=2))
    return result


# --------------------------------
# Entry point
# --------------------------------
if __name__ == "__main__":
    if len(sys.argv) < 4:
        print("Usage: python test_rewards_local.py <merchant> <mcc> <card_slug>")
        print("Example: python test_rewards_local.py Dining 5812 amex-gold")
        sys.exit(1)

    merchant_name = sys.argv[1]
    mcc = sys.argv[2]
    card_name = sys.argv[3]

    test_rewards_local(merchant_name, mcc, card_name)
