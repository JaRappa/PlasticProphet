//
//  ProfileView.swift
//  PlasticProphet
//
//  Created by Caroline Zanuto on 10/23/25.
// User profile with account options and navigation to settings

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var app: AppState
    @State private var showMyAccount = false
    @State private var showSettings = false
    @State private var showHelpSupport = false
    @State private var showAboutApp = false
    @State private var faceIDEnabled = false
    @State private var twoFactorEnabled = false
    @State private var showingSignOutAlert = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // User Profile Header
                    VStack(spacing: 16) {
                        // Avatar and Name Section
                        HStack(spacing: 16) {
                            // Avatar Circle
                            ZStack {
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 60, height: 60)
                                
                                Image(systemName: "person.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(Color.ppGreen)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(app.userFirstName) \(app.userLastName)")
                                    .font(.custom("Montserrat", size: 22))
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                
                                Text(app.userEmail)
                                    .font(.custom("Montserrat", size: 14))
                                    .foregroundColor(.white.opacity(0.9))
                            }
                            
                            Spacer()
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.ppGreen)
                        )
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)
                    
                    // Quick Actions Section
                    VStack(spacing: 0) {
                        Text("Account")
                            .font(.custom("Montserrat", size: 18))
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                            .padding(.bottom, 12)
                        
                        VStack(spacing: 0) {
                            ProfileMenuItem(
                                icon: "person.circle",
                                iconColor: Color.ppGreen,
                                title: "My Account",
                                subtitle: "Make changes to your account",
                                showChevron: true,
                                showWarning: false
                            ) {
                                showMyAccount = true
                            }
                            
                            Divider()
                                .padding(.leading, 60)
                            
                            ProfileMenuItem(
                                icon: "bookmark.circle",
                                iconColor: Color.ppGreen,
                                title: "Saved Beneficiary",
                                subtitle: "Manage your saved account",
                                showChevron: true
                            ) {
                                // TODO: Navigate to saved beneficiary
                            }
                            
                            Divider()
                                .padding(.leading, 60)
                            
                            ProfileMenuToggle(
                                icon: "faceid",
                                iconColor: Color.ppGreen,
                                title: "Face ID / Touch ID",
                                subtitle: "Manage your device security",
                                isOn: $faceIDEnabled
                            )
                            
                            Divider()
                                .padding(.leading, 60)
                            
                            ProfileMenuItem(
                                icon: "shield.checkered",
                                iconColor: Color.ppGreen,
                                title: "Two-Factor Authentication",
                                subtitle: "Further secure your account for safety",
                                showChevron: true
                            ) {
                                // TODO: Navigate to 2FA setup
                            }
                        }
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                        .padding(.horizontal)
                    }
                    
                    // More Section
                    VStack(spacing: 0) {
                        Text("More")
                            .font(.custom("Montserrat", size: 18))
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                            .padding(.bottom, 12)
                        
                        VStack(spacing: 0) {
                            ProfileMenuItem(
                                icon: "questionmark.circle",
                                iconColor: Color.ppGreen,
                                title: "Help & Support",
                                subtitle: "Get help and contact us",
                                showChevron: true
                            ) {
                                showHelpSupport = true
                            }
                            
                            Divider()
                                .padding(.leading, 60)
                            
                            ProfileMenuItem(
                                icon: "info.circle",
                                iconColor: Color.ppGreen,
                                title: "About App",
                                subtitle: "Learn more about PlasticProphet",
                                showChevron: true
                            ) {
                                showAboutApp = true
                            }
                            
                            Divider()
                                .padding(.leading, 60)
                            
                            ProfileMenuItem(
                                icon: "gearshape",
                                iconColor: Color.ppGreen,
                                title: "Settings",
                                subtitle: "Manage app preferences",
                                showChevron: true
                            ) {
                                showSettings = true
                            }
                        }
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                        .padding(.horizontal)
                    }
                    
                    // Log Out Button
                    Button(action: { showingSignOutAlert = true }) {
                        HStack {
                            Image(systemName: "arrow.right.square")
                                .font(.system(size: 20))
                            Text("Log Out")
                                .font(.custom("Montserrat", size: 16))
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(Color.ppGreen)
                        .frame(maxWidth: .infinity)
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.ppGreen, lineWidth: 2)
                        )
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 32)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showSettings) {
            NavigationStack {
                SettingsView()
            }
        }
        .sheet(isPresented: $showMyAccount) {
            MyAccountView()
        }
        .sheet(isPresented: $showHelpSupport) {
            HelpSupportView()
        }
        .sheet(isPresented: $showAboutApp) {
            AboutAppView()
        }
        .alert("Log Out", isPresented: $showingSignOutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Log Out", role: .destructive) {
                app.signOut()
            }
        } message: {
            Text("Are you sure you want to log out?")
        }
    }
}

// MARK: - Profile Menu Item
struct ProfileMenuItem: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    var showChevron: Bool = true
    var showWarning: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.1))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(iconColor)
                }
                
                // Text
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.custom("Montserrat", size: 16))
                        .fontWeight(.semibold)
                        .foregroundColor(.black)
                    
                    Text(subtitle)
                        .font(.custom("Montserrat", size: 12))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // Chevron or Warning
                if showWarning {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .font(.system(size: 16))
                }
                
                if showChevron {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.gray)
                }
            }
            .padding(16)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Profile Menu Toggle
struct ProfileMenuToggle: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.1))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(iconColor)
            }
            
            // Text
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.custom("Montserrat", size: 16))
                    .fontWeight(.semibold)
                    .foregroundColor(.black)
                
                Text(subtitle)
                    .font(.custom("Montserrat", size: 12))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // Toggle
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(Color.ppGreen)
        }
        .padding(16)
    }
}

// MARK: - Placeholder Views
struct MyAccountView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(Color.ppGreen)
                
                Text("My Account")
                    .font(.custom("Montserrat", size: 24))
                    .fontWeight(.bold)
                
                Text("Edit profile functionality coming soon!")
                    .font(.custom("Montserrat", size: 14))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .navigationTitle("My Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.custom("Montserrat", size: 16))
                }
            }
        }
    }
}

struct HelpSupportView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "questionmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(Color.ppGreen)
                
                Text("Help & Support")
                    .font(.custom("Montserrat", size: 24))
                    .fontWeight(.bold)
                
                Text("Need help? Contact us at support@plasticprophet.com")
                    .font(.custom("Montserrat", size: 14))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding()
            .navigationTitle("Help & Support")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.custom("Montserrat", size: 16))
                }
            }
        }
    }
}

struct AboutAppView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image("App Logo Black")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                
                Text("PlasticProphet")
                    .font(.custom("Montserrat", size: 28))
                    .fontWeight(.bold)
                
                Text("Version 1.0.0")
                    .font(.custom("Montserrat", size: 16))
                    .foregroundColor(.gray)
                
                Text("Your smart companion for maximizing credit card rewards")
                    .font(.custom("Montserrat", size: 14))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .padding(.top, 8)
            }
            .padding()
            .navigationTitle("About App")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.custom("Montserrat", size: 16))
                }
            }
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(AppState())
}

