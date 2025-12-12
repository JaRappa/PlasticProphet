# verify_rewardscc_full_lookup.py
import json
import os
import urllib.parse
from pathlib import Path

import requests

RAPIDAPI_KEY = os.getenv("RAPIDAPI_KEY", "YOUR_RAPIDAPI_KEY_HERE")
BASE_URL = "https://rewards-credit-card-api.p.rapidapi.com"
WORKINGCARDS_PATH = Path(__file__).with_name("workingcards.json")
FUZZY_CUTOFF = 0.6  # similarity threshold for typo correction (more tolerant)


def search_card_by_name(query: str):
    """First try to find the cardKey via /creditcard-detail-namesearch/{query}."""
    headers = {
        "X-RapidAPI-Key": RAPIDAPI_KEY,
        "X-RapidAPI-Host": "rewards-credit-card-api.p.rapidapi.com",
    }

    normalized = query.strip().lower()
    encoded = urllib.parse.quote(normalized)

    url = f"{BASE_URL}/creditcard-detail-namesearch/{encoded}"
    print(f"[INFO] Searching by name: {url}")

    try:
        resp = requests.get(url, headers=headers, timeout=10)
        print(f"[DEBUG] Status: {resp.status_code}")
        if resp.status_code != 200:
            print(f"[ERROR] API returned {resp.status_code}: {resp.text[:200]}")
            return None, None

        data = resp.json()
        if isinstance(data, list) and len(data) > 0:
            card = data[0]
            card_key = card.get("cardKey")
            print(f"[FOUND CARD] {card.get('cardName')} (key: {card_key})")
            return card_key, card.get("cardName")

        print("[WARN] No results found for query.")
        return None, None

    except Exception as e:
        print(f"[ERROR] Name search failed: {e}")
        return None, None


def fetch_card_details(card_key: str):
    """Fetch full details for a specific cardKey."""
    headers = {
        "X-RapidAPI-Key": RAPIDAPI_KEY,
        "X-RapidAPI-Host": "rewards-credit-card-api.p.rapidapi.com",
    }

    url = f"{BASE_URL}/creditcard-detail-bycard/{card_key}"
    print(f"[INFO] Fetching full details: {url}")

    try:
        resp = requests.get(url, headers=headers, timeout=10)
        print(f"[DEBUG] Status: {resp.status_code}")
        data = resp.json()

        if isinstance(data, list) and len(data) > 0:
            card = data[0]
        elif isinstance(data, dict):
            card = data
        else:
            print("[ERROR] Unexpected response format")
            print(json.dumps(data, indent=2))
            return None

        print("\n[FULL CARD DETAILS]")
        print(f"Card Name: {card.get('cardName')}")
        print(f"Card Key: {card.get('cardKey')}")
        print(f"Issuer: {card.get('cardIssuer')}")
        print(f"Network: {card.get('cardNetwork')}")
        print(f"Annual Fee: ${card.get('annualFee')}")
        print(f"Base Reward: {card.get('baseSpendAmount')}x {card.get('baseSpendEarnCategory')}")

        print("\nTop Reward Categories:")
        for cat in card.get("spendBonusCategory", []):
            print(
                f" - {cat.get('spendBonusCategoryName')}: "
                f"{cat.get('earnMultiplier')}x + {cat.get('spendBonusDesc')}"
            )

        return card

    except Exception as e:
        print(f"[ERROR] Detail lookup failed: {e}")
        return None


def _load_working_cards():
    """Read workingcards.json; gracefully handle missing/invalid file."""
    if not WORKINGCARDS_PATH.exists():
        return []

    try:
        content = WORKINGCARDS_PATH.read_text(encoding="utf-8").strip()
        if not content:
            return []
        data = json.loads(content)
        return data if isinstance(data, list) else []
    except Exception as exc:
        print(f"[WARN] Could not read {WORKINGCARDS_PATH.name}: {exc}")
        return []


def save_working_card(card_name: str, card_key: str):
    """
    Persist successful card lookups to workingcards.json as
    [{'cardName': ..., 'cardKey': ...}, ...].
    """
    clean_name = card_name.strip()
    if not clean_name or not card_key:
        return

    cards = _load_working_cards()
    if not any(entry.get("cardKey") == card_key for entry in cards):
        cards.append({"cardName": clean_name, "cardKey": card_key})
    else:
        for entry in cards:
            if entry.get("cardKey") == card_key:
                entry["cardName"] = clean_name
                break

    try:
        WORKINGCARDS_PATH.write_text(json.dumps(cards, indent=2), encoding="utf-8")
        print(f"[INFO] Saved to {WORKINGCARDS_PATH.name}")
    except Exception as exc:
        print(f"[WARN] Could not write {WORKINGCARDS_PATH.name}: {exc}")


def _normalize_name(name: str) -> str:
    return " ".join(name.lower().split())


def find_local_card_match(query: str):
    """
    Attempt to match the input against saved working cards, allowing typo correction.
    Returns (cardKey, canonicalName) or (None, None) if no close match.
    """
    from difflib import SequenceMatcher

    cards = _load_working_cards()
    if not cards:
        print("[INFO] No local cards in workingcards.json to match against.")
        return None, None

    name_map = {_normalize_name(c.get("cardName", "")): c for c in cards if c.get("cardName")}
    normalized_query = _normalize_name(query)

    best_key = None
    best_score = 0.0
    for candidate in name_map.keys():
        # quick substring check
        if normalized_query in candidate or candidate in normalized_query:
            score = 1.0
        else:
            score = SequenceMatcher(None, normalized_query, candidate).ratio()
        if score > best_score:
            best_score = score
            best_key = candidate

    if not best_key or best_score < FUZZY_CUTOFF:
        return None, None

    match = name_map.get(best_key)
    if match and match.get("cardKey"):
        print(
            f"[INFO] Matched local card '{match.get('cardName')}' "
            f"from workingcards.json (similarity: {best_score:.2f})"
        )
        return match.get("cardKey"), match.get("cardName")

    return None, None


if __name__ == "__main__":
    print("=== RewardsCC Full Lookup Test ===")
    user_input = input(
        "Enter card name (e.g. 'amex gold', 'chase sapphire preferred', 'discover it cash back'): "
    ).strip()

    # First try to resolve locally (exact/fuzzy) to avoid saving typos.
    card_key, canonical_name = find_local_card_match(user_input)
    if not card_key:
        card_key, canonical_name = search_card_by_name(user_input)

    if card_key:
        card = fetch_card_details(card_key)
        if card:
            name_to_store = canonical_name or card.get("cardName") or user_input
            save_working_card(name_to_store, card_key)
    else:
        print("\n[INFO] Could not resolve card name to key.")
