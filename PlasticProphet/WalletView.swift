// WalletView.swift
// Shows user's cards and a FAB for add options when no cards exist

import SwiftUI

struct WalletView: View {
    @EnvironmentObject var app: AppState
    @State private var fabOpen: Bool = false
    @State private var showManualEntry: Bool = false

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
                    .fontWeight(.medium)
                    .foregroundColor(Color(red: 0.16, green: 0.76, blue: 0.24))
                    .tracking(-0.5)

                if app.cards.isEmpty {
                    // empty state with dotted card and FAB
                    VStack(alignment: .leading, spacing: 8) {
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(red: 0.04, green: 0.23, blue: 0.05).opacity(0.30), style: StrokeStyle(lineWidth: 0.5, dash: [6]))
                            .frame(height: 100)
                            .overlay(
                                Text("Please Add Card...")
                                    .font(.custom("Montserrat", size: 14))
                                    .fontWeight(.medium)
                                    .foregroundColor(Color(red: 0.04, green: 0.23, blue: 0.05).opacity(0.50))
                                    .padding(.top, 12)
                                    .padding(.leading, 12), alignment: .topLeading
                            )
                    }
                    .padding(16)
                    .frame(height: 100)

                    Spacer()

                    // Floating area for FAB and options
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            ZStack {
                                if fabOpen {
                                    VStack(spacing: 12) {
                                        fabOption(icon: "magnifyingglass", title: "Search") {
                                            // TODO: hook up search
                                        }
                                        fabOption(icon: "camera", title: "Scan") {
                                            app.showingScanner = true
                                        }
                                        fabOption(icon: "pencil", title: "Manual Entry") {
                                            showManualEntry = true
                                        }
                                    }
                                    .transition(.move(edge: .trailing).combined(with: .opacity))
                                }

                                Button(action: { withAnimation { fabOpen.toggle() } }) {
                                    ZStack {
                                        Circle()
                                            .fill(Color(red: 0.16, green: 0.76, blue: 0.24).opacity(0.70))
                                            .frame(width: 56, height: 56)
                                            .shadow(color: Color(red: 0.04, green: 0.23, blue: 0.05).opacity(0.25), radius: 10, y: 6)
                                        Text("+")
                                            .font(.custom("Montserrat", size: 40))
                                            .fontWeight(.semibold)
                                            .foregroundColor(.white)
                                    }
                                }
                                .offset(x: 0, y: 0)
                            }
                            .padding()
                        }
                    }
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
            .sheet(isPresented: $showManualEntry) {
                NavigationStack {
                    ManualAddView(showManual: $showManualEntry)
                        .environmentObject(app)
                }
            }
        }
        .navigationBarHidden(true)
    }

    @ViewBuilder
    private func fabOption(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: { withAnimation { action(); fabOpen = false } }) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(.white)
                    .frame(width: 19, height: 19)
                Text(title)
                    .font(.custom("Montserrat", size: 16))
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            }
            .padding(EdgeInsets(top: 16, leading: 32, bottom: 16, trailing: 32))
            .background(Color(red: 0.16, green: 0.76, blue: 0.24))
            .cornerRadius(28)
            .shadow(color: Color(red: 0.04, green: 0.23, blue: 0.05).opacity(0.25), radius: 8, y: 4)
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
