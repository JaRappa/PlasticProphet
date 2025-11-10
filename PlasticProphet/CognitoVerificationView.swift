// CognitoVerificationView.swift
// Handles AWS Cognito email verification with auto sign-in

import SwiftUI

struct CognitoVerificationView: View {
    @EnvironmentObject var app: AppState
    @Environment(\.dismiss) private var dismiss
    
    let email: String
    
    @State private var code: [String] = ["", "", "", "", "", ""]
    @FocusState private var focusedField: Int?
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var successMessage = ""
    @State private var isResending = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.white.ignoresSafeArea()
                
                VStack(alignment: .center, spacing: 24) {
                    // Email icon
                    Image(systemName: "envelope.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(Color.ppGreen)
                        .padding(.top, 20)
                    
                    Text("Verify Your Email")
                        .font(.custom("Montserrat", size: 28))
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                    
                    // Email display
                    VStack(spacing: 4) {
                        Text("We sent a verification code to")
                            .font(.custom("Montserrat", size: 16))
                            .foregroundColor(.black)
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
                                .frame(width: 50, height: 60)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(focusedField == index ? Color.ppGreen : Color.clear, lineWidth: 2)
                                )
                                .keyboardType(.numberPad)
                                .focused($focusedField, equals: index)
                                .onChange(of: code[index]) { _, newValue in
                                    handleCodeInput(index: index, newValue: newValue)
                                }
                        }
                    }
                    .padding(.top, 32)
                    
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
                            Text("Verify")
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
                            .foregroundColor(.black)
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
    
    // MARK: - Verification with Auto Sign-In
    
    private func verifyCode() {
        errorMessage = ""
        successMessage = ""
        isLoading = true
        
        let verificationCode = code.joined()
        
        print("🔵 Attempting to verify code: \(verificationCode)")
        
        Task {
            do {
                // Step 1: Confirm the signup
                try await app.authService.confirmSignUp(email: email, code: verificationCode)
                print("✅ Email confirmed!")
                
                await MainActor.run {
                    isLoading = false
                    successMessage = "Email verified! You can now sign in securely."
                    
                    // Close the verification view - user needs to sign in via OAuth 2.0
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        dismiss()
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    print("❌ Confirmation failed: \(error.localizedDescription)")
                    
                    if error.localizedDescription.contains("CodeMismatchException") {
                        errorMessage = "Invalid code. Please try again."
                    } else if error.localizedDescription.contains("ExpiredCodeException") {
                        errorMessage = "Code expired. Please request a new code."
                    } else {
                        errorMessage = "Invalid code provided, please request a code again."
                    }
                    
                    code = ["", "", "", "", "", ""]
                    focusedField = 0
                }
            }
        }
    }
    
    // MARK: - Resend Code
    
    private func resendCode() {
        errorMessage = ""
        successMessage = ""
        isResending = true
        
        print("🔵 Resending verification code to: '\(email)'")  // Check what email looks like
        print("🔵 Email length: \(email.count)")
        print("🔵 Email isEmpty: \(email.isEmpty)")
        
        Task {
            do {
                try await app.authService.resendConfirmationCode(email: email)
                
                await MainActor.run {
                    isResending = false
                    successMessage = "New code sent! Check your email."
                    print("✅ New verification code sent")
                    
                    code = ["", "", "", "", "", ""]
                    focusedField = 0
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        successMessage = ""
                    }
                }
            } catch {
                await MainActor.run {
                    isResending = false
                    errorMessage = "Failed to resend code. Please try again."
                    print("❌ Failed to resend code: \(error.localizedDescription)")
                }
            }
        }
    }
}

#Preview {
    CognitoVerificationView(email: "test@example.com")
        .environmentObject(AppState())
}










