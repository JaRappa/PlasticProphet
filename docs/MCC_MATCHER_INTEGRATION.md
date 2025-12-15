# MCC Matcher Integration Guide

## Overview

This document describes the AI-powered MCC (Merchant Category Code) matching system that uses ChatGPT to determine the correct MCC code for a business location based on data from the iOS app.

## Architecture

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   iOS App       │────▶│  API Gateway    │────▶│  Lambda         │
│   (MapKit)      │     │  /mcc-match     │     │  MCCMatcherAPI  │
└─────────────────┘     └─────────────────┘     └────────┬────────┘
                                                         │
                                                         ▼
                                                ┌─────────────────┐
                                                │  OpenAI API     │
                                                │  (ChatGPT)      │
                                                └─────────────────┘
```

## Flow

1. **iOS App detects nearby place** (via MapKit or geofencing)
2. **App sends location data to Lambda** including:
   - Business name
   - Category (from MapKit)
   - Address
   - Coordinates
   - Phone number
   - Website URL
3. **Lambda sends data to ChatGPT** with the full MCC codes list
4. **ChatGPT returns the best matching MCC code** with confidence level
5. **Lambda returns MCC to iOS app**
6. **App uses MCC to determine best credit card** for that purchase category

## Files Created/Modified

### Lambda Function (New)
- `lambda/MCCMatcherAPI/lambda_function.py` - Main Lambda handler
- `lambda/MCCMatcherAPI/mcc_codes.json` - MCC codes database (copied)
- `lambda/MCCMatcherAPI/requirements.txt` - Python dependencies
- `lambda/MCCMatcherAPI/deploy.sh` - Deployment script
- `lambda/MCCMatcherAPI/README.md` - Lambda documentation
- `lambda/MCCMatcherAPI/test_mcc_matcher.py` - Local test script

### iOS App (New)
- `PlasticProphet/MCCMatcherService.swift` - Service to call the MCC API

### iOS App (Modified)
- `PlasticProphet/AppState.swift` - Added MCC matching methods

## Deployment Steps

### 1. Deploy Lambda Function

```bash
cd lambda/MCCMatcherAPI

# Create deployment package
./deploy.sh
```

Or manually:
1. Go to AWS Lambda Console
2. Create function: `MCCMatcherAPI`
3. Runtime: Python 3.11
4. Upload `deployment.zip`
5. Set environment variable: `OPENAI_API_KEY`

### 2. Set OpenAI API Key

In Lambda Console → Configuration → Environment Variables:
- Key: `OPENAI_API_KEY`
- Value: `sk-your-openai-api-key`

### 3. Add API Gateway Route

Add to your existing API Gateway (`0vl413zppl`):
- Method: POST
- Path: `/mcc-match`
- Integration: Lambda `MCCMatcherAPI`
- CORS: Enabled

### 4. Update iOS App

The `MCCMatcherService.swift` is already configured to use:
```swift
CognitoConfig.apiBaseURL + "/mcc-match"
```

Make sure `CognitoConfig.apiBaseURL` points to your API Gateway.

## Usage in iOS App

### Basic Usage
```swift
// Get MCC for a business name
app.fetchMCCForPlace(
    name: "Starbucks Coffee",
    category: "Coffee Shop",
    address: "123 Main St, San Francisco, CA"
)
```

### With MapKit MKMapItem
```swift
let mccMatch = try await MCCMatcherService.shared.matchMCC(for: mapItem)
```

### Direct Service Call
```swift
let mccMatch = try await MCCMatcherService.shared.matchMCC(
    name: "McDonald's",
    category: "Fast Food",
    latitude: 37.7749,
    longitude: -122.4194
)

print("MCC: \(mccMatch.mcc)")        // e.g., "5814"
print("Confidence: \(mccMatch.confidence)")  // "high", "medium", or "low"
print("Description: \(mccMatch.description)")  // "Fast Food Restaurants"
```

## API Reference

### Request
```json
POST /mcc-match
Content-Type: application/json

{
    "name": "Starbucks Coffee",      // Required
    "category": "Coffee Shop",        // Optional
    "address": "123 Main St",         // Optional
    "latitude": 37.7749,              // Optional
    "longitude": -122.4194,           // Optional
    "phoneNumber": "+14155551234",    // Optional
    "url": "https://starbucks.com"    // Optional
}
```

### Response
```json
{
    "mcc": "5814",
    "confidence": "high",
    "description": "Fast Food Restaurants",
    "irs_description": "Fast Food Restaurants",
    "usda_description": "Eating Places and Restaurants",
    "location_name": "Starbucks Coffee"
}
```

## Cost Estimation

- Model: `gpt-4o-mini`
- ~$0.15 per million input tokens
- ~$0.60 per million output tokens
- Each request: ~3,000 input tokens, ~10 output tokens
- **Estimated cost: ~$0.0005 per request** (half a cent)

## Caching Recommendations

To reduce costs and latency for common businesses:

1. **In-memory cache** for Lambda (handles repeated cold starts)
2. **DynamoDB cache** keyed by normalized business name
3. Cache hit rate should be high for chains (Starbucks, McDonald's, etc.)

## Testing

### Local Testing
```bash
cd lambda/MCCMatcherAPI
export OPENAI_API_KEY=sk-your-key
pip install httpx
python test_mcc_matcher.py
```

### Lambda Console Testing
```json
{
    "name": "Starbucks Coffee",
    "category": "Coffee Shop"
}
```

## Troubleshooting

### "OpenAI API key not configured"
Set the `OPENAI_API_KEY` environment variable in Lambda configuration.

### Timeout errors
Increase Lambda timeout to 30 seconds (ChatGPT can take a few seconds).

### CORS errors
Ensure CORS is enabled on the API Gateway endpoint.

## Next Steps

1. Deploy Lambda function
2. Set OpenAI API key
3. Add API Gateway route
4. Test from iOS app
5. Consider adding caching layer for cost optimization
