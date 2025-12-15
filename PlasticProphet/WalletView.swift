// WalletView.swift
import SwiftUI

struct WalletView: View {
    @EnvironmentObject var app: AppState
    @State private var showAddCard: Bool = false
    @State private var showManualEntry: Bool = false
    @State private var selectedCardForDetail: Card? = nil

    var body: some View {
        ZStack {
            mainContent
            fabButton
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showAddCard) {
            AddCardView().environmentObject(app)
        }
        .sheet(isPresented: $showManualEntry) {
            NavigationStack {
                ManualAddView(showManual: $showManualEntry).environmentObject(app)
            }
        }
        .sheet(item: $selectedCardForDetail) { card in
            CardWalletDetailView(card: card) { app.removeCard(card) }
        }
    }
    
    private var mainContent: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Wallet").font(.custom("Montserrat", size: 32)).fontWeight(.bold).foregroundColor(.black).padding(.top, 20).tracking(-1.5)
            Text("Your Cards").font(.custom("Montserrat", size: 20)).fontWeight(.semibold).foregroundColor(.ppGreen).tracking(-0.5)
            
            if app.cards.isEmpty {
                emptyState
            } else {
                cardsList
            }
        }
        .padding(16)
    }
    
    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 8) {
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [6]))
                .frame(height: 100)
                .overlay(Text("Please Add Card...").font(.custom("Montserrat", size: 14)).fontWeight(.medium).foregroundColor(.gray.opacity(0.5)).padding(.top, 12).padding(.leading, 12), alignment: .topLeading)
            Spacer()
        }.padding(.horizontal, 16)
    }
    
    private var cardsList: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(app.cards) { card in
                    WalletCardRow(card: card) { selectedCardForDetail = card }
                }
            }.padding(.top)
        }
    }
    
    private var fabButton: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button(action: { showAddCard = true }) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(colors: [Color.ppGreen, Color.ppGreen.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing))
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
}

struct ManualAddView: View {
    @EnvironmentObject var app: AppState
    @Binding var showManual: Bool
    @State private var cardNumber = ""
    @State private var network = ""
    @State private var rewards = ""

    var body: some View {
        Form {
            Section(header: Text("Card Info")) {
                TextField("Card number", text: $cardNumber).keyboardType(.numberPad)
                TextField("Card type (e.g. Visa)", text: $network)
                TextField("Rewards summary", text: $rewards)
            }
            Section {
                Button("Add Card") {
                    let digits = cardNumber.filter { $0.isNumber }
                    guard digits.count >= 4 else { return }
                    let last4 = String(digits.suffix(4))
                    let name = network.isEmpty ? "Manual Card ••••\(last4)" : "\(network) ••••\(last4)"
                    app.addCard(Card(name: name, network: network.isEmpty ? "Unknown" : network, last4: last4, rewardSummary: rewards))
                    showManual = false
                }.disabled(cardNumber.filter { $0.isNumber }.count < 4)
                Button("Cancel") { showManual = false }.tint(.red)
            }
        }.navigationTitle("Add Card Manually").navigationBarTitleDisplayMode(.inline)
    }
}

struct WalletCardRow: View {
    let card: Card
    let onTap: () -> Void
    
    private var logoName: String? {
        let name = card.name.lowercased()
        let key = (card.cardKey ?? "").lowercased()
        if name.contains("chase") || key.contains("chase") { return "Chase" }
        if name.contains("amex") || name.contains("american express") || key.contains("amex") { return "Amex" }
        if name.contains("capital one") || key.contains("capitalone") { return "CapitalOne" }
        if name.contains("discover") || key.contains("discover") { return "Discover" }
        if name.contains("wells fargo") || key.contains("wellsfargo") { return "WellsFargo" }
        if name.contains("apple") || key.contains("apple") { return "Apple" }
        if name.contains("target") || key.contains("target") { return "Target" }
        return nil
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                if let logo = logoName {
                    Image(logo).resizable().scaledToFit().frame(width: 50, height: 50).clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8).fill(Color.ppGreen.opacity(0.15)).frame(width: 50, height: 50)
                        Image(systemName: "creditcard.fill").font(.system(size: 20)).foregroundColor(.ppGreen)
                    }
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(card.name).font(.custom("Montserrat", size: 16)).fontWeight(.semibold).lineLimit(1)
                    Text(card.rewardSummary).font(.custom("Montserrat", size: 12)).foregroundColor(.secondary).lineLimit(1)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 12, weight: .semibold)).foregroundColor(.gray)
            }
            .padding(14).background(Color(.systemBackground)).cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        }.buttonStyle(.plain).padding(.horizontal)
    }
}

struct CardWalletDetailView: View {
    let card: Card
    let onRemove: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    cardVisual
                    rewardsSection
                    Spacer(minLength: 100)
                }.padding(.top, 20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Card Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .navigationBarLeading) { Button("Done") { dismiss() }.foregroundColor(.ppGreen) } }
            .safeAreaInset(edge: .bottom) { removeButton }
        }
    }
    
    private var cardVisual: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(LinearGradient(colors: [Color.ppGreen, Color.ppGreen.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(height: 200)
            VStack(alignment: .leading, spacing: 16) {
                Text(card.network).font(.custom("Montserrat", size: 14)).foregroundColor(.white.opacity(0.8))
                Spacer()
                Text("•••• •••• •••• \(card.last4)").font(.custom("Montserrat", size: 20)).fontWeight(.semibold).foregroundColor(.white)
                Text(card.name).font(.custom("Montserrat", size: 16)).fontWeight(.bold).foregroundColor(.white)
            }.padding(24).frame(maxWidth: .infinity, alignment: .leading)
        }.padding(.horizontal, 20)
    }
    
    private var rewardsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Rewards Summary").font(.custom("Montserrat", size: 18)).fontWeight(.semibold)
            Text(card.rewardSummary).font(.custom("Montserrat", size: 15)).foregroundColor(.secondary)
        }.frame(maxWidth: .infinity, alignment: .leading).padding(16).background(Color(.systemBackground)).cornerRadius(12).padding(.horizontal, 20)
    }
    
    private var removeButton: some View {
        Button { onRemove(); dismiss() } label: {
            HStack { Image(systemName: "trash"); Text("Remove from Wallet") }
                .font(.custom("Montserrat", size: 16)).fontWeight(.semibold).foregroundColor(.white)
                .frame(maxWidth: .infinity).padding(16)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.red))
        }.padding(.horizontal, 20).padding(.vertical, 12).background(Color(.systemBackground))
    }
}

#Preview { WalletView().environmentObject(AppState()) }
