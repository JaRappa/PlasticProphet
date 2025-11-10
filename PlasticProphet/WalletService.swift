// WalletService.swift
// Service layer for wallet API communication with Python backend

import Foundation

class WalletService: ObservableObject {
    
    // MARK: - Configuration
    
    private let baseURL: String
    private let session: URLSession
    
    init(baseURL: String = APIConfig.baseURL) {
        self.baseURL = baseURL
        
        // Configure session with timeout
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: config)
    }
    
    // MARK: - Fetch Wallet
    
    func fetchWallet(userId: Int) async throws -> [Card] {
        print("🔵 WalletService: Fetching wallet for user \(userId)")
        
        let endpoint = "\(baseURL)/wallet/\(userId)"
        guard let url = URL(string: endpoint) else {
            throw WalletError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, httpResponse) = try await session.data(for: request)
        
        guard let response = httpResponse as? HTTPURLResponse else {
            throw WalletError.invalidResponse
        }
        
        print("📥 Wallet fetch response: \(response.statusCode)")
        
        guard response.statusCode == 200 else {
            if let errorResponse = try? JSONDecoder().decode(CardResponse.self, from: data) {
                throw WalletError.apiError(errorResponse.error ?? "Unknown error")
            }
            throw WalletError.serverError(response.statusCode)
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let walletResponse = try decoder.decode(WalletResponse.self, from: data)
        
        print("✅ Fetched \(walletResponse.count) cards")
        return walletResponse.cards
    }
    
    // MARK: - Add Card
    
    func addCard(
        userId: Int,
        cardNetwork: CardNetwork,
        cardType: String? = nil,
        cardIssuer: String? = nil,
        cardName: String? = nil
    ) async throws -> Card {
        print("🔵 WalletService: Adding card for user \(userId)")
        
        let endpoint = "\(baseURL)/wallet/add"
        guard let url = URL(string: endpoint) else {
            throw WalletError.invalidURL
        }
        
        let requestBody = AddCardRequest(
            userId: userId,
            cardNetwork: cardNetwork.rawValue,
            cardType: cardType,
            cardIssuer: cardIssuer,
            cardName: cardName
        )
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        request.httpBody = try encoder.encode(requestBody)
        
        let (data, httpResponse) = try await session.data(for: request)
        
        guard let response = httpResponse as? HTTPURLResponse else {
            throw WalletError.invalidResponse
        }
        
        print("📥 Add card response: \(response.statusCode)")
        
        let decoder = JSONDecoder()
        let cardResponse = try decoder.decode(CardResponse.self, from: data)
        
        guard cardResponse.success, let cardId = cardResponse.cardId else {
            throw WalletError.apiError(cardResponse.error ?? "Failed to add card")
        }
        
        print("✅ Card added with ID: \(cardId)")
        
        // Fetch the newly added card to get complete details
        let cards = try await fetchWallet(userId: userId)
        guard let newCard = cards.first(where: { $0.id == cardId }) else {
            throw WalletError.cardNotFound
        }
        
        return newCard
    }
    
    // MARK: - Remove Card
    
    func removeCard(userId: Int, cardId: Int) async throws {
        print("🔵 WalletService: Removing card \(cardId) for user \(userId)")
        
        let endpoint = "\(baseURL)/wallet/remove"
        guard let url = URL(string: endpoint) else {
            throw WalletError.invalidURL
        }
        
        let requestBody = RemoveCardRequest(userId: userId, cardId: cardId)
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        request.httpBody = try encoder.encode(requestBody)
        
        let (data, httpResponse) = try await session.data(for: request)
        
        guard let response = httpResponse as? HTTPURLResponse else {
            throw WalletError.invalidResponse
        }
        
        print("📥 Remove card response: \(response.statusCode)")
        
        let decoder = JSONDecoder()
        let cardResponse = try decoder.decode(CardResponse.self, from: data)
        
        guard cardResponse.success else {
            throw WalletError.apiError(cardResponse.error ?? "Failed to remove card")
        }
        
        print("✅ Card removed successfully")
    }
    
    // MARK: - Update Card
    
    func updateCard(
        userId: Int,
        cardId: Int,
        cardType: String? = nil,
        cardIssuer: String? = nil,
        cardName: String? = nil
    ) async throws -> Card {
        print("🔵 WalletService: Updating card \(cardId) for user \(userId)")
        
        let endpoint = "\(baseURL)/wallet/update"
        guard let url = URL(string: endpoint) else {
            throw WalletError.invalidURL
        }
        
        let requestBody = UpdateCardRequest(
            userId: userId,
            cardId: cardId,
            cardType: cardType,
            cardIssuer: cardIssuer,
            cardName: cardName
        )
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        request.httpBody = try encoder.encode(requestBody)
        
        let (data, httpResponse) = try await session.data(for: request)
        
        guard let response = httpResponse as? HTTPURLResponse else {
            throw WalletError.invalidResponse
        }
        
        print("📥 Update card response: \(response.statusCode)")
        
        let decoder = JSONDecoder()
        let cardResponse = try decoder.decode(CardResponse.self, from: data)
        
        guard cardResponse.success else {
            throw WalletError.apiError(cardResponse.error ?? "Failed to update card")
        }
        
        print("✅ Card updated successfully")
        
        // Fetch the updated card
        let cards = try await fetchWallet(userId: userId)
        guard let updatedCard = cards.first(where: { $0.id == cardId }) else {
            throw WalletError.cardNotFound
        }
        
        return updatedCard
    }
    
    // MARK: - Get Cards by Network
    
    func getCardsByNetwork(userId: Int, network: CardNetwork) async throws -> [Card] {
        print("🔵 WalletService: Fetching \(network.displayName) cards for user \(userId)")
        
        let endpoint = "\(baseURL)/wallet/\(userId)/network/\(network.rawValue)"
        guard let url = URL(string: endpoint) else {
            throw WalletError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, httpResponse) = try await session.data(for: request)
        
        guard let response = httpResponse as? HTTPURLResponse else {
            throw WalletError.invalidResponse
        }
        
        guard response.statusCode == 200 else {
            throw WalletError.serverError(response.statusCode)
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let walletResponse = try decoder.decode(WalletResponse.self, from: data)
        
        print("✅ Fetched \(walletResponse.count) \(network.displayName) cards")
        return walletResponse.cards
    }
}

// MARK: - Errors

enum WalletError: LocalizedError {
    case invalidURL
    case invalidResponse
    case serverError(Int)
    case apiError(String)
    case cardNotFound
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .serverError(let code):
            return "Server error: \(code)"
        case .apiError(let message):
            return message
        case .cardNotFound:
            return "Card not found"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}

// MARK: - API Configuration

struct APIConfig {
    // TODO: Update with your actual API Gateway URL
    static let baseURL = "https://your-api-gateway.execute-api.us-east-1.amazonaws.com/prod"
    
    // For local development
    static let localURL = "http://localhost:8000"
    
    // Toggle for development vs production
    #if DEBUG
    // static let baseURL = localURL  // Uncomment for local testing
    #endif
}
