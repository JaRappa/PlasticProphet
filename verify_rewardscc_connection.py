# verify_rewardscc_full_lookup.py
import json
import os
import urllib.parse
from pathlib import Path

import pg8000.native as pg
import requests

RAPIDAPI_KEY = os.getenv("RAPIDAPI_KEY", "YOUR_RAPIDAPI_KEY_HERE")
HARDCODED_CARD_QUERY = os.getenv("HARDCODED_CARD_QUERY", "wells fargo")
BASE_URL = "https://rewards-credit-card-api.p.rapidapi.com"
FUZZY_CUTOFF = 0.55  # similarity threshold for typo correction (more tolerant)
WORKINGCARDS_PATH = Path(__file__).with_name("workingcards.json")  # packaged seed only

DB_HOST = os.getenv("DB_HOST")
DB_NAME = os.getenv("DB_NAME")
DB_USER = os.getenv("DB_USER")
DB_PASSWORD = os.getenv("DB_PASSWORD")
DB_PORT = int(os.getenv("DB_PORT", "5432"))
DB_CONNECT_TIMEOUT = float(os.getenv("DB_CONNECT_TIMEOUT", "3"))


def _get_conn():
    if not all([DB_HOST, DB_NAME, DB_USER, DB_PASSWORD]):
        raise RuntimeError("DB connection env vars missing (DB_HOST/DB_NAME/DB_USER/DB_PASSWORD)")
    return pg.Connection(
        user=DB_USER,
        password=DB_PASSWORD,
        host=DB_HOST,
        database=DB_NAME,
        port=DB_PORT,
        timeout=DB_CONNECT_TIMEOUT,
    )


# Common card name aliases for fuzzy matching
CARD_ALIASES = {
    "amex": "american express",
    "citi": "citibank",
    "cap one": "capital one",
    "boa": "bank of america",
}


def _expand_aliases(name: str) -> str:
    """Expand common abbreviations in card names."""
    result = name.lower()
    for abbrev, full in CARD_ALIASES.items():
        if result.startswith(abbrev + " ") or result == abbrev:
            result = result.replace(abbrev, full, 1)
            break
    return result


def _generate_query_variants(raw: str):
    """
    Return a list of search variants to improve hit rate for the API.
    Example: "amex-platinum" => ["amex-platinum", "amex platinum", "american express platinum", "american express platinum card"]
    """
    base = " ".join(raw.strip().lower().replace("_", " ").split())
    variants = [base]

    # Replace hyphens with spaces
    hyphen_space = base.replace("-", " ")
    if hyphen_space not in variants:
        variants.append(hyphen_space)

    # Expand aliases (e.g., "amex gold" -> "american express gold")
    expanded = _expand_aliases(hyphen_space)
    if expanded not in variants:
        variants.append(expanded)

    # Add a common suffix if missing "card"
    if not expanded.endswith(" card"):
        with_card = f"{expanded} card".strip()
        if with_card not in variants:
            variants.append(with_card)

    return variants[:4]


def search_card_by_name(query: str):
    """First try to find the cardKey via /creditcard-detail-namesearch/{query}."""
    headers = {
        "X-RapidAPI-Key": RAPIDAPI_KEY,
        "X-RapidAPI-Host": "rewards-credit-card-api.p.rapidapi.com",
    }

    variants = _generate_query_variants(query)
    print(f"[INFO] Name search variants: {variants}")

    for variant in variants:
        encoded = urllib.parse.quote(variant)
        url = f"{BASE_URL}/creditcard-detail-namesearch/{encoded}"
        print(f"[TRY] name variant: '{variant}'")

        try:
            resp = requests.get(url, headers=headers, timeout=10)
            if resp.status_code != 200:
                print(f"[WARN] {variant} -> {resp.status_code}")
                continue

            data = resp.json()
            if isinstance(data, list) and len(data) > 0:
                card = data[0]
                card_key = card.get("cardKey")
                print(f"[FOUND] {card.get('cardName')} (key: {card_key}) via '{variant}'")
                return card_key, card.get("cardName"), card

            print(f"[WARN] No results for '{variant}'")

        except Exception as e:
            print(f"[ERROR] Name search failed for '{variant}': {e}")

    return None, None, None


def search_card_by_key(card_key: str):
    """
    Try fetching by treating the input directly as a cardKey.
    Returns (cardKey, cardName, cardObj) or (None, None, None).
    """
    if not card_key:
        return None, None, None
    try:
        card = fetch_card_details(card_key)
        if card:
            return card.get("cardKey"), card.get("cardName"), card
    except Exception as exc:
        print(f"[ERROR] Direct key lookup failed: {exc}")
    return None, None, None


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
    """
    Load cached cards from Postgres. Fall back to packaged JSON only if DB load fails.
    """
    try:
        with _get_conn() as conn:
            rows = conn.run("SELECT card_key, card_name FROM working_cards")
            return [{"cardKey": r[0], "cardName": r[1]} for r in rows]
    except Exception as exc:
        print(f"[WARN] DB load failed: {exc}")

    if WORKINGCARDS_PATH.exists():
        try:
            content = WORKINGCARDS_PATH.read_text(encoding="utf-8").strip()
            if content:
                data = json.loads(content)
                return data if isinstance(data, list) else []
        except Exception as sub_exc:
            print(f"[WARN] Could not read {WORKINGCARDS_PATH.name}: {sub_exc}")
    return []


def save_working_card(card_name: str, card_key: str):
    """
    Persist successful card lookups to Postgres (working_cards table).
    """
    clean_name = card_name.strip()
    if not clean_name or not card_key:
        return

    try:
        print(f"[INFO] Connecting to DB {DB_HOST}:{DB_PORT} with user {DB_USER}")
        with _get_conn() as conn:
            print("[INFO] DB connection established")
            conn.run(
                """
                INSERT INTO working_cards (card_key, card_name)
                VALUES (:key, :name)
                ON CONFLICT (card_key)
                DO UPDATE SET card_name = EXCLUDED.card_name, updated_at = now()
                """,
                key=card_key,
                name=clean_name,
            )
            print(f"[INFO] Saved to DB: {clean_name} ({card_key})")
    except Exception as exc:
        print(f"[WARN] Could not persist to DB: {exc}")


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
    expanded_query = _expand_aliases(normalized_query)

    best_key = None
    best_score = 0.0
    for candidate in name_map.keys():
        # quick substring check
        if normalized_query in candidate or candidate in normalized_query:
            score = 1.0
        elif expanded_query in candidate or candidate in expanded_query:
            score = 0.95  # High score for alias match
        else:
            # Compare using both original and expanded query
            score1 = SequenceMatcher(None, normalized_query, candidate).ratio()
            score2 = SequenceMatcher(None, expanded_query, candidate).ratio()
            score = max(score1, score2)
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


def run_lookup(card_name: str):
    """Run the lookup flow without prompting for input (suitable for Lambda tests)."""
    card_name = card_name.strip()
    print(f"=== RewardsCC Lookup (query='{card_name}') ===")

    # First try to resolve locally (exact/fuzzy) to avoid saving typos.
    card_key, canonical_name = find_local_card_match(card_name)
    card_obj = None
    source = "local"
    if not card_key:
        card_key, canonical_name, card_obj = search_card_by_name(card_name)
        source = "name search"

    # Fallback: treat input as a cardKey
    if not card_key:
        card_key, canonical_name, card_obj = search_card_by_key(card_name)
        source = "direct key" if card_key else source

    if card_key:
        card = card_obj or fetch_card_details(card_key)
        if card:
            name_to_store = canonical_name or card.get("cardName") or card_name
            save_working_card(name_to_store, card_key)
            print(f"[OK] Resolved via {source}: {name_to_store} (key: {card_key})")
            return card

    print("\n[INFO] Could not resolve card name to key.")
    return None


def lambda_handler(event=None, context=None):
    """
    AWS Lambda entrypoint.

    Accepts:
      - event.card_name or event.cardName
      - event.body containing JSON (string or dict) with card_name/cardName
    Falls back to HARDCODED_CARD_QUERY only if no card_name is provided.
    """
    card_name = None
    if isinstance(event, dict):
        card_name = event.get("cardName") or event.get("card_name")

        body = event.get("body")
        if body:
            try:
                if isinstance(body, str):
                    body_obj = json.loads(body)
                elif isinstance(body, dict):
                    body_obj = body
                else:
                    body_obj = None
                if body_obj:
                    card_name = card_name or body_obj.get("cardName") or body_obj.get("card_name")
            except (json.JSONDecodeError, TypeError):
                pass

    card_name = card_name or HARDCODED_CARD_QUERY

    result = run_lookup(card_name)
    return {"cardName": card_name, "result": result}


if __name__ == "__main__":
    run_lookup(HARDCODED_CARD_QUERY)
