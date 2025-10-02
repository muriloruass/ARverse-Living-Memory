import SwiftUI
import simd
import UIKit

/// Screen for adding a new memory to ARverse
struct AddMemoryView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var memoryManager: MemoryManager
    
    @State private var memoryText: String = ""
    @State private var capturedPhoto: UIImage?
    @State private var showingCamera = false
    @State private var showingPhotoLibrary = false
    @State private var isAdding = false
    
    let position: SIMD3<Float>
    
    var body: some View {
        NavigationView {
            ZStack {
                // Dark background for better AR visualization
                Color.black.opacity(0.9)
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 25) {
                    // Inspiring title
                    VStack(spacing: 10) {
                        Text("📸 ARverse Living Memory")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Capture this moment in space")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    
                    // Photo area
                    VStack(spacing: 15) {
                        if let photo = capturedPhoto {
                            // Show captured photo
                            Image(uiImage: photo)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: 200)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.blue, lineWidth: 2)
                                )
                        } else {
                            // Capture buttons
                            VStack(spacing: 10) {
                                Button(action: { showingCamera = true }) {
                                    HStack {
                                        Image(systemName: "camera.fill")
                                        Text("Take Photo")
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                                }
                                
                                Button(action: { showingPhotoLibrary = true }) {
                                    HStack {
                                        Image(systemName: "photo.fill")
                                        Text("Choose from Gallery")
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 45)
                                    .background(Color.gray.opacity(0.3))
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                                }
                            }
                        }
                        
                        if capturedPhoto != nil {
                            Button("📷 Change Photo") {
                                showingCamera = true
                            }
                            .foregroundColor(.blue)
                        }
                    }
                    
                    
                    // Main text field
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Your memory:")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        TextField("Describe this moment...", text: $memoryText, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                            .lineLimit(2...4)
                            .font(.body)
                    }
                    
                    Spacer()
                    
                    // Action buttons
                    VStack(spacing: 15) {
                        // Save button
                        Button(action: saveMemory) {
                            HStack {
                                if isAdding {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "heart.fill")
                                }
                                Text(isAdding ? "Saving..." : "Save AR Memory")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 55)
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
                        .disabled(memoryText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isAdding)
                        
                        // Cancel button
                        Button("Cancel") {
                            dismiss()
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 45)
                        .background(Color.gray.opacity(0.3))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                }
                .padding(25)
            }
            .navigationBarHidden(true)
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showingCamera) {
            CameraPickerView(selectedImage: $capturedPhoto)
        }
        .sheet(isPresented: $showingPhotoLibrary) {
            PhotoLibraryPickerView(selectedImage: $capturedPhoto)
        }
    }
    
    /// Saves the memory and closes the screen
    private func saveMemory() {
        let text = memoryText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        
        isAdding = true
        
        // Simulate a small delay for visual feedback
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            memoryManager.addMemory(text: text, photo: capturedPhoto, at: position)
            
            // Haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            
            isAdding = false
            dismiss()
        }
    }
}

// MARK: - Camera Picker

struct CameraPickerView: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        picker.allowsEditing = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPickerView
        
        init(_ parent: CameraPickerView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - Photo Library Picker

struct PhotoLibraryPickerView: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        picker.allowsEditing = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: PhotoLibraryPickerView
        
        init(_ parent: PhotoLibraryPickerView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

#Preview {
    AddMemoryView(
        memoryManager: MemoryManager(),
        position: SIMD3<Float>(0, 0, -0.5)
    )
}
