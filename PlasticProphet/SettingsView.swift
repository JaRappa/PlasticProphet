// SettingsView.swift
// App settings and preferences
import SwiftUI
import UserNotifications
import CoreLocation

struct SettingsView: View {
    @EnvironmentObject var app: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var notificationStatus: UNAuthorizationStatus = .notDetermined
    @State private var locationStatus: CLAuthorizationStatus = .notDetermined
    
    var body: some View {
        Form {
            Section("Permissions") {
                // Notifications Permission
                HStack {
                    Label {
                        Text(notificationStatus == .authorized ? "Notifications Enabled" : "Notifications Disabled")
                            .font(.custom("Montserrat", size: 16))
                    } icon: {
                        Image(systemName: notificationStatus == .authorized ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(notificationStatus == .authorized ? .green : .red)
                    }
                    
                    Spacer()
                    
                    if notificationStatus != .authorized {
                        Button("Enable") {
                            openAppSettings()
                        }
                        .font(.custom("Montserrat", size: 14))
                        .foregroundColor(.ppGreen)
                    }
                }
                
                // Location Permission
                HStack {
                    Label {
                        Text(locationStatusText)
                            .font(.custom("Montserrat", size: 16))
                    } icon: {
                        Image(systemName: locationStatus == .authorizedAlways ? "checkmark.circle.fill" : (locationStatus == .authorizedWhenInUse ? "exclamationmark.circle.fill" : "xmark.circle.fill"))
                            .foregroundStyle(locationStatus == .authorizedAlways ? .green : (locationStatus == .authorizedWhenInUse ? .orange : .red))
                    }
                    
                    Spacer()
                    
                    if locationStatus != .authorizedAlways {
                        Button("Settings") {
                            openAppSettings()
                        }
                        .font(.custom("Montserrat", size: 14))
                        .foregroundColor(.ppGreen)
                    }
                }
            }
            
            Section("Account") {
                Button("Delete Account") {
                    // TODO: Implement account deletion
                }
                .font(.custom("Montserrat", size: 16))
                .foregroundColor(.red)
            }
            
            Section("Debug") {
                Button("Send Test Notification") {
                    sendTestNotification()
                }
                .font(.custom("Montserrat", size: 16))
                .foregroundColor(.ppGreen)
                
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
        .onAppear {
            checkPermissions()
        }
    }
    
    private var locationStatusText: String {
        switch locationStatus {
        case .authorizedAlways: return "Location: Always"
        case .authorizedWhenInUse: return "Location: While Using"
        case .denied: return "Location Denied"
        case .restricted: return "Location Restricted"
        case .notDetermined: return "Location Not Set"
        @unknown default: return "Location Unknown"
        }
    }
    
    private func checkPermissions() {
        // Check notification status
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                notificationStatus = settings.authorizationStatus
            }
        }
        
        // Check location status
        locationStatus = app.locationService.authorizationStatus
    }
    
    private func openAppSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
    
    private func sendTestNotification() {
        let content = UNMutableNotificationContent()
        content.title = "💳 Card Recommendation"
        content.body = "Use your Chase Sapphire Preferred for 3x points at this restaurant!"
        content.sound = .default
        
        // Trigger immediately (1 second delay)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Failed to send test notification: \(error)")
            } else {
                print("✅ Test notification scheduled")
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
