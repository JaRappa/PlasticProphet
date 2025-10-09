// filepath: /Users/jakerappa/Documents/Pace/PlasticProphet/PlasticProphet/CardSelectionView.swift
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

private extension Color {
    // #2AC33C
    static let selectionGreen = Color(red: 0x2A/255.0, green: 0xC3/255.0, blue: 0x3C/255.0)
}

struct CardSelectionView: View {
    @EnvironmentObject var app: AppState
    @State private var query: String = ""

    private var filteredCatalog: [Card] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return popularCardCatalog }
        return popularCardCatalog.filter { c in
            c.name.lowercased().contains(q) || c.network.lowercased().contains(q)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                TextField("Search cards", text: $query)
                    .textFieldStyle(.roundedBorder)
                Button {
                    // Simulate scan adding a mock card
                    app.addMockCard(network: ["Visa","Mastercard","Amex"].randomElement()!)
                } label: {
                    Image(systemName: "camera")
                }
                .buttonStyle(.bordered)
                .accessibilityLabel("Scan card")
            }

            let columns = [GridItem(.adaptive(minimum: 150), spacing: 12)]
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(filteredCatalog) { card in
                    CardTile(card: card, isSelected: isSelected(card)) {
                        toggle(card)
                    }
                }
            }
        }
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

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(card.network)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Color.selectionGreen)
                    }
                }
                Text(card.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.leading)
                Text(card.rewardSummary)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isSelected ? Color.selectionGreen.opacity(0.12) : Color(.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isSelected ? Color.selectionGreen : Color.gray.opacity(0.2), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}

#Preview {
    CardSelectionView()
        .environmentObject(AppState())
        .padding()
}
