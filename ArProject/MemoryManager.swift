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
    
    private var memoryEntities: [UUID: Entity] = [:]
    
    
    /// Registers that AR is ready
    func setReady() {
        self.isReady = true
    }
    
    /// Adds a new memory anchored at current camera position
    func addMemory(text: String, photo: UIImage? = nil, at position: SIMD3<Float>) {
        let memory = Memory(text: text, photo: photo, position: position)
        memories.append(memory)
        
        let photoInfo = photo != nil ? "with photo" : "text only"
        print("💭 Memory added: '\(text)' (\(photoInfo)) at position \(position)")
    }
    
    /// Creates the visual entity for a memory in AR space
    func createMemoryEntity(for memory: Memory) -> Entity {
        // Create sphere representing the memory
        let sphere = Entity()
        let mesh = MeshResource.generateSphere(radius: 0.05)
        let material = SimpleMaterial(color: .systemBlue, roughness: 0.2, isMetallic: false)
        sphere.components.set(ModelComponent(mesh: mesh, materials: [material]))
        
        // Add custom component for identification
        sphere.components.set(MemoryComponent(memory: memory))
        
        // Position the memory
        sphere.position = memory.position
        
        // Store reference
        memoryEntities[memory.id] = sphere
        
        print("🌟 Visual entity created for memory: \(memory.text)")
        return sphere
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
        memories.removeAll()
        
        for (_, entity) in memoryEntities {
            entity.removeFromParent()
        }
        memoryEntities.removeAll()
        
        print("🧹 All memories have been cleared")
    }
    
    /// Retorna uma memória próxima à posição especificada (raio de 50cm)
    func findNearbyMemory(at position: SIMD3<Float>, radius: Float = 0.5) -> Memory? {
        return memories.first { memory in
            let distance = simd_distance(memory.position, position)
            return distance <= radius
        }
    }
    
    /// Retorna todas as entidades de memória para serem adicionadas à cena
    func getAllMemoryEntities() -> [Entity] {
        return Array(memoryEntities.values)
    }
}

// Não precisamos mais da extensão float4x4 para esta versão simplificada
