//
//  PlasticProphetApp.swift
//  PlasticProphet
//

import SwiftUI
import UserNotifications

@main
struct PlasticProphetApp: App {
    // Single shared global app state
    @StateObject private var appState = AppState()
    
    // App delegate for handling notifications
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    init() {
        FontRegistration.registerFonts()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .onAppear {
                    // Set up notification delegate
                    UNUserNotificationCenter.current().delegate = NotificationService.shared
                }
        }
    }
}

// MARK: - App Delegate for Background Tasks

class AppDelegate: NSObject, UIApplicationDelegate {
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Set up notification delegate early
        UNUserNotificationCenter.current().delegate = NotificationService.shared
        
        // Set up notification categories
        NotificationService.shared.setupNotificationCategories()
        
        // Check if launched from a location event
        if let _ = launchOptions?[.location] {
            print("📍 App launched from location event")
        }
        
        return true
    }
    
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("📱 Device token: \(token)")
    }
    
    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("❌ Failed to register for remote notifications: \(error)")
    }
}
