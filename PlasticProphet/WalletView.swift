// WalletView.swift
// Shows user's cards with add and remove functionality

import SwiftUI

struct WalletView: View {
    @EnvironmentObject var app: AppState
    @State private var showAddCard: Bool = false
    @State private var selectedCardForDetail: Card? = nil
    @State private var showDeleteConfirmation: Bool = false
    @State private var cardToDelete: Card? = nil

    var body: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 18) {
                Text("Wallet")
                    .font(.custom("Montserrat", size: 32))
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                    .padding(.top, 20)
                    .tracking(-1.5)
                Text("Your Cards")
                    .font(.custom("Montserrat", size: 20))
                    .fontWeight(.semibold)
                    .foregroundColor(.ppGreen)
                    .tracking(-0.5)

                if app.cards.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.gray.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [6]))
                            .frame(height: 100)
                            .overlay(
                                Text("Please Add Card...")
                                    .font(.custom("Montserrat", size: 14))
                                    .fontWeight(.medium)
                                    .foregroundColor(.gray.opacity(0.5))
                                    .padding(.top, 12)
                                    .padding(.leading, 12), alignment: .topLeading
                            )
                    }
                    .padding(.horizontal, 16)
                    Spacer()
                } else {
                    List {
                        ForEach(app.cards) { card in
                            WalletCardRow(card: card) {
                                selectedCardForDetail = card
                            }
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    cardToDelete = card
                                    showDeleteConfirmation = true
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .padding(16)
            
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: { showAddCard = true }) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.ppGreen, Color.ppGreen.opacity(0.8)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 60, height: 60)
                                .shadow(color: Color.ppShadow.opacity(0.4), radius: 12, x: 0, y: 6)
                            
                            Image(systemName: "plus")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 100)
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showAddCard) {
            AddCardView()
                .environmentObject(app)
        }
        .sheet(item: $selectedCardForDetail) { card in
            CardWalletDetailView(card: card) {
                removeCard(card)
            }
        }
        .alert("Remove Card", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { cardToDelete = nil }
            Button("Remove", role: .destructive) {
                if let card = cardToDelete { removeCard(card) }
                cardToDelete = nil
            }
        } message: {
            Text("Are you sure you want to remove \(cardToDelete?.name ?? "this card") from your wallet?")
        }
    }
    
    private func removeCard(_ card: Card) {
        withAnimation { app.removeCard(card) }
    }
}

// MARK: - Card Image Helper

struct CardImageHelper {
    static func imageNameForCardKey(_ cardKey: String) -> String? {
        let key = cardKey.lowercased()
        if key.contains("amex") || key.contains("american-express") { return "Amex" }
        if key.contains("chase") { return "Chase" }
        if key.contains("discover") { return "Discover" }
        if key.contains("apple") || key.contains("goldmansachs") { return "Apple" }
        if key.contains("capitalone") || key.contains("capital-one") { return "CapitalOne" }
        if key.contains("wellsfargo") || key.contains("wells-fargo") { return "WellsFargo" }
        if key.contains("target") || key.contains("tdbank") { return "Target" }
        if key.contains("abbybank") || key.contains("abby-bank") { return "AbbyBank" }
        if key.contains("americanairlines") || key.contains("aacfu") { return "AmericanAirlines" }
        return nil
    }
}

// MARK: - Wallet Card Row

struct WalletCardRow: View {
    let card: Card
    let onTap: () -> Void
    
    private var cardImageName: String? {
        guard let cardKey = card.cardKey else { return nil }
        return CardImageHelper.imageNameForCardKey(cardKey)
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                if let imageName = cardImageName, let uiImage = UIImage(named: imageName) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 50, height: 50)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.ppGreen.opacity(0.15))
                            .frame(width: 50, height: 50)
                        Image(systemName: "creditcard.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.ppGreen)
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(card.name)
                        .font(.custom("Montserrat", size: 16))
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                    Text(card.rewardSummary)
                        .font(.custom("Montserrat", size: 12))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.gray)
            }
            .padding(14)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Card Wallet Detail View

struct CardWalletDetailView: View {
    let card: Card
    let onRemove: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    private var cardImageName: String? {
        guard let cardKey = card.cardKey else { return nil }
        return CardImageHelper.imageNameForCardKey(cardKey)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 16) {
                        if let imageName = cardImageName, let uiImage = UIImage(named: imageName) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxWidth: .infinity)
                                .frame(height: 220)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
                        } else {
                            ZStack {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(LinearGradient(colors: [Color.ppGreen, Color.ppGreen.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .frame(height: 200)
                                VStack(alignment: .leading, spacing: 16) {
                                    Spacer()
                                    Text(card.name)
                                        .font(.custom("Montserrat", size: 20))
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                }
                                .padding(24)
                            }
                        }
                        
                        Text(card.name)
                            .font(.custom("Montserrat", size: 22))
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                        
                        if let fee = card.annualFee {
                            Text(fee > 0 ? "$\(Int(fee)) Annual Fee" : "No Annual Fee")
                                .font(.custom("Montserrat", size: 14))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Rewards Summary")
                            .font(.custom("Montserrat", size: 18))
                            .fontWeight(.semibold)
                        Text(card.rewardSummary)
                            .font(.custom("Montserrat", size: 15))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal, 20)
                    
                    if let categories = card.spendBonusCategories, !categories.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Bonus Categories")
                                .font(.custom("Montserrat", size: 18))
                                .fontWeight(.semibold)
                            ForEach(categories.prefix(6), id: \.name) { category in
                                HStack {
                                    Text(category.name)
                                        .font(.custom("Montserrat", size: 15))
                                    Spacer()
                                    Text("\(Int(category.multiplier))x")
                                        .font(.custom("Montserrat", size: 15))
                                        .fontWeight(.semibold)
                                        .foregroundColor(.ppGreen)
                                }
                                .padding(.vertical, 8)
                                if category.name != categories.prefix(6).last?.name {
                                    Divider()
                                }
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
                    Button("Done") { dismiss() }
                        .foregroundColor(.ppGreen)
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button {
                    onRemove()
                    dismiss()
                } label: {
                    HStack {
                        Image(systemName: "trash")
                        Text("Remove from Wallet")
                    }
                    .font(.custom("Montserrat", size: 16))
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(16)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.red))
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color(.systemBackground))
            }
        }
    }
}

#Preview {
    WalletView().environmentObject(AppState())
}
