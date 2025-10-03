//
//  User.swift
//  ArProject
//
//  Created by Murilo Ruas Lucena on 2025-10-02.
//

import Foundation
import Combine

/// User data model for ARverse Living Memory
struct User: Identifiable, Codable, Equatable {
    let id: UUID
    let username: String
    let email: String
    private let passwordHash: String
    let createdAt: Date
    let lastLoginAt: Date
    
    init(username: String, email: String, password: String) {
        self.id = UUID()
        self.username = username
        self.email = email
        self.passwordHash = User.hashPassword(password)
        self.createdAt = Date()
        self.lastLoginAt = Date()
    }
    
    /// Creates a copy with updated login time
    func withUpdatedLoginTime() -> User {
        var copy = self
        copy = User(
            id: self.id,
            username: self.username,
            email: self.email,
            passwordHash: self.passwordHash,
            createdAt: self.createdAt,
            lastLoginAt: Date()
        )
        return copy
    }
    
    /// Private init for creating copies
    private init(id: UUID, username: String, email: String, passwordHash: String, createdAt: Date, lastLoginAt: Date) {
        self.id = id
        self.username = username
        self.email = email
        self.passwordHash = passwordHash
        self.createdAt = createdAt
        self.lastLoginAt = lastLoginAt
    }
    
    /// Verifies if the provided password is correct
    func verifyPassword(_ password: String) -> Bool {
        let inputHash = User.hashPassword(password)
        let isValid = inputHash == passwordHash
        print("🔐 Password verification:")
        print("   Input: '\(password)' -> Hash: \(inputHash)")
        print("   Stored hash: \(passwordHash)")
        print("   Match: \(isValid)")
        return isValid
    }
    
    /// Simple password hashing (in production, use proper crypto)
    /// Using a consistent hash method that works across app restarts
    private static func hashPassword(_ password: String) -> String {
        // Using a simple but consistent hash method
        var hash = 0
        for char in password.utf8 {
            hash = ((hash &* 31) &+ Int(char)) & Int.max
        }
        return String(hash)
    }
}

/// Authentication manager for user login/registration
@MainActor
class AuthManager: ObservableObject {
    @Published var currentUser: User?
    @Published var isLoggedIn = false
    @Published var showingLogin = false
    @Published var authError: String?
    
    private let userDefaults = UserDefaults.standard
    private let usersKey = "ARverse_Users"
    private let currentUserKey = "ARverse_CurrentUser"
    
    init() {
        print("🚀 AuthManager initializing...")
        print("🔑 Will use keys: users='\(usersKey)', currentUser='\(currentUserKey)'")
        
        // Check what data exists on startup
        debugStoredData()
        
        loadCurrentUser()
        print("🚀 AuthManager initialization complete")
    }
    
    /// Register a new user
    func register(username: String, email: String, password: String) -> Bool {
        // Validate input
        guard !username.isEmpty, !email.isEmpty, password.count >= 6 else {
            authError = "Please fill all fields. Password must be at least 6 characters."
            return false
        }
        
        // Check if user already exists
        if userExists(username: username, email: email) {
            authError = "User with this username or email already exists."
            return false
        }
        
        // Create new user
        let newUser = User(username: username, email: email, password: password)
        
        // Save to storage FIRST
        saveUser(newUser)
        
        // Wait a moment to ensure data is saved before login
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            // Login automatically
            self.login(user: newUser)
            
            print("✅ User registered: \(username)")
        }
        
        return true
    }
    
    /// Login with username/email and password
    func login(usernameOrEmail: String, password: String) -> Bool {
        let users = loadAllUsers()
        print("🔍 Attempting login for: '\(usernameOrEmail)'")
        print("📚 Total users in storage: \(users.count)")
        
        // Debug: print all users (without sensitive info)
        for user in users {
            print("👤 User: \(user.username) (\(user.email))")
        }
        
        // Find user by username or email
        guard let user = users.first(where: { 
            $0.username == usernameOrEmail || $0.email == usernameOrEmail 
        }) else {
            authError = "User not found."
            print("❌ User not found in storage")
            return false
        }
        
        print("✅ User found: \(user.username)")
        
        // Verify password
        guard user.verifyPassword(password) else {
            authError = "Incorrect password."
            print("❌ Password verification failed")
            return false
        }
        
        print("✅ Password verified successfully")
        
        // Update last login
        let updatedUser = user.withUpdatedLoginTime()
        updateUser(updatedUser)
        
        login(user: updatedUser)
        return true
    }
    
    /// Login with user object
    private func login(user: User) {
        Task { @MainActor in
            print("🔄 Starting login for user: \(user.username)")
            currentUser = user
            isLoggedIn = true
            authError = nil
            
            // Save current user
            if let userData = try? JSONEncoder().encode(user) {
                userDefaults.set(userData, forKey: currentUserKey)
                print("💾 User data saved to UserDefaults")
            }
            
            print("✅ User logged in successfully: \(user.username)")
            print("🔍 isLoggedIn = \(isLoggedIn)")
        }
    }
    
    /// Logout current user
    func logout() {
        Task { @MainActor in
            currentUser = nil
            isLoggedIn = false
            userDefaults.removeObject(forKey: currentUserKey)
            print("👋 User logged out")
        }
    }
    
    /// Load current user from storage
    private func loadCurrentUser() {
        // Disabled auto-login to force users to login each time
        // This prevents the issue where users appear logged in by default
        print("🔐 Auto-login disabled - users must login manually")
        return
        
        /*
        guard let userData = userDefaults.data(forKey: currentUserKey),
              let user = try? JSONDecoder().decode(User.self, from: userData) else {
            // No user stored, stay in login state
            return
        }
        
        currentUser = user
        isLoggedIn = true
        print("📱 Auto-loaded user: \(user.username)")
        */
    }
    
    /// Save user to storage
    private func saveUser(_ user: User) {
        var users = loadAllUsers()
        users.append(user)
        
        print("💾 Saving user: \(user.username)")
        print("📚 Total users to save: \(users.count)")
        print("🔑 Using key: \(usersKey)")
        
        do {
            let data = try JSONEncoder().encode(users)
            userDefaults.set(data, forKey: usersKey)
            
            // Force synchronization - this is CRITICAL for persistence
            let success = userDefaults.synchronize()
            print("💾 UserDefaults synchronize result: \(success)")
            
            // Wait a moment and verify
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                let verifyUsers = self.loadAllUsers()
                print("✅ Verification: \(verifyUsers.count) users in storage after save")
                if let savedUser = verifyUsers.first(where: { $0.username == user.username }) {
                    print("✅ User verified in storage: \(savedUser.username)")
                    
                    // Double check by reading raw data
                    if let rawData = self.userDefaults.data(forKey: self.usersKey) {
                        print("✅ Raw data exists: \(rawData.count) bytes")
                    } else {
                        print("❌ No raw data found in UserDefaults!")
                    }
                } else {
                    print("❌ User verification failed!")
                }
            }
        } catch {
            print("❌ Failed to encode users: \(error)")
        }
    }
    
    /// Update existing user
    private func updateUser(_ user: User) {
        var users = loadAllUsers()
        print("🔄 Updating user: \(user.username)")
        
        if let index = users.firstIndex(where: { $0.id == user.id }) {
            users[index] = user
            
            do {
                let data = try JSONEncoder().encode(users)
                userDefaults.set(data, forKey: usersKey)
                userDefaults.synchronize()
                print("✅ User updated successfully")
            } catch {
                print("❌ Failed to encode users for update: \(error)")
            }
        } else {
            print("❌ User not found for update")
        }
    }
    
    /// Load all users from storage
    private func loadAllUsers() -> [User] {
        print("📂 Loading users from storage with key: \(usersKey)")
        
        guard let data = userDefaults.data(forKey: usersKey) else {
            print("� No users data found in storage")
            return []
        }
        
        do {
            let users = try JSONDecoder().decode([User].self, from: data)
            print("📂 Loaded \(users.count) users from storage")
            for user in users {
                print("   - \(user.username) (\(user.email))")
            }
            return users
        } catch {
            print("❌ Failed to decode users: \(error)")
            print("❌ Clearing corrupted user data")
            userDefaults.removeObject(forKey: usersKey)
            return []
        }
    }
    
    /// Check if user exists
    private func userExists(username: String, email: String) -> Bool {
        let users = loadAllUsers()
        return users.contains { $0.username == username || $0.email == email }
    }
    
    /// Clear all stored data (for debugging purposes)
    func clearAllStoredData() {
        userDefaults.removeObject(forKey: usersKey)
        userDefaults.removeObject(forKey: currentUserKey)
        
        // Also clear all memory data
        let allKeys = Array(userDefaults.dictionaryRepresentation().keys)
        for key in allKeys {
            if key.hasPrefix("ARverse_Memories_") {
                userDefaults.removeObject(forKey: key)
                print("🗑️ Removed memory data for key: \(key)")
            }
        }
        
        userDefaults.synchronize()
        currentUser = nil
        isLoggedIn = false
        print("🧹 All stored user and memory data cleared")
    }
    
    /// Migrates old hash format to new consistent format
    /// Call this if you have login issues after updating hash method
    func migrateOldHashFormat() {
        print("🔄 Starting hash format migration...")
        var users = loadAllUsers()
        
        // Clear all users and ask them to re-register
        // This is the safest approach since we can't reverse the old hash
        clearAllStoredData()
        
        print("⚠️ Hash format migration complete - all users need to re-register")
        print("ℹ️ This is a one-time migration due to hash method improvement")
    }
    
    /// Debug method to show all stored data
    func debugStoredData() {
        print("📊 === DEBUG: Stored Data ===")
        
        // Test UserDefaults accessibility
        userDefaults.set("test", forKey: "test_key")
        if let testValue = userDefaults.string(forKey: "test_key") {
            print("✅ UserDefaults is working: \(testValue)")
            userDefaults.removeObject(forKey: "test_key")
        } else {
            print("❌ UserDefaults is NOT working!")
        }
        
        // Show users
        let users = loadAllUsers()
        print("👥 Total users: \(users.count)")
        for user in users {
            print("   - \(user.username) (\(user.email)) - Created: \(user.createdAt)")
        }
        
        // Show raw data
        if let rawData = userDefaults.data(forKey: usersKey) {
            print("💾 Raw users data: \(rawData.count) bytes")
        } else {
            print("💾 No raw users data found")
        }
        
        // Show current user
        if let current = currentUser {
            print("👤 Current user: \(current.username)")
        } else {
            print("👤 No current user")
        }
        
        // Show memory keys
        let allKeys = Array(userDefaults.dictionaryRepresentation().keys)
        let memoryKeys = allKeys.filter { $0.hasPrefix("ARverse_Memories_") }
        print("💭 Memory storage keys: \(memoryKeys.count)")
        for key in memoryKeys {
            print("   - \(key)")
        }
        
        print("📊 === END DEBUG ===")
    }
}