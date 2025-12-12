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
                            .foregroundStyle(app.permissions.locationAuthorized ? .green : .red) // ✅ fixed
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
