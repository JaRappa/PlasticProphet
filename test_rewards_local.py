# ================================
# test_rewards_local.py
# ================================
import os
import json
import requests
import sys
import re

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
# Optional default card for local testing or when upstream does not supply one
DEFAULT_CARD_NAME = os.getenv("DEFAULT_CARD_NAME")

# --------------------------------
# Synonyms (Amex Gold inspired, expanded)
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
def words(s: str):
    return set(re.findall(r"[a-zA-Z]+", s.lower()))


# --------------------------------
# Pure reward matching logic
# --------------------------------
def match_reward(merchant_name: str, mcc: str, card_name: str, api_data: dict):
    """Pure matching logic: given merchant, mcc, and card API payload, decide reward."""
    if not merchant_name or not mcc or not card_name:
        return {"error": "merchant_name, mcc, and card_name are required"}

    bonus_categories = api_data.get("spendBonusCategory", []) or []
    benefits = api_data.get("benefit", []) or []
    base_rate = api_data.get("baseSpendAmount", 1.0)
    card_label = api_data.get("cardName", card_name)

    merchant_words = words(merchant_name)
    mcc_category = MCC_CODES.get(str(mcc), "").lower()
    mcc_words = words(mcc_category)
    merchant_lower = merchant_name.lower()
    card_lower = card_label.lower()

    # Generic words that shouldn't drive category matches
    STOPWORDS = {"store", "stores", "market", "markets"}

    # 1) Merchant-specific benefits take precedence (e.g., Dunkin credit)
    merchant_benefits = []
    for benefit in benefits:
        title = benefit.get("benefitTitle", "")
        desc = benefit.get("benefitDesc", "")
        if merchant_words & (words(title) | words(desc)):
            merchant_benefits.append({
                "benefitTitle": benefit.get("benefitTitle"),
                "benefitDesc": benefit.get("benefitDesc")
            })
    if merchant_benefits:
        return {
            "source": "benefit_match",
            "card_name": card_label,
            "reward_rate": None,
            "category": None,
            "description": "Issuer benefit match for merchant",
            "related_benefits": merchant_benefits,
        }

    # 2) Bonus category match (MCC + merchant keywords + synonyms)
    best = None
    best_score = 0

    for cat in bonus_categories:
        cat_name = cat.get("spendBonusCategoryName", "").lower()
        cat_words = words(cat_name)

        # Overlap on MCC category words (discounting stopwords)
        mcc_overlap = len((cat_words & mcc_words) - STOPWORDS)
        score = mcc_overlap * 2  # MCC-driven matches are weighted highest

        # Synonym-based match (only if both MCC category and cat name carry the synonym)
        for syn_terms in SYNONYMS.values():
            if any(t in mcc_category for t in syn_terms) and any(t in cat_name for t in syn_terms):
                score += 2

        # Merchant keyword overlap only helps when MCC category is unknown/weak
        if not mcc_category:
            score += len(cat_words & merchant_words)

        if score > best_score and score > 0:
            best_score = score
            best = cat

    # 3) Brand-affinity fallback: if card name contains the merchant brand, prefer the top multiplier
    if best is None and (merchant_lower in card_lower or any(w in card_lower for w in merchant_words)):
        if bonus_categories:
            def safe_multiplier(cat):
                try:
                    return float(cat.get("earnMultiplier", 0))
                except (TypeError, ValueError):
                    return 0.0
            brand_cat = max(bonus_categories, key=safe_multiplier)
            return {
                "source": "brand_affinity",
                "card_name": card_label,
                "reward_rate": brand_cat.get("earnMultiplier", base_rate),
                "category": brand_cat.get("spendBonusCategoryName"),
                "description": brand_cat.get("spendBonusDesc"),
                "related_benefits": None,
            }

    if best and best_score > 0:
        return {
            "source": "mcc_match",
            "card_name": card_label,
            "reward_rate": best.get("earnMultiplier", base_rate),
            "category": best.get("spendBonusCategoryName"),
            "description": best.get("spendBonusDesc"),
            "related_benefits": None,
        }

    return {
        "source": "base_rate",
        "card_name": card_label,
        "reward_rate": base_rate,
        "description": "Default base rate (no category or benefit match)",
        "related_benefits": None,
    }


# --------------------------------
# Main testing function
# --------------------------------
def test_rewards_local(merchant_name: str, mcc: str, card_name: str | None, suppress_output: bool = False):
    """Fetch card data and match merchant/mcc to the best reward."""
    if RAPIDAPI_KEY in ("", "YOUR_RAPIDAPI_KEY_HERE"):
        if not suppress_output:
            print("[ERROR] RAPIDAPI_KEY is not set")
        return None

    if not merchant_name or not mcc:
        if not suppress_output:
            print("[ERROR] merchant_name and mcc are required")
        return None

    # Use provided card_name or fall back to DEFAULT_CARD_NAME for local testing
    card_name = card_name or DEFAULT_CARD_NAME
    if not card_name:
        if not suppress_output:
            print("[ERROR] card_name is required (set DEFAULT_CARD_NAME or pass card_name)")
        return None

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
        if not suppress_output:
            print(f"[ERROR] API request failed: {e}")
        return None

    if isinstance(data, list):
        data = data[0] if data else None
    if not data:
        if not suppress_output:
            print("[ERROR] Empty API response.")
        return None

    # === Reward Logic ===
    result = match_reward(merchant_name, mcc, card_name, data)

    # Only emit when we found a meaningful match; otherwise stay quiet
    if result and result.get("source") in {"benefit_match", "mcc_match", "brand_affinity"}:
        if result.get("source") == "benefit_match" and result.get("related_benefits"):
            if not suppress_output:
                print(json.dumps(result["related_benefits"], indent=2))
        elif not suppress_output:
            print(json.dumps(result, indent=2))
        return result

    # No meaningful reward found
    return None


# --------------------------------
# AWS Lambda handler
# --------------------------------
def lambda_handler(event, context=None):
    """
    Lambda entry.

    Accepts either direct keys on event (merchant_name, mcc, card_name) or an
    upstream Lambda-style response with a JSON body containing mcc and
    location_name. card_name still needs to be provided at the top level.
    """
    merchant_name = None
    mcc = None
    card_name = None

    if isinstance(event, dict):
        card_name = event.get("card_name")
        merchant_name = event.get("merchant_name")
        mcc = event.get("mcc")

        # If an upstream Lambda response is passed in, parse its body
        body = event.get("body")
        if body:
            try:
                # body may be a JSON string; if already a dict, json.loads will raise TypeError
                if isinstance(body, str):
                    body_obj = json.loads(body)
                elif isinstance(body, dict):
                    body_obj = body
                else:
                    body_obj = None
                if body_obj:
                    merchant_name = merchant_name or body_obj.get("location_name")
                    mcc = mcc or body_obj.get("mcc")
            except (json.JSONDecodeError, TypeError):
                pass

    if RAPIDAPI_KEY in ("", "YOUR_RAPIDAPI_KEY_HERE"):
        return {"error": "RAPIDAPI_KEY is not set"}

    if not merchant_name or not mcc:
        return {"error": "merchant_name and mcc are required"}

    # Use provided card_name or fall back to DEFAULT_CARD_NAME
    card_name = card_name or DEFAULT_CARD_NAME
    if not card_name:
        return {"error": "card_name is required (set DEFAULT_CARD_NAME or pass card_name)"}

    result = test_rewards_local(merchant_name, str(mcc), card_name, suppress_output=True)
    if result is None:
        return {"error": "No reward match found"}
    return result


# --------------------------------
# Entry point
# --------------------------------
if __name__ == "__main__":
    args = sys.argv[1:]
    if len(args) < 2:
        print("Usage: python test_rewards_local.py <merchant> <mcc> [card_slug]")
        print("Example: python test_rewards_local.py Dining 5812 amex-gold")
        print("Or set DEFAULT_CARD_NAME env var to omit card_slug.")
        sys.exit(1)

    merchant_name = args[0]
    mcc = args[1]
    card_name = args[2] if len(args) > 2 else DEFAULT_CARD_NAME

    test_rewards_local(merchant_name, mcc, card_name)
