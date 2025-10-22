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
        // Register any fonts the developer placed in the app bundle under a `Fonts/` folder.
        // This allows using Font.custom("Montserrat", ...) without editing Info.plist.
        FontRegistration.registerFonts()
    }
    var body: some Scene {
        WindowGroup {
            MainAppView()
                .environmentObject(AppState())
        }
    }
}
