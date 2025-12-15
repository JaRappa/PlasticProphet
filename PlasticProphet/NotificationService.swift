// NotificationService.swift
// Handles local push notifications for card recommendations when entering merchant locations

import Foundation
import UserNotifications
import UIKit

class NotificationService: NSObject, ObservableObject {
    
    static let shared = NotificationService()
    
    @Published var isAuthorized: Bool = false
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    
    private override init() {
        super.init()
        checkAuthorizationStatus()
    }
    
    // MARK: - Authorization
    
    /// Check current notification authorization status
    func checkAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.authorizationStatus = settings.authorizationStatus
                self?.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
    
    /// Request notification permissions
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .sound, .badge]
            )
            
            await MainActor.run {
                self.isAuthorized = granted
                self.authorizationStatus = granted ? .authorized : .denied
            }
            
            if granted {
                print("✅ Notification permission granted")
            } else {
                print("❌ Notification permission denied")
            }
            
            return granted
        } catch {
            print("❌ Error requesting notification permission: \(error)")
            return false
        }
    }
    
    // MARK: - Card Recommendation Notifications
    
    /// Send a local notification recommending a card for a merchant
    /// - Parameters:
    ///   - cardName: The recommended card name
    ///   - merchantName: The merchant/location name
    ///   - rewardRate: The reward rate (e.g., "4X")
    ///   - category: The spending category
    func sendCardRecommendationNotification(
        cardName: String,
        merchantName: String,
        rewardRate: String,
        category: String
    ) {
        guard isAuthorized else {
            print("⚠️ Cannot send notification - not authorized")
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = "💳 Best Card for \(merchantName)"
        content.body = "Use your \(cardName) for \(rewardRate) rewards on \(category)!"
        content.sound = .default
        content.categoryIdentifier = "CARD_RECOMMENDATION"
        
        // Add data for when user taps the notification
        content.userInfo = [
            "cardName": cardName,
            "merchantName": merchantName,
            "rewardRate": rewardRate,
            "category": category
        ]
        
        // Create a unique identifier for this notification
        let identifier = "card_recommendation_\(UUID().uuidString)"
        
        // Trigger immediately
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Error sending notification: \(error)")
            } else {
                print("✅ Card recommendation notification sent for \(merchantName)")
            }
        }
    }
    
    /// Send a simple geofence entry notification (fallback when card lookup fails)
    func sendGeofenceEntryNotification(merchantName: String, merchantType: String) {
        guard isAuthorized else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "📍 You're near \(merchantName)"
        content.body = "Open Plastic Prophet to see the best card to use!"
        content.sound = .default
        content.categoryIdentifier = "GEOFENCE_ENTRY"
        
        let identifier = "geofence_entry_\(UUID().uuidString)"
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Error sending geofence notification: \(error)")
            } else {
                print("✅ Geofence entry notification sent for \(merchantName)")
            }
        }
    }
    
    // MARK: - Notification Categories
    
    /// Set up notification categories and actions
    func setupNotificationCategories() {
        // Action to open the app and show the card
        let viewCardAction = UNNotificationAction(
            identifier: "VIEW_CARD",
            title: "View Card",
            options: [.foreground]
        )
        
        // Action to dismiss
        let dismissAction = UNNotificationAction(
            identifier: "DISMISS",
            title: "Dismiss",
            options: [.destructive]
        )
        
        // Category for card recommendations
        let cardRecommendationCategory = UNNotificationCategory(
            identifier: "CARD_RECOMMENDATION",
            actions: [viewCardAction, dismissAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        
        // Category for geofence entries
        let geofenceEntryCategory = UNNotificationCategory(
            identifier: "GEOFENCE_ENTRY",
            actions: [viewCardAction, dismissAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([
            cardRecommendationCategory,
            geofenceEntryCategory
        ])
    }
    
    // MARK: - Clear Notifications
    
    /// Remove all pending notifications
    func clearPendingNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    /// Remove all delivered notifications
    func clearDeliveredNotifications() {
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationService: UNUserNotificationCenterDelegate {
    
    /// Handle notification when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show the notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    /// Handle user interaction with notification
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        
        switch response.actionIdentifier {
        case "VIEW_CARD":
            // Handle view card action - could post a notification to navigate to wallet
            if let cardName = userInfo["cardName"] as? String {
                print("📱 User wants to view card: \(cardName)")
                NotificationCenter.default.post(
                    name: .didTapCardRecommendationNotification,
                    object: nil,
                    userInfo: userInfo
                )
            }
            
        case UNNotificationDefaultActionIdentifier:
            // User tapped the notification itself
            print("📱 User tapped notification")
            NotificationCenter.default.post(
                name: .didTapCardRecommendationNotification,
                object: nil,
                userInfo: userInfo
            )
            
        default:
            break
        }
        
        completionHandler()
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let didTapCardRecommendationNotification = Notification.Name("didTapCardRecommendationNotification")
}
