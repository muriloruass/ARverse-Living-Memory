//
//  LoginView.swift
//  ArProject
//
//  Created by Murilo Ruas Lucena on 2025-10-02.
//

import SwiftUI
import Combine

/// Login and registration screen for ARverse Living Memory
struct LoginView: View {
    @ObservedObject var authManager: AuthManager
    @State private var isRegistering = false
    
    // Login fields
    @State private var usernameOrEmail = ""
    @State private var password = ""
    
    // Registration fields
    @State private var newUsername = ""
    @State private var newEmail = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    
    @State private var isLoading = false
    
    var body: some View {
        ZStack {
            // AR-themed gradient background
            LinearGradient(
                colors: [
                    Color.black,
                    Color.blue.opacity(0.3),
                    Color.purple.opacity(0.2),
                    Color.black
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // App logo and title
                VStack(spacing: 15) {
                    // AR-style logo
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 100, height: 100)
                        
                        Image(systemName: "camera.viewfinder")
                            .font(.system(size: 40, weight: .light))
                            .foregroundColor(.white)
                    }
                    
                    VStack(spacing: 5) {
                        Text("ARverse")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Living Memory")
                            .font(.title3)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.top, 20)
                
                // Form container
                VStack(spacing: 25) {
                    if isRegistering {
                        registrationForm
                    } else {
                        loginForm
                    }
                }
                .padding(.horizontal, 30)
                
                Spacer()
                
                // Switch between login/register
                switchModeButton
                
                // Debug button (for testing - remove in production)
                VStack(spacing: 10) {
                    Button("🧹 Clear All Data (DEBUG)") {
                        authManager.clearAllStoredData()
                    }
                    .font(.caption)
                    .foregroundColor(.red)
                    
                    Button("📊 Show Debug Info") {
                        authManager.debugStoredData()
                    }
                    .font(.caption)
                    .foregroundColor(.orange)
                    
                    Button("🔄 Force UserDefaults Sync") {
                        let success = UserDefaults.standard.synchronize()
                        print("🔄 Manual sync result: \(success)")
                        authManager.debugStoredData()
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                    
                    Button("🔧 Fix Login Issues") {
                        authManager.migrateOldHashFormat()
                    }
                    .font(.caption)
                    .foregroundColor(.green)
                }
                .padding(.top, 10)
                
                // Error message
                if let error = authManager.authError {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
            .padding()
        }
        .preferredColorScheme(.dark)
    }
    
    // MARK: - Login Form
    
    private var loginForm: some View {
        VStack(spacing: 20) {
            Text("Welcome back!")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            VStack(spacing: 15) {
                // Username/Email field
                HStack {
                    Image(systemName: "person.circle")
                        .foregroundColor(.gray)
                        .frame(width: 20)
                    
                    TextField("Username or Email", text: $usernameOrEmail)
                        .textFieldStyle(.plain)
                        .foregroundColor(.white)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(12)
                
                // Password field
                HStack {
                    Image(systemName: "lock.circle")
                        .foregroundColor(.gray)
                        .frame(width: 20)
                    
                    SecureField("Password", text: $password)
                        .textFieldStyle(.plain)
                        .foregroundColor(.white)
                }
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(12)
            }
            
            // Login button
            Button(action: performLogin) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "arrow.right.circle.fill")
                    }
                    Text(isLoading ? "Signing In..." : "Sign In")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(usernameOrEmail.isEmpty || password.isEmpty || isLoading)
        }
    }
    
    // MARK: - Registration Form
    
    private var registrationForm: some View {
        VStack(spacing: 20) {
            Text("Create Account")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            VStack(spacing: 15) {
                // Username field
                HStack {
                    Image(systemName: "person.circle")
                        .foregroundColor(.gray)
                        .frame(width: 20)
                    
                    TextField("Username", text: $newUsername)
                        .textFieldStyle(.plain)
                        .foregroundColor(.white)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(12)
                
                // Email field
                HStack {
                    Image(systemName: "envelope.circle")
                        .foregroundColor(.gray)
                        .frame(width: 20)
                    
                    TextField("Email", text: $newEmail)
                        .textFieldStyle(.plain)
                        .foregroundColor(.white)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .keyboardType(.emailAddress)
                }
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(12)
                
                // Password field
                HStack {
                    Image(systemName: "lock.circle")
                        .foregroundColor(.gray)
                        .frame(width: 20)
                    
                    SecureField("Password (min 6 chars)", text: $newPassword)
                        .textFieldStyle(.plain)
                        .foregroundColor(.white)
                }
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(12)
                
                // Confirm password field
                HStack {
                    Image(systemName: "checkmark.circle")
                        .foregroundColor(.gray)
                        .frame(width: 20)
                    
                    SecureField("Confirm Password", text: $confirmPassword)
                        .textFieldStyle(.plain)
                        .foregroundColor(.white)
                }
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(12)
            }
            
            // Register button
            Button(action: performRegistration) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "plus.circle.fill")
                    }
                    Text(isLoading ? "Creating Account..." : "Create Account")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    LinearGradient(
                        colors: [.green, .blue],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(!isValidRegistration || isLoading)
        }
    }
    
    // MARK: - Switch Mode Button
    
    private var switchModeButton: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.3)) {
                isRegistering.toggle()
                authManager.authError = nil
            }
        }) {
            HStack {
                Text(isRegistering ? "Already have an account?" : "Don't have an account?")
                    .foregroundColor(.gray)
                Text(isRegistering ? "Sign In" : "Sign Up")
                    .foregroundColor(.blue)
                    .fontWeight(.semibold)
            }
        }
    }
    
    // MARK: - Validation
    
    private var isValidRegistration: Bool {
        !newUsername.isEmpty &&
        !newEmail.isEmpty &&
        newPassword.count >= 6 &&
        newPassword == confirmPassword &&
        newEmail.contains("@")
    }
    
    // MARK: - Actions
    
    private func performLogin() {
        isLoading = true
        authManager.authError = nil
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let success = authManager.login(usernameOrEmail: usernameOrEmail, password: password)
            isLoading = false
            
            if success {
                // Clear fields
                usernameOrEmail = ""
                password = ""
            }
        }
    }
    
    private func performRegistration() {
        isLoading = true
        authManager.authError = nil
        
        guard newPassword == confirmPassword else {
            authManager.authError = "Passwords don't match."
            isLoading = false
            return
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let success = authManager.register(username: newUsername, email: newEmail, password: newPassword)
            isLoading = false
            
            if success {
                // Debug: show stored data after registration
                authManager.debugStoredData()
                
                // Clear fields
                newUsername = ""
                newEmail = ""
                newPassword = ""
                confirmPassword = ""
            }
        }
    }
}

#Preview {
    LoginView(authManager: AuthManager())
}