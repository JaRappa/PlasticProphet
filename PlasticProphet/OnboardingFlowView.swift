// OnboardingFlowView.swift
// Basic multi-step onboarding flow stub

import SwiftUI

struct OnboardingFlowView: View {
    enum Step { case welcome, permissions, addCards, done }
    @EnvironmentObject var app: AppState
    @State private var step: Step = .welcome

    var body: some View {
        VStack(spacing: 24) {
            switch step {
            case .welcome:
                VStack(spacing: 12) {
                    Text("Welcome to PlasticProphet")
                        .font(.title)
                    Text("Smarter credit card recommendations based on where you are.")
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                    Toggle("I accept Terms of Service", isOn: $app.acceptedTos)
                    Button("Continue") { step = .permissions }
                        .disabled(!app.acceptedTos)
                        .buttonStyle(.borderedProminent)
                }
            case .permissions:
                VStack(spacing: 16) {
                    Text("Permissions")
                        .font(.title2)
                    Text("Allow camera (for quick card entry) and location (for geofence recommendations). These are simulated toggles right now.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    Toggle("Camera Authorized", isOn: Binding(
                        get: { app.permissions.cameraAuthorized },
                        set: { app.markPermissions(camera: $0) }
                    ))
                    Toggle("Location Authorized", isOn: Binding(
                        get: { app.permissions.locationAuthorized },
                        set: { app.markPermissions(location: $0) }
                    ))
                    Button("Continue") { step = .addCards }
                        .disabled(!app.permissions.allGranted)
                        .buttonStyle(.borderedProminent)
                }
            case .addCards:
                VStack(spacing: 16) {
                    Text("Add Your Cards")
                        .font(.title2)
                    Text("Search or scan to add your cards. Popular cards are shown below; tap a card tile to select it.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    // Card selection component with search + camera button + popular tiles
                    CardSelectionView()
                        .environmentObject(app)

                    Button("Finish") {
                        app.proceedIfReady()
                        step = .done
                    }
                    .disabled(app.cards.isEmpty)
                    .buttonStyle(.borderedProminent)
                }
            case .done:
                VStack(spacing: 16) {
                    if app.onboardingCompleted {
                        Image(systemName: "checkmark.seal.fill").font(.largeTitle).foregroundStyle(.green)
                        Text("All Set!").font(.title2)
                        Text("You can start receiving recommendations.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        Button("Enter App") { /* handled by parent view observing state */ }
                            .buttonStyle(.borderedProminent)
                    } else {
                        ProgressView("Finishing up…")
                            .task { app.proceedIfReady() }
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .padding()
        .animation(.default, value: step)
        .onChange(of: app.onboardingCompleted) { _, _ in
            if app.onboardingCompleted { step = .done }
        }
    }
}

#Preview {
    OnboardingFlowView()
        .environmentObject(AppState())
}
