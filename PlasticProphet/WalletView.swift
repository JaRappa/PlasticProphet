// WalletView.swift
// Shows user's cards and a FAB for add options when no cards exist

import SwiftUI

struct WalletView: View {
    @EnvironmentObject var app: AppState
    @State private var showFABMenu: Bool = false
    @State private var showManualEntry: Bool = false
    @State private var showCardSelection: Bool = false
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
                    // empty state with dotted card
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
                    // show cards with swipe to delete
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
            
            // Backdrop when menu is open
            if showFABMenu {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            showFABMenu = false
                        }
                    }
                    .transition(.opacity)
            }
            
            // FAB Menu
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    VStack(alignment: .trailing, spacing: 16) {
                        // Menu options
                        if showFABMenu {
                            FABMenuItem(
                                icon: "magnifyingglass",
                                title: "Search Cards",
                                color: .ppGreen
                            ) {
                                withAnimation { showFABMenu = false }
                                showAddCard = true
                            }
                            .transition(.scale.combined(with: .opacity))
                            
                            FABMenuItem(
                                icon: "camera.fill",
                                title: "Scan Card",
                                color: .ppGreen
                            ) {
                                withAnimation { showFABMenu = false }
                                app.showingScanner = true
                            }
                            .transition(.scale.combined(with: .opacity))
                            
                            FABMenuItem(
                                icon: "pencil",
                                title: "Manual Entry",
                                color: .ppGreen
                            ) {
                                withAnimation { showFABMenu = false }
                                showManualEntry = true
                            }
                            .transition(.scale.combined(with: .opacity))
                        }
                        
                        // Main FAB Button
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                showFABMenu.toggle()
                            }
                        }) {
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
                                
                                Image(systemName: showFABMenu ? "xmark" : "plus")
                                    .font(.system(size: 24, weight: .semibold))
                                    .foregroundColor(.white)
                                    .rotationEffect(.degrees(showFABMenu ? 90 : 0))
                            }
                        }
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 100)
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showManualEntry) {
            NavigationStack {
                ManualAddView(showManual: $showManualEntry)
                    .environmentObject(app)
            }
        }
        .sheet(isPresented: $showAddCard) {
            AddCardView()
                .environmentObject(app)
        }
        .sheet(isPresented: $showCardSelection) {
            CardSelectionView()
                .environmentObject(app)
        }
        .sheet(item: $selectedCardForDetail) { card in
            CardWalletDetailView(card: card) {
                removeCard(card)
            }
        }
        .alert("Remove Card", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {
                cardToDelete = nil
            }
            Button("Remove", role: .destructive) {
                if let card = cardToDelete {
                    removeCard(card)
                }
                cardToDelete = nil
            }
        } message: {
            Text("Are you sure you want to remove \(cardToDelete?.name ?? "this card") from your wallet?")
        }
    }
    
    private func removeCard(_ card: Card) {
        withAnimation {
            app.removeCard(card)
        }
    }
}

struct ManualAddView: View {
    @EnvironmentObject var app: AppState
    @Binding var showManual: Bool
    @State private var cardNumber: String = ""
    @State private var network: String = ""
    @State private var rewards: String = ""

    var body: some View {
        Form {
            Section(header: Text("Card Info").font(.custom("Montserrat", size: 14))) {
                TextField("Card number", text: $cardNumber)
                    .keyboardType(.numberPad)
                    .font(.custom("Montserrat", size: 16))
                TextField("Card type (e.g. Visa)", text: $network)
                    .font(.custom("Montserrat", size: 16))
                TextField("Rewards summary", text: $rewards)
                    .font(.custom("Montserrat", size: 16))
            }
            Section {
                Button("Add Card") {
                    let digits = cardNumber.filter { $0.isNumber }
                    guard digits.count >= 4 else { return }
                    let last4 = String(digits.suffix(4))
                    let name = network.isEmpty ? "Manual Card ••••\(last4)" : "\(network) ••••\(last4)"
                    let card = Card(name: name, network: network.isEmpty ? "Unknown" : network, last4: last4, rewardSummary: rewards)
                    app.addCard(card)
                    showManual = false
                }
                .font(.custom("Montserrat", size: 16))
                .disabled(cardNumber.filter { $0.isNumber }.count < 4)
                
                Button("Cancel") {
                    showManual = false
                }
                .font(.custom("Montserrat", size: 16))
                .tint(.red)
            }
        }
        .navigationTitle("Add Card Manually")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Wallet Card Row

struct WalletCardRow: View {
    let card: Card
    let onTap: () -> Void
    
    private var networkColor: Color {
        switch card.network.lowercased() {
        case "visa":
            return Color.visaBlue
        case "mastercard":
            return Color.mastercardRed
        case "amex", "american express":
            return Color.amexBlue
        case "discover":
            return Color.discoverOrange
        default:
            return Color.ppGreen
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                // Card Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(networkColor.opacity(0.15))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "creditcard.fill")
                        .font(.system(size: 20))
                        .foregroundColor(networkColor)
                }
                
                // Card Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(card.name)
                        .font(.custom("Montserrat", size: 16))
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text(card.rewardSummary)
                        .font(.custom("Montserrat", size: 12))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Last 4 digits
                VStack(alignment: .trailing, spacing: 4) {
                    Text("••••\(card.last4)")
                        .font(.custom("Montserrat", size: 14))
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(card.network)
                        .font(.custom("Montserrat", size: 11))
                        .foregroundColor(.secondary)
                }
                
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
    
    private var networkColor: Color {
        switch card.network.lowercased() {
        case "visa":
            return Color.visaBlue
        case "mastercard":
            return Color.mastercardRed
        case "amex", "american express":
            return Color.amexBlue
        case "discover":
            return Color.discoverOrange
        default:
            return Color.ppGreen
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Card Visual
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: [networkColor, networkColor.opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(height: 200)
                        
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text(card.cardIssuer ?? card.network)
                                    .font(.custom("Montserrat", size: 14))
                                    .fontWeight(.medium)
                                    .foregroundColor(.white.opacity(0.8))
                                Spacer()
                                if let fee = card.annualFee {
                                    Text(fee > 0 ? "$\(Int(fee))/yr" : "No Fee")
                                        .font(.custom("Montserrat", size: 12))
                                        .fontWeight(.medium)
                                        .foregroundColor(.white.opacity(0.9))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.white.opacity(0.2))
                                        .cornerRadius(6)
                                }
                            }
                            
                            Spacer()
                            
                            Text("•••• •••• •••• \(card.last4)")
                                .font(.custom("Montserrat", size: 20))
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .tracking(2)
                            
                            Text(card.name)
                                .font(.custom("Montserrat", size: 16))
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            HStack {
                                Text(card.network)
                                    .font(.custom("Montserrat", size: 14))
                                    .foregroundColor(.white.opacity(0.9))
                                Spacer()
                            }
                        }
                        .padding(24)
                    }
                    .padding(.horizontal, 20)
                    
                    // Rewards Summary
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
                    
                    // Bonus Categories (if available)
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
                    
                    // Card Info
                    if card.cardKey != nil || card.cardIssuer != nil {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Card Information")
                                .font(.custom("Montserrat", size: 18))
                                .fontWeight(.semibold)
                            
                            if let issuer = card.cardIssuer {
                                InfoRow(label: "Issuer", value: issuer)
                            }
                            
                            InfoRow(label: "Network", value: card.network)
                            
                            if let fee = card.annualFee {
                                InfoRow(label: "Annual Fee", value: fee > 0 ? "$\(Int(fee))" : "None")
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
                    Button("Done") {
                        dismiss()
                    }
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
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.red)
                    )
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color(.systemBackground))
            }
        }
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.custom("Montserrat", size: 14))
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.custom("Montserrat", size: 14))
                .fontWeight(.medium)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    WalletView().environmentObject(AppState())
}
