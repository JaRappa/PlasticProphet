// ProfileView.swift
// User profile with account options

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var app: AppState
    @State private var showMyAccount = false
    @State private var showSettings = false
    @State private var showingSignOutAlert = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // User Profile Header Card (tappable)
                Button(action: { showMyAccount = true }) {
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
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.ppGreen)
                    )
                }
                .buttonStyle(.plain)
                .padding(.horizontal)
                .padding(.top, 20)
                
                // Settings Option
                VStack(spacing: 0) {
                    Button(action: { showSettings = true }) {
                        HStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(Color.ppGreen.opacity(0.1))
                                    .frame(width: 44, height: 44)
                                
                                Image(systemName: "gearshape")
                                    .font(.system(size: 20))
                                    .foregroundColor(.ppGreen)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Settings")
                                    .font(.custom("Montserrat", size: 16))
                                    .fontWeight(.semibold)
                                    .foregroundColor(.black)
                                
                                Text("Manage app preferences")
                                    .font(.custom("Montserrat", size: 12))
                                    .foregroundColor(.gray)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.gray)
                        }
                        .padding(16)
                    }
                    .buttonStyle(.plain)
                }
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                .padding(.horizontal)
                
                Spacer()
                
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
                .padding(.bottom, 100)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showSettings) {
            NavigationStack {
                SettingsView()
                    .environmentObject(app)
            }
        }
        .sheet(isPresented: $showMyAccount) {
            MyAccountView()
                .environmentObject(app)
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

// MARK: - My Account View
struct MyAccountView: View {
    @EnvironmentObject var app: AppState
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Text("First Name")
                        Spacer()
                        Text(app.userFirstName)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Last Name")
                        Spacer()
                        Text(app.userLastName)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Email")
                        Spacer()
                        Text(app.userEmail)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("My Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.ppGreen)
                }
            }
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(AppState())
}
