// OnboardingFlowView.swift
import SwiftUI
import CoreLocation
import UserNotifications

struct OnboardingFlowView: View {
    enum Step { case intro, tos, permissions, addCards, done }
    @EnvironmentObject var app: AppState
    @State private var step: Step = .intro
    @State private var locationStatus: CLAuthorizationStatus = .notDetermined
    @State private var notificationStatus: UNAuthorizationStatus = .notDetermined
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
        .onChange(of: app.locationService.authorizationStatus) { _, newStatus in
            locationStatus = newStatus
            if newStatus == .authorizedAlways { stopLocationStatusPolling() }
        }
        .onAppear {
            locationStatus = app.locationService.authorizationStatus
            checkNotificationStatus()
        }
        .onDisappear { stopLocationStatusPolling() }
    }
    
    private func checkNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async { notificationStatus = settings.authorizationStatus }
        }
    }
    
    private var permissionsStepContent: some View {
        VStack(spacing: 0) {
            VStack(spacing: 12) {
                Text("Permissions").font(.custom("Montserrat", size: 28)).fontWeight(.bold).foregroundColor(.black).tracking(-1.5)
                Text("To provide you with the best experience, PlasticProphet needs access to your location and notifications.")
                    .font(.custom("Montserrat", size: 15)).foregroundColor(.secondary).multilineTextAlignment(.center).padding(.horizontal)
            }.padding(.top, 20)
            
            ScrollView {
                VStack(spacing: 20) {
                    notificationSection
                    locationSection
                }.padding(.horizontal).padding(.top, 24)
            }
            Spacer()
            continueButton
        }
        .padding(.vertical)
        .onAppear { locationStatus = app.locationService.authorizationStatus; checkNotificationStatus() }
    }
    
    private var notificationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "bell.fill").foregroundColor(Color(hex: "2ac33c")).font(.title2)
                Text("Notification Access").font(.custom("Montserrat", size: 18)).fontWeight(.semibold).foregroundColor(.black)
                Spacer()
            }
            Text("Get notified which card to use when you arrive at stores, gas stations, and restaurants.")
                .font(.custom("Montserrat", size: 14)).foregroundColor(.secondary)
            HStack(spacing: 8) {
                if notificationStatus == .authorized {
                    Image(systemName: "checkmark.circle.fill").foregroundColor(Color(hex: "2ac33c"))
                    Text("Notifications: Enabled ✓").font(.custom("Montserrat", size: 16))
                } else {
                    Image(systemName: "bell.badge").foregroundColor(.orange)
                    Text("Notifications: Not Set").font(.custom("Montserrat", size: 16))
                }
            }
            Button {
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in
                    DispatchQueue.main.async { checkNotificationStatus() }
                }
            } label: {
                Text(notificationStatus == .authorized ? "Notifications Enabled ✓" : "Enable Notifications")
                    .font(.custom("Montserrat", size: 16)).fontWeight(.semibold).foregroundColor(.white)
                    .frame(maxWidth: .infinity).padding(12)
                    .background(RoundedRectangle(cornerRadius: 10).fill(notificationStatus == .authorized ? Color.gray.opacity(0.5) : Color(hex: "2ac33c")))
            }.disabled(notificationStatus == .authorized)
        }.padding().background(Color.gray.opacity(0.05)).cornerRadius(12)
    }
    
    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "location.fill").foregroundColor(Color(hex: "2ac33c")).font(.title2)
                Text("Location Access").font(.custom("Montserrat", size: 18)).fontWeight(.semibold).foregroundColor(.black)
                Spacer()
            }
            Text("Receive personalized recommendations based on nearby merchants.")
                .font(.custom("Montserrat", size: 14)).foregroundColor(.secondary)
            HStack(spacing: 8) {
                if locationStatus == .authorizedAlways {
                    Image(systemName: "checkmark.circle.fill").foregroundColor(Color(hex: "2ac33c"))
                    Text("Location: Always Allow ✓").font(.custom("Montserrat", size: 16))
                } else if locationStatus == .authorizedWhenInUse {
                    Image(systemName: "exclamationmark.circle.fill").foregroundColor(.orange)
                    Text("Location: While Using App").font(.custom("Montserrat", size: 16))
                } else {
                    Image(systemName: "xmark.circle.fill").foregroundColor(.red)
                    Text("Location: Not Set").font(.custom("Montserrat", size: 16))
                }
            }
            if locationStatus == .authorizedWhenInUse {
                Text("Tap below to request 'Always Allow' for background notifications.")
                    .font(.custom("Montserrat", size: 12)).foregroundColor(.orange)
            }
            Button {
                app.locationService.requestAlwaysAuthorization()
                startLocationStatusPolling()
            } label: {
                let text = locationStatus == .authorizedAlways ? "Always Allow Enabled ✓" : (locationStatus == .authorizedWhenInUse ? "Upgrade to Always Allow" : "Enable Location")
                Text(text).font(.custom("Montserrat", size: 16)).fontWeight(.semibold).foregroundColor(.white)
                    .frame(maxWidth: .infinity).padding(12)
                    .background(RoundedRectangle(cornerRadius: 10).fill(locationStatus == .authorizedAlways ? Color.gray.opacity(0.5) : Color(hex: "2ac33c")))
            }.disabled(locationStatus == .authorizedAlways)
        }.padding().background(Color.gray.opacity(0.05)).cornerRadius(12)
    }
    
    private var continueButton: some View {
        let canContinue = notificationStatus == .authorized && locationStatus == .authorizedAlways
        return Button(action: { step = .addCards }) {
            Text("Continue").font(.custom("Montserrat", size: 20)).fontWeight(.black).foregroundColor(.white)
                .frame(maxWidth: .infinity).padding(16)
                .background(RoundedRectangle(cornerRadius: 12).fill(canContinue ? Color(hex: "2ac33c") : Color.ppGreen.opacity(0.4)))
        }.disabled(!canContinue).padding(.horizontal).padding(.bottom, 20)
    }
    
    private func startLocationStatusPolling() {
        stopLocationStatusPolling()
        locationCheckTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { _ in
            Task { @MainActor in
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

struct IntroStepView: View {
    @Binding var step: OnboardingFlowView.Step
    var body: some View {
        ZStack {
            Color.white
            VStack(spacing: 40) {
                VStack(spacing: 12) {
                    Text("Welcome to").font(.custom("Montserrat", size: 38)).fontWeight(.black).foregroundColor(.black).tracking(-1.5)
                    Image("App Logo Black").resizable().scaledToFit().frame(width: 280, height: 280)
                }
                Button(action: { withAnimation { step = .tos } }) {
                    Text("Let's Get Started!").font(.custom("Montserrat", size: 22)).fontWeight(.heavy).foregroundColor(.white)
                        .padding(16).frame(maxWidth: .infinity)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.ppGreen.opacity(0.75)))
                }.padding(.horizontal, 24)
            }.padding(16).frame(maxWidth: 340)
        }.frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct TOSStepView: View {
    @Binding var step: OnboardingFlowView.Step
    @EnvironmentObject var app: AppState
    @State private var isOver18: Bool = false
    @State private var acceptedPrivacyPolicy: Bool = false
    
    private var canContinue: Bool {
        app.acceptedTos && isOver18 && acceptedPrivacyPolicy
    }
    
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
                Text("Last Updated: December 15, 2025")
                    .font(.custom("Montserrat", size: 12)).foregroundColor(.secondary).italic()
                
                Text("Please read these Terms of Service carefully before using PlasticProphet.")
                    .font(.custom("Montserrat", size: 14)).foregroundColor(.secondary)
                
                Group {
                    Text("1. Acceptance of Terms").font(.custom("Montserrat", size: 16)).fontWeight(.semibold).foregroundColor(.black).padding(.top, 8)
                    Text("By accessing or using PlasticProphet, you agree to be bound by these Terms of Service and all applicable laws and regulations. If you do not agree with any of these terms, you are prohibited from using this application.")
                        .font(.custom("Montserrat", size: 14)).foregroundColor(.secondary)
                    
                    Text("2. Description of Service").font(.custom("Montserrat", size: 16)).fontWeight(.semibold).foregroundColor(.black).padding(.top, 8)
                    Text("PlasticProphet provides credit card recommendation services based on your location and merchant category codes (MCC). The app suggests which credit card may offer the best rewards for purchases at nearby establishments. These recommendations are for informational purposes only and should not be considered financial advice.")
                        .font(.custom("Montserrat", size: 14)).foregroundColor(.secondary)
                    
                    Text("3. User Responsibilities").font(.custom("Montserrat", size: 16)).fontWeight(.semibold).foregroundColor(.black).padding(.top, 8)
                    Text("You are responsible for maintaining the confidentiality of your account information and for all activities that occur under your account. You agree to provide accurate, current, and complete information during registration.")
                        .font(.custom("Montserrat", size: 14)).foregroundColor(.secondary)
                }
                
                Group {
                    Text("4. Location Services").font(.custom("Montserrat", size: 16)).fontWeight(.semibold).foregroundColor(.black).padding(.top, 8)
                    Text("PlasticProphet uses location services to provide relevant recommendations. By enabling location services, you consent to the collection and use of your location data as described in our Privacy Policy.")
                        .font(.custom("Montserrat", size: 14)).foregroundColor(.secondary)
                    
                    Text("5. No Financial Advice").font(.custom("Montserrat", size: 16)).fontWeight(.semibold).foregroundColor(.black).padding(.top, 8)
                    Text("The information provided by PlasticProphet is for general informational purposes only. It is not intended to be financial, legal, or professional advice. Always consult with qualified professionals before making financial decisions.")
                        .font(.custom("Montserrat", size: 14)).foregroundColor(.secondary)
                    
                    Text("6. Limitation of Liability").font(.custom("Montserrat", size: 16)).fontWeight(.semibold).foregroundColor(.black).padding(.top, 8)
                    Text("In no event shall PlasticProphet be liable for any indirect, incidental, special, consequential, or punitive damages resulting from your use of the service.")
                        .font(.custom("Montserrat", size: 14)).foregroundColor(.secondary)
                    
                    Text("7. Contact Us").font(.custom("Montserrat", size: 16)).fontWeight(.semibold).foregroundColor(.black).padding(.top, 8)
                    Text("If you have any questions about these Terms, please contact us at support@plasticprophet.com.")
                        .font(.custom("Montserrat", size: 14)).foregroundColor(.secondary)
                }
            }.padding()
        }.background(Color.gray.opacity(0.05)).cornerRadius(12).padding(.horizontal)
    }
    
    private var tosFooter: some View {
        VStack(spacing: 12) {
            Toggle(isOn: $isOver18) {
                Text("I confirm that I am 18 years or older")
                    .font(.custom("Montserrat", size: 14)).fontWeight(.medium)
            }
            .tint(Color(hex: "2ac33c")).padding(.horizontal)
            
            HStack {
                Toggle(isOn: $acceptedPrivacyPolicy) {
                    HStack(spacing: 4) {
                        Text("I agree to the")
                            .font(.custom("Montserrat", size: 14)).fontWeight(.medium)
                        Link("Privacy Policy", destination: URL(string: "https://plasticprophet.com/privacy")!)
                            .font(.custom("Montserrat", size: 14)).fontWeight(.semibold)
                            .foregroundColor(Color(hex: "2ac33c"))
                    }
                }
                .tint(Color(hex: "2ac33c"))
            }
            .padding(.horizontal)
            
            Toggle("I accept the Terms of Service", isOn: $app.acceptedTos)
                .font(.custom("Montserrat", size: 14)).fontWeight(.medium)
                .tint(Color(hex: "2ac33c")).padding(.horizontal)
            
            Button(action: { step = .permissions }) {
                Text("Continue")
                    .font(.custom("Montserrat", size: 20)).fontWeight(.black)
                    .foregroundColor(.white).frame(maxWidth: .infinity).padding(16)
                    .background(RoundedRectangle(cornerRadius: 12)
                        .fill(canContinue ? Color(hex: "2ac33c") : Color.ppGreen.opacity(0.4)))
            }.disabled(!canContinue).padding(.horizontal).padding(.bottom, 20)
        }
    }
}

struct AddCardsStepView: View {
    @Binding var step: OnboardingFlowView.Step
    @EnvironmentObject var app: AppState
    @State private var showAddCard = false
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Add Your Cards").font(.custom("Montserrat", size: 28)).fontWeight(.bold).foregroundColor(.black).tracking(-1.5)
            Text("Add your credit cards to get personalized recommendations.").font(.custom("Montserrat", size: 14)).foregroundColor(.secondary).multilineTextAlignment(.center).padding(.horizontal)
            
            if !app.cards.isEmpty {
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(app.cards) { card in
                            HStack {
                                cardLogo(for: card)
                                Text(card.name).font(.custom("Montserrat", size: 14))
                                Spacer()
                                Image(systemName: "checkmark.circle.fill").foregroundColor(.ppGreen)
                            }.padding(12).background(Color.gray.opacity(0.05)).cornerRadius(8)
                        }
                    }.padding(.horizontal)
                }.frame(maxHeight: 200)
            }
            
            Button(action: { showAddCard = true }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text(app.cards.isEmpty ? "Add Your First Card" : "Add Another Card")
                }.font(.custom("Montserrat", size: 16)).fontWeight(.semibold).foregroundColor(.white)
                    .frame(maxWidth: .infinity).padding(14)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.ppGreen))
            }.padding(.horizontal)
            
            Spacer()
            
            HStack(spacing: 12) {
                Button(action: { app.onboardingCompleted = true; step = .done }) {
                    Text("Skip for now").font(.custom("Montserrat", size: 18)).fontWeight(.bold).foregroundColor(.gray)
                        .frame(maxWidth: .infinity).padding(.vertical, 16)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.gray.opacity(0.1)))
                }
                Button(action: { app.onboardingCompleted = true; step = .done }) {
                    Text("Continue").font(.custom("Montserrat", size: 18)).fontWeight(.black).foregroundColor(.white)
                        .frame(maxWidth: .infinity).padding(.vertical, 16)
                        .background(RoundedRectangle(cornerRadius: 12).fill(app.cards.isEmpty ? Color.ppGreen.opacity(0.4) : Color(hex: "2ac33c")))
                }.disabled(app.cards.isEmpty)
            }.padding(.horizontal).padding(.bottom, 20)
        }
        .sheet(isPresented: $showAddCard) { AddCardView().environmentObject(app) }
    }
    
    @ViewBuilder
    private func cardLogo(for card: Card) -> some View {
        let name = card.name.lowercased()
        let key = (card.cardKey ?? "").lowercased()
        if name.contains("chase") || key.contains("chase") {
            Image("Chase").resizable().scaledToFit().frame(width: 30, height: 30).clipShape(RoundedRectangle(cornerRadius: 4))
        } else if name.contains("amex") || name.contains("american express") || key.contains("amex") {
            Image("Amex").resizable().scaledToFit().frame(width: 30, height: 30).clipShape(RoundedRectangle(cornerRadius: 4))
        } else if name.contains("capital one") || key.contains("capitalone") {
            Image("CapitalOne").resizable().scaledToFit().frame(width: 30, height: 30).clipShape(RoundedRectangle(cornerRadius: 4))
        } else if name.contains("discover") || key.contains("discover") {
            Image("Discover").resizable().scaledToFit().frame(width: 30, height: 30).clipShape(RoundedRectangle(cornerRadius: 4))
        } else if name.contains("wells fargo") || key.contains("wellsfargo") {
            Image("WellsFargo").resizable().scaledToFit().frame(width: 30, height: 30).clipShape(RoundedRectangle(cornerRadius: 4))
        } else if name.contains("apple") || key.contains("apple") {
            Image("Apple").resizable().scaledToFit().frame(width: 30, height: 30).clipShape(RoundedRectangle(cornerRadius: 4))
        } else if name.contains("target") || key.contains("target") {
            Image("Target").resizable().scaledToFit().frame(width: 30, height: 30).clipShape(RoundedRectangle(cornerRadius: 4))
        } else {
            Image(systemName: "creditcard.fill").foregroundColor(.ppGreen)
        }
    }
}

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
                    Text("Enter App").font(.custom("Montserrat", size: 20)).fontWeight(.black).foregroundColor(.white)
                        .frame(maxWidth: .infinity).padding(16)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color(hex: "2ac33c")))
                }.padding(.horizontal, 24).padding(.top, 8)
            }
            Spacer()
        }
    }
}

#Preview { OnboardingFlowView().environmentObject(AppState()) }
