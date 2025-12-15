// Models.swift
// Basic domain stubs for PlasticProphet

import Foundation
import CoreLocation

struct Card: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var network: String
    var last4: String
    var rewardSummary: String
    var cardKey: String?
    
    init(name: String, network: String, last4: String, rewardSummary: String, cardKey: String? = nil) {
        self.name = name
        self.network = network
        self.last4 = last4
        self.rewardSummary = rewardSummary
        self.cardKey = cardKey
    }
}

extension Card {
    init(from apiResponse: CardAPIResponse) {
        self.name = apiResponse.cardName ?? "Unknown Card"
        self.network = apiResponse.cardNetwork ?? "Unknown"
        self.last4 = "••••"
        self.cardKey = apiResponse.cardKey
        if let categories = apiResponse.spendBonusCategory, !categories.isEmpty {
            let top = categories.prefix(3).compactMap { cat -> String? in
                guard let n = cat.spendBonusCategoryName, let m = cat.earnMultiplier else { return nil }
                return "\(Int(m))x \(n)"
            }
            self.rewardSummary = top.joined(separator: ", ")
        } else if let base = apiResponse.baseSpendAmount {
            self.rewardSummary = "\(Int(base))x on all purchases"
        } else {
            self.rewardSummary = "Rewards Card"
        }
    }
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

struct TestMerchant: Identifiable {
    let id: String
    let name: String
    let coordinate: CLLocationCoordinate2D
    let radius: CLLocationDistance
    let mcc: String?
    
    init(id: String, name: String, coordinate: CLLocationCoordinate2D, radius: CLLocationDistance, mcc: String? = nil) {
        self.id = id
        self.name = name
        self.coordinate = coordinate
        self.radius = radius
        self.mcc = mcc
    }
}

let testMerchants: [TestMerchant] = [
    TestMerchant(id: "coffee_1", name: "Coffee Shop", coordinate: CLLocationCoordinate2D(latitude: 37.33233141, longitude: -122.0312186), radius: 75, mcc: "5814"),
    TestMerchant(id: "grocery_1", name: "Grocery Store", coordinate: CLLocationCoordinate2D(latitude: 37.333, longitude: -122.03), radius: 75, mcc: "5411"),
    TestMerchant(id: "gas_1", name: "Gas Station", coordinate: CLLocationCoordinate2D(latitude: 37.334, longitude: -122.029), radius: 75, mcc: "5541"),
    TestMerchant(id: "starbucks_1", name: "Starbucks", coordinate: CLLocationCoordinate2D(latitude: 37.332, longitude: -122.031), radius: 75, mcc: "5814")
]
