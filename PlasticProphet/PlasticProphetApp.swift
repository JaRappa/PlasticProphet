//
//  PlasticProphetApp.swift
//  PlasticProphet
//
//  Created by Jake on 10/6/25.
//

import SwiftUI

@main
struct PlasticProphetApp: App {
    init() {
        FontRegistration.registerFonts()
    }
    var body: some Scene {
        WindowGroup {
            SplashScreenView()  // ✅ Changed from ContentView() to SplashScreenView()
                .environmentObject(AppState())
        }
    }
}
