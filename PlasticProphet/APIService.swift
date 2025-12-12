// APIService.swift
// Handles general backend API calls (non-auth related)

import Foundation

class APIService {
    
    // We use the shared Base URL so we don't hardcode it in multiple places
    private let baseURL = CognitoConfig.apiBaseURL
    
    /// Checks if the backend is online and reachable
    func checkHealth() async throws -> String {
        guard let url = URL(string: baseURL + "/health") else {
            throw URLError(.badURL)
        }
        
        print("🌐 Checking Backend Health: \(url.absoluteString)")
        
        // Simple GET request (No Auth Header needed for this public endpoint)
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        if httpResponse.statusCode == 200 {
            // Parse the JSON message
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let message = json["message"] as? String {
                return message
            }
            return "Healthy (No message)"
        } else {
            throw URLError(.badServerResponse)
        }
    }
}
