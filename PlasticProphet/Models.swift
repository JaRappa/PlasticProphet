// Models.swift
// Data models for PlasticProphet matching PostgreSQL schema

import Foundation

// MARK: - User Model
struct User: Identifiable, Codable {
    let id: Int
    let username: String
    let email: String
    let phoneNumber: String?
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id = "user_id"
        case username
        case email
        case phoneNumber = "phone_number"
        case createdAt = "created_at"
    }
}

// MARK: - Card Model (matches wallet table)
struct Card: Identifiable, Codable, Hashable {
    let id: Int
    let userId: Int
    var cardType: String?           // e.g., "Signature", "Preferred", "Platinum"
    let cardNetwork: CardNetwork    // visa, mastercard, amex, discover, other
    var cardIssuer: String?         // e.g., "Chase", "Bank of America"
    var cardName: String?           // e.g., "Chase Sapphire Preferred"
    let addedAt: Date
    
    // Computed property for display
    var displayName: String {
        if let name = cardName, !name.isEmpty {
            return name
        } else if let issuer = cardIssuer, let type = cardType {
            return "\(issuer) \(cardNetwork.rawValue.capitalized) \(type)"
        } else if let issuer = cardIssuer {
            return "\(issuer) \(cardNetwork.rawValue.capitalized)"
        } else {
            return "\(cardNetwork.rawValue.capitalized) Card"
        }
    }
    
    // For backward compatibility with existing UI
    var name: String { displayName }
    var network: String { cardNetwork.rawValue }
    var last4: String { "****" } // No actual card numbers stored
    var rewardSummary: String {
        // This will be populated from a separate rewards table in future
        "Rewards vary by merchant"
    }
    
    enum CodingKeys: String, CodingKey {
        case id = "card_id"
        case userId = "user_id"
        case cardType = "card_type"
        case cardNetwork = "card_network"
        case cardIssuer = "card_issuer"
        case cardName = "card_name"
        case addedAt = "added_at"
    }
    
    // Custom hash for Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Card, rhs: Card) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Card Network Enum
enum CardNetwork: String, Codable, CaseIterable {
    case visa
    case mastercard
    case amex
    case discover
    case other
    
    var displayName: String {
        switch self {
        case .visa: return "Visa"
        case .mastercard: return "Mastercard"
        case .amex: return "American Express"
        case .discover: return "Discover"
        case .other: return "Other"
        }
    }
    
    var logoName: String {
        switch self {
        case .visa: return "Visa Logo"
        case .mastercard: return "MC Logo"
        case .amex: return "Amex Logo"
        case .discover: return "Discovery Logo"
        case .other: return "creditcard.fill"
        }
    }
}

// MARK: - Rolling Merchant Model
struct RollingMerchant: Identifiable, Codable {
    let userId: Int
    let generationId: UUID
    let merchantHash: String
    let rawPoiName: String?
    let generalizedName: String
    let categoryKey: String?
    let mcc: String?
    let lat: Double?
    let lon: Double?
    let radiusMeters: Int?
    let armGeofence: Bool?
    let regionIdentifier: String?
    let distanceMeters: Int?
    let detectedAt: Date
    let expiresAt: Date?
    
    var id: String { merchantHash }
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case generationId = "generation_id"
        case merchantHash = "merchant_hash"
        case rawPoiName = "raw_poi_name"
        case generalizedName = "generalized_name"
        case categoryKey = "category_key"
        case mcc
        case lat
        case lon
        case radiusMeters = "radius_meters"
        case armGeofence = "arm_geofence"
        case regionIdentifier = "region_identifier"
        case distanceMeters = "distance_meters"
        case detectedAt = "detected_at"
        case expiresAt = "expires_at"
    }
}

// MARK: - Favorite Merchant Model
struct FavoriteMerchant: Identifiable, Codable {
    let userId: Int
    let merchantHash: String
    let generalizedName: String
    let categoryKey: String?
    let lat: Double?
    let lon: Double?
    let createdAt: Date
    
    var id: String { merchantHash }
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case merchantHash = "merchant_hash"
        case generalizedName = "generalized_name"
        case categoryKey = "category_key"
        case lat
        case lon
        case createdAt = "created_at"
    }
}

// MARK: - Recommendation Model (for UI)
struct Recommendation: Identifiable, Hashable {
    let id = UUID()
    var card: Card
    var merchantName: String
    var rationale: String
    var rewardText: String
}

// MARK: - Permissions Status
struct PermissionsStatus {
    var cameraAuthorized: Bool = false
    var locationAuthorized: Bool = false
    var allGranted: Bool { cameraAuthorized && locationAuthorized }
}

// MARK: - API Request/Response Models

struct AddCardRequest: Codable {
    let userId: Int
    let cardNetwork: String
    let cardType: String?
    let cardIssuer: String?
    let cardName: String?
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case cardNetwork = "card_network"
        case cardType = "card_type"
        case cardIssuer = "card_issuer"
        case cardName = "card_name"
    }
}

struct RemoveCardRequest: Codable {
    let userId: Int
    let cardId: Int
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case cardId = "card_id"
    }
}

struct UpdateCardRequest: Codable {
    let userId: Int
    let cardId: Int
    let cardType: String?
    let cardIssuer: String?
    let cardName: String?
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case cardId = "card_id"
        case cardType = "card_type"
        case cardIssuer = "card_issuer"
        case cardName = "card_name"
    }
}

struct APIResponse<T: Codable>: Codable {
    let success: Bool
    let message: String?
    let error: String?
    let data: T?
}

struct WalletResponse: Codable {
    let success: Bool
    let cards: [Card]
    let count: Int
}

struct CardResponse: Codable {
    let success: Bool
    let cardId: Int?
    let message: String?
    let error: String?
    
    enum CodingKeys: String, CodingKey {
        case success
        case cardId = "card_id"
        case message
        case error
    }
}
