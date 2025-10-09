// MainAppView.swift
// Tab shell for post-onboarding experience

import SwiftUI

struct MainAppView: View {
    @EnvironmentObject var app: AppState

    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Home", systemImage: "house") }
            CardsView()
                .tabItem { Label("Cards", systemImage: "creditcard") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gear") }
        }
        .sheet(isPresented: $app.showingScanner) { ScannerView() }
    }
}

struct HomeView: View {
    @EnvironmentObject var app: AppState
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if let rec = app.latestRecommendation {
                        RecommendationCard(rec: rec)
                    } else {
                        ContentUnavailableView("No Recommendation", systemImage: "location.circle", description: Text("Trigger a geofence or tap refresh to simulate."))
                    }
                    Button("Simulate Geofence Recommendation") {
                        app.fetchRecommendation(for: "Coffee Shop")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(app.cards.isEmpty)
                    if app.cards.isEmpty {
                        Text("Add at least one card to get recommendations.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .padding(.top, 8)
                    }
                }
                .padding()
            }
            .navigationTitle("PlasticProphet")
            .toolbar { toolbarContent }
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button { app.showingScanner = true } label: { Image(systemName: "camera.viewfinder") }
                .disabled(app.cards.isEmpty)
                .help("Scan new merchant (placeholder)")
        }
    }
}

struct RecommendationCard: View {
    let rec: Recommendation
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "creditcard.fill")
                    .foregroundStyle(Color.accentColor)
                Text(rec.card.name).font(.headline)
            }
            Text("Merchant: \(rec.merchantName)").font(.subheadline)
            Text(rec.rewardText).font(.body).bold()
            Text(rec.rationale).font(.footnote).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .shadow(radius: 2, y: 1)
    }
}

struct CardsView: View {
    @EnvironmentObject var app: AppState
    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                if app.cards.isEmpty {
                    ContentUnavailableView("No Cards", systemImage: "creditcard.trianglebadge.exclamation", description: Text("Add a mock card to begin."))
                } else {
                    List(app.cards) { card in
                        VStack(alignment: .leading) {
                            Text(card.name).bold()
                            Text(card.rewardSummary).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
                HStack {
                    Button("Add VISA") { app.addMockCard(network: "VISA") }
                    Button("Add MC") { app.addMockCard(network: "MC") }
                    Button("Add Amex") { app.addMockCard(network: "Amex") }
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal)
            .navigationTitle("Cards")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { app.showingScanner = true } label: { Image(systemName: "camera") }
                        .disabled(app.cards.isEmpty)
                }
            }
        }
    }
}

struct ScannerView: View {
    @EnvironmentObject var app: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var scannedDigits: String = ""
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Scanner Placeholder")
                    .font(.title3)
                TextField("Enter 6 BIN digits", text: $scannedDigits)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 240)
                Button("Suggest Card Types") {
                    // For now just add a single mock suggestion
                    if !scannedDigits.isEmpty { app.addMockCard(network: "BIN" + String(scannedDigits.prefix(2))) }
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                Button("Cancel", role: .cancel) { dismiss() }
            }
            .padding()
            .navigationTitle("Scan")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } } }
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject var app: AppState
    @State private var notificationsEnabled = true
    var body: some View {
        NavigationStack {
            Form {
                Section("Permissions (Simulated)") {
                    Label(app.permissions.cameraAuthorized ? "Camera Granted" : "Camera Missing", systemImage: app.permissions.cameraAuthorized ? "checkmark.circle" : "xmark.circle")
                        .foregroundStyle(app.permissions.cameraAuthorized ? .green : .red)
                    Label(app.permissions.locationAuthorized ? "Location Granted" : "Location Missing", systemImage: app.permissions.locationAuthorized ? "checkmark.circle" : "xmark.circle")
                        .foregroundStyle(app.permissions.locationAuthorized ? .green : .red)
                }
                Section("Notifications") {
                    Toggle("Local Notifications", isOn: $notificationsEnabled)
                }
                Section("Account") {
                    Button("Delete Account") { /* placeholder */ }
                        .tint(.red)
                }
                Section("Debug") {
                    Button("Reset Onboarding") {
                        app.onboardingCompleted = false
                        app.acceptedTos = false
                        app.cards.removeAll()
                        app.latestRecommendation = nil
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    MainAppView().environmentObject(AppState())
}
