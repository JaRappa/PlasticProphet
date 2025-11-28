// SettingsView.swift
// App settings and preferences

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var app: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var notificationsEnabled = true
    
    var body: some View {
        Form {
            Section("Permissions") {
                HStack {
                    Label {
                        // FIX: Use new boolean properties
                        Text(app.isCameraAuthorized ? "Camera Granted" : "Camera Missing")
                            .font(.custom("Montserrat", size: 16))
                    } icon: {
                        Image(systemName: app.isCameraAuthorized ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(app.isCameraAuthorized ? .green : .red)
                    }
                }
                
                HStack {
                    Label {
                        // FIX: Use new boolean properties
                        Text(app.isLocationAuthorized ? "Location Granted" : "Location Missing")
                            .font(.custom("Montserrat", size: 16))
                    } icon: {
                        Image(systemName: app.isLocationAuthorized ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(app.isLocationAuthorized ? .green : .red)
                    }
                }
            }
            
            Section("Notifications") {
                Toggle("Local Notifications", isOn: $notificationsEnabled)
                    .font(.custom("Montserrat", size: 16))
                    .tint(Color.ppGreen)
            }
            
            Section("Account") {
                Button("Delete Account") {
                    // TODO: Implement account deletion
                }
                .font(.custom("Montserrat", size: 16))
                .foregroundColor(.red)
            }
            
            Section("Debug") {
                Button("Reset Onboarding") {
                    // This clears the persistent store so you can test onboarding again
                    if !app.userEmail.isEmpty {
                        UserDefaults.standard.removeObject(forKey: "onboarded_\(app.userEmail.lowercased())")
                    }
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
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    dismiss()
                }
                .font(.custom("Montserrat", size: 16))
                .foregroundColor(Color.ppGreen)
            }
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .environmentObject(AppState())
    }
}
