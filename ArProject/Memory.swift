//
//  Memory.swift
//  ArProject
//
//  Created by Murilo Ruas Lucena on 2025-10-01.
//

import Foundation
import RealityKit
import simd
import UIKit

/// Data model for a memory anchored in AR space
struct Memory: Identifiable, Codable {
    let id = UUID()
    let text: String
    let photoData: Data? // Memory photo
    let position: SIMD3<Float>
    let createdAt: Date
    
    init(text: String, photo: UIImage? = nil, position: SIMD3<Float>) {
        self.text = text
        self.photoData = photo?.jpegData(compressionQuality: 0.8)
        self.position = position
        self.createdAt = Date()
    }
    
    /// Returns photo as UIImage
    var photo: UIImage? {
        guard let data = photoData else { return nil }
        return UIImage(data: data)
    }
}

/// Custom component to identify memory entities
struct MemoryComponent: Component {
    let memory: Memory
}