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
            if app.onboardingCompleted {
                MainAppView()
            } else {
                OnboardingFlowView()
            }
        }
        .animation(.easeInOut, value: app.onboardingCompleted)
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
}
