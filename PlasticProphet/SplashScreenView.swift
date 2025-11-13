// SplashScreenView.swift
// Initial splash screen shown on app launch

import SwiftUI

struct SplashScreenView: View {
    @State private var isActive = false
    @State private var logoOpacity = 0.0
    @State private var logoScale = 0.8
    
    var body: some View {
        if isActive {
            ContentView()
        } else {
            ZStack {
                // Background color - white to match your design
                Color.adaptiveBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // Your green card logo
                    Image("Green Card")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 250, height: 250)
                        .opacity(logoOpacity)
                        .scaleEffect(logoScale)
                }
            }
            .onAppear {
                // Animate logo appearance
                withAnimation(.easeIn(duration: 0.8)) {
                    logoOpacity = 1.0
                    logoScale = 1.0
                }
                
                // Transition to main app after delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation(.easeOut(duration: 0.6)) {
                        isActive = true
                    }
                }
            }
        }
    }
}

#Preview {
    SplashScreenView()
        .environmentObject(AppState())
}
