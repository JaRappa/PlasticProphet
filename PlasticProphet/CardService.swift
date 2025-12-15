// CardService.swift
// Handles card lookups and management using the Rewards Credit Card API
// Based on verify_rewardscc_connection.py

import Foundation

// MARK: - API Response Models

struct CardAPIResponse: Codable {
    let cardName: String?
    let cardKey: String?
    let cardIssuer: String?
    let cardNetwork: String?
    let annualFee: Double?
    let baseSpendAmount: Double?
    let baseSpendEarnCategory: String?
    let spendBonusCategory: [SpendBonusCategory]?
    let cardUrl: String?
    let cardImageUrl: String?
}

struct SpendBonusCategory: Codable, Identifiable {
    var id: String { spendBonusCategoryName ?? UUID().uuidString }
    let spendBonusCategoryName: String?
    let earnMultiplier: Double?
    let spendBonusDesc: String?
}

// MARK: - Supported Card Model

struct SupportedCard: Codable, Identifiable {
    var id: String { cardKey }
    let cardName: String
    let cardKey: String
}

// MARK: - Card Service

@MainActor
class CardService: ObservableObject {
    
    static let shared = CardService()
    
    // MARK: - Published Properties
    
    @Published var supportedCards: [SupportedCard] = []
    @Published var isLoading: Bool = false
    @Published var lastError: String? = nil
    
    // MARK: - Configuration
    
    private let rapidAPIKey = ProcessInfo.processInfo.environment["RAPIDAPI_KEY"] ?? "YOUR_RAPIDAPI_KEY_HERE"
    private let baseURL = "https://rewards-credit-card-api.p.rapidapi.com"
    
    // Common card name aliases for fuzzy matching
    private let cardAliases: [String: String] = [
        "amex": "american express",
        "citi": "citibank",
        "cap one": "capital one",
        "boa": "bank of america",
    ]
    
    private let fuzzyThreshold: Double = 0.55
    
    // MARK: - Init
    
    init() {
        loadSupportedCards()
    }
    
    // MARK: - Load Supported Cards
    
    /// Loads supported cards from the bundled workingcards.json file
    func loadSupportedCards() {
        guard let url = Bundle.main.url(forResource: "workingcards", withExtension: "json") else {
            print("❌ Could not find workingcards.json in bundle")
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            supportedCards = try JSONDecoder().decode([SupportedCard].self, from: data)
            print("✅ Loaded \(supportedCards.count) supported cards")
        } catch {
            print("❌ Failed to load supported cards: \(error)")
        }
    }
    
    // MARK: - Local Card Matching
    
    /// Check if a card name matches any supported card locally (fuzzy match)
    func findLocalMatch(for query: String) -> SupportedCard? {
        let normalizedQuery = normalizeCardName(query)
        let expandedQuery = expandAliases(normalizedQuery)
        
        var bestMatch: SupportedCard?
        var bestScore: Double = 0
        
        for card in supportedCards {
            let normalizedCard = normalizeCardName(card.cardName)
            var score: Double = 0
            
            // Quick substring check
            if normalizedQuery.contains(normalizedCard) || normalizedCard.contains(normalizedQuery) {
                score = 1.0
            } else if expandedQuery.contains(normalizedCard) || normalizedCard.contains(expandedQuery) {
                score = 0.95
            } else {
                // Fuzzy similarity check
                let score1 = stringSimilarity(normalizedQuery, normalizedCard)
                let score2 = stringSimilarity(expandedQuery, normalizedCard)
                score = max(score1, score2)
            }
            
            if score > bestScore {
                bestScore = score
                bestMatch = card
            }
        }
        
        if bestScore >= fuzzyThreshold {
            print("✅ Found local match: \(bestMatch?.cardName ?? "Unknown") (score: \(String(format: "%.2f", bestScore)))")
            return bestMatch
        }
        
        return nil
    }
    
    /// Check if a card is supported
    func isCardSupported(_ cardKey: String) -> Bool {
        return supportedCards.contains { $0.cardKey.lowercased() == cardKey.lowercased() }
    }
    
    // MARK: - API Card Search
    
    /// Search for a card by name via the API
    func searchCardByName(_ query: String) async throws -> CardAPIResponse? {
        let variants = generateQueryVariants(query)
        print("🔍 Searching API with variants: \(variants)")
        
        for variant in variants {
            if let result = try? await performNameSearch(variant) {
                return result
            }
        }
        
        return nil
    }
    
    /// Fetch full card details by cardKey
    func fetchCardDetails(cardKey: String) async throws -> CardAPIResponse? {
        guard !rapidAPIKey.contains("YOUR_") else {
            throw CardServiceError.missingAPIKey
        }
        
        let encodedKey = cardKey.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? cardKey
        guard let url = URL(string: "\(baseURL)/creditcard-detail-bycard/\(encodedKey)") else {
            throw CardServiceError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(rapidAPIKey, forHTTPHeaderField: "X-RapidAPI-Key")
        request.setValue("rewards-credit-card-api.p.rapidapi.com", forHTTPHeaderField: "X-RapidAPI-Host")
        request.timeoutInterval = 10
        
        print("📡 Fetching details for cardKey: \(cardKey)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw CardServiceError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            print("⚠️ API returned status: \(httpResponse.statusCode)")
            throw CardServiceError.apiError(statusCode: httpResponse.statusCode)
        }
        
        // API returns an array, we want the first item
        let cards = try JSONDecoder().decode([CardAPIResponse].self, from: data)
        return cards.first
    }
    
    /// Complete card lookup - tries local first, then API
    func lookupCard(query: String) async -> (card: CardAPIResponse?, source: CardLookupSource) {
        isLoading = true
        lastError = nil
        defer { isLoading = false }
        
        // First try local match
        if let localMatch = findLocalMatch(for: query) {
            do {
                if let details = try await fetchCardDetails(cardKey: localMatch.cardKey) {
                    return (details, .local)
                }
            } catch {
                print("⚠️ Failed to fetch details for local match: \(error)")
            }
        }
        
        // Then try API search
        do {
            if let apiResult = try await searchCardByName(query) {
                return (apiResult, .api)
            }
        } catch {
            lastError = error.localizedDescription
            print("❌ API search failed: \(error)")
        }
        
        // Finally try treating input as cardKey
        do {
            if let directResult = try await fetchCardDetails(cardKey: query) {
                return (directResult, .directKey)
            }
        } catch {
            print("⚠️ Direct key lookup failed: \(error)")
        }
        
        return (nil, .notFound)
    }
    
    // MARK: - Private Helpers
    
    private func performNameSearch(_ query: String) async throws -> CardAPIResponse? {
        guard !rapidAPIKey.contains("YOUR_") else {
            throw CardServiceError.missingAPIKey
        }
        
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? query
        guard let url = URL(string: "\(baseURL)/creditcard-detail-namesearch/\(encoded)") else {
            throw CardServiceError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(rapidAPIKey, forHTTPHeaderField: "X-RapidAPI-Key")
        request.setValue("rewards-credit-card-api.p.rapidapi.com", forHTTPHeaderField: "X-RapidAPI-Host")
        request.timeoutInterval = 10
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            return nil
        }
        
        let cards = try JSONDecoder().decode([CardAPIResponse].self, from: data)
        return cards.first
    }
    
    private func normalizeCardName(_ name: String) -> String {
        return name.lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
    
    private func expandAliases(_ name: String) -> String {
        var result = name
        for (abbrev, full) in cardAliases {
            if result.hasPrefix(abbrev + " ") || result == abbrev {
                result = result.replacingOccurrences(of: abbrev, with: full)
                break
            }
        }
        return result
    }
    
    private func generateQueryVariants(_ raw: String) -> [String] {
        let base = normalizeCardName(raw).replacingOccurrences(of: "_", with: " ")
        var variants = [base]
        
        // Replace hyphens with spaces
        let hyphenSpace = base.replacingOccurrences(of: "-", with: " ")
        if !variants.contains(hyphenSpace) {
            variants.append(hyphenSpace)
        }
        
        // Expand aliases
        let expanded = expandAliases(hyphenSpace)
        if !variants.contains(expanded) {
            variants.append(expanded)
        }
        
        // Add "card" suffix if missing
        if !expanded.hasSuffix(" card") {
            let withCard = "\(expanded) card".trimmingCharacters(in: .whitespaces)
            if !variants.contains(withCard) {
                variants.append(withCard)
            }
        }
        
        return Array(variants.prefix(4))
    }
    
    /// Simple string similarity using Levenshtein-like approach
    private func stringSimilarity(_ s1: String, _ s2: String) -> Double {
        if s1 == s2 { return 1.0 }
        if s1.isEmpty || s2.isEmpty { return 0.0 }
        
        let longer = s1.count > s2.count ? s1 : s2
        let shorter = s1.count > s2.count ? s2 : s1
        
        let longerLength = Double(longer.count)
        let distance = Double(levenshteinDistance(longer, shorter))
        
        return (longerLength - distance) / longerLength
    }
    
    private func levenshteinDistance(_ s1: String, _ s2: String) -> Int {
        let s1Array = Array(s1)
        let s2Array = Array(s2)
        let m = s1Array.count
        let n = s2Array.count
        
        if m == 0 { return n }
        if n == 0 { return m }
        
        var matrix = [[Int]](repeating: [Int](repeating: 0, count: n + 1), count: m + 1)
        
        for i in 0...m { matrix[i][0] = i }
        for j in 0...n { matrix[0][j] = j }
        
        for i in 1...m {
            for j in 1...n {
                let cost = s1Array[i - 1] == s2Array[j - 1] ? 0 : 1
                matrix[i][j] = min(
                    matrix[i - 1][j] + 1,      // deletion
                    matrix[i][j - 1] + 1,      // insertion
                    matrix[i - 1][j - 1] + cost // substitution
                )
            }
        }
        
        return matrix[m][n]
    }
}

// MARK: - Supporting Types

enum CardLookupSource {
    case local
    case api
    case directKey
    case notFound
}

enum CardServiceError: LocalizedError {
    case missingAPIKey
    case invalidURL
    case invalidResponse
    case apiError(statusCode: Int)
    case cardNotFound
    
    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "API key is not configured"
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .apiError(let code):
            return "API error (status: \(code))"
        case .cardNotFound:
            return "Card not found"
        }
    }
}
