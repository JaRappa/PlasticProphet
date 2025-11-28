// AppState.swift
// Global observable application state with authentication

import Foundation
import SwiftUI
import Combine // Required for permission listeners

@MainActor
final class AppState: ObservableObject {
    // MARK: - Authentication
    @Published var isAuthenticated: Bool = false
    @Published var userFirstName: String = ""
    @Published var userLastName: String = ""
    @Published var userEmail: String = ""
    
    // Cognito Auth Service
    @Published var authService = CognitoAuthService()
    
    // API Service (Added for health checks)
    let apiService = APIService()
    
    // MARK: - Onboarding
    @Published var onboardingCompleted: Bool = false
    @Published var acceptedTos: Bool = false
    
    // [NEW] Real System Permission Manager
    @Published var permissionManager = PermissionManager()
    
    // 2. ADDED: Storage for the permission listener
    private var cancellables = Set<AnyCancellable>()
         
    // Helper to check Camera status
    var isCameraAuthorized: Bool {
        permissionManager.cameraStatus == .authorized
    }
         
    // Helper to check Location status
    var isLocationAuthorized: Bool {
        permissionManager.locationStatus == .authorizedWhenInUse ||
        permissionManager.locationStatus == .authorizedAlways
    }
    
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
        
        // 3. ADDED: The Listener Logic
        // This ensures the Onboarding View updates INSTANTLY when you click "Allow"
        permissionManager.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
        
        // Load persisted onboarding status
        loadPersistedState()
        
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
            // First confirm the signup
            try await authService.confirmSignUp(email: email, code: code)
            print("✅ Email confirmed - you can now sign in")
            
            // Note: We can't auto sign-in because we don't have the password here
            // User will need to sign in manually on the next screen
            
        } catch {
            print("❌ Confirmation failed: \(error.localizedDescription)")
        }
    }
    
    func signIn() async {
        do {
            print("🔵 Starting secure OAuth 2.0 sign in")
            try await authService.signIn()
            print("✅ Sign in successful!")
            
            // Extract user info
            let attributes = try await authService.extractUserInfoFromIDToken()
            
            await MainActor.run {
                self.isAuthenticated = true
                self.userEmail = attributes["email"] ?? self.authService.currentUsername ?? ""
                self.userFirstName = attributes["given_name"] ?? ""
                self.userLastName = attributes["family_name"] ?? ""
                
                print("👤 User identified as: \(self.userEmail)")
                self.checkPreviousOnboarding()
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
            
            // Extract user info from stored ID token
            Task {
                do {
                    let attributes = try await authService.extractUserInfoFromIDToken()
                    await MainActor.run {
                        self.userFirstName = attributes["given_name"] ?? "User"
                        self.userLastName = attributes["family_name"] ?? ""
                        if let email = attributes["email"] {
                            self.userEmail = email
                        }
                        self.checkPreviousOnboarding()
                    }
                    print("✅ Restored user session for: \(self.userEmail)")
                } catch {
                    print("⚠️ Could not extract user info from stored token: \(error)")
                }
            }
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
            // self.permissions = PermissionsStatus() // No longer needed with PermissionManager
            
            // Clear persisted state
            clearPersistedState()
            
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
        // No-op: handled by PermissionManager now, kept for backward compatibility if needed
    }

    // MARK: - Onboarding

    func proceedIfReady() {
        // 4. UPDATED: Ensure we use the real system checks
        if acceptedTos && !cards.isEmpty && isCameraAuthorized && isLocationAuthorized {
            self.onboardingCompleted = true
            savePersistedState()
        }
    }
    
    // MARK: - Persistence
    
    func savePersistedState() {
        UserDefaults.standard.set(onboardingCompleted, forKey: "onboarding_completed")
        UserDefaults.standard.set(acceptedTos, forKey: "accepted_tos")
        print("💾 Saved onboarding state: completed=\(onboardingCompleted)")
        if !userEmail.isEmpty {
            // FIX: Use lowercased() so Case Sensitivity doesn't break it
            let key = "onboarded_\(userEmail.lowercased())"
            UserDefaults.standard.set(true, forKey: key)
            print("💾 Saved onboarding state for \(key)")
        }
    }
    
    func checkPreviousOnboarding() {
        print("🔍 checkingPreviousOnboarding invoked...")
        
        guard !userEmail.isEmpty else {
            print("⚠️ Cannot check onboarding: userEmail is empty in AppState")
            return
        }
        
        let key = "onboarded_\(userEmail.lowercased())"
        let hasFinished = UserDefaults.standard.bool(forKey: key)
        
        print("🔍 Checking UserDefaults for key: [\(key)]")
        print("🔍 Result: \(hasFinished)")
        
        if hasFinished {
            self.onboardingCompleted = true
            print("✅ Restored onboarding status: Completed")
        }
    }
    
    private func loadPersistedState() {
        onboardingCompleted = UserDefaults.standard.bool(forKey: "onboarding_completed")
        acceptedTos = UserDefaults.standard.bool(forKey: "accepted_tos")
        print("📂 Loaded onboarding state: completed=\(onboardingCompleted)")
    }
    
    private func clearPersistedState() {
        UserDefaults.standard.removeObject(forKey: "onboarding_completed")
        UserDefaults.standard.removeObject(forKey: "accepted_tos")
        print("🗑️ Cleared persisted state")
    }
}
