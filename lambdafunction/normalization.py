import re

# Manual overrides for specific messy names
MANUAL_OVERRIDES = {
    "DUNKIN DONUTS": "DUNKIN",
    "DUNKIN D": "DUNKIN",
    "STARBUCKS COFFEE": "STARBUCKS",
    # Add more as you discover them
}


def normalize_poi_name(raw):
    """
    Normalize a raw POI name from MapKit into a "generalized" name.
    
    Args:
        raw (str): Raw merchant/POI name
    
    Returns:
        str: Normalized merchant name
    """
    if not raw:
        return ""
    
    # Convert to uppercase
    cleaned = raw.upper()
    
    # Remove special characters, keep only alphanumeric and ampersand
    cleaned = re.sub(r'[^A-Z0-9& ]+', ' ', cleaned)
    
    # Remove extra spaces
    cleaned = re.sub(r'\s+', ' ', cleaned).strip()
    
    # Apply manual overrides
    if cleaned in MANUAL_OVERRIDES:
        cleaned = MANUAL_OVERRIDES[cleaned]
    
    return cleaned
