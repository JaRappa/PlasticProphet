//
//  AppState.swift
//  PlasticProphet
//

import Foundation
import SwiftUI

@MainActor
final class AppState: ObservableObject {
    
    // MARK: - Authentication
    
    @Published var isAuthenticated: Bool = false
    @Published var userFirstName: String = ""
    @Published var userLastName: String = ""
    @Published var userEmail: String = ""
    
    // Cognito Authentication service
    @Published var authService = CognitoAuthService()
    
    // MARK: - Onboarding & Permissions
    
    @Published var onboardingCompleted: Bool = false
    @Published var acceptedTos: Bool = false
    @Published var permissions = PermissionsStatus()
    
    // MARK: - Location
    
    @Published var locationService = LocationService()
    
    // MARK: - App Data
    
    @Published var cards: [Card] = []
    @Published var latestRecommendation: Recommendation? = nil
    
    // Backend service for merchant data
    let merchantNetworkService = MerchantNetworkService()
    @Published var lastNormalizedMerchant: NormalizedMerchantResponse? = nil
    
    // MCC Matcher service for AI-powered category matching
    let mccMatcherService = MCCMatcherService.shared
    @Published var lastMCCMatch: MCCMatchResponse? = nil
    
    @Published var showingScanner: Bool = false
    @Published var showingSettings: Bool = false
    
    // 0 = Wallet, 1 = Home, 2 = Profile
    @Published var selectedTab: Int = 0
    
    // MARK: - Init
    
    init() {
        // Connect geofence events → fetch normalized merchant data from backend
        locationService.onMerchantRegionEntered = { [weak self] merchantName in
            guard let self else { return }
            print("🔥 AppState received geofence enter for: \(merchantName)")
            self.fetchNormalizedMerchantData(merchantName: merchantName)
        }
    }
    
    // MARK: - Cognito Wrappers (no throws, match how views call them)
    
    func signUp(email: String, password: String, firstName: String, lastName: String) async {
        do {
            try await authService.signUp(
                email: email,
                password: password,
                firstName: firstName,
                lastName: lastName
            )
            
            await MainActor.run {
                self.userFirstName = firstName
                self.userLastName = lastName
                self.userEmail = email
            }
        } catch {
            print("❌ Sign up error: \(error)")
        }
    }
    
    func confirmSignUp(email: String, code: String) async {
        do {
            try await authService.confirmSignUp(email: email, code: code)
        } catch {
            print("❌ Confirm sign-up error: \(error)")
        }
    }
    
    func resendCode(email: String) async {
        do {
            try await authService.resendSignUpCode(email: email)
        } catch {
            print("❌ Resend code error: \(error)")
        }
    }
    
    func signIn(email: String, password: String) async {
        do {
            try await authService.signIn(email: email, password: password)
            
            self.isAuthenticated = self.authService.isAuthenticated
            self.userEmail = email
            print("🔐 AppState.isAuthenticated set to: \(self.isAuthenticated)")
        } catch {
            print("❌ Sign in error: \(error)")
        }
    }
    
    /// Note: this is *not* async so `ProfileView` can call `app.signOut()` directly.
    func signOut() {
        Task {
            await authService.signOut()
            self.isAuthenticated = false
            self.onboardingCompleted = false
            self.userFirstName = ""
            self.userLastName = ""
            self.userEmail = ""
        }
    }
    
    // MARK: - Permissions
    
    func markPermissions(camera: Bool? = nil, location: Bool? = nil) {
        if let camera { permissions.cameraAuthorized = camera }
        if let location { permissions.locationAuthorized = location }
    }
    
    // MARK: - Mock / Test Data Helpers
    
    /// Adds a sample card to the user's wallet for testing / onboarding.
    func addMockCard(network: String) {
        let mockCard = Card(
            name: "\(network) Test Card",
            network: network,
            last4: String(Int.random(in: 1000...9999)),
            rewardSummary: "2% Everywhere"
        )
        
        cards.append(mockCard)
    }
    
    /// Add a card to the user's wallet
    func addCard(_ card: Card) {
        // Avoid duplicates
        if !cards.contains(where: { $0.name == card.name }) {
            cards.append(card)
        }
    }
    
    /// Remove a card from the user's wallet
    func removeCard(_ card: Card) {
        cards.removeAll { $0.name == card.name }
    }
    
    // MARK: - Recommendations
    
    /// Fetch MCC code for a place using AI-powered matching
    /// This is the primary method for getting accurate MCC codes from location data
    func fetchMCCForPlace(
        name: String,
        category: String? = nil,
        address: String? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        phoneNumber: String? = nil,
        url: String? = nil
    ) {
        Task {
            do {
                print("🔍 Fetching MCC for: \(name)")
                
                let mccMatch = try await mccMatcherService.matchMCC(
                    name: name,
                    category: category,
                    address: address,
                    latitude: latitude,
                    longitude: longitude,
                    phoneNumber: phoneNumber,
                    url: url
                )
                
                await MainActor.run {
                    self.lastMCCMatch = mccMatch
                    print("✅ AI MCC Match: \(mccMatch.mcc) (\(mccMatch.confidence))")
                    print("   Description: \(mccMatch.description ?? "N/A")")
                    
                    // Create recommendation using the AI-matched MCC
                    self.createRecommendationFromMCCMatch(
                        mccMatch: mccMatch,
                        merchantName: name
                    )
                }
            } catch {
                await MainActor.run {
                    print("❌ Failed to match MCC via AI: \(error.localizedDescription)")
                    // Fallback to the old mock recommendation system
                    self.fetchRecommendation(for: name)
                }
            }
        }
    }
    
    /// Create a recommendation based on AI-matched MCC code
    private func createRecommendationFromMCCMatch(mccMatch: MCCMatchResponse, merchantName: String) {
        let chosenCard: Card
        if let firstCard = cards.first {
            chosenCard = firstCard
        } else {
            chosenCard = Card(
                name: "Wells Fargo Active Cash",
                network: "Visa",
                last4: "1234",
                rewardSummary: "2% Everywhere"
            )
        }
        
        let description = mccMatch.description ?? "Unknown Category"
        let irsDescription = mccMatch.irsDescription ?? description
        
        let rationale: String
        let rewardText: String
        
        // Use the MCC code and description to provide smart recommendations
        // MCC code ranges help determine category:
        // 5812-5814: Eating/Drinking
        // 5411: Grocery Stores
        // 5541-5542: Gas Stations
        // 4000-4999: Transportation/Travel
        // 5311-5399: Retail/Department Stores
        
        let mccInt = Int(mccMatch.mcc) ?? 0
        
        switch mccInt {
        case 5812...5814:
            // Restaurants and eating places
            rationale = "Higher cashback on dining at \(merchantName)."
            rewardText = "3% back at restaurants"
        case 5411:
            // Grocery stores
            rationale = "Great rewards on groceries."
            rewardText = "4% back at grocery stores"
        case 5541, 5542:
            // Gas stations
            rationale = "Bonus rewards on fuel purchases."
            rewardText = "5% back at gas stations"
        case 4000...4999:
            // Travel & transportation
            rationale = "Excellent rewards on travel."
            rewardText = "3% back on travel"
        case 5311...5399:
            // Department stores & retail
            rationale = "Good rewards at department stores."
            rewardText = "2% back at retail stores"
        case 5732:
            // Electronics stores
            rationale = "Solid rewards on electronics."
            rewardText = "2% back at electronics stores"
        default:
            // General category - use description for context
            rationale = "Solid rewards at \(irsDescription)."
            rewardText = "1.5% back on this purchase"
        }
        
        latestRecommendation = Recommendation(
            card: chosenCard,
            merchantName: merchantName,
            rationale: rationale,
            rewardText: rewardText
        )
    }
    
    /// Fetch normalized merchant data from backend and create recommendation
    func fetchNormalizedMerchantData(merchantName: String) {
        Task {
            do {
                // Use email as userId (or you could use an actual numeric ID)
                let userId = userEmail.isEmpty ? "guest_user" : userEmail.replacingOccurrences(of: "@", with: "_").replacingOccurrences(of: ".", with: "_")
                let generationId = UUID().uuidString
                
                let normalizedData = try await merchantNetworkService.fetchNormalizedMerchant(
                    merchantName: merchantName,
                    userId: userId,
                    generationId: generationId
                )
                
                await MainActor.run {
                    self.lastNormalizedMerchant = normalizedData
                    print("✅ Received normalized merchant: \(normalizedData.generalizedName ?? "Unknown")")
                    print("   MCC: \(normalizedData.mcc ?? "N/A")")
                    print("   MCC Label: \(normalizedData.mccLabel ?? "N/A")")
                    
                    // Now create a recommendation based on the normalized data
                    self.createRecommendationFromNormalizedData(normalizedData: normalizedData)
                }
            } catch {
                await MainActor.run {
                    print("❌ Failed to fetch normalized merchant: \(error.localizedDescription)")
                    // Fallback to the old mock recommendation system
                    self.fetchRecommendation(for: merchantName)
                }
            }
        }
    }
    
    /// Create a recommendation based on backend-normalized merchant data
    private func createRecommendationFromNormalizedData(normalizedData: NormalizedMerchantResponse) {
        let chosenCard: Card
        if let firstCard = cards.first {
            chosenCard = firstCard
        } else {
            chosenCard = Card(
                name: "Wells Fargo Active Cash",
                network: "Visa",
                last4: "1234",
                rewardSummary: "2% Everywhere"
            )
        }
        
        let merchantDisplayName = normalizedData.generalizedName ?? normalizedData.merchantName
        let categoryKey = normalizedData.categoryKey ?? "GENERAL"
        let mccLabel = normalizedData.mccLabel ?? "Unknown Category"
        
        let rationale: String
        let rewardText: String
        
        // Use the MCC category to provide smarter recommendations
        switch categoryKey.uppercased() {
        case let cat where cat.contains("FOOD") || cat.contains("RESTAURANT"):
            rationale = "Higher cashback on food and dining."
            rewardText = "3% back at restaurants and food merchants"
        case let cat where cat.contains("GROCERY"):
            rationale = "Great rewards on groceries."
            rewardText = "4% back at grocery stores"
        case let cat where cat.contains("GAS"):
            rationale = "Bonus rewards on fuel purchases."
            rewardText = "5% back at gas stations"
        case let cat where cat.contains("TRAVEL"):
            rationale = "Excellent rewards on travel purchases."
            rewardText = "3% back on travel"
        default:
            rationale = "Solid rewards at \(mccLabel)."
            rewardText = "1.5% back on this purchase"
        }
        
        latestRecommendation = Recommendation(
            card: chosenCard,
            merchantName: merchantDisplayName,
            rationale: rationale,
            rewardText: rewardText
        )
    }
    
    /// Build a fake recommendation locally (Phase 1)
    func fetchRecommendation(for merchant: String) {
        // Pick an existing card if the user has added any; otherwise use a default.
        let chosenCard: Card
        if let firstCard = cards.first {
            chosenCard = firstCard
        } else {
            chosenCard = Card(
                name: "Wells Fargo Active Cash",
                network: "Visa",
                last4: "1234",
                rewardSummary: "2% Everywhere"
            )
        }
        
        let lower = merchant.lowercased()
        let rationale: String
        let rewardText: String
        
        if lower.contains("coffee") {
            rationale = "Higher cashback at coffee shops."
            rewardText = "3% back at coffee merchants"
        } else if lower.contains("grocery") {
            rationale = "Great rewards on groceries."
            rewardText = "4% back at grocery stores"
        } else if lower.contains("gas") {
            rationale = "Bonus rewards on fuel purchases."
            rewardText = "5% back at gas stations"
        } else {
            rationale = "Solid flat-rate cashback for this purchase."
            rewardText = chosenCard.rewardSummary
        }
        
        latestRecommendation = Recommendation(
            card: chosenCard,
            merchantName: merchant,
            rationale: rationale,
            rewardText: rewardText
        )
    }
    
    // MARK: - Onboarding
    
    func proceedIfReady() {
        if acceptedTos && permissions.allGranted && !cards.isEmpty {
            onboardingCompleted = true
        }
    }
}
