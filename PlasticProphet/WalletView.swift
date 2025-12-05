// WalletView.swift
// Shows user's cards and a FAB for add options when no cards exist

import SwiftUI

struct WalletView: View {
    @EnvironmentObject var app: AppState
    @State private var showFABMenu: Bool = false
    @State private var showManualEntry: Bool = false
    @State private var showCardSelection: Bool = false

    var body: some View {
        ZStack {
            // Adaptive Background
            Color.adaptiveSecondaryBackground
                .ignoresSafeArea()
            
            // 1. Main Content
            VStack(spacing: 0) {
                // Keep this Spacer to respect Safe Area Top for content
                Color.clear.frame(height: 1)
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Wallet")
                                .font(.custom("Montserrat", size: 32))
                                .fontWeight(.bold)
                                .foregroundColor(.adaptiveText)
                                .tracking(-1.5)
                            
                            Text("Your Cards")
                                .font(.custom("Montserrat", size: 20))
                                .fontWeight(.semibold)
                                .foregroundColor(.ppGreen)
                                .tracking(-0.5)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .padding(.top, 20)
                        
                        // Cards Section
                        if app.cards.isEmpty {
                            // Empty State Card
                            VStack(alignment: .leading, spacing: 12) {
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.adaptiveSecondaryText.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [6]))
                                    .frame(height: 120)
                                    .overlay(
                                        VStack(spacing: 8) {
                                            Image(systemName: "creditcard")
                                                .font(.system(size: 32))
                                                .foregroundColor(.adaptiveSecondaryText.opacity(0.5))
                                            
                                            Text("No cards added yet")
                                                .font(.custom("Montserrat", size: 16))
                                                .fontWeight(.medium)
                                                .foregroundColor(.adaptiveSecondaryText.opacity(0.8))
                                            
                                            Text("Tap the + button to add your first card")
                                                .font(.custom("Montserrat", size: 14))
                                                .foregroundColor(.adaptiveSecondaryText.opacity(0.6))
                                        }
                                    )
                            }
                            .padding()
                            .background(Color.adaptiveCardBackground)
                            .cornerRadius(12)
                            .shadow(color: Color.adaptiveShadow, radius: 8, x: 0, y: 2)
                            .padding(.horizontal)
                        } else {
                            // Cards List
                            VStack(spacing: 12) {
                                ForEach(app.cards) { card in
                                    HStack(spacing: 16) {
                                        // Card Network Icon
                                        ZStack {
                                            Circle()
                                                .fill(Color.ppGreen.opacity(0.1))
                                                .frame(width: 44, height: 44)
                                            
                                            Image(systemName: "creditcard")
                                                .font(.system(size: 20))
                                                .foregroundColor(.ppGreen)
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(card.name)
                                                .font(.custom("Montserrat", size: 16))
                                                .fontWeight(.semibold)
                                                .foregroundColor(.adaptiveText)
                                            
                                            Text(card.rewardSummary)
                                                .font(.custom("Montserrat", size: 14))
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Spacer()
                                        
                                        Text("••••\(card.last4)")
                                            .font(.custom("Montserrat", size: 14))
                                            .fontWeight(.medium)
                                            .foregroundColor(.adaptiveSecondaryText)
                                    }
                                    .padding()
                                    .background(Color.adaptiveCardBackground)
                                    .cornerRadius(12)
                                    .shadow(color: Color.adaptiveShadow, radius: 4, x: 0, y: 2)
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        Spacer(minLength: 100)
                    }
                }
            }
            
            // 2. Backdrop when menu is open
            if showFABMenu {
                Color.adaptiveText.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            showFABMenu = false
                        }
                    }
                    .transition(.opacity)
            }
            
            // 3. FAB Menu
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
        .sheet(isPresented: $showManualEntry) {
            NavigationStack {
                ManualAddView(showManual: $showManualEntry)
                    .environmentObject(app)
            }
        }
        .sheet(isPresented: $showCardSelection) {
            CardSelectionView()
                .environmentObject(app)
        }
    }
}

// MARK: - Helper Views

// Updated Manual Add View to use standard Form (which adapts automatically)
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
                    app.cards.append(card)
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

#Preview {
    WalletView().environmentObject(AppState())
}
