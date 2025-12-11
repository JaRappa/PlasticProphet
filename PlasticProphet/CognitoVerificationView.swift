// CognitoVerificationView.swift
// Add this as a NEW file to your project
// This handles AWS Cognito email verification with your design style

import SwiftUI

struct CognitoVerificationView: View {
    @EnvironmentObject var app: AppState
    @Environment(\.dismiss) private var dismiss
    
    let email: String
    @State private var code: [String] = ["", "", "", "", "", ""] // 6 digits for AWS Cognito
    @FocusState private var focusedField: Int?
    @State private var isLoading = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.white.ignoresSafeArea()
                
                VStack(alignment: .center, spacing: 24) {
                    // Card icon
                    Image(systemName: "envelope.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(Color.ppGreen)
                        .padding(.top, 20)
                    
                    Text("Verify Your Email")
                        .font(.custom("Montserrat", size: 28))
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                    
                    // Fixed text without concatenation
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
                    
                    // Error message
                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .font(.custom("Montserrat", size: 12))
                            .foregroundColor(.red)
                            .padding(.horizontal, 32)
                    }
                    
                    // Code input boxes (6 digits for AWS Cognito)
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
                                    if newValue.count == 1 && index < 5 {
                                        focusedField = index + 1
                                    } else if newValue.isEmpty && index > 0 {
                                        focusedField = index - 1
                                    }
                                    // Limit to 1 character
                                    if newValue.count > 1 {
                                        code[index] = String(newValue.prefix(1))
                                    }
                                }
                        }
                    }
                    .padding(.top, 32)
                    
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
    
    private var isCodeComplete: Bool {
        code.allSatisfy { !$0.isEmpty }
    }
    
    private func verifyCode() {
        errorMessage = ""
        isLoading = true
        
        let verificationCode = code.joined() // Combine all digits
        
        Task {
            await app.confirmSignUp(email: email, code: verificationCode)
            
            await MainActor.run {
                isLoading = false
                
                // Check if verification was successful
                if app.authService.isAuthenticated {
                    dismiss() // Close verification view
                    // User can now sign in
                } else {
                    errorMessage = "Invalid code. Please try again."
                }
            }
        }
    }
}

#Preview {
    CognitoVerificationView(email: "test@example.com")
        .environmentObject(AppState())
}
