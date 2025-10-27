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
                    // show a simple list of cards
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(app.cards) { card in
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(card.name)
                                            .font(.custom("Montserrat", size: 16))
                                            .fontWeight(.semibold)
                                        Text(card.rewardSummary)
                                            .font(.custom("Montserrat", size: 12))
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Text("••••\(card.last4)")
                                        .font(.custom("Montserrat", size: 14))
                                        .fontWeight(.medium)
                                }
                                .padding()
                                .background(Color.white)
                                .cornerRadius(10)
                                .shadow(radius: 1)
                                .padding(.horizontal)
                            }
                        }
                        .padding(.top)
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
