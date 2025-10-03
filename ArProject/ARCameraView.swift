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
    @ObservedObject var errorManager: ErrorManager
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
        
        // Enable user interaction
        arView.isUserInteractionEnabled = true
        
        // Add tap gesture for memory interaction
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handleTap(_:)))
        tapGesture.numberOfTapsRequired = 1
        arView.addGestureRecognizer(tapGesture)
        
        // Store reference
        context.coordinator.arView = arView
        
        print("🚀 ARView with real camera initialized!")
        print("🔧 Tap gesture configured for memory interaction")
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        // Update memories in scene
        context.coordinator.updateMemories(memoryManager.memories)
    }
    
    func makeCoordinator() -> ARCoordinator {
        ARCoordinator(memoryManager: memoryManager, errorManager: errorManager, currentTransform: $currentCameraTransform)
    }
}

/// Coordinator to manage ARKit
class ARCoordinator: NSObject, ARSessionDelegate {
    let memoryManager: MemoryManager
    let errorManager: ErrorManager
    @Binding var currentCameraTransform: simd_float4x4?
    var arView: ARView?
    private var memoryEntities: [UUID: Entity] = [:]
    
    init(memoryManager: MemoryManager, errorManager: ErrorManager, currentTransform: Binding<simd_float4x4?>) {
        self.memoryManager = memoryManager
        self.errorManager = errorManager
        self._currentCameraTransform = currentTransform
    }
    
    // MARK: - ARSessionDelegate
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        // Update camera position
        DispatchQueue.main.async {
            self.currentCameraTransform = frame.camera.transform
            // Monitor tracking state
            self.errorManager.handleTrackingState(frame.camera.trackingState)
        }
    }
    
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        print("🎯 \(anchors.count) anchors detected")
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        DispatchQueue.main.async {
            if let arError = error as? ARError {
                switch arError.code {
                case .cameraUnauthorized:
                    self.errorManager.showError(.cameraPermissionDenied)
                case .unsupportedConfiguration:
                    self.errorManager.showError(.arNotSupported)
                default:
                    self.errorManager.showError(.trackingLost)
                }
            }
        }
    }
    
    // MARK: - Memory Management
    
    func updateMemories(_ memories: [Memory]) {
        guard let arView = arView else { return }
        
        // Add new memories
        for memory in memories {
            if memoryEntities[memory.id] == nil {
                // Create floating bubble entity from MemoryManager
                let memoryEntity = memoryManager.createMemoryEntity(for: memory)
                
                // Create anchor to position it in world space with better precision
                let anchor = AnchorEntity(world: memory.position)
                anchor.addChild(memoryEntity)
                
                // Reset the entity position to (0,0,0) since the anchor handles world positioning
                memoryEntity.position = SIMD3<Float>(0, 0, 0)
                
                arView.scene.addAnchor(anchor)
                memoryEntities[memory.id] = anchor
                print("✨ Floating memory added: \(memory.text) at world position \(memory.position)")
            }
        }
        
        // Remove deleted memories
        let currentMemoryIds = Set(memories.map { $0.id })
        for (id, entity) in memoryEntities {
            if !currentMemoryIds.contains(id) {
                entity.removeFromParent()
                memoryEntities.removeValue(forKey: id)
                print("🗑️ Memory removed: \(id)")
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
    
    // MARK: - Tap Gesture Handling
    
    @objc func handleTap(_ gesture: UITapGestureRecognizer) {
        guard let arView = arView else { return }
        
        let location = gesture.location(in: arView)
        print("👆 Tap detected at location: \(location)")
        
        // Perform hit test on AR content
        let hitResults = arView.hitTest(location)
        print("🎯 Hit test found \(hitResults.count) results")
        
        for (index, result) in hitResults.enumerated() {
            print("🔍 Hit \(index): entity \(result.entity)")
            
            // Check if tapped entity has a MemoryComponent
            if let memoryComponent = result.entity.components[MemoryComponent.self] {
                print("✅ Found MemoryComponent on entity!")
                // Found a memory! Show details
                DispatchQueue.main.async {
                    self.memoryManager.showMemoryDetail(memoryComponent.memory)
                    
                    // Haptic feedback
                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                    impactFeedback.impactOccurred()
                }
                return
            }
            
            // Also check parent entities in case the tap hit a child
            var currentEntity = result.entity.parent
            var parentLevel = 1
            while currentEntity != nil {
                print("🔍 Checking parent level \(parentLevel): \(currentEntity!)")
                if let memoryComponent = currentEntity?.components[MemoryComponent.self] {
                    print("✅ Found MemoryComponent on parent entity level \(parentLevel)!")
                    DispatchQueue.main.async {
                        self.memoryManager.showMemoryDetail(memoryComponent.memory)
                        
                        // Haptic feedback
                        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                        impactFeedback.impactOccurred()
                    }
                    return
                }
                currentEntity = currentEntity?.parent
                parentLevel += 1
            }
        }
        
        print("❌ No memory entities found in tap results")
    }
}