//
//  MemoryDetailView.swift
//  ArProject
//
//  Created by Murilo Ruas Lucena on 2025-10-02.
//

import SwiftUI
import MapKit

/// Detailed view for a selected memory
struct MemoryDetailView: View {
    let memory: Memory
    @Environment(\.dismiss) private var dismiss
    @State private var showingMap = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Dark AR-themed background
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 25) {
                        // Memory photo (if available)
                        if let photo = memory.photo {
                            photoSection(photo)
                        } else {
                            noPhotoSection
                        }
                        
                        // Memory details
                        detailsSection
                        
                        // Location section
                        locationSection
                        
                        // Metadata
                        metadataSection
                    }
                    .padding()
                }
            }
            .navigationTitle("Memory Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.blue)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    // MARK: - Photo Section
    
    private func photoSection(_ photo: UIImage) -> some View {
        VStack(spacing: 15) {
            // Photo with AR-style border
            Image(uiImage: photo)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxHeight: 300)
                .cornerRadius(15)
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                )
                .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
            
            // Photo info
            HStack {
                Image(systemName: "camera.fill")
                    .foregroundColor(.blue)
                Text("Captured at this location")
                    .font(.caption)
                    .foregroundColor(.gray)
                Spacer()
            }
        }
    }
    
    // MARK: - No Photo Section
    
    private var noPhotoSection: some View {
        VStack(spacing: 15) {
            // AR memory icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                
                Image(systemName: "memories")
                    .font(.system(size: 40, weight: .light))
                    .foregroundColor(.white)
            }
            
            Text("Text Memory")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(.vertical)
    }
    
    // MARK: - Details Section
    
    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: "quote.bubble.fill")
                    .foregroundColor(.blue)
                Text("Memory Description")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
            }
            
            Text(memory.text)
                .font(.body)
                .foregroundColor(.white)
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(12)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    // MARK: - Location Section
    
    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: "location.fill")
                    .foregroundColor(.green)
                Text("AR Position")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                
                Button(action: { showingMap = true }) {
                    HStack {
                        Image(systemName: "map")
                        Text("View")
                    }
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("X:")
                        .foregroundColor(.gray)
                    Text(String(format: "%.2f", memory.position.x))
                        .foregroundColor(.white)
                        .font(.system(.body, design: .monospaced))
                    
                    Spacer()
                    
                    Text("Y:")
                        .foregroundColor(.gray)
                    Text(String(format: "%.2f", memory.position.y))
                        .foregroundColor(.white)
                        .font(.system(.body, design: .monospaced))
                    
                    Spacer()
                    
                    Text("Z:")
                        .foregroundColor(.gray)
                    Text(String(format: "%.2f", memory.position.z))
                        .foregroundColor(.white)
                        .font(.system(.body, design: .monospaced))
                }
                
                Text("Coordinates in 3D space relative to tracking origin")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
        }
        .sheet(isPresented: $showingMap) {
            // Simple coordinates display (in real app, could show actual map)
            NavigationView {
                VStack {
                    Text("3D Coordinates")
                        .font(.title2)
                        .padding()
                    
                    Text("This memory is positioned at:")
                        .foregroundColor(.gray)
                    
                    Text("X: \(String(format: "%.3f", memory.position.x))")
                    Text("Y: \(String(format: "%.3f", memory.position.y))")
                    Text("Z: \(String(format: "%.3f", memory.position.z))")
                    
                    Spacer()
                }
                .navigationTitle("Location")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            showingMap = false
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Metadata Section
    
    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.orange)
                Text("Memory Info")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
            }
            
            VStack(spacing: 10) {
                infoRow(title: "Created", value: formatDate(memory.createdAt), icon: "calendar")
                infoRow(title: "Type", value: memory.photo != nil ? "Photo + Text" : "Text Only", icon: "doc.text")
                infoRow(title: "ID", value: String(memory.id.uuidString.prefix(8)), icon: "number.circle")
            }
        }
    }
    
    private func infoRow(title: String, value: String, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.gray)
                .frame(width: 20)
            
            Text(title)
                .foregroundColor(.gray)
                .frame(width: 80, alignment: .leading)
            
            Text(value)
                .foregroundColor(.white)
            
            Spacer()
        }
        .padding(.vertical, 5)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    MemoryDetailView(
        memory: Memory(
            text: "Beautiful sunset at the beach. The colors were amazing and the sound of waves was so peaceful.",
            photo: UIImage(systemName: "photo"),
            position: SIMD3<Float>(1.2, 0.5, -2.1),
            userID: UUID()
        )
    )
}
