//
//  ErrorManager.swift
//  ArProject
//
//  Created by Murilo Ruas Lucena on 2025-10-02.
//

import Foundation
import SwiftUI
import ARKit
import AVFoundation
import Combine

/// Centralized error management for ARverse Living Memory
@MainActor
class ErrorManager: ObservableObject {
    @Published var currentError: ARError?
    @Published var showingAlert = false
    
    /// AR-specific errors that can occur
    enum ARError: LocalizedError, Identifiable {
        case cameraPermissionDenied
        case arNotSupported
        case trackingLimited
        case trackingLost
        case memoryCreationFailed
        case photoCaptureFailed
        case deviceNotSupported
        
        var id: String { localizedDescription }
        
        var errorDescription: String? {
            switch self {
            case .cameraPermissionDenied:
                return "Camera Access Required"
            case .arNotSupported:
                return "AR Not Available"
            case .trackingLimited:
                return "AR Tracking Limited"
            case .trackingLost:
                return "AR Tracking Lost"
            case .memoryCreationFailed:
                return "Memory Creation Failed"
            case .photoCaptureFailed:
                return "Photo Capture Failed"
            case .deviceNotSupported:
                return "Device Not Supported"
            }
        }
        
        var recoverySuggestion: String? {
            switch self {
            case .cameraPermissionDenied:
                return "Please enable camera access in Settings > Privacy & Security > Camera > ARverse Living Memory"
            case .arNotSupported:
                return "Your device doesn't support AR features. ARverse requires iOS 12+ and A9 chip or newer."
            case .trackingLimited:
                return "Move your device slowly and ensure good lighting. Point at surfaces with texture."
            case .trackingLost:
                return "Return to where you started or find a well-lit area with clear features."
            case .memoryCreationFailed:
                return "Please try again. Make sure you have enough storage space."
            case .photoCaptureFailed:
                return "Check camera permissions and try taking the photo again."
            case .deviceNotSupported:
                return "ARverse requires iPhone 6s or newer with iOS 12+."
            }
        }
        
        var icon: String {
            switch self {
            case .cameraPermissionDenied, .photoCaptureFailed:
                return "camera.fill"
            case .arNotSupported, .deviceNotSupported:
                return "exclamationmark.triangle.fill"
            case .trackingLimited, .trackingLost:
                return "location.slash.fill"
            case .memoryCreationFailed:
                return "heart.slash.fill"
            }
        }
    }
    
    /// Shows an error to the user
    func showError(_ error: ARError) {
        currentError = error
        showingAlert = true
        
        // Log for debugging
        print("❌ ARverse Error: \(error.localizedDescription)")
        print("💡 Suggestion: \(error.recoverySuggestion ?? "No suggestion")")
    }
    
    /// Checks if AR is supported on current device
    func checkARSupport() {
        guard ARWorldTrackingConfiguration.isSupported else {
            showError(.arNotSupported)
            return
        }
        
        // Check device compatibility
        let device = UIDevice.current
        if !device.model.contains("iPhone") || 
           !ProcessInfo.processInfo.isOperatingSystemAtLeast(OperatingSystemVersion(majorVersion: 12, minorVersion: 0, patchVersion: 0)) {
            showError(.deviceNotSupported)
        }
    }
    
    /// Checks camera permissions
    func checkCameraPermission() async {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch status {
        case .denied, .restricted:
            showError(.cameraPermissionDenied)
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            if !granted {
                showError(.cameraPermissionDenied)
            }
        case .authorized:
            break
        @unknown default:
            showError(.cameraPermissionDenied)
        }
    }
    
    /// Handles AR tracking state changes
    func handleTrackingState(_ state: ARCamera.TrackingState) {
        switch state {
        case .limited(let reason):
            switch reason {
            case .insufficientFeatures, .excessiveMotion:
                showError(.trackingLimited)
            default:
                break
            }
        case .notAvailable:
            showError(.trackingLost)
        case .normal:
            // Clear any tracking errors when back to normal
            if currentError == .trackingLimited || currentError == .trackingLost {
                currentError = nil
                showingAlert = false
            }
        }
    }
}

// MARK: - Error Alert View Modifier

extension View {
    func errorAlert(errorManager: ErrorManager) -> some View {
        alert(
            errorManager.currentError?.localizedDescription ?? "Error",
            isPresented: Binding<Bool>(
                get: { errorManager.showingAlert },
                set: { _ in errorManager.showingAlert = false }
            )
        ) {
            Button("Settings") {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            }
            Button("OK") {
                errorManager.showingAlert = false
            }
        } message: {
            if let error = errorManager.currentError {
                HStack {
                    Image(systemName: error.icon)
                    Text(error.recoverySuggestion ?? "")
                }
            }
        }
    }
}