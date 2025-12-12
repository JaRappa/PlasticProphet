//
//  ContentView.swift
//  PlasticProphet
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var app: AppState
    
    var body: some View {
        // Root navigation for the whole app
        NavigationStack {
            Group {
                if !app.isAuthenticated {
                    // Not signed in yet → auth landing
                    AuthLandingView()
                } else if !app.onboardingCompleted {
                    // Signed in but not onboarded → onboarding flow
                    OnboardingFlowView()
                } else {
                    // Signed in + onboarded → main tabbed app
                    MainAppView()
                }
            }
        }
        // Smooth transitions when auth/onboarding state flips
        .animation(.easeInOut, value: app.isAuthenticated)
        .animation(.easeInOut, value: app.onboardingCompleted)
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
}
