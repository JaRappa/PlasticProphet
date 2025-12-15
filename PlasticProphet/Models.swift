// Models.swift
// Basic domain stubs for PlasticProphet
// Generated as initial scaffolding

import Foundation

struct Card: Identifiable, Hashable, Codable {
    var id = UUID()
    var name: String
    var network: String
    var last4: String
    var rewardSummary: String
    
    // Additional fields from API
    var cardKey: String?
    var cardIssuer: String?
    var annualFee: Double?
    var cardUrl: String?
    var cardImageUrl: String?
    var spendBonusCategories: [CardBonusCategory]?
    
    // Basic init for backward compatibility
    init(name: String, network: String, last4: String, rewardSummary: String) {
        self.name = name
        self.network = network
        self.last4 = last4
        self.rewardSummary = rewardSummary
    }
    
    // Full init with API data
    init(
        name: String,
        network: String,
        last4: String,
        rewardSummary: String,
        cardKey: String? = nil,
        cardIssuer: String? = nil,
        annualFee: Double? = nil,
        cardUrl: String? = nil,
        cardImageUrl: String? = nil,
        spendBonusCategories: [CardBonusCategory]? = nil
    ) {
        self.name = name
        self.network = network
        self.last4 = last4
        self.rewardSummary = rewardSummary
        self.cardKey = cardKey
        self.cardIssuer = cardIssuer
        self.annualFee = annualFee
        self.cardUrl = cardUrl
        self.cardImageUrl = cardImageUrl
        self.spendBonusCategories = spendBonusCategories
    }
    
    // Init from API response
    init(from apiResponse: CardAPIResponse) {
        self.name = apiResponse.cardName ?? "Unknown Card"
        self.network = apiResponse.cardNetwork ?? "Unknown"
        self.last4 = "0000"
        self.cardKey = apiResponse.cardKey
        self.cardIssuer = apiResponse.cardIssuer
        self.annualFee = apiResponse.annualFee
        self.cardUrl = apiResponse.cardUrl
        self.cardImageUrl = apiResponse.cardImageUrl
        
        // Build reward summary from bonus categories
        if let categories = apiResponse.spendBonusCategory, !categories.isEmpty {
            let topCategories = categories.prefix(3)
            let summary = topCategories.compactMap { cat -> String? in
                guard let name = cat.spendBonusCategoryName,
                      let multiplier = cat.earnMultiplier else { return nil }
                return "\(Int(multiplier))x \(name)"
            }.joined(separator: " / ")
            self.rewardSummary = summary.isEmpty ? "Rewards Card" : summary
            
            self.spendBonusCategories = categories.map {
                CardBonusCategory(
                    name: $0.spendBonusCategoryName ?? "Unknown",
                    multiplier: $0.earnMultiplier ?? 1.0,
                    description: $0.spendBonusDesc
                )
            }
        } else if let baseAmount = apiResponse.baseSpendAmount,
                  let baseCategory = apiResponse.baseSpendEarnCategory {
            self.rewardSummary = "\(Int(baseAmount))x \(baseCategory)"
        } else {
            self.rewardSummary = "Rewards Card"
        }
    }
    
    // Hashable conformance based on cardKey or name
    func hash(into hasher: inout Hasher) {
        hasher.combine(cardKey ?? name)
    }
    
    static func == (lhs: Card, rhs: Card) -> Bool {
        if let lhsKey = lhs.cardKey, let rhsKey = rhs.cardKey {
            return lhsKey == rhsKey
        }
        return lhs.name == rhs.name && lhs.network == rhs.network
    }
}

struct CardBonusCategory: Hashable, Codable {
    var name: String
    var multiplier: Double
    var description: String?
}

struct Recommendation: Identifiable, Hashable {
    let id = UUID()
    var card: Card
    var merchantName: String
    var rationale: String
    var rewardText: String
}

struct PermissionsStatus {
    var cameraAuthorized: Bool = false
    var locationAuthorized: Bool = false
    var allGranted: Bool { cameraAuthorized && locationAuthorized }
}

import CoreLocation

/// A simple hard-coded merchant model used only for Phase 1 geofence testing.
struct TestMerchant: Identifiable {
    let id: String               // unique identifier for the region
    let name: String             // display name ("Coffee Shop")
    let coordinate: CLLocationCoordinate2D
    let radius: CLLocationDistance
}

/// A small list of sample merchants to create geofences around.
/// Replace coordinates with real ones later if needed.
let testMerchants: [TestMerchant] = [
    TestMerchant(
        id: "coffee_1",
        name: "Coffee Shop",
        coordinate: CLLocationCoordinate2D(latitude: 37.33233141, longitude: -122.0312186), // Apple HQ example
        radius: 75
    ),
    TestMerchant(
        id: "grocery_1",
        name: "Grocery Store",
        coordinate: CLLocationCoordinate2D(latitude: 37.333, longitude: -122.03),
        radius: 75
    ),
    TestMerchant(
        id: "gas_1",
        name: "Gas Station",
        coordinate: CLLocationCoordinate2D(latitude: 37.334, longitude: -122.029),
        radius: 75
    )
]

