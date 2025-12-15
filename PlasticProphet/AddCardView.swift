// AddCardView.swift
// Full-featured view for adding cards with search and API integration

import SwiftUI

struct AddCardView: View {
    @EnvironmentObject var app: AppState
    @Environment(\.dismiss) private var dismiss
    @StateObject private var cardService = CardService.shared
    
    @State private var searchQuery: String = ""
    @State private var searchResults: [CardAPIResponse] = []
    @State private var isSearching: Bool = false
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    @State private var selectedCard: CardAPIResponse? = nil
    @State private var showCardDetail: Bool = false
    
    // Debounce timer for search
    @State private var searchTask: Task<Void, Never>?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search Bar
                searchBar
                
                // Content
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Supported Cards Section
                        if searchQuery.isEmpty {
                            supportedCardsSection
                        } else {
                            searchResultsSection
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }
                .background(Color(.systemGroupedBackground))
            }
            .navigationTitle("Add Card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.ppGreen)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .sheet(isPresented: $showCardDetail) {
                if let card = selectedCard {
                    CardDetailSheet(card: card, onAdd: { addedCard in
                        addCardToWallet(addedCard)
                        showCardDetail = false
                        dismiss()
                    })
                }
            }
        }
    }
    
    // MARK: - Search Bar
    
    private var searchBar: some View {
        HStack(spacing: 12) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                TextField("Search for a credit card...", text: $searchQuery)
                    .font(.custom("Montserrat", size: 16))
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .onChange(of: searchQuery) { _, newValue in
                        performSearch(query: newValue)
                    }
                
                if !searchQuery.isEmpty {
                    Button {
                        searchQuery = ""
                        searchResults = []
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(12)
            .background(Color(.systemBackground))
            .cornerRadius(10)
            
            if isSearching {
                ProgressView()
                    .tint(.ppGreen)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - Supported Cards Section
    
    private var supportedCardsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Supported Cards")
                .font(.custom("Montserrat", size: 18))
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text("These cards are verified to work with our rewards tracking")
                .font(.custom("Montserrat", size: 13))
                .foregroundColor(.secondary)
            
            LazyVStack(spacing: 10) {
                ForEach(cardService.supportedCards) { supportedCard in
                    SupportedCardRow(card: supportedCard) {
                        selectSupportedCard(supportedCard)
                    }
                }
            }
        }
    }
    
    // MARK: - Search Results Section
    
    private var searchResultsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if isSearching {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        ProgressView()
                            .tint(.ppGreen)
                        Text("Searching...")
                            .font(.custom("Montserrat", size: 14))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding(.vertical, 40)
            } else if searchResults.isEmpty && !searchQuery.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "creditcard.trianglebadge.exclamationmark")
                        .font(.system(size: 48))
                        .foregroundColor(.gray)
                    Text("No cards found")
                        .font(.custom("Montserrat", size: 16))
                        .fontWeight(.medium)
                    Text("Try a different search term")
                        .font(.custom("Montserrat", size: 14))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                Text("Search Results")
                    .font(.custom("Montserrat", size: 18))
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                LazyVStack(spacing: 10) {
                    ForEach(searchResults, id: \.cardKey) { card in
                        SearchResultRow(card: card) {
                            selectedCard = card
                            showCardDetail = true
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Actions
    
    private func performSearch(query: String) {
        searchTask?.cancel()
        
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            searchResults = []
            return
        }
        
        searchTask = Task {
            // Debounce
            try? await Task.sleep(nanoseconds: 500_000_000)
            
            guard !Task.isCancelled else { return }
            
            await MainActor.run {
                isSearching = true
            }
            
            let (result, _) = await cardService.lookupCard(query: query)
            
            guard !Task.isCancelled else { return }
            
            await MainActor.run {
                isSearching = false
                if let card = result {
                    searchResults = [card]
                } else {
                    searchResults = []
                }
            }
        }
    }
    
    private func selectSupportedCard(_ supportedCard: SupportedCard) {
        Task {
            isSearching = true
            let (result, _) = await cardService.lookupCard(query: supportedCard.cardKey)
            isSearching = false
            
            if let card = result {
                selectedCard = card
                showCardDetail = true
            } else {
                // Fallback: add basic card info
                let basicCard = Card(
                    name: supportedCard.cardName,
                    network: "Unknown",
                    last4: "0000",
                    rewardSummary: "Rewards Card",
                    cardKey: supportedCard.cardKey
                )
                addCardToWallet(basicCard)
                dismiss()
            }
        }
    }
    
    private func addCardToWallet(_ card: Card) {
        // Check if card already exists
        if !app.cards.contains(where: { $0.cardKey == card.cardKey || $0.name == card.name }) {
            app.cards.append(card)
            print("✅ Added card to wallet: \(card.name)")
        } else {
            errorMessage = "This card is already in your wallet"
            showError = true
        }
    }
}

// MARK: - Supporting Views

struct SupportedCardRow: View {
    let card: SupportedCard
    let onTap: () -> Void
    
    // Get logo name based on card issuer/name
    private var logoName: String? {
        let name = card.cardName.lowercased()
        let key = card.cardKey.lowercased()
        
        if name.contains("chase") || key.contains("chase") { return "Chase" }
        if name.contains("amex") || name.contains("american express") || key.contains("amex") { return "Amex" }
        if name.contains("capital one") || key.contains("capitalone") { return "CapitalOne" }
        if name.contains("discover") || key.contains("discover") { return "Discover" }
        if name.contains("wells fargo") || key.contains("wellsfargo") { return "WellsFargo" }
        if name.contains("apple") || key.contains("apple") { return "Apple" }
        if name.contains("target") || key.contains("target") { return "Target" }
        if name.contains("american airlines") || key.contains("americanairlines") { return "AmericanAirlines" }
        
        return nil
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                // Card logo or default icon
                if let logo = logoName {
                    Image(logo)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 44, height: 44)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.ppGreen.opacity(0.15))
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: "creditcard.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.ppGreen)
                    }
                }
                
                // Only show user-friendly name
                Text(card.cardName)
                    .font(.custom("Montserrat", size: 15))
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.ppGreen)
            }
            .padding(14)
            .background(Color(.systemBackground))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

struct SearchResultRow: View {
    let card: CardAPIResponse
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.ppGreen.opacity(0.15))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "creditcard.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.ppGreen)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(card.cardName ?? "Unknown Card")
                        .font(.custom("Montserrat", size: 15))
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    
                    HStack(spacing: 8) {
                        if let issuer = card.cardIssuer {
                            Text(issuer)
                                .font(.custom("Montserrat", size: 12))
                                .foregroundColor(.secondary)
                        }
                        
                        if let network = card.cardNetwork {
                            Text("•")
                                .foregroundColor(.secondary)
                            Text(network)
                                .font(.custom("Montserrat", size: 12))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.gray)
            }
            .padding(14)
            .background(Color(.systemBackground))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

struct CardDetailSheet: View {
    let card: CardAPIResponse
    let onAdd: (Card) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Card Preview
                    VStack(spacing: 16) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.ppGreen, Color.ppGreen.opacity(0.7)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(height: 180)
                            
                            VStack(alignment: .leading, spacing: 12) {
                                Text(card.cardIssuer ?? "")
                                    .font(.custom("Montserrat", size: 14))
                                    .fontWeight(.medium)
                                    .foregroundColor(.white.opacity(0.8))
                                
                                Spacer()
                                
                                Text(card.cardName ?? "Credit Card")
                                    .font(.custom("Montserrat", size: 20))
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                
                                HStack {
                                    Text(card.cardNetwork ?? "")
                                        .font(.custom("Montserrat", size: 14))
                                        .foregroundColor(.white.opacity(0.9))
                                    
                                    Spacer()
                                    
                                    if let fee = card.annualFee {
                                        Text(fee > 0 ? "$\(Int(fee))/yr" : "No Annual Fee")
                                            .font(.custom("Montserrat", size: 14))
                                            .fontWeight(.medium)
                                            .foregroundColor(.white)
                                    }
                                }
                            }
                            .padding(20)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Rewards Section
                    if let categories = card.spendBonusCategory, !categories.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Bonus Categories")
                                .font(.custom("Montserrat", size: 18))
                                .fontWeight(.semibold)
                            
                            ForEach(categories.prefix(6)) { category in
                                HStack {
                                    Text(category.spendBonusCategoryName ?? "Category")
                                        .font(.custom("Montserrat", size: 15))
                                    
                                    Spacer()
                                    
                                    if let multiplier = category.earnMultiplier {
                                        Text("\(Int(multiplier))x")
                                            .font(.custom("Montserrat", size: 15))
                                            .fontWeight(.semibold)
                                            .foregroundColor(.ppGreen)
                                    }
                                }
                                .padding(.vertical, 8)
                                
                                if category.id != categories.prefix(6).last?.id {
                                    Divider()
                                }
                            }
                        }
                        .padding(16)
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .padding(.horizontal, 20)
                    }
                    
                    // Base Reward
                    if let baseAmount = card.baseSpendAmount,
                       let baseCategory = card.baseSpendEarnCategory {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Base Reward")
                                .font(.custom("Montserrat", size: 18))
                                .fontWeight(.semibold)
                            
                            HStack {
                                Text(baseCategory)
                                    .font(.custom("Montserrat", size: 15))
                                Spacer()
                                Text("\(Int(baseAmount))x")
                                    .font(.custom("Montserrat", size: 15))
                                    .fontWeight(.semibold)
                                    .foregroundColor(.ppGreen)
                            }
                        }
                        .padding(16)
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .padding(.horizontal, 20)
                    }
                    
                    Spacer(minLength: 100)
                }
                .padding(.top, 20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Card Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.ppGreen)
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button {
                    let newCard = Card(from: card)
                    onAdd(newCard)
                } label: {
                    Text("Add to Wallet")
                        .font(.custom("Montserrat", size: 18))
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.ppGreen)
                        )
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color(.systemBackground))
            }
        }
    }
}

#Preview {
    AddCardView()
        .environmentObject(AppState())
}
