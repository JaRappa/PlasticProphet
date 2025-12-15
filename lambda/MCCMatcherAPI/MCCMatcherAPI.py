import json
import os
import httpx

# Load MCC codes on cold start
MCC_CODES = []

def load_mcc_codes():
    """Load MCC codes from bundled JSON file."""
    global MCC_CODES
    if MCC_CODES:
        return
    
    try:
        current_dir = os.path.dirname(os.path.abspath(__file__))
        file_path = os.path.join(current_dir, 'mcc_codes.json')
        
        with open(file_path, 'r') as f:
            MCC_CODES = json.load(f)
        
        print(f"✅ Loaded {len(MCC_CODES)} MCC records")
    except Exception as e:
        print(f"❌ Error loading MCC codes: {e}")
        MCC_CODES = []


def get_simplified_mcc_list():
    """
    Create a simplified list of MCC codes for the ChatGPT prompt.
    Only include code and description to minimize tokens.
    """
    simplified = []
    for record in MCC_CODES:
        mcc = record.get('mcc', '')
        desc = record.get('edited_description') or record.get('combined_description', '')
        if mcc and desc:
            simplified.append(f"{mcc}: {desc}")
    return simplified


def call_chatgpt_for_mcc(location_data: dict, openai_api_key: str) -> dict:
    """
    Call ChatGPT API to determine the best MCC code for a location.
    
    Args:
        location_data: Dict with name, category, address, etc.
        openai_api_key: OpenAI API key
    
    Returns:
        Dict with 'mcc' and 'confidence' fields
    """
    
    mcc_list = get_simplified_mcc_list()
    mcc_list_text = "\n".join(mcc_list)
    
    # Build location description
    location_desc = f"Business Name: {location_data.get('name', 'Unknown')}"
    if location_data.get('category'):
        location_desc += f"\nCategory: {location_data.get('category')}"
    if location_data.get('address'):
        location_desc += f"\nAddress: {location_data.get('address')}"
    if location_data.get('phoneNumber'):
        location_desc += f"\nPhone: {location_data.get('phoneNumber')}"
    if location_data.get('url'):
        location_desc += f"\nWebsite: {location_data.get('url')}"
    
    system_prompt = """You are an expert at categorizing businesses into Merchant Category Codes (MCC).
Your task is to analyze a business/location and return the SINGLE most appropriate MCC code from the provided list.

Rules:
1. Return ONLY a JSON object with 'mcc' (the 4-digit code) and 'confidence' (high/medium/low)
2. Choose the most specific matching category
3. If the business could fit multiple categories, choose the primary business activity
4. For restaurants, consider the type (fast food = 5814, full service = 5812)
5. For stores, consider what they primarily sell
6. If truly uncertain, use a general category but mark confidence as 'low'

Example response: {"mcc": "5812", "confidence": "high"}"""

    user_prompt = f"""Based on this location information, determine the most appropriate MCC code.

LOCATION INFORMATION:
{location_desc}

AVAILABLE MCC CODES:
{mcc_list_text}

Return ONLY a JSON object with 'mcc' and 'confidence' fields. No other text."""

    try:
        with httpx.Client(timeout=30.0) as client:
            response = client.post(
                "https://api.openai.com/v1/chat/completions",
                headers={
                    "Authorization": f"Bearer {openai_api_key}",
                    "Content-Type": "application/json"
                },
                json={
                    "model": "gpt-4o-mini",  # Cost-effective and fast
                    "messages": [
                        {"role": "system", "content": system_prompt},
                        {"role": "user", "content": user_prompt}
                    ],
                    "temperature": 0.1,  # Low temperature for consistent results
                    "max_tokens": 50
                }
            )
            
            response.raise_for_status()
            result = response.json()
            
            # Extract the assistant's message
            content = result['choices'][0]['message']['content'].strip()
            
            # Parse JSON response
            # Handle potential markdown code blocks
            if content.startswith('```'):
                content = content.split('```')[1]
                if content.startswith('json'):
                    content = content[4:]
                content = content.strip()
            
            mcc_result = json.loads(content)
            
            return {
                'mcc': mcc_result.get('mcc'),
                'confidence': mcc_result.get('confidence', 'medium')
            }
            
    except httpx.HTTPStatusError as e:
        print(f"❌ OpenAI API error: {e.response.status_code} - {e.response.text}")
        raise Exception(f"OpenAI API error: {e.response.status_code}")
    except json.JSONDecodeError as e:
        print(f"❌ Failed to parse ChatGPT response: {content}")
        raise Exception(f"Invalid response from ChatGPT: {content}")
    except Exception as e:
        print(f"❌ Error calling ChatGPT: {e}")
        raise


def get_mcc_details(mcc_code: str) -> dict:
    """Get full MCC details from the loaded codes."""
    for record in MCC_CODES:
        if record.get('mcc') == mcc_code:
            return {
                'mcc': mcc_code,
                'description': record.get('edited_description') or record.get('combined_description'),
                'irs_description': record.get('irs_description'),
                'usda_description': record.get('usda_description')
            }
    return {'mcc': mcc_code, 'description': 'Unknown'}


def lambda_handler(event, context):
    """
    Lambda handler for MCC code matching using ChatGPT.
    
    Expected input:
    {
        "name": "Starbucks",
        "category": "Coffee Shop",        # Optional - from MapKit
        "address": "123 Main St",         # Optional
        "latitude": 37.3382,              # Optional
        "longitude": -122.0309,           # Optional
        "phoneNumber": "+1234567890",     # Optional
        "url": "https://starbucks.com"    # Optional
    }
    
    Returns:
    {
        "mcc": "5814",
        "description": "Fast Food Restaurants",
        "confidence": "high",
        "irs_description": "Fast Food Restaurants"
    }
    """
    # Load MCC codes if not already loaded
    load_mcc_codes()
    
    try:
        # Parse input - handle both direct invocation and API Gateway
        if isinstance(event.get('body'), str):
            body = json.loads(event['body'])
        else:
            body = event
        
        # Extract location data
        location_data = {
            'name': body.get('name'),
            'category': body.get('category'),
            'address': body.get('address'),
            'latitude': body.get('latitude'),
            'longitude': body.get('longitude'),
            'phoneNumber': body.get('phoneNumber'),
            'url': body.get('url')
        }
        
        # Validate required field
        if not location_data.get('name'):
            return {
                'statusCode': 400,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                'body': json.dumps({
                    'error': 'Missing required field: name'
                })
            }
        
        # Get OpenAI API key from environment
        openai_api_key = os.environ.get('OPENAI_API_KEY')
        if not openai_api_key:
            return {
                'statusCode': 500,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                'body': json.dumps({
                    'error': 'OpenAI API key not configured'
                })
            }
        
        # Call ChatGPT to determine MCC
        print(f"🔍 Matching MCC for: {location_data.get('name')}")
        mcc_result = call_chatgpt_for_mcc(location_data, openai_api_key)
        
        # Get full MCC details
        mcc_details = get_mcc_details(mcc_result['mcc'])
        
        response_data = {
            'mcc': mcc_result['mcc'],
            'confidence': mcc_result['confidence'],
            'description': mcc_details.get('description'),
            'irs_description': mcc_details.get('irs_description'),
            'usda_description': mcc_details.get('usda_description'),
            'location_name': location_data.get('name')
        }
        
        print(f"✅ Matched {location_data.get('name')} → MCC {mcc_result['mcc']} ({mcc_result['confidence']})")
        
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps(response_data)
        }
        
    except Exception as e:
        print(f"❌ Error: {str(e)}")
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'error': str(e)
            })
        }
