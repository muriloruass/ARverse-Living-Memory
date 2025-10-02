//
//  ContentView.swift
//  ArProject
//
//  Created by Murilo Ruas Lucena on 2025-10-01.
//

import SwiftUI
import RealityKit
import ARKit

/// Main screen of ARverse Living Memory
struct ContentView: View {
    @StateObject private var memoryManager = MemoryManager()
    @State private var showingAddMemory = false
    @State private var currentCameraTransform: simd_float4x4?
    
    var body: some View {
        ZStack {
            // ARView with real camera
            ARCameraView(
                memoryManager: memoryManager,
                currentCameraTransform: $currentCameraTransform
            )
            .edgesIgnoringSafeArea(.all)
            .onTapGesture(count: 2) { location in
                // Double tap to add memory
                addMemoryAtCurrentPosition()
            }
            
            // Interface overlay
            VStack {
                // Header
                HStack {
                    VStack(alignment: .leading) {
                        Text("ARverse")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        Text("Living Memory")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    // Memory counter
                    Text("\(memoryManager.memories.count) memories")
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.black.opacity(0.6))
                        .foregroundColor(.white)
                        .cornerRadius(15)
                }
                .padding(.horizontal)
                .padding(.top, 50)
                
                Spacer()
                
                // Action buttons
                HStack {
                    Spacer()
                    
                    VStack(spacing: 15) {
                        // Main button - Add memory
                        Button(action: addMemoryAtCurrentPosition) {
                            Image(systemName: "plus")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(width: 60, height: 60)
                                .background(
                                    LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .clipShape(Circle())
                                .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 0)
                        }
                        
                        // Secondary button - Clear memories
                        if !memoryManager.memories.isEmpty {
                            Button(action: clearAllMemories) {
                                Image(systemName: "trash")
                                    .font(.title3)
                                    .foregroundColor(.white)
                                    .frame(width: 45, height: 45)
                                    .background(Color.red.opacity(0.8))
                                    .clipShape(Circle())
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 50)
            }
            
            // Instructions for the user
            if memoryManager.memories.isEmpty {
                VStack {
                    Spacer()
                    
                    VStack(spacing: 10) {
                        Text("👋 Welcome to ARverse!")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Tap the + button to create your first memory\nor double tap anywhere on screen")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .padding(20)
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(15)
                    .padding(.horizontal)
                    
                    Spacer()
                    Spacer()
                }
            }
        }
        .preferredColorScheme(.dark)
        .statusBarHidden(true)
        .sheet(isPresented: $showingAddMemory) {
            AddMemoryView(
                memoryManager: memoryManager,
                position: getCurrentCameraPosition()
            )
        }
    }
    
    /// Gets current camera position for new memory
    private func getCurrentCameraPosition() -> SIMD3<Float> {
        guard let transform = currentCameraTransform else {
            return SIMD3<Float>(0, 0, -0.5)
        }
        
        // Position memory 50cm in front of camera
        let cameraPosition = SIMD3<Float>(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)
        let cameraForward = -SIMD3<Float>(transform.columns.2.x, transform.columns.2.y, transform.columns.2.z)
        
        return cameraPosition + (cameraForward * 0.5)
    }
    
    /// Adds a memory at current camera position
    private func addMemoryAtCurrentPosition() {
        showingAddMemory = true
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    /// Clears all memories
    private func clearAllMemories() {
        memoryManager.clearAllMemories()
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
}

#Preview {
    ContentView()
}