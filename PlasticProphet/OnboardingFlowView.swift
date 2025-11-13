// OnboardingFlowView.swift
// Enhanced multi-step onboarding flow

import SwiftUI

struct OnboardingFlowView: View {
    enum Step { case intro, tos, permissions, addCards, done }
    @EnvironmentObject var app: AppState
    @State private var step: Step = .intro

    // New state for manual entry + sheet
    @State private var showManualEntry: Bool = false
    @State private var manualCardNumber: String = ""
    @State private var manualNetwork: String = ""
    @State private var manualRewards: String = ""

    var body: some View {
        VStack(spacing: 24) {
            switch step {
            case .intro:
                // Enhanced intro splash
                ZStack {
                    Color.adaptiveBackground
                    VStack(spacing: 40) {
                        VStack(spacing: 12) {
                            Text("Welcome to")
                                .font(.custom("Montserrat", size: 38))
                                .fontWeight(.black)
                                .foregroundColor(.adaptiveText)
                                .multilineTextAlignment(.center)
                                .tracking(-1.5)
                                .shadow(color: Color(red: 0.04, green: 0.23, blue: 0.05).opacity(0.25), radius: 2, x: 0, y: 4)
                                .minimumScaleFactor(0.5)
                                .lineLimit(1)

                            AdaptiveLogo(width: 280, height: 280)
                        }

                        Button(action: { withAnimation { step = .tos } }) {
                            HStack {
                                Text("Let's Get Started!")
                                    .font(.custom("Montserrat", size: 22))
                                    .fontWeight(.heavy)
                                    .foregroundColor(Color.white)
                            }
                            .padding(16)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.ppGreen.opacity(0.75))
                                    .shadow(color: Color(red: 0.04, green: 0.23, blue: 0.05).opacity(0.15), radius: 8, x: 0, y: 4)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(red: 0.16, green: 0.76, blue: 0.24), lineWidth: 2)
                            )
                            .shadow(color: Color(red: 0.04, green: 0.23, blue: 0.05).opacity(0.3), radius: 4, x: 0, y: 2)
                        }
                        .padding(.horizontal, 24)
                    }
                    .padding(16)
                    .frame(maxWidth: 340)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            case .tos:
                VStack(spacing: 0) {
                    Text("Terms of Service")
                        .font(.custom("Montserrat", size: 28))
                        .fontWeight(.bold)
                        .foregroundColor(.adaptiveText)
                        .tracking(-1.5)
                        .padding(.top, 20)
                        .padding(.bottom, 16)
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Terms and Conditions")
                                .font(.custom("Montserrat", size: 18))
                                .fontWeight(.semibold)
                                .foregroundColor(.adaptiveText)
                            
                            Text("By using PlasticProphet you agree to our terms and conditions. This is a placeholder Terms of Service. Replace with your real legal text.")
                                .font(.custom("Montserrat", size: 14))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.leading)
                            
                            Text("1. Acceptance of Terms")
                                .font(.custom("Montserrat", size: 16))
                                .fontWeight(.semibold)
                                .foregroundColor(.adaptiveText)
                                .padding(.top, 8)
                            
                            Text("Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris.")
                                .font(.custom("Montserrat", size: 14))
                                .foregroundColor(.secondary)
                            
                            Text("2. User Responsibilities")
                                .font(.custom("Montserrat", size: 16))
                                .fontWeight(.semibold)
                                .foregroundColor(.adaptiveText)
                                .padding(.top, 8)
                            
                            Text("Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident.")
                                .font(.custom("Montserrat", size: 14))
                                .foregroundColor(.secondary)
                            
                            Text("3. Privacy Policy")
                                .font(.custom("Montserrat", size: 16))
                                .fontWeight(.semibold)
                                .foregroundColor(.adaptiveText)
                                .padding(.top, 8)
                            
                            Text("Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium, totam rem aperiam, eaque ipsa quae ab illo inventore veritatis.")
                                .font(.custom("Montserrat", size: 14))
                                .foregroundColor(.secondary)
                            
                            Text("4. Limitation of Liability")
                                .font(.custom("Montserrat", size: 16))
                                .fontWeight(.semibold)
                                .foregroundColor(.adaptiveText)
                                .padding(.top, 8)
                            
                            Text("At vero eos et accusamus et iusto odio dignissimos ducimus qui blanditiis praesentium voluptatum deleniti atque corrupti quos dolores et quas molestias excepturi sint occaecati cupiditate non provident.")
                                .font(.custom("Montserrat", size: 14))
                                .foregroundColor(.secondary)
                        }
                        .padding()
                    }
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    VStack(spacing: 16) {
                        Toggle("I accept Terms of Service", isOn: $app.acceptedTos)
                            .font(.custom("Montserrat", size: 20))
                            .fontWeight(.medium)
                            .tint(Color(hex: "2ac33c"))
                            .padding(.horizontal)
                        
                        Button(action: { step = .permissions }) {
                            Text("Continue")
                                .font(.custom("Montserrat", size: 20))
                                .fontWeight(.black)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(app.acceptedTos ? Color(hex: "2ac33c") : Color.ppGreen.opacity(0.4))
                                )
                                .shadow(color: Color(hex: "0a3a0e").opacity(0.3), radius: 4, x: 0, y: 2)
                        }
                        .disabled(!app.acceptedTos)
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                    }
                }
                .padding(.vertical)

            case .permissions:
                VStack(spacing: 0) {
                    VStack(spacing: 12) {
                        Text("Permissions")
                            .font(.custom("Montserrat", size: 28))
                            .fontWeight(.bold)
                            .foregroundColor(.adaptiveText)
                            .tracking(-1.5)
                        
                        Text("To provide you with the best experience, PlasticProphet needs access to your camera and location.")
                            .font(.custom("Montserrat", size: 15))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top, 20)
                    
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "camera.fill")
                                    .foregroundColor(Color(hex: "2ac33c"))
                                    .font(.title2)
                                Text("Camera Access")
                                    .font(.custom("Montserrat", size: 18))
                                    .fontWeight(.semibold)
                                    .foregroundColor(.adaptiveText)
                                Spacer()
                            }
                            Text("Scan your credit cards quickly for instant card entry and recognition.")
                                .font(.custom("Montserrat", size: 14))
                                .foregroundColor(.secondary)
                            
                            Toggle("Camera Authorized", isOn: Binding(
                                get: { app.permissions.cameraAuthorized },
                                set: { app.markPermissions(camera: $0) }
                            ))
                            .font(.custom("Montserrat", size: 18))
                            .fontWeight(.medium)
                            .tint(Color(hex: "2ac33c"))
                        }
                        .padding()
                        .background(Color.gray.opacity(0.05))
                        .cornerRadius(12)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "location.fill")
                                    .foregroundColor(Color(hex: "2ac33c"))
                                    .font(.title2)
                                Text("Location Access")
                                    .font(.custom("Montserrat", size: 18))
                                    .fontWeight(.semibold)
                                    .foregroundColor(.adaptiveText)
                                Spacer()
                            }
                            Text("Receive personalized recommendations based on nearby merchants and locations.")
                                .font(.custom("Montserrat", size: 14))
                                .foregroundColor(.secondary)
                            
                            Toggle("Location Authorized", isOn: Binding(
                                get: { app.permissions.locationAuthorized },
                                set: { app.markPermissions(location: $0) }
                            ))
                            .font(.custom("Montserrat", size: 18))
                            .fontWeight(.medium)
                            .tint(Color(hex: "2ac33c"))
                        }
                        .padding()
                        .background(Color.gray.opacity(0.05))
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .padding(.top, 24)
                    
                    Spacer()
                    
                    Button(action: { step = .addCards }) {
                        Text("Continue")
                            .font(.custom("Montserrat", size: 20))
                            .fontWeight(.black)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(app.permissions.allGranted ? Color(hex: "2ac33c") : Color.ppGreen.opacity(0.4))
                            )
                            .shadow(color: Color(hex: "0a3a0e").opacity(0.3), radius: 4, x: 0, y: 2)
                    }
                    .disabled(!app.permissions.allGranted)
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
                .padding(.vertical)

            case .addCards:
                VStack(spacing: 16) {
                    Text("Add Your Cards")
                        .font(.custom("Montserrat", size: 28))
                        .fontWeight(.bold)
                        .foregroundColor(.adaptiveText)
                        .tracking(-1.5)
                    
                    Text("Search or scan to add your cards. Popular cards are shown below; tap a card tile to select it.")
                        .font(.custom("Montserrat", size: 14))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                        .minimumScaleFactor(0.8)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal)

                    // Card selection component with search + camera button + popular tiles
                    CardSelectionView(showHeader: false, showDoneButton: false)
                        .environmentObject(app)

                    Button(action: { showManualEntry = true }) {
                        HStack {
                            Image(systemName: "pencil")
                            Text("Add Manually")
                        }
                        .font(.custom("Montserrat", size: 16))
                        .fontWeight(.semibold)
                        .foregroundColor(Color(hex: "2ac33c"))
                        .padding(12)
                        .frame(maxWidth: .infinity)
                        .background(Color(hex: "2ac33c").opacity(0.1))
                        .cornerRadius(10)
                    }
                    .padding(.horizontal)

                    HStack(spacing: 12) {
                        Button(action: {
                            app.onboardingCompleted = true
                            step = .done
                        }) {
                            Text("Skip for now")
                                .font(.custom("Montserrat", size: 20))
                                .fontWeight(.bold)
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .padding(.horizontal, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.gray.opacity(0.1))
                                )
                                .minimumScaleFactor(0.7)
                                .lineLimit(1)
                        }

                        Button(action: {
                            app.proceedIfReady()
                            step = .done
                        }) {
                            Text("Finish")
                                .font(.custom("Montserrat", size: 20))
                                .fontWeight(.black)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .padding(.horizontal, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(app.cards.isEmpty ? Color.ppGreen.opacity(0.3) : Color(hex: "2ac33c"))
                                )
                                .shadow(color: Color(hex: "0a3a0e").opacity(0.3), radius: 4, x: 0, y: 2)
                                .minimumScaleFactor(0.7)
                                .lineLimit(1)
                        }
                        .disabled(app.cards.isEmpty)
                    }
                    .padding(.horizontal)
                }
                .padding()
                .sheet(isPresented: $showManualEntry) {
                    NavigationStack {
                        Form {
                            Section(header: Text("Card Info").font(.custom("Montserrat", size: 14))) {
                                TextField("Card number", text: $manualCardNumber)
                                    .keyboardType(.numberPad)
                                    .font(.custom("Montserrat", size: 16))
                                TextField("Card type (e.g. Visa)", text: $manualNetwork)
                                    .font(.custom("Montserrat", size: 16))
                                TextField("Rewards summary", text: $manualRewards)
                                    .font(.custom("Montserrat", size: 16))
                            }

                            Section {
                                Button("Add Card") {
                                    let digits = manualCardNumber.filter { $0.isNumber }
                                    guard digits.count >= 4 else { return }
                                    let last4 = String(digits.suffix(4))
                                    let name = manualNetwork.isEmpty ? "Manual Card ••••\(last4)" : "\(manualNetwork) ••••\(last4)"
                                    let card = Card(name: name, network: manualNetwork.isEmpty ? "Unknown" : manualNetwork, last4: last4, rewardSummary: manualRewards)
                                    app.cards.append(card)

                                    manualCardNumber = ""
                                    manualNetwork = ""
                                    manualRewards = ""
                                    showManualEntry = false
                                }
                                .font(.custom("Montserrat", size: 16))
                                .disabled(manualCardNumber.filter { $0.isNumber }.count < 4)

                                Button("Cancel") {
                                    showManualEntry = false
                                }
                                .font(.custom("Montserrat", size: 16))
                                .tint(.red)
                            }
                        }
                        .navigationTitle("Add Card Manually")
                        .navigationBarTitleDisplayMode(.inline)
                    }
                }

            case .done:
                VStack(spacing: 0) {
                    Spacer()
                    
                    VStack(spacing: 24) {
                        Image("App Logo Black")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 300, height: 300)
                        
                        HStack(spacing: 8) {
                            Text("All Set!")
                                .font(.custom("Montserrat", size: 32))
                                .fontWeight(.bold)
                                .foregroundColor(.adaptiveText)
                                .tracking(-1.5)
                            Image(systemName: "checkmark.seal.fill")
                                .font(.title)
                                .foregroundStyle(Color(hex: "2ac33c"))
                        }
                        
                        Text("You can start receiving recommendations.")
                            .font(.custom("Montserrat", size: 16))
                            .foregroundColor(.secondary)
                        
                        Button(action: {
                            app.onboardingCompleted = true
                            app.selectedTab = 0
                        }) {
                            Text("Enter App")
                                .font(.custom("Montserrat", size: 20))
                                .fontWeight(.black)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(hex: "2ac33c"))
                                )
                                .shadow(color: Color(hex: "0a3a0e").opacity(0.3), radius: 4, x: 0, y: 2)
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 8)
                    }
                    
                    Spacer()
                }
            }
            
            if step != .done {
                Spacer(minLength: 0)
            }
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
