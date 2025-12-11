//
//  PlasticProphetApp.swift
//  PlasticProphet
//

import SwiftUI

@main
struct PlasticProphetApp: App {
    // Single shared global app state
    @StateObject private var appState = AppState()

    init() {
        FontRegistration.registerFonts()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
        }
    }
}
