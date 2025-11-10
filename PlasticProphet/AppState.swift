// AppState.swift
// Global observable application state with authentication

import Foundation
import SwiftUI

@MainActor
final class AppState: ObservableObject {
    // MARK: - Authentication
    @Published var isAuthenticated: Bool = false
    @Published var userFirstName: String = ""
    @Published var userLastName: String = ""
    @Published var userEmail: String = ""
    
    // Cognito Auth Service
    @Published var authService = CognitoAuthService()
    
    // MARK: - Onboarding
    @Published var onboardingCompleted: Bool = false
    @Published var acceptedTos: Bool = false
    @Published var permissions = PermissionsStatus()
    
    // MARK: - App Data
    @Published var cards: [Card] = []
    @Published var latestRecommendation: Recommendation? = nil
    @Published var showingScanner: Bool = false
    @Published var showingSettings: Bool = false
    
    // Wallet Service
    let walletService = WalletService()
    
    // User ID from Cognito (will be set after authentication)
    @Published var userId: Int?
    
    // Loading states
    @Published var isLoadingWallet: Bool = false
    @Published var walletError: String?
    
    // 0 = Wallet, 1 = Home, 2 = Profile
    @Published var selectedTab: Int = 0
    
    // MARK: - Initialization
    
    init() {
        // Check Cognito configuration on startup
        print("🚀🚀🚀 APPSTATE INIT - CONSOLE TEST 🚀🚀🚀")
        CognitoConfig.printStatus()
        
        // Check if user is already signed in
        checkSession()
    }
    
    // MARK: - Authentication Methods
    
    func signUp(email: String, password: String, firstName: String, lastName: String) async {
        do {
            print("🔵 Starting sign up for: \(email)")
            try await authService.signUp(email: email, password: password, firstName: firstName, lastName: lastName)
                    print("✅ Sign up successful - check email for verification code")
                } catch {
                    print("❌ Sign up failed: \(error)")
                    print("❌ Error details: \(error.localizedDescription)")
                }
            }
    
    func confirmSignUp(email: String, code: String) async {
        do {
            try await authService.confirmSignUp(email: email, code: code)
            print("✅ Email confirmed - you can now sign in")
        } catch {
            print("❌ Confirmation failed: \(error.localizedDescription)")
        }
    }
    
    func signIn(email: String, password: String) async {
        do {
            print("🔵 Starting sign in for: \(email)")
            try await authService.signIn(email: email, password: password)
            print("✅ Sign in successful!")
            
            // Fetch user info from Cognito
            let attributes = try await authService.getUserAttributes()
            
            await MainActor.run {
                self.isAuthenticated = true
                self.userEmail = attributes["email"] ?? email
                self.userFirstName = attributes["given_name"] ?? "User"
                self.userLastName = attributes["family_name"] ?? ""
                
                // TODO: Fetch user_id from your backend
                // For now, use a placeholder. You'll need to:
                // 1. Store user_id in Cognito custom attributes, OR
                // 2. Call your backend to get user_id by email
                // Example: self.userId = try await fetchUserIdFromBackend(email: email)
            }
            
            // Fetch wallet after successful sign in
            await fetchWallet()
            
        } catch {
            print("❌ Sign in failed: \(error)")
            print("❌ Error details: \(error.localizedDescription)")
        }
    }
    
    func checkSession() {
        authService.checkSession()
        
        if authService.isAuthenticated {
            self.isAuthenticated = true
            self.userEmail = authService.currentUsername ?? ""
        }
    }
    
    func signOut() {
        Task {
            await authService.signOut()
            
            // Clear all user data
            self.isAuthenticated = false
            self.onboardingCompleted = false
            self.acceptedTos = false
            self.cards.removeAll()
            self.latestRecommendation = nil
            self.userFirstName = ""
            self.userLastName = ""
            self.userEmail = ""
            self.permissions = PermissionsStatus()
            
            print("✅ Signed out")
        }
    }
    
    // MARK: - Recommendation Methods

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

    // MARK: - Card Management
    
    /// Fetch all cards from the backend
    func fetchWallet() async {
        guard let userId = userId else {
            print("❌ No user ID available")
            return
        }
        
        await MainActor.run { isLoadingWallet = true }
        
        do {
            let fetchedCards = try await walletService.fetchWallet(userId: userId)
            await MainActor.run {
                self.cards = fetchedCards
                self.isLoadingWallet = false
                self.walletError = nil
                print("✅ Wallet loaded: \(fetchedCards.count) cards")
            }
        } catch {
            await MainActor.run {
                self.isLoadingWallet = false
                self.walletError = error.localizedDescription
                print("❌ Failed to fetch wallet: \(error)")
            }
        }
    }
    
    /// Add a new card to the wallet
    func addCard(
        network: CardNetwork,
        type: String? = nil,
        issuer: String? = nil,
        name: String? = nil
    ) async -> Bool {
        guard let userId = userId else {
            print("❌ No user ID available")
            return false
        }
        
        do {
            let newCard = try await walletService.addCard(
                userId: userId,
                cardNetwork: network,
                cardType: type,
                cardIssuer: issuer,
                cardName: name
            )
            
            await MainActor.run {
                self.cards.append(newCard)
                print("✅ Card added: \(newCard.displayName)")
            }
            return true
        } catch {
            await MainActor.run {
                self.walletError = error.localizedDescription
                print("❌ Failed to add card: \(error)")
            }
            return false
        }
    }
    
    /// Remove a card from the wallet
    func removeCard(_ card: Card) async -> Bool {
        guard let userId = userId else {
            print("❌ No user ID available")
            return false
        }
        
        do {
            try await walletService.removeCard(userId: userId, cardId: card.id)
            
            await MainActor.run {
                self.cards.removeAll { $0.id == card.id }
                print("✅ Card removed: \(card.displayName)")
            }
            return true
        } catch {
            await MainActor.run {
                self.walletError = error.localizedDescription
                print("❌ Failed to remove card: \(error)")
            }
            return false
        }
    }
    
    /// Update card information
    func updateCard(
        _ card: Card,
        type: String? = nil,
        issuer: String? = nil,
        name: String? = nil
    ) async -> Bool {
        guard let userId = userId else {
            print("❌ No user ID available")
            return false
        }
        
        do {
            let updatedCard = try await walletService.updateCard(
                userId: userId,
                cardId: card.id,
                cardType: type,
                cardIssuer: issuer,
                cardName: name
            )
            
            await MainActor.run {
                if let index = self.cards.firstIndex(where: { $0.id == card.id }) {
                    self.cards[index] = updatedCard
                    print("✅ Card updated: \(updatedCard.displayName)")
                }
            }
            return true
        } catch {
            await MainActor.run {
                self.walletError = error.localizedDescription
                print("❌ Failed to update card: \(error)")
            }
            return false
        }
    }

    func addMockCard(network: String) {
        // This is deprecated - use addCard() with proper API call
        print("⚠️ addMockCard is deprecated - use addCard() instead")
    }

    // MARK: - Permissions

    func markPermissions(camera: Bool? = nil, location: Bool? = nil) {
        if let camera { permissions.cameraAuthorized = camera }
        if let location { permissions.locationAuthorized = location }
    }

    // MARK: - Onboarding

    func proceedIfReady() {
        if acceptedTos && permissions.allGranted && !cards.isEmpty {
            onboardingCompleted = true
        }
    }
}
