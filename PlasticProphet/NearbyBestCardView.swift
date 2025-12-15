// NearbyBestCardView.swift
// Card view showing the best credit card for the nearest establishment

import SwiftUI
import MapKit

struct NearbyBestCardView: View {
    @EnvironmentObject var app: AppState
    @StateObject private var viewModel = NearbyBestCardViewModel()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if viewModel.isLoading {
                LoadingCardView()
            } else if let recommendation = viewModel.bestCardRecommendation {
                BestCardRecommendationView(recommendation: recommendation, nearbyPlace: viewModel.nearbyPlace)
            } else if let error = viewModel.errorMessage {
                ErrorCardView(message: error) {
                    Task {
                        await viewModel.refresh(cards: app.cards, location: app.locationService.lastLocation)
                    }
                }
            } else {
                EmptyNearbyCardView()
            }
        }
        .onAppear {
            viewModel.startAutoRefresh(cards: app.cards, locationService: app.locationService)
        }
        .onDisappear {
            viewModel.stopAutoRefresh()
        }
        .onChange(of: app.cards) { _, newCards in
            Task {
                await viewModel.refresh(cards: newCards, location: app.locationService.lastLocation)
            }
        }
    }
}

// MARK: - View Model

@MainActor
class NearbyBestCardViewModel: ObservableObject {
    @Published var bestCardRecommendation: BestCardRecommendation?
    @Published var nearbyPlace: MKMapItem?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var lastUpdate: Date?
    
    private var refreshTimer: Timer?
    private let refreshInterval: TimeInterval = 60 // 1 minute
    private var lastRefreshLocation: CLLocation? // Track the last location we refreshed for
    private let locationChangeThreshold: CLLocationDistance = 50 // meters - minimum distance to trigger refresh
    
    private let mccMatcherService = MCCMatcherService.shared
    private let rewardsService = RewardsLocalService.shared
    
    deinit {
        refreshTimer?.invalidate()
    }
    
    // MARK: - Auto Refresh
    
    private var storedLocationService: LocationService?
    private var storedCards: [Card] = []
    
    func startAutoRefresh(cards: [Card], locationService: LocationService) {
        // Store references for use in timer
        self.storedLocationService = locationService
        self.storedCards = cards
        
        // Initial fetch
        Task {
            await refresh(cards: cards, location: locationService.lastLocation, forceRefresh: true)
        }
        
        // Set up timer for periodic refresh (only if location changed)
        refreshTimer?.invalidate()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: refreshInterval, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                let currentLocation = self.storedLocationService?.lastLocation
                await self.refresh(cards: self.storedCards, location: currentLocation, forceRefresh: false)
            }
        }
    }
    
    func stopAutoRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
    
    // MARK: - Refresh Logic
    
    func refresh(cards: [Card], location: CLLocation?, forceRefresh: Bool = true) async {
        guard !cards.isEmpty else {
            errorMessage = "Add cards to get recommendations"
            bestCardRecommendation = nil
            return
        }
        
        guard let location = location else {
            errorMessage = "Enable location to find nearby places"
            bestCardRecommendation = nil
            return
        }
        
        // Check if location has changed enough to warrant a refresh
        if !forceRefresh {
            if let lastLocation = lastRefreshLocation {
                let distance = location.distance(from: lastLocation)
                if distance < locationChangeThreshold {
                    print("📍 Location hasn't changed enough (\(Int(distance))m < \(Int(locationChangeThreshold))m threshold), skipping refresh")
                    return
                }
                print("📍 Location changed by \(Int(distance))m, refreshing recommendations")
            }
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Step 1: Find nearest place of interest
            let place = try await findNearestPlace(at: location)
            nearbyPlace = place
            
            // Step 2: Get MCC code for the place
            let mccResponse = try await mccMatcherService.matchMCC(for: place)
            
            // Step 3: Get card keys from user's cards
            // For now, we'll use the card name as the key (you might need to map these properly)
            let cardKeys = cards.compactMap { cardNameToKey($0.name) }
            
            guard !cardKeys.isEmpty else {
                errorMessage = "No supported cards found"
                isLoading = false
                return
            }
            
            // Step 4: Find the best card for this merchant/MCC
            let merchantName = place.name ?? "Unknown Merchant"
            let bestCard = try await rewardsService.findBestCard(
                merchantName: merchantName,
                mcc: mccResponse.mcc,
                cardKeys: cardKeys
            )
            
            bestCardRecommendation = bestCard
            lastUpdate = Date()
            lastRefreshLocation = location // Update last refresh location
            
            if bestCard == nil {
                errorMessage = "No rewards found for nearby places"
            }
            
        } catch {
            print("❌ Error fetching nearby best card: \(error.localizedDescription)")
            errorMessage = "Unable to fetch recommendations"
        }
        
        isLoading = false
    }
    
    // MARK: - Private Helpers
    
    private func findNearestPlace(at location: CLLocation) async throws -> MKMapItem {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = "restaurant coffee store shop"
        request.region = MKCoordinateRegion(
            center: location.coordinate,
            latitudinalMeters: 500,
            longitudinalMeters: 500
        )
        request.resultTypes = .pointOfInterest
        
        let search = MKLocalSearch(request: request)
        let response = try await search.start()
        
        guard let nearestItem = response.mapItems.first else {
            throw NearbyCardError.noPlacesFound
        }
        
        return nearestItem
    }
    
    /// Convert card name to API card key
    /// This is a simplified mapping - you may need to expand this based on your workingcards.json
    private func cardNameToKey(_ name: String) -> String? {
        let lowercased = name.lowercased()
        
        // Common card mappings
        if lowercased.contains("amex") && lowercased.contains("gold") {
            return "amex-gold"
        }
        if lowercased.contains("amex") && lowercased.contains("platinum") {
            return "amex-platinum"
        }
        if lowercased.contains("chase") && lowercased.contains("sapphire") && lowercased.contains("preferred") {
            return "chase-sapphire-preferred"
        }
        if lowercased.contains("chase") && lowercased.contains("sapphire") && lowercased.contains("reserve") {
            return "chase-sapphire-reserve"
        }
        if lowercased.contains("chase") && lowercased.contains("freedom") && lowercased.contains("flex") {
            return "chase-freedom-flex"
        }
        if lowercased.contains("chase") && lowercased.contains("freedom") && lowercased.contains("unlimited") {
            return "chase-freedom-unlimited"
        }
        if lowercased.contains("discover") && lowercased.contains("it") {
            return "discover-it"
        }
        if lowercased.contains("capital one") && lowercased.contains("venture") {
            return "capital-one-venture"
        }
        if lowercased.contains("capital one") && lowercased.contains("savor") {
            return "capital-one-savor"
        }
        if lowercased.contains("citi") && lowercased.contains("double") {
            return "citi-double-cash"
        }
        if lowercased.contains("wells fargo") && lowercased.contains("active") {
            return "wells-fargo-active-cash"
        }
        
        // Default: convert name to slug format
        return name.lowercased()
            .replacingOccurrences(of: " ", with: "-")
            .replacingOccurrences(of: "•", with: "")
            .replacingOccurrences(of: "––", with: "-")
            .trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
    }
}

// MARK: - Error Types

enum NearbyCardError: LocalizedError {
    case noPlacesFound
    case noCardsConfigured
    
    var errorDescription: String? {
        switch self {
        case .noPlacesFound:
            return "No places found nearby"
        case .noCardsConfigured:
            return "No cards configured"
        }
    }
}

// MARK: - Subviews

struct LoadingCardView: View {
    var body: some View {
        VStack(spacing: 16) {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .frame(height: 180)
                .overlay(
                    VStack(spacing: 12) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Finding best card nearby...")
                            .font(.custom("Montserrat", size: 14))
                            .foregroundColor(.gray)
                    }
                )
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
        }
    }
}

struct BestCardRecommendationView: View {
    let recommendation: BestCardRecommendation
    let nearbyPlace: MKMapItem?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with location
            HStack {
                Image(systemName: "location.fill")
                    .foregroundColor(.ppGreen)
                    .font(.system(size: 14))
                
                Text("Near \(nearbyPlace?.name ?? "You")")
                    .font(.custom("Montserrat", size: 14))
                    .fontWeight(.medium)
                    .foregroundColor(.gray)
                
                Spacer()
                
                Image(systemName: "arrow.clockwise")
                    .foregroundColor(.gray.opacity(0.6))
                    .font(.system(size: 12))
                Text("Auto-updates")
                    .font(.custom("Montserrat", size: 11))
                    .foregroundColor(.gray.opacity(0.6))
            }
            
            Divider()
            
            // Best Card Info
            HStack(alignment: .top, spacing: 16) {
                // Card icon
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [Color.ppGreen, Color.ppGreen.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 40)
                    
                    Image(systemName: "creditcard.fill")
                        .foregroundColor(.white)
                        .font(.system(size: 20))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Best Card")
                        .font(.custom("Montserrat", size: 11))
                        .fontWeight(.medium)
                        .foregroundColor(.gray)
                    
                    Text(recommendation.cardName)
                        .font(.custom("Montserrat", size: 18))
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                        .lineLimit(2)
                }
                
                Spacer()
                
                // Reward Rate Badge
                VStack(spacing: 2) {
                    Text(recommendation.rewardRateDisplay)
                        .font(.custom("Montserrat", size: 28))
                        .fontWeight(.black)
                        .foregroundColor(.ppGreen)
                    
                    Text("Points")
                        .font(.custom("Montserrat", size: 10))
                        .fontWeight(.semibold)
                        .foregroundColor(.gray)
                }
            }
            
            // Category & Description
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: "tag.fill")
                        .foregroundColor(.ppGreen.opacity(0.7))
                        .font(.system(size: 12))
                    
                    Text(recommendation.category)
                        .font(.custom("Montserrat", size: 13))
                        .fontWeight(.semibold)
                        .foregroundColor(.ppGreen)
                }
                
                Text(recommendation.description)
                    .font(.custom("Montserrat", size: 12))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            // Related Benefits (if any)
            if !recommendation.relatedBenefits.isEmpty {
                Divider()
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Related Benefits")
                        .font(.custom("Montserrat", size: 11))
                        .fontWeight(.semibold)
                        .foregroundColor(.gray)
                    
                    ForEach(recommendation.relatedBenefits.prefix(2), id: \.benefitTitle) { benefit in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                                .font(.system(size: 10))
                            
                            Text(benefit.benefitTitle ?? "")
                                .font(.custom("Montserrat", size: 11))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
    }
}

struct ErrorCardView: View {
    let message: String
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .frame(height: 140)
                .overlay(
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 28))
                            .foregroundColor(.orange)
                        
                        Text(message)
                            .font(.custom("Montserrat", size: 14))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                        
                        Button("Retry") {
                            onRetry()
                        }
                        .font(.custom("Montserrat", size: 13))
                        .fontWeight(.semibold)
                        .foregroundColor(.ppGreen)
                    }
                    .padding()
                )
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
        }
    }
}

struct EmptyNearbyCardView: View {
    var body: some View {
        VStack(spacing: 16) {
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [6]))
                .frame(height: 160)
                .overlay(
                    VStack(spacing: 8) {
                        Image(systemName: "creditcard.and.123")
                            .font(.system(size: 36))
                            .foregroundColor(.ppGreen.opacity(0.5))
                        
                        Text("Best Card Nearby")
                            .font(.custom("Montserrat", size: 16))
                            .fontWeight(.medium)
                            .foregroundColor(.gray)
                        
                        Text("Add cards and enable location\nto see recommendations")
                            .font(.custom("Montserrat", size: 12))
                            .foregroundColor(.gray.opacity(0.7))
                            .multilineTextAlignment(.center)
                    }
                )
        }
    }
}

#Preview {
    VStack {
        BestCardRecommendationView(
            recommendation: BestCardRecommendation(
                cardName: "American Express Gold Card",
                cardKey: "amex-gold",
                rewardRate: 4.0,
                category: "Restaurants",
                description: "4X points at restaurants worldwide",
                merchantName: "Starbucks",
                mcc: "5812",
                source: "mcc_match",
                relatedBenefits: [
                    RelatedBenefit(benefitTitle: "$120 Dining Credit", benefitDesc: "Monthly dining credit")
                ]
            ),
            nearbyPlace: nil
        )
        .padding()
        
        LoadingCardView()
            .padding()
        
        EmptyNearbyCardView()
            .padding()
    }
    .background(Color(.systemGroupedBackground))
}
