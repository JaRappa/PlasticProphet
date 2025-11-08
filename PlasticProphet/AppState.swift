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
            }
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

    func addMockCard(network: String) {
        let suffix = String(Int.random(in: 1000...9999))
        let card = Card(name: "Rewards \(network) \(suffix)", network: network, last4: suffix, rewardSummary: "5% Dining / 3% Grocery")
        cards.append(card)
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
