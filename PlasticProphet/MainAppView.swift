// MainAppView.swift
// Tab shell for post-onboarding experience

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
                    Label("Cards", systemImage: "creditcard.fill")
                }
                .tag(1)
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(2)
        }
        .accentColor(Color.ppGreen)
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
                    .font(.custom("Montserrat", size: 16))
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(app.cards.isEmpty ? Color.gray : Color.ppGreen)
                    )
                    .disabled(app.cards.isEmpty)
                    
                    if app.cards.isEmpty {
                        Text("Add at least one card to get recommendations.")
                            .font(.custom("Montserrat", size: 12))
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
            Button { app.showingScanner = true } label: {
                Image(systemName: "camera.viewfinder")
                    .foregroundColor(Color.ppGreen)
            }
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
                    .foregroundStyle(Color.ppGreen)
                Text(rec.card.name)
                    .font(.custom("Montserrat", size: 18))
                    .fontWeight(.bold)
            }
            Text("Merchant: \(rec.merchantName)")
                .font(.custom("Montserrat", size: 16))
                .fontWeight(.medium)
            Text(rec.rewardText)
                .font(.custom("Montserrat", size: 16))
                .fontWeight(.bold)
                .foregroundColor(Color.ppGreen)
            Text(rec.rationale)
                .font(.custom("Montserrat", size: 14))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .shadow(radius: 2, y: 1)
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
                    .font(.custom("Montserrat", size: 20))
                    .fontWeight(.bold)
                TextField("Enter 6 BIN digits", text: $scannedDigits)
                    .font(.custom("Montserrat", size: 16))
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 240)
                Button("Suggest Card Types") {
                    if !scannedDigits.isEmpty {
                        app.addMockCard(network: "BIN" + String(scannedDigits.prefix(2)))
                    }
                    dismiss()
                }
                .font(.custom("Montserrat", size: 16))
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding()
                .background(Color.ppGreen)
                .cornerRadius(10)
                
                Button("Cancel", role: .cancel) { dismiss() }
                    .font(.custom("Montserrat", size: 16))
            }
            .padding()
            .navigationTitle("Scan")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .font(.custom("Montserrat", size: 16))
                }
            }
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject var app: AppState
    @State private var notificationsEnabled = true
    @State private var showingSignOutAlert = false
    
    var body: some View {
        NavigationStack {
            Form {
                // User Info Section
                Section {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(Color.ppGreen)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(app.userFirstName) \(app.userLastName)")
                                .font(.custom("Montserrat", size: 18))
                                .fontWeight(.bold)
                            Text(app.userEmail)
                                .font(.custom("Montserrat", size: 14))
                                .foregroundColor(.secondary)
                        }
                        .padding(.leading, 8)
                    }
                    .padding(.vertical, 8)
                }
                
                Section("Permissions") {
                    HStack {
                        Label {
                            Text(app.permissions.cameraAuthorized ? "Camera Granted" : "Camera Missing")
                                .font(.custom("Montserrat", size: 16))
                        } icon: {
                            Image(systemName: app.permissions.cameraAuthorized ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundStyle(app.permissions.cameraAuthorized ? .green : .red)
                        }
                    }
                    
                    HStack {
                        Label {
                            Text(app.permissions.locationAuthorized ? "Location Granted" : "Location Missing")
                                .font(.custom("Montserrat", size: 16))
                        } icon: {
                            Image(systemName: app.permissions.locationAuthorized ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundStyle(app.permissions.locationAuthorized ? .green : .red)
                        }
                    }
                }
                
                Section("Notifications") {
                    Toggle("Local Notifications", isOn: $notificationsEnabled)
                        .font(.custom("Montserrat", size: 16))
                        .tint(Color.ppGreen)
                }
                
                Section("Account") {
                    Button(action: { showingSignOutAlert = true }) {
                        HStack {
                            Image(systemName: "arrow.right.square")
                            Text("Sign Out")
                                .font(.custom("Montserrat", size: 16))
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(Color.ppGreen)
                    }
                    
                    Button("Delete Account") {
                        // TODO: Implement account deletion
                    }
                    .font(.custom("Montserrat", size: 16))
                    .foregroundColor(.red)
                }
                
                Section("Debug") {
                    Button("Reset Onboarding") {
                        app.onboardingCompleted = false
                        app.acceptedTos = false
                        app.cards.removeAll()
                        app.latestRecommendation = nil
                    }
                    .font(.custom("Montserrat", size: 16))
                    .foregroundColor(.orange)
                }
            }
            .navigationTitle("Settings")
        }
        .alert("Sign Out", isPresented: $showingSignOutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Sign Out", role: .destructive) {
                app.signOut()
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
    }
}

#Preview {
    MainAppView().environmentObject(AppState())
}
