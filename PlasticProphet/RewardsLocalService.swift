// RewardsLocalService.swift
// Service to get the best card recommendation for a merchant based on MCC code

import Foundation

// MARK: - Response Models

struct RewardsLocalRequest: Codable {
    let merchantName: String
    let mcc: String
    let cardKey: String
    
    enum CodingKeys: String, CodingKey {
        case merchantName = "merchant_name"
        case mcc
        case cardKey = "card_key"
    }
}

struct RewardsLocalResponse: Codable {
    let source: String?
    let cardName: String?
    let rewardRate: Double?
    let category: String?
    let description: String?
    let relatedBenefits: [RelatedBenefit]?
    
    enum CodingKeys: String, CodingKey {
        case source
        case cardName = "card_name"
        case rewardRate = "reward_rate"
        case category
        case description
        case relatedBenefits = "related_benefits"
    }
}

struct RelatedBenefit: Codable {
    let benefitTitle: String?
    let benefitDesc: String?
    
    enum CodingKeys: String, CodingKey {
        case benefitTitle = "benefit_title"
        case benefitDesc = "benefit_desc"
    }
}

struct BestCardRecommendation: Identifiable {
    let id = UUID()
    let cardName: String
    let cardKey: String
    let rewardRate: Double
    let category: String
    let description: String
    let merchantName: String
    let mcc: String
    let source: String
    let relatedBenefits: [RelatedBenefit]
    
    var rewardRateDisplay: String {
        if rewardRate == floor(rewardRate) {
            return "\(Int(rewardRate))X"
        }
        return String(format: "%.1fX", rewardRate)
    }
}

// MARK: - Rewards Local Service

class RewardsLocalService {
    
    static let shared = RewardsLocalService()
    
    private let baseURL = "https://0vl413zppl.execute-api.us-east-1.amazonaws.com"
    private let rewardsPath = "/test_rewards_local"
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Get the best card for a merchant based on MCC code
    /// - Parameters:
    ///   - merchantName: The name of the merchant
    ///   - mcc: The MCC code for the merchant category
    ///   - cardKey: The card key/slug to check (e.g., "amex-gold")
    /// - Returns: RewardsLocalResponse with reward information
    func getCardRewards(merchantName: String, mcc: String, cardKey: String) async throws -> RewardsLocalResponse {
        guard let url = URL(string: baseURL + rewardsPath) else {
            throw RewardsLocalError.invalidURL
        }
        
        print("🎁 Fetching rewards for \(merchantName) (MCC: \(mcc)) with card \(cardKey)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 15
        
        // Create request body
        let requestBody = RewardsLocalRequest(
            merchantName: merchantName,
            mcc: mcc,
            cardKey: cardKey
        )
        
        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw RewardsLocalError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200:
            let decoder = JSONDecoder()
            let rewardsResponse = try decoder.decode(RewardsLocalResponse.self, from: data)
            print("✅ Rewards response: \(rewardsResponse.rewardRate ?? 1.0)X for \(rewardsResponse.category ?? "Unknown")")
            return rewardsResponse
            
        case 400:
            throw RewardsLocalError.badRequest
            
        case 500:
            throw RewardsLocalError.serverError
            
        default:
            throw RewardsLocalError.unexpectedStatus(httpResponse.statusCode)
        }
    }
    
    /// Find the best card from a list of cards for a specific merchant/MCC
    /// - Parameters:
    ///   - merchantName: The merchant name
    ///   - mcc: The MCC code
    ///   - cardKeys: Array of card keys to compare
    ///   - userFriendlyNames: Dictionary mapping card keys to user-friendly display names
    /// - Returns: The best card recommendation with highest reward rate
    func findBestCard(merchantName: String, mcc: String, cardKeys: [String], userFriendlyNames: [String: String] = [:]) async throws -> BestCardRecommendation? {
        guard !cardKeys.isEmpty else { return nil }
        
        var bestRecommendation: BestCardRecommendation?
        var highestRate: Double = 0
        
        // Query each card and find the best one
        for cardKey in cardKeys {
            do {
                let response = try await getCardRewards(merchantName: merchantName, mcc: mcc, cardKey: cardKey)
                let rate = response.rewardRate ?? 1.0
                
                if rate > highestRate {
                    highestRate = rate
                    // Use user-friendly name if available, otherwise use API response name or format the cardKey
                    let displayName = userFriendlyNames[cardKey] ?? response.cardName ?? formatCardKeyAsName(cardKey)
                    bestRecommendation = BestCardRecommendation(
                        cardName: displayName,
                        cardKey: cardKey,
                        rewardRate: rate,
                        category: response.category ?? "General",
                        description: response.description ?? "Base rewards rate",
                        merchantName: merchantName,
                        mcc: mcc,
                        source: response.source ?? "base_rate",
                        relatedBenefits: response.relatedBenefits ?? []
                    )
                }
            } catch {
                print("⚠️ Failed to get rewards for card \(cardKey): \(error.localizedDescription)")
                continue
            }
        }
        
        return bestRecommendation
    }
    
    /// Format a card key (e.g., "amex-gold") into a user-friendly name (e.g., "Amex Gold")
    private func formatCardKeyAsName(_ cardKey: String) -> String {
        return cardKey
            .replacingOccurrences(of: "-", with: " ")
            .split(separator: " ")
            .map { $0.prefix(1).uppercased() + $0.dropFirst().lowercased() }
            .joined(separator: " ")
    }
}

// MARK: - Error Types

enum RewardsLocalError: LocalizedError {
    case invalidURL
    case invalidResponse
    case badRequest
    case serverError
    case unexpectedStatus(Int)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .badRequest:
            return "Bad request"
        case .serverError:
            return "Server error"
        case .unexpectedStatus(let code):
            return "Unexpected status code: \(code)"
        }
    }
}
