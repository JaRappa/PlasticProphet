// MainAppView.swift
// Tab shell for post-onboarding experience - Home, Wallet, Profile

import SwiftUI

struct MainAppView: View {
    @EnvironmentObject var app: AppState

    var body: some View {
        TabView(selection: $app.selectedTab) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)
            
            WalletView()
                .tabItem {
                    Label("Wallet", systemImage: "creditcard.fill")
                }
                .tag(1)
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(2)
        }
        .accentColor(Color.ppGreen)
        .sheet(isPresented: $app.showingScanner) { ScannerView() }
    }
}

struct HomeView: View {
    @EnvironmentObject var app: AppState
    @State private var showFABMenu = false
    @State private var showManualEntry = false
    @State private var showCardSelection = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Title
                        Text("Home")
                            .font(.custom("Montserrat", size: 32))
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                            .tracking(-1.5)
                            .padding(.horizontal)
                            .padding(.top, 8)
                        
                        Text("Best Deals Near You")
                            .font(.custom("Montserrat", size: 20))
                            .fontWeight(.semibold)
                            .foregroundColor(Color.ppGreen)
                            .padding(.horizontal)
                        
                        if let rec = app.latestRecommendation {
                            RecommendationCard(rec: rec)
                                .padding(.horizontal)
                        } else {
                            // Empty state
                            VStack(spacing: 16) {
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [6]))
                                    .frame(height: 160)
                                    .overlay(
                                        VStack(spacing: 8) {
                                            Image(systemName: "location.circle")
                                                .font(.system(size: 40))
                                                .foregroundColor(.ppGreen.opacity(0.5))
                                            Text("No recommendations yet")
                                                .font(.custom("Montserrat", size: 16))
                                                .fontWeight(.medium)
                                                .foregroundColor(.gray)
                                            Text("Add cards and enable location")
                                                .font(.custom("Montserrat", size: 12))
                                                .foregroundColor(.gray.opacity(0.7))
                                        }
                                    )
                                    .padding(.horizontal)
                            }
                        }
                        
                        Button("Simulate Geofence Recommendation") {
                            app.fetchRecommendation(for: "Coffee Shop")
                        }
                        .font(.custom("Montserrat", size: 16))
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(app.cards.isEmpty ? Color.ppGreen.opacity(0.3) : Color.ppGreen)
                        )
                        .disabled(app.cards.isEmpty)
                        .padding(.horizontal)
                        
                        if app.cards.isEmpty {
                            Text("Add at least one card to get recommendations.")
                                .font(.custom("Montserrat", size: 12))
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity)
                                .padding(.horizontal)
                        }
                        
                        // Extra padding for FAB
                        Color.clear.frame(height: 80)
                    }
                    .padding(.vertical)
                }
                .background(Color(.systemGroupedBackground))
                
                // Backdrop when menu is open - behind everything
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
                
                // FAB Menu - on top
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
                                    color: Color.ppGreen
                                ) {
                                    withAnimation { showFABMenu = false }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                        showCardSelection = true
                                    }
                                }
                                .transition(.scale.combined(with: .opacity))
                                
                                FABMenuItem(
                                    icon: "camera.fill",
                                    title: "Scan Card",
                                    color: Color.ppGreen
                                ) {
                                    withAnimation { showFABMenu = false }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                        app.showingScanner = true
                                    }
                                }
                                .transition(.scale.combined(with: .opacity))
                                
                                FABMenuItem(
                                    icon: "pencil",
                                    title: "Manual Entry",
                                    color: Color.ppGreen
                                ) {
                                    withAnimation { showFABMenu = false }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                        showManualEntry = true
                                    }
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
        }
        .sheet(isPresented: $showManualEntry) {
            HomeManualAddView(showManual: $showManualEntry)
                .environmentObject(app)
        }
        .sheet(isPresented: $showCardSelection) {
            CardSelectionView()
                .environmentObject(app)
        }
    }
}

// MARK: - FAB Menu Item
struct FABMenuItem: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text(title)
                    .font(.custom("Montserrat", size: 15))
                    .fontWeight(.semibold)
                    .foregroundColor(.ppGreen)
                
                ZStack {
                    Circle()
                        .fill(color)
                        .frame(width: 48, height: 48)
                        .shadow(color: Color.ppShadow.opacity(0.3), radius: 8, x: 0, y: 4)
                    
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 4)
            )
        }
    }
}

// MARK: - Home Manual Add View
struct HomeManualAddView: View {
    @EnvironmentObject var app: AppState
    @Binding var showManual: Bool
    @Environment(\.dismiss) private var dismiss
    @State private var cardNumber: String = ""
    @State private var network: String = ""
    @State private var rewards: String = ""

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Spacer()
                    Text("Add Card Manually")
                        .font(.custom("Montserrat", size: 18))
                        .fontWeight(.bold)
                    Spacer()
                }
                .padding()
                .background(Color.white)
                
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
                            let cardName = network.isEmpty ? "Manual Card ••••\(last4)" : "\(network) ••••\(last4)"
                            
                            // Determine card network from input
                            let cardNetwork: CardNetwork
                            let networkLower = network.lowercased()
                            if networkLower.contains("visa") {
                                cardNetwork = .visa
                            } else if networkLower.contains("master") {
                                cardNetwork = .mastercard
                            } else if networkLower.contains("amex") || networkLower.contains("american") {
                                cardNetwork = .amex
                            } else if networkLower.contains("discover") {
                                cardNetwork = .discover
                            } else {
                                cardNetwork = .other
                            }
                            
                            let card = Card(
                                id: Int.random(in: 10000...99999),
                                userId: 0,
                                cardType: "Manual",
                                cardNetwork: cardNetwork,
                                cardIssuer: network.isEmpty ? "Unknown" : network,
                                cardName: cardName,
                                addedAt: Date()
                            )
                            app.cards.append(card)
                            dismiss()
                        }
                        .font(.custom("Montserrat", size: 16))
                        .disabled(cardNumber.filter { $0.isNumber }.count < 4)
                    }
                }
                
                // Bottom buttons
                HStack(spacing: 16) {
                    Button("Close") {
                        dismiss()
                    }
                    .font(.custom("Montserrat", size: 16))
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 25)
                            .fill(Color.ppGreen)
                    )
                    
                    Button("Cancel") {
                        dismiss()
                    }
                    .font(.custom("Montserrat", size: 16))
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 25)
                            .fill(Color.red)
                    )
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
                .background(Color.white)
            }
        }
    }
}

struct RecommendationCard: View {
    let rec: Recommendation
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "creditcard.fill")
                    .foregroundStyle(Color.ppGreen)
                    .font(.system(size: 20))
                Text(rec.card.name)
                    .font(.custom("Montserrat", size: 18))
                    .fontWeight(.bold)
            }
            
            HStack {
                Image(systemName: "mappin.circle.fill")
                    .foregroundColor(.gray)
                Text("Merchant: \(rec.merchantName)")
                    .font(.custom("Montserrat", size: 16))
                    .fontWeight(.medium)
            }
            
            Text(rec.rewardText)
                .font(.custom("Montserrat", size: 16))
                .fontWeight(.bold)
                .foregroundColor(Color.ppGreen)
            
            Text(rec.rationale)
                .font(.custom("Montserrat", size: 14))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
    }
}

struct ScannerView: View {
    @EnvironmentObject var app: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var scannedDigits: String = ""
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            VStack(spacing: 24) {
                Spacer()
                
                Text("Scanner Placeholder")
                    .font(.custom("Montserrat", size: 24))
                    .fontWeight(.bold)
                
                TextField("Enter 6 BIN digits", text: $scannedDigits)
                    .font(.custom("Montserrat", size: 16))
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 240)
                    .padding()
                
                Spacer()
                
                // Bottom buttons
                HStack(spacing: 16) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .font(.custom("Montserrat", size: 16))
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 25)
                            .fill(Color.red)
                    )
                    
                    Button("Confirm") {
                        if !scannedDigits.isEmpty {
                            app.addMockCard(network: "BIN" + String(scannedDigits.prefix(2)))
                        }
                        dismiss()
                    }
                    .font(.custom("Montserrat", size: 16))
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 25)
                            .fill(Color.ppGreen)
                    )
                    .disabled(scannedDigits.isEmpty)
                    .opacity(scannedDigits.isEmpty ? 0.5 : 1.0)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
        }
    }
}

#Preview {
    MainAppView().environmentObject(AppState())
}
