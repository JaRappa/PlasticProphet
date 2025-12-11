// CognitoAuthServiceNoSDK.swift
// AWS Cognito authentication without any SDK - just REST API calls

import Foundation

class CognitoAuthService: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUsername: String?
    @Published var accessToken: String?
    @Published var idToken: String?
    @Published var refreshToken: String?
    
    private var cognitoURL: String {
        "https://cognito-idp.\(CognitoConfig.region).amazonaws.com/"
    }
    
    // MARK: - Init
    
    init() {
        // Try to restore any saved session
        loadTokensFromKeychain()
    }
    
    // MARK: - Sign Up
    
    func signUp(email: String, password: String, firstName: String, lastName: String) async throws {
        print("🔵 CognitoAuthService: Starting sign up for \(email)")
        
        let headers = [
            "X-Amz-Target": "AWSCognitoIdentityProviderService.SignUp",
            "Content-Type": "application/x-amz-json-1.1"
        ]
        
        let body: [String: Any] = [
            "ClientId": CognitoConfig.appClientId,
            "Username": email,
            "Password": password,
            "UserAttributes": [
                ["Name": "email", "Value": email],
                ["Name": "given_name", "Value": firstName],
                ["Name": "family_name", "Value": lastName],
                // Placeholder – you can remove or replace this if you want
                ["Name": "birthdate", "Value": "2000-01-01"]
            ]
        ]
        
        _ = try await makeRequest(endpoint: cognitoURL,
                                  headers: headers,
                                  body: body)
        
        print("✅ Sign up successful!")
    }
    
    // MARK: - Confirm Sign Up
    
    func confirmSignUp(email: String, code: String) async throws {
        print("🔵 Confirming sign up for \(email)")
        
        let headers = [
            "X-Amz-Target": "AWSCognitoIdentityProviderService.ConfirmSignUp",
            "Content-Type": "application/x-amz-json-1.1"
        ]
        
        let body: [String: Any] = [
            "ClientId": CognitoConfig.appClientId,
            "Username": email,
            "ConfirmationCode": code
        ]
        
        _ = try await makeRequest(endpoint: cognitoURL,
                                  headers: headers,
                                  body: body)
        
        print("✅ Confirmation successful!")
    }
    
    // MARK: - Resend Sign Up Code
    
    func resendSignUpCode(email: String) async throws {
        print("🔵 Resending sign up code for \(email)")
        
        let headers = [
            "X-Amz-Target": "AWSCognitoIdentityProviderService.ResendConfirmationCode",
            "Content-Type": "application/x-amz-json-1.1"
        ]
        
        let body: [String: Any] = [
            "ClientId": CognitoConfig.appClientId,
            "Username": email
        ]
        
        _ = try await makeRequest(endpoint: cognitoURL,
                                  headers: headers,
                                  body: body)
        
        print("✅ Resent confirmation code")
    }
    
    // MARK: - Sign In
    
    func signIn(email: String, password: String) async throws {
        print("🔵 CognitoAuthService: Starting sign in for \(email)")
        
        let headers = [
            "X-Amz-Target": "AWSCognitoIdentityProviderService.InitiateAuth",
            "Content-Type": "application/x-amz-json-1.1"
        ]
        
        let body: [String: Any] = [
            "AuthFlow": "USER_PASSWORD_AUTH",
            "ClientId": CognitoConfig.appClientId,
            "AuthParameters": [
                "USERNAME": email,
                "PASSWORD": password
            ]
        ]
        
        let response = try await makeRequest(endpoint: cognitoURL,
                                             headers: headers,
                                             body: body)
        
        guard let authResult = response["AuthenticationResult"] as? [String: Any] else {
            print("❌ Missing AuthenticationResult in response: \(response)")
            throw CognitoError.invalidResponse
        }
        
        let newAccessToken = authResult["AccessToken"] as? String
        let newIdToken = authResult["IdToken"] as? String
        let newRefreshToken = authResult["RefreshToken"] as? String
        
        await MainActor.run {
            self.accessToken = newAccessToken
            self.idToken = newIdToken
            self.refreshToken = newRefreshToken
            self.currentUsername = email
            self.isAuthenticated = (newAccessToken != nil)
        }
        
        saveTokensToKeychain()
        print("✅ Sign in successful!")
    }
    
    // MARK: - Sign Out
    
    func signOut() async {
        await MainActor.run {
            self.accessToken = nil
            self.idToken = nil
            self.refreshToken = nil
            self.currentUsername = nil
            self.isAuthenticated = false
            clearTokensFromKeychain()
        }
        print("✅ Signed out")
    }
    
    // MARK: - Get User Attributes
    
    func getUserAttributes() async throws -> [String: String] {
        print("🔍 Fetching user attributes...")
        
        guard let accessToken = accessToken else {
            throw CognitoError.notAuthenticated
        }
        
        let headers = [
            "X-Amz-Target": "AWSCognitoIdentityProviderService.GetUser",
            "Content-Type": "application/x-amz-json-1.1"
        ]
        
        let body: [String: Any] = [
            "AccessToken": accessToken
        ]
        
        let response = try await makeRequest(endpoint: cognitoURL,
                                             headers: headers,
                                             body: body)
        
        var attributes: [String: String] = [:]
        if let userAttrs = response["UserAttributes"] as? [[String: Any]] {
            for attr in userAttrs {
                if let name = attr["Name"] as? String,
                   let value = attr["Value"] as? String {
                    attributes[name] = value
                }
            }
        }
        
        print("✅ Got user attributes: \(attributes)")
        return attributes
    }
    
    // MARK: - Helper: HTTP Request
    
    private func makeRequest(endpoint: String,
                             headers: [String: String],
                             body: [String: Any]) async throws -> [String: Any] {
        print("🌐 Making request to Cognito...")
        
        guard let url = URL(string: endpoint) else {
            throw CognitoError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        headers.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, httpResponse) = try await URLSession.shared.data(for: request)
        
        guard let response = httpResponse as? HTTPURLResponse else {
            throw CognitoError.invalidResponse
        }
        
        print("📥 Response status: \(response.statusCode)")
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            if response.statusCode >= 400 {
                let errorString = String(data: data, encoding: .utf8) ?? "Unknown"
                print("❌ Server error (raw): \(errorString)")
                throw CognitoError.serverError(response.statusCode)
            }
            throw CognitoError.invalidResponse
        }
        
        if response.statusCode >= 400 {
            let errorMessage =
                json["message"] as? String ??
                json["__type"] as? String ??
                "Unknown error"
            print("❌ API Error: \(errorMessage)")
            throw CognitoError.apiError(errorMessage)
        }
        
        return json
    }
    
    // MARK: - "Keychain" Helpers (here using UserDefaults)
    
    private func saveTokensToKeychain() {
        UserDefaults.standard.set(accessToken, forKey: "cognito_access_token")
        UserDefaults.standard.set(idToken, forKey: "cognito_id_token")
        UserDefaults.standard.set(refreshToken, forKey: "cognito_refresh_token")
        UserDefaults.standard.set(currentUsername, forKey: "cognito_username")
    }
    
    private func loadTokensFromKeychain() {
        accessToken = UserDefaults.standard.string(forKey: "cognito_access_token")
        idToken = UserDefaults.standard.string(forKey: "cognito_id_token")
        refreshToken = UserDefaults.standard.string(forKey: "cognito_refresh_token")
        currentUsername = UserDefaults.standard.string(forKey: "cognito_username")
        
        if accessToken != nil {
            isAuthenticated = true
        }
    }
    
    private func clearTokensFromKeychain() {
        UserDefaults.standard.removeObject(forKey: "cognito_access_token")
        UserDefaults.standard.removeObject(forKey: "cognito_id_token")
        UserDefaults.standard.removeObject(forKey: "cognito_refresh_token")
        UserDefaults.standard.removeObject(forKey: "cognito_username")
    }
    
    // MARK: - Session Check
    
    func checkSession() {
        print("🔍 Checking session...")
        loadTokensFromKeychain()
        print(isAuthenticated ? "✅ Session found" : "ℹ️ No session")
    }
}

// MARK: - Errors

enum CognitoError: LocalizedError {
    case invalidURL
    case invalidResponse
    case notAuthenticated
    case noRefreshToken
    case serverError(Int)
    case apiError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .invalidResponse: return "Invalid response"
        case .notAuthenticated: return "Not authenticated"
        case .noRefreshToken: return "No refresh token"
        case .serverError(let code): return "Server error: \(code)"
        case .apiError(let message): return message
        }
    }
}
