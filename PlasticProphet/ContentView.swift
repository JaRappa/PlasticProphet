//
//  ContentView.swift
//  PlasticProphet
//
//  Created by Jake on 10/6/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var app: AppState
    
    var body: some View {
        Group {
            if !app.isAuthenticated {
                // Show authentication screens
                AuthLandingView()
            } else if !app.onboardingCompleted {
                // User is authenticated but hasn't completed onboarding
                OnboardingFlowView()
            } else {
                // User is authenticated and onboarded - show main app
                MainAppView()
            }
        }
        .animation(.easeInOut, value: app.isAuthenticated)
        .animation(.easeInOut, value: app.onboardingCompleted)
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
}
