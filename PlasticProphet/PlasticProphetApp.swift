//
//  PlasticProphetApp.swift
//  PlasticProphet
//
//  Created by Jake on 10/6/25.
//

import SwiftUI

@main
struct PlasticProphetApp: App {
    @StateObject private var appState = AppState()
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
        }
    }
}
