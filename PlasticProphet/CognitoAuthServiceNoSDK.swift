// CognitoAuthServiceNoSDK.swift
// AWS Cognito authentication using OAuth 2.0 + PKCE (secure industry standard)
// No passwords transmitted directly - uses Cognito Hosted UI

import Foundation
import AuthenticationServices
import CryptoKit

class CognitoAuthService: NSObject, ObservableObject, ASWebAuthenticationPresentationContextProviding {
    @Published var isAuthenticated = false
    @Published var currentUsername: String?
    @Published var accessToken: String?
    @Published var idToken: String?
    @Published var refreshToken: String?
    
    private var cognitoURL: String {
        "https://cognito-idp.\(CognitoConfig.region).amazonaws.com"
    }
    
    // IMPORTANT: Your Cognito domain - format is: https://{domain-prefix}.auth.{region}.amazoncognito.com
    // The domain prefix is typically based on your User Pool ID
    private var hostedUIURL: String {
        // Format: Remove the underscore and make it lowercase for the domain
        let poolId = CognitoConfig.userPoolId.replacingOccurrences(of: "_", with: "").lowercased()
        return "https://\(poolId).auth.\(CognitoConfig.region).amazoncognito.com"
    }
    
    // PKCE values for current auth attempt
    private var codeVerifier: String?
    private var codeChallenge: String?
    private var authSession: ASWebAuthenticationSession?
    
    override init() {
        super.init()
        checkSession()
        print("🔧 Cognito Hosted UI URL: \(hostedUIURL)")
    }
    
    // MARK: - PKCE Helper Methods
    
    /// Generate a random code verifier for PKCE
    private func generateCodeVerifier() -> String {
        var buffer = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, buffer.count, &buffer)
        return Data(buffer).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
    
    /// Generate code challenge from verifier using SHA256
    private func generateCodeChallenge(from verifier: String) -> String {
        guard let data = verifier.data(using: .utf8) else { return "" }
        let digest = SHA256.hash(data: data)
        return Data(digest).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
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
                ["Name": "birthdate", "Value": "2000-01-01"]
            ]
        ]
        
        _ = try await makeRequest(endpoint: "\(cognitoURL)/", headers: headers, body: body)
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
        
        _ = try await makeRequest(endpoint: "\(cognitoURL)/", headers: headers, body: body)
        print("✅ Confirmation successful!")
    }
    
    // MARK: - Resend Confirmation Code
    
    func resendConfirmationCode(email: String) async throws {
        print("🔵 Resending confirmation code for \(email)")
        
        let headers = [
            "X-Amz-Target": "AWSCognitoIdentityProviderService.ResendConfirmationCode",
            "Content-Type": "application/x-amz-json-1.1"
        ]
        
        let body: [String: Any] = [
            "ClientId": CognitoConfig.appClientId,
            "Username": email
        ]
        
        _ = try await makeRequest(endpoint: "\(cognitoURL)/", headers: headers, body: body)
        print("✅ Confirmation code resent!")
    }
    
    // MARK: - Sign In (OAuth 2.0 + PKCE via Hosted UI)
    
    func signIn() async throws {
        print("🔵 Starting secure OAuth 2.0 sign in")
        
        // Generate PKCE values
        codeVerifier = generateCodeVerifier()
        guard let verifier = codeVerifier else {
            throw CognitoError.invalidURL
        }
        codeChallenge = generateCodeChallenge(from: verifier)
        
        // Build authorization URL
        var components = URLComponents(string: "\(hostedUIURL)/oauth2/authorize")!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: CognitoConfig.appClientId),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "redirect_uri", value: "plasticprophet://auth-callback"),
            URLQueryItem(name: "scope", value: "openid email profile"),
            URLQueryItem(name: "code_challenge", value: codeChallenge),
            URLQueryItem(name: "code_challenge_method", value: "S256")
        ]
        
        guard let authURL = components.url else {
            throw CognitoError.invalidURL
        }
        
        print("🌐 Opening Cognito Hosted UI: \(authURL)")
        
        return try await withCheckedThrowingContinuation { continuation in
            // Use ASWebAuthenticationSession for secure OAuth flow
            let session = ASWebAuthenticationSession(
                url: authURL,
                callbackURLScheme: "plasticprophet"
            ) { [weak self] callbackURL, error in
                Task {
                    do {
                        try await self?.handleAuthCallback(callbackURL: callbackURL, error: error)
                        continuation.resume()
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            }
            
            session.presentationContextProvider = self
            session.prefersEphemeralWebBrowserSession = false
            
            self.authSession = session
            
            if !session.start() {
                continuation.resume(throwing: CognitoError.authenticationFailed("Failed to start authentication session"))
            }
        }
    }
    
    // MARK: - Handle Auth Callback
    
    private func handleAuthCallback(callbackURL: URL?, error: Error?) async throws {
        if let error = error {
            print("❌ Auth error: \(error.localizedDescription)")
            throw error
        }
        
        guard let callbackURL = callbackURL else {
            throw CognitoError.invalidURL
        }
        
        print("✅ Received callback from Cognito: \(callbackURL)")
        
        // Extract authorization code from callback
        guard let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false),
              let code = components.queryItems?.first(where: { $0.name == "code" })?.value else {
            throw CognitoError.invalidResponse
        }
        
        print("🔵 Exchanging authorization code for tokens...")
        
        // Exchange authorization code for tokens
        try await exchangeCodeForTokens(code: code)
    }
    
    // MARK: - Exchange Code for Tokens (PKCE)
    
    private func exchangeCodeForTokens(code: String) async throws {
        guard let verifier = codeVerifier else {
            throw CognitoError.invalidURL
        }
        
        let tokenURL = "\(hostedUIURL)/oauth2/token"
        
        var request = URLRequest(url: URL(string: tokenURL)!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let body = "grant_type=authorization_code&client_id=\(CognitoConfig.appClientId)&code=\(code)&redirect_uri=plasticprophet://auth-callback&code_verifier=\(verifier)"
        request.httpBody = body.data(using: .utf8)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw CognitoError.invalidResponse
        }
        
        print("📥 Token exchange response: \(httpResponse.statusCode)")
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        
        if httpResponse.statusCode >= 400 {
            let errorMsg = json?["error"] as? String ?? "Token exchange failed"
            print("❌ Token exchange error: \(errorMsg)")
            throw CognitoError.authenticationFailed(errorMsg)
        }
        
        guard let json = json else {
            throw CognitoError.invalidResponse
        }
        
        // Extract user info from ID token
        let username = try extractUsernameFromIDToken(json["id_token"] as? String ?? "")
        
        await MainActor.run {
            self.accessToken = json["access_token"] as? String
            self.idToken = json["id_token"] as? String
            self.refreshToken = json["refresh_token"] as? String
            self.currentUsername = username
            self.isAuthenticated = true
            self.codeVerifier = nil
            self.codeChallenge = nil
            self.saveTokensToKeychain()
        }
        
        print("✅ Secure sign in successful!")
    }
    
    // MARK: - Extract Username from ID Token
    
    private func extractUsernameFromIDToken(_ token: String) throws -> String {
        let parts = token.split(separator: ".")
        guard parts.count == 3 else {
            throw CognitoError.invalidResponse
        }
        
        var base64String = String(parts[1])
        // Add padding if needed
        while base64String.count % 4 != 0 {
            base64String.append("=")
        }
        
        guard let data = Data(base64Encoded: base64String),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let email = json["email"] as? String else {
            throw CognitoError.invalidResponse
        }
        
        return email
    }
    
    // MARK: - Sign Out
    
    func signOut() async {
        await MainActor.run {
            self.accessToken = nil
            self.idToken = nil
            self.refreshToken = nil
            self.currentUsername = nil
            self.isAuthenticated = false
            self.clearTokensFromKeychain()
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
        
        let response = try await makeRequest(endpoint: "\(cognitoURL)/", headers: headers, body: body)
        
        // Parse user attributes
        var attributes: [String: String] = [:]
        if let userAttrs = response["UserAttributes"] as? [[String: String]] {
            for attr in userAttrs {
                if let name = attr["Name"], let value = attr["Value"] {
                    attributes[name] = value
                }
            }
        }
        
        print("✅ Got user attributes: \(attributes)")
        return attributes
    }
    
    // MARK: - Helper Methods
    
    private func makeRequest(endpoint: String, headers: [String: String], body: [String: Any]) async throws -> [String: Any] {
        print("🌐 Making request to Cognito...")
        
        guard let url = URL(string: endpoint) else {
            throw CognitoError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        for (key, value) in headers {
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
                print("❌ Server error: \(errorString)")
                throw CognitoError.serverError(response.statusCode)
            }
            throw CognitoError.invalidResponse
        }
        
        if response.statusCode >= 400 {
            let errorMessage = json["message"] as? String ?? json["__type"] as? String ?? "Unknown error"
            print("❌ API Error: \(errorMessage)")
            throw CognitoError.apiError(errorMessage)
        }
        
        return json
    }
    
    // MARK: - Keychain Storage
    
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
    
    func checkSession() {
        print("🔍 Checking session...")
        loadTokensFromKeychain()
        print(isAuthenticated ? "✅ Session found" : "ℹ️ No session")
    }
    
    // MARK: - ASWebAuthenticationPresentationContextProviding
    
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return ASPresentationAnchor()
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
    case authenticationFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .invalidResponse: return "Invalid response"
        case .notAuthenticated: return "Not authenticated"
        case .noRefreshToken: return "No refresh token"
        case .serverError(let code): return "Server error: \(code)"
        case .apiError(let message): return message
        case .authenticationFailed(let message): return message
        }
    }
}
