// WalletView.swift
// Shows user's cards with real API integration

import SwiftUI

struct WalletView: View {
    @EnvironmentObject var app: AppState
    @State private var showFABMenu: Bool = false
    @State private var showManualEntry: Bool = false
    @State private var showCardSelection: Bool = false
    @State private var showEditCard: Card?
    @State private var cardToDelete: Card?
    @State private var showDeleteAlert = false

    var body: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 18) {
                // Header
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

                // Error Message
                if let error = app.walletError {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                        Text(error)
                            .font(.custom("Montserrat", size: 14))
                            .foregroundColor(.red)
                    }
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
                    .padding(.horizontal)
                }
                
                // Loading State
                if app.isLoadingWallet {
                    VStack {
                        ProgressView()
                            .scaleEffect(1.5)
                            .padding()
                        Text("Loading wallet...")
                            .font(.custom("Montserrat", size: 14))
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                // Empty State
                else if app.cards.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.gray.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [6]))
                            .frame(height: 100)
                            .overlay(
                                VStack(spacing: 8) {
                                    Image(systemName: "creditcard")
                                        .font(.system(size: 40))
                                        .foregroundColor(.gray.opacity(0.3))
                                    Text("No cards yet")
                                        .font(.custom("Montserrat", size: 16))
                                        .fontWeight(.medium)
                                        .foregroundColor(.gray.opacity(0.5))
                                    Text("Tap + to add your first card")
                                        .font(.custom("Montserrat", size: 12))
                                        .foregroundColor(.gray.opacity(0.4))
                                }
                            )
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 40)

                    Spacer()
                }
                // Cards List
                else {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(app.cards) { card in
                                CardRowView(card: card)
                                    .onTapGesture {
                                        showEditCard = card
                                    }
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            cardToDelete = card
                                            showDeleteAlert = true
                                        } label: {
                                            Label("Delete Card", systemImage: "trash")
                                        }
                                    }
                            }
                        }
                        .padding(.top)
                        .padding(.horizontal)
                    }
                    .refreshable {
                        await app.fetchWallet()
                    }
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
                                showCardSelection = true
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
        .sheet(isPresented: $app.showingScanner) {
            ScannerView()
        }
        .sheet(isPresented: $showManualEntry) {
            NavigationStack {
                AddCardView(isPresented: $showManualEntry)
                    .environmentObject(app)
            }
        }
        .sheet(item: $showEditCard) { card in
            NavigationStack {
                EditCardView(card: card, isPresented: .constant(true))
                    .environmentObject(app)
            }
        }
        .sheet(isPresented: $showCardSelection) {
            CardSelectionView()
                .environmentObject(app)
        }
        .alert("Delete Card", isPresented: $showDeleteAlert, presenting: cardToDelete) { card in
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task {
                    _ = await app.removeCard(card)
                }
            }
        } message: { card in
            Text("Are you sure you want to delete \(card.displayName)?")
        }
        .onAppear {
            // Load wallet when view appears
            Task {
                await app.fetchWallet()
            }
        }
    }
}

// MARK: - Card Row View
struct CardRowView: View {
    let card: Card
    
    var body: some View {
        HStack(spacing: 16) {
            // Card network logo
            if let uiImage = UIImage(named: card.cardNetwork.logoName) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 50, height: 32)
            } else {
                Image(systemName: "creditcard.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.ppGreen)
                    .frame(width: 50, height: 32)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(card.displayName)
                    .font(.custom("Montserrat", size: 16))
                    .fontWeight(.semibold)
                    .foregroundColor(.black)
                
                if let issuer = card.cardIssuer {
                    Text(issuer)
                        .font(.custom("Montserrat", size: 12))
                        .foregroundColor(.gray)
                }
                
                Text(card.cardNetwork.displayName)
                    .font(.custom("Montserrat", size: 11))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.gray.opacity(0.5))
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Add Card View
struct AddCardView: View {
    @EnvironmentObject var app: AppState
    @Binding var isPresented: Bool
    
    @State private var selectedNetwork: CardNetwork = .visa
    @State private var cardType: String = ""
    @State private var cardIssuer: String = ""
    @State private var cardName: String = ""
    @State private var isSubmitting = false
    
    var body: some View {
        Form {
            Section(header: Text("Card Network").font(.custom("Montserrat", size: 14))) {
                Picker("Network", selection: $selectedNetwork) {
                    ForEach(CardNetwork.allCases, id: \.self) { network in
                        Text(network.displayName).tag(network)
                    }
                }
                .pickerStyle(.segmented)
            }
            
            Section(header: Text("Card Details").font(.custom("Montserrat", size: 14))) {
                TextField("Card Name (e.g., Chase Sapphire Preferred)", text: $cardName)
                    .font(.custom("Montserrat", size: 16))
                
                TextField("Issuer (e.g., Chase)", text: $cardIssuer)
                    .font(.custom("Montserrat", size: 16))
                
                TextField("Type (e.g., Signature, Platinum)", text: $cardType)
                    .font(.custom("Montserrat", size: 16))
            }
            
            Section {
                Button(action: {
                    Task {
                        await submitCard()
                    }
                }) {
                    if isSubmitting {
                        HStack {
                            Spacer()
                            ProgressView()
                            Text("Adding...")
                                .font(.custom("Montserrat", size: 16))
                            Spacer()
                        }
                    } else {
                        Text("Add Card")
                            .font(.custom("Montserrat", size: 16))
                            .frame(maxWidth: .infinity)
                    }
                }
                .disabled(isSubmitting || cardName.isEmpty)
                
                Button("Cancel") {
                    isPresented = false
                }
                .font(.custom("Montserrat", size: 16))
                .tint(.red)
            }
        }
        .navigationTitle("Add Card")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func submitCard() async {
        isSubmitting = true
        
        let success = await app.addCard(
            network: selectedNetwork,
            type: cardType.isEmpty ? nil : cardType,
            issuer: cardIssuer.isEmpty ? nil : cardIssuer,
            name: cardName.isEmpty ? nil : cardName
        )
        
        isSubmitting = false
        
        if success {
            isPresented = false
        }
    }
}

// MARK: - Edit Card View
struct EditCardView: View {
    @EnvironmentObject var app: AppState
    let card: Card
    @Binding var isPresented: Bool
    
    @State private var cardType: String
    @State private var cardIssuer: String
    @State private var cardName: String
    @State private var isSubmitting = false
    
    init(card: Card, isPresented: Binding<Bool>) {
        self.card = card
        self._isPresented = isPresented
        self._cardType = State(initialValue: card.cardType ?? "")
        self._cardIssuer = State(initialValue: card.cardIssuer ?? "")
        self._cardName = State(initialValue: card.cardName ?? "")
    }
    
    var body: some View {
        Form {
            Section(header: Text("Card Network").font(.custom("Montserrat", size: 14))) {
                HStack {
                    Text(card.cardNetwork.displayName)
                        .font(.custom("Montserrat", size: 16))
                    Spacer()
                    Text("Cannot be changed")
                        .font(.custom("Montserrat", size: 12))
                        .foregroundColor(.gray)
                }
            }
            
            Section(header: Text("Card Details").font(.custom("Montserrat", size: 14))) {
                TextField("Card Name", text: $cardName)
                    .font(.custom("Montserrat", size: 16))
                
                TextField("Issuer", text: $cardIssuer)
                    .font(.custom("Montserrat", size: 16))
                
                TextField("Type", text: $cardType)
                    .font(.custom("Montserrat", size: 16))
            }
            
            Section {
                Button(action: {
                    Task {
                        await updateCard()
                    }
                }) {
                    if isSubmitting {
                        HStack {
                            Spacer()
                            ProgressView()
                            Text("Updating...")
                                .font(.custom("Montserrat", size: 16))
                            Spacer()
                        }
                    } else {
                        Text("Update Card")
                            .font(.custom("Montserrat", size: 16))
                            .frame(maxWidth: .infinity)
                    }
                }
                .disabled(isSubmitting)
                
                Button("Cancel") {
                    isPresented = false
                }
                .font(.custom("Montserrat", size: 16))
                .tint(.red)
            }
        }
        .navigationTitle("Edit Card")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func updateCard() async {
        isSubmitting = true
        
        let success = await app.updateCard(
            card,
            type: cardType.isEmpty ? nil : cardType,
            issuer: cardIssuer.isEmpty ? nil : cardIssuer,
            name: cardName.isEmpty ? nil : cardName
        )
        
        isSubmitting = false
        
        if success {
            isPresented = false
        }
    }
}

#Preview {
    WalletView().environmentObject(AppState())
}
