// CardSelectionView.swift
// Search + grid of popular cards with selectable tiles that highlight when selected

import SwiftUI

// Static catalog used for onboarding selection
private let popularCardCatalog: [Card] = [
    Card(name: "Chase Sapphire Preferred", network: "Visa", last4: "0000", rewardSummary: "2x Dining / 2x Travel"),
    Card(name: "Chase Freedom Flex", network: "Mastercard", last4: "0000", rewardSummary: "5% Rotating Categories"),
    Card(name: "Amex Gold", network: "Amex", last4: "0000", rewardSummary: "4x Dining / 4x Grocery"),
    Card(name: "Amex Platinum", network: "Amex", last4: "0000", rewardSummary: "5x Flights / 5x Hotels"),
    Card(name: "Citi Custom Cash", network: "Mastercard", last4: "0000", rewardSummary: "5% Top Category"),
    Card(name: "Citi Premier", network: "Mastercard", last4: "0000", rewardSummary: "3x Dining / 3x Gas / 3x Grocery"),
    Card(name: "Capital One SavorOne", network: "Mastercard", last4: "0000", rewardSummary: "3% Dining / 3% Grocery / 3% Entertainment"),
    Card(name: "Wells Fargo Active Cash", network: "Visa", last4: "0000", rewardSummary: "2% Everywhere"),
]

struct CardSelectionView: View {
    @EnvironmentObject var app: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var query: String = ""

    private var filteredCatalog: [Card] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return popularCardCatalog }
        return popularCardCatalog.filter { c in
            c.name.lowercased().contains(q) || c.network.lowercased().contains(q)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Custom header
            VStack(alignment: .leading, spacing: 8) {
                Text("Search Cards")
                    .font(.custom("Montserrat", size: 32))
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                    .tracking(-1.5)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 16)
            .background(Color.white)
            
            // Search and cards content
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 8) {
                        TextField("Search cards", text: $query)
                            .textFieldStyle(.roundedBorder)
                            .font(.custom("Montserrat", size: 16))
                        Button {
                            // Simulate scan adding a mock card
                            app.addMockCard(network: ["Visa","Mastercard","Amex"].randomElement()!)
                        } label: {
                            Image(systemName: "camera")
                                .font(.system(size: 18))
                                .foregroundColor(Color.ppGreen)
                        }
                        .buttonStyle(.bordered)
                        .tint(Color.ppGreen)
                        .accessibilityLabel("Scan card")
                    }
                    .padding(.horizontal, 20)
                    
                    let columns = [GridItem(.adaptive(minimum: 150), spacing: 12)]
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(filteredCatalog) { card in
                            CardTile(card: card, isSelected: isSelected(card)) {
                                toggle(card)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Extra padding for bottom button
                    Color.clear.frame(height: 100)
                }
                .padding(.vertical, 16)
            }
            .background(Color(.systemGroupedBackground))
            
            // Bottom Done button
            VStack(spacing: 0) {
                Divider()
                
                Button(action: {
                    dismiss()
                }) {
                    Text("Done")
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
                .padding(.vertical, 16)
            }
            .background(Color.white)
        }
        .background(Color(.systemGroupedBackground))
    }

    private func isSelected(_ card: Card) -> Bool {
        app.cards.contains(where: { $0.id == card.id })
    }

    private func toggle(_ card: Card) {
        if let idx = app.cards.firstIndex(where: { $0.id == card.id }) {
            app.cards.remove(at: idx)
        } else {
            app.cards.append(card)
        }
    }
}

private struct CardTile: View {
    let card: Card
    let isSelected: Bool
    let onTap: () -> Void
    
    private var networkColor: Color {
        switch card.network.lowercased() {
        case "visa":
            return Color.visaBlue
        case "mastercard":
            return Color.mastercardRed
        case "amex":
            return Color.amexBlue
        case "discover":
            return Color.discoverOrange
        default:
            return .secondary
        }
    }
    
    private var logoName: String {
        switch card.network.lowercased() {
        case "visa":
            return "Visa Logo"
        case "mastercard":
            return "MC Logo"
        case "amex":
            return "Amex Logo"
        case "discover":
            return "Discovery Logo"
        default:
            return ""
        }
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                // Checkmark in top right corner
                HStack {
                    Spacer()
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Color.ppGreen)
                            .font(.system(size: 20))
                    }
                }
                
                // Card name and rewards
                VStack(alignment: .leading, spacing: 4) {
                    Text(card.name)
                        .font(.custom("Montserrat", size: 15))
                        .fontWeight(.semibold)
                        .foregroundColor(.black)
                        .multilineTextAlignment(.leading)
                    Text(card.rewardSummary)
                        .font(.custom("Montserrat", size: 11))
                        .fontWeight(.regular)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // Network logo at bottom
                HStack {
                    if !logoName.isEmpty {
                        Image(logoName)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 24)
                            .frame(maxWidth: 50)
                        
                    }
                    Spacer()
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 140) // Fixed height for consistent layout
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.ppGreen.opacity(isSelected ? 0.4 : 0.2))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isSelected ? Color.ppGreen : Color.clear, lineWidth: isSelected ? 2.5 : 0)
            )
            .scaleEffect(isSelected ? 0.98 : 1.0)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(TapGesture().onEnded { })
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}

#Preview {
    CardSelectionView()
        .environmentObject(AppState())
}
