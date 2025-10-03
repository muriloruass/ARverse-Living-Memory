//
//  MemoryManager.swift
//  ArProject
//
//  Created by Murilo Ruas Lucena on 2025-10-01.
//

import Foundation
import RealityKit
import SwiftUI
import simd
import Combine

/// Main AR memories manager - the heart of ARverse Living Memory
@MainActor
class MemoryManager: ObservableObject {
    @Published var memories: [Memory] = []
    @Published var isReady = false
    @Published var selectedMemory: Memory?
    @Published var showingMemoryDetail = false
    
    private var memoryEntities: [UUID: Entity] = [:]
    private let userDefaults = UserDefaults.standard
    private var currentUserID: UUID?
    private var animationTimer: Timer?
    
    init() {
        startFloatingAnimation()
    }
    
    deinit {
        animationTimer?.invalidate()
    }
    
    /// Sets current user and loads their memories
    func setCurrentUser(_ userID: UUID) {
        Task { @MainActor in
            print("🔄 Setting current user: \(userID)")
            currentUserID = userID
            loadMemoriesForCurrentUser()
            print("📱 Loaded \(memories.count) memories for user")
        }
    }
    
    /// Registers that AR is ready
    func setReady() {
        self.isReady = true
    }
    
    /// Adds a new memory anchored at current camera position
    func addMemory(text: String, photo: UIImage? = nil, at position: SIMD3<Float>) {
        guard let userID = currentUserID else { 
            print("❌ No current user set - cannot add memory")
            return 
        }
        
        Task { @MainActor in
            print("💭 Adding memory for user: \(userID)")
            print("📝 Text: '\(text)'")
            print("📷 Has photo: \(photo != nil)")
            print("📍 Position: \(position)")
            
            let memory = Memory(text: text, photo: photo, position: position, userID: userID)
            memories.append(memory)
            
            print("📚 Total memories now: \(memories.count)")
            
            saveMemoriesToStorage()
            
            let photoInfo = photo != nil ? "with photo" : "text only"
            print("✅ Memory added successfully: '\(text)' (\(photoInfo)) at position \(position)")
        }
    }
    
    /// Shows memory details
    func showMemoryDetail(_ memory: Memory) {
        Task { @MainActor in
            selectedMemory = memory
            showingMemoryDetail = true
        }
    }
    
    /// Creates enhanced visual entity for a memory in AR space - floating bubble style
    func createMemoryEntity(for memory: Memory) -> Entity {
        let container = Entity()
        
        // Main sphere (floating bubble) - smaller for better precision
        let sphere = Entity()
        let mesh = MeshResource.generateSphere(radius: 0.06) // Reduced from 0.08
        
        // Different colors for photo vs text memories
        let baseColor: UIColor = memory.photo != nil ? .systemBlue : .systemPurple
        let material = SimpleMaterial(
            color: baseColor,
            roughness: 0.1,
            isMetallic: false
        )
        
        sphere.components.set(ModelComponent(mesh: mesh, materials: [material]))
        
        // Add subtle glow effect with outer sphere
        let glowSphere = Entity()
        let glowMesh = MeshResource.generateSphere(radius: 0.09) // Reduced from 0.12
        let glowMaterial = SimpleMaterial(
            color: baseColor.withAlphaComponent(0.3),
            roughness: 0.0,
            isMetallic: false
        )
        glowSphere.components.set(ModelComponent(mesh: glowMesh, materials: [glowMaterial]))
        
        // Add collision component to make the sphere tappable
        let shape = ShapeResource.generateSphere(radius: 0.09)
        sphere.components.set(CollisionComponent(shapes: [shape]))
        
        // Add components
        container.addChild(glowSphere)
        container.addChild(sphere)
        
        // IMPORTANT: Add MemoryComponent to both container AND sphere for better hit detection
        container.components.set(MemoryComponent(memory: memory))
        sphere.components.set(MemoryComponent(memory: memory))
        
        // Position the memory - use exact position without floating animation initially
        container.position = memory.position
        
        // Add simple floating animation using periodic transform
        let floatComponent = PeriodicFloatComponent()
        sphere.components.set(floatComponent)
        
        // Store reference
        memoryEntities[memory.id] = container
        
        print("✨ Enhanced floating bubble created for memory: \(memory.text) at \(memory.position)")
        print("🔧 Added collision and memory components for tap detection")
        return container
    }
    
    /// Creates a simple 3D text entity to display memory content
    private func createTextEntity(for memory: Memory) -> Entity {
        let textEntity = Entity()
        
        // For simplicity, we'll just return a small sphere
        // 3D text can be added in future versions
        let textMesh = MeshResource.generateSphere(radius: 0.02)
        let textMaterial = SimpleMaterial(color: .white, isMetallic: false)
        textEntity.components.set(ModelComponent(mesh: textMesh, materials: [textMaterial]))
        
        return textEntity
    }
    
    /// Removes a specific memory
    func removeMemory(_ memory: Memory) {
        memories.removeAll { $0.id == memory.id }
        
        if let entity = memoryEntities[memory.id] {
            entity.removeFromParent()
            memoryEntities.removeValue(forKey: memory.id)
        }
        
        print("🗑️ Memory removed: \(memory.text)")
    }
    
    /// Clears all memories
    func clearAllMemories() {
        Task { @MainActor in
            memories.removeAll()
            saveMemoriesToStorage()
            
            for (_, entity) in memoryEntities {
                entity.removeFromParent()
            }
            memoryEntities.removeAll()
            
            print("🧹 All memories have been cleared")
        }
    }
    
    /// Finds nearby memory for tap detection
    func findNearbyMemory(at position: SIMD3<Float>, radius: Float = 0.5) -> Memory? {
        return memories.first { memory in
            let distance = simd_distance(memory.position, position)
            return distance <= radius
        }
    }
    
    /// Returns all memory entities for AR scene
    func getAllMemoryEntities() -> [Entity] {
        return Array(memoryEntities.values)
    }
    
    // MARK: - Persistence
    
    /// Saves memories to UserDefaults for current user
    private func saveMemoriesToStorage() {
        guard let userID = currentUserID else { 
            print("❌ Cannot save memories - no current user ID")
            return 
        }
        
        let key = "ARverse_Memories_\(userID.uuidString)"
        print("💾 Saving \(memories.count) memories with key: \(key)")
        
        if let data = try? JSONEncoder().encode(memories) {
            userDefaults.set(data, forKey: key)
            userDefaults.synchronize() // Force synchronization
            print("✅ Successfully saved \(memories.count) memories for user")
            
            // Verify the save by trying to load it back
            if let savedData = userDefaults.data(forKey: key),
               let verifyMemories = try? JSONDecoder().decode([Memory].self, from: savedData) {
                print("✅ Verification: \(verifyMemories.count) memories saved and verified")
            } else {
                print("❌ Verification failed - could not read back saved data")
            }
        } else {
            print("❌ Failed to encode memories for saving")
        }
    }
    
    /// Loads memories from storage for current user
    private func loadMemoriesForCurrentUser() {
        guard let userID = currentUserID else { return }
        
        let key = "ARverse_Memories_\(userID.uuidString)"
        
        guard let data = userDefaults.data(forKey: key),
              let loadedMemories = try? JSONDecoder().decode([Memory].self, from: data) else {
            memories = []
            print("📱 No saved memories found for user")
            return
        }
        
        memories = loadedMemories
        print("📂 Loaded \(memories.count) memories for user")
    }
    
    /// Clears all stored memories for current user
    func clearStoredMemories() {
        guard let userID = currentUserID else { return }
        
        let key = "ARverse_Memories_\(userID.uuidString)"
        userDefaults.removeObject(forKey: key)
        
        clearAllMemories()
        print("🗑️ Cleared all stored memories for user")
    }
    
    // MARK: - Animation System
    
    /// Starts the floating animation timer
    private func startFloatingAnimation() {
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { [weak self] _ in
            self?.updateFloatingAnimation()
        }
    }
    
    /// Updates floating animation for all memory entities
    private func updateFloatingAnimation() {
        let time = Date().timeIntervalSince1970
        
        for (_, entity) in memoryEntities {
            // Find the sphere child that should float
            for child in entity.children {
                if child.components.has(PeriodicFloatComponent.self) {
                    let offset = Float(sin(time * 2.0)) * 0.02
                    child.transform.translation.y = offset
                }
            }
        }
    }
}

/// Simple component for floating animation
struct PeriodicFloatComponent: Component {
    // Marker component for floating entities
}
