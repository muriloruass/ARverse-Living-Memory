//
//  ARCameraView.swift
//  ArProject
//
//  Created by Murilo Ruas Lucena on 2025-10-01.
//

import SwiftUI
import ARKit
import RealityKit

/// View that integrates ARKit with real camera
struct ARCameraView: UIViewRepresentable {
    @ObservedObject var memoryManager: MemoryManager
    @Binding var currentCameraTransform: simd_float4x4?
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        
        // Configure AR session
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal, .vertical]
        config.environmentTexturing = .automatic
        
        // Check if LiDAR is available
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            config.sceneReconstruction = .mesh
        }
        
        arView.session.run(config)
        arView.session.delegate = context.coordinator
        
        // Configure lighting
        arView.automaticallyConfigureSession = false
        arView.environment.lighting.intensityExponent = 1.5
        
        // Store reference
        context.coordinator.arView = arView
        
        print("🚀 ARView with real camera initialized!")
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        // Update memories in scene
        context.coordinator.updateMemories(memoryManager.memories)
    }
    
    func makeCoordinator() -> ARCoordinator {
        ARCoordinator(memoryManager: memoryManager, currentTransform: $currentCameraTransform)
    }
}

/// Coordinator to manage ARKit
class ARCoordinator: NSObject, ARSessionDelegate {
    let memoryManager: MemoryManager
    @Binding var currentCameraTransform: simd_float4x4?
    var arView: ARView?
    private var memoryEntities: [UUID: Entity] = [:]
    
    init(memoryManager: MemoryManager, currentTransform: Binding<simd_float4x4?>) {
        self.memoryManager = memoryManager
        self._currentCameraTransform = currentTransform
    }
    
    // MARK: - ARSessionDelegate
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        // Update camera position
        DispatchQueue.main.async {
            self.currentCameraTransform = frame.camera.transform
        }
    }
    
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        print("🎯 \(anchors.count) anchors detected")
    }
    
    // MARK: - Memory Management
    
    func updateMemories(_ memories: [Memory]) {
        guard let arView = arView else { return }
        
        // Add new memories
        for memory in memories {
            if memoryEntities[memory.id] == nil {
                let entity = createMemoryEntity(for: memory)
                arView.scene.addAnchor(entity)
                memoryEntities[memory.id] = entity
                print("📍 Memory added: \(memory.text)")
            }
        }
        
        // Remove deleted memories
        let currentMemoryIds = Set(memories.map { $0.id })
        for (id, entity) in memoryEntities {
            if !currentMemoryIds.contains(id) {
                entity.removeFromParent()
                memoryEntities.removeValue(forKey: id)
            }
        }
    }
    
    private func createMemoryEntity(for memory: Memory) -> AnchorEntity {
        // Create anchor at memory position
        let anchor = AnchorEntity(world: memory.position)
        
        if let photo = memory.photo {
            // Create photo display
            let photoEntity = createPhotoEntity(image: photo, text: memory.text)
            anchor.addChild(photoEntity)
        } else {
            // Create text-only display
            let textEntity = createTextOnlyEntity(text: memory.text)
            anchor.addChild(textEntity)
        }
        
        return anchor
    }
    
    private func createPhotoEntity(image: UIImage, text: String) -> Entity {
        let entity = Entity()
        
        // Criar material com a foto
        var material = UnlitMaterial()
        do {
            let texture = try TextureResource.generate(from: image.cgImage!, options: .init(semantic: .color))
            material.color = .init(texture: .init(texture))
        } catch {
            print("❌ Error creating texture: \(error)")
            material.color = .init(tint: .blue)
        }
        
        // Create plane to show the photo
        let mesh = MeshResource.generatePlane(width: 0.2, height: 0.15)
        entity.components.set(ModelComponent(mesh: mesh, materials: [material]))
        
        // Add text below the photo
        let textEntity = Entity()
        let textMesh = MeshResource.generateText(
            text,
            extrusionDepth: 0.01,
            font: .systemFont(ofSize: 0.02),
            containerFrame: CGRect(x: -0.1, y: -0.1, width: 0.2, height: 0.05),
            alignment: .center,
            lineBreakMode: .byTruncatingTail
        )
        let textMaterial = SimpleMaterial(color: .white, isMetallic: false)
        textEntity.components.set(ModelComponent(mesh: textMesh, materials: [textMaterial]))
        textEntity.position = [0, -0.1, 0]
        entity.addChild(textEntity)
        
        // Make photo always look at camera
        entity.components.set(BillboardComponent())
        
        return entity
    }
    
    private func createTextOnlyEntity(text: String) -> Entity {
        let entity = Entity()
        
        // Create blue sphere
        let sphereMesh = MeshResource.generateSphere(radius: 0.05)
        let sphereMaterial = SimpleMaterial(color: .systemBlue, roughness: 0.2, isMetallic: false)
        entity.components.set(ModelComponent(mesh: sphereMesh, materials: [sphereMaterial]))
        
        // Add text
        let textEntity = Entity()
        let textMesh = MeshResource.generateText(
            text,
            extrusionDepth: 0.01,
            font: .systemFont(ofSize: 0.03),
            containerFrame: CGRect(x: -0.15, y: 0, width: 0.3, height: 0.1),
            alignment: .center,
            lineBreakMode: .byWordWrapping
        )
        let textMaterial = SimpleMaterial(color: .white, isMetallic: false)
        textEntity.components.set(ModelComponent(mesh: textMesh, materials: [textMaterial]))
        textEntity.position = [0, 0.1, 0]
        entity.addChild(textEntity)
        
        // Billboard para sempre olhar para a câmera
        textEntity.components.set(BillboardComponent())
        
        return entity
    }
    
    /// Captures current camera position for new memory
    func getCurrentCameraPosition() -> SIMD3<Float> {
        guard let transform = currentCameraTransform else {
            return SIMD3<Float>(0, 0, -0.5)
        }
        
        // Position memory 50cm in front of camera
        let cameraPosition = SIMD3<Float>(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)
        let cameraForward = -SIMD3<Float>(transform.columns.2.x, transform.columns.2.y, transform.columns.2.z)
        
        return cameraPosition + (cameraForward * 0.5)
    }
}