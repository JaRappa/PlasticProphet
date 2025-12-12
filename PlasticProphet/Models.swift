// Models.swift
// Basic domain stubs for PlasticProphet
// Generated as initial scaffolding

import Foundation

struct Card: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var network: String
    var last4: String
    var rewardSummary: String
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

