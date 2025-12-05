// CognitoVerificationView.swift
// Handles AWS Cognito email verification - after verification, user signs in automatically

import SwiftUI

struct CognitoVerificationView: View {
    @EnvironmentObject var app: AppState
    @Environment(\.dismiss) private var dismiss
    
    let email: String
    let password: String // 👈 ADDED: To enable auto-login
    
    @State private var code: [String] = ["", "", "", "", "", ""]
    @FocusState private var focusedField: Int?
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var successMessage = ""
    @State private var isResending = false
    
    // Note: We removed 'navigateToSignIn' because we will auto-login instead
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.adaptiveBackground.ignoresSafeArea()
                
                VStack(alignment: .center, spacing: 24) {
                    // Email icon
                    Image(systemName: "envelope.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(Color.ppGreen)
                        .padding(.top, 20)
                    
                    Text("Verify Your Email")
                        .font(.custom("Montserrat", size: 28))
                        .fontWeight(.bold)
                        .foregroundColor(.adaptiveText)
                    
                    // Email display
                    VStack(spacing: 4) {
                        Text("We sent a verification code to")
                            .font(.custom("Montserrat", size: 16))
                            .foregroundColor(.adaptiveText)
                        Text(email)
                            .font(.custom("Montserrat", size: 16))
                            .fontWeight(.bold)
                            .foregroundColor(Color.ppGreen)
                    }
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.top, 20)
                    
                    // Success message
                    if !successMessage.isEmpty {
                        Text(successMessage)
                            .font(.custom("Montserrat", size: 12))
                            .foregroundColor(Color.ppGreen)
                            .padding(.horizontal, 32)
                    }
                    
                    // Error message
                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .font(.custom("Montserrat", size: 12))
                            .foregroundColor(.red)
                            .padding(.horizontal, 32)
                    }
                    
                    // Code input boxes
                    HStack(spacing: 12) {
                        ForEach(0..<6, id: \.self) { index in
                            TextField("", text: $code[index])
                                .font(.custom("Montserrat", size: 24))
                                .fontWeight(.bold)
                                .multilineTextAlignment(.center)
                                .frame(width: 45, height: 55) // Adjusted slightly for fit
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(focusedField == index ? Color.ppGreen : Color.clear, lineWidth: 2)
                                )
                                .keyboardType(.numberPad)
                                .focused($focusedField, equals: index)
                                .foregroundColor(.adaptiveText)
                                .onChange(of: code[index]) { _, newValue in
                                    handleCodeInput(index: index, newValue: newValue)
                                }
                        }
                    }
                    .padding(.top, 32)
                    .padding(.horizontal)
                    
                    // Resend Code Button
                    Button(action: resendCode) {
                        HStack {
                            if isResending {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: Color.ppGreen))
                                    .scaleEffect(0.8)
                            }
                            Text("Resend Code")
                                .font(.custom("Montserrat", size: 16))
                                .foregroundColor(Color.ppGreen)
                        }
                    }
                    .disabled(isResending || isLoading)
                    .padding(.top, 16)
                    
                    Spacer()
                    
                    // Verify Button
                    Button(action: verifyCode) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            }
                            Text("Verify & Continue")
                                .font(.custom("Montserrat", size: 20))
                                .fontWeight(.black)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(isCodeComplete ? Color.ppGreen : Color.gray)
                        )
                        .shadow(color: Color.ppShadow.opacity(0.3), radius: 4, x: 0, y: 2)
                    }
                    .disabled(!isCodeComplete || isLoading)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "arrow.left")
                            .foregroundColor(.adaptiveText)
                            .font(.system(size: 20))
                    }
                }
            }
            .onAppear {
                focusedField = 0
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var isCodeComplete: Bool {
        code.allSatisfy { !$0.isEmpty }
    }
    
    // MARK: - Helper Methods
    
    private func handleCodeInput(index: Int, newValue: String) {
        errorMessage = ""
        successMessage = ""
        
        if newValue.count == 1 && index < 5 {
            focusedField = index + 1
        } else if newValue.isEmpty && index > 0 {
            focusedField = index - 1
        }
        
        if newValue.count > 1 {
            code[index] = String(newValue.prefix(1))
        }
    }
    
    // MARK: - Verification & Auto-Login
    
    private func verifyCode() {
        errorMessage = ""
        successMessage = ""
        isLoading = true
        
        let verificationCode = code.joined()
        print("🔵 Attempting to verify code: \(verificationCode)")
        
        Task {
            do {
                // 1. Confirm the signup in Cognito
                try await app.authService.confirmSignUp(email: email, code: verificationCode)
                print("✅ Email confirmed!")
                
                await MainActor.run {
                    successMessage = "Verified! Signing you in..."
                }
                
                // 2. Auto-Login (Native)
                // We use the password passed from the previous screen
                try await app.authService.signInNative(username: email, password: password)
                
                // 3. Update App State
                // We need to ensure the AppState knows we are logged in so ContentView switches tabs
                // Extract info like we do in the normal sign in
                let attributes = try await app.authService.extractUserInfoFromIDToken()
                
                await MainActor.run {
                    app.isAuthenticated = true
                    app.userEmail = attributes["email"] ?? email
                    app.userFirstName = attributes["given_name"] ?? ""
                    app.userLastName = attributes["family_name"] ?? ""
                    
                    // Check onboarding (will be false for new user)
                    app.checkPreviousOnboarding()
                    
                    isLoading = false
                    // Dismiss the sheet -> ContentView will re-render -> Show Onboarding
                    dismiss()
                }
                
            } catch {
                await MainActor.run {
                    isLoading = false
                    print("❌ Error: \(error.localizedDescription)")
                    
                    // 👇 NEW CHECK: If already confirmed, try logging in anyway!
                    if error.localizedDescription.contains("Current status is CONFIRMED") {
                        print("⚠️ User already confirmed. Proceeding to auto-login...")
                        // Retry login
                        Task {
                            try? await app.authService.signInNative(username: email, password: password)
                            await MainActor.run {
                                app.checkPreviousOnboarding()
                                dismiss() // Success!
                            }
                        }
                        return
                    }
                    
                    if error.localizedDescription.contains("CodeMismatchException") {
                        errorMessage = "Invalid code. Please try again."
                    } else {
                        errorMessage = "Verification success, but auto-login failed. Please sign in manually."
                    }
                }
            }
        }
    }
    
    // MARK: - Resend Code
    
    private func resendCode() {
        errorMessage = ""
        successMessage = ""
        isResending = true
        
        Task {
            do {
                try await app.authService.resendConfirmationCode(email: email)
                
                await MainActor.run {
                    isResending = false
                    successMessage = "New code sent! Check your email."
                    code = ["", "", "", "", "", ""]
                    focusedField = 0
                }
            } catch {
                await MainActor.run {
                    isResending = false
                    errorMessage = "Failed to resend code. Please try again."
                }
            }
        }
    }
}

#Preview {
    CognitoVerificationView(email: "test@example.com", password: "password123")
        .environmentObject(AppState())
}
