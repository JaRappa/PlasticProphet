// AuthenticationViews.swift
// Sign In, Sign Up, and Forgot Password flows

import SwiftUI

// MARK: - Landing Page (Sign Up/Sign In Choice)
struct AuthLandingView: View {
    @EnvironmentObject var app: AppState
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // Logo
                Image("App Logo Black")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 300, height: 300)
                
                Spacer()
                
                // Buttons
                VStack(spacing: 16) {
                    // ✅ Use NavigationLink instead of manual state + navigationDestination
                    NavigationLink {
                        SignUpView()
                    } label: {
                        Text("Sign Up")
                            .font(.custom("Montserrat", size: 16))
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(hex: "2AC33C"))
                            .cornerRadius(10)
                    }
                    
                    NavigationLink {
                        SignInView()
                    } label: {
                        Text("Sign In")
                            .font(.custom("Montserrat", size: 16))
                            .fontWeight(.semibold)
                            .foregroundColor(Color(hex: "2AC33C"))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color(hex: "2AC33C"), lineWidth: 2)
                            )
                    }
                    
                    // 🚧 DEV BYPASS BUTTON — lets you skip the auth wall
                    Button(action: {
                        app.userFirstName = "Dev"
                        app.userLastName = "User"
                        app.userEmail = "dev@plasticprophet.test"
                        app.isAuthenticated = true
                    }) {
                        Text("Skip for now (Dev)")
                            .font(.custom("Montserrat", size: 14))
                            .fontWeight(.medium)
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity)
                            .padding(10)
                    }
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 60)
            }
        }
    }
}

#Preview("Landing") {
    NavigationStack {
        AuthLandingView()
            .environmentObject(AppState())
    }
}

// MARK: - Sign In View
// MARK: - Sign In View
struct SignInView: View {
    @EnvironmentObject var app: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var showPassword: Bool = false
    @State private var showForgotPassword = false
    @FocusState private var focusedField: SignInField?
    
    enum SignInField {
        case email, password
    }
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 24) {
                // Card icon
                Image(systemName: "creditcard.fill")
                    .font(.system(size: 50))
                    .foregroundColor(Color.ppGreen)
                    .rotationEffect(.degrees(15))
                    .padding(.top, 20)
                
                Text("Sign In")
                    .font(.custom("Montserrat", size: 32))
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                
                VStack(alignment: .leading, spacing: 16) {
                    // Email
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email Address")
                            .font(.custom("Montserrat", size: 14))
                            .fontWeight(.medium)
                            .foregroundColor(.black)
                        
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
                            .foregroundColor(.black)
                        
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
                    
                    // Forgot Password
                    Button(action: { showForgotPassword = true }) {
                        Text("Forgot Password?")
                            .font(.custom("Montserrat", size: 14))
                            .foregroundColor(.gray)
                    }
                }
                .padding(.top, 20)
                
                Spacer()
                
                // Sign In Button
                Button(action: signIn) {
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
                .disabled(email.isEmpty || password.isEmpty)
                .opacity(email.isEmpty || password.isEmpty ? 0.5 : 1.0)
                .padding(.bottom, 40)
            }
            .padding(.horizontal, 32)
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
        .navigationDestination(isPresented: $showForgotPassword) {
            ForgotPasswordView()
        }
    }
    
    private func signIn() {
        Task {
            await app.signIn(email: email, password: password)
            // Dismiss this view after successful sign-in so ContentView can switch to the next screen
            if app.isAuthenticated {
                dismiss()
            }
        }
    }
}

// MARK: - Sign Up View
struct SignUpView: View {
    @EnvironmentObject var app: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var showPassword: Bool = false
    @State private var showConfirmPassword: Bool = false
    @FocusState private var focusedField: SignUpField?
    @State private var showVerification = false
    @State private var signUpEmail = ""
    
    enum SignUpField {
        case firstName, lastName, email, password, confirmPassword
    }
    
    private var isValidPassword: Bool {
        password.count >= 8 &&
        password.range(of: "[A-Z]", options: .regularExpression) != nil &&
        password.range(of: "[a-z]", options: .regularExpression) != nil &&
        password.range(of: "[^A-Za-z0-9]", options: .regularExpression) != nil
    }
    
    private var canSignUp: Bool {
        !firstName.isEmpty &&
        !lastName.isEmpty &&
        !email.isEmpty &&
        isValidPassword &&
        password == confirmPassword
    }
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Card icon
                    Image(systemName: "creditcard.fill")
                        .font(.system(size: 50))
                        .foregroundColor(Color.ppGreen)
                        .rotationEffect(.degrees(15))
                        .padding(.top, 20)
                    
                    // First Name
                    VStack(alignment: .leading, spacing: 8) {
                        Text("First Name")
                            .font(.custom("Montserrat", size: 14))
                            .fontWeight(.medium)
                            .foregroundColor(.black)
                        
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
                            .foregroundColor(.black)
                        
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
                            .foregroundColor(.black)
                        
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
                            .foregroundColor(.black)
                        
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
                            .foregroundColor(.black)
                        
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
                        .foregroundColor(.black)
                        .font(.system(size: 20))
                }
            }
        }
        .sheet(isPresented: $showVerification) {
            CognitoVerificationView(email: signUpEmail)
                .environmentObject(app)
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
}
        
        // MARK: - Forgot Password View
        struct ForgotPasswordView: View {
            @Environment(\.dismiss) private var dismiss
            @State private var email: String = ""
            @State private var showVerification = false
            @FocusState private var emailFocused: Bool
            
            var body: some View {
                ZStack {
                    Color.white.ignoresSafeArea()
                    
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
                            .foregroundColor(.black)
                        
                        // Email
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email Address")
                                .font(.custom("Montserrat", size: 14))
                                .fontWeight(.medium)
                                .foregroundColor(.black)
                            
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
                        Button(action: { showVerification = true }) {
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
                                .foregroundColor(.black)
                                .font(.system(size: 20))
                        }
                    }
                }
                .navigationDestination(isPresented: $showVerification) {
                    VerificationCodeView(email: email)
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
                    Color.white.ignoresSafeArea()
                    
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
                                .foregroundColor(.black)
                            HStack(spacing: 4) {
                                Text("code to")
                                    .font(.custom("Montserrat", size: 16))
                                    .foregroundColor(.black)
                                Text(email)
                                    .font(.custom("Montserrat", size: 16))
                                    .fontWeight(.bold)
                                    .foregroundColor(Color.ppGreen)
                                Text(".")
                                    .font(.custom("Montserrat", size: 16))
                                    .foregroundColor(.black)
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
                                .foregroundColor(.black)
                                .font(.system(size: 20))
                        }
                    }
                }
                .navigationDestination(isPresented: $showResetPassword) {
                    ResetPasswordView()
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
            @State private var password: String = ""
            @State private var confirmPassword: String = ""
            @State private var showPassword: Bool = false
            @State private var showConfirmPassword: Bool = false
            @State private var showSuccess = false
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
                    Color.white.ignoresSafeArea()
                    
                    VStack(alignment: .leading, spacing: 24) {
                        // Card icon
                        Image(systemName: "creditcard.fill")
                            .font(.system(size: 50))
                            .foregroundColor(Color.ppGreen)
                            .rotationEffect(.degrees(15))
                            .padding(.top, 20)
                        
                        // Password requirements
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .font(.custom("Montserrat", size: 14))
                                .fontWeight(.semibold)
                                .foregroundColor(.black)
                            
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
                        
                        // Password
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
                        
                        // Confirm Password
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Confirm Password")
                                .font(.custom("Montserrat", size: 14))
                                .fontWeight(.medium)
                                .foregroundColor(.black)
                            
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
                        
                        Spacer()
                        
                        // Enter Button
                        Button(action: resetPassword) {
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
                                .foregroundColor(.black)
                                .font(.system(size: 20))
                        }
                    }
                }
                .alert("Password Reset", isPresented: $showSuccess) {
                    Button("OK") {
                        // Pop back to sign in
                        dismiss()
                    }
                } message: {
                    Text("Your password has been successfully reset. Please sign in with your new password.")
                }
            }
            
            private func resetPassword() {
                // TODO: Add real password reset
                showSuccess = true
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
    
