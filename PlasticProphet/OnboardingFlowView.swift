// OnboardingFlowView.swift
// Enhanced multi-step onboarding flow

import SwiftUI
import CoreLocation

struct OnboardingFlowView: View {
    enum Step { case intro, tos, permissions, addCards, done }
    @EnvironmentObject var app: AppState
    @State private var step: Step = .intro
    @State private var locationStatus: CLAuthorizationStatus = .notDetermined
    @State private var locationCheckTimer: Timer?

    var body: some View {
        VStack(spacing: 24) {
            switch step {
            case .intro: IntroStepView(step: $step)
            case .tos: TOSStepView(step: $step).environmentObject(app)
            case .permissions: permissionsStepContent
            case .addCards: AddCardsStepView(step: $step).environmentObject(app)
            case .done: DoneStepView().environmentObject(app)
            }
            if step != .done { Spacer(minLength: 0) }
        }
        .padding()
        .animation(.default, value: step)
        .onChange(of: app.onboardingCompleted) { _, _ in
            if app.onboardingCompleted { step = .done }
        }
        .onChange(of: app.locationService.authorizationStatus) { _, newStatus in
            locationStatus = newStatus
            app.markPermissions(location: newStatus == .authorizedAlways)
            if newStatus == .authorizedAlways { stopLocationStatusPolling() }
        }
        .onAppear {
            locationStatus = app.locationService.authorizationStatus
            app.markPermissions(location: locationStatus == .authorizedAlways)
        }
        .onDisappear { stopLocationStatusPolling() }
    }
    
    // MARK: - Permissions Step
    private var permissionsStepContent: some View {
        VStack(spacing: 0) {
            permissionsHeader
            VStack(spacing: 20) {
                cameraSection
                locationSection
            }.padding(.horizontal).padding(.top, 24)
            Spacer()
            continueButton
        }
        .padding(.vertical)
        .onAppear {
            locationStatus = app.locationService.authorizationStatus
            app.markPermissions(location: locationStatus == .authorizedAlways)
        }
    }
    
    private var permissionsHeader: some View {
        VStack(spacing: 12) {
            Text("Permissions")
                .font(.custom("Montserrat", size: 28)).fontWeight(.bold)
                .foregroundColor(.black).tracking(-1.5)
            Text("To provide you with the best experience, PlasticProphet needs access to your camera and location.")
                .font(.custom("Montserrat", size: 15)).foregroundColor(.secondary)
                .multilineTextAlignment(.center).padding(.horizontal)
        }.padding(.top, 20)
    }
    
    private var cameraSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "camera.fill").foregroundColor(Color(hex: "2ac33c")).font(.title2)
                Text("Camera Access").font(.custom("Montserrat", size: 18)).fontWeight(.semibold).foregroundColor(.black)
                Spacer()
            }
            Text("Scan your credit cards quickly for instant card entry and recognition.")
                .font(.custom("Montserrat", size: 14)).foregroundColor(.secondary)
            Toggle("Camera Authorized", isOn: Binding(
                get: { app.permissions.cameraAuthorized },
                set: { newValue in app.markPermissions(camera: newValue) }
            )).font(.custom("Montserrat", size: 18)).fontWeight(.medium).tint(Color(hex: "2ac33c"))
        }.padding().background(Color.gray.opacity(0.05)).cornerRadius(12)
    }
    
    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "location.fill").foregroundColor(Color(hex: "2ac33c")).font(.title2)
                Text("Location Access").font(.custom("Montserrat", size: 18)).fontWeight(.semibold).foregroundColor(.black)
                Spacer()
            }
            Text("Receive personalized recommendations based on nearby merchants and locations.")
                .font(.custom("Montserrat", size: 14)).foregroundColor(.secondary)
            locationStatusRow
            locationInstructions
            locationButton
        }.padding().background(Color.gray.opacity(0.05)).cornerRadius(12)
    }
    
    private var locationStatusRow: some View {
        HStack(spacing: 8) {
            statusIcon
            Text(statusText).font(.custom("Montserrat", size: 16)).foregroundColor(.primary)
        }
    }
    
    @ViewBuilder
    private var statusIcon: some View {
        switch locationStatus {
        case .authorizedAlways:
            Image(systemName: "checkmark.circle.fill").foregroundColor(Color(hex: "2ac33c"))
        case .authorizedWhenInUse:
            Image(systemName: "exclamationmark.circle.fill").foregroundColor(.orange)
        default:
            Image(systemName: "xmark.circle.fill").foregroundColor(.red)
        }
    }
    
    private var statusText: String {
        switch locationStatus {
        case .notDetermined: return "Location: Not Determined"
        case .restricted: return "Location: Restricted"
        case .denied: return "Location: Denied"
        case .authorizedWhenInUse: return "Location: While Using App"
        case .authorizedAlways: return "Location: Always Allow ✓"
        @unknown default: return "Location: Unknown"
        }
    }
    
    @ViewBuilder
    private var locationInstructions: some View {
        if locationStatus == .authorizedWhenInUse {
            Text("You selected 'While Using'. Tap below to request 'Always Allow' for background notifications when you arrive at merchants.")
                .font(.custom("Montserrat", size: 12)).foregroundColor(.orange)
        } else if locationStatus == .notDetermined {
            Text("When prompted, please select 'Allow While Using App' first. Then tap the button again to upgrade to 'Always Allow'.")
                .font(.custom("Montserrat", size: 12)).foregroundColor(.secondary)
        }
    }
    
    private var locationButton: some View {
        Button {
            app.locationService.requestAlwaysAuthorization()
            startLocationStatusPolling()
        } label: {
            Text(locationButtonText)
                .font(.custom("Montserrat", size: 16)).fontWeight(.semibold)
                .foregroundColor(.white).frame(maxWidth: .infinity).padding(12)
                .background(RoundedRectangle(cornerRadius: 10)
                    .fill(locationStatus == .authorizedAlways ? Color.gray.opacity(0.5) : Color(hex: "2ac33c")))
        }.disabled(locationStatus == .authorizedAlways)
    }
    
    private var locationButtonText: String {
        switch locationStatus {
        case .authorizedAlways: return "Always Allow Enabled ✓"
        case .authorizedWhenInUse: return "Upgrade to Always Allow"
        default: return "Enable Location"
        }
    }
    
    private var continueButton: some View {
        let canContinue = app.permissions.cameraAuthorized && locationStatus == .authorizedAlways
        return Button(action: { step = .addCards }) {
            Text("Continue")
                .font(.custom("Montserrat", size: 20)).fontWeight(.black)
                .foregroundColor(.white).frame(maxWidth: .infinity).padding(16)
                .background(RoundedRectangle(cornerRadius: 12)
                    .fill(canContinue ? Color(hex: "2ac33c") : Color.ppGreen.opacity(0.4)))
                .shadow(color: Color(hex: "0a3a0e").opacity(0.3), radius: 4, x: 0, y: 2)
        }.disabled(!canContinue).padding(.horizontal).padding(.bottom, 20)
    }
    
    private func startLocationStatusPolling() {
        stopLocationStatusPolling()
        locationCheckTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { [weak app] _ in
            Task { @MainActor in
                guard let app = app else { return }
                let newStatus = app.locationService.authorizationStatus
                if newStatus != locationStatus { locationStatus = newStatus }
            }
        }
    }
    
    private func stopLocationStatusPolling() {
        locationCheckTimer?.invalidate()
        locationCheckTimer = nil
    }
}

// MARK: - Intro Step
struct IntroStepView: View {
    @Binding var step: OnboardingFlowView.Step
    var body: some View {
        ZStack {
            Color.white
            VStack(spacing: 40) {
                VStack(spacing: 12) {
                    Text("Welcome to")
                        .font(.custom("Montserrat", size: 38)).fontWeight(.black)
                        .foregroundColor(.black).multilineTextAlignment(.center).tracking(-1.5)
                        .shadow(color: Color(red: 0.04, green: 0.23, blue: 0.05).opacity(0.25), radius: 2, x: 0, y: 4)
                        .minimumScaleFactor(0.5).lineLimit(1)
                    Image("App Logo Black").resizable().scaledToFit().frame(width: 280, height: 280)
                }
                Button(action: { withAnimation { step = .tos } }) {
                    Text("Let's Get Started!")
                        .font(.custom("Montserrat", size: 22)).fontWeight(.heavy).foregroundColor(.white)
                        .padding(16).frame(maxWidth: .infinity)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.ppGreen.opacity(0.75))
                            .shadow(color: Color(red: 0.04, green: 0.23, blue: 0.05).opacity(0.15), radius: 8, x: 0, y: 4))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(red: 0.16, green: 0.76, blue: 0.24), lineWidth: 2))
                        .shadow(color: Color(red: 0.04, green: 0.23, blue: 0.05).opacity(0.3), radius: 4, x: 0, y: 2)
                }.padding(.horizontal, 24)
            }.padding(16).frame(maxWidth: 340)
        }.frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - TOS Step
struct TOSStepView: View {
    @Binding var step: OnboardingFlowView.Step
    @EnvironmentObject var app: AppState
    var body: some View {
        VStack(spacing: 0) {
            Text("Terms of Service")
                .font(.custom("Montserrat", size: 28)).fontWeight(.bold)
                .foregroundColor(.black).tracking(-1.5)
                .padding(.top, 20).padding(.bottom, 16)
            tosScrollView
            Spacer()
            tosFooter
        }.padding(.vertical)
    }
    
    private var tosScrollView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Terms and Conditions").font(.custom("Montserrat", size: 18)).fontWeight(.semibold).foregroundColor(.black)
                Text("By using PlasticProphet you agree to our terms and conditions. This is a placeholder Terms of Service.")
                    .font(.custom("Montserrat", size: 14)).foregroundColor(.secondary)
                Text("1. Acceptance of Terms").font(.custom("Montserrat", size: 16)).fontWeight(.semibold).foregroundColor(.black).padding(.top, 8)
                Text("Lorem ipsum dolor sit amet, consectetur adipiscing elit.").font(.custom("Montserrat", size: 14)).foregroundColor(.secondary)
                Text("2. User Responsibilities").font(.custom("Montserrat", size: 16)).fontWeight(.semibold).foregroundColor(.black).padding(.top, 8)
                Text("Duis aute irure dolor in reprehenderit in voluptate velit.").font(.custom("Montserrat", size: 14)).foregroundColor(.secondary)
                Text("3. Privacy Policy").font(.custom("Montserrat", size: 16)).fontWeight(.semibold).foregroundColor(.black).padding(.top, 8)
                Text("Sed ut perspiciatis unde omnis iste natus error sit voluptatem.").font(.custom("Montserrat", size: 14)).foregroundColor(.secondary)
            }.padding()
        }.background(Color.gray.opacity(0.05)).cornerRadius(12).padding(.horizontal)
    }
    
    private var tosFooter: some View {
        VStack(spacing: 16) {
            Toggle("I accept Terms of Service", isOn: $app.acceptedTos)
                .font(.custom("Montserrat", size: 20)).fontWeight(.medium)
                .tint(Color(hex: "2ac33c")).padding(.horizontal)
            Button(action: { step = .permissions }) {
                Text("Continue")
                    .font(.custom("Montserrat", size: 20)).fontWeight(.black)
                    .foregroundColor(.white).frame(maxWidth: .infinity).padding(16)
                    .background(RoundedRectangle(cornerRadius: 12)
                        .fill(app.acceptedTos ? Color(hex: "2ac33c") : Color.ppGreen.opacity(0.4)))
                    .shadow(color: Color(hex: "0a3a0e").opacity(0.3), radius: 4, x: 0, y: 2)
            }.disabled(!app.acceptedTos).padding(.horizontal).padding(.bottom, 20)
        }
    }
}

// MARK: - Add Cards Step
struct AddCardsStepView: View {
    @Binding var step: OnboardingFlowView.Step
    @State private var showAddCard: Bool = false
    @EnvironmentObject var app: AppState
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Add Your Cards").font(.custom("Montserrat", size: 28)).fontWeight(.bold).foregroundColor(.black).tracking(-1.5)
            Text("Search to add your credit cards.")
                .font(.custom("Montserrat", size: 14)).foregroundColor(.secondary)
                .multilineTextAlignment(.center).padding(.horizontal)
            
            // Show current cards or empty state
            if app.cards.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "creditcard")
                        .font(.system(size: 60))
                        .foregroundColor(.gray.opacity(0.4))
                    Text("No cards added yet")
                        .font(.custom("Montserrat", size: 16))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.vertical, 40)
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(app.cards) { card in
                            HStack(spacing: 12) {
                                // Card image
                                if let cardKey = card.cardKey,
                                   let imageName = CardImageHelper.imageNameForCardKey(cardKey),
                                   let uiImage = UIImage(named: imageName) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 44, height: 44)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                } else {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.ppGreen.opacity(0.15))
                                            .frame(width: 44, height: 44)
                                        Image(systemName: "creditcard.fill")
                                            .font(.system(size: 18))
                                            .foregroundColor(.ppGreen)
                                    }
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(card.name)
                                        .font(.custom("Montserrat", size: 16))
                                        .fontWeight(.semibold)
                                    Text(card.rewardSummary)
                                        .font(.custom("Montserrat", size: 12))
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Button {
                                    app.removeCard(card)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.red.opacity(0.7))
                                }
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(10)
                            .shadow(radius: 1)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            
            // Add card button
            Button(action: { showAddCard = true }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Card")
                }
                .font(.custom("Montserrat", size: 18)).fontWeight(.semibold)
                .foregroundColor(.white).padding(14).frame(maxWidth: .infinity)
                .background(Color.ppGreen).cornerRadius(12)
            }.padding(.horizontal)
            
            actionButtons
        }
        .padding()
        .sheet(isPresented: $showAddCard) {
            AddCardView()
                .environmentObject(app)
        }
    }
    
    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button(action: { app.onboardingCompleted = true; step = .done }) {
                Text("Skip for now")
                    .font(.custom("Montserrat", size: 20)).fontWeight(.bold).foregroundColor(.gray)
                    .frame(maxWidth: .infinity).padding(.vertical, 16)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.gray.opacity(0.1)))
            }
            Button(action: { app.proceedIfReady(); step = .done }) {
                Text("Finish")
                    .font(.custom("Montserrat", size: 20)).fontWeight(.black).foregroundColor(.white)
                    .frame(maxWidth: .infinity).padding(.vertical, 16)
                    .background(RoundedRectangle(cornerRadius: 12)
                        .fill(app.cards.isEmpty ? Color.ppGreen.opacity(0.3) : Color(hex: "2ac33c")))
                    .shadow(color: Color(hex: "0a3a0e").opacity(0.3), radius: 4, x: 0, y: 2)
            }.disabled(app.cards.isEmpty)
        }.padding(.horizontal)
    }
}

// MARK: - Done Step
struct DoneStepView: View {
    @EnvironmentObject var app: AppState
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(spacing: 24) {
                Image("App Logo Black").resizable().scaledToFit().frame(width: 300, height: 300)
                HStack(spacing: 8) {
                    Text("All Set!").font(.custom("Montserrat", size: 32)).fontWeight(.bold).foregroundColor(.black).tracking(-1.5)
                    Image(systemName: "checkmark.seal.fill").font(.title).foregroundStyle(Color(hex: "2ac33c"))
                }
                Text("You can start receiving recommendations.").font(.custom("Montserrat", size: 16)).foregroundColor(.secondary)
                Button(action: { app.onboardingCompleted = true; app.selectedTab = 0 }) {
                    Text("Enter App")
                        .font(.custom("Montserrat", size: 20)).fontWeight(.black)
                        .foregroundColor(.white).frame(maxWidth: .infinity).padding(16)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color(hex: "2ac33c")))
                        .shadow(color: Color(hex: "0a3a0e").opacity(0.3), radius: 4, x: 0, y: 2)
                }.padding(.horizontal, 24).padding(.top, 8)
            }
            Spacer()
        }
    }
}

#Preview {
    OnboardingFlowView().environmentObject(AppState())
}
