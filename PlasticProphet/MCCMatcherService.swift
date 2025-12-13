// MCCMatcherService.swift
// Service to match location/place data to MCC codes via Lambda + ChatGPT

import Foundation
import MapKit

/// Response from the MCC Matcher API
struct MCCMatchResponse: Codable {
    let mcc: String
    let confidence: String
    let description: String?
    let irsDescription: String?
    let usdaDescription: String?
    let locationName: String?
    
    enum CodingKeys: String, CodingKey {
        case mcc
        case confidence
        case description
        case irsDescription = "irs_description"
        case usdaDescription = "usda_description"
        case locationName = "location_name"
    }
}

/// Error response from the API
struct MCCMatchErrorResponse: Codable {
    let error: String
}

/// Input data for MCC matching
struct MCCMatchRequest: Codable {
    let name: String
    let category: String?
    let address: String?
    let latitude: Double?
    let longitude: Double?
    let phoneNumber: String?
    let url: String?
}

/// Service class to interact with the MCC Matcher Lambda API
class MCCMatcherService {
    
    /// Shared instance for convenience
    static let shared = MCCMatcherService()
    
    /// Base URL for the API (uses the same API Gateway as other endpoints)
    private let baseURL = CognitoConfig.apiBaseURL
    
    /// Endpoint path for MCC matching
    private let mccMatchPath = "/mcc-match"
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Match a MapKit place to an MCC code
    /// - Parameter mapItem: The MKMapItem from MapKit search/nearby results
    /// - Returns: MCCMatchResponse with the matched MCC code
    func matchMCC(for mapItem: MKMapItem) async throws -> MCCMatchResponse {
        let request = MCCMatchRequest(
            name: mapItem.name ?? "Unknown",
            category: mapItem.pointOfInterestCategory?.rawValue,
            address: formatAddress(from: mapItem.placemark),
            latitude: mapItem.placemark.coordinate.latitude,
            longitude: mapItem.placemark.coordinate.longitude,
            phoneNumber: mapItem.phoneNumber,
            url: mapItem.url?.absoluteString
        )
        
        return try await matchMCC(request: request)
    }
    
    /// Match location data to an MCC code
    /// - Parameters:
    ///   - name: Business/location name (required)
    ///   - category: Business category (optional)
    ///   - address: Street address (optional)
    ///   - latitude: Latitude coordinate (optional)
    ///   - longitude: Longitude coordinate (optional)
    ///   - phoneNumber: Phone number (optional)
    ///   - url: Website URL (optional)
    /// - Returns: MCCMatchResponse with the matched MCC code
    func matchMCC(
        name: String,
        category: String? = nil,
        address: String? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        phoneNumber: String? = nil,
        url: String? = nil
    ) async throws -> MCCMatchResponse {
        let request = MCCMatchRequest(
            name: name,
            category: category,
            address: address,
            latitude: latitude,
            longitude: longitude,
            phoneNumber: phoneNumber,
            url: url
        )
        
        return try await matchMCC(request: request)
    }
    
    // MARK: - Private Methods
    
    private func matchMCC(request: MCCMatchRequest) async throws -> MCCMatchResponse {
        guard let url = URL(string: baseURL + mccMatchPath) else {
            throw MCCMatchError.invalidURL
        }
        
        print("🔍 Requesting MCC match for: \(request.name)")
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Encode request body
        let encoder = JSONEncoder()
        urlRequest.httpBody = try encoder.encode(request)
        
        // Make the request
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw MCCMatchError.invalidResponse
        }
        
        // Handle response
        switch httpResponse.statusCode {
        case 200:
            let decoder = JSONDecoder()
            let mccResponse = try decoder.decode(MCCMatchResponse.self, from: data)
            print("✅ MCC Match: \(mccResponse.mcc) (\(mccResponse.confidence)) - \(mccResponse.description ?? "N/A")")
            return mccResponse
            
        case 400:
            let errorResponse = try? JSONDecoder().decode(MCCMatchErrorResponse.self, from: data)
            throw MCCMatchError.badRequest(errorResponse?.error ?? "Bad request")
            
        case 500:
            let errorResponse = try? JSONDecoder().decode(MCCMatchErrorResponse.self, from: data)
            throw MCCMatchError.serverError(errorResponse?.error ?? "Server error")
            
        default:
            throw MCCMatchError.unexpectedStatus(httpResponse.statusCode)
        }
    }
    
    /// Format address from placemark
    private func formatAddress(from placemark: CLPlacemark) -> String? {
        var components: [String] = []
        
        if let subThoroughfare = placemark.subThoroughfare {
            components.append(subThoroughfare)
        }
        if let thoroughfare = placemark.thoroughfare {
            components.append(thoroughfare)
        }
        if let locality = placemark.locality {
            components.append(locality)
        }
        if let administrativeArea = placemark.administrativeArea {
            components.append(administrativeArea)
        }
        if let postalCode = placemark.postalCode {
            components.append(postalCode)
        }
        
        return components.isEmpty ? nil : components.joined(separator: ", ")
    }
}

// MARK: - Error Types

enum MCCMatchError: LocalizedError {
    case invalidURL
    case invalidResponse
    case badRequest(String)
    case serverError(String)
    case unexpectedStatus(Int)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .badRequest(let message):
            return "Bad request: \(message)"
        case .serverError(let message):
            return "Server error: \(message)"
        case .unexpectedStatus(let code):
            return "Unexpected status code: \(code)"
        }
    }
}
