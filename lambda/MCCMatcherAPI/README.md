# MCCMatcherAPI Lambda Function

This Lambda function matches business/location names to MCC (Merchant Category Codes) using ChatGPT.

## Overview

The function receives location data (name, category, address, etc.) from the iOS app and uses the OpenAI ChatGPT API to determine the most appropriate MCC code from the standard list of ~800 MCC codes.

## Input

```json
{
    "name": "Starbucks",           // Required - Business name
    "category": "Coffee Shop",     // Optional - MapKit POI category
    "address": "123 Main St",      // Optional - Street address
    "latitude": 37.3382,           // Optional - Coordinates
    "longitude": -122.0309,
    "phoneNumber": "+1234567890",  // Optional - Phone number
    "url": "https://starbucks.com" // Optional - Website URL
}
```

## Output

```json
{
    "mcc": "5814",
    "confidence": "high",
    "description": "Fast Food Restaurants",
    "irs_description": "Fast Food Restaurants",
    "usda_description": "Eating Places and Restaurants",
    "location_name": "Starbucks"
}
```

## Setup

### 1. Create Lambda Function

In AWS Console:
1. Go to Lambda → Create function
2. Name: `MCCMatcherAPI`
3. Runtime: Python 3.11
4. Architecture: x86_64

### 2. Deploy Code

```bash
# Make deploy script executable
chmod +x deploy.sh

# Run deployment
./deploy.sh
```

Or manually upload `deployment.zip` to the Lambda function.

### 3. Configure Environment Variables

In Lambda Console → Configuration → Environment Variables:

| Key | Value |
|-----|-------|
| `OPENAI_API_KEY` | `sk-your-openai-api-key` |

### 4. Set Up API Gateway

Add a route to your existing API Gateway:
- Method: POST
- Path: `/mcc-match`
- Integration: Lambda function `MCCMatcherAPI`

### 5. Configure Lambda Settings

Recommended settings:
- Memory: 256 MB
- Timeout: 30 seconds (ChatGPT can take a few seconds)
- No VPC needed (doesn't access RDS)

## Cost Considerations

- Uses `gpt-4o-mini` model (~$0.15 per million input tokens, $0.60 per million output tokens)
- Each request uses ~2000-4000 input tokens (MCC list + location data)
- Output is minimal (~10 tokens)
- **Estimated cost: ~$0.001 per request**

## Caching Suggestions

To reduce API costs and latency:
1. Cache results in DynamoDB or RDS keyed by normalized business name
2. Check cache before calling ChatGPT
3. Cache hit rate should be high for chain businesses (Starbucks, McDonald's, etc.)

## Files

- `lambda_function.py` - Main Lambda handler
- `mcc_codes.json` - Standard MCC codes (bundled with deployment)
- `requirements.txt` - Python dependencies (httpx)
- `deploy.sh` - Deployment script

## Testing

Test event in Lambda Console:

```json
{
    "name": "Starbucks Coffee",
    "category": "Coffee Shop",
    "address": "123 Main St, San Francisco, CA"
}
```

Expected response:
```json
{
    "statusCode": 200,
    "body": "{\"mcc\": \"5814\", \"confidence\": \"high\", ...}"
}
```
