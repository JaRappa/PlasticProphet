// AuthenticationViews.swift
// Sign In, Sign Up, and Forgot Password flows

import SwiftUI

// MARK: - Landing Page (Sign Up/Sign In Choice)
struct AuthLandingView: View {
    @EnvironmentObject var app: AppState
    @State private var showSignIn = false
    @State private var showSignUp = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.adaptiveBackground.ignoresSafeArea()
                
                VStack(spacing: 40) {
                    Spacer()
                    
                    // Logo
                    AdaptiveLogo(width: 300, height: 300)
                    
                    Spacer()
                    
                    // Buttons
                    VStack(spacing: 16) {
                        Button(action: { showSignUp = true }) {
                            Text("Sign Up")
                                .font(.custom("Montserrat", size: 20))
                                .fontWeight(.black)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.ppGreen)
                                )
                                .shadow(color: Color.ppShadow.opacity(0.3), radius: 4, x: 0, y: 2)
                        }
                        
                        Button(action: { showSignIn = true }) {
                            Text("Sign In")
                                .font(.custom("Montserrat", size: 20))
                                .fontWeight(.black)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.ppGreen)
                                )
                                .shadow(color: Color.ppShadow.opacity(0.3), radius: 4, x: 0, y: 2)
                        }
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 60)
                }
            }
            .navigationDestination(isPresented: $showSignIn) {
                SignInView()
            }
            .navigationDestination(isPresented: $showSignUp) {
                SignUpView()
            }
        }
    }
}

// MARK: - Sign In View
struct SignInView: View {
    @EnvironmentObject var app: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var password = ""
    // 👇 NEW STATE for toggling visibility
    @State private var showPassword = false
    @State private var isLoading = false
    @State private var errorMessage = ""
    @FocusState private var focusedField: SignInField?
    
    enum SignInField {
        case email, password
    }
    
    var body: some View {
        ZStack {
            Color.adaptiveBackground.ignoresSafeArea()
            
            VStack(alignment: .center, spacing: 24) {
                // Card icon
                Image(systemName: "creditcard.fill")
                    .font(.system(size: 50))
                    .foregroundColor(Color.ppGreen)
                    .rotationEffect(.degrees(15))
                    .padding(.top, 20)
                
                Text("Secure Sign In")
                    .font(.custom("Montserrat", size: 32))
                    .fontWeight(.bold)
                    .foregroundColor(.adaptiveText)
                
                // Info text
                VStack(spacing: 12) {
                    Text("Sign in securely using Cognito")
                        .font(.custom("Montserrat", size: 16))
                        .foregroundColor(.adaptiveText)
                        .multilineTextAlignment(.center)
                    
                    Text("Your credentials are never shared with this app")
                        .font(.custom("Montserrat", size: 14))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 32)
                .padding(.top, 20)
                
                // Form Fields
                VStack(spacing: 16) {
                    // Email Input
                    TextField("Email Address", text: $email)
                        .font(.custom("Montserrat", size: 16))
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .focused($focusedField, equals: .email)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(focusedField == .email ? Color.ppGreen : Color.clear, lineWidth: 2)
                        )
                    
                    // 👇 NEW Password Input with Toggle
                    HStack {
                        if showPassword {
                            TextField("Password", text: $password)
                                .font(.custom("Montserrat", size: 16))
                                .focused($focusedField, equals: .password)
                        } else {
                            SecureField("Password", text: $password)
                                .font(.custom("Montserrat", size: 16))
                                .focused($focusedField, equals: .password)
                        }
                        
                        Button(action: { showPassword.toggle() }) {
                            Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                .foregroundColor(.gray)
                                .padding(8) // Increases tap area
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(focusedField == .password ? Color.ppGreen : Color.clear, lineWidth: 2)
                    )
                }
                .padding(.horizontal, 32)
                .padding(.top, 10)
                
                // Error message
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .font(.custom("Montserrat", size: 12))
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .padding(12)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                }
                
                Spacer()
                
                // Native Sign In Button
                Button(action: performNativeSignIn) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .padding(.trailing, 8)
                        }
                        Text("Sign In")
                            .font(.custom("Montserrat", size: 20))
                            .fontWeight(.black)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(email.isEmpty || password.isEmpty ? Color.gray : Color.ppGreen)
                    )
                    .shadow(color: Color.ppShadow.opacity(0.3), radius: 4, x: 0, y: 2)
                }
                .disabled(email.isEmpty || password.isEmpty || isLoading)
                .padding(.horizontal, 32)
                
                // Forgot Password Link
                NavigationLink(destination: ForgotPasswordView()) {
                    Text("Forgot Password?")
                        .font(.custom("Montserrat", size: 14))
                        .fontWeight(.semibold)
                        .foregroundColor(Color.ppGreen)
                }
                .padding(.bottom, 20)
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
    }
    
    // MARK: - Helper Functions
    
    private func performNativeSignIn() {
        errorMessage = ""
        isLoading = true
        
        Task {
            do {
                try await app.authService.signInNative(username: email, password: password)
                let attributes = try await app.authService.extractUserInfoFromIDToken()
                
                await MainActor.run {
                    app.isAuthenticated = true
                    app.userEmail = attributes["email"] ?? email
                    app.userFirstName = attributes["given_name"] ?? ""
                    app.userLastName = attributes["family_name"] ?? ""
                    
                    app.checkPreviousOnboarding()
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    print("❌ Error: \(error.localizedDescription)")
                    
                    if error.localizedDescription.contains("NotAuthorizedException") {
                        errorMessage = "Incorrect email or password."
                    } else if error.localizedDescription.contains("UserNotFoundException") {
                        errorMessage = "User does not exist."
                    } else if error.localizedDescription.contains("UserNotConfirmedException") {
                        errorMessage = "Email not verified."
                    } else {
                        errorMessage = "Sign in failed. Please try again."
                    }
                }
            }
        }
    }
    
    // Kept your debug functions below
    private func runHealthCheck() {
        Task {
            do {
                print("🚀 Starting Health Check...")
                // This creates a temporary instance of APIService just for this test
                let status = try await APIService().checkHealth()
                print("✅ SUCCESS: Backend says: '\(status)'")
                errorMessage = "✅ Connected: \(status)" // Optional: Show on screen
            } catch {
                print("❌ FAILED: Could not reach backend. \(error.localizedDescription)")
                errorMessage = "❌ Connection Failed" // Optional: Show on screen
            }
        }
    }
    
    private func testCallbackURL() {
        // Test if the callback URL scheme is properly registered
        let testURL = URL(string: "plasticprophet://auth-callback?test=1")!
        if UIApplication.shared.canOpenURL(testURL) {
            UIApplication.shared.open(testURL)
            errorMessage = "✅ Callback URL scheme is working!"
        } else {
            errorMessage = "❌ Callback URL scheme not registered. Check Info.plist"
        }
    }
}

// MARK: - Sign Up View
struct SignUpView: View {
    @EnvironmentObject var app: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var showVerification = false
    @State private var signUpEmail = ""
    @State private var navigateToSignIn = false
    
    // Form fields
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    
    enum SignUpField {
        case firstName, lastName, email, password, confirmPassword
    }
    
    @FocusState private var focusedField: SignUpField?
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.adaptiveBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Card icon
                        Image(systemName: "creditcard.fill")
                            .font(.system(size: 50))
                            .foregroundColor(Color.ppGreen)
                            .rotationEffect(.degrees(15))
                            .padding(.top, 20)
                        
                        Text("Create Your Account")
                            .font(.custom("Montserrat", size: 32))
                            .fontWeight(.bold)
                            .foregroundColor(.adaptiveText)
                        
                        // First Name
                        VStack(alignment: .leading, spacing: 8) {
                            Text("First Name")
                                .font(.custom("Montserrat", size: 14))
                                .fontWeight(.medium)
                                .foregroundColor(.adaptiveText)
                            
                            TextField("First Name", text: $firstName)
                                .font(.custom("Montserrat", size: 16))
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(focusedField == .firstName ? Color.ppGreen : Color.clear, lineWidth: 2)
                                )
                                .focused($focusedField, equals: .firstName)
                        }
                        
                        // Last Name
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Last Name")
                                .font(.custom("Montserrat", size: 14))
                                .fontWeight(.medium)
                                .foregroundColor(.adaptiveText)
                            
                            TextField("Last Name", text: $lastName)
                                .font(.custom("Montserrat", size: 16))
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(focusedField == .lastName ? Color.ppGreen : Color.clear, lineWidth: 2)
                                )
                                .focused($focusedField, equals: .lastName)
                        }
                        
                        // Email
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email Address")
                                .font(.custom("Montserrat", size: 14))
                                .fontWeight(.medium)
                                .foregroundColor(.adaptiveText)
                            
                            TextField("Email Address", text: $email)
                                .font(.custom("Montserrat", size: 16))
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(focusedField == .email ? Color.ppGreen : Color.clear, lineWidth: 2)
                                )
                                .keyboardType(.emailAddress)
                                .textInputAutocapitalization(.never)
                                .focused($focusedField, equals: .email)
                        }
                        
                        // Password
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .font(.custom("Montserrat", size: 14))
                                .fontWeight(.medium)
                                .foregroundColor(.adaptiveText)
                            
                            HStack {
                                if showPassword {
                                    TextField("Password", text: $password)
                                        .font(.custom("Montserrat", size: 16))
                                        .focused($focusedField, equals: .password)
                                } else {
                                    SecureField("Password", text: $password)
                                        .font(.custom("Montserrat", size: 16))
                                        .focused($focusedField, equals: .password)
                                }
                                
                                Button(action: { showPassword.toggle() }) {
                                    Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                        .foregroundColor(.gray)
                                }
                                .padding(.trailing, 8)
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(focusedField == .password ? Color.ppGreen : Color.clear, lineWidth: 2)
                            )
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Your password must include at least:")
                                    .font(.custom("Montserrat", size: 11))
                                    .foregroundColor(.secondary)
                                Text("• 8 characters")
                                    .font(.custom("Montserrat", size: 11))
                                    .foregroundColor(.secondary)
                                Text("• One uppercase and one lowercase characters")
                                    .font(.custom("Montserrat", size: 11))
                                    .foregroundColor(.secondary)
                                Text("• One special character")
                                    .font(.custom("Montserrat", size: 11))
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        // Confirm Password
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Confirm Password")
                                .font(.custom("Montserrat", size: 14))
                                .fontWeight(.medium)
                                .foregroundColor(.adaptiveText)
                            
                            HStack {
                                if showConfirmPassword {
                                    TextField("Confirm Password", text: $confirmPassword)
                                        .font(.custom("Montserrat", size: 16))
                                        .focused($focusedField, equals: .confirmPassword)
                                } else {
                                    SecureField("Confirm Password", text: $confirmPassword)
                                        .font(.custom("Montserrat", size: 16))
                                        .focused($focusedField, equals: .confirmPassword)
                                }
                                
                                Button(action: { showConfirmPassword.toggle() }) {
                                    Image(systemName: showConfirmPassword ? "eye.slash.fill" : "eye.fill")
                                        .foregroundColor(.gray)
                                }
                                .padding(.trailing, 8)
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(focusedField == .confirmPassword ? Color.ppGreen : Color.clear, lineWidth: 2)
                            )
                        }
                        
                        // Sign Up Button
                        Button(action: signUp) {
                            Text("Continue")
                                .font(.custom("Montserrat", size: 20))
                                .fontWeight(.black)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(canSignUp ? Color.ppGreen : Color.ppGreen.opacity(0.3))
                                )
                                .shadow(color: Color.ppShadow.opacity(0.3), radius: 4, x: 0, y: 2)
                        }
                        .disabled(!canSignUp)
                        .padding(.top, 20)
                        .padding(.bottom, 40)
                    }
                    .padding(.horizontal, 32)
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
            .sheet(isPresented: $showVerification) {
                CognitoVerificationView(email: signUpEmail, password: password)
                    .environmentObject(app)
            }
            .navigationDestination(isPresented: $navigateToSignIn) {
                SignInView()
            }
        }
    }
    
    private func signUp() {
        signUpEmail = email // Save for verification
        
        Task {
            await app.signUp(
                email: email,
                password: password,
                firstName: firstName,
                lastName: lastName
            )
            
            await MainActor.run {
                showVerification = true
            }
        }
    }
    
    private var canSignUp: Bool {
        !firstName.isEmpty &&
        !lastName.isEmpty &&
        !email.isEmpty &&
        password.count >= 8 &&
        password == confirmPassword
    }
}
        
// MARK: - Forgot Password View
struct ForgotPasswordView: View {
    @EnvironmentObject var app: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var email: String = ""
    @State private var showVerification = false
    @FocusState private var emailFocused: Bool
    
    // --- 1. THE BODY (UI) ---
    var body: some View {
        ZStack {
            Color.adaptiveBackground.ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 24) {
                // Card icon
                Image(systemName: "creditcard.fill")
                    .font(.system(size: 50))
                    .foregroundColor(Color.ppGreen)
                    .rotationEffect(.degrees(15))
                    .padding(.top, 20)
                
                Text("Forgot Password")
                    .font(.custom("Montserrat", size: 32))
                    .fontWeight(.bold)
                    .foregroundColor(.adaptiveText)
                
                // Email
                VStack(alignment: .leading, spacing: 8) {
                    Text("Email Address")
                        .font(.custom("Montserrat", size: 14))
                        .fontWeight(.medium)
                        .foregroundColor(.adaptiveText)
                    
                    TextField("Email Address", text: $email)
                        .font(.custom("Montserrat", size: 16))
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(emailFocused ? Color.ppGreen : Color.clear, lineWidth: 2)
                        )
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .focused($emailFocused)
                }
                .padding(.top, 20)
                
                Spacer()
                
                // Enter Button
                Button(action: { requestReset() }) { // <--- 2. Call the function here
                    Text("Enter")
                        .font(.custom("Montserrat", size: 20))
                        .fontWeight(.black)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.ppGreen)
                        )
                        .shadow(color: Color.ppShadow.opacity(0.3), radius: 4, x: 0, y: 2)
                }
                .disabled(email.isEmpty)
                .opacity(email.isEmpty ? 0.5 : 1.0)
                .padding(.bottom, 40)
            }
            .padding(.horizontal, 32)
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
        .navigationDestination(isPresented: $showVerification) {
            VerificationCodeView(email: email)
        }
    } // <--- END OF BODY
    
    // --- 3. THE FUNCTION (Outside Body, Inside Struct) ---
    private func requestReset() {
        Task {
            do {
                // Call the new service function
                try await app.authService.forgotPassword(email: email)
                
                await MainActor.run {
                    // Navigate to the verification code screen
                    showVerification = true
                }
            } catch {
                print("❌ Failed to request reset: \(error.localizedDescription)")
                // Optional: set an errorMessage state variable here to show the user
            }
        }
    }
}
        
        // MARK: - Verification Code View
        struct VerificationCodeView: View {
            @Environment(\.dismiss) private var dismiss
            let email: String
            @State private var code: [String] = ["", "", "", ""]
            @FocusState private var focusedField: Int?
            @State private var showResetPassword = false
            
            var body: some View {
                ZStack {
                    Color.adaptiveBackground.ignoresSafeArea()
                    
                    VStack(alignment: .center, spacing: 24) {
                        // Card icon
                        Image(systemName: "creditcard.fill")
                            .font(.system(size: 50))
                            .foregroundColor(Color.ppGreen)
                            .rotationEffect(.degrees(15))
                            .padding(.top, 20)
                        
                        // Fixed text without concatenation
                        VStack(spacing: 4) {
                            Text("We sent a two-step authentication")
                                .font(.custom("Montserrat", size: 16))
                                .foregroundColor(.adaptiveText)
                            HStack(spacing: 4) {
                                Text("code to")
                                    .font(.custom("Montserrat", size: 16))
                                    .foregroundColor(.adaptiveText)
                                Text(email)
                                    .font(.custom("Montserrat", size: 16))
                                    .fontWeight(.bold)
                                    .foregroundColor(Color.ppGreen)
                                Text(".")
                                    .font(.custom("Montserrat", size: 16))
                                    .foregroundColor(.adaptiveText)
                            }
                        }
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .padding(.top, 40)
                        
                        // Code input boxes
                        HStack(spacing: 16) {
                            ForEach(0..<4, id: \.self) { index in
                                TextField("", text: $code[index])
                                    .font(.custom("Montserrat", size: 24))
                                    .fontWeight(.bold)
                                    .multilineTextAlignment(.center)
                                    .frame(width: 60, height: 60)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(focusedField == index ? Color.ppGreen : Color.clear, lineWidth: 2)
                                    )
                                    .keyboardType(.numberPad)
                                    .focused($focusedField, equals: index)
                                    .onChange(of: code[index]) { _, newValue in
                                        if newValue.count == 1 && index < 3 {
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
                        
                        // Enter Button
                        Button(action: { showResetPassword = true }) {
                            Text("Enter")
                                .font(.custom("Montserrat", size: 20))
                                .fontWeight(.black)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(isCodeComplete ? Color.ppGreen : Color.gray)
                                )
                                .shadow(color: Color.ppShadow.opacity(0.3), radius: 4, x: 0, y: 2)
                        }
                        .disabled(!isCodeComplete)
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
                .navigationDestination(isPresented: $showResetPassword) {
                    // We pass the email AND the code (joined from the array) to the final screen
                    ResetPasswordView(email: email, code: code.joined())
                }
                .onAppear {
                    focusedField = 0
                }
            }
            
            private var isCodeComplete: Bool {
                code.allSatisfy { !$0.isEmpty }
            }
        }
        
// MARK: - Reset Password View
struct ResetPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var app: AppState
    
    // 👇 Added these properties to receive data from the previous screen
    let email: String
    let code: String
    
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var showPassword: Bool = false
    @State private var showConfirmPassword: Bool = false
    @State private var showSuccess = false
    @State private var errorMessage = "" // Added for error handling
    @FocusState private var focusedField: ResetField?
    
    enum ResetField {
        case password, confirmPassword
    }
    
    private var isValidPassword: Bool {
        password.count >= 8 &&
        password.range(of: "[A-Z]", options: .regularExpression) != nil &&
        password.range(of: "[a-z]", options: .regularExpression) != nil &&
        password.range(of: "[^A-Za-z0-9]", options: .regularExpression) != nil
    }
    
    private var canReset: Bool {
        isValidPassword && password == confirmPassword
    }
    
    var body: some View {
        ZStack {
            Color.adaptiveBackground.ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 24) {
                // Card icon
                Image(systemName: "creditcard.fill")
                    .font(.system(size: 50))
                    .foregroundColor(Color.ppGreen)
                    .rotationEffect(.degrees(15))
                    .padding(.top, 20)
                
                // Password requirements (Keeping your existing UI layout)
                VStack(alignment: .leading, spacing: 8) {
                    Text("Password")
                        .font(.custom("Montserrat", size: 14))
                        .fontWeight(.semibold)
                        .foregroundColor(.adaptiveText)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Your password must include at least:")
                            .font(.custom("Montserrat", size: 11))
                            .foregroundColor(.secondary)
                        Text("• 8 characters")
                            .font(.custom("Montserrat", size: 11))
                            .foregroundColor(.secondary)
                        Text("• One uppercase and one lowercase characters")
                            .font(.custom("Montserrat", size: 11))
                            .foregroundColor(.secondary)
                        Text("• One special character")
                            .font(.custom("Montserrat", size: 11))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.top, 20)
                
                // Password Input
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        if showPassword {
                            TextField("Password", text: $password)
                                .font(.custom("Montserrat", size: 16))
                                .focused($focusedField, equals: .password)
                        } else {
                            SecureField("Password", text: $password)
                                .font(.custom("Montserrat", size: 16))
                                .focused($focusedField, equals: .password)
                        }
                        
                        Button(action: { showPassword.toggle() }) {
                            Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                .foregroundColor(.gray)
                        }
                        .padding(.trailing, 8)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(focusedField == .password ? Color.ppGreen : Color.clear, lineWidth: 2)
                    )
                }
                
                // Confirm Password Input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Confirm Password")
                        .font(.custom("Montserrat", size: 14))
                        .fontWeight(.medium)
                        .foregroundColor(.adaptiveText)
                    
                    HStack {
                        if showConfirmPassword {
                            TextField("Confirm Password", text: $confirmPassword)
                                .font(.custom("Montserrat", size: 16))
                                .focused($focusedField, equals: .confirmPassword)
                        } else {
                            SecureField("Confirm Password", text: $confirmPassword)
                                .font(.custom("Montserrat", size: 16))
                                .focused($focusedField, equals: .confirmPassword)
                        }
                        
                        Button(action: { showConfirmPassword.toggle() }) {
                            Image(systemName: showConfirmPassword ? "eye.slash.fill" : "eye.fill")
                                .foregroundColor(.gray)
                        }
                        .padding(.trailing, 8)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(focusedField == .confirmPassword ? Color.ppGreen : Color.clear, lineWidth: 2)
                    )
                }
                
                // Error Message Display
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .font(.custom("Montserrat", size: 12))
                        .foregroundColor(.red)
                }
                
                Spacer()
                
                // Submit Button
                Button(action: { submitNewPassword() }) {
                    Text("Enter")
                        .font(.custom("Montserrat", size: 20))
                        .fontWeight(.black)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(canReset ? Color.ppGreen : Color.gray)
                        )
                        .shadow(color: Color.ppShadow.opacity(0.3), radius: 4, x: 0, y: 2)
                }
                .disabled(!canReset)
                .padding(.bottom, 40)
            }
            .padding(.horizontal, 32)
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
        .alert("Password Reset", isPresented: $showSuccess) {
            Button("OK") {
                // Return to Sign In screen
                // We dismiss all the way back (simplest way is typically handled by root view,
                // but dismiss() here pops this view off the stack)
                dismiss() // Pop Reset View
                // You might need a way to pop multiple views or reset the navigation stack
                // For now, let's just pop this one.
            }
        } message: {
            Text("Your password has been successfully reset. Please sign in with your new password.")
        }
    }
    
    // 👇 THE BACKEND CONNECTION
    private func submitNewPassword() {
        Task {
            do {
                try await app.authService.confirmForgotPassword(
                    email: email,
                    code: code,
                    newPassword: password
                )
                
                await MainActor.run {
                    showSuccess = true
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Error: \(error.localizedDescription)"
                }
            }
        }
    }
}
        
        // MARK: - Previews
        #Preview("Landing") {
            AuthLandingView()
                .environmentObject(AppState())
        }
        
        #Preview("Sign In") {
            NavigationStack {
                SignInView()
                    .environmentObject(AppState())
            }
        }
        
        #Preview("Sign Up") {
            NavigationStack {
                SignUpView()
                    .environmentObject(AppState())
            }
        }
