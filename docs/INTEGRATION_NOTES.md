# Backend Integration - Merchant Data Pipeline

## ✅ What's Now Connected

The iOS app now has a **complete pipeline** to fetch and use normalized merchant data from your backend:

### Flow:
1. **Geofence Triggered** → `LocationService.didEnterRegion` fires
2. **AppState Notified** → `onMerchantRegionEntered` callback triggers
3. **Backend API Called** → `MerchantNetworkService.fetchNormalizedMerchant()`
4. **Data Retrieved** → Backend normalizes the merchant name and returns MCC codes
5. **Recommendation Created** → AppState builds a recommendation using real MCC category data
6. **UI Updates** → Latest recommendation is displayed to the user

## Files Modified/Created

### New File: `MerchantNetworkService.swift`
- Makes HTTP GET requests to your backend API
- Decodes normalized merchant responses
- Handles errors gracefully with fallback to mock data
- Query parameters: `merchantName`, `userId`, `generationId`

### Updated: `AppState.swift`
- Added `merchantNetworkService` property
- Added `lastNormalizedMerchant` published property (stores backend response)
- Created `fetchNormalizedMerchantData()` - calls backend when geofence fires
- Created `createRecommendationFromNormalizedData()` - builds recommendations using MCC categories
- Kept `fetchRecommendation()` as fallback for offline scenarios

## Configuration Needed

Update the `baseURL` in `MerchantNetworkService.swift` with your actual API Gateway URL:

```swift
init(baseURL: String = "https://YOUR-API-GATEWAY-URL.execute-api.us-east-1.amazonaws.com/prod",
     session: URLSession = .shared) {
```

## What Your Backend Should Return

The iOS app expects a `NormalizedMerchantResponse` with:
```json
{
  "merchant_name": "STARBUCKS",
  "generalized_name": "STARBUCKS",
  "mcc": "5810",
  "mcc_label": "Eating Places, Restaurants",
  "mcc_irs_category": "...",
  "category_key": "FOOD",
  "lat": 37.33,
  "lon": -122.03
}
```

## What Still Needs Backend Work

Your responsibility as outlined:
- ✅ `normalization.ts` - generalizes raw merchant names
- ✅ `mccDirectory.ts` - maps merchants to MCC codes
- ⏳ `getMerchants.ts` - needs to actually fetch from MapKit API
- ⏳ Backend needs to call your normalization → MCC pipeline

Once those are complete, the iOS-to-backend pipeline is fully functional!

## Testing

When a user enters a geofence area, you should see:
```
✅ didEnterRegion fired for identifier: coffee_1
📍 Entered geofence for merchant: Coffee Shop
🔥 AppState received geofence enter for: Coffee Shop
✅ Received normalized merchant: COFFEE SHOP
   MCC: 5810
   MCC Label: Eating Places, Restaurants
```

And a recommendation card will appear with smart cashback suggestions based on the MCC category.
