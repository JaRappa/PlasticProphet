import Foundation

/// Service to communicate with the backend API for merchant data
struct MerchantNetworkService {
    
    private let baseURL: String
    private let session: URLSession
    
    init(baseURL: String = "https://your-api-gateway-url.execute-api.us-east-1.amazonaws.com/prod",
         session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }
    
    /// Fetch normalized merchant data and MCC info from backend
    /// - Parameters:
    ///   - merchantName: The raw merchant name from geofence
    ///   - userId: The authenticated user ID
    ///   - generationId: The current generation ID for tracking
    /// - Returns: Backend merchant response with normalized data
    func fetchNormalizedMerchant(
        merchantName: String,
        userId: String,
        generationId: String
    ) async throws -> NormalizedMerchantResponse {
        
        // Build the query parameters
        var components = URLComponents(string: "\(baseURL)/merchants")!
        components.queryItems = [
            URLQueryItem(name: "merchantName", value: merchantName),
            URLQueryItem(name: "userId", value: userId),
            URLQueryItem(name: "generationId", value: generationId)
        ]
        
        guard let url = components.url else {
            throw MerchantNetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw MerchantNetworkError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw MerchantNetworkError.httpError(statusCode: httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        let merchantResponse = try decoder.decode(NormalizedMerchantResponse.self, from: data)
        
        return merchantResponse
    }
}

// MARK: - Response Models

struct NormalizedMerchantResponse: Codable {
    let merchantName: String
    let generalizedName: String?
    let mcc: String?
    let mccLabel: String?
    let mccIrsCategory: String?
    let categoryKey: String?
    let lat: Double?
    let lon: Double?
    
    enum CodingKeys: String, CodingKey {
        case merchantName = "merchant_name"
        case generalizedName = "generalized_name"
        case mcc = "mcc"
        case mccLabel = "mcc_label"
        case mccIrsCategory = "mcc_irs_category"
        case categoryKey = "category_key"
        case lat
        case lon
    }
}

// MARK: - Error Handling

enum MerchantNetworkError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int)
    case decodingError(Error)
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The URL is invalid"
        case .invalidResponse:
            return "Received an invalid response from the server"
        case .httpError(let statusCode):
            return "HTTP error: \(statusCode)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}
