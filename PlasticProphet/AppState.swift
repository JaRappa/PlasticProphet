// AppState.swift
// Global observable application state & simple recommendation stub

import Foundation
import SwiftUI

@MainActor
final class AppState: ObservableObject {
    @Published var onboardingCompleted: Bool = false
    @Published var acceptedTos: Bool = false
    @Published var permissions = PermissionsStatus()
    @Published var cards: [Card] = []
    @Published var latestRecommendation: Recommendation? = nil
    @Published var showingScanner: Bool = false
    @Published var showingSettings: Bool = false

    // Simulated recommendation lookup
    func fetchRecommendation(for merchant: String? = nil) {
        guard let first = cards.first else {
            latestRecommendation = nil
            return
        }
        latestRecommendation = Recommendation(
            card: first,
            merchantName: merchant ?? "Nearby Merchant",
            rationale: "Higher cashback on dining",
            rewardText: first.rewardSummary
        )
    }

    func addMockCard(network: String) {
        let suffix = String(Int.random(in: 1000...9999))
        let card = Card(name: "Rewards \(network) \(suffix)", network: network, last4: suffix, rewardSummary: "5% Dining / 3% Grocery")
        cards.append(card)
    }

    func markPermissions(camera: Bool? = nil, location: Bool? = nil) {
        if let camera { permissions.cameraAuthorized = camera }
        if let location { permissions.locationAuthorized = location }
    }

    func proceedIfReady() {
        if acceptedTos && permissions.allGranted && !cards.isEmpty { onboardingCompleted = true }
    }
}
